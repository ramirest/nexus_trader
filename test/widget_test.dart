import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:nexus_trader/main.dart';

class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    return MockWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params) {
    return MockPlatformNavigationDelegate(params);
  }
  
  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
      PlatformWebViewWidgetCreationParams params) {
    return MockPlatformWebViewWidget(params);
  }
}

class MockWebViewController extends PlatformWebViewController {
  MockWebViewController(PlatformWebViewControllerCreationParams params) : super.implementation(params);
  
  @override 
  Future<void> loadRequest(LoadRequestParams params) async {}
  
  @override 
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}
}

class MockPlatformNavigationDelegate extends PlatformNavigationDelegate {
  MockPlatformNavigationDelegate(PlatformNavigationDelegateCreationParams params) : super.implementation(params);

  @override
  Future<void> setOnPageStarted(void Function(String url) onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(void Function(String url) onPageFinished) async {}

  @override
  Future<void> setOnWebResourceError(void Function(WebResourceError error) onWebResourceError) async {}
}

class MockPlatformWebViewWidget extends PlatformWebViewWidget {
  MockPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) : super.implementation(params);
  @override Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('NexusTraderApp smoke test', (WidgetTester tester) async {
    dotenv.testLoad(fileInput: '''
GEMINI_API_KEY=dummy_key
GEMINI_MODEL=gemini-pro-vision
''');

    WebViewPlatform.instance = MockWebViewPlatform();

    await tester.pumpWidget(const NexusTraderApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
