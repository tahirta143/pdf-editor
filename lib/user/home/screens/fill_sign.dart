import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FillAndSignScreen extends StatefulWidget {
  const FillAndSignScreen({super.key});

  @override
  State<FillAndSignScreen> createState() => _FillAndSignState();
}

class _FillAndSignState extends State<FillAndSignScreen> {
  File? _selectedFile;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  bool _isProcessing = false;
  int _currentPage = 1;

  Future<void> _pickAndOpenPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _showSignatureDialog() {
    final r = ResponsiveHelper.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: r.hp(80),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFF7E57C2),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF7E57C2),
                tabs: [
                  Tab(icon: Icon(Icons.keyboard), text: "Type"),
                  Tab(icon: Icon(Icons.gesture), text: "Draw"),
                  Tab(icon: Icon(Icons.upload), text: "Upload"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTypeTab(),
                    _buildDrawTab(),
                    _buildUploadTab(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context), 
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3E5F5), foregroundColor: const Color(0xFF7E57C2)),
                      child: const Text("Use Signature"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab() {
    final controller = TextEditingController(text: "Alex Appleseed");
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Type your name", style: TextStyle(color: Colors.grey)),
          TextField(controller: controller),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildSignaturePreview("Alex Appleseed", "Cursive"),
                _buildSignaturePreview("Alex Appleseed", "Brush Script"),
                _buildSignaturePreview("Alex Appleseed", "Handwriting"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePreview(String name, String font) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(name, style: const TextStyle(fontSize: 24, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildDrawTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
              child: SfSignaturePad(key: _signaturePadKey),
            ),
          ),
          TextButton(onPressed: () => _signaturePadKey.currentState?.clear(), child: const Text("Clear")),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return const Center(child: Text("Select an image from gallery"));
  }

  void _showAddTextDialog() {
    final controller = TextEditingController();
    double fontSize = 20;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Text"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Type here..."),
              ),
              const SizedBox(height: 20),
              const Text("Font"),
              DropdownButton<String>(
                value: "Regular",
                isExpanded: true,
                items: ["Regular", "Bold", "Italic"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 20),
              const Text("Size"),
              Slider(
                value: fontSize,
                min: 10,
                max: 50,
                onChanged: (v) => setDialogState(() => fontSize = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (controller.text.isNotEmpty) {
                  _applyText(controller.text, fontSize);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyText(String text, double size) async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);
    try {
      final bytes = await PdfService.addTextToPdfBytes(_selectedFile!, text, const Offset(50, 100), fontSize: size);
      
      // Save to temp file to refresh viewer
      final tempDir = await getTemporaryDirectory();
      final tempPath = p.join(tempDir.path, "temp_edit_${DateTime.now().millisecondsSinceEpoch}.pdf");
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      setState(() {
        _selectedFile = tempFile;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveFinalPdf() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      if (!mounted) return;

      final newName = await PdfService.showSaveAsDialog(context, "Signed_Document");
      if (newName != null && newName.isNotEmpty) {
        final path = await PdfService.savePdf(bytes, newName);
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Saved to Downloads!")));
        OpenFile.open(path);
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF7E57C2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Fill & Sign"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.check, color: primaryPurple), 
            onPressed: _selectedFile != null ? _saveFinalPdf : null,
            tooltip: "Save Final PDF",
          ),
        ],
      ),
      body: Stack(
        children: [
          _selectedFile == null ? _buildEmptyState() : _buildViewer(),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: _selectedFile == null ? null : _buildBottomToolbar(),
    );
  }

  Widget _buildEmptyState() {
    final r = ResponsiveHelper.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: r.scale(80), color: Colors.grey.shade300),
          const SizedBox(height: 20),
          AppButton(icon: Icons.attach_file, label: "Select PDF", onPressed: _pickAndOpenPdf, fullWidth: false),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    return SfPdfViewer.file(
      _selectedFile!,
      key: _pdfViewerKey,
      onPageChanged: (details) => setState(() => _currentPage = details.newPageNumber),
    );
  }

  Widget _buildBottomToolbar() {
    final r = ResponsiveHelper.of(context);
    return Container(
      height: r.scale(60),
      padding: EdgeInsets.symmetric(horizontal: r.wp(5), vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Text("Page $_currentPage", style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.text_fields, color: Color(0xFF7E57C2)), onPressed: _showAddTextDialog, tooltip: "Add Text"),
          const SizedBox(width: 20),
          IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: _showSignatureDialog, tooltip: "Sign"),
        ],
      ),
    );
  }
}
