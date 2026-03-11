import 'dart:typed_data';

/// Interface for the service responsible for capturing the trading screen.
abstract class VisionService {
  /// Analyzes the image to return a trading signal.
  /// This is a mock/stub for now.
  Future<AnalysisResult> analyzeScreenshot(Uint8List image);
}

enum SignalType { buy, sell, wait }

class AnalysisResult {
  final SignalType signal;
  final double confidence;
  final String reasoning;

  AnalysisResult(this.signal, this.confidence, this.reasoning);
}

// Mock Implementation
class MockVisionService implements VisionService {
  @override
  Future<AnalysisResult> analyzeScreenshot(Uint8List image) async {
    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 1500));

    // Randomly return WAIT (90%), BUY (5%), SELL (5%) for testing
    // Or just WAIT for safety
    return AnalysisResult(
        SignalType.wait, 0.0, "Mock Analysis: No pattern found");
  }
}
