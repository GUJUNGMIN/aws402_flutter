// 원본: phone/android/app/src/main/kotlin/bitc/aws402/wear/Envelope.kt (2026-11-26 이식, 패키지만 바꿈. 고치면 원본도 함께 확인)
package bitc.aws402.aws402_flutter.wear

import org.json.JSONObject

/**
 * 워치↔폰 메시지 봉투 (PROTOCOL.md 2절). payload 는 해석하지 않고 그대로 Dart 로 넘긴다.
 * org.json 의 optString 은 null 을 "null" 문자열로 돌려주므로 [str] 로만 읽는다.
 */
data class Envelope(
    val v: Int = 1,
    val msgId: String,
    val type: String,
    val replyTo: String? = null,
    val sessionId: String? = null,
    val participantId: String? = null,
    val seq: Long = 0,
    val createdAt: Long,
    val sentAt: Long = 0,
    val retry: Int = 0,
    val payload: JSONObject = JSONObject(),
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("v", v)
        put("msgId", msgId)
        put("type", type)
        put("replyTo", replyTo ?: JSONObject.NULL)
        put("sessionId", sessionId ?: JSONObject.NULL)
        put("participantId", participantId ?: JSONObject.NULL)
        put("seq", seq)
        put("createdAt", createdAt)
        put("sentAt", sentAt)
        put("retry", retry)
        put("payload", payload)
    }

    fun encode(): String = toJson().toString()
    fun bytes(): ByteArray = encode().toByteArray(Charsets.UTF_8)

    companion object {
        fun str(o: JSONObject, k: String): String? = if (!o.has(k) || o.isNull(k)) null else o.getString(k)

        fun parse(text: String): Envelope {
            val o = JSONObject(text)
            return Envelope(
                v = o.optInt("v", 1),
                msgId = o.getString("msgId"),
                type = o.getString("type"),
                replyTo = str(o, "replyTo"),
                sessionId = str(o, "sessionId"),
                participantId = str(o, "participantId"),
                seq = o.optLong("seq", 0),
                createdAt = o.getLong("createdAt"),
                sentAt = o.optLong("sentAt", 0),
                retry = o.optInt("retry", 0),
                payload = o.optJSONObject("payload") ?: JSONObject(),
            )
        }

        fun parse(bytes: ByteArray): Envelope = parse(bytes.toString(Charsets.UTF_8))
    }
}
