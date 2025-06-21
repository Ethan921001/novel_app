import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Book {
  final String title;
  final String author;
  final String date;
  final int views;
  final int favorites;
  final String content;
  final String image;

  List<Map<String, dynamic>> comments;

  Book(
      this.title,
      this.author,
      this.date,
      this.views,
      this.favorites,
      this.content,
      this.image,
      ) : comments = [];

  String get commentStorageKey => 'comments_${title.replaceAll(' ', '_')}';

  Future<void> loadComments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(commentStorageKey);
    if (jsonStr != null) {
      final decoded = jsonDecode(jsonStr);
      comments = List<Map<String, dynamic>>.from(decoded);
    }
  }

  Future<void> saveComments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(commentStorageKey, jsonEncode(comments));
  }
}

Future<String> loadBookText(String path) async {
  return await rootBundle.loadString(path);
}
