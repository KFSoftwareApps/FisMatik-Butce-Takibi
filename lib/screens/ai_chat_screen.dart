import 'package:flutter/material.dart';
import 'package:fismatik/core/app_theme.dart';
import 'package:fismatik/services/intelligence_service.dart';
import 'package:fismatik/services/auth_service.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import 'package:fismatik/models/membership_model.dart';
import 'package:fismatik/screens/subscriptions_screen.dart';
import 'package:intl/intl.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final IntelligenceService _intelligenceService = IntelligenceService();
  final SupabaseDatabaseService _dbService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();

  int _usageCount = 0;
  int _usageLimit = 0;
  bool _isUnlimited = false;
  bool _isFamilyTier = false;

  @override
  void initState() {
    super.initState();
    _loadInitialAnalysis();
    _checkLimits();
  }

  Future<void> _checkLimits() async {
    final tier = await _authService.getCurrentTier();
    final count = await _dbService.getAICoachUsageCount();
    
    if (mounted) {
      setState(() {
        _isFamilyTier = tier.id == 'limitless_family';
        _usageLimit = tier.aiMessageLimit;
        _usageCount = count;
        // Eğer limit çok yüksekse (örn: 999999), sınırsız kabul et
        _isUnlimited = _usageLimit > 1000;
      });
    }
  }

  Future<void> _loadInitialAnalysis() async {
    setState(() => _isLoading = true);
    
    // Simulating "thinking" time
    await Future.delayed(const Duration(seconds: 1));

    try {
      final tips = await _intelligenceService.getPersonalizedSavingTips();
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Merhaba! Ben FişMatik AI Finans Koçun. 👋\n\nSenin için harcamalarını analiz ettim:",
            isUser: false,
          ));
          
          for (var tip in tips) {
             _messages.add(ChatMessage(
              text: tip,
              isUser: false,
            ));
          }
           _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Şu an bağlantı kuramıyorum, ama harcamalarını takip etmeye devam et!",
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  void _showLimitExceededDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Limit Doldu"),
        content: const Text(
            "Aylık AI Finans Koçu mesaj kullanım hakkınız dolmuştur.\n\n"
            "Daha fazla hak için Aile paketine geçebilir veya gelecek ayı bekleyebilirsiniz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
          if (_usageLimit < 50) // Aile paketi değilse upgrade öner
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionsScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Yükselt", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    // Limit kontrolü
    if (!_isUnlimited && _usageCount >= _usageLimit) {
      _showLimitExceededDialog();
      return;
    }
    
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Handle AI response
    try {
      final response = await _intelligenceService.getChatResponse(text);
      
      // Refresh count from DB (especially if consumed via Edge Function)
      await _checkLimits();

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
          ));
          _isLoading = false;
        });
         Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Üzgünüm, şu an cevap veremiyorum. Lütfen daha sonra tekrar dene.",
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Finans Koçu",
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (!_isLoading && _usageLimit > 0)
                  Text(
                    _isUnlimited 
                      ? "Sınırsız Erişim" 
                      : (_isFamilyTier ? "Aile Ortak Kalan Hak: ${_usageLimit - _usageCount}" : "Kalan Hak: ${_usageLimit - _usageCount}"),
                    style: TextStyle(
                      color: (_usageLimit - _usageCount) <= 3 ? Colors.red : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textDark,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Bir şeyler sor...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
