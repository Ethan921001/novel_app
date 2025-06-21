import 'package:flutter/material.dart';
import 'book.dart';
import 'book_data.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  // Step control
  int step = 1;

  // Step 1 - 基本資料
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _dateController = TextEditingController();
  final _viewsController = TextEditingController();
  final _favoritesController = TextEditingController();

  // Step 2 - 角色
  int characterCount = 0;
  List<TextEditingController> _characterNameControllers = [];
  List<TextEditingController> _characterDescControllers = [];

  // Step 3 - 簡介與章節
  final _introController = TextEditingController();
  List<TextEditingController> _chapterTitleControllers = [];
  List<TextEditingController> _chapterContentControllers = [];

  void _prepareCharacters() {
    _characterNameControllers = List.generate(characterCount, (_) => TextEditingController());
    _characterDescControllers = List.generate(characterCount, (_) => TextEditingController());
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

  void _saveBook() {
    // print("✅ 進入 saveBook()");
    // print('title: "${_titleController.text}"');
    // if (!(_formKey.currentState?.validate() ?? false)) {
    //   print("❌ 表單驗證失敗");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("請確認書名是否填寫")),
    //   );
    //   return;
    // }

    // print("✅ 表單驗證通過");
    {
      // 整理 content
      String content = '#INTRO#\n${_introController.text.trim()}\n';
      for (int i = 0; i < _chapterTitleControllers.length; i++) {
        final title = _chapterTitleControllers[i].text.trim();
        final body = _chapterContentControllers[i].text.trim();
        content += '\n#CHAPTER# ${title.isEmpty ? "第${i + 1}章" : title}\n$body\n';
      }

      // 整理角色
      final characters = <Character>[];
      for (int i = 0; i < _characterNameControllers.length; i++) {
        final name = _characterNameControllers[i].text.trim();
        final desc = _characterDescControllers[i].text.trim();
        if (name.isNotEmpty) {
          characters.add(Character(name: name, description: desc));
        }
      }

      Book newBook = Book(
        _titleController.text.trim(),
        _authorController.text.trim(),
        _dateController.text.trim(),
        int.tryParse(_viewsController.text.trim()) ?? 0,
        int.tryParse(_favoritesController.text.trim()) ?? 0,
        content,
        'assets/images/no_image.png',
        characters,
        _authorController.text.trim(),
      );

      books.add(newBook);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("成功！"),
          content: const Text("書籍已新增"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();       // 關閉 dialog
                Navigator.of(context).pop();   // 返回上一頁
              },
              child: const Text("確定"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增書籍')),
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
            controller: _characterNameControllers[i],
            decoration: InputDecoration(labelText: '角色 ${i + 1} 名字'),
          ),
          TextFormField(
            controller: _characterDescControllers[i],
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
        const Text('章節內容', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          onPressed: _saveBook,
          child: const Text('完成新增書籍'),
        ),
      ],
    );
  }
}
