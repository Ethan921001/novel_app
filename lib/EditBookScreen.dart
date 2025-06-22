import 'package:flutter/material.dart';
import 'book.dart';
import 'book_data.dart';

class BookFormScreen extends StatefulWidget {
  final Book? book; // 若為 null 則為新增，否則為編輯

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  int step = 1;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _dateController = TextEditingController();
  final _viewsController = TextEditingController();
  final _favoritesController = TextEditingController();

  int characterCount = 0;
  List<TextEditingController> _characterNameControllers = [];
  List<TextEditingController> _characterDescControllers = [];

  final _introController = TextEditingController();
  List<TextEditingController> _chapterTitleControllers = [];
  List<TextEditingController> _chapterContentControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _dateController.text = book.date;
      _viewsController.text = book.views.toString();
      _favoritesController.text = book.favorites.toString();

      characterCount = book.characters.length;
      _characterNameControllers = book.characters
          .map((c) => TextEditingController(text: c.name))
          .toList();
      _characterDescControllers = book.characters
          .map((c) => TextEditingController(text: c.description))
          .toList();

      final contentLines = book.content.split('\n');
      final introLines = <String>[];
      final chapterTitles = <String>[];
      final chapterBodies = <String>[];

      bool inIntro = false, inChapter = false;
      String currentBody = '';

      for (String line in contentLines) {
        if (line.startsWith('#INTRO#')) {
          inIntro = true;
          inChapter = false;
          continue;
        }
        if (line.startsWith('#CHAPTER#')) {
          if (currentBody.isNotEmpty) {
            chapterBodies.add(currentBody.trim());
            currentBody = '';
          }
          inIntro = false;
          inChapter = true;
          chapterTitles.add(line.replaceFirst('#CHAPTER#', '').trim());
          continue;
        }
        if (inIntro) {
          introLines.add(line);
        } else if (inChapter) {
          currentBody += '$line\n';
        }
      }
      if (currentBody.isNotEmpty) {
        chapterBodies.add(currentBody.trim());
      }

      _introController.text = introLines.join('\n').trim();
      _chapterTitleControllers = chapterTitles
          .map((title) => TextEditingController(text: title))
          .toList();
      _chapterContentControllers = chapterBodies
          .map((body) => TextEditingController(text: body))
          .toList();
    }
  }

  void _prepareCharacters() {
    _characterNameControllers =
        List.generate(characterCount, (_) => TextEditingController());
    _characterDescControllers =
        List.generate(characterCount, (_) => TextEditingController());
  }

  void _addChapter() {
    setState(() {
      _chapterTitleControllers.add(TextEditingController());
      _chapterContentControllers.add(TextEditingController());
    });
  }

  void _removeChapter(int index) {
    setState(() {
      _chapterTitleControllers.removeAt(index);
      _chapterContentControllers.removeAt(index);
    });
  }

  void _saveOrUpdateBook() {
    // if (!(_formKey.currentState?.validate() ?? false)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("請確認書名是否填寫")),
    //   );
    //   return;
    // }

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

    final isEdit = widget.book != null;
    final book = widget.book ??
        Book('', '', '', 0, 0, '', 'assets/images/book_default.png', [], '');

    book.title = _titleController.text.trim();
    book.author = _authorController.text.trim();
    book.date = _dateController.text.trim();
    book.views = int.tryParse(_viewsController.text.trim()) ?? 0;
    book.favorites = int.tryParse(_favoritesController.text.trim()) ?? 0;
    book.content = content;
    book.characters = characters;

    if (!isEdit) {
      books.add(book);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "成功修改" : "新增成功"),
        content: Text(isEdit ? "書籍內容已更新" : "書籍已新增"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("確定"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '編輯書籍' : '新增書籍')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: step == 1
            ? _buildStep1()
            : step == 2
            ? _buildStep2()
            : _buildStep3(),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '書名'),
            validator: (v) => v == null || v.isEmpty ? '請輸入書名' : null,
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
            controller: _viewsController,
            decoration: const InputDecoration(labelText: '瀏覽次數'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: _favoritesController,
            decoration: const InputDecoration(labelText: '收藏數'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => step = 2);
            },
            child: const Text('下一步：輸入角色'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return ListView(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: '角色數量'),
          keyboardType: TextInputType.number,
          initialValue: characterCount.toString(),
          onChanged: (value) {
            final count = int.tryParse(value.trim()) ?? 0;
            setState(() {
              characterCount = count;
              _prepareCharacters();
            });
          },
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < characterCount; i++) ...[
          TextFormField(
            controller: i < _characterNameControllers.length
                ? _characterNameControllers[i]
                : TextEditingController(),
            decoration: InputDecoration(labelText: '角色 ${i + 1} 名字'),
          ),
          TextFormField(
            controller: i < _characterDescControllers.length
                ? _characterDescControllers[i]
                : TextEditingController(),
            decoration: InputDecoration(labelText: '角色 ${i + 1} 描述'),
          ),
          const Divider(),
        ],
        ElevatedButton(
          onPressed: () => setState(() => step = 3),
          child: const Text('下一步：輸入章節'),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      children: [
        TextFormField(
          controller: _introController,
          decoration: const InputDecoration(labelText: '簡介'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const Text('章節內容',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (int i = 0; i < _chapterTitleControllers.length; i++) ...[
          TextFormField(
            controller: _chapterTitleControllers[i],
            decoration: InputDecoration(labelText: '第 ${i + 1} 章 標題'),
          ),
          TextFormField(
            controller: _chapterContentControllers[i],
            maxLines: 4,
            decoration: InputDecoration(labelText: '第 ${i + 1} 章 內容'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _removeChapter(i),
                icon: const Icon(Icons.delete),
              )
            ],
          ),
          const Divider(),
        ],
        ElevatedButton(
          onPressed: _addChapter,
          child: const Text('新增章節'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveOrUpdateBook,
          child: const Text('完成'),
        ),
      ],
    );
  }
}
