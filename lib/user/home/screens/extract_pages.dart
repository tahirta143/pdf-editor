import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class ExtractPagesScreen extends StatefulWidget {
  const ExtractPagesScreen({super.key});

  @override
  State<ExtractPagesScreen> createState() => _ExtractPagesState();
}

class _ExtractPagesState extends State<ExtractPagesScreen> {
  File? selectedFile;
  bool isProcessing = false;
  String? savedPath;
  final TextEditingController rangeController = TextEditingController();

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

  Future<void> processExtraction() async {
    if (selectedFile == null) return;
    if (rangeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter page range to extract (e.g. 1-3)")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final paths = await PdfService.splitPdf(
        selectedFile!,
        rangeController.text.trim(),
      );

      setState(() {
        savedPath = paths.first;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pages extracted. Saved: ${paths.first}")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Check range and try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(title: const Text("Extract Pages"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.content_cut, color: Colors.orange),
                title: Text(selectedFile == null ? "No file selected" : selectedFile!.path.split(Platform.pathSeparator).last),
                trailing: ElevatedButton(onPressed: pickPdf, child: const Text("Pick")),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: rangeController,
              decoration: const InputDecoration(
                labelText: "Page Range to Extract",
                hintText: "e.g. 1-5",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedFile == null || isProcessing ? null : processExtraction,
                icon: const Icon(Icons.download),
                label: Text(isProcessing ? "Extracting..." : "Extract to New PDF"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
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
