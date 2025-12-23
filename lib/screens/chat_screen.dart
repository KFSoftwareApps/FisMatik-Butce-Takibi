import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/usage_guard.dart';
import '../services/supabase_database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upgrade_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final AiService _aiService = AiService();
  final AuthService _authService = AuthService();
  final SupabaseDatabaseService _dbService = SupabaseDatabaseService();
  
  bool _isLoading = false;
  int _dailyCount = 0;
  int _dailyLimit = 0;
  String _userTier = 'standart';
  bool _isTierLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyUsage();
    _loadUserTier();
    _loadMessages();
  }

  Future<void> _loadUserTier() async {
    setState(() => _isTierLoading = true);
    _dbService.getUserTierStream().listen((tier) {
      if (mounted) {
        setState(() {
          _userTier = tier;
          _isTierLoading = false;
        });
      }
    });
  }

  Future<void> _loadDailyUsage() async {
    final usage = await UsageGuard.getDailyUsage(UsageFeature.aiChat);
    if (mounted) {
      setState(() {
        _dailyCount = usage['current'] ?? 0;
        _dailyLimit = usage['limit'] ?? 0;
      });
    }
  }

  bool get _isChatAllowed {
    // Sadece Pro (limitless) ve Aile (limitless_family) kullanabilir
    return _userTier == 'limitless' || _userTier == 'limitless_family';
  }

  bool get _isLimitReached {
    if (!_isChatAllowed) return true; // İzin yoksa limit dolmuş gibi davran
    return _dailyCount >= _dailyLimit;
  }

  Future<void> _loadMessages() async {
    try {
      final userId = _dbService.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true); // Eskiden yeniye

      if (mounted) {
        setState(() {
          _messages.clear();
          for (final item in response) {
            _messages.add({
              'role': item['role'] as String,
              'content': item['content'] as String,
            });
          }
        });
      }
    } catch (e) {
      print("Mesaj geçmişi yükleme hatası: $e");
    }
  }

  Future<void> _saveMessageToDb(String role, String content) async {
    try {
      final userId = _dbService.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('chat_messages').insert({
        'user_id': userId,
        'role': role,
        'content': content,
      });
    } catch (e) {
      print("Mesaj kaydetme hatası: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    // _isChatAllowed kontrolüne gerek yok, zaten true

    // GÜVENLİK: UsageGuard ile kontrol et
    final guardResult = await UsageGuard.checkAndConsume(UsageFeature.aiChat);
    
    if (!guardResult.isAllowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(guardResult.message ?? "Günlük limit aşıldı.")),
        );
      }
      return;
    }

    // Limit kontrolü başarılı, mesajı gönder
    final message = _controller.text;
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
      _controller.clear();
      // UI'da sayacı hemen artır (gerçek artış sunucuda oldu zaten)
      _dailyCount++; 
    });

    // DB'ye kaydet (User)
    _saveMessageToDb('user', message);

    try {
      // Finansal bağlamı al
      final contextData = await _dbService.getFinancialSummary();

      // AI'ya bağlam ile gönder
      final reply = await _aiService.chat(message, context: contextData);
      
      if (reply != null) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });
        // DB'ye kaydet (Assistant)
        await _saveMessageToDb('assistant', reply);
      } else {
        // Hata durumunda hakkı iade et (Opsiyonel, ama kullanıcı dostu olur)
        await UsageGuard.refund(UsageFeature.aiChat);
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Üzgünüm, şu an cevap veremiyorum. Lütfen tekrar dene.'});
          _dailyCount--; // UI'da sayacı geri al
        });
      }
    } catch (e) {
      // Hata durumunda hakkı iade et
      await UsageGuard.refund(UsageFeature.aiChat);
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Bir hata oluştu: $e'});
        _dailyCount--; // UI'da sayacı geri al
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTierLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("AI Finans Asistanı 🤖")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Finans Asistanı 🤖"),
        actions: [
          if (_isChatAllowed)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  "Limit: $_dailyCount/$_dailyLimit",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: !_isChatAllowed
          ? _buildUpgradePrompt()
          : Column(
              children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg['content']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          
          // Input sadece limit dolmadıysa göster
          if (!_isLimitReached)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Finansal bir soru sor...",
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          
          // Limit dolduğunda mesaj göster
          if (_isLimitReached)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Günlük Limit Doldu. Yeni sohbet için 00:00 saatini bekleyin.',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'AI Finans Asistanı',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu özellik sadece Pro üyelerde kullanılabilir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Upgrade ekranına yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpgradeScreen()),
                );
              },
              icon: const Icon(Icons.star),
              label: const Text('Pro\'ya Geç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
