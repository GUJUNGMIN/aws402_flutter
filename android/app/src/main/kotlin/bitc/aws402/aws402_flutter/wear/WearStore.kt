// 원본: phone/android/app/src/main/kotlin/bitc/aws402/wear/WearStore.kt (2026-11-26 이식, 패키지만 바꿈. 고치면 원본도 함께 확인)
package bitc.aws402.aws402_flutter.wear

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * 폰 네이티브 DB. 워치에서 받은 것을 Dart 보다 먼저 여기에 저장한다 (phone/CLAUDE.md).
 * - inbox: 받은 메시지. msgId 가 기본키라 중복 판단에도 쓴다. delivered=1 이면 Dart 로 넘긴 것.
 * - outbox: 폰이 보낸 요청 중 ACK 를 아직 못 받은 것 (재전송 큐)
 * - meta: 보내는 쪽 seq
 *
 * Room 대신 SQLiteOpenHelper 를 쓴다. 표가 단순하고, Flutter Gradle 빌드에 어노테이션 처리(KSP)를 더하지 않기 위해서다.
 */
class WearStore(context: Context) : SQLiteOpenHelper(context.applicationContext, "seniorsafe-wear.db", null, 1) {

    data class InboxRow(
        val msgId: String, val seq: Long, val type: String, val path: String, val transport: String,
        val nodeId: String, val json: String, val bytes: Int, val receivedAt: Long,
    )

