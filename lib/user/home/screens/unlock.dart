import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class UnlockPdfScreen extends StatefulWidget {
  const UnlockPdfScreen({super.key});

  @override
  State<UnlockPdfScreen> createState() => _UnlockPdfState();
}

class _UnlockPdfState extends State<UnlockPdfScreen> {
  File? selectedFile;
  bool isProcessing = false;
  String? savedPath;
  final TextEditingController passwordController = TextEditingController();

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

  Future<void> unlockPdf() async {
    if (selectedFile == null) return;
    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the current password")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final path = await PdfService.unlockPdf(
        selectedFile!,
        passwordController.text,
        "Unlocked_${selectedFile!.path.split(Platform.pathSeparator).last}",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Unlocked and Saved: $path")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Likely incorrect password or file issue")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(
        title: const Text("Unlock PDF"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.green),
                title: Text(selectedFile == null ? "No file selected" : selectedFile!.path.split(Platform.pathSeparator).last),
                trailing: ElevatedButton(onPressed: pickPdf, child: const Text("Pick")),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "Enter Current Password",
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedFile == null || isProcessing ? null : unlockPdf,
                icon: const Icon(Icons.no_encryption),
                label: Text(isProcessing ? "Processing..." : "Unlock & Remove Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
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
