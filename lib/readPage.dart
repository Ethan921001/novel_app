import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'chatbot.dart';
import 'main.dart'; // 為了取得 themeNotifier
import 'book.dart';
import 'tts.dart';
import 'user.dart'; // 新增：取得使用者資訊
import 'dart:io';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class AnnotatedLine extends StatefulWidget {
  final String line;
  final String keyId;
  final double fontSize;
  final bool isHighlighted;
  final ValueChanged<bool> onToggle;

  const AnnotatedLine({
    super.key,
    required this.line,
    required this.keyId,
    required this.fontSize,
    required this.isHighlighted,
    required this.onToggle,
  });

  @override
  State<AnnotatedLine> createState() => _AnnotatedLineState();
}

class _AnnotatedLineState extends State<AnnotatedLine> {
  late bool _highlighted;

  @override
  void initState() {
    super.initState();
    _highlighted = widget.isHighlighted;
  }

  @override
  void didUpdateWidget(covariant AnnotatedLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHighlighted != widget.isHighlighted) {
      _highlighted = widget.isHighlighted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _highlighted = !_highlighted;
        });
        widget.onToggle(_highlighted);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: _highlighted ? Colors.yellow.withOpacity(0.4) : null,
        child: Text(
          widget.line,
          style: TextStyle(fontSize: widget.fontSize),
        ),
      ),
    );
  }
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late PageController _pageController;
  late List<ScrollController> _scrollControllers;
  int chapterCount = 20;
  List<String> chapterTitles = [];
  double _fontSize = 16.0; // 字體大小 state
  bool useCantonese = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollControllers = List.generate(chapterCount + 1, (_) => ScrollController());
    _detectChapterCount();
    widget.book.loadComments().then((_) {
      setState(() {}); // 載入完畢後更新畫面
    });
  }

  Future<void> _detectChapterCount() async {
    int count = 0;
    List<String> titles = ['簡介'];

    while (true) {
      try {
        String path = '${widget.book.content}/chapter${count + 1}.txt';
        String content = await rootBundle.loadString(path);
        final firstLine = content.split('\n').first.trim();
        titles.add(firstLine.isNotEmpty ? firstLine : '第 ${count + 1} 章');
        count++;
      } catch (e) {
        // fallback：從 content 裡面偵測 #CHAPTER# 數量
        final content = widget.book.content;
        final chapterMatches = RegExp(r'#CHAPTER#').allMatches(content).toList();

        // 如果沒有任何 chapterN.txt，但 book.content 有 #CHAPTER# 標記
        if (count == 0 && chapterMatches.isNotEmpty) {
          count = chapterMatches.length;
          for (int i = 0; i < count; i++) {
            // 試圖從每個章節擷取標題
            final start = chapterMatches[i].start;
            final end = (i + 1 < chapterMatches.length)
                ? chapterMatches[i + 1].start
                : content.length;
            final chunk = content.substring(start, end);
            final lines = chunk.split('\n');
            final titleLine = lines.length > 0 ? lines[0].replaceAll('#CHAPTER#', '').trim() : '第 ${i + 1} 章';
            titles.add(titleLine.isNotEmpty ? titleLine : '第 ${i + 1} 章');
          }
        }
        break;
      }
    }

    setState(() {
      chapterCount = count;
      chapterTitles = titles;
    });
  }


  Future<String> _loadIntro(int index) async {
    String path = '${widget.book.content}/intro.txt';
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      // fallback: 用 content 裡的 #INTRO# 內容
      final content = widget.book.content;
      final introStart = content.indexOf('#INTRO#');
      if (introStart == -1) return '無法讀取簡介。';
      final chapterStart = content.indexOf('#CHAPTER#', introStart);
      if (chapterStart == -1) {
        // 從 #INTRO# 後面到末尾全當簡介
        return content.substring(introStart + 7).trim();
      } else {
        return content.substring(introStart + 7, chapterStart).trim();
      }
    }
  }

  Future<String> _loadChapterContent(int index) async {
    if (index == 0) {
      return '簡介\n這是《${widget.book.title}》的簡介頁。\n\n作者：${widget.book.author}\n發布日期：${widget.book.date}\n共 $chapterCount 章。\n\n右滑以開始閱讀第一章。';
    }

    // 根據語言選擇檔案名稱
    String fileName = useCantonese ? 'chapter${index}_ZHH.txt' : 'chapter$index.txt';
    String path = '${widget.book.content}/$fileName';

    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      // fallback：從 book.content 中擷取章節資料
      final content = widget.book.content;

      int findChapterStart(int i) {
        int pos = 0;
        for (int c = 1; c <= i; c++) {
          final nextPos = content.indexOf('#CHAPTER#', pos + 1);
          if (nextPos == -1) return -1;
          pos = nextPos;
        }
        return pos;
      }

      final start = findChapterStart(index);
      if (start == -1) return '第 $index 章\n無法讀取內容';

      final nextStart = findChapterStart(index + 1);
      String raw = (nextStart == -1)
          ? content.substring(start)
          : content.substring(start, nextStart);

      raw = raw.replaceFirst('#CHAPTER#', '').trim();

      final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) return '第 $index 章\n（本章無內容）';

      String title = lines.first.trim();
      String body = lines.sublist(1).join('\n');
      return '$title\n$body';
    }
  }



  void _showChapterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('章節選擇'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: chapterTitles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(chapterTitles[index]),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pageController.jumpToPage(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final isFavorited = user?.favorites.contains(widget.book.title) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent,
              ),
              tooltip: '收藏',
              onPressed: () {
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("請先登入才能收藏")),
                  );
                } else {
                  userProvider.toggleFavorite(widget.book.title);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFavorited ? "已取消收藏" : "已加入收藏"),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: chapterCount + 1,
              itemBuilder: (context, index) {
                final scrollController = _scrollControllers[index];

                if (index == 0) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: widget.book.image.startsWith('/data') || widget.book.image.startsWith('/storage')
                              ? Image.file(File(widget.book.image), height: 200, fit: BoxFit.cover)
                              : Image.asset(widget.book.image, height: 200, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 16),
                        Text("書名: ${widget.book.title}",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("作者: ${widget.book.author}", style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text("發布日期: ${widget.book.date}"),
                        const SizedBox(height: 8),
                        Text("瀏覽次數: ${widget.book.views}"),
                        Text("收藏數: ${widget.book.favorites}"),
                        const SizedBox(height: 16),
                        const Divider(height: 24),
                        FutureBuilder<String>(
                          future: _loadIntro(0),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Text("讀取簡介失敗: ${snapshot.error}");
                            } else {
                              return Text(
                                snapshot.data ?? '',
                                style: TextStyle(fontSize: _fontSize),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                } else {
                  return FutureBuilder<String>(
                    future: _loadChapterContent(index),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("錯誤：${snapshot.error}"));
                      } else {
                        final content = snapshot.data ?? "";
                        final lines = content.split('\n');
                        final title = lines.isNotEmpty ? lines.first.trim() : '';
                        final bodyLines = lines.length > 1 ? lines.sublist(1) : [];

                        return SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: _fontSize + 6,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...bodyLines.map((line) {
                                final keyId = '$index-$line';
                                final isHighlighted = widget.book.annotations[keyId] ?? false;

                                return AnnotatedLine(
                                  line: line,
                                  keyId: keyId,
                                  fontSize: _fontSize,
                                  isHighlighted: isHighlighted,
                                  onToggle: (newVal) {
                                    setState(() {
                                      widget.book.annotations[keyId] = newVal;
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showChapterDialog,
                    icon: const Icon(Icons.menu_book),
                    label: const Text(' 章節選擇 '),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      themeNotifier.value = themeNotifier.value == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                    icon: const Icon(Icons.brightness_6),
                    label: const Text(' 日/夜間 '),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NovelReader(
                            basePath: widget.book.content,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.headphones),
                    label: const Text(' 聽書模式 '),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                  onPressed: () {
                  final controller = TextEditingController();
                  int rating = 3;

                  showDialog(
                  context: context,
                  builder: (context) {
                  final existingComments = widget.book.comments;
                  final avgRating = existingComments.isEmpty
                  ? 0
                      : existingComments.map((e) => e['rating'] as int).reduce((a, b) => a + b) / existingComments.length;

                  return AlertDialog(
                  title: Text("《${widget.book.title}》評論區"),
                  content: SingleChildScrollView(
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 500,
                  ),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  if (existingComments.isNotEmpty) ...[
                  Text("平均評分：${avgRating.toStringAsFixed(1)} / 5.0"),
                  const SizedBox(height: 8),
                  SizedBox(
                  height: 120,
                  child: ListView.builder(
                  itemCount: existingComments.length,
                  itemBuilder: (context, index) {
                  final c = existingComments[index];
                  return ListTile(
                  dense: true,
                  title: Text('${c['user']}（${c['rating']} 星）'),
                  subtitle: Text(c['comment']),
                  );
                  },
                  ),
                  ),
                  const Divider(),
                  ],
                  const Text("你的評論"),
                  TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: "輸入評論內容"),
                  maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () {
                            rating = i + 1;
                            (context as Element).markNeedsBuild();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4), // 控制間距
                            child: Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20, // ✅ 調整星星大小（預設為 24）
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  ),
                  ),
                  ),
                  actions: [
                  TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("取消"),
                  ),
                  TextButton(
                  onPressed: () async {
                  final user = Provider.of<UserProvider>(context, listen: false).currentUser;
                  if (controller.text.trim().isNotEmpty && user != null) {
                  setState(() {
                  widget.book.comments.add({
                  "user": user.name,
                  "comment": controller.text.trim(),
                  "rating": rating,
                  });
                  });
                  await widget.book.saveComments(); // ✅ 儲存至 SharedPreferences

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("已新增評論")),
                  );
                  } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("請登入帳號")),
                  );
                  }
                  },
                  child: const Text("送出"),
                  ),
                  ],
                  );
                  },
                  );
                  },
                  icon: const Icon(Icons.comment),
                  label: const Text(' 評論 '),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_fontSize < 30) _fontSize += 2;
                      });
                    },
                    icon: const Icon(Icons.zoom_in),
                    label: const Text(' 放大字體 '),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_fontSize > 10) _fontSize -= 2;
                      });
                    },
                    icon: const Icon(Icons.zoom_out),
                    label: const Text(' 縮小字體 '),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        useCantonese = !useCantonese;
                      });
                      _pageController.jumpToPage(_pageController.page?.round() ?? 0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(useCantonese ? '已切換至粵語版' : '已切換至原始版本')),
                      );
                    },
                    icon: const Icon(Icons.translate),
                    label: Text(useCantonese ? '切換至原文' : '切換至粵語'),
                  ),


                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.book.characters.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("本書暫無角色資料")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CharacterSelectionPage(
                            characters: widget.book.characters,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text(' 角色對話 '),
                  ),

                ],
              ),
            ),
          ),
          Container(
            height: 40,
            color: Theme.of(context).colorScheme.surfaceVariant, // 你想要的顏色
          )
        ],
      ),
    );
  }
}