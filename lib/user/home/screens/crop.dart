import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class CropPdfScreen extends StatefulWidget {
  const CropPdfScreen({super.key});

  @override
  State<CropPdfScreen> createState() => _CropPdfState();
}

class _CropPdfState extends State<CropPdfScreen> {
  File? selectedFile;
  bool isProcessing = false;
  String? savedPath;
  
  // Margins in points
  final TextEditingController leftController = TextEditingController(text: "50");
  final TextEditingController topController = TextEditingController(text: "50");
  final TextEditingController rightController = TextEditingController(text: "500");
  final TextEditingController bottomController = TextEditingController(text: "700");

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

  Future<void> processCrop() async {
    if (selectedFile == null) return;

    setState(() => isProcessing = true);

    try {
      final double left = double.parse(leftController.text);
      final double top = double.parse(topController.text);
      final double width = double.parse(rightController.text) - left;
      final double height = double.parse(bottomController.text) - top;

      final path = await PdfService.cropPdf(
        selectedFile!,
        Rect.fromLTWH(left, top, width, height),
        "Cropped_${selectedFile!.path.split(Platform.pathSeparator).last}",
      );

      setState(() {
        savedPath = path;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Cropped. Saved: $path")),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Check margin values")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(title: const Text("Crop PDF"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.crop, color: Colors.cyan),
                title: Text(selectedFile == null ? "No file selected" : selectedFile!.path.split(Platform.pathSeparator).last),
                trailing: ElevatedButton(onPressed: pickPdf, child: const Text("Pick")),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Define Crop Box (Points):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMarginInput("Left", leftController)),
                const SizedBox(width: 10),
                Expanded(child: _buildMarginInput("Top", topController)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMarginInput("Right (X2)", rightController)),
                const SizedBox(width: 10),
                Expanded(child: _buildMarginInput("Bottom (Y2)", bottomController)),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Tip: Standard A4 is approx 595 x 842 points.", style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedFile == null || isProcessing ? null : processCrop,
                icon: const Icon(Icons.crop),
                label: Text(isProcessing ? "Cropping..." : "Crop All Pages"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
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

  Widget _buildMarginInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }
}
