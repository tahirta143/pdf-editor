import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfState();
}

class _SplitPdfState extends State<SplitPdfScreen> {
  File? selectedFile;
  bool isProcessing = false;
  List<String> savedPaths = [];
  final TextEditingController rangeController = TextEditingController(text: "1-2, 3-4");

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        savedPaths = [];
      });
    }
  }

  Future<void> splitPdf() async {
    if (selectedFile == null) return;
    if (rangeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter page ranges (e.g., 1-2, 3-5)")),
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
        savedPaths = paths;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Split into ${paths.length} files")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(
        title: const Text("Split PDF"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILE SELECTION
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(selectedFile == null ? "No file selected" : selectedFile!.path.split(Platform.pathSeparator).last),
                trailing: ElevatedButton(
                  onPressed: pickPdf,
                  child: const Text("Pick"),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // RANGE INPUT
            const Text("Enter Page Ranges (e.g. 1-2, 3-5):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: rangeController,
              decoration: const InputDecoration(
                hintText: "1-2, 3-4",
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            // ACTION BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedFile == null || isProcessing ? null : splitPdf,
                icon: isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.call_split),
                label: Text(isProcessing ? "Processing..." : "Split PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // RESULTS
            if (savedPaths.isNotEmpty) ...[
              const Text("Generated Files:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: savedPaths.length,
                  itemBuilder: (context, index) {
                    final path = savedPaths[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.file_copy, size: 20),
                      title: Text(path.split(Platform.pathSeparator).last, style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.remove_red_eye, size: 18), onPressed: () => OpenFile.open(path)),
                          IconButton(icon: const Icon(Icons.share, size: 18), onPressed: () => Share.shareXFiles([XFile(path)])),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
