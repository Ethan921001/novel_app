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
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: GridView.builder(
          itemCount: favoriteBooks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 8,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final bookTitle = favoriteBooks[index];
            final book = books.firstWhere((b) => b.title == bookTitle);

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
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade600, width: 1.2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth - 30;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Image.asset(
                            book.image,
                            width: cardWidth,
                            height: cardWidth * 1.3,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: cardWidth,
                            child: Text(
                              book.title,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 16,
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
      ),
    );
  }
}
