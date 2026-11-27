// 원본: phone/android/app/src/main/kotlin/bitc/aws402/wear/AlertNotifier.kt (2026-11-26 이식, 패키지만 바꿈. 고치면 원본도 함께 확인)
package bitc.aws402.aws402_flutter.wear

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.util.Log
import bitc.aws402.aws402_flutter.MainActivity

/**
 * 경고 이상 이벤트 알림 (FR-P-11). Dart 상태와 상관없이 네이티브가 받은 즉시 띄운다.
 * 대상: SOS 확정·카운트다운 시작, "도움 요청" 응답, 등급 WARNING 이상.
 * 실제 보호자·기관 발송은 하지 않는다 (CLAUDE.md 규칙 9).
 *
 * TODO(device-check): 화면이 꺼지고 앱이 종료된 상태에서 알림 소리가 나는지 (T2-05).
 */
object AlertNotifier {
    private const val CHANNEL = "seniorsafe-alert"
    private val urgentGrades = setOf("WARNING", "DANGER", "EMERGENCY")
    private val gradeLabel = mapOf("WARNING" to "경고", "DANGER" to "위험", "EMERGENCY" to "위험(위급)")

    fun maybeNotify(context: Context, env: Envelope) {
        val p = env.payload
        val text: String = when (env.type) {
            "EVENT_SOS" -> when (Envelope.str(p, "state")) {
                "CONFIRMED" -> "워치에서 SOS 가 확정되었습니다"
                // 2단계 v2: 위급 취소 카운트다운 시작. 화면이 꺼져 있어도 폰에서 취소할 수 있게 알린다
                "COUNTDOWN" -> "워치 위급 카운트다운이 시작되었습니다. 앱에서 취소할 수 있어요"
                else -> return
            }
            "EVENT_RESPONSE" -> if (Envelope.str(p, "response") == "HELP") "참여자가 도움을 요청했습니다" else return
            // 3단계: 워치가 판정한 등급 변경. 참여자에게 알렸고(alert) 경고 이상일 때만 (FR-P-11)
            "EVENT_GRADE" -> {
                val g = Envelope.str(p, "grade")
                val alert = p.optBoolean("alert", false)
                if (g in urgentGrades && alert) "워치 등급: ${gradeLabel[g]}" else return
            }
            "GRADE_STATE" -> {
                val g = Envelope.str(p, "grade")
                if (g in urgentGrades) "워치 등급: ${gradeLabel[g]}" else return
            }
            else -> return
        }
        try {
            val nm = context.getSystemService(NotificationManager::class.java)
            val ch = NotificationChannel(CHANNEL, "경고 이상 알림", NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build(),
                )
                enableVibration(true)
            }
            nm.createNotificationChannel(ch)
            val open = PendingIntent.getActivity(
                context, 0, context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: android.content.Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val n = android.app.Notification.Builder(context, CHANNEL)
                .setSmallIcon(android.R.drawable.stat_sys_warning)
                .setContentTitle("헬스가드 워치 경고")
                .setContentText("$text (seq ${env.seq})")
                .setCategory(android.app.Notification.CATEGORY_ALARM)
                .setContentIntent(open)
                .setAutoCancel(true)
                .build()
            nm.notify(env.msgId.hashCode(), n)
        } catch (t: Throwable) {
            // 알림 권한이 없으면 SecurityException. 숨기지 않고 로그에 남긴다 (NFR-05).
            Log.w(WearBridge.TAG, "[wear] 경고 알림 실패: ${t.javaClass.simpleName} ${t.message}")
        }
    }
}
