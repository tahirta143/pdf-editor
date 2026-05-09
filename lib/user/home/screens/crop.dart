import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';

class CropPdfScreen extends StatefulWidget {
  const CropPdfScreen({super.key});

  @override
  State<CropPdfScreen> createState() => _CropPdfState();
}

class _CropPdfState extends State<CropPdfScreen> {
  File? selectedFile;
  Uint8List? fileBytes;

  /// One thumbnail per page (null while still loading that page)
  List<Uint8List?> pageThumbs = [];

  Size? firstPagePdfSize;
  bool isLoading = false;
  bool isProcessing = false;
  String? savedPath;

  /// Per-page crop rects stored here. Falls back to [_defaultCrop] if absent.
  final Map<int, Rect> _cropRects = {};
  int _selectedPageIndex = 0;
  int _pageCount = 0;

  String selectedPageSize = 'crop';
  bool fitCropToPage = false;
  String? _pdfPassword;
  bool _applyToAllPages = true;

  static const double _minCropSide = 0.12;
  static const Rect _defaultCrop = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);

  // Scroll controller so we can jump to the selected thumbnail
  final ScrollController _thumbScrollController = ScrollController();

  Rect get _currentCropRect =>
      _cropRects[_selectedPageIndex] ?? _defaultCrop;

  // ─────────────────────────────────────────────────────────────────────────
  // File picking & loading
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      selectedFile = File(result.files.single.path!);
      savedPath = null;
      isLoading = true;
      _pdfPassword = null;
      _pageCount = 0;
      _selectedPageIndex = 0;
      _cropRects.clear();
      pageThumbs = [];
    });
    _loadAllPages();
  }

  Future<void> _loadAllPages() async {
    if (selectedFile == null) return;
    try {
      final pageCount = await PdfService.getPageCountWithPassword(
        selectedFile!,
        password: _pdfPassword,
      );
      if (pageCount <= 0) throw Exception('No pages found in PDF.');

      fileBytes = await PdfService.buildPreviewPdfBytes(
        selectedFile!,
        password: _pdfPassword,
      );

      final pageSize = await PdfService.getPageSize(
        selectedFile!,
        pageIndex: 0,
        password: _pdfPassword,
      );

      if (!mounted) return;
      setState(() {
        _pageCount = pageCount;
        firstPagePdfSize = pageSize;
        pageThumbs = List<Uint8List?>.filled(pageCount, null, growable: false);
        isLoading = false;
      });

      for (int i = 0; i < pageCount; i++) {
        if (!mounted) return;
        final thumb = await PdfService.rasterizePage(fileBytes!, i);
        if (!mounted) return;
        setState(() => pageThumbs[i] = thumb);
      }
    } catch (e) {
      if (!mounted) return;
      if (PdfService.isEncryptedPdfError(e)) {
        final pass =
        await PdfService.showPasswordDialog(context, 'Encrypted PDF');
        if (pass == null || pass.isEmpty) {
          setState(() => isLoading = false);
          _showSnack('Password required to open this PDF.');
          return;
        }
        _pdfPassword = pass;
        await _loadAllPages();
        return;
      }
      setState(() => isLoading = false);
      _showSnack('Could not load PDF: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Crop & save
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _processCropAndSave() async {
    if (selectedFile == null) return;
    setState(() => isProcessing = true);

    try {
      final bytes = await PdfService.cropPdfBytes(
        selectedFile!,
        _currentCropRect,
        outputPageSize: _selectedOutputPageSize(),
        fitToPage: fitCropToPage,
        password: _pdfPassword,
        pageIndex: _applyToAllPages ? null : _selectedPageIndex,
      );

      if (!mounted) return;

      final originalName = selectedFile!.path
          .split(Platform.pathSeparator)
          .last
          .replaceAll('.pdf', '');
      final newName =
      await PdfService.showSaveAsDialog(context, 'cropped_$originalName');

      if (newName != null && newName.isNotEmpty) {
        final path = await PdfService.savePdf(bytes, newName);
        setState(() {
          savedPath = path;
          isProcessing = false;
        });
        _showSnack('PDF Cropped Successfully!');
      } else {
        setState(() => isProcessing = false);
      }
    } catch (e) {
      setState(() => isProcessing = false);
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F6),
      appBar: AppBar(
        title: const Text('Crop PDF'),
        elevation: 0,
        backgroundColor: const Color(0xFFF3F1F6),
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppButton(
              icon: Icons.attach_file,
              label: selectedFile == null ? 'Pick PDF' : 'Change',
              onPressed: pickPdf,
              fullWidth: false,
            ),
          ),
        ],
      ),
      body: selectedFile == null
          ? _buildEmptyState()
          : isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainLayout(),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final r = ResponsiveHelper.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.crop_free, size: r.scale(80), color: Colors.grey.shade300),
          SizedBox(height: r.hp(2)),
          Text('Open a PDF to start cropping',
              style: TextStyle(color: Colors.grey, fontSize: r.sp(14))),
          SizedBox(height: r.hp(3)),
          AppButton(
            icon: Icons.attach_file,
            label: 'Pick PDF',
            onPressed: pickPdf,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  // ── Main layout ────────────────────────────────────────────────────────────

  Widget _buildMainLayout() {
    return Stack(
      children: [
        Column(
          children: [
            _buildOptionsBar(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageList(),
                  Expanded(child: _buildCropPreview()),
                ],
              ),
            ),
            _buildBottomToolbar(),
          ],
        ),
        if (isProcessing) const Center(child: CircularProgressIndicator()),
        if (savedPath != null) _buildSaveSuccessOverlay(),
      ],
    );
  }

  // ── Options bar ────────────────────────────────────────────────────────────

  Widget _buildOptionsBar() {
    const primaryColor = Color(0xFF0B2D5C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E4F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _applyToAllPages,
              activeColor: primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) =>
                  setState(() => _applyToAllPages = v ?? true),
            ),
          ),
          const SizedBox(width: 6),
          const Text('All pages',
              style: TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD7CCE8)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPageSize,
                  isDense: true,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'crop',
                        child: Text('Crop size',
                            style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(
                        value: 'original',
                        child: Text('Original size',
                            style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(
                        value: 'a4',
                        child: Text('A4',
                            style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(
                        value: 'letter',
                        child: Text('Letter',
                            style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => selectedPageSize = v);
                  },
                ),
              ),
            ),
          ),
          if (selectedPageSize != 'crop') ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: fitCropToPage,
                activeColor: primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) =>
                    setState(() => fitCropToPage = v ?? false),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Fit',
                style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ],
      ),
    );
  }

  // ── Page thumbnail list ────────────────────────────────────────────────────

  Widget _buildPageList() {
    return Container(
      width: 80,
      color: const Color(0xFFEDE9F5),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFF0B2D5C),
            child: Text(
              '$_pageCount pages',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _thumbScrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _pageCount,
              itemBuilder: (context, index) => _buildThumbItem(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbItem(int index) {
    final isSelected = index == _selectedPageIndex;
    final hasCrop =
        _cropRects.containsKey(index) && !_applyToAllPages;
    final thumb =
    pageThumbs.length > index ? pageThumbs[index] : null;

    return GestureDetector(
      onTap: () => setState(() => _selectedPageIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color:
            isSelected ? const Color(0xFF7E57C2) : Colors.transparent,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            if (isSelected)
              const BoxShadow(
                  color: Color(0x447E57C2), blurRadius: 8, spreadRadius: 1)
            else
              BoxShadow(
                  color: Colors.black.withOpacity(0.1), blurRadius: 3),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 0.707,
                child: thumb != null
                    ? Image.memory(thumb, fit: BoxFit.cover)
                    : Container(
                  color: Colors.white,
                  child: const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: isSelected
                      ? const Color(0xFF7E57C2).withOpacity(0.88)
                      : Colors.black.withOpacity(0.45),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (hasCrop)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFF4EA0FF),
                        shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Crop preview ───────────────────────────────────────────────────────────

  Widget _buildCropPreview() {
    final thumb = pageThumbs.length > _selectedPageIndex
        ? pageThumbs[_selectedPageIndex]
        : null;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFFF3F1F6),
          child: Text(
            'Page ${_selectedPageIndex + 1}  •  Drag crop box or handles to adjust',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final Size pageSize =
                  firstPagePdfSize ?? const Size(3, 4);
              final double aspect = pageSize.width / pageSize.height;
              final double maxW = constraints.maxWidth - 24;
              final double maxH = constraints.maxHeight - 16;

              double pw = maxW;
              double ph = pw / aspect;
              if (ph > maxH) {
                ph = maxH;
                pw = ph * aspect;
              }

              final Rect crop = _currentCropRect;
              final Rect cropPx = Rect.fromLTWH(
                crop.left * pw,
                crop.top * ph,
                crop.width * pw,
                crop.height * ph,
              );

              return Center(
                child: Container(
                  width: pw,
                  height: ph,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Page image
                      if (thumb != null)
                        Positioned.fill(
                          child: Image.memory(thumb, fit: BoxFit.fill),
                        )
                      else
                        const Center(child: CircularProgressIndicator()),

                      // Dark overlay outside crop
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DarkOverlayPainter(cropPx),
                        ),
                      ),

                      // Draggable + resizable crop box
                      Positioned(
                        left: cropPx.left,
                        top: cropPx.top,
                        child: GestureDetector(
                          // Move the whole box
                          onPanUpdate: (d) {
                            final dx = d.delta.dx / pw;
                            final dy = d.delta.dy / ph;
                            final c = _currentCropRect;
                            setState(() {
                              _cropRects[_selectedPageIndex] =
                                  Rect.fromLTWH(
                                    (c.left + dx).clamp(0.0, 1.0 - c.width),
                                    (c.top + dy).clamp(0.0, 1.0 - c.height),
                                    c.width,
                                    c.height,
                                  );
                            });
                          },
                          child: Container(
                            width: cropPx.width,
                            height: cropPx.height,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF7E57C2), width: 2),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // ── 4 Corner handles ──────────────────────
                                // Top-left
                                _buildHandle(
                                  left: -9,
                                  top: -9,
                                  onPanUpdate: (d) => _resizeCrop(
                                    -d.delta.dx / pw,
                                    -d.delta.dy / ph,
                                    moveLeft: true,
                                    moveTop: true,
                                  ),
                                ),
                                // Top-right
                                _buildHandle(
                                  right: -9,
                                  top: -9,
                                  onPanUpdate: (d) => _resizeCrop(
                                    d.delta.dx / pw,
                                    -d.delta.dy / ph,
                                    moveTop: true,
                                  ),
                                ),
                                // Bottom-left
                                _buildHandle(
                                  left: -9,
                                  bottom: -9,
                                  onPanUpdate: (d) => _resizeCrop(
                                    -d.delta.dx / pw,
                                    d.delta.dy / ph,
                                    moveLeft: true,
                                  ),
                                ),
                                // Bottom-right
                                _buildHandle(
                                  right: -9,
                                  bottom: -9,
                                  onPanUpdate: (d) => _resizeCrop(
                                    d.delta.dx / pw,
                                    d.delta.dy / ph,
                                  ),
                                ),

                                // ── 4 Edge-center handles ──────────────────
                                // Top-center
                                _buildEdgeCenterHandle(
                                  top: -9,
                                  left: 0,
                                  right: 0,
                                  alignment: Alignment.topCenter,
                                  onPanUpdate: (d) => _resizeCrop(
                                    0,
                                    -d.delta.dy / ph,
                                    moveTop: true,
                                  ),
                                ),
                                // Bottom-center
                                _buildEdgeCenterHandle(
                                  bottom: -9,
                                  left: 0,
                                  right: 0,
                                  alignment: Alignment.bottomCenter,
                                  onPanUpdate: (d) => _resizeCrop(
                                    0,
                                    d.delta.dy / ph,
                                  ),
                                ),
                                // Left-center
                                _buildEdgeCenterHandle(
                                  left: -9,
                                  top: 0,
                                  bottom: 0,
                                  alignment: Alignment.centerLeft,
                                  onPanUpdate: (d) => _resizeCrop(
                                    -d.delta.dx / pw,
                                    0,
                                    moveLeft: true,
                                  ),
                                ),
                                // Right-center
                                _buildEdgeCenterHandle(
                                  right: -9,
                                  top: 0,
                                  bottom: 0,
                                  alignment: Alignment.centerRight,
                                  onPanUpdate: (d) => _resizeCrop(
                                    d.delta.dx / pw,
                                    0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Bottom toolbar ─────────────────────────────────────────────────────────

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B2D5C),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reset
          _toolbarButton(
            icon: Icons.delete_outline,
            label: 'Reset',
            onTap: () => setState(() {
              if (_applyToAllPages) {
                _cropRects.clear();
              } else {
                _cropRects.remove(_selectedPageIndex);
              }
            }),
          ),
          // Fit toggle
          _toolbarButton(
            icon: fitCropToPage ? Icons.fit_screen : Icons.crop,
            label: fitCropToPage ? 'Fit on' : 'Fit off',
            onTap: () => setState(() => fitCropToPage = !fitCropToPage),
          ),
          // Apply crop
          GestureDetector(
            onTap: selectedFile == null || isProcessing
                ? null
                : _processCropAndSave,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF7E57C2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Apply Crop',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  // ── Save success overlay ───────────────────────────────────────────────────

  Widget _buildSaveSuccessOverlay() {
    final r = ResponsiveHelper.of(context);
    return Container(
      color: Colors.white.withOpacity(0.93),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle,
                color: Colors.green, size: r.scale(80)),
            SizedBox(height: r.hp(2)),
            Text('PDF Cropped Successfully!',
                style: TextStyle(
                    fontSize: r.sp(17), fontWeight: FontWeight.bold)),
            SizedBox(height: r.hp(3)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  icon: Icons.remove_red_eye,
                  label: 'Open',
                  onPressed: () => OpenFile.open(savedPath!),
                  filled: true,
                  fullWidth: false,
                ),
                SizedBox(width: r.wp(3)),
                AppButton(
                  icon: Icons.share,
                  label: 'Share',
                  onPressed: () => SharePlus.instance
                      .share(ShareParams(files: [XFile(savedPath!)])),
                  fullWidth: false,
                ),
              ],
            ),
            SizedBox(height: r.hp(2)),
            TextButton(
              onPressed: () => setState(() => savedPath = null),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Handle widgets
  // ─────────────────────────────────────────────────────────────────────────

  /// The blue dot used for all handles.
  Widget _handleDot() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF4EA0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
    );
  }

  /// Corner handle — positioned by exact pixel offsets.
  Widget _buildHandle({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required ValueChanged<DragUpdateDetails> onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate,
        child: _handleDot(),
      ),
    );
  }

  /// Edge-center handle — spans the full edge so Align can center the dot.
  Widget _buildEdgeCenterHandle({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required Alignment alignment,
    required ValueChanged<DragUpdateDetails> onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Align(
        alignment: alignment,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPanUpdate,
          child: _handleDot(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Resize logic
  // ─────────────────────────────────────────────────────────────────────────

  void _resizeCrop(
      double deltaW,
      double deltaH, {
        bool moveLeft = false,
        bool moveTop = false,
      }) {
    final c = _currentCropRect;
    double left = c.left;
    double top = c.top;
    double width = c.width;
    double height = c.height;

    if (moveLeft) {
      final nextLeft =
      (left - deltaW).clamp(0.0, left + width - _minCropSide);
      width =
          (width + (left - nextLeft)).clamp(_minCropSide, 1.0 - nextLeft);
      left = nextLeft;
    } else {
      width = (width + deltaW).clamp(_minCropSide, 1.0 - left);
    }

    if (moveTop) {
      final nextTop =
      (top - deltaH).clamp(0.0, top + height - _minCropSide);
      height =
          (height + (top - nextTop)).clamp(_minCropSide, 1.0 - nextTop);
      top = nextTop;
    } else {
      height = (height + deltaH).clamp(_minCropSide, 1.0 - top);
    }

    setState(() {
      _cropRects[_selectedPageIndex] =
          Rect.fromLTWH(left, top, width, height);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Size? _selectedOutputPageSize() {
    switch (selectedPageSize) {
      case 'crop':
        return null;
      case 'original':
        return firstPagePdfSize;
      case 'a4':
        return _fitOrientation(const Size(595, 842));
      case 'letter':
        return _fitOrientation(const Size(612, 792));
      default:
        return null;
    }
  }

  Size _fitOrientation(Size paperSize) {
    final c = _currentCropRect;
    return c.width > c.height
        ? Size(paperSize.height, paperSize.width)
        : paperSize;
  }

  @override
  void dispose() {
    _thumbScrollController.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark overlay outside crop box
// ─────────────────────────────────────────────────────────────────────────────

class _DarkOverlayPainter extends CustomPainter {
  final Rect cropRect;
  _DarkOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.38);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DarkOverlayPainter old) => old.cropRect != cropRect;
}