// 원본: phone/android/app/src/main/kotlin/bitc/aws402/wear/WearBridge.kt (2026-11-26 이식, 패키지만 바꿈. 고치면 원본도 함께 확인)
package bitc.aws402.aws402_flutter.wear

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.CapabilityInfo
import com.google.android.gms.wearable.ChannelClient
import com.google.android.gms.wearable.PutDataRequest
import com.google.android.gms.wearable.Wearable
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import org.json.JSONObject

/**
 * 폰 쪽 Data Layer 연결 (PROTOCOL.md 5절). 워치의 core/datalayer/WearLink 와 같은 규칙을 따른다.
 *
 * - 받을 때: 네이티브 DB(inbox)에 먼저 저장 → ACK → 경고 이상이면 알림(FR-P-11) → Dart 로 전달.
 *   Dart 가 없으면(앱 종료·엔진 없음) DB 에 남겨 두고, 엔진이 붙으면 순서대로 넘긴다.
 * - 보낼 때: outbox 에 넣고 보낸다. ACK 가 오면 지우고, 3초 → 6초 … 최대 60초 간격으로 다시 보낸다.
 * - request(): 응답(replyTo)이 오거나 시간이 다 되면 결과를 돌려준다 (MethodChannel Future).
 */
class WearBridge private constructor(context: Context) {
    private val app = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val main = Handler(Looper.getMainLooper())
    val store = WearStore(app)
    private val messages = Wearable.getMessageClient(app)
    private val data = Wearable.getDataClient(app)
    private val channels = Wearable.getChannelClient(app)
    private val capabilities = Wearable.getCapabilityClient(app)
    private val flushLock = Mutex()
    private val wake = Channel<Unit>(Channel.CONFLATED)
    @Volatile private var localNodeId: String? = null

    data class Peer(val id: String, val name: String, val nearby: Boolean)

    @Volatile var peers: List<Peer> = emptyList(); private set

    /** Dart 로 이벤트를 보내는 통로. 메인 스레드에서 부른다. null 이면 Dart 가 없다. */
    @Volatile private var sink: ((Map<String, Any?>) -> Unit)? = null

    private class Pending(
        val finalTypes: Set<String>,
        val type: String,
        val seq: Long,
        val path: String,
        val createdAt: Long,
        val callback: (Map<String, Any?>) -> Unit,
        @Volatile var ackAt: Long? = null,
        @Volatile var firstSentAt: Long? = null,
    )

    private val pending = ConcurrentHashMap<String, Pending>()

    private val capabilityListener = CapabilityClient.OnCapabilityChangedListener { onCapability(it) }

    init {
        capabilities.addListener(capabilityListener, Paths.CAP_WATCH)
        scope.launch { refreshPeers() }
        scope.launch { retryLoop() }
        scope.launch { runCatching { localNodeId = Wearable.getNodeClient(app).localNode.await().id } }
    }

    private fun now() = System.currentTimeMillis()

    // ------------------------------------------------------------ Dart 연결

    fun attachSink(s: (Map<String, Any?>) -> Unit) {
        sink = s
        emit(nodesEvent())
        scope.launch { deliverStored() }
    }

    fun detachSink() { sink = null }

    private fun emit(event: Map<String, Any?>) {
        val s = sink ?: return
        main.post { s(event) }
    }

    /** 저장만 되고 Dart 로 넘어가지 않은 메시지를 받은 순서대로 넘긴다. */
    private suspend fun deliverStored() = flushLock.withLock {
        while (sink != null) {
            val rows = store.undelivered()
            if (rows.isEmpty()) return@withLock
            for (r in rows) {
                if (sink == null) return@withLock
                emit(messageEvent(r, stored = true))
                store.markDelivered(r.msgId)
            }
        }
    }

    private fun messageEvent(r: WearStore.InboxRow, stored: Boolean) = mapOf(
        "kind" to "message", "path" to r.path, "transport" to r.transport, "nodeId" to r.nodeId,
        "receivedAt" to r.receivedAt, "bytes" to r.bytes, "json" to r.json, "fromStore" to stored,
    )

    // ------------------------------------------------------------ 상대 노드

