import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:voice_ai_chat/app/pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Set the OpenAI API key and base URL
  OpenAI.baseUrl = 'https://api.pawan.krd/cosmosrp';
  OpenAI.apiKey = 'pk-CrOtYeRkuXpCiOigmlkdxyPJYEROZyONHsPhKDDrTdRuIAvs'; // Set the OpenAI API key
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

