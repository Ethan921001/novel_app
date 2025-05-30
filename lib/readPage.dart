import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'book.dart';
import 'book_data.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late PageController _pageController;
  int chapterCount = 20; // 根據你預期的最大章節數

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _detectChapterCount(); // 自動偵測有幾個章節
  }

  Future<void> _detectChapterCount() async {
    int count = 0;
    while (true) {
      try {
        String path = '${widget.book.content}/chapter${count + 1}.txt';
        print('嘗試載入：$path');
        await rootBundle.loadString(path);
        count++;
      } catch (e) {
        print('載入失敗：第 ${count + 1} 章, 錯誤: $e');
        break;
      }
    }
    setState(() {
      chapterCount = count;
      print('總章節數：$chapterCount');
    });
  }

  Future<String> _loadIntro(int index) async {
    String path = '${widget.book.content}/intro.txt';
    print(path);
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      return '無法讀取簡介。';
    }
  }

  Future<String> _loadChapterContent(int index) async {
    if (index == 0) {
      // 簡介頁
      return '這是《${widget.book.title}》的簡介頁。\n\n作者：${widget.book.author}\n發布日期：${widget.book.date}\n共 $chapterCount 章。\n\n右滑以開始閱讀第一章。';
    }

    String path = '${widget.book.content}/chapter$index.txt';
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      return '無法讀取第 $index 章內容。';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                setState(() {
                  // currentChapter = index;
                });
              },
              itemCount: chapterCount + 1, // +1 是簡介
              itemBuilder: (context, index) {
                if (index == 0) {
                  // 簡介頁面
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.asset(widget.book.image, height: 200),
                        ),
                        const SizedBox(height: 16),
                        Text("書名: ${widget.book.title}",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("作者: ${widget.book.author}",
                            style: const TextStyle(fontSize: 18)),
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
                                style: const TextStyle(fontSize: 16),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                } else {
                  // 正文頁面
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
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...bodyLines.map(
                                    (line) => Text(
                                  line,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }

}
