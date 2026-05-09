import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractPagesScreen extends StatefulWidget {
  const ExtractPagesScreen({super.key});

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesState();
}

class _ExtractPagesState extends State<ExtractPagesScreen> {
  File? selectedFile;
  Uint8List? fileBytes;
  List<Uint8List?> thumbnails = [];
  Set<int> selectedIndices = {};
  int totalPages = 0;
  bool isLoading = false;
  bool isProcessing = false;
  String? savedPath;
  double _zoom = 3.0;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      fileBytes = await File(result.files.single.path!).readAsBytes();
      if (!mounted) return;
      
      final document = PdfDocument(inputBytes: fileBytes);
      totalPages = document.pages.count;
      document.dispose();

      setState(() {
        selectedFile = File(result.files.single.path!);
        thumbnails = List.filled(totalPages, null);
        selectedIndices = {};
        savedPath = null;
        isLoading = true;
      });
      _loadThumbnails();
    }
  }

  Future<void> _loadThumbnails() async {
    if (selectedFile == null) return;
    fileBytes = await selectedFile!.readAsBytes();
    final document = PdfDocument(inputBytes: fileBytes);
    totalPages = document.pages.count;
    document.dispose();

    setState(() {
      thumbnails = List.filled(totalPages, null);
    });

    for (int i = 0; i < totalPages; i++) {
      final thumb = await PdfService.rasterizePage(fileBytes!, i);
      if (!mounted) return;
      setState(() {
        thumbnails[i] = thumb;
        if (i == totalPages - 1) isLoading = false;
      });
    }
  }

  void _selectOdd() {
    setState(() {
      selectedIndices.clear();
      for (int i = 0; i < totalPages; i++) {
        if ((i + 1) % 2 != 0) selectedIndices.add(i);
      }
    });
  }

  void _selectEven() {
    setState(() {
      selectedIndices.clear();
      for (int i = 0; i < totalPages; i++) {
        if ((i + 1) % 2 == 0) selectedIndices.add(i);
      }
    });
  }

  Future<void> processExtractAndSave() async {
    if (selectedFile == null || selectedIndices.isEmpty) return;
    setState(() => isProcessing = true);

    try {
      final bytes = await PdfService.extractPagesBytes(selectedFile!, selectedIndices.toList()..sort());

      if (!mounted) return;

      final originalName = selectedFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final newName = await PdfService.showSaveAsDialog(context, "extracted_$originalName");

      if (newName != null && newName.isNotEmpty) {
        final path = await PdfService.savePdf(bytes, newName);
        setState(() {
          savedPath = path;
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pages Extracted Successfully!")));
      } else {
        setState(() => isProcessing = false);
      }
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF7E57C2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Extract Pages"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (selectedFile != null)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => setState(() => selectedIndices = Set.from(Iterable.generate(totalPages))),
            ),
        ],
      ),
      body: Column(
        children: [
          // Zoom and Quick Select
          if (selectedFile != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, size: 20, color: Colors.grey),
                  Expanded(
                    child: Slider(
                      value: _zoom,
                      min: 2,
                      max: 5,
                      activeColor: primaryPurple,
                      onChanged: (v) => setState(() => _zoom = v),
                    ),
                  ),
                  const Icon(Icons.zoom_in, size: 20, color: Colors.grey),
                  const SizedBox(width: 20),
                  TextButton(onPressed: _selectOdd, child: const Text("Odd")),
                  TextButton(onPressed: _selectEven, child: const Text("Even")),
                ],
              ),
            ),

          Expanded(
            child: Stack(
              children: [
                if (selectedFile == null) 
                  _buildEmptyState() 
                else 
                  _buildGrid(),
                if (isProcessing) const Center(child: CircularProgressIndicator()),
                if (savedPath != null) _buildSaveSuccessOverlay(),
              ],
            ),
          ),

          // Bottom Action Panel
          if (selectedFile != null && savedPath == null)
            Builder(builder: (context) {
              final r = ResponsiveHelper.of(context);
              return Container(
                padding: EdgeInsets.all(r.wp(5)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("${selectedIndices.length} pages selected", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: selectedIndices.isEmpty || isProcessing ? null : processExtractAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: r.hp(2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.scale(30))),
                      ),
                      child: const Text("Extract & Save"),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
      floatingActionButton: selectedFile == null
          ? FloatingActionButton(
              onPressed: pickPdf,
              backgroundColor: primaryPurple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    final r = ResponsiveHelper.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: r.scale(80), color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("Open a PDF to extract pages", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    const primaryPurple = Color(0xFF7E57C2);
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _zoom.toInt(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: thumbnails.length,
      itemBuilder: (context, index) {
        final isSelected = selectedIndices.contains(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedIndices.remove(index);
              } else {
                selectedIndices.add(index);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? primaryPurple : Colors.grey.shade300, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: thumbnails[index] == null
                      ? const Center(child: CircularProgressIndicator())
                      : Image.memory(thumbnails[index]!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                if (isSelected)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: primaryPurple,
                      child: const Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  ),
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: Text("${index + 1}", style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveSuccessOverlay() {
    final r = ResponsiveHelper.of(context);
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: r.scale(80)),
            const SizedBox(height: 20),
            Text("Pages Extracted Successfully!", style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(icon: Icons.remove_red_eye, label: "Open", onPressed: () => OpenFile.open(savedPath!), filled: true, fullWidth: false),
                SizedBox(width: r.wp(3)),
                AppButton(icon: Icons.share, label: "Share", onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(savedPath!)])), fullWidth: false),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () => setState(() => savedPath = null), child: const Text("Dismiss")),
          ],
        ),
      ),
    );
  }
}
