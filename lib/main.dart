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
      create: (_) => UserProvider()..tryAutoLogin(),
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


class BookListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("書籍分類")),
      body: ListView.builder(
        itemCount: books.length,
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
              child: ListTile(
                leading: Image.asset(
                  book.image,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                ),
                title: Text(book.title),
                subtitle: Text("作者: ${book.author}"),
              ),
            ),
          );
        },
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
        backgroundColor: Colors.blue, // ✅ AppBar 背景藍色
      ),
      body: Container(
        color: Colors.white, // ✅ 頁面內容區背景白色
        child: Center(
          child: Text(
            "這是首頁內容",
            style: TextStyle(fontSize: 20),
          ),
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
