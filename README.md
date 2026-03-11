# Nexus Trader

Nexus Trader is an automated Agentic AI Trading application built with Flutter. It integrates a WebView to display and interact with the Trex Broker interface, overlaying a sophisticated Agentic AI architecture to simulate human interactions for automated trading and risk management.

## 🌟 Key Features

The application orchestrates several specialized "Agents" to analyze, execute, and safeguard your trading interactions seamlessly:

### 1. **Agentic AI Architecture**
*   **Orchestrator**: Acts as the central nervous system, managing the application state, coordinating between agents, and maintaining the trading flow.
*   **Analyst (Vision AI)**: Utilizes Google Gemini Vision AI to analyze real-time market data directly from the broker interface. It periodically captures screenshots via native macOS commands, interprets market signals (CALL, PUT, or WAIT), and communicates its reasoning.
*   **Operator**: Simulates human DOM interactions. When a signal is confirmed, the Operator securely executes the trade by injecting JavaScript to trigger `mousedown`, `mouseup`, and `click` events directly on the broker's underlying BUY/SELL buttons, ensuring the interaction is undetectable and smooth.
*   **Risk Guardian**: Constantly monitors the account balance. It prevents devastating losses and guarantees secured profits by strictly enforcing user-defined **Stop Loss** and **Stop Win** limits. It also enforces a strict cooldown period between trades to filter out signal noise.

### 2. **Account Switching & Broker UI Integrations**
*   **Native WebView**: Effortlessly loads your broker platform within a secure Flutter wrapper (defaulting to App Trex Broker).
*   **Demo & Real Account Integrator**: Instantly switch between Demo and Real broker accounts directly from the Nexus overlay. This interacts directly with the broker UI for a seamless transition.

### 3. **Native macOS Image Capture**
*   The application bypasses common WebView capture restrictions by leveraging native macOS `screencapture` CLI tools under the hood. This guarantees it reliably "sees" precisely what you see on your main screen seamlessly.

---

## 🛠 Prerequisites

Currently, the application is highly optimized for the macOS platform due to its reliance on native capture APIs.

*   Flutter SDK (v3.2.0 or newer)
*   macOS operating system
*   A Google Gemini API key (preferably with access to the `gemini-1.5-flash` or `gemini-pro-vision` models)

---

## ⚙️ Configuration & Setup

1.  **Clone the Repository & Install Dependencies:**
    ```bash
    flutter clean
    flutter pub get
    ```

2.  **Environment Variables (`.env`)**
    The app relies on a `.env` file for API keys and configurations. Create a `.env` file in the root directory (using `.env.example` as a template) and add your credentials:

    ```env
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
    GEMINI_MODEL=gemini-1.5-flash

    # Optional: Email Notification Configuration
    SMTP_HOST=smtp.gmail.com
    SMTP_PORT=587
    SMTP_USER=your_email@gmail.com
    SMTP_PASSWORD=your_app_password
    EMAIL_FROM=Nexus Trader <your_email@gmail.com>
    EMAIL_TO=recipient@example.com
    ```

3.  **Run the application locally (macOS target recommended):**
    ```bash
    flutter run -d macos
    ```

---

## 🚀 How to Use Nexus Trader Fully

1.  **Launch the App**: Once launched, Nexus Trader will automatically navigate the WebView to the pre-configured broker platform (`https://app.trexbroker.com`).
2.  **Login Manually**: Securely log into your broker account using the embedded WebView. The AI does not handle your credentials.
3.  **Configure Account Mode**: Use the Nexus overlay to choose your preferred trading environment (**Demo** or **Real**). 
4.  **Set Your Risk Limits**:
    It's critical to configure the Risk Guardian before enabling AI:
    *   Set your **Stop Loss** limit to protect your capital.
    *   Set your **Stop Win** limit to secure your gains.
5.  **Initialize the Analyst AI**: Click the "Analyze" or "Start" button on the overlay UI to awake the Agentic loop.
6.  **Sit Back & Monitor**:
    *   The Analyst will start periodically analyzing the market at configured intervals.
    *   You can read the AI's real-time reasoning and confirmed signals directly in the chat overlay. 
    *   If a Valid `CALL` (Buy) or `PUT` (Sell) signal aligns with your Risk limits, the Operator will automatically interact with the broker on your behalf.
7.  **Auto-Halt Mechanism**: The Orchestrator will automatically halt all analysis and trading activity the moment your Stop Loss or Stop Win limits are reached by the Risk Guardian.
