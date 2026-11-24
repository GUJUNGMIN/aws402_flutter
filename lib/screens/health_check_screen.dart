// [인수인계] 같은 WatchHealthController로 실제 연결과 최초 측정을 요청하고 저장 진행/완료 상태를 보여준다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';

import '../mobile/location_permission_service.dart';
import '../watch/watch_health_controller.dart';
import '../watch/watch_client.dart';
import '../config/step2_feature_flags.dart';

// 구정민 : 수정 - 실제 어댑터의 연결 상태와 서버 저장 확인된 측정 결과를 표시한다.
class HealthCheckScreen extends StatefulWidget {
  final WatchHealthController controller;

  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const HealthCheckScreen({super.key, required this.controller});

  @override
  /// [인수인계] 이 화면 인스턴스에 대응하는 State 객체를 만든다.
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen>
    with WidgetsBindingObserver {
  LocationAccessStatus _gpsStatus = LocationAccessStatus.checking;
  bool _gpsBusy = false;

  @override
  /// [인수인계] 화면 최초 생성 시 필요한 구독·조회·타이머를 초기화한다. dispose와 함께 확인한다.
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_healthChanged);
    _refreshGpsStatus();
  }

  @override
  /// [인수인계] 화면/객체가 사라질 때 등록한 구독·리스너·타이머를 정리한다.
  void dispose() {
    widget.controller.removeListener(_healthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  /// [인수인계] OS 설정에서 앱으로 돌아오면 위치 권한 상태를 다시 읽는다.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 구정민 : 사용자가 Android 설정 화면에서 권한을 변경하고 앱으로 복귀하면 상태를 다시 읽는다.
    if (state == AppLifecycleState.resumed) _refreshGpsStatus();
  }

  /// [인수인계] 현재 OS 권한/위치 서비스 상태를 읽어 화면 안내를 갱신한다.
  Future<void> _refreshGpsStatus() async {
    final status = await LocationPermissionService.checkStatus();
    if (mounted) {
      setState(() {
        _gpsStatus = status;
      });
    }
  }

  // 구정민 : 권한 거부 시 설정 이동만 안내하며, 별도 위치 사전 검사를 업무 시작 조건에 추가하지 않는다.
  /// [인수인계] 현재 권한 상태에 맞춰 OS 권한 요청 또는 앱/위치 설정 이동을 수행한다. 건강 저장의 필수 조건은 아니다.
  Future<void> _requestGpsPermission() async {
    if (_gpsBusy) return;
    setState(() {
      _gpsBusy = true;
    });
    try {
      LocationAccessStatus status;
      switch (_gpsStatus) {
        case LocationAccessStatus.permanentlyDenied:
          await LocationPermissionService.openAppSettings();
          status = await LocationPermissionService.checkStatus();
          break;
        case LocationAccessStatus.serviceDisabled:
          await LocationPermissionService.openLocationSettings();
          status = await LocationPermissionService.checkStatus();
          break;
        default:
          status = await LocationPermissionService.requestAccess();
      }
      if (mounted) {
        setState(() {
          _gpsStatus = status;
        });
      }
    } catch (_) {
      // 구정민 : 기기 설정 화면 열기가 실패해도 건강 측정 기능은 유지한다.
      if (mounted) {
        setState(() {
          _gpsStatus = LocationAccessStatus.error;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _gpsBusy = false;
        });
      }
    }
  }

  String get _gpsLabel => switch (_gpsStatus) {
    LocationAccessStatus.granted => '권한 승인 · GPS 사용 가능',
    LocationAccessStatus.denied => '권한 미승인 (선택)',
    LocationAccessStatus.permanentlyDenied => '권한 거부 · 설정에서 변경',
    LocationAccessStatus.serviceDisabled => '위치 서비스 꺼짐',
    LocationAccessStatus.error => '권한 확인 실패',
    LocationAccessStatus.checking => '확인 중',
  };

  String get _gpsButtonLabel => switch (_gpsStatus) {
    LocationAccessStatus.permanentlyDenied => '앱 설정에서 GPS 권한 변경',
    LocationAccessStatus.serviceDisabled => '휴대폰 위치 서비스 켜기',
    LocationAccessStatus.granted => 'GPS 권한 상태 새로고침',
    _ => 'GPS 위치 권한 승인',
  };

  /// [인수인계] 공유 측정 컨트롤러가 변경되면 화면을 다시 그린다.
  void _healthChanged() {
    if (mounted) setState(() {});
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.state;
    final sending = controller.busy;
    final connecting = controller.connection == WatchConnection.connecting;

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Scaffold(
      appBar: AppBar(title: const Text('워치 연결 · 건강 측정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.watch, size: 64, color: Colors.blue),
            const SizedBox(height: 12),
            const Text(
              '워치 건강 측정',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '워치를 연결한 뒤 새 건강 측정을 진행해 주세요.\n'
              '서버 저장이 확인된 측정값과 판정만 표시합니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _statusTile(
              '워치 연결',
              connecting
                  ? '연결 중'
                  : state.watchConnected
                  ? '연결 완료'
                  : '연결 전',
            ),
            _statusTile(
              '최초 건강 측정',
              state.initialHealthChecked ? '서버 측정 완료' : '측정 전',
            ),
            // 구정민 : GPS는 사용자가 선택적으로 승인한다. 거부해도 건강값/근무 API는 정상 사용한다.
            _statusTile('GPS 위치 권한', _gpsLabel),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: Text(
                'GPS 권한을 승인하면 건강 측정값과 현재 위치를 서버에 함께 전송합니다. '
                '거부해도 건강 측정과 근무 시작은 가능합니다.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _gpsBusy || sending
                  ? null
                  : _gpsStatus == LocationAccessStatus.granted
                  ? _refreshGpsStatus
                  : _requestGpsPermission,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(_gpsButtonLabel),
            ),
            if (state.hasSavedMeasurement)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('심박수 ${state.latestBpm} bpm'),
                      Text('피부온도 ${state.latestTemperature} ℃'),
                      Text('산소포화도 ${state.latestSpo2}%'),
                      Text(
                        !Step2FeatureFlags.showEmergency &&
                                Step2FeatureFlags.isEmergencyStatus(
                                  state.latestGrade,
                                )
                            ? '서버 판정: 현재 표시하지 않는 상태'
                            : '서버 판정: ${state.latestGrade}',
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '서버 저장이 확인된 워치 측정값',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                controller.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: state.serverConnected
                      ? Colors.green.shade800
                      : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: sending || connecting
                  ? null
                  : state.watchConnected
                  ? controller.disconnect
                  : controller.connect,
              icon: Icon(
                state.watchConnected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_connected,
              ),
              label: Text(
                connecting
                    ? '워치 연결 중...'
                    : state.watchConnected
                    ? '워치 연결 해제'
                    : '워치 연결',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: state.watchConnected && !sending
                  ? controller.requestMeasurement
                  : null,
              icon: const Icon(Icons.monitor_heart),
              label: Text(sending ? '측정 및 저장 중...' : '건강 측정'),
            ),
            // 구정민 : 수정 - 건강 측정 API의 DB 저장 성공 응답으로 연결 상태를 확인하므로 별도 버튼은 제거한다.
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('메인으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  /// [인수인계] 권한/연결 항목의 표시 상태와 선택 동작을 한 행으로 구성한다.
  Widget _statusTile(String label, String status) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text(
        status,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
