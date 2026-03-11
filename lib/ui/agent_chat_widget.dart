import 'package:flutter/material.dart';
import 'package:nexus_trader/controllers/agent_controller.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AgentChatWidget extends StatefulWidget {
  final AgentController controller;

  const AgentChatWidget({super.key, required this.controller});

  @override
  State<AgentChatWidget> createState() => _AgentChatWidgetState();
}

class _AgentChatWidgetState extends State<AgentChatWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Scroll only if user is near bottom or if it's a new message
      // For simplicity, auto-scroll always for now
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border:
            Border(top: BorderSide(color: Colors.green.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("LIVE AGENT FEED",
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () {
                    // This could collapse the widget if implemented
                  },
                ),
              ],
            ),
          ),

          // Chat List
          Expanded(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                final messages = widget.controller.messages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageItem(msg);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    Color color;
    IconData icon;

    switch (msg.type) {
      case MessageType.analysis:
        color = Colors.blueAccent;
        icon = Icons.analytics;
        break;
      case MessageType.trade:
        color = Colors.greenAccent;
        icon = Icons.attach_money;
        break;
      case MessageType.error:
        color = Colors.redAccent;
        icon = Icons.error_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${msg.sender} • ${_formatTime(msg.timestamp)}",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  msg.type == MessageType.analysis
                      ? MarkdownBody(
                          data: msg.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            strong: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                            tableBody: const TextStyle(color: Colors.white70),
                            tableHead: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : Text(
                          msg.text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }
}
