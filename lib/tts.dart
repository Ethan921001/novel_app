import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(NovelReader());

class NovelReader extends StatefulWidget {
  @override
  _NovelReaderState createState() => _NovelReaderState();
}

class _NovelReaderState extends State<NovelReader> {
  late FlutterTts flutterTts;
  final ScrollController _scrollController = ScrollController();
  final Duration scrollDuration = Duration(milliseconds: 600);

  List<String> sentences = [];
  int currentIndex = 0;
  bool isSpeaking = false;

  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  String selectedLanguage = 'zh-CN';

  final List<Map<String, String>> languages = [
    {'label': '中文（普通話）', 'value': 'zh-CN'},
    {'label': '粵語（廣東話）', 'value': 'yue-HK'}, // 若不支援 yue-HK，可改 zh-HK
  ];

  final String novelContent = '''
第一章：蒼雲古城。

在遙遠的東方，有一座名為蒼雲的古老山城。
晨曦照耀下的青石板路，藏著無數故事的回聲。
少年扶劍而行，尋找失落已久的真相。
他名為風凌，一位孤兒，卻天資卓絕。
當年一場大火奪去了他所有的記憶，也燃起了他尋根的決心。
''';

  @override
  void initState() {
    super.initState();
    initTts();
    splitTextIntoSentences(novelContent);
  }

  void splitTextIntoSentences(String text) {
    final pattern = RegExp(r'(?<=[。！？\n])'); // 中文標點分句
    sentences = text.split(pattern).where((s) => s.trim().isNotEmpty).toList();
  }

  Future<void> initTts() async {
    flutterTts = FlutterTts();

    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setCompletionHandler(() async {
      if (!mounted) return;
      if (isSpeaking && currentIndex < sentences.length - 1) {
        setState(() {
          currentIndex++;
        });
        await scrollToCurrent();
        await speakCurrent();
      } else {
        setState(() {
          isSpeaking = false;
        });
      }
    });

    flutterTts.setErrorHandler((msg) {
      print("TTS error: $msg");
      setState(() {
        isSpeaking = false;
      });
    });
  }

  Future<void> scrollToCurrent() async {
    final position = currentIndex * 70.0;
    await _scrollController.animateTo(
      position,
      duration: scrollDuration,
      curve: Curves.easeInOut,
    );
  }

  Future<void> speakCurrent() async {
    await flutterTts.speak(sentences[currentIndex]);
  }

  Future<void> startSpeaking() async {
    if (sentences.isEmpty) return;
    setState(() {
      currentIndex = 0;
      isSpeaking = true;
    });
    await scrollToCurrent();
    await speakCurrent();
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();
    setState(() {
      isSpeaking = false;
    });
  }

  Future<void> pauseSpeaking() async {
    await flutterTts.pause();
    setState(() {
      isSpeaking = false;
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("小說朗讀（自動滾動）")),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: sentences.length,
                itemBuilder: (context, index) {
                  final isActive = index == currentIndex;
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      sentences[index],
                      style: TextStyle(
                        fontSize: 18,
                        color: isActive ? Colors.blue : Colors.black87,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildLanguageSelector(),
            _buildControlButtons(),
            _buildSliders(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _iconButton(Icons.play_arrow, "播放", Colors.green, startSpeaking),
          _iconButton(Icons.pause, "暫停", Colors.orange, pauseSpeaking),
          _iconButton(Icons.stop, "停止", Colors.red, stopSpeaking),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String label, Color color, Function func) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          iconSize: 32,
          onPressed: () => func(),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [
        Slider(
          value: volume,
          onChanged: (val) {
            setState(() => volume = val);
            flutterTts.setVolume(val);
          },
          min: 0.0,
          max: 1.0,
          label: "音量: ${volume.toStringAsFixed(1)}",
        ),
        Slider(
          value: pitch,
          onChanged: (val) {
            setState(() => pitch = val);
            flutterTts.setPitch(val);
          },
          min: 0.5,
          max: 2.0,
          label: "音調: ${pitch.toStringAsFixed(1)}",
        ),
        Slider(
          value: rate,
          onChanged: (val) {
            setState(() => rate = val);
            flutterTts.setSpeechRate(val);
          },
          min: 0.0,
          max: 1.0,
          label: "語速: ${rate.toStringAsFixed(1)}",
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("語言："),
          DropdownButton<String>(
            value: selectedLanguage,
            items: languages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang['value'],
                child: Text(lang['label']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedLanguage = value;
                });
                flutterTts.setLanguage(selectedLanguage);
              }
            },
          ),
        ],
      ),
    );
  }
}
