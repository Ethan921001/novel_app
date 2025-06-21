import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'readPage.dart';
import 'book_data.dart';
import 'book.dart';
import 'account.dart';
import 'user.dart';
import 'bookshelf.dart';

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
    BottomNavigationBarItem(icon: Icon(Icons.category), label: '分類'),
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
      appBar: AppBar(title: Text("書籍分類")),
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
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Image.asset(
                        book.image,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                      title: Text(book.title),
                      subtitle: Text("作者: ${book.author}\n觀看數: ${book.views} 收藏: ${book.favorites}"),
                      isThreeLine: true,
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
      body: Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: ListTile(
                leading: Image.asset(
                  book.image,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                ),
                title: Text(book.title, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("作者：${book.author}\n日期：${book.date}"),
                isThreeLine: true,
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
                      title: Text(book.title),
                      leading: Image.asset(
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
        leading: Image.asset('assets/images/book0.jpg', width: 40),
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
