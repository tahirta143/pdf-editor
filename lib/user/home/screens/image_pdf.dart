import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfState();
}

class _ImageToPdfState extends State<ImageToPdfScreen> {
  List<File> selectedImages = [];
  bool isProcessing = false;
  String? savedPath;

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedImages.addAll(result.paths.map((path) => File(path!)).toList());
        savedPath = null;
      });
    }
  }

  Future<void> convertAndSave() async {
    if (selectedImages.isEmpty) return;
    setState(() => isProcessing = true);

    try {
      // Step 1: Process and get bytes
      final bytes = await PdfService.imagesToPdfBytes(selectedImages);

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final newName = await PdfService.showSaveAsDialog(context, "Converted_Images");

      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);

        setState(() {
          savedPath = path;
          isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF Saved to Downloads!")),
        );
      } else {
        setState(() => isProcessing = false);
      }
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF7E57C2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Image to PDF"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (selectedImages.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => selectedImages = []),
              child: const Text("Clear All", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: selectedImages.isEmpty
                ? _buildEmptyState()
                : _buildImageGrid(primaryPurple),
          ),
          
          if (selectedImages.isNotEmpty)
            _buildActionPanel(primaryPurple),
        ],
      ),
      floatingActionButton: selectedImages.isEmpty
          ? FloatingActionButton(
              onPressed: pickImages,
              backgroundColor: primaryPurple,
              child: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
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
          Icon(Icons.add_photo_alternate_outlined, size: r.scale(80), color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("Select images to convert to PDF", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildImageGrid(Color color) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: selectedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                selectedImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionPanel(Color color) {
    final r = ResponsiveHelper.of(context);
    return Container(
      padding: EdgeInsets.all(r.wp(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (savedPath == null)
            Row(
              children: [
                Expanded(child: AppButton(icon: Icons.add, label: "Add More", onPressed: pickImages)),
                SizedBox(width: r.wp(3)),
                Expanded(child: AppButton(icon: Icons.picture_as_pdf, label: isProcessing ? "Converting..." : "Convert & Save", onPressed: isProcessing ? null : convertAndSave, filled: true, isLoading: isProcessing)),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: AppButton(icon: Icons.remove_red_eye, label: "Open", onPressed: () => OpenFile.open(savedPath!), filled: true)),
                SizedBox(width: r.wp(3)),
                Expanded(child: AppButton(icon: Icons.share, label: "Share", onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(savedPath!)])))),
              ],
            ),
        ],
      ),
    );
  }
}
