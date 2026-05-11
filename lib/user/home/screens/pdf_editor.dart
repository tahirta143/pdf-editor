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
  int _currentPageNumber = 1;

  // Undo/redo history
  final List<File> _history = [];
  int _historyIndex = -1;

  // Formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;
  Color _selectedColor = Colors.black;

  // ── Inline overlay state ─────────────────────────────────────────────────
  bool _showInlineEditor = false;
  Offset _overlayPosition = Offset.zero;
  double _overlayWidth = 300;
  String _originalText = '';
  Rect _tappedBounds = Rect.zero;
  int _tappedPageIndex = 0;
  final TextEditingController _inlineController = TextEditingController();
  final FocusNode _inlineFocus = FocusNode();

  /// Key on the Stack that wraps SfPdfViewer — lets us read its size/position.
  final GlobalKey _viewerKey = GlobalKey();

  @override
  void dispose() {
    _inlineController.dispose();
    _inlineFocus.dispose();
    super.dispose();
  }

  // ─── History helpers ──────────────────────────────────────────────────────

  void _pushHistory(File file) {
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

  // ─── File picking ─────────────────────────────────────────────────────────

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
      _currentPageNumber = 1;
      _pushHistory(pickedFile);
      setState(() => _pageCount = pageCount <= 0 ? 1 : pageCount);
    }
  }

  // ─── TAP-TO-EDIT ──────────────────────────────────────────────────────────

  Future<void> _handlePdfTap(PdfGestureDetails details) async {
    // A tap while the overlay is open → dismiss it (no save).
    if (_showInlineEditor) {
      setState(() => _showInlineEditor = false);
      _inlineFocus.unfocus();
      return;
    }

    if (_selectedFile == null || _isProcessing) return;

    final int pageIndex = details.pageNumber - 1;
    final Offset tapPos = details.pagePosition;

    setState(() => _isProcessing = true);

    try {
      final result = await PdfService.findTextAtPosition(
        _selectedFile!,
        pageIndex,
        tapPos,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tap on text to edit it'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // ── Position the overlay ─────────────────────────────────────────────
      // Use full viewer width minus a small horizontal padding on each side.
      final viewerSize = _viewerKey.currentContext?.size ?? Size.zero;
      const double hPad = 12.0;
      final double overlayW = viewerSize.width - hPad * 2;

      // Convert global screen position → local position inside the viewer Stack.
      Offset localTap = details.position;
      final ro = _viewerKey.currentContext?.findRenderObject();
      if (ro is RenderBox) localTap = ro.globalToLocal(details.position);

      // Place the overlay above the tap; flip below if too close to the top.
      // We don't know the final height (it auto-sizes to content), so we
      // use a generous estimate of 200 px for the flip calculation.
      const double estimatedH = 200.0;
      double dy = localTap.dy - estimatedH - 8;
      if (dy < 8) dy = localTap.dy + 24;

      _originalText = result.text;
      _tappedBounds = result.bounds;
      _tappedPageIndex = pageIndex;

      _inlineController.text = result.text;
      _inlineController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: result.text.length,
      );

      setState(() {
        _overlayPosition = Offset(hPad, dy);
        _overlayWidth = overlayW;
        _showInlineEditor = true;
      });

      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _inlineFocus.requestFocus();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ─── Apply inline edit ────────────────────────────────────────────────────

  Future<void> _applyInlineEdit() async {
    final newText = _inlineController.text.trim();
    setState(() => _showInlineEditor = false);
    _inlineFocus.unfocus();

    if (newText.isEmpty || newText == _originalText.trim()) return;

    setState(() => _isProcessing = true);
    try {
      final List<int> bytes = await PdfService.editTextAtBounds(
        _selectedFile!,
        _tappedPageIndex,
        _tappedBounds,
        newText,
        isBold: _isBold,
        isItalic: _isItalic,
        isUnderlined: _isUnderlined,
        color: _selectedColor,
      );

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = p.join(
        tempDir.path,
        'edited_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      if (!mounted) return;
      setState(() => _isProcessing = false);
      _pushHistory(tempFile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Text updated'),
            ],
          ),
          backgroundColor: const Color(0xFF7E57C2),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Edit failed: $e')));
      }
    }
  }

  // ─── Add text annotation ──────────────────────────────────────────────────

  Future<void> _addTextAnnotation() async {
    if (_selectedFile == null) return;

    final textController = TextEditingController();
    final pageController = TextEditingController(text: '$_currentPageNumber');

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
                fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
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
              final page = int.tryParse(pageController.text.trim()) ?? 1;
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

    if (result != null && (result['text'] as String).trim().isNotEmpty) {
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

  // ─── Save PDF ─────────────────────────────────────────────────────────────

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
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Edited PDF Saved!')));
        }
        OpenFile.open(path);
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  // ─── Color picker ─────────────────────────────────────────────────────────

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
                      ? Border.all(color: Colors.black, width: 3)
                      : Border.all(color: Colors.grey.shade300, width: 1),
                ),
              ),
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
          _buildFlatToolbar(),
          if (_selectedFile != null) _buildEditHintBanner(),
          Expanded(
            child: Stack(
              children: [
                _selectedFile == null
                    ? _buildEmptyState()
                    : _buildViewerWithOverlay(),
                if (_isProcessing)
                  Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: Color(0xFF7E57C2)),
                              SizedBox(height: 12),
                              Text('Processing…'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF viewer + inline overlay Stack ────────────────────────────────────

  Widget _buildViewerWithOverlay() {
    return Stack(
      key: _viewerKey,
      children: [
        // ── PDF viewer ────────────────────────────────────────────────────
        SfPdfViewer.file(
          _selectedFile!,
          key: _pdfViewerKey,
          enableDoubleTapZooming: true,
          canShowScrollStatus: true,
          onPageChanged: (PdfPageChangedDetails details) {
            _currentPageNumber = details.newPageNumber;
          },
          onTap: _handlePdfTap,
        ),

        // ── Inline text overlay ───────────────────────────────────────────
        if (_showInlineEditor)
          Positioned(
            left: _overlayPosition.dx,
            top: _overlayPosition.dy,
            child: _InlineTextEditor(
              controller: _inlineController,
              focusNode: _inlineFocus,
              isBold: _isBold,
              isItalic: _isItalic,
              isUnderlined: _isUnderlined,
              color: _selectedColor,
              width: _overlayWidth,
              onApply: _applyInlineEdit,
              onDismiss: () {
                setState(() => _showInlineEditor = false);
                _inlineFocus.unfocus();
              },
            ),
          ),
      ],
    );
  }

  // ── Hint banner ───────────────────────────────────────────────────────────

  Widget _buildEditHintBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEDE7F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: const Row(
        children: [
          Icon(Icons.touch_app_rounded, size: 15, color: Color(0xFF7E57C2)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tap any text in the PDF to edit it inline',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7E57C2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Flat toolbar ──────────────────────────────────────────────────────────

  Widget _buildFlatToolbar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _flatToggleButton(
            label: 'B',
            bold: true,
            active: _isBold,
            onTap: () => setState(() => _isBold = !_isBold),
          ),
          const SizedBox(width: 6),
          _flatToggleButton(
            label: 'I',
            italic: true,
            active: _isItalic,
            onTap: () => setState(() => _isItalic = !_isItalic),
          ),
          const SizedBox(width: 6),
          _flatToggleButton(
            label: 'U',
            underline: true,
            active: _isUnderlined,
            onTap: () => setState(() => _isUnderlined = !_isUnderlined),
          ),
          const SizedBox(width: 6),
          _flatIconButton(
            child: const Text('🎨', style: TextStyle(fontSize: 18)),
            onTap: _showColorPicker,
            active: false,
          ),
          const SizedBox(width: 6),
          _flatIconButton(
            child: Icon(Icons.undo_rounded,
                size: 20,
                color: _canUndo ? Colors.black87 : Colors.black26),
            onTap: _canUndo ? _undo : null,
            active: false,
          ),
          const SizedBox(width: 6),
          _flatIconButton(
            child: Icon(Icons.redo_rounded,
                size: 20,
                color: _canRedo ? Colors.black87 : Colors.black26),
            onTap: _canRedo ? _redo : null,
            active: false,
          ),
          const SizedBox(width: 6),
          _flatIconButton(
            child: const Icon(Icons.picture_as_pdf_rounded,
                size: 22, color: Color(0xFFD32F2F)),
            onTap: _selectedFile != null ? _saveFinalPdf : null,
            active: false,
          ),
          // const Spacer(),
          // if (_selectedFile != null)
          //   GestureDetector(
          //     onTap: _addTextAnnotation,
          //     child: Container(
          //       padding:
          //       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //       decoration: BoxDecoration(
          //         color: const Color(0xFF7E57C2),
          //         borderRadius: BorderRadius.circular(20),
          //       ),
          //       child: const Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Icon(Icons.add, color: Colors.white, size: 16),
          //           SizedBox(width: 4),
          //           Text(
          //             'Add Text',
          //             style: TextStyle(
          //                 color: Colors.white,
          //                 fontSize: 13,
          //                 fontWeight: FontWeight.w600),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

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
          color: active ? const Color(0xFFEDE7F6) : Colors.white,
          border: Border.all(
            color: active ? const Color(0xFF7E57C2) : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration:
            underline ? TextDecoration.underline : TextDecoration.none,
            decorationThickness: 2,
            color: active ? const Color(0xFF7E57C2) : Colors.black87,
          ),
        ),
      ),
    );
  }

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
            color: active ? const Color(0xFF7E57C2) : Colors.grey.shade400,
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
}

// ─── Inline text editor overlay ──────────────────────────────────────────────
//
// A floating card that appears directly on the PDF page.
// The TextField is fully multiline and auto-expands — no scrolling.
// Action buttons (Cancel / Apply) sit in their own row below the field.

class _InlineTextEditor extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;
  final Color color;
  final double width;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _InlineTextEditor({
    required this.controller,
    required this.focusNode,
    required this.isBold,
    required this.isItalic,
    required this.isUnderlined,
    required this.color,
    required this.width,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7E57C2), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // shrink-wrap height to content
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header label ───────────────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE7F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_rounded,
                      size: 14, color: Color(0xFF7E57C2)),
                  SizedBox(width: 6),
                  Text(
                    'Edit Text',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E57C2),
                    ),
                  ),
                ],
              ),
            ),

            // ── Multiline, auto-expanding text field ───────────────────────
            // maxLines: null  → grows with content, never scrolls
            // minLines: 2     → at least 2 lines tall so short text isn't cramped
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,   // ← key: unlimited lines, no scroll
                minLines: 2,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: isUnderlined
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  color: color,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(0),
                  border: InputBorder.none,
                  hintText: 'Edit text…',
                  hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            ),

            const Divider(
                height: 1, thickness: 1, color: Color(0xFFEDE7F6)),

            // ── Action buttons row ─────────────────────────────────────────
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel
                  TextButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Apply
                  ElevatedButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E57C2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}