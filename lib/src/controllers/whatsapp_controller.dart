import 'dart:io';

import 'package:flint_dart/flint_dart.dart';
import 'dart:convert';
import '../services/whatsapp_pricing_service.dart';
import '../services/whatsapp_support_service.dart';
import '../services/whatsapp_contact_service.dart';
import '../services/whatsapp_welcome_service.dart';

class WhatsappController {
  // ✅ FlintClient acts like `http` but with better handling
  final client = FlintClient(baseUrl: "https://graph.facebook.com/v22.0/");

  // ✅ Gemini AI endpoint (replace with your API proxy or Gemini API endpoint)
  final aiClient = FlintClient(
      baseUrl:
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent");

  final pricingService = WhatsappPricingService();
  final supportService = WhatsappSupportService();
  final contactService = WhatsappContactService();
  final welcomeService = WhatsappWelcomeService();

  // ✅ Environment values
  final String verifyToken = FlintEnv.get('WHATSAPP_VERIFY_TOKEN');
  final String phoneNumberId = FlintEnv.get('WHATSAPP_PHONE_NUMBER_ID');
  final String accessToken = FlintEnv.get('WHATSAPP_ACCESS_TOKEN');
  final String geminiApiKey = FlintEnv.get('GEMINI_API_KEY');

  // 🔹 Webhook verification for WhatsApp Cloud API
  Future<Response> verifyWebhook(Request req, Response res) async {
    print("🌍 [Webhook] Verification request received.");
    final mode = req.query['hub.mode'];
    final challenge = req.query['hub.challenge'];
    final token = req.query['hub.verify_token'];

    if (mode == 'subscribe' && token == verifyToken) {
      print("✅ Webhook verified successfully!");
      return res.send(challenge ?? '');
    } else {
      print("❌ Webhook verification failed!");
      return res.status(403).send("Verification failed");
    }
  }

  // 🔹 Receive WhatsApp messages from Meta webhook
  Future<Response> receiveMessage(Request req, Response res) async {
    print("📨 [Webhook] POST / received");
    final body = await req.json();
    print("🧾 Incoming body: ${jsonEncode(body)}");

    if (body != null && body['entry'] != null) {
      final entry = body['entry'][0];
      final changes = entry['changes'][0];
      final messages = changes['value']['messages'];

      if (messages != null) {
        final msg = messages[0];
        final from = msg['from'];
        final text = msg['text']?['body']?.trim() ?? '';

        print("📩 Message from $from: $text");

        final reply = await _generateReply(text);
        print("🤖 Generated reply: $reply");

        await sendMessage(from, reply);
      } else {
        print("⚠️ No message field in webhook payload.");
      }
    } else {
      print("⚠️ Invalid webhook payload: no entry field found.");
    }

    return res.json({'status': 'received'});
  }

  // 🔹 Reply router — directs messages to proper service or Gemini AI
  Future<String> _generateReply(String message) async {
    final lower = message.toLowerCase();

    switch (lower) {
      case "hi":
      case "hello":
      case "menu":
      case "hey":
      case "hy":
        return welcomeService.getReply();
      case "1":
      case "pricing":
        return pricingService.getReply();
      case "2":
      case "support":
        return supportService.getReply();
      case "3":
      case "contact":
        return contactService.getReply();
      default:
        // 🚀 Use Gemini AI for other queries
        final aiReply = await _askGemini(message);
        return aiReply ??
            "🤖 I didn’t understand that. Please reply with:\n1. Pricing\n2. Support\n3. Contact Info";
    }
  }

  // 🔹 Ask Gemini AI
  Future<String?> _askGemini(String prompt) async {
    try {
      final context = await File('data/eulogia_docs.md').readAsString();

      final response = await aiClient.post(
        "?key=$geminiApiKey",
        headers: {"Content-Type": "application/json"},
        body: {
          "contents": [
            {
              "parts": [
                {
                  "text":
                      """You are Eulogia Technologies' AI assistant. Reply short, friendly, and professional. 
Answer only questions related to Eulogia Technologies, EuCloudHost, Euvate, SchoolHQ.ng, Training Class, and Flint Dart.
If asked about issues or help, suggest contacting support@eulogia.net or hello@eulogia.net.
User said: "$prompt"."""
                }
              ]
            }
          ]
        },
      );

      final data = response.data;
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      return text?.trim();
    } catch (e) {
      print("❌ Gemini AI error: $e");
      return null;
    }
  }

  // 🔹 Send message using FlintClient (Meta WhatsApp Cloud API)
  Future<void> sendMessage(String to, String message) async {
    final endpoint = "$phoneNumberId/messages";
    print("🚀 Sending message to $to via endpoint: $endpoint");

    final safeMessage = message.replaceAll('\r', '').replaceAll('₦', 'NGN');

    final payload = {
      "messaging_product": "whatsapp",
      "to": to,
      "type": "text",
      "text": {"body": safeMessage},
    };

    try {
      final response = await client.post(
        endpoint,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
            "⚠️ Failed to send message: ${response.statusCode} - ${response.error}");
      } else {
        print("✅ Message successfully sent to $to");
      }
    } catch (e) {
      print("❌ Error sending WhatsApp message: $e");
    }
  }
}
