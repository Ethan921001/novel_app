import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Character {
  final String name;
  final String description;

  Character({required this.name, required this.description});
}

class Book {
  String title;
  String author;
  String date;
  int views;
  int favorites;
  String content;
  String image;
  String? createdBy;

  List<Map<String, dynamic>> comments;
  List<Character> characters;

  Book(
      this.title,
      this.author,
      this.date,
      this.views,
      this.favorites,
      this.content,
      this.image,
      this.characters,
      [this.createdBy]
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
