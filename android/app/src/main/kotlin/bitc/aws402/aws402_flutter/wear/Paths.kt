// 원본: phone/android/app/src/main/kotlin/bitc/aws402/wear/Paths.kt (2026-11-26 이식, 패키지만 바꿈. 고치면 원본도 함께 확인)
package bitc.aws402.aws402_flutter.wear

/**
 * 경로와 메시지 종류. 기준: shared/protocol/PROTOCOL.md 3·4절.
 * 워치의 같은 상수: wear/core/datalayer/Paths.kt, wear/core/model 의 protocol/Payloads.kt (MsgType)
 */
object Paths {
    const val CAP_WATCH = "seniorsafe_watch"
    const val CAP_PHONE = "seniorsafe_phone"

    const val ACK = "/ack"

    enum class Transport { MESSAGE, DATA, CHANNEL }

    /** 폰 → 워치 요청의 경로와 전송 방식 */
    private val outgoing: Map<String, Pair<String, Transport>> = mapOf(
        "PING" to ("/ping" to Transport.MESSAGE),
        "REQ_SDK_STATUS" to ("/req/sdk-status" to Transport.MESSAGE),
        "REQ_HR_ONCE" to ("/req/hr-once" to Transport.MESSAGE),
        "CMD_STREAM" to ("/cmd/stream" to Transport.MESSAGE),
        "CMD_SUMMARY" to ("/cmd/summary" to Transport.MESSAGE),
        "REQ_SPO2" to ("/req/spo2" to Transport.MESSAGE),
        "REQ_SKIN_TEMP" to ("/req/skin-temp" to Transport.MESSAGE),
        "REQ_HRV" to ("/req/hrv" to Transport.MESSAGE),
        "REQ_HR0" to ("/req/hr0" to Transport.MESSAGE),
        "CONFIG_THRESHOLD" to ("/config/threshold" to Transport.DATA),
        "CMD_SESSION" to ("/cmd/session" to Transport.MESSAGE),
        "CMD_GRADE" to ("/cmd/grade" to Transport.MESSAGE),
        "REQ_SESSION_SUMMARY" to ("/req/session-summary" to Transport.MESSAGE),
        "REQ_BULK" to ("/req/bulk" to Transport.MESSAGE),
        "REQ_BURST" to ("/req/burst" to Transport.MESSAGE),
        "CMD_SCENARIO" to ("/cmd/scenario" to Transport.MESSAGE),
        "CMD_RELEASE" to ("/cmd/release" to Transport.MESSAGE),
        "CMD_EMERGENCY" to ("/cmd/emergency" to Transport.MESSAGE),
        "FINAL_GRADE" to ("/push/final-grade" to Transport.MESSAGE),
        // 2단계 v2 (PROTOCOL.md 9절)
        "REQ_PRECHECK" to ("/req/precheck" to Transport.MESSAGE),
        "CMD_RESPONSE" to ("/cmd/response" to Transport.MESSAGE),
        "CMD_REALERT" to ("/cmd/realert" to Transport.MESSAGE),
        "CMD_SOS_CANCEL" to ("/cmd/sos-cancel" to Transport.MESSAGE),
    )

    /** 워치 → 폰 메시지 종류 (받을 수 있는 것) */
    val INCOMING_TYPES: Set<String> = setOf(
        "PONG", "SDK_STATUS", "MEASURE_RESULT", "STREAM_STATE", "STREAM_BIO", "SUMMARY_STATE", "SUMMARY_MINUTE",
        "HRV_RESULT", "HR0_PROGRESS", "HR0_RESULT", "CONFIG_APPLIED", "SESSION_STATE", "GRADE_STATE",
        "SUMMARY_SESSION", "BULK_HR", "EVENT_BURST", "EVENT_SOS", "EVENT_RESPONSE", "EVENT_STATUS", "ERROR",
        "SCENARIO_STATE", "EVENT_GRADE", "PRECHECK_RESULT",
    )

    /** 프로토콜의 모든 종류 (직렬화 테스트가 samples 와 맞춰 본다) */
    val ALL_TYPES: Set<String> get() = outgoing.keys + INCOMING_TYPES + "ACK"

    fun route(type: String): Pair<String, Transport> =
        outgoing[type] ?: throw IllegalArgumentException("폰이 보낼 수 없는 type: $type (PROTOCOL.md 3.1절)")
}
