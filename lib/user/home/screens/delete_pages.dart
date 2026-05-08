import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class DeletePagesScreen extends StatefulWidget {
  const DeletePagesScreen({super.key});

  @override
  State<DeletePagesScreen> createState() => _DeletePagesState();
}

class _DeletePagesState extends State<DeletePagesScreen> {
  File? selectedFile;
  bool isProcessing = false;
  String? savedPath;
  final TextEditingController pageController = TextEditingController();

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        savedPath = null;
      });
    }
  }

  Future<void> processDeletion() async {
    if (selectedFile == null) return;
    if (pageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter page numbers to delete (e.g. 1, 3, 5)")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Parse "1, 2, 5" into [0, 1, 4]
      final List<int> indices = pageController.text
          .split(',')
          .map((e) => int.parse(e.trim()) - 1)
          .toList();

      final path = await PdfService.deletePages(
        selectedFile!,
        indices,
        "Modified_${selectedFile!.path.split(Platform.pathSeparator).last}",
      );

      setState(() {
        savedPath = path;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pages deleted. Saved: $path")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Check page numbers and try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(title: const Text("Delete Pages"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(selectedFile == null ? "No file selected" : selectedFile!.path.split(Platform.pathSeparator).last),
                trailing: ElevatedButton(onPressed: pickPdf, child: const Text("Pick")),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pageController,
              decoration: const InputDecoration(
                labelText: "Page Numbers to Remove",
                hintText: "e.g. 1, 2, 5",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedFile == null || isProcessing ? null : processDeletion,
                icon: const Icon(Icons.delete),
                label: Text(isProcessing ? "Processing..." : "Remove Pages"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ),
            if (savedPath != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () => OpenFile.open(savedPath!), icon: const Icon(Icons.remove_red_eye), label: const Text("Open"))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: () => Share.shareXFiles([XFile(savedPath!)]), icon: const Icon(Icons.share), label: const Text("Share"))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
