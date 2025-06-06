import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user.dart'; // 包含 User 與 UserProvider
import 'readPage.dart';
import 'book_data.dart';
import 'book.dart';

class UserBookshelfWidget extends StatelessWidget {
  const UserBookshelfWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          '請登入帳號',
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      );
    }

    final List<String> favoriteBooks = userProvider.getUserFavoriteBooks();

    return Scaffold(
      appBar: AppBar(title: const Text('我的書櫃')),
      body: favoriteBooks.isEmpty
          ? const Center(child: Text('尚未收藏任何書籍'))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: favoriteBooks.length,
        itemBuilder: (context, index) {
          final bookTitle = favoriteBooks[index];
          final book = books[index];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                bookTitle,
                style: const TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: 替換為實際的導向邏輯
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
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
