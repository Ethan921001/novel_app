import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  // test account: qqq
  // test password: 123
  final String id;
  final String name;
  List<String> favorites;

  User({
    required this.id,
    required this.name,
    List<String>? favorites,
    Map<String, List<String>>? comments,
  })  : favorites = favorites ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'favorites': favorites,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      favorites: List<String>.from(json['favorites'] ?? []),
      comments: Map<String, List<String>>.from(
        (json['comments'] ?? {}).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
    );
  }
}

class UserProvider with ChangeNotifier {
  User? currentUser;

  Future<void> login(User user) async {
    currentUser = user;
    await _saveUserToPrefs(user);
    notifyListeners();
  }

  Future<void> logout() async {
    if (currentUser != null) {
      await updateUserInDatabase();
    }
    currentUser = null;
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

  Future<void> updateUserInDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('userDatabase');
    if (rawData == null || currentUser == null) return;

    final userDatabase = jsonDecode(rawData) as Map<String, dynamic>;

    final currentUserJson = currentUser!.toJson();
    final existingEntry = userDatabase[currentUser!.id] ?? {};

    // 保留原本的 password
    final password = existingEntry['password'] ?? '';

    userDatabase[currentUser!.id] = {
      'password': password,
      'name': currentUserJson['name'],
      'favorites': currentUserJson['favorites'],
      'comments': currentUserJson['comments'],
    };

    await prefs.setString('userDatabase', jsonEncode(userDatabase));
  }


  void toggleFavorite(String bookId) async {
    if (currentUser == null) return;

    if (currentUser!.favorites.contains(bookId)) {
      currentUser!.favorites.remove(bookId);
    } else {
      currentUser!.favorites.add(bookId);
    }

    await _saveUserToPrefs(currentUser!);
    await updateUserInDatabase();
    notifyListeners();
  }

  List<String> getUserFavoriteBooks() {
    return currentUser?.favorites ?? [];
  }
}