    suspend fun refreshPeers() {
        try {
            onCapability(capabilities.getCapability(Paths.CAP_WATCH, CapabilityClient.FILTER_REACHABLE).await())
        } catch (t: Throwable) {
            log("!", "노드 조회 실패: ${t.javaClass.simpleName} ${t.message}")
        }
    }

    private fun onCapability(info: CapabilityInfo) {
        val before = peers
        peers = info.nodes.map { Peer(it.id, it.displayName, it.isNearby) }.sortedByDescending { it.nearby }
        emit(nodesEvent())
        if (before.isEmpty() && peers.isNotEmpty()) {
            log("←", "워치 연결됨 → 큐 즉시 재전송")
            scope.launch { store.makeAllDue(); wake.trySend(Unit) }
        } else if (before.isNotEmpty() && peers.isEmpty()) {
            log("!", "워치 연결 끊김")
        }
    }

    fun nodesEvent(): Map<String, Any?> = mapOf(
        "kind" to "nodes", "at" to now(),
        "nodes" to peers.map { mapOf("id" to it.id, "name" to it.name, "nearby" to it.nearby) },
    )

    // ------------------------------------------------------------ 보내기

    /** 메시지를 만들어 큐에 넣는다. 경로·전송 방식은 type 으로 정한다. */
    fun enqueue(type: String, payload: JSONObject, sessionId: String?): Envelope {
        val (path, transport) = Paths.route(type)
        val seq = store.nextSeq()
        val env = Envelope(
            msgId = UUID.randomUUID().toString(), type = type, sessionId = sessionId,
            participantId = PARTICIPANT_ID, seq = seq, createdAt = now(), payload = payload,
        )
        store.putOutbox(
            WearStore.OutboxRow(env.msgId, seq, type, path, transport.name, env.encode(), env.createdAt, 0, 0, null, null)
        )
        wake.trySend(Unit)
        return env
    }

    /**
     * 요청을 보내고 [finalTypes] 중 하나가 replyTo 로 돌아오거나(ERROR 포함) [timeoutMs] 가 지나면 [callback].
     * 결과: ok, msgId, seq, path, createdAt, firstSentAt, ackAt, replyAt, reply(JSON), error, detail
     */
    fun request(type: String, payload: JSONObject, sessionId: String?, timeoutMs: Long, finalTypes: Set<String>, callback: (Map<String, Any?>) -> Unit) {
        val env = try {
            enqueue(type, payload, sessionId)
        } catch (t: Throwable) {
            callback(mapOf("ok" to false, "error" to "BAD_REQUEST", "detail" to (t.message ?: t.javaClass.simpleName)))
            return
        }
        val p = Pending(finalTypes + "ERROR", env.type, env.seq, Paths.route(type).first, env.createdAt, callback)
        pending[env.msgId] = p
        main.postDelayed({
            val left = pending.remove(env.msgId) ?: return@postDelayed
            val reason = when {
                peers.isEmpty() -> "워치 노드 없음 (큐에 남아 연결되면 재전송)"
                left.ackAt == null -> "ACK 없음"
                else -> "ACK 는 받았으나 응답 없음"
            }
            left.callback(result(env.msgId, left) + mapOf("ok" to false, "error" to "TIMEOUT", "detail" to "${timeoutMs}ms 초과: $reason"))
        }, timeoutMs)
    }

    private fun result(msgId: String, p: Pending): Map<String, Any?> = mapOf(
        "msgId" to msgId, "seq" to p.seq, "type" to p.type, "path" to p.path, "createdAt" to p.createdAt,
        "firstSentAt" to p.firstSentAt, "ackAt" to p.ackAt,
    )

    fun clearQueue() {
        store.clearOutbox()
        log("!", "송신 큐를 비움 (사용자 요청)")
    }

    private suspend fun retryLoop() {
        while (true) {
            flushDue()
            val next = store.nextDueAt()
            val wait = if (next == null) 30_000L else (next - now()).coerceIn(50L, 30_000L)
            withTimeoutOrNull(wait) { wake.receive() }
        }
    }

    private suspend fun flushDue() {
        while (true) {
            val due = store.due(now())
            if (due.isEmpty()) return
            for (r in due) attempt(r)
            if (peers.isEmpty()) return
        }
    }

