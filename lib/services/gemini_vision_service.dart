import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'vision_service.dart';

class GeminiVisionService implements VisionService {
  final GenerativeModel _model;

  GeminiVisionService(String apiKey, {String modelName = 'gemini-pro-vision'})
      : _model = GenerativeModel(model: modelName, apiKey: apiKey);

  @override
  Future<AnalysisResult> analyzeScreenshot(Uint8List image) async {
    try {
      final prompt = TextPart("""
Analyze this trading chart image. You are an expert trading analyst.
Determine if I should BUY (Call), SELL (Put), or WAIT.
Return your response in the following structured Markdown format:

Contexto: [Brief description of trend/pattern]

1. Indicadores e Gatilhos
[List observed indicators like EMA, Volume, RSI, Support/Resistance with their current status/values]

2. A Operação
Setup: [Name of the setup, e.g., Breakout, Pullback]
Entrada: [Condition for entry]
Stop Loss (SL): [Price level]
Take Profit (TP): [Price level]

3. Resumo da Entrada
Parâmetro | Valor/Ação
--- | ---
Ativo | [Asset Name]
Direção | [Compra/Venda]
Gatilho | [Trigger]
Risco/Recompensa | [Ratio]

Logic: [Detailed reasoning]
Signal: [BUY, SELL, or WAIT]
""");
      final imagePart = DataPart('image/png', image);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text ?? "";

      // Strict Parsing Logic using Regex
      SignalType signal = SignalType.wait;

      // 1. Sanity Check for invalid image
      final lowerText = text.toLowerCase();
      if (lowerText.contains("image is black") ||
          lowerText.contains("cannot see") ||
          lowerText.contains("image unavailable") ||
          lowerText.contains("error")) {
        return AnalysisResult(
            SignalType.wait, 0.0, "VISION ERROR: Image unusable. $text");
      }

      // 2. Strict Regex for "Signal: BUY" or "Signal: SELL"
      final signalRegex =
          RegExp(r"Signal:\s*(BUY|SELL|WAIT|CALL|PUT)", caseSensitive: false);
      final match = signalRegex.firstMatch(text);

      if (match != null) {
        final captured = match.group(1)?.toUpperCase();
        if (captured == "BUY" || captured == "CALL") {
          signal = SignalType.buy;
        } else if (captured == "SELL" || captured == "PUT") {
          signal = SignalType.sell;
        }
      } else {
        // Fallback: Check if the text explicitly concludes with a decision
        // This prevents "I will not BUY" from triggering a BUY
        if (lowerText.contains("**signal**: buy") ||
            lowerText.contains("**signal**: call")) {
          signal = SignalType.buy;
        } else if (lowerText.contains("**signal**: sell") ||
            lowerText.contains("**signal**: put")) {
          signal = SignalType.sell;
        }
      }

      return AnalysisResult(signal, 0.8, text);
    } catch (e) {
      return AnalysisResult(SignalType.wait, 0.0, "Error: $e");
    }
  }
}
