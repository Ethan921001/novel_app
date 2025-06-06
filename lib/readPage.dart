import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'main.dart'; // 為了取得 themeNotifier
import 'book.dart';
import 'tts.dart';
import 'user.dart'; // 新增：取得使用者資訊

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late PageController _pageController;
  int chapterCount = 20;
  List<String> chapterTitles = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _detectChapterCount();
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
      return '無法讀取簡介。';
    }
  }

  Future<String> _loadChapterContent(int index) async {
    if (index == 0) {
      return '這是《${widget.book.title}》的簡介頁。\n\n作者：${widget.book.author}\n發布日期：${widget.book.date}\n共 $chapterCount 章。\n\n右滑以開始閱讀第一章。';
    }
    String path = '${widget.book.content}/chapter$index.txt';
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      return '無法讀取第 $index 章內容。';
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
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: chapterCount + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
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
                                style: const TextStyle(fontSize: 16),
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
                              ...bodyLines.map((line) => Text(
                                line,
                                style: const TextStyle(fontSize: 16),
                              )),
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showChapterDialog,
                    icon: const Icon(Icons.menu_book),
                    label: const Text('章節選擇'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      themeNotifier.value = themeNotifier.value == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                    icon: const Icon(Icons.brightness_6),
                    label: const Text('日/夜間'),
                  ),
                  const SizedBox(width: 8),
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
                    label: const Text('聽書模式'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("請先登入才能收藏")),
                        );
                      } else {
                        userProvider.toggleFavorite(widget.book.title);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorited ? "已取消收藏" : "已加入收藏",
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
                    label: const Text('收藏'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("請先登入才能評論")),
                        );
                      } else {
                        final controller = TextEditingController();
                        int rating = 3;

                        showDialog(
                          context: context,
                          builder: (context) {
                            final existingComments = userProvider.getComments(widget.book.title);
                            final avgRating = userProvider.getAverageRating(widget.book.title);

                            return AlertDialog(
                              title: Text("《${widget.book.title}》評論區"),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (existingComments.isNotEmpty) ...[
                                      Text("平均評分：${avgRating.toStringAsFixed(1)} / 5.0"),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 100,
                                        child: ListView.builder(
                                          itemCount: existingComments.length,
                                          itemBuilder: (context, index) {
                                            final c = existingComments[index];
                                            return ListTile(
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
                                      children: [
                                        const Text("評分："),
                                        for (int i = 1; i <= 5; i++)
                                          IconButton(
                                            icon: Icon(
                                              i <= rating ? Icons.star : Icons.star_border,
                                              color: Colors.amber,
                                            ),
                                            onPressed: () {
                                              rating = i;
                                              (context as Element).markNeedsBuild(); // 更新 dialog 畫面
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("取消"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    userProvider.addComment(widget.book.title, controller.text, rating);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("已新增評論與評分")),
                                    );
                                  },
                                  child: const Text("送出"),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    icon: const Icon(Icons.comment),
                    label: const Text('評論'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
