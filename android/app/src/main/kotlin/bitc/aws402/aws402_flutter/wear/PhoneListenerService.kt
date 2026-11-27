// 원본: phone/android/app/src/main/kotlin/bitc/aws402/wear/PhoneListenerService.kt (2026-11-26 이식, 패키지만 바꿈. 고치면 원본도 함께 확인)
package bitc.aws402.aws402_flutter.wear

import com.google.android.gms.wearable.ChannelClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

/**
 * 워치 메시지·DataItem·채널을 받는다. Flutter 엔진이 없어도(앱 종료) 시스템이 이 서비스를 띄우고,
 * [WearBridge] 가 네이티브 DB 에 저장한 뒤 ACK 를 보낸다 (T2-05).
 */
class PhoneListenerService : WearableListenerService() {
    private val bridge by lazy { WearBridge.get(applicationContext) }

    override fun onMessageReceived(event: MessageEvent) {
        bridge.onMessage(event.sourceNodeId, event.path, event.data)
    }

    override fun onDataChanged(events: DataEventBuffer) {
        // 버퍼는 이 함수가 끝나면 닫히므로 필요한 값만 먼저 꺼낸다.
        val items = events.filter { it.type == DataEvent.TYPE_CHANGED }.map {
            Triple(it.dataItem.uri.host ?: "", it.dataItem.uri.path ?: "", it.dataItem.data)
        }
        for ((node, path, bytes) in items) if (bytes != null) bridge.onData(node, path, bytes)
    }

    override fun onChannelOpened(channel: ChannelClient.Channel) {
        bridge.onChannel(channel)
    }
}
