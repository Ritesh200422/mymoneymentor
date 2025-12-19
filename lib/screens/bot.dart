import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// ---------------- RESPONSIVE HELPERS ----------------
double sw(BuildContext context) => MediaQuery.of(context).size.width;
double sh(BuildContext context) => MediaQuery.of(context).size.height;

bool isSmallPhone(BuildContext context) => sw(context) < 360;
bool isPhone(BuildContext context) => sw(context) < 600;
bool isTablet(BuildContext context) => sw(context) >= 600;

/// ---------------------------------------------------

class AdvisorBot extends StatefulWidget {
  const AdvisorBot({super.key});

  @override
  State<AdvisorBot> createState() => _FinanceChatbotState();
}

class _FinanceChatbotState extends State<AdvisorBot>
    with SingleTickerProviderStateMixin {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user', firstName: 'You');
  final _bot = const types.User(id: 'bot', firstName: 'Mentor');

  bool _isSending = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeChat();
  }

  void _initializeChat() {
    final welcomeMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text:
          "👋 Hello! I'm your MyMoneyMentor AI Finance Coach.\n\n"
          "I can help you with budgeting, investing, savings strategies, and more.\n\n"
          "Ask your doubts in simple language and we'll learn step by step. 🚀",
    );

    final suggestionMessage = types.CustomMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch + 100,
      id: const Uuid().v4(),
      metadata: const {
        'type': 'suggestions',
        'items': [
          {'text': 'I am a student, how do I start investing?', 'icon': 0xe80c},
          {'text': 'Explain SIP in simple words.', 'icon': 0xf04b3},
          {'text': 'How can I start saving every month?', 'icon': 0xe850},
          {
            'text': 'What is diversification and why is it important?',
            'icon': 0xe6c4,
          },
          {
            'text': 'Difference between stocks and mutual funds?',
            'icon': 0xe051,
          },
          {'text': 'How do I build an emergency fund?', 'icon': 0xe39d},
        ],
      },
    );

    setState(() {
      _messages.add(welcomeMessage);
      _messages.add(suggestionMessage);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    final text = message.text.trim();
    if (text.isEmpty) return;

    final userMsg = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );

    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });

    final reply = await _getFinanceResponse(text);

    final botMsg = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: reply,
    );

    setState(() {
      _messages.add(botMsg);
      _isSending = false;
    });
  }

  Future<String> _getFinanceResponse(String query) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': query}),
      );

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body)['reply'] ?? 'No reply';
      }
      return "⚠️ Server error ${resp.statusCode}";
    } catch (e) {
      return "❌ Server unreachable";
    }
  }

  /// ---------------- CUSTOM SUGGESTIONS ----------------
  Widget _buildCustomMessage(
    types.CustomMessage message, {
    required int messageWidth,
  }) {
    final meta = message.metadata ?? {};
    if (meta['type'] != 'suggestions') return const SizedBox();

    final items = meta['items'] as List;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: items.map<Widget>((item) {
          return InkWell(
            onTap: () =>
                _handleSendPressed(types.PartialText(text: item['text'])),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: BoxConstraints(maxWidth: sw(context) * 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F2937), Color(0xFF111827)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF22C55E).withOpacity(.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconData(item['icon'], fontFamily: 'MaterialIcons'),
                    size: 16,
                    color: const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item['text'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallPhone(context) ? 12 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ---------------- HEADER ----------------
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF020617).withOpacity(.8),
          border: Border(
            bottom: BorderSide(color: const Color(0xFF22C55E).withOpacity(.2)),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.currency_rupee, color: Color(0xFF22C55E)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MyMoneyMentor",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isPhone(context) ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "AI Financial Advisor • Online",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: isPhone(context) ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: Chat(
                messages: _messages,
                user: _user,
                onSendPressed: _handleSendPressed,
                customMessageBuilder: _buildCustomMessage,
                typingIndicatorOptions: TypingIndicatorOptions(
                  typingUsers: _isSending ? [_bot] : const [],
                ),
                theme: DefaultChatTheme(
                  backgroundColor: Colors.transparent,
                  primaryColor: const Color(0xFF22C55E),
                  secondaryColor: const Color(0xFF1F2937),
                  sentMessageBodyTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: isPhone(context) ? 14 : 15,
                  ),
                  receivedMessageBodyTextStyle: TextStyle(
                    color: Colors.white70,
                    fontSize: isPhone(context) ? 14 : 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
