import 'package:aws402_flutter/mobile/mobile_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mobile_api_stub.dart';

// 구정민 : 수정 - 기존 테스트 파일은 유지하고 가상 GET 대신 워치값 POST 계약을 검증한다.
void main() {
  test('워치 측정 POST에 걸음 수·강제 등급·시나리오가 포함되지 않는다', () async {
    final requests = <Map<String, dynamic>>[];
    configureMobileApiStub(requests: requests);
    final sample = fakeWatch.sample(bpm: 130, temperature: 38.5, spo2: 89);
    final result = await MobileApi.instance.sendMeasurement(sample);
    expect(result['saved'], true);
    expect(result['status'], 'DANGER');
    final body = requests.single['body'] as Map;
    expect(body['bpm'], 130);
    expect(body['skinTemperature'], 38.5);
    expect(body['spo2'], 89);
    for (final key in ['steps', 'status', 'scenario']) {
      expect(body.containsKey(key), false);
    }
    expect(body['sampleId'], sample.sampleId);
    expect(
      DateTime.parse(body['measuredAt'] as String),
      sample.measuredAt.toUtc(),
    );
    expect(requests.single['path'], '/api/mobile/measurements');
  });
  test('워치 데이터 모델은 누락 대체나 건강 등급 생성을 하지 않는다', () {
    final watch = FakeWatchClient();
    expect(watch.sample().isValid, true);
    expect(watch.sample(temperature: double.nan).isValid, false);
    expect(watch.sample(id: '').isValid, false);
    expect(watch.sample(spo2: 101).isValid, false);
    expect(watch.sample().toJson().containsKey('steps'), false);
  });
}
