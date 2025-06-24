import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(NovelReader(basePath: "assets/books/book0"));

class NovelReader extends StatefulWidget {
  final String basePath; // e.g., "assets/novel1"
  final int initialChapter;

  const NovelReader({super.key, required this.basePath, this.initialChapter = 1});

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
  int currentChapter = 1;
  int maxChapter = 20;

  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;

  String selectedLanguage = 'zh-CN';

  final List<Map<String, String>> languages = [
    {'label': '中文（普通話）', 'value': 'zh-CN'},
    {'label': '粵語（廣東話）', 'value': 'yue-HK'},
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = 'zh-CN';
    initTts();
    loadChapter(currentChapter);
  }

  Future<void> initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.setLanguage(selectedLanguage);
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
  }



  Future<void> loadChapter(int chapter) async {
    print("載入章節");
    setState(() {
      isSpeaking = true;
      currentIndex = 0;
    });
    await stopSpeaking(); // 停止語音

    try {
      final path = '${widget.basePath}/chapter$chapter.txt';
      final text = await rootBundle.loadString(path);
      final pattern = RegExp(r'(?<=[。！？\n])');
      setState(() {
        sentences = text.split(pattern).where((s) => s.trim().isNotEmpty).toList();
        currentChapter = chapter;
        currentIndex = 0;
      });
      await startSpeaking(); // 從新章節頭朗讀
    } catch (e) {
      setState(() {
        sentences = ['無法載入第 $chapter 章。'];
      });
    }
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
    print("開始播放");
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
    return Scaffold(
      appBar: AppBar(
        title: Text("小說朗讀：第$currentChapter章"),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: currentChapter > 1 ? () => loadChapter(currentChapter - 1) : null,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () => loadChapter(currentChapter + 1),
          ),
        ],
      ),
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
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodyLarge?.color,
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
          // _buildTestTtsButton(),
        ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text("音量:"),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: (val) {
                    setState(() => volume = val);
                    flutterTts.setVolume(val);
                  },
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              Text(volume.toStringAsFixed(1)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text("音調:"),
              Expanded(
                child: Slider(
                  value: pitch,
                  onChanged: (val) {
                    setState(() => pitch = val);
                    flutterTts.setPitch(val);
                  },
                  min: 0.5,
                  max: 2.0,
                ),
              ),
              Text(pitch.toStringAsFixed(1)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text("語速:"),
              Expanded(
                child: Slider(
                  value: rate,
                  onChanged: (val) {
                    setState(() => rate = val);
                    flutterTts.setSpeechRate(val);
                  },
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              Text(rate.toStringAsFixed(1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestTtsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(Icons.record_voice_over),
        label: Text("測試 TTS 發聲"),
        onPressed: () async {
          await stopSpeaking(); // 停止目前播放
          final result = await flutterTts.speak("這是一段語音測試。Hello, this is a TTS test.");
          print("TTS 播放結果: $result");
        },
      ),
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
              onChanged: (value) async {
                if (value != null) {
                  await stopSpeaking();
                  setState(() {
                    selectedLanguage = value;
                  });
                  await flutterTts.setLanguage(selectedLanguage);
                  // currentIndex = 0;
                  // await speakCurrent();
                  await loadChapter(currentChapter);
                }
              }
          ),
        ],
      ),
    );
  }
}
