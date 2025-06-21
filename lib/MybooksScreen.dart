// my_books_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'book.dart';
import 'book_data.dart';
import 'user.dart';
import 'EditBookScreen.dart';

class MyBooksScreen extends StatelessWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("請先登入")),
      );
    }

    final myBooks =
    books.where((book) => book.createdBy == user.name).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('我的書籍')),
      body: ListView.builder(
        itemCount: myBooks.length,
        itemBuilder: (context, index) {
          final book = myBooks[index];
          return ListTile(
            leading: Image.asset(book.image, width: 50),
            title: Text(book.title),
            subtitle: Text("作者：${book.author}"),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookFormScreen(book: book),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
