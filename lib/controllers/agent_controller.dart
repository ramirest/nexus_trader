import 'dart:io';
import 'package:flutter/material.dart'; // Added for GlobalKey
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/vision_service.dart';
import '../services/gemini_vision_service.dart';

enum AgentStatus { idle, analyzing, trading }

class AgentController extends ChangeNotifier {
  WebViewController? _webViewController;
  // GlobalKey? _repaintBoundaryKey; // Replaced by Native Capture
  AgentStatus _status = AgentStatus.idle;

  // Trade Cooldown
  DateTime? _lastTradeTime;
  final Duration _tradeCooldown = const Duration(minutes: 1);
  String _currentUrl = "https://app.trexbroker.com";
  bool _isDemoAccount = true;

  // Chat History
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Services & State
  late final VisionService _visionService;
  bool _isAnalysisRunning = false;

  // Risk Management
  double _initialBalance = 0.0;
  double _currentBalance = 0.0;
  double _stopLossLimit = 0.0; // Configured by user
  double _stopWinLimit = 0.0;

  // Getters
  AgentStatus get status => _status;
  String get currentUrl => _currentUrl;
  bool get isDemoAccount => _isDemoAccount;
  bool get isAnalysisRunning => _isAnalysisRunning; // Fixed getter name

  AgentController() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-pro-vision';

    if (apiKey.isNotEmpty) {
      _visionService = GeminiVisionService(apiKey, modelName: modelName);
      print("NexusAgent: Vision Service Initialized with Gemini ($modelName)");
    } else {
      _visionService = MockVisionService();
      _visionService = MockVisionService();
      print("NexusAgent: No API Key found, using Mock Vision Service");
    }

