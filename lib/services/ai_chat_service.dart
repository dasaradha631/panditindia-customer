import '../core/network/api_client.dart';

/// One chat turn handed to [AiChatService.queryVedicAI] — the mobile shape of
/// the web widget's `{ sender, text }` message objects.
class AiChatTurn {
  const AiChatTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

/// Mobile counterpart of the web `frontend/src/services/aiChatService.js`
/// `queryVedicAI()` (line 427).
///
/// Posts the exact payload the web client sends — same `POST`
/// `/v1/chat/completions` path, same JSON headers
/// (`Content-Type: application/json`, `Authorization: Bearer …`) and the same
/// body (`model`, `messages`, `temperature`, `max_tokens`) — through
/// [ApiClient] so the request rides the shared `https://api.panditindia.com`
/// base URL with the app's bearer token and the standard request timeout.
///
/// Returns `null` whenever the call errors, times out or comes back empty so
/// callers can fall back to their local auto-reply engine, exactly like the
/// web widget falls back to `getLocalAutoReply()` (line 337).
class AiChatService {
  /// OpenAI-style chat completions path. The web client posts to
  /// `https://api.openai.com/v1/chat/completions`; [ApiClient] resolves the
  /// same path against `AppConfig.baseUrl` (`https://api.panditindia.com`).
  static const String path = '/v1/chat/completions';

  static const String model = 'gpt-4o-mini';

  /// Web `SYSTEM_PROMPT` (aiChatService.js line 316) — kept verbatim so both
  /// platforms share one personality, price sheet and helpline number.
  static const String systemPrompt = '''You are "Acharya AI" (VedaGPT), the warm, highly knowledgeable, and respectful Vedic AI Assistant for "PanditIndia" (India's #1 verified platform for Vedic Ceremonies, Pujas, Hawans, and Shubh Muhurat consultations).

Your traits:
1. Tone: Respectful, serene, traditional yet modern, empathetic, polite (use "Namaste 🙏", "Om Shanti", "Shubham Bhavatu" appropriately).
2. Expertise: Deep knowledge of Hindu Vedic rituals, Shastras, Samagri, Muhurats, Mantras, and cultural nuances across North and South India.
3. Accurate Platform Knowledge:
   - Griha Pravesh & Vastu Shanti: ₹5,100 (3.5-4 hrs)
   - Sri Satyanarayana Swamy Vratam: ₹3,500 (2.5 hrs)
   - Maha Rudrabhishekam: ₹4,200 (3 hrs)
   - Maha Ganapathi Homam: ₹3,800 (2.5 hrs)
   - Navachandi Mahayajnam: ₹11,000 (5-6 hrs, 3 scholars)
   - Vedic Vivah Samskara: ₹15,500 (Full day / Custom)
   - Special Vastu Dosha Nivarana Yajna: ₹6,500 (4.5 hrs)
   - Samagri Kits: Premium Sealed Eco-Kit (₹1,500), Standard Kit (₹900), or Devotee Arranges (₹0).
   - Languages: Hindi, Telugu, Tamil, Kannada, Marathi, Bengali, Gujarati, Odia, Malayalam, English.
   - Toll-free Helpline: 1800-890-VEDA (8334), WhatsApp: +91 98765 43210.
4. Formatting: Keep responses crisp, clear, well-formatted using markdown bullet points and emojis. Avoid overly long walls of text. Always invite the devotee to book or request an Acharya callback if needed.''';

  /// Calls the endpoint behind the web `queryVedicAI` and returns the reply
  /// text, or `null` on error/timeout so the caller can use its local
  /// fallback (the web client does the same with `getLocalAutoReply`).
  Future<String?> queryVedicAI(
    String message, {
    List<AiChatTurn> history = const [],
  }) async {
    final text = message.trim();
    if (text.isEmpty) return null;
    try {
      // Web keeps only the latest six turns: `conversationHistory.slice(-6)`.
      final recent = history.length > 6
          ? history.sublist(history.length - 6)
          : history;
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        for (final turn in recent)
          {
            'role': turn.fromUser ? 'user' : 'assistant',
            'content': turn.text,
          },
        {'role': 'user', 'content': text},
      ];
      final res = await ApiClient.post(
        path,
        body: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 350,
        },
      );
      return _extractReply(res.body);
    } catch (_) {
      return null;
    }
  }

  /// Reads `choices[0].message.content` (OpenAI shape, like the web client)
  /// and also tolerates a plain `{ reply: … }` gateway envelope.
  static String? _extractReply(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final choices = body['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final msg = first['message'];
        if (msg is Map && msg['content'] is String) {
          final reply = (msg['content'] as String).trim();
          if (reply.isNotEmpty) return reply;
        }
      }
    }
    for (final key in const ['reply', 'response', 'message']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
