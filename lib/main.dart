import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dart_openai/dart_openai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Set the OpenAI API key and base URL
  OpenAI.baseUrl = 'https://api.pawan.krd';
  OpenAI.apiKey = 'your api key'; // Set the OpenAI API key
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice AI Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setPitch(1.0);
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) async {
        setState(() {
          _text = result.recognizedWords;
        });

        if (result.hasConfidenceRating && result.confidence > 0) {
          await _sendMessageToAI(_text);
          _stopListening(); // Stop listening after sending the message
        }
      });
    }
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
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
        model: "gpt-3.5-turbo",
        messages: requestMessages,
        temperature: 0.2,
        maxTokens: 500,
      );

      final aiResponse = chatCompletion.choices.first.message.content;
      setState(() {
        _response = aiResponse as String;
      });
      await _flutterTts.speak(_response);
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice AI Chat'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
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
