import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_provider.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Merhaba! Keskin Asistan detaylı analiz moduna geçti. 👷‍♂️\nLütfen incelemek istediğiniz periyodu (Aylık/Yıllık) üst panelden seçip aşağıdan dilediğiniz analiz raporunu isteyin.", 
      isUser: false
    )
  ];
  final ScrollController _scrollController = ScrollController();
  bool _isMonthly = true;

  final List<String> _questions = [
    "Durum Özeti",
    "En Büyük Gider",
    "En Büyük Gelir",
    "En Çok Harcanan Kategori",
    "Son İşlemler"
  ];

  void _sendSelectedQuestion(String query) {
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final response = context.read<AppProvider>().getBotResponse(query, isMonthly: _isMonthly);
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
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

  Widget _buildRichText(String text, bool isUser) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 15, height: 1.4),
      );
    }

    // HTML formatındaki <g> .. </g> ve <r> .. </r> parse ediliyor
    final RegExp exp = RegExp(r'<([gr])>(.*?)</\1>');
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: const TextStyle(color: Colors.white, height: 1.4)));
      }
      final color = match.group(1) == 'g' ? AppTheme.incomeColor : AppTheme.expenseColor;
      spans.add(TextSpan(text: match.group(2), style: TextStyle(color: color, fontWeight: FontWeight.bold, height: 1.4)));
      start = match.end;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: const TextStyle(color: Colors.white, height: 1.4)));
    }
    
    return RichText(text: TextSpan(children: spans, style: const TextStyle(fontSize: 15)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keskin Asistan'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(50))
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isMonthly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isMonthly ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text("Aylık", style: TextStyle(color: _isMonthly ? Colors.black : Colors.white, fontWeight: _isMonthly ? FontWeight.bold : FontWeight.w500)),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _isMonthly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_isMonthly ? AppTheme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text("Yıllık", style: TextStyle(color: !_isMonthly ? Colors.black : Colors.white, fontWeight: !_isMonthly ? FontWeight.bold : FontWeight.w500)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.isUser;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                      border: isUser ? null : Border.all(color: AppTheme.primaryColor.withAlpha(50)),
                    ),
                    child: _buildRichText(msg.text, isUser),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 15, offset: const Offset(0, -5))
              ]
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: _questions.map((q) {
                      return ActionChip(
                        backgroundColor: AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppTheme.primaryColor.withAlpha(100), width: 1.5)
                        ),
                        label: Text(
                          q,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        onPressed: () => _sendSelectedQuestion(q),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