    // Initial Greeting
    addMessage("Orchestrator",
        "Agent system initialized. Waiting for commands...", MessageType.info);
  }

  // --- CHAT ACTIONS ---

  void addMessage(String sender, String text, MessageType type) {
    _messages.add(ChatMessage(
        sender: sender, text: text, timestamp: DateTime.now(), type: type));
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Setters
  void setWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  // void setRepaintBoundaryKey(GlobalKey key) {
  //   _repaintBoundaryKey = key;
  // }

  void setUrl(String url) {
    _currentUrl = url;
    _webViewController?.loadRequest(Uri.parse(url));
    notifyListeners();
  }

  // --- TRADING ACTIONS ---

  Future<void> executeCall() async {
    if (_webViewController == null) return;

    // Cooldown Check
    if (_lastTradeTime != null &&
        DateTime.now().difference(_lastTradeTime!) < _tradeCooldown) {
      addMessage("Risk", "Trade rejected: Cooldown active", MessageType.error);
      return;
    }

    _setStatus(AgentStatus.trading);
    addMessage("Operator", "Executing CALL (BUY) order...", MessageType.trade);
    _lastTradeTime = DateTime.now();

    // Simulate Human Click on BUY button
    const js = """
      (function() {
        const btn = document.querySelector('.buy-button');
        if (btn) {
          const events = ['mousedown', 'mouseup', 'click'];
          events.forEach(eventType => {
            const event = new MouseEvent(eventType, {
              view: window,
              bubbles: true,
              cancelable: true,
              buttons: 1
            });
            btn.dispatchEvent(event);
          });
          console.log('NexusAgent: Executed CALL');
        } else {
          console.error('NexusAgent: Buy button not found');
        }
      })();
    """;

    await _webViewController?.runJavaScript(js);
    await Future.delayed(const Duration(milliseconds: 500)); // Cool down
    _setStatus(AgentStatus.idle);
  }

  Future<void> executePut() async {
    if (_webViewController == null) return;

    // Cooldown Check
    if (_lastTradeTime != null &&
        DateTime.now().difference(_lastTradeTime!) < _tradeCooldown) {
      addMessage("Risk", "Trade rejected: Cooldown active", MessageType.error);
      return;
    }

    _setStatus(AgentStatus.trading);
    addMessage("Operator", "Executing PUT (SELL) order...", MessageType.trade);
    _lastTradeTime = DateTime.now();

    const js = """
      (function() {
        const btn = document.querySelector('.sell-button');
        if (btn) {
             const events = ['mousedown', 'mouseup', 'click'];
          events.forEach(eventType => {
            const event = new MouseEvent(eventType, {
              view: window,
              bubbles: true,
              cancelable: true,
              buttons: 1
            });
            btn.dispatchEvent(event);
          });
          console.log('NexusAgent: Executed PUT');
        } else {
          console.error('NexusAgent: Sell button not found');
        }
      })();
    """;

    await _webViewController?.runJavaScript(js);
    await Future.delayed(const Duration(milliseconds: 500));
    _setStatus(AgentStatus.idle);
  }

  // --- ACCOUNT SWITCHER ---

  Future<void> switchAccount(bool toDemo) async {
    if (_webViewController == null) return;

    const openMenuSelector = '.balance-info';
    const demoOptionSelector = '.account-type-demo';
    const realOptionSelector = '.account-type-real';

    final targetSelector = toDemo ? demoOptionSelector : realOptionSelector;
    final logName = toDemo ? "DEMO" : "REAL";

    final js = """
      (function() {
        console.log('NexusAgent: Switching to $logName...');
        const menuBtn = document.querySelector('$openMenuSelector');
        if (menuBtn) {
          menuBtn.click();
          setTimeout(() => {
            const optionBtn = document.querySelector('$targetSelector');
            if (optionBtn) {
              optionBtn.click();
              console.log('NexusAgent: Clicked $logName option');
            } else {
              console.error('NexusAgent: Option $logName not found');
            }
          }, 300);
        } else {
          console.error('NexusAgent: Account Menu not found');
        }
      })();
    """;

    await _webViewController?.runJavaScript(js);
    _isDemoAccount = toDemo;
    notifyListeners();
  }

  // --- ANALYST AGENT LOOP ---

  void toggleAnalysis() {
    if (_isAnalysisRunning) {
      _stopAnalysis();
    } else {
      _startAnalysis();
    }
  }

  void _startAnalysis() {
    _isAnalysisRunning = true;
    _setStatus(AgentStatus.analyzing);
    _analysisLoop();
    notifyListeners();
  }

  void _stopAnalysis() {
    _isAnalysisRunning = false;
    _setStatus(AgentStatus.idle);
    notifyListeners();
  }

  Future<void> _analysisLoop() async {
    while (_isAnalysisRunning) {
      if (_status == AgentStatus.trading) {
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }

      try {
        // 1. Risk Check
        await _updateBalance();
        if (await _checkRisk()) {
          _stopAnalysis();
          print("NexusAgent: Risk Limit Hit. Stopping.");
          break; // Stop loop
        }

        // 2. Vision Analysis
        addMessage("Analyst", "Capturing market data...", MessageType.info);
        final image = await _captureScreen(); // Use internal capture

        if (image != null) {
          final result = await _visionService.analyzeScreenshot(image);
          addMessage("Analyst", result.reasoning, MessageType.analysis);

          if (result.signal == SignalType.buy) {
            addMessage("Orchestrator", "Signal Confirmed: CALL. Executing...",
                MessageType.trade);
            await executeCall();
          } else if (result.signal == SignalType.sell) {
            addMessage("Orchestrator", "Signal Confirmed: PUT. Executing...",
                MessageType.trade);
            await executePut();
          } else {
            addMessage(
                "Orchestrator",
                "Holding position. Waiting for better setup.",
                MessageType.info);
          }
        } else {
          addMessage(
              "System", "Error: Screen capture failed.", MessageType.error);
        }
      } catch (e) {
        print("NexusAgent: Analysis Error: $e");
      }

      if (!_isAnalysisRunning) break;
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  // --- RISK MANAGEMENT ---

  Future<void> _updateBalance() async {
    if (_webViewController == null) return;
    try {
      // Selector based on typical broker UI (needs verification by user)
      const js = "document.querySelector('.balance-value')?.innerText || '0'";
      final result =
          await _webViewController!.runJavaScriptReturningResult(js) as String;

      // Cleanup: "$10,000.00" -> 10000.00
      String clean = result.replaceAll(RegExp(r'[^0-9.]'), '');
      if (clean.isNotEmpty) {
        double val = double.tryParse(clean) ?? 0.0;
        if (val > 0) {
          _currentBalance = val;
          if (_initialBalance == 0) _initialBalance = _currentBalance;
          // notifyListeners(); // Optional: update UI if displaying live balance
        }
      }
    } catch (e) {
      // Likely JS return type mismatch or element not found
      // print("NexusAgent: Error reading balance: $e");
    }
  }

  bool _checkRisk() {
    if (_initialBalance == 0) return false;

    double profit = _currentBalance - _initialBalance;

    // Stop Loss Check (e.g., if profit is -50 and limit is 50)
    if (_stopLossLimit > 0 && profit <= -_stopLossLimit) {
      print("NexusAgent: STOP LOSS TRIGGERED! Profit: $profit");
      return true;
    }

    // Stop Win Check
    if (_stopWinLimit > 0 && profit >= _stopWinLimit) {
      print("NexusAgent: STOP WIN TRIGGERED! Profit: $profit");
      return true;
    }

    return false;
  }

  void setRiskLimits(double stopLoss, double stopWin) {
    _stopLossLimit = stopLoss;
    _stopWinLimit = stopWin;
    print("NexusAgent: Risk Limits Set (SL: $stopLoss, SW: $stopWin)");
    notifyListeners();
  }

  // --- UTILS ---

  void toggleStatus() {
    toggleAnalysis();
  }

  void _setStatus(AgentStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
  // --- CAPTURE LOGIC ---

  Future<Uint8List?> _captureScreen() async {
    // METHOD: Native macOS Capture (Screencapture CLI)
    // This captures the main screen. It ensures WYSIWYG.
    try {
      final tempDir = Directory.systemTemp;
      final tempPath =
          '${tempDir.path}/nexus_capture_${DateTime.now().millisecondsSinceEpoch}.png';

      // -x: No sound, -m: Main monitor, -t png: Format
      // We use -m to capture the main monitor where the app is likely running.
      final result = await Process.run(
          'screencapture', ['-x', '-m', '-t', 'png', tempPath]);

      if (result.exitCode == 0) {
        final file = File(tempPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await file.delete(); // Cleanup
          // print("NexusAgent: Native Capture Success (${bytes.lengthInBytes} bytes)");
          return bytes;
        } else {
          addMessage("System", "Capture Error: File not found at $tempPath",
              MessageType.error);
        }
      } else {
        print("NexusAgent: Native Capture Failed: ${result.stderr}");
        addMessage(
            "System",
            "Capture Failed (Exit Code ${result.exitCode}): ${result.stderr}",
            MessageType.error);
      }
    } catch (e) {
      print("NexusAgent: Native Capture Error: $e");
      addMessage("System", "Capture Exception: $e", MessageType.error);
    }
    return null;
  }

  // --- SYSTEM CHECK ---

  Future<void> runSystemCheck() async {
    print("NexusAgent: Running System Check...");

    // 1. Check Vision API
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    print(
        "CHECK: Vision API Key Present? ${apiKey != null && apiKey.isNotEmpty}");

    // 2. Check Capture
    final img = await _captureScreen();
    print("CHECK: Screen Capture Working? ${img != null && img.isNotEmpty}");

    // 3. Check Selectors (Dry Run)
    if (_webViewController != null) {
      // Evaluate if buttons exist
      final buyBtn = await _webViewController!.runJavaScriptReturningResult(
          "document.querySelector('.buy-button') != null");
      print("CHECK: Buy Button Found? $buyBtn");

      final sellBtn = await _webViewController!.runJavaScriptReturningResult(
          "document.querySelector('.sell-button') != null");
      print("CHECK: Sell Button Found? $sellBtn");
    }

    print("NexusAgent: System Check Complete.");
    addMessage(
        "System",
        "System Check Complete. Vision: ${apiKey != null}, Capture: ${img != null}",
        MessageType.info);
  }
}

enum MessageType { info, analysis, trade, error }

class ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.type,
  });
}
