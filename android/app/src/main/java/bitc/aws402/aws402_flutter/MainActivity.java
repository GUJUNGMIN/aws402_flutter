package bitc.aws402.aws402_flutter;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  @Override
  public void configureFlutterEngine(FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "health_guard/phone")
        .setMethodCallHandler(
            (call, result) -> {
              if (!"openDialer".equals(call.method)) {
                result.notImplemented();
                return;
              }
              if (!(call.arguments instanceof String)
                  || !((String) call.arguments).matches("\\+?[0-9]{7,15}")) {
                result.error("INVALID_NUMBER", "유효한 담당자 전화번호가 필요합니다.", null);
                return;
              }
              String number = (String) call.arguments;
              try {
                // 번호만 표시하며 통화는 사용자가 전화 앱에서 직접 시작한다.
                startActivity(new Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", number, null)));
                result.success(null);
              } catch (ActivityNotFoundException | SecurityException e) {
                result.error("DIALER_UNAVAILABLE", "전화 앱을 열 수 없습니다.", null);
              }
            });
  }
}
