import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user.dart';

class LoginRegisterWidget extends StatefulWidget {
  const LoginRegisterWidget({Key? key}) : super(key: key);

  @override
  State<LoginRegisterWidget> createState() => _LoginRegisterWidgetState();
}

class _LoginRegisterWidgetState extends State<LoginRegisterWidget> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Map<String, Map<String, dynamic>> _userDatabase = {};

  @override
  void initState() {
    super.initState();
    _loadUserDatabase();
  }

  Future<void> _loadUserDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('userDatabase');
    if (rawData != null) {
      final decoded = jsonDecode(rawData) as Map<String, dynamic>;
      _userDatabase = decoded.map((key, value) =>
          MapEntry(key, Map<String, dynamic>.from(value)));
    }
  }

  Future<void> _saveUserDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_userDatabase);
    await prefs.setString('userDatabase', encoded);
  }

  void _register() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (account.isEmpty || password.isEmpty || name.isEmpty) {
      _showMessage('請輸入帳號、密碼和名字');
      return;
    }

    if (_userDatabase.containsKey(account)) {
      _showMessage('帳號已存在');
      return;
    }

    _userDatabase[account] = {
      'password': password,
      'name': name,
      'favorites': [],
      'comments': {},
    };
    await _saveUserDatabase();

    _showMessage('註冊成功');
    _accountController.clear();
    _passwordController.clear();
    _nameController.clear();
  }

  void _login(BuildContext context) async {
    await _loadUserDatabase();

    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();

    if (account.isEmpty || password.isEmpty) {
      _showMessage('請輸入帳號和密碼');
      return;
    }

    final userData = _userDatabase[account];

    try {
      if (userData != null && userData['password'] == password) {
        final user = User(
          id: account,
          name: userData['name'],
          favorites: List<String>.from(userData['favorites'] ?? []),
          comments: Map<String, List<String>>.from(
            (userData['comments'] ?? {}).map(
                  (key, value) => MapEntry(key, List<String>.from(value)),
            ),
          ),
        );

        await Provider.of<UserProvider>(context, listen: false).login(user);

        _accountController.clear();
        _passwordController.clear();
        _nameController.clear();

        _showMessage('登入成功');
      } else {
        _showMessage('帳號或密碼錯誤');
      }
    } catch (e) {
      print('登入失敗: $e');
      _showMessage('登入失敗，資料格式錯誤');
    }
  }

  void _logout(BuildContext context) {
    _saveUserDatabase();
    Provider.of<UserProvider>(context, listen: false).logout();
  }

  void _deleteAccount(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final account = userProvider.currentUser?.id;
    if (account == null) return;

    _userDatabase.remove(account);
    await _saveUserDatabase();
    _logout(context);
    _showMessage('帳號已刪除');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    return Scaffold(
      body: Center(
        child: user != null
            ? _buildLoggedInUI(context, user)
            : _buildLoginForm(context),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextField(
            controller: _accountController,
            decoration: const InputDecoration(labelText: '帳號'),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: '密碼'),
            obscureText: true,
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '名字（註冊用）'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: _register,
                child: const Text('註冊新會員'),
              ),
              ElevatedButton(
                onPressed: () => _login(context),
                child: const Text('登入'),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLoggedInUI(BuildContext context, User user) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('您好，${user.name}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => _logout(context),
          child: const Text('登出'),
        ),
        ElevatedButton(
          onPressed: () => _deleteAccount(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('刪除帳號'),
        ),
      ],
    );
  }
}