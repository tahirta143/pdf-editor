import 'dart:io';
import 'package:flutter/material.dart';
import 'package:html_to_pdf/html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class HtmlToPdfScreen extends StatefulWidget {
  const HtmlToPdfScreen({super.key});

  @override
  State<HtmlToPdfScreen> createState() => _HtmlToPdfState();
}

class _HtmlToPdfState extends State<HtmlToPdfScreen> {
  final TextEditingController htmlController = TextEditingController(text: "<h1>Hello World</h1><p>This is a PDF from HTML.</p>");
  bool isProcessing = false;
  String? savedPath;

  Future<void> convertHtmlToPdf() async {
    if (htmlController.text.trim().isEmpty) return;

    setState(() => isProcessing = true);

    try {
      final Directory tempDir = await getTemporaryDirectory();
      
      final File generatedPdfFile = await HtmlToPdf.convertFromHtmlContent(
        htmlContent: htmlController.text.trim(),
        printPdfConfiguration: PrintPdfConfiguration(
          targetDirectory: tempDir.path,
          targetName: "HTML_to_PDF",
        ),
      );

      // Copy to Downloads for easier access
      final downloadDir = Directory('/storage/emulated/0/Download');
      String finalPath;
      if (await downloadDir.exists()) {
        finalPath = "${downloadDir.path}/HTML_to_PDF_${DateTime.now().millisecondsSinceEpoch}.pdf";
        await generatedPdfFile.copy(finalPath);
      } else {
        finalPath = generatedPdfFile.path;
      }

      setState(() {
        savedPath = finalPath;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("HTML converted to PDF: $finalPath")),
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
      appBar: AppBar(title: const Text("HTML to PDF"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Enter HTML Content:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: htmlController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: "<html><body>...</body></html>",
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : convertHtmlToPdf,
                icon: const Icon(Icons.language),
                label: Text(isProcessing ? "Generating..." : "Convert to PDF"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
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
