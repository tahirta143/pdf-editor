import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfState();
}

class _MergePdfState extends State<MergePdfScreen> {
  List<File> selectedFiles = [];
  bool isProcessing = false;
  String? savedPath;
  final TextEditingController fileNameController = TextEditingController(text: "Merged_Document");

  Future<void> pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedFiles.addAll(result.paths.map((path) => File(path!)).toList());
        savedPath = null;
      });
    }
  }

  Future<void> mergePdfs() async {
    if (selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least 2 PDF files to merge")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final path = await PdfService.mergePdfs(
        selectedFiles,
        fileNameController.text.trim().isEmpty ? "Merged_Document" : fileNameController.text.trim(),
      );

      setState(() {
        savedPath = path;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Merged and Saved: $path")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(
        title: const Text("Merge PDFs"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // FILE NAME INPUT
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                labelText: "Output File Name",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            // FILE LIST
            Expanded(
              child: selectedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text("No PDF files selected"),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: selectedFiles.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = selectedFiles.removeAt(oldIndex);
                          selectedFiles.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final file = selectedFiles[index];
                        return ListTile(
                          key: ValueKey(file.path),
                          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          title: Text(file.path.split(Platform.pathSeparator).last),
                          subtitle: Text("${(file.lengthSync() / 1024).toStringAsFixed(2)} KB"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.drag_handle),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => removeFile(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickPdfs,
                    icon: const Icon(Icons.add),
                    label: const Text("Add PDFs"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: selectedFiles.length < 2 || isProcessing ? null : mergePdfs,
                    icon: isProcessing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.merge_type),
                    label: Text(isProcessing ? "Merging..." : "Merge PDFs"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            if (savedPath != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => OpenFile.open(savedPath!),
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text("Open PDF"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Share.shareXFiles([XFile(savedPath!)], text: "My Merged PDF"),
                      icon: const Icon(Icons.share),
                      label: const Text("Share PDF"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
