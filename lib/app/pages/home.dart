import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dart_openai/dart_openai.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';
  String _response = '';
  String _selectedLocale = "ja-JP"; // Use locale as identifier

  // List of available voices
  final List<Map<String, String>> _voices = [
    {"name": "Microsoft David - English (United States)", "locale": "en-US"},
    {"name": "Microsoft Mark - English (United States)", "locale": "en-US"},
    {"name": "Microsoft Zira - English (United States)", "locale": "en-US"},
    {"name": "Microsoft Pattara - Thai (Thailand)", "locale": "th-TH"},
    {"name": "Google Deutsch", "locale": "de-DE"},
    {"name": "Google US English", "locale": "en-US"},
    {"name": "Google UK English Female", "locale": "en-GB"},
    {"name": "Google UK English Male", "locale": "en-GB"},
    {"name": "Google español", "locale": "es-ES"},
    {"name": "Google español de Estados Unidos", "locale": "es-US"},
    {"name": "Google français", "locale": "fr-FR"},
    {"name": "Google हिन्दी", "locale": "hi-IN"},
    {"name": "Google Bahasa Indonesia", "locale": "id-ID"},
    {"name": "Google italiano", "locale": "it-IT"},
    {"name": "Google 日本語", "locale": "ja-JP"},
    {"name": "Google 한국의", "locale": "ko-KR"},
    {"name": "Google Nederlands", "locale": "nl-NL"},
    {"name": "Google polski", "locale": "pl-PL"},
    {"name": "Google português do Brasil", "locale": "pt-BR"},
    {"name": "Google русский", "locale": "ru-RU"},
    {"name": "Google 普通话（中国大陆）", "locale": "zh-CN"},
    {"name": "Google 粤語（香港）", "locale": "zh-HK"},
    {"name": "Google 國語（臺灣）", "locale": "zh-TW"}
  ];

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setPitch(1.0);
    _flutterTts.setVoice(
        {"name": "Google 日本語", "locale": "ja-JP"}); // Update to use locale
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) async {
        setState(() {
          _text = result.recognizedWords;
        });

        print(result);

        if (result.hasConfidenceRating && result.confidence > 0) {
          _stopListening(); // Stop listening after sending the message
        }
      });
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
    await _sendMessageToAI(_text);
  }

  Future<void> _sendMessageToAI(String message) async {
    try {
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "return any message you are given as JSON.",
          ),
        ],
        role: OpenAIChatMessageRole.assistant,
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            message,
          ),
        ],
        role: OpenAIChatMessageRole.user,
      );

      final requestMessages = [systemMessage, userMessage];

      final chatCompletion = await OpenAI.instance.chat.create(
        model: "cosmosrp",
        messages: requestMessages,
        temperature: 0.2,
        maxTokens: 500,
      );

      final aiResponse = chatCompletion.choices.first.message.content;

      setState(() {
        _response = aiResponse?.first.text as String;
      });

      print(await _flutterTts.getVoices);

      await _flutterTts.speak(_response);
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  void _handleTextInput() async {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      _controller.clear();
      await _sendMessageToAI(message);
    }
  }

  Future<void> _handleVoiceChange(String selectedLocale) async {
    final selectedVoice =
        _voices.firstWhere((voice) => voice['locale'] == selectedLocale);
    setState(() {
      _selectedLocale = selectedLocale;
      _flutterTts.setVoice(selectedVoice); // Update the voice for TTS
    });

    await _flutterTts.speak("Hi");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice AI Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text('You: $_text'),
                  ),
                  ListTile(
                    title: Text('AI: $_response'),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: _selectedLocale,
              items: _voices.map((voice) {
                return DropdownMenuItem<String>(
                  value: voice['locale'],
                  child: Text(voice['name'] ?? 'Unknown Voice'),
                );
              }).toList(),
              onChanged: (selectedLocale) {
                if (selectedLocale != null) {
                  _handleVoiceChange(selectedLocale);
                }
              },
            ),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type your message",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleTextInput,
                ),
              ),
              onSubmitted: (value) => _handleTextInput(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
