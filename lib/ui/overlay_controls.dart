import 'package:flutter/material.dart';

import '../controllers/agent_controller.dart';
import 'agent_chat_widget.dart';

class OverlayControls extends StatelessWidget {
  final AgentController controller;

  const OverlayControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: Stack(
        children: [
          // 1. Top Status Badge & Account Switcher
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(),
                const SizedBox(height: 10),
                _buildAccountToggle(),
              ],
            ),
          ),

          // 3. Chat Interface (Bottom Panel)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: AgentChatWidget(controller: controller),
          ),

          // 4. Floating Controls (Above Chat)
          Positioned(
            bottom: 310, // Above the chat
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPanicButton(),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    switch (controller.status) {
      case AgentStatus.analyzing:
        color = Colors.amber;
        text = "ANALYSING";
        break;
      case AgentStatus.trading:
        color = Colors.green;
        text = "TRADING";
        break;
      default:
        color = Colors.grey;
        text = "IDLE";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAccountToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: controller.isDemoAccount ? Colors.orange : Colors.green,
            width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.isDemoAccount ? "DEMO" : "REAL",
            style: TextStyle(
              color: controller.isDemoAccount ? Colors.orange : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Switch(
            value: !controller.isDemoAccount, // False = Demo, True = Real
            activeColor: Colors.green,
            inactiveThumbColor: Colors.orange,
            inactiveTrackColor: Colors.orange.withOpacity(0.3),
            onChanged: (bool isReal) {
              // Security check or confirmation could go here
              controller.switchAccount(!isReal); // if isReal=true, toDemo=false
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        controller.toggleAnalysis();
      },
      backgroundColor:
          controller.isAnalysisRunning ? Colors.redAccent : Colors.teal,
      icon: Icon(controller.isAnalysisRunning ? Icons.stop : Icons.play_arrow),
      label: Text(controller.isAnalysisRunning ? "STOP AI" : "START AI"),
    );
  }

  Widget _buildActionButtons() {
    // Hidden/Developer controls for testing
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: controller.executeCall,
            tooltip: "Test Call",
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.red),
            onPressed: controller.executePut,
            tooltip: "Test Put",
          ),
          IconButton(
            icon: const Icon(Icons.build, color: Colors.blue),
            onPressed: controller.runSystemCheck,
            tooltip: "System Check",
          ),
        ],
      ),
    );
  }
}

// Helper widget if PointerInterceptor isn't available in your specific env setup yet
class PointerInterceptor extends StatelessWidget {
  final Widget child;
  const PointerInterceptor({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
