import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mobile/mobile_api.dart';
import '../mobile/person_in_charge.dart';

const _phone = MethodChannel('health_guard/phone');

/// 로그인한 사용자의 담당자를 조회하고 선택된 번호로 Android 전화 앱을 연다.
Future<void> showPersonInChargeContact(
  BuildContext context, {
  bool emergencyPreview = false,
}) async {
  final api = MobileApi.instance;
  final contacts = api.personInChargeContacts();
  final selected = await showDialog<PersonInCharge>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(emergencyPreview ? '119 연결 테스트' : '담당자 연결'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emergencyPreview) ...[
              const Text('등록된 담당자 번호로 연결합니다. 실제 119 신고는 전화 앱에서 직접 해 주세요.'),
              const SizedBox(height: 12),
            ],
            Flexible(
              child: FutureBuilder<List<PersonInCharge>>(
                future: contacts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    final expired =
                        error is DioException &&
                        error.response?.statusCode == 401;
                    return Text(
                      expired
                          ? '로그인이 만료되었습니다. 다시 로그인해 주세요.'
                          : '담당자 연락처를 불러오지 못했습니다. 서버 연결을 확인해 주세요.',
                    );
                  }
                  final callable = snapshot.data!
                      .where((contact) => contact.dialNumber != null)
                      .toList();
                  if (callable.isEmpty) {
                    return const Text('등록된 담당자 연락처가 없습니다.');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: callable.length,
                    itemBuilder: (context, index) {
                      final contact = callable[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(contact.name),
                        subtitle: Text(contact.phone),
                        trailing: TextButton.icon(
                          onPressed: () =>
                              Navigator.pop(dialogContext, contact),
                          icon: const Icon(Icons.phone_outlined),
                          label: const Text('전화'),
                        ),
                        onTap: () => Navigator.pop(dialogContext, contact),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
  final number = selected?.dialNumber;
  if (!context.mounted || number == null || !api.isAuthenticated) return;
  try {
    await _phone.invokeMethod<void>('openDialer', number);
  } on PlatformException {
    if (context.mounted) _showDialerError(context, selected!.phone);
  } on MissingPluginException {
    if (context.mounted) _showDialerError(context, selected!.phone);
  }
}

void _showDialerError(BuildContext context, String phone) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text('전화 앱을 열 수 없습니다. 담당자 번호: $phone')));
}
