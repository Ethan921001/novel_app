import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'readPage.dart';
import 'book_data.dart';
import 'book.dart';
import 'account.dart';
import 'user.dart';
import 'bookshelf.dart';
import 'addbook.dart';
import 'dart:io';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: BookListApp(),
    ),
  );
}

class BookListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, mode, _) {
          return MaterialApp(
            title: 'Novel App',
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
            home: MainNavigation(),
            debugShowCheckedModeBanner: false, // 把右上角的東東拿掉
          );
        },
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // 預設打開分類頁

  static final List<Widget> _pages = <Widget>[
    FrontPage(), // 首頁
    BookListScreen(), // 分類頁
    SearchPage(),
    UserBookshelfWidget(),
    LoginRegisterWidget(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
    BottomNavigationBarItem(icon: Icon(Icons.category), label: '列表'),
    BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜尋'),
    BottomNavigationBarItem(icon: Icon(Icons.book), label: '書架'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

List<Book> showBooks = [];
final TextEditingController _searchController = TextEditingController();

class BookListScreen extends StatefulWidget {
  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String? sortKey = '日期'; // 預設排序欄位
  bool ascending = false; // 預設為降序
  List<Book> sortedBooks = [];

  @override
  void initState() {
    super.initState();
    sortBooks();
  }

  void toggleSort(String key) {
    setState(() {
      if (sortKey == key) {
        ascending = !ascending; // 同一個欄位則反轉順序
      } else {
        sortKey = key;
        ascending = true; // 新欄位預設升序
      }
      sortBooks();
    });
  }

  void sortBooks() {
    sortedBooks = [...books];
    switch (sortKey) {
      case '日期':
        sortedBooks.sort((a, b) => a.date.compareTo(b.date));
        break;
      case '觀看數':
        sortedBooks.sort((a, b) => a.views.compareTo(b.views));
        break;
      case '收藏數':
        sortedBooks.sort((a, b) => a.favorites.compareTo(b.favorites));
        break;
    }
    if (!ascending) {
      sortedBooks = sortedBooks.reversed.toList();
    }
  }

  Icon sortIcon(String key) {
    if (key != sortKey) return Icon(Icons.unfold_more, size: 16);
    return ascending ? Icon(Icons.arrow_upward, size: 16) : Icon(Icons.arrow_downward, size: 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("書籍列表")),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            height: 50,
            color: Colors.grey[100],
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                TextButton.icon(
                  onPressed: () => toggleSort('日期'),
                  icon: sortIcon('日期'),
                  label: Text('日期'),
                ),
                TextButton.icon(
                  onPressed: () => toggleSort('觀看數'),
                  icon: sortIcon('觀看數'),
                  label: Text('觀看數'),
                ),
                TextButton.icon(
                  onPressed: () => toggleSort('收藏數'),
                  icon: sortIcon('收藏數'),
                  label: Text('收藏數'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedBooks.length,
              itemBuilder: (context, index) {
                final book = sortedBooks[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // 整體更大
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Card 內邊距放大
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center, // 垂直置中
                        children: [
                          book.image.startsWith('/')
                              ? Image.file(
                            File(book.image),
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                          )
                              : Image.asset(
                            book.image,
                            width: 100,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 16), // 圖片和文字間距
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // 文字靠左對齊
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  book.title,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "作者: ${book.author}",
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  "觀看數: ${book.views} 收藏: ${book.favorites}",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FrontPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("首頁"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        itemCount: books.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
          childAspectRatio: 0.58, // 稍微拉高比例以放大內容
        ),
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailScreen(book: book),
                ),
              );
            },
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Colors.grey.shade700,
                  width: 1.5,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth = constraints.maxWidth;

                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // ✅ 圖片寬度等於 Card 寬度（或略小）
                        book.image.startsWith('/')
                            ? Image.file(
                          File(book.image),
                          width: cardWidth, // 或 cardWidth * 0.95 讓邊緣留一點空
                          height: cardWidth * 1.3, // 比例高度可調整
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          book.image,
                          width: cardWidth, // 或 cardWidth * 0.95 讓邊緣留一點空
                          height: cardWidth * 1.3, // 比例高度可調整
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: cardWidth,
                          child: Text(
                            book.title,
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );

        },
      ),
    );
  }
}




class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  late List<Book> showBooks;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(); // ← 加這行初始化
    showBooks = List.from(books);
  }

  void _searchBooks(String keyword) {
    setState(() {
      showBooks = books.where((book) =>
      book.title.contains(keyword) ||
          book.author.contains(keyword)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // 這樣就不會報錯了
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('書籍搜尋')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '搜尋書名或作者',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchBooks,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: showBooks.length,
                itemBuilder: (context, index) {
                  final book = showBooks[index];
                  return Card(
                    child: ListTile(
                      title: Text(book.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      leading:   book.image.startsWith('/')
                          ? Image.file(
                        File(book.image),
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                          : Image.asset(
                        book.image,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                      subtitle: Text('作者: ${book.author}'),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailScreen(book: book),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class BookCard extends StatelessWidget {
  final Book book;

  BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading:   book.image.startsWith('/')
            ? Image.file(
          File(book.image),
          width: 40,
        )
            : Image.asset(
          book.image,
          width: 40,
        ),
        title: Text(book.title),
        subtitle: Text(
          "${book.author}\n${book.date}",
          style: TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("👁️ ${book.views}"),
            Text("❤️ ${book.favorites}"),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(book.title),
              content: Text("點選了書籍：${book.title}"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("關閉"))
              ],
            ),
          );
        },
      ),
    );
  }
}
