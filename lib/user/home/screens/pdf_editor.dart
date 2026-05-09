import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PdfEditorScreen extends StatefulWidget {
  const PdfEditorScreen({super.key});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  File? _selectedFile;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isProcessing = false;
  int _pageCount = 1;

  // Undo/redo history
  final List<File> _history = [];
  int _historyIndex = -1;

  // Formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  Color _selectedColor = Colors.black;

  // ─── History helpers ───────────────────────────────────────────────────────

  void _pushHistory(File file) {
    // Drop any redo entries ahead of current position
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(file);
    _historyIndex = _history.length - 1;
    setState(() => _selectedFile = file);
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _selectedFile = _history[_historyIndex];
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _selectedFile = _history[_historyIndex];
      });
    }
  }

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  // ─── File picking ──────────────────────────────────────────────────────────

  Future<void> _pickAndOpenPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final pageCount = await PdfService.getPageCount(pickedFile);
      _history.clear();
      _historyIndex = -1;
      _pushHistory(pickedFile);
      setState(() => _pageCount = pageCount <= 0 ? 1 : pageCount);
    }
  }

  // ─── Add text annotation ───────────────────────────────────────────────────

  Future<void> _addTextAnnotation() async {
    if (_selectedFile == null) return;

    final textController = TextEditingController();
    final pageController = TextEditingController(text: '1');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text Annotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Type something...',
                border: OutlineInputBorder(),
              ),
              style: TextStyle(
                fontWeight:
                _isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle:
                _isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: _isUnderlined
                    ? TextDecoration.underline
                    : TextDecoration.none,
                color: _selectedColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Page number (1–$_pageCount)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page =
                  int.tryParse(pageController.text.trim()) ?? 1;
              Navigator.pop(context, {
                'text': textController.text,
                'pageIndex': page - 1,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3E5F5),
              foregroundColor: const Color(0xFF7E57C2),
            ),
            child: const Text('Place on PDF'),
          ),
        ],
      ),
    );

    if (result != null &&
        (result['text'] as String).trim().isNotEmpty) {
      final text = (result['text'] as String).trim();
      final pageIndex =
      (result['pageIndex'] as int).clamp(0, _pageCount - 1);
      setState(() => _isProcessing = true);
      try {
        final bytes = await PdfService.addTextToPdfBytes(
          _selectedFile!,
          text,
          const Offset(100, 100),
          pageIndex: pageIndex,
          isBold: _isBold,
          isItalic: _isItalic,
          isUnderlined: _isUnderlined,
          color: _selectedColor,
        );

        final tempDir = await getTemporaryDirectory();
        final tempPath = p.join(
          tempDir.path,
          'temp_editor_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        setState(() => _isProcessing = false);
        _pushHistory(tempFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Text added on page ${pageIndex + 1}')),
          );
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  // ─── Save PDF ──────────────────────────────────────────────────────────────

  Future<void> _saveFinalPdf() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await _selectedFile!.readAsBytes();
      if (!mounted) return;
      final newName =
      await PdfService.showSaveAsDialog(context, 'Edited_Document');
      if (newName != null && newName.isNotEmpty) {
        final path = await PdfService.savePdf(bytes, newName);
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edited PDF Saved!')));
        }
        OpenFile.open(path);
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  // ─── Color picker ──────────────────────────────────────────────────────────

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Colors.black,
            const Color(0xFF7E57C2),
            Colors.red,
            Colors.blue,
            Colors.green,
            Colors.orange,
          ]
              .map(
                (color) => GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: _selectedColor == color
                      ? Border.all(
                      color: Colors.black, width: 3)
                      : Border.all(
                      color: Colors.grey.shade300, width: 1),
                ),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PDF Editor'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_selectedFile == null)
            IconButton(
              icon: const Icon(Icons.folder_open_rounded,
                  color: Color(0xFF7E57C2)),
              onPressed: _pickAndOpenPdf,
              tooltip: 'Open PDF',
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Screenshot-style flat toolbar ──────────────────────────────
          _buildFlatToolbar(),
          // ── PDF viewer or empty state ──────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                _selectedFile == null
                    ? _buildEmptyState()
                    : _buildViewer(),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Flat toolbar matching the screenshot ──────────────────────────────────

  Widget _buildFlatToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // B
          _flatToggleButton(
            label: 'B',
            bold: true,
            active: _isBold,
            onTap: () => setState(() => _isBold = !_isBold),
          ),
          const SizedBox(width: 6),
          // I
          _flatToggleButton(
            label: 'I',
            italic: true,
            active: _isItalic,
            onTap: () => setState(() => _isItalic = !_isItalic),
          ),
          const SizedBox(width: 6),
          // U
          _flatToggleButton(
            label: 'U',
            underline: true,
            active: _isUnderlined,
            onTap: () =>
                setState(() => _isUnderlined = !_isUnderlined),
          ),
          const SizedBox(width: 6),
          // Color palette button
          _flatIconButton(
            child: const Text(
              '🎨',
              style: TextStyle(fontSize: 18),
            ),
            onTap: _showColorPicker,
            active: false,
          ),
          const SizedBox(width: 6),
          // Undo
          _flatIconButton(
            child: Icon(
              Icons.undo_rounded,
              size: 20,
              color: _canUndo ? Colors.black87 : Colors.black26,
            ),
            onTap: _canUndo ? _undo : null,
            active: false,
          ),
          const SizedBox(width: 6),
          // Redo
          _flatIconButton(
            child: Icon(
              Icons.redo_rounded,
              size: 20,
              color: _canRedo ? Colors.black87 : Colors.black26,
            ),
            onTap: _canRedo ? _redo : null,
            active: false,
          ),
          const SizedBox(width: 6),
          // Save PDF (red PDF icon like screenshot)
          _flatIconButton(
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              size: 22,
              color: Color(0xFFD32F2F),
            ),
            onTap: _selectedFile != null ? _saveFinalPdf : null,
            active: false,
          ),
          const Spacer(),
          // Add text annotation (plus button)
          if (_selectedFile != null)
            GestureDetector(
              onTap: _addTextAnnotation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E57C2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Add Text',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Flat bordered button with a text label (B / I / U).
  Widget _flatToggleButton({
    required String label,
    bool bold = false,
    bool italic = false,
    bool underline = false,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFEDE7F6)
              : Colors.white,
          border: Border.all(
            color: active
                ? const Color(0xFF7E57C2)
                : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight:
            bold ? FontWeight.bold : FontWeight.w500,
            fontStyle:
            italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationThickness: 2,
            color: active
                ? const Color(0xFF7E57C2)
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// Flat bordered button with any child widget (icon / emoji).
  Widget _flatIconButton({
    required Widget child,
    VoidCallback? onTap,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEDE7F6) : Colors.white,
          border: Border.all(
            color: active
                ? const Color(0xFF7E57C2)
                : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final r = ResponsiveHelper.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_document,
              size: r.scale(80), color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text('Select a PDF to start editing',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          AppButton(
            icon: Icons.folder_open_rounded,
            label: 'Choose File',
            onPressed: _pickAndOpenPdf,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  // ── PDF viewer ────────────────────────────────────────────────────────────

  Widget _buildViewer() {
    return SfPdfViewer.file(
      _selectedFile!,
      key: _pdfViewerKey,
      enableDoubleTapZooming: true,
      canShowScrollStatus: true,
    );
  }
}