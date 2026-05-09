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

class DeletePagesScreen extends StatefulWidget {
  const DeletePagesScreen({super.key});

  @override
  State<DeletePagesScreen> createState() => _DeletePagesState();
}

class _DeletePagesState extends State<DeletePagesScreen> {
  File? selectedFile;
  Uint8List? fileBytes;
  List<Uint8List?> thumbnails = [];
  Set<int> selectedIndices = {};
  int totalPages = 0;
  bool isLoading = false;
  bool isProcessing = false;
  String? savedPath;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        thumbnails = [];
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

  Future<void> processDeleteAndSave() async {
    if (selectedFile == null || selectedIndices.isEmpty) return;
    setState(() => isProcessing = true);

    try {
      // Step 1: Process and get bytes
      final bytes = await PdfService.deletePagesBytes(selectedFile!, selectedIndices.toList());

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final originalName = selectedFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final newName = await PdfService.showSaveAsDialog(context, "modified_$originalName");

      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);
        
        setState(() {
          savedPath = path;
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pages Deleted Successfully!")));
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
    final r = ResponsiveHelper.of(context);
    final emptyIconSize = r.scale(80);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(title: const Text("Delete Pages")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(r.wp(4)),
            child: Row(
              children: [
                Expanded(child: AppButton(icon: Icons.attach_file, label: "Pick PDF", onPressed: pickPdf)),
                SizedBox(width: r.wp(3)),
                Expanded(child: AppButton(icon: Icons.delete_sweep, label: "Delete", onPressed: selectedIndices.isEmpty || isProcessing ? null : processDeleteAndSave, filled: true, isLoading: isProcessing)),
              ],
            ),
          ),
          if (selectedFile != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.wp(5)),
              child: Text("Selected: ${selectedIndices.length} pages to delete", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                if (selectedFile == null) _buildEmptyState(emptyIconSize) else _buildGrid(),
                if (isProcessing) const Center(child: CircularProgressIndicator()),
                if (savedPath != null) _buildSaveSuccessOverlay(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(double iconSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_forever, size: iconSize, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("Pick a PDF to select pages to delete", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
              border: Border.all(color: isSelected ? Colors.red : Colors.grey.shade300, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                thumbnails[index] == null
                    ? const Center(child: CircularProgressIndicator())
                    : Image.memory(thumbnails[index]!, fit: BoxFit.cover),
                if (isSelected)
                  Container(
                    color: Colors.red.withOpacity(0.3),
                    child: const Center(child: Icon(Icons.delete, color: Colors.white, size: 40)),
                  ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: isSelected ? Colors.red : Colors.black54,
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

  Widget _buildSaveSuccessOverlay(ResponsiveHelper r) {
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: r.scale(80)),
            const SizedBox(height: 20),
            Text("Pages Deleted Successfully!", style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.bold)),
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