    private suspend fun attempt(r: WearStore.OutboxRow) {
        val peer = peers.firstOrNull()
        if (peer == null) {
            store.putOutbox(r.copy(nextAttemptAt = now() + FIRST_BACKOFF_MS, lastError = "워치 노드 없음"))
            return
        }
        val at = now()
        val env = Envelope.parse(r.json).copy(sentAt = at, retry = r.attempts)
        val bytes = env.bytes()
        val error = try {
            when (Paths.Transport.valueOf(r.transport)) {
                Paths.Transport.MESSAGE -> messages.sendMessage(peer.id, r.path, bytes).await()
                Paths.Transport.DATA -> data.putDataItem(PutDataRequest.create(r.path).setData(bytes).setUrgent()).await()
                Paths.Transport.CHANNEL -> throw UnsupportedOperationException("폰은 채널로 보내지 않음")
            }
            null
        } catch (t: Throwable) {
            "${t.javaClass.simpleName}: ${t.message}"
        }
        val attempts = r.attempts + 1
        store.putOutbox(r.copy(json = env.encode(), attempts = attempts, lastAttemptAt = at, nextAttemptAt = at + backoff(attempts), lastError = error))
        pending[r.msgId]?.let { if (it.firstSentAt == null) it.firstSentAt = at }
        emit(
            mapOf(
                "kind" to "sent", "msgId" to r.msgId, "type" to r.type, "seq" to r.seq, "path" to r.path,
                "attempt" to attempts, "at" to at, "bytes" to bytes.size, "error" to error,
            )
        )
    }

    private fun sendAck(nodeId: String, of: Envelope, status: String, detail: String? = null) {
        val payload = JSONObject().apply {
            put("ackOf", of.msgId); put("ackSeq", of.seq); put("status", status); put("detail", detail ?: JSONObject.NULL)
        }
        val ack = Envelope(
            msgId = UUID.randomUUID().toString(), type = "ACK", replyTo = of.msgId, sessionId = of.sessionId,
            participantId = PARTICIPANT_ID, seq = 0, createdAt = now(), sentAt = now(), payload = payload,
        )
        scope.launch {
            try {
                messages.sendMessage(nodeId, Paths.ACK, ack.bytes()).await()
            } catch (t: Throwable) {
                log("!", "ACK 전송 실패 ${of.type}#${of.seq}: ${t.message}")
            }
        }
    }

    // ------------------------------------------------------------ 받기 (PhoneListenerService 가 부른다)

    fun onMessage(nodeId: String, path: String, bytes: ByteArray) {
        scope.launch { handle(nodeId, path, bytes, Paths.Transport.MESSAGE) }
    }

    fun onData(nodeId: String, path: String, bytes: ByteArray) {
        if (nodeId == localNodeId) return // 내가 넣은 DataItem
        scope.launch { handle(nodeId, path, bytes, Paths.Transport.DATA) }
    }

    fun onChannel(channel: ChannelClient.Channel) {
        scope.launch {
            val started = now()
            val bytes = try {
                channels.getInputStream(channel).await().use { it.readBytes() }
            } catch (t: Throwable) {
                log("!", "채널 ${channel.path} 읽기 실패: ${t.message}")
                return@launch
            } finally {
                runCatching { channels.close(channel).await() }
            }
            log("←", "채널 ${channel.path} ${bytes.size}B, ${now() - started}ms")
            handle(channel.nodeId, channel.path, bytes, Paths.Transport.CHANNEL, channelMs = now() - started)
        }
    }

