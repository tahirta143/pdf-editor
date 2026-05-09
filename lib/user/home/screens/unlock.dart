import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
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

  Future<void> unlockAndSave() async {
    if (selectedFile == null) return;
    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the current password")),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Step 1: Process and get bytes
      final bytes = await PdfService.unlockPdfBytes(
        selectedFile!,
        passwordController.text,
      );

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final originalName = selectedFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final newName = await PdfService.showSaveAsDialog(context, "unlocked_$originalName");

      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);

        setState(() {
          savedPath = path;
          isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF Password Removed and Saved!")),
        );
      } else {
        setState(() => isProcessing = false);
      }
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
    final r = ResponsiveHelper.of(context);
    final vPad = r.hp(2);
    final hPad = r.wp(r.isTablet || r.isExpanded ? 8 : 5);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(title: const Text("Unlock PDF")),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(icon: Icons.attach_file, label: selectedFile == null ? "Select PDF" : selectedFile!.path.split(Platform.pathSeparator).last, onPressed: pickPdf),
            SizedBox(height: vPad * 1.5),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Current Password",
                prefixIcon: const Icon(Icons.key_outlined, color: Color(0xFF6C5C8F)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF6C5C8F), width: 2)),
                filled: true,
                fillColor: const Color(0xFFEDE7F6).withOpacity(0.3),
              ),
            ),
            SizedBox(height: vPad * 2),
            AppButton(
              icon: Icons.no_encryption_gmailerrorred_outlined,
              label: isProcessing ? "Processing..." : "Unlock & Remove Password",
              onPressed: selectedFile == null || isProcessing ? null : unlockAndSave,
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
