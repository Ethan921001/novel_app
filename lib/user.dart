import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String name;
  List<String> favorites;
  Map<String, List<String>> comments;

  User({
    required this.id,
    required this.name,
    List<String>? favorites,
    Map<String, List<String>>? comments,
  })  : favorites = favorites ?? [],
        comments = comments ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'favorites': favorites,
      'comments': comments,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      favorites: List<String>.from(json['favorites'] ?? []),
      comments: Map<String, List<String>>.from((json['comments'] ?? {}).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      )),
    );
  }
}

class UserProvider with ChangeNotifier {
  User? currentUser;
  final Map<String, List<Map<String, dynamic>>> _bookComments = {};

  Future<void> login(User user) async {
    currentUser = user;
    await _saveUserToPrefs(user);
    notifyListeners();
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    if (userData != null) {
      final decoded = jsonDecode(userData);
      currentUser = User.fromJson(decoded);
      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(user.toJson());
    await prefs.setString('userData', jsonString);
  }

  void toggleFavorite(String bookId) {
    if (currentUser == null) return;

    if (currentUser!.favorites.contains(bookId)) {
      currentUser!.favorites.remove(bookId);
    } else {
      currentUser!.favorites.add(bookId);
    }

    _saveUserToPrefs(currentUser!);
    notifyListeners();
  }

  void addComment(String bookTitle, String comment, int rating) {
    _bookComments.putIfAbsent(bookTitle, () => []);
    _bookComments[bookTitle]!.add({
      'user': currentUser?.name ?? '匿名',
      'comment': comment,
      'rating': rating,
    });
    notifyListeners();
  }

  List<String> getUserFavoriteBooks(){
    return currentUser!.favorites;
  }

  List<Map<String, dynamic>> getComments(String bookTitle) {
    return _bookComments[bookTitle] ?? [];
  }

  double getAverageRating(String bookTitle) {
    final comments = getComments(bookTitle);
    if (comments.isEmpty) return 0.0;
    return comments.map((c) => c['rating'] as int).reduce((a, b) => a + b) / comments.length;
  }
}