    private suspend fun handle(nodeId: String, path: String, bytes: ByteArray, transport: Paths.Transport, channelMs: Long? = null) {
        val env = try {
            Envelope.parse(bytes)
        } catch (t: Throwable) {
            log("!", "$path 해석 실패(${bytes.size}B): ${t.message}")
            return
        }
        if (env.type == "ACK") return onAck(env)

        val at = now()
        var json = env.encode()
        if (channelMs != null) {
            // 채널 전송 속도 측정을 위해 받은 시간을 봉투 밖 정보로 붙인다 (Dart 의 KB/s 계산)
            json = JSONObject(json).put("_channelMs", channelMs).toString()
        }
        val row = WearStore.InboxRow(env.msgId, env.seq, env.type, path, transport.name, nodeId, json, bytes.size, at)
        // 1) 저장 → 2) ACK. 중복이면 저장하지 않고 DUPLICATE ACK 만 보낸다.
        if (!store.insertInbox(row)) {
            sendAck(nodeId, env, "DUPLICATE")
            emit(mapOf("kind" to "duplicate", "type" to env.type, "seq" to env.seq, "msgId" to env.msgId, "retry" to env.retry, "at" to at))
            return
        }
        val known = env.type in Paths.INCOMING_TYPES
        sendAck(nodeId, env, if (known) "OK" else "REJECTED", if (known) null else "unknown type ${env.type}")
        // 3) 경고 이상은 Dart 상태와 상관없이 네이티브에서 알린다 (FR-P-11)
        AlertNotifier.maybeNotify(app, env)
        // 4) 요청 결과
        env.replyTo?.let { rt ->
            val p = pending[rt]
            if (p != null && env.type in p.finalTypes) {
                pending.remove(rt)
                main.post { p.callback(result(rt, p) + mapOf("ok" to (env.type != "ERROR"), "replyAt" to at, "reply" to json)) }
            }
        }
        // 5) Dart 로 전달
        if (sink != null) {
            emit(messageEvent(row, stored = false))
            store.markDelivered(env.msgId)
        }
        if (env.seq % 500 == 0L) store.pruneInbox()
    }

    private fun onAck(ack: Envelope) {
        val ackOf = Envelope.str(ack.payload, "ackOf") ?: return
        val status = Envelope.str(ack.payload, "status") ?: "?"
        val row = store.outbox(ackOf)
        val at = now()
        pending[ackOf]?.let { if (it.ackAt == null) it.ackAt = at }
        if (row != null) {
            store.deleteOutbox(ackOf)
            if (Paths.Transport.valueOf(row.transport) == Paths.Transport.DATA) deleteDataItem(row.path)
        }
        emit(
            mapOf(
                "kind" to "ack", "ackOf" to ackOf, "status" to status, "at" to at, "type" to row?.type,
                "seq" to row?.seq, "rttMs" to row?.lastAttemptAt?.let { at - it }, "known" to (row != null),
            )
        )
    }

    @SuppressLint("VisibleForTests")
    private fun deleteDataItem(path: String) {
        val uri = Uri.Builder().scheme(PutDataRequest.WEAR_URI_SCHEME).path(path).build()
        scope.launch {
            runCatching { data.deleteDataItems(uri).await() }.onFailure { log("!", "$path DataItem 삭제 실패: ${it.message}") }
        }
    }

    // ------------------------------------------------------------ 상태 조회 (MethodChannel)

    fun queueInfo(): Map<String, Any?> {
        val rows = store.allOutbox()
        val (total, undelivered) = store.inboxCounts()
        return mapOf(
            "outbox" to rows.take(30).map {
                mapOf("msgId" to it.msgId, "type" to it.type, "seq" to it.seq, "attempts" to it.attempts, "lastError" to it.lastError)
            },
            "outboxCount" to rows.size, "inboxCount" to total, "inboxUndelivered" to undelivered,
        )
    }

    private fun log(dir: String, text: String) {
        if (dir == "!") Log.w(TAG, "[wear] $text") else Log.d(TAG, "[wear] $text")
        emit(mapOf("kind" to "log", "dir" to dir, "text" to text, "at" to now()))
    }

    companion object {
        const val TAG = "SeniorSafe"
        /** 3단계 참여자 ID. phone/ 의 scenario flavor 와 같은 값 (워치 app-scenario 의 participantId 와 같음) */
        val PARTICIPANT_ID: String = "P-0001"
        private const val FIRST_BACKOFF_MS = 3_000L
        private const val MAX_BACKOFF_MS = 60_000L

        /** PROTOCOL.md 5절: 3초 → 6초 → 12초 … 최대 60초 */
        fun backoff(attempts: Int): Long =
            if (attempts <= 1) FIRST_BACKOFF_MS
            else (FIRST_BACKOFF_MS shl (attempts - 1).coerceAtMost(10)).coerceAtMost(MAX_BACKOFF_MS)

        @Volatile private var instance: WearBridge? = null

        fun get(context: Context): WearBridge = instance ?: synchronized(this) {
            instance ?: WearBridge(context).also { instance = it }
        }
    }
}