    data class OutboxRow(
        val msgId: String, val seq: Long, val type: String, val path: String, val transport: String,
        val json: String, val createdAt: Long, val attempts: Int, val nextAttemptAt: Long,
        val lastAttemptAt: Long?, val lastError: String?,
    )

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE inbox(msgId TEXT PRIMARY KEY, seq INTEGER, type TEXT, path TEXT, transport TEXT, nodeId TEXT," +
                " json TEXT, bytes INTEGER, receivedAt INTEGER, delivered INTEGER NOT NULL DEFAULT 0)"
        )
        db.execSQL("CREATE INDEX inbox_pending ON inbox(delivered, receivedAt)")
        db.execSQL(
            "CREATE TABLE outbox(msgId TEXT PRIMARY KEY, seq INTEGER, type TEXT, path TEXT, transport TEXT, json TEXT," +
                " createdAt INTEGER, attempts INTEGER, nextAttemptAt INTEGER, lastAttemptAt INTEGER, lastError TEXT)"
        )
        db.execSQL("CREATE TABLE meta(k TEXT PRIMARY KEY, v INTEGER)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}

    /** 처음 받은 것이면 true. 이미 있으면 false(중복). */
    @Synchronized
    fun insertInbox(r: InboxRow): Boolean {
        val cv = ContentValues().apply {
            put("msgId", r.msgId); put("seq", r.seq); put("type", r.type); put("path", r.path)
            put("transport", r.transport); put("nodeId", r.nodeId); put("json", r.json)
            put("bytes", r.bytes); put("receivedAt", r.receivedAt); put("delivered", 0)
        }
        return writableDatabase.insertWithOnConflict("inbox", null, cv, SQLiteDatabase.CONFLICT_IGNORE) != -1L
    }

    @Synchronized
    fun undelivered(limit: Int = 500): List<InboxRow> = readableDatabase.rawQuery(
        "SELECT msgId, seq, type, path, transport, nodeId, json, bytes, receivedAt FROM inbox" +
            " WHERE delivered = 0 ORDER BY receivedAt LIMIT ?",
        arrayOf(limit.toString()),
    ).use { c ->
        buildList {
            while (c.moveToNext()) add(
                InboxRow(
                    c.getString(0), c.getLong(1), c.getString(2), c.getString(3), c.getString(4),
                    c.getString(5), c.getString(6), c.getInt(7), c.getLong(8),
                )
            )
        }
    }

    @Synchronized
    fun markDelivered(msgId: String) {
        writableDatabase.execSQL("UPDATE inbox SET delivered = 1 WHERE msgId = ?", arrayOf(msgId))
    }

    /** (전체, Dart 로 아직 못 넘긴 것) */
    @Synchronized
    fun inboxCounts(): Pair<Long, Long> = readableDatabase.rawQuery(
        "SELECT COUNT(*), COALESCE(SUM(CASE WHEN delivered = 0 THEN 1 ELSE 0 END), 0) FROM inbox", null,
    ).use { c -> c.moveToFirst(); c.getLong(0) to c.getLong(1) }

    /** 넘긴 지 오래된 받은 메시지를 지운다. 중복 판단은 최근 [keep] 건으로 충분하다. */
    @Synchronized
    fun pruneInbox(keep: Int = 20_000) {
        writableDatabase.execSQL(
            "DELETE FROM inbox WHERE delivered = 1 AND receivedAt <" +
                " (SELECT receivedAt FROM inbox ORDER BY receivedAt DESC LIMIT 1 OFFSET ?)",
            arrayOf<Any>(keep),
        )
    }

    @Synchronized
    fun putOutbox(r: OutboxRow) {
        val cv = ContentValues().apply {
            put("msgId", r.msgId); put("seq", r.seq); put("type", r.type); put("path", r.path)
            put("transport", r.transport); put("json", r.json); put("createdAt", r.createdAt)
            put("attempts", r.attempts); put("nextAttemptAt", r.nextAttemptAt)
            put("lastAttemptAt", r.lastAttemptAt); put("lastError", r.lastError)
        }
        writableDatabase.insertWithOnConflict("outbox", null, cv, SQLiteDatabase.CONFLICT_REPLACE)
    }

    private fun outboxQuery(where: String, args: Array<String>): List<OutboxRow> = readableDatabase.rawQuery(
        "SELECT msgId, seq, type, path, transport, json, createdAt, attempts, nextAttemptAt, lastAttemptAt, lastError" +
            " FROM outbox $where",
        args,
    ).use { c ->
        buildList {
            while (c.moveToNext()) add(
                OutboxRow(
                    c.getString(0), c.getLong(1), c.getString(2), c.getString(3), c.getString(4), c.getString(5),
                    c.getLong(6), c.getInt(7), c.getLong(8), if (c.isNull(9)) null else c.getLong(9),
                    if (c.isNull(10)) null else c.getString(10),
                )
            )
        }
    }

    @Synchronized fun outbox(msgId: String): OutboxRow? = outboxQuery("WHERE msgId = ?", arrayOf(msgId)).firstOrNull()

    @Synchronized
    fun due(now: Long): List<OutboxRow> = outboxQuery("WHERE nextAttemptAt <= ? ORDER BY seq LIMIT 50", arrayOf(now.toString()))

    @Synchronized fun allOutbox(): List<OutboxRow> = outboxQuery("ORDER BY seq", emptyArray())

    @Synchronized
    fun nextDueAt(): Long? = readableDatabase.rawQuery("SELECT MIN(nextAttemptAt) FROM outbox", null)
        .use { c -> if (c.moveToFirst() && !c.isNull(0)) c.getLong(0) else null }

    @Synchronized fun deleteOutbox(msgId: String): Boolean = writableDatabase.delete("outbox", "msgId = ?", arrayOf(msgId)) > 0
    @Synchronized fun clearOutbox() { writableDatabase.delete("outbox", null, null) }
    @Synchronized fun makeAllDue() { writableDatabase.execSQL("UPDATE outbox SET nextAttemptAt = 0") }

    @Synchronized
    fun nextSeq(): Long {
        val db = writableDatabase
        val cur = db.rawQuery("SELECT v FROM meta WHERE k = ?", arrayOf("seq")).use { if (it.moveToFirst()) it.getLong(0) else 0L }
        val next = cur + 1
        db.execSQL("INSERT OR REPLACE INTO meta(k, v) VALUES(?, ?)", arrayOf<Any>("seq", next))
        return next
    }
}
