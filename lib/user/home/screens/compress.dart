import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfState();
}

class _CompressPdfState extends State<CompressPdfScreen> {
  File? selectedFile;
  bool isProcessing = false;
  double quality = 30;
  String? savedPath;
  String? resultInfo;
  String? _pdfPassword;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        savedPath = null;
        resultInfo = null;
        _pdfPassword = null;
      });
    }
  }

  Future<void> compressAndSave() async {
    if (selectedFile == null) return;
    setState(() {
      isProcessing = true;
      resultInfo = "Compressing PDF for minimum size...";
    });

    try {
      final originalSize = await selectedFile!.length();
      final originalName = selectedFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      
      // Step 1: Process and get bytes
      late final List<int> bytes;
      try {
        bytes = await PdfService.compressPdfBytes(
          selectedFile!,
          quality: quality,
          password: _pdfPassword,
        );
      } catch (e) {
        if (!mounted) return;
        if (PdfService.isEncryptedPdfError(e)) {
          final pass = await PdfService.showPasswordDialog(context, "Encrypted PDF");
          if (pass == null || pass.isEmpty) {
            setState(() {
              isProcessing = false;
              resultInfo = "Password required for encrypted PDF.";
            });
            return;
          }
          _pdfPassword = pass;
          bytes = await PdfService.compressPdfBytes(
            selectedFile!,
            quality: quality,
            password: _pdfPassword,
          );
        } else {
          rethrow;
        }
      }

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final newName = await PdfService.showSaveAsDialog(context, "compressed_$originalName");
      
      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);
        final newSize = await File(path).length();
        final bool reduced = newSize < originalSize;

        setState(() {
          savedPath = path;
          isProcessing = false;
          resultInfo = reduced
              ? "Saved: ${_formatSize(originalSize)} -> ${_formatSize(newSize)}"
              : "Saved, but file is already optimized: ${_formatSize(newSize)}";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reduced ? "PDF compressed and saved!" : "PDF saved (already optimized).")),
        );
      } else {
        setState(() {
          isProcessing = false;
          resultInfo = "Save cancelled.";
        });
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
        resultInfo = "Error occurred.";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String _formatSize(int bytes) {
    return (bytes / (1024 * 1024)).toStringAsFixed(2) + " MB";
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final vPad = r.hp(2);
    final hPad = r.wp(r.isTablet || r.isExpanded ? 8 : 5);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(title: const Text("PDF Compress")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: vPad),
            AppButton(
              icon: Icons.attach_file,
              label: selectedFile == null ? "Select PDF" : selectedFile!.path.split(Platform.pathSeparator).last,
              onPressed: pickPdf,
            ),
            SizedBox(height: vPad * 1.5),
            if (selectedFile != null) ...[
              Text("Compression quality: ${quality.toInt()}%", style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF6C5C8F),
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: const Color(0xFF6C5C8F),
                  overlayColor: const Color(0xFF6C5C8F).withOpacity(0.15),
                  trackHeight: 4,
                ),
                child: Slider(value: quality, min: 1, max: 100, onChanged: (val) => setState(() => quality = val)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.wp(2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Lower = smaller file", style: TextStyle(color: Colors.grey, fontSize: r.sp(12))),
                    Text("Higher = better quality", style: TextStyle(color: Colors.grey, fontSize: r.sp(12))),
                  ],
                ),
              ),
              SizedBox(height: vPad * 2),
              AppButton(
                icon: Icons.unfold_less,
                label: isProcessing ? "Processing..." : "Compress & Save PDF",
                onPressed: isProcessing ? null : compressAndSave,
                filled: true,
                isLoading: isProcessing,
              ),
              if (resultInfo != null) ...[
                SizedBox(height: vPad),
                Center(child: Text(resultInfo!, style: TextStyle(fontSize: r.sp(13), color: Colors.black87, fontWeight: FontWeight.w500))),
              ],
              if (savedPath != null) ...[
                SizedBox(height: vPad * 1.5),
                Row(
                  children: [
                    Expanded(child: AppButton(icon: Icons.remove_red_eye, label: "Open", onPressed: () => OpenFile.open(savedPath!))),
                    SizedBox(width: r.wp(3)),
                    Expanded(child: AppButton(icon: Icons.share, label: "Share", onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(savedPath!)])))),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}