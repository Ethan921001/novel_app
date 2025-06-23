import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'book.dart';

// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: '有記憶的聊天',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const CharacterSelectionPage(),
//     );
//   }
// }

// class CharacterSelectionPage extends StatelessWidget {
//   const CharacterSelectionPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('選擇角色')),
//       body: ListView(
//         children: [
//           ListTile(
//             leading: CircleAvatar(
//               backgroundImage: AssetImage('assets/avatar/sun_wukong.png'),
//             ),
//             title: const Text('孫悟空'),
//             subtitle: const Text('西遊記'),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatPage(
//                     characterName: '孫悟空',
//                     characterDescription: '西遊記角色',
//                     avatarAsset: 'assets/avatar/sun_wukong.png', // 傳遞頭像路徑
//                   ),
//                 ),
//               );
//             },
//           ),
//           ListTile(
//             leading: CircleAvatar(
//               backgroundImage: AssetImage('assets/avatar/pigsy.png'),
//             ),
//             title: const Text('豬八戒'),
//             subtitle: const Text('西遊記角色'),
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatPage(
//                     characterName: '豬八戒',
//                     characterDescription: '西遊記角色',
//                     avatarAsset: 'assets/avatar/pigsy.png', // 傳遞頭像路徑
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

class CharacterSelectionPage extends StatelessWidget {
  final List<Character> characters;

  const CharacterSelectionPage({
    super.key,
    required this.characters,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('選擇角色')),
      body: ListView.builder(
        itemCount: characters.length,
        itemBuilder: (context, index) {
          final character = characters[index];
          return ListTile(
            leading: CircleAvatar(
              // 這裡可以根據角色名稱顯示不同頭像
              child: Text(character.name.substring(0, 1)),
            ),
            title: Text(character.name),
            subtitle: Text(character.description),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    characterName: character.name,
                    characterDescription: character.description,
                    avatarAsset: _getCharacterAvatar(character.name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 根據角色名稱返回對應的頭像資源路徑
  String _getCharacterAvatar(String name) {
    // 這裡可以實現你的頭像映射邏輯
    // 例如:
    if (name.contains('孫悟空')) return 'assets/images/sun_wukong.png';
    if (name.contains('豬八戒')) return 'assets/images/pig.png';
    // 默認頭像
    return 'assets/images/default_avatar.png';
  }
}


class ChatPage extends StatefulWidget {
  final String characterName;
  final String characterDescription;
  final String avatarAsset; // 頭貼路徑

  const ChatPage({
    required this.characterName,
    required this.characterDescription,
    required this.avatarAsset,
    super.key,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ConversationMemory _memory = ConversationMemory();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sendWelcomeMessage();
  }

  Future<void> _sendWelcomeMessage() async {
    // final welcomeMessage = ChatMessage(
    //   content: '你好！我是${widget.characterName}，${widget.characterDescription}',
    //   isUser: false,
    //   timestamp: DateTime.now(),
    //   role: 'assistant',
    // );
    //
    // setState(() {
    //   _memory.addMessage(welcomeMessage);
    // });
    final init_message = "你現在扮演${widget.characterName}，${widget.characterDescription}。請用這個角色的身份和語言風格對話，現在自我介紹。";
    final userMessage = ChatMessage(
      content: init_message,
      isUser: true,
      timestamp: DateTime.now(),
      role: 'system',
    );
    _messageController.clear();

    setState(() {
      _memory.addMessage(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final aiResponse = await _getAIResponse();

      setState(() {
        _memory.addMessage(aiResponse);
      });
    } catch (e) {
      setState(() {
        _memory.addMessage(ChatMessage(
          content: '抱歉，我遇到了一些問題: $e',
          isUser: false,
          timestamp: DateTime.now(),
          role: 'assistant',
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      content: _messageController.text,
      isUser: true,
      timestamp: DateTime.now(),
      role: 'user',
    );
    _messageController.clear();

    setState(() {
      _memory.addMessage(userMessage);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final aiResponse = await _getAIResponse();

      setState(() {
        _memory.addMessage(aiResponse);
      });
    } catch (e) {
      setState(() {
        _memory.addMessage(ChatMessage(
          content: '抱歉，我遇到了一些問題: $e',
          isUser: false,
          timestamp: DateTime.now(),
          role: 'assistant',
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<ChatMessage> _getAIResponse() async {
    try {
      const apiKey = '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'; // 替換為你的API密鑰
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',
          'messages': [
            ..._memory.getMessagesForApi(),
            {
              'role': 'system',
              'content':
                  '若之前有對話紀錄，請參考之前的對話內容進行回應。'
            },

          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage(
          content: data['choices'][0]['message']['content'],
          isUser: false,
          timestamp: DateTime.now(),
          role: 'assistant',
        );
      } else {
        throw Exception('API請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('請求出錯: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('與${widget.characterName}對話')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _memory.getRecentMessages(100).length,
              itemBuilder: (context, index) {
                final message = _memory.getRecentMessages(100).reversed.toList()[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.role == 'system') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 關鍵修改：改為 start 對齊
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(widget.avatarAsset),
              ),
            ),
          Flexible( // 使用 Flexible 確保氣泡不會超出屏幕
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Colors.blue[100]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.isUser ? '你' : widget.characterName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: message.isUser ? Colors.blue[800] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(message.content),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/user_avatar.png'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '輸入訊息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? role;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.role,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, String> toApiMap() {
    return {
      'role': role ?? (isUser ? 'user' : 'assistant'),
      'content': content,
    };
  }
}

class ConversationMemory {
  final List<ChatMessage> _messages = [];
  final int _maxMemoryLength;

  ConversationMemory({int maxMemoryLength = 20})
      : _maxMemoryLength = maxMemoryLength;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    if (_messages.length > _maxMemoryLength) {
      _messages.removeAt(0);
    }
  }

  List<Map<String, String>> getMessagesForApi() {
    return _messages.map((msg) => msg.toApiMap()).toList();
  }

  List<ChatMessage> getRecentMessages(int count) {
    final start = _messages.length - count;
    return _messages.sublist(start < 0 ? 0 : start);
  }

  void clear() {
    _messages.clear();
  }
}