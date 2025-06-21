// edit_book_screen.dart
import 'package:flutter/material.dart';
import 'book.dart';
import 'book_data.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _dateController;
  late TextEditingController _introController;

  List<TextEditingController> _chapterTitleControllers = [];
  List<TextEditingController> _chapterContentControllers = [];
  List<TextEditingController> _characterNameControllers = [];
  List<TextEditingController> _characterDescControllers = [];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _dateController = TextEditingController(text: widget.book.date);

    final content = widget.book.content;
    final introMatch =
    RegExp(r'#INTRO#([\s\S]*?)(?=#CHAPTER#|\$)').firstMatch(content);
    _introController =
        TextEditingController(text: introMatch?.group(1)?.trim() ?? '');

    final chapterMatches = RegExp(r'#CHAPTER# (.*?)\n([\s\S]*?)(?=#CHAPTER#|\\$)')
        .allMatches(content);
    _chapterTitleControllers = chapterMatches
        .map((m) => TextEditingController(text: m.group(1)?.trim()))
        .toList();
    _chapterContentControllers = chapterMatches
        .map((m) => TextEditingController(text: m.group(2)?.trim()))
        .toList();

    if (widget.book.characters != null) {
      for (var c in widget.book.characters!) {
        _characterNameControllers.add(TextEditingController(text: c.name));
        _characterDescControllers
            .add(TextEditingController(text: c.description));
      }
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    String content = '#INTRO#\n${_introController.text.trim()}\n';
    for (int i = 0; i < _chapterTitleControllers.length; i++) {
      final title = _chapterTitleControllers[i].text.trim();
      final body = _chapterContentControllers[i].text.trim();
      content += '\n#CHAPTER# ${title.isEmpty ? "第${i + 1}章" : title}\n$body\n';
    }

    final characters = <Character>[];
    for (int i = 0; i < _characterNameControllers.length; i++) {
      final name = _characterNameControllers[i].text.trim();
      final desc = _characterDescControllers[i].text.trim();
      if (name.isNotEmpty) {
        characters.add(Character(name: name, description: desc));
      }
    }

    setState(() {
      widget.book.title = _titleController.text.trim();
      widget.book.author = _authorController.text.trim();
      widget.book.date = _dateController.text.trim();
      widget.book.content = content;
      widget.book.characters = characters;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("已儲存修改")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('編輯書籍')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '書名'),
                validator: (v) => v == null || v.trim().isEmpty ? '請輸入書名' : null,
              ),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: '作者'),
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: '日期'),
              ),
              TextFormField(
                controller: _introController,
                decoration: const InputDecoration(labelText: '簡介'),
                maxLines: 3,
              ),
              const Divider(),
              const Text("角色列表", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              for (int i = 0; i < _characterNameControllers.length; i++) ...[
                TextFormField(
                  controller: _characterNameControllers[i],
                  decoration: InputDecoration(labelText: '角色 ${i + 1} 名字'),
                ),
                TextFormField(
                  controller: _characterDescControllers[i],
                  decoration: InputDecoration(labelText: '角色 ${i + 1} 描述'),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _characterNameControllers.add(TextEditingController());
                        _characterDescControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('新增角色'),
                  ),
                  const SizedBox(width: 8),
                  if (_characterNameControllers.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _characterNameControllers.removeLast();
                          _characterDescControllers.removeLast();
                        });
                      },
                      icon: const Icon(Icons.remove_circle),
                      label: const Text('刪除角色'),
                    ),
                ],
              ),
              const Divider(),
              const Text("章節內容", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              for (int i = 0; i < _chapterTitleControllers.length; i++) ...[
                TextFormField(
                  controller: _chapterTitleControllers[i],
                  decoration: InputDecoration(labelText: '第 ${i + 1} 章標題'),
                ),
                TextFormField(
                  controller: _chapterContentControllers[i],
                  maxLines: 5,
                  decoration: InputDecoration(labelText: '第 ${i + 1} 章內容'),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _chapterTitleControllers
                            .add(TextEditingController(text: '第${_chapterTitleControllers.length + 1}章'));
                        _chapterContentControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('新增章節'),
                  ),
                  const SizedBox(width: 8),
                  if (_chapterTitleControllers.length > 1)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _chapterTitleControllers.removeLast();
                          _chapterContentControllers.removeLast();
                        });
                      },
                      icon: const Icon(Icons.remove),
                      label: const Text('刪除章節'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('儲存修改'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}