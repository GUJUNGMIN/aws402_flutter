package bitc.aws402.aws402_flutter.wear

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.json.JSONObject

/**
 * Flutter ↔ [WearBridge] 채널. phone/ 의 MainActivity 에 있던 등록 코드를 옮겼다 (채널 이름·인자 같음).
 * - `seniorsafe/wear_events` (EventChannel): nodes · message · sent · ack · duplicate · log 이벤트
 * - `seniorsafe/wear_cmd` (MethodChannel): request · send · nodes · refreshNodes · queue · clearQueue
 *
 * 받은 메시지 저장·ACK·재전송은 [WearBridge] 와 [PhoneListenerService] 가 맡는다. 앱이 꺼져 있어도 받는다.
 */
class WearChannels(context: Context, messenger: BinaryMessenger) {
    private val bridge = WearBridge.get(context.applicationContext)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val events = EventChannel(messenger, "seniorsafe/wear_events")
    private val cmd = MethodChannel(messenger, "seniorsafe/wear_cmd")

    init {
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                bridge.attachSink { sink.success(it) }
            }

            override fun onCancel(arguments: Any?) = bridge.detachSink()
        })

        cmd.setMethodCallHandler { call, result ->
            when (call.method) {
                "request" -> {
                    val type = call.argument<String>("type")!!
                    val payload = JSONObject(call.argument<String>("payload") ?: "{}")
                    val timeoutMs = (call.argument<Number>("timeoutMs") ?: 10_000).toLong()
                    val finalTypes = call.argument<List<String>>("finalTypes")!!.toSet()
                    bridge.request(type, payload, call.argument<String>("sessionId"), timeoutMs, finalTypes) { result.success(it) }
                }
                "send" -> {
                    val type = call.argument<String>("type")!!
                    val payload = JSONObject(call.argument<String>("payload") ?: "{}")
                    try {
                        val env = bridge.enqueue(type, payload, call.argument<String>("sessionId"))
                        result.success(mapOf("ok" to true, "msgId" to env.msgId, "seq" to env.seq, "createdAt" to env.createdAt))
                    } catch (t: Throwable) {
                        result.success(mapOf("ok" to false, "error" to "BAD_REQUEST", "detail" to (t.message ?: t.javaClass.simpleName)))
                    }
                }
                "nodes" -> result.success(bridge.nodesEvent())
                "refreshNodes" -> scope.launch { bridge.refreshPeers(); result.success(bridge.nodesEvent()) }
                "queue" -> result.success(bridge.queueInfo())
                "clearQueue" -> { bridge.clearQueue(); result.success(bridge.queueInfo()) }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        events.setStreamHandler(null)
        cmd.setMethodCallHandler(null)
        bridge.detachSink()
        scope.cancel()
    }
}
