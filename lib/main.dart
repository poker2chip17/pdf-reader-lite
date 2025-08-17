```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiteApp());
}

class LiteApp extends StatelessWidget {
  const LiteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Reader Lite',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const LiteHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LiteHomePage extends StatefulWidget {
  const LiteHomePage({super.key});
  @override
  State<LiteHomePage> createState() => _LiteHomePageState();
}

class _LiteHomePageState extends State<LiteHomePage> {
  String? _lastFileName;
  int? _lastPage;

  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastFileName = prefs.getString('last_file_name');
      _lastPage = prefs.getInt('last_page');
    });
  }

  Future<void> _openPicker() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final file = res.files.single;
    final data = file.bytes ?? await File(file.path!).readAsBytes();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiteViewerPage(
          fileName: file.name,
          pdfBytes: data,
        ),
      ),
    ).then((_) => _loadLast());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Reader Lite')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เริ่มจากศูนย์: เลือกไฟล์ PDF แล้วแอพจะจำหน้าที่อ่านค้างไว้ให้'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openPicker,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('เปิดไฟล์ PDF'),
            ),
            const SizedBox(height: 24),
            if (_lastFileName != null && _lastPage != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_lastFileName!),
                  subtitle: Text('ค้างที่หน้า $_lastPage'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LiteViewerPage extends StatefulWidget {
  final String fileName;
  final Uint8List pdfBytes;
  const LiteViewerPage({super.key, required this.fileName, required this.pdfBytes});
  @override
  State<LiteViewerPage> createState() => _LiteViewerPageState();
}

class _LiteViewerPageState extends State<LiteViewerPage> {
  late final PdfControllerPinch _controller;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(widget.pdfBytes),
    );
    _controller.addListener(() {
      final p = _controller.page ?? 1;
      if (p != _currentPage) {
        _currentPage = p;
        _saveLocal(p);
        setState(() {});
      }
    });
  }

  Future<void> _saveLocal(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_page', page);
    await prefs.setString('last_file_name', widget.fileName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.fileName} — $_currentPage/$_totalPages')),
      body: PdfViewPinch(
        controller: _controller,
        onDocumentLoaded: (doc) => setState(() => _totalPages = doc.pagesCount),
        onPageChanged: (page) {
          _currentPage = page;
          _saveLocal(page);
          setState(() {});
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'prev',
            onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
            child: const Icon(Icons.chevron_left),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'next',
            onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
            child: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
```
