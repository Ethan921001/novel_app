import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';


void main() {
  /// Call the runApp function to start the app
  runApp(const MyApp());
}

/// The [MyApp] widget is the root widget of the app
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      /// Set the app theme to use Material 3
      theme: ThemeData(
        useMaterial3: true,
      ),

      /// Set the app home page to be the Test widget
      home: CharacterSelectionPage(),
    );
  }
}


class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}

class OpenAIService {
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> sendMessageAsCharacter({
    required String message,
    required String characterDescription,
    List<Map<String, String>> history = const [],
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': '''
      你現在要扮演以下角色：
      $characterDescription
      
      請注意：
      1. 完全以角色身份回應
      2. 保持角色語言風格
      3. 回答簡潔，2-3句話
      
      '''
      },
      ...history,
      {'role': 'user', 'content': message},
    ];

    return sendMessage(messages: messages);
  }


  Future<String> sendMessage({
    required List<Map<String, String>> messages,
    String model = 'gpt-3.5-turbo',
    double temperature = 0.7,
    int maxTokens = 500,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('请求出错: $e');
    }
  }
}

class ChatPage extends StatefulWidget {
  final Character? character;

  const ChatPage({super.key, this.character});

  @override
  State<ChatPage> createState() => _ChatPageState();
}



class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final OpenAIService _openAIService = OpenAIService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 延遲一小段時間後發送歡迎消息
    Future.delayed(const Duration(milliseconds: 500), () {
      _addWelcomeMessage();
    });
  }

  void _addWelcomeMessage() async{

    final welcome_text = await _openAIService.sendMessageAsCharacter(
      message: "現在自我介紹，並打招呼",
      characterDescription: widget.character!.description,
      history: _messages.reversed
          .where((msg) => msg.content.isNotEmpty)
          .map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      })
          .toList(),

    );
    setState(() {
      _messages.add(ChatMessage.assistant(welcome_text));
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI聊天'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages.reversed.toList()[index];
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.isUser)
                const CircleAvatar(
                  child: Icon(Icons.android),
                ),
              const SizedBox(width: 8),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 8),
              if (message.isUser)
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: MarkdownBody(
              data: message.content,
              selectable: true,
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
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isLoading
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isLoading) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage.user(userMessage));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final messages = _messages.reversed
          .map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      })
          .toList();

      final response;
      // if (widget.character != null) {
      //   response = await _openAIService.sendMessageAsCharacter(
      //     message: userMessage,
      //     characterDescription: widget.character!.description,
      //     history: _messages.reversed
      //         .where((msg) => msg.content.isNotEmpty)
      //         .map((msg) => {
      //       'role': msg.isUser ? 'user' : 'assistant',
      //       'content': msg.content,
      //     })
      //         .toList(),
      //   );
      // } else {
        // 普通聊天模式
        response = await _openAIService.sendMessage(
          messages: _messages.reversed
              .where((msg) => msg.content.isNotEmpty)
              .map((msg) => {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.content,
          })
              .toList(),
        );
      // }

      setState(() {
        _messages.add(ChatMessage.assistant(response));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage.assistant('出错: $e'));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
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

  void _clearConversation() {
    setState(() {
      _messages.clear();
    });
  }
}


// 创建角色选择界面
class CharacterSelectionPage extends StatelessWidget {
  final List<Character> characters = [
    Character(
      name: '武侠剑客',
      description: '一位年过五旬的武林前辈，说话带有古风，常用成语典故',
    ),
    Character(
      name: '科幻AI',
      description: '高度智能的未来AI，回答精确且逻辑性强，带有科技感',
    ),
    // 更多角色...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择角色')),
      body: ListView.builder(
        itemCount: characters.length,
        itemBuilder: (context, index) {
          final character = characters[index];
          return ListTile(
            title: Text(character.name),
            subtitle: Text(character.description),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    character: character,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Character {
  final String name;
  final String description;

  Character({required this.name, required this.description});
}
