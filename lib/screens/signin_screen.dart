// [인수인계] 계정 입력을 확인하고 모바일 로그인 API 성공 후 홈으로 이동한다.
// 기능 연결 위치: 프로젝트의 HANDOFF_LOGIC.html / SOURCE_INDEX.txt

import 'package:flutter/material.dart';
import 'package:aws402_flutter/router/app_routes.dart';

import '../l10n/app_localizations.dart';
import '../mobile/mobile_api.dart';
import '../utils/color_extension.dart';

class SigninScreen extends StatefulWidget {
  /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
  const SigninScreen({super.key});
  @override
  /// [인수인계] 이 화면 인스턴스에 대응하는 State 객체를 만든다.
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  bool _isObscure = true;
  bool _loading = false;
  final TextEditingController controlId = TextEditingController();
  final TextEditingController controlPwd = TextEditingController();

  // 구정민 : 수정 - 임의 ID/PW 허용을 제거하고 모바일 전용 서버 로그인 성공 시에만 홈으로 이동한다.
  /// [인수인계] 기존 Login 조회 결과를 호출부에 반환한다.
  Future<void> getLogin() async {
    if (controlId.text.trim().isEmpty || controlPwd.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('아이디와 비밀번호를 입력해 주세요.')));
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      await MobileApi.instance.login(controlId.text.trim(), controlPwd.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(MobileApi.errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  /// [인수인계] 화면/객체가 사라질 때 등록한 구독·리스너·타이머를 정리한다.
  void dispose() {
    controlId.dispose();
    controlPwd.dispose();
    super.dispose();
  }

  @override
  /// [인수인계] 현재 상태를 위젯으로 구성한다. 네트워크 저장과 판정 계산은 컨트롤러/서비스에서 처리한다.
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fontSize = double.tryParse(l10n.font_size) ?? 20.0;

    /// [인수인계] 생성에 필요한 의존성/초기값을 받아 이 객체를 구성한다.
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.login,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controlId,
              enabled: !_loading,
              autofocus: true,
              // 구정민 : 수정 - 로그인 계정에 영문·숫자·밑줄 입력이 가능하도록 텍스트 키보드를 명시한다.
              // 구정민 : 수정 - 숫자 전용 키보드·입력 필터를 사용하지 않고 로그인 ID를 원문 그대로 서버에 전송한다.
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: '${l10n.id} (${l10n.user_number})',
                hintText: '아이디를 입력하세요 (영문·숫자 입력 가능)',
                labelStyle: TextStyle(fontSize: fontSize),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controlPwd,
              enabled: !_loading,
              obscureText: _isObscure,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.password,
                labelStyle: TextStyle(fontSize: fontSize),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() {
                    _isObscure = !_isObscure;
                  }),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_loading) getLogin();
              },
            ),
            const SizedBox(height: 8),
            const Text(
              '헬스가드 · 서버 로그인',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _loading ? null : getLogin,
              style: FilledButton.styleFrom(
                backgroundColor: l10n.color_blue.toColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                _loading ? '서버 확인 중...' : l10n.login,
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
