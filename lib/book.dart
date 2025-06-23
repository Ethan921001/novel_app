import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_word_highlighter/text_word_highlighter.dart';
import 'package:text_word_highlighter/utils/word_highlight.dart';

class HighlightRange {
  final int start;
  final int end;

  HighlightRange(this.start, this.end);
}

class Character {
  final String name;
  final String description;
  // final String avatarPath;
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
  Map<String, bool> annotations = {};
  Map<int, List<WordHighlight>> highlightRanges = {};

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

  Future<void> saveAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('annotations_${title}', jsonEncode(annotations));
  }

  Future<void> loadAnnotations() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('annotations_${title}');
    if (json != null) {
      annotations = Map<String, dynamic>.from(jsonDecode(json)).map((key, value) => MapEntry(key, value as bool));
    }
  }
}

Future<String> loadBookText(String path) async {
  return await rootBundle.loadString(path);
}
