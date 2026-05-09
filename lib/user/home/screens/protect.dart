import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class ProtectPdfScreen extends StatefulWidget {
  const ProtectPdfScreen({super.key});

  @override
  State<ProtectPdfScreen> createState() => _ProtectPdfState();
}

class _ProtectPdfState extends State<ProtectPdfScreen> {
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

  Future<void> protectAndSave() async {
    if (selectedFile == null) return;
    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a password")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Step 1: Process and get bytes
      final bytes = await PdfService.protectPdfBytes(
        selectedFile!,
        passwordController.text,
      );

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final originalName = selectedFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final newName = await PdfService.showSaveAsDialog(context, "protected_$originalName");

      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);

        setState(() {
          savedPath = path;
          isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF Password Protected and Saved!")),
        );
      } else {
        setState(() => isProcessing = false);
      }
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final vPad = r.hp(2);
    final hPad = r.wp(r.isTablet || r.isExpanded ? 8 : 5);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(title: const Text("Protect PDF")),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(icon: Icons.attach_file, label: selectedFile == null ? "Select PDF" : selectedFile!.path.split(Platform.pathSeparator).last, onPressed: pickPdf),
            SizedBox(height: vPad * 1.5),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Set Password",
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6C5C8F)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF6C5C8F), width: 2)),
                filled: true,
                fillColor: const Color(0xFFEDE7F6).withOpacity(0.3),
              ),
            ),
            SizedBox(height: vPad * 2),
            AppButton(
              icon: Icons.security,
              label: isProcessing ? "Encrypting..." : "Protect & Save PDF",
              onPressed: selectedFile == null || isProcessing ? null : protectAndSave,
              filled: true,
              isLoading: isProcessing,
            ),
            if (savedPath != null) ...[
              SizedBox(height: vPad * 1.5),
              Row(
                children: [
                  Expanded(child: AppButton(icon: Icons.remove_red_eye, label: "Open", onPressed: () => OpenFile.open(savedPath!), filled: true)),
                  SizedBox(width: r.wp(3)),
                  Expanded(child: AppButton(icon: Icons.share, label: "Share", onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(savedPath!)])))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
