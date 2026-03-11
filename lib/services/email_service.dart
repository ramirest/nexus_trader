import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  late final SmtpServer _smtpServer;
  final String _emailTo;
  final String _emailFrom;
  bool _isConfigured = false;

  EmailService()
      : _emailTo = dotenv.env['EMAIL_TO'] ?? '',
        _emailFrom = dotenv.env['EMAIL_FROM'] ?? dotenv.env['SMTP_USER'] ?? '' {
    _init();
  }

  void _init() {
    final host = dotenv.env['SMTP_HOST'] ?? '';
    final username = dotenv.env['SMTP_USER'] ?? '';
    final password = dotenv.env['SMTP_PASSWORD'] ?? '';
    final port = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;

    if (host.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
      _smtpServer = SmtpServer(host,
          username: username,
          password: password,
          port: port,
          ssl: port == 465,
          allowInsecure: port != 465, // Allow insecure for TLS (587)
          ignoreBadCertificate: false);
      _isConfigured = true;
      print("NexusAgent: Email Service Configured ($username)");
    } else {
      print(
          "NexusAgent: Email Service NOT configured (Missing .env variables)");
    }
  }

  Future<void> sendNotification({
    required String subject,
    required String body,
  }) async {
    if (!_isConfigured) {
      print("NexusAgent: Cannot send email (Service not configured)");
      return;
    }

    final message = Message()
      ..from = Address(_emailFrom, 'Nexus Trader Bot')
      ..recipients.add(_emailTo)
      ..subject = subject
      ..text = body
      // Html body optional
      ..html = "<p>${body.replaceAll('\n', '<br>')}</p>";

    try {
      final sendReport = await send(message, _smtpServer);
      print('NexusAgent: Email Sent: ' + sendReport.toString());
    } catch (e) {
      print('NexusAgent: Error sending email: $e');
    }
  }
}
