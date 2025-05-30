import 'package:flutter/services.dart' show rootBundle;

class Book {
  final String title;
  final String author;
  final String date;
  final int views;
  final int favorites;
  final String content; // 新增：章節內容
  final String image; // 封面

  Book(this.title, this.author, this.date, this.views, this.favorites, this.content, this.image);
}

Future<String> loadBookText(String path) async {
  return await rootBundle.loadString(path);
}
