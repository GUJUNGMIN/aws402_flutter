/// 서버의 숫자 코드와 기존 등급 문자열을 같은 건강 상태로 해석한다.
class HealthStatus {
  const HealthStatus._();

  static String normalize(Object? value) => switch (value?.toString()) {
    '7001' || 'NORMAL' => 'NORMAL',
    '7002' || 'N' || 'NOTICE' => 'NOTICE',
    '7003' || 'W' || 'WARNING' => 'WARNING',
    '7004' || 'D' || 'DANGER' => 'DANGER',
    '7005' || 'E' || 'EMERGENCY' => 'EMERGENCY',
    _ => value?.toString() ?? '',
  };
}
