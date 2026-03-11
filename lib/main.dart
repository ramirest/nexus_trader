import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'controllers/agent_controller.dart';
import 'ui/overlay_controls.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const NexusTraderApp());
}

class NexusTraderApp extends StatelessWidget {
  const NexusTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Trader',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const TraderScreen(),
    );
  }
}

class TraderScreen extends StatefulWidget {
  const TraderScreen({super.key});

  @override
  State<TraderScreen> createState() => _TraderScreenState();
}

class _TraderScreenState extends State<TraderScreen> {
  late final WebViewController _webViewController;
  final AgentController _agentController = AgentController();
  final TextEditingController _urlController = TextEditingController();
  // final GlobalKey _webViewKey = GlobalKey(); // Removed RepaintBoundary
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _urlController.text = _agentController.currentUrl;

    // Initialize WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Handle url changes
            setState(() => _isLoading = true);
            _urlController.text = url;
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print('Web Resouce Error: ${error.description}');
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_agentController.currentUrl));

    // Bind controller
    _agentController.setWebViewController(_webViewController);
    // _agentController.setRepaintBoundaryKey(_webViewKey); // Native Capture used instead
  }

  void _navigateToUrl() {
    final url = _urlController.text;
    if (url.isNotEmpty) {
      _agentController.setUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Address Bar
            _buildAddressBar(),

            // 2. Main Content (WebView + Overlay)
            Expanded(
              child: Stack(
                children: [
                  // Layer 0: Browser
                  WebViewWidget(controller: _webViewController),

                  /* Native capture handles screenshot now. 
                  RepaintBoundary(
                    key: _webViewKey,
                    child: WebViewWidget(controller: _webViewController),
                  ),
                  */

                  // Layer 1: Loading Screen (Covers WebView)
                  if (_isLoading)
                    Container(
                      color:
                          Colors.black, // Opaque background to hide white flash
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ),
                      ),
                    ),

                  // Layer 2: Agent Interface
                  AnimatedBuilder(
                    animation: _agentController,
                    builder: (context, _) =>
                        OverlayControls(controller: _agentController),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressBar() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Enter URL",
              ),
              onSubmitted: (_) => _navigateToUrl(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _webViewController.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 20),
            onPressed: _navigateToUrl,
          ),
        ],
      ),
    );
  }
}
