/// 기존 PIC에 등록된 담당자와 전화 앱에 전달할 번호를 표현한다.
class PersonInCharge {
  final String name;
  final String phone;

  const PersonInCharge({required this.name, required this.phone});

  factory PersonInCharge.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim() ?? '';
    return PersonInCharge(
      name: name.isEmpty ? '담당자' : name,
      phone: (json['phone'] as String?)?.trim() ?? '',
    );
  }

  /// 일반 전화번호 구분 기호만 제거한다. 단축 신고번호는 연락처에서 제외한다.
  String? get dialNumber {
    final value = phone.replaceAll(RegExp(r'[\s().-]'), '');
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value) ? value : null;
  }
}
