import 'package:aws402_flutter/router/app_routes.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/color_extension.dart';

class SigninScreen extends StatefulWidget{
  const SigninScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen>{
  bool _isObscure = true;
  bool _isEnable = true;

  TextEditingController control_id = TextEditingController();
  TextEditingController control_pwd = TextEditingController();

  // 구정민 : 수정 - 기존 가짜 로그인 완료 처리를 입력 검증 후 홈 이동으로 변경했다.
  // 로그인 버튼에서 호출하며, 현재는 서버 인증을 수행하지 않는다.
  void getLogin() {
    if (control_id.text.trim().isEmpty || control_pwd.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해 주세요.')),
      );
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  // 구정민 : 수정 - 로그인 화면이 닫힐 때 입력 컨트롤러를 해제한다.
  @override
  void dispose() {
    control_id.dispose();
    control_pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    double fontSize = double.tryParse(l10n.font_size) ?? 20.0;
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.login,
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,

              ),
            ),
            SizedBox(height: 10.0),
            TextField(
              controller: control_id,
              autofocus: true,
              enabled: _isEnable,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '${l10n.id} (${l10n.user_number})',
                labelStyle: TextStyle(
                  fontSize: fontSize
                )
              ),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 10.0,),
            TextField(
              controller: control_pwd,
              obscureText: _isObscure,
              enabled: _isEnable,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: l10n.password,
                labelStyle: TextStyle(
                    fontSize: fontSize
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
              textInputAction: TextInputAction.done,
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
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isEnable ? getLogin : null,
              style: FilledButton.styleFrom(
                backgroundColor: l10n.color_blue.toColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              child: Text(
                l10n.login,
                style: TextStyle(
                  fontSize: fontSize
                ),
              ),
            ),
          ),
        ),
      )
    );
  }

}