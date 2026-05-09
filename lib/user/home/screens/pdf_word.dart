import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';

class PdfToWordScreen extends StatefulWidget {
  const PdfToWordScreen({super.key});

  @override
  State<PdfToWordScreen> createState() => _PdfToWordState();
}

class _PdfToWordState extends State<PdfToWordScreen> {
  File? _selectedFile;
  bool _isConverting = false;
  String? _savedPath;
  String _statusMessage = '';
  double _progress = 0;

  // ─── Pick PDF ──────────────────────────────────────────────────────────────
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _savedPath = null;
        _statusMessage = '';
        _progress = 0;
      });
    }
  }

  // ─── Convert PDF → Word-compatible .doc ────────────────────────────────────
  Future<void> _convert() async {
    if (_selectedFile == null) return;

    setState(() {
      _isConverting = true;
      _savedPath = null;
      _progress = 0.1;
      _statusMessage = 'Reading PDF file...';
    });

    try {
      setState(() {
        _progress = 0.5;
        _statusMessage = 'Extracting text...';
      });

      final String rawText = await PdfService.extractText(_selectedFile!);

      if (rawText.trim().isEmpty) {
        setState(() {
          _isConverting = false;
          _statusMessage = 'No text found. PDF may be scanned.';
          _progress = 0;
        });
        return;
      }

      setState(() {
        _progress = 0.8;
        _statusMessage = 'Generating Word document...';
      });

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final originalName = _selectedFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final newName = await PdfService.showSaveAsDialog(context, "${originalName}_converted");

      if (newName != null && newName.isNotEmpty) {
        final String htmlDoc = '''
<html>
  <head>
    <meta charset="utf-8">
    <title>$newName</title>
  </head>
  <body style="font-family: Calibri, Arial, sans-serif; line-height: 1.5;">
    <pre style="white-space: pre-wrap;">${const HtmlEscape().convert(rawText)}</pre>
  </body>
</html>
''';
        final List<int> docBytes = utf8.encode(htmlDoc);
        final String savedPath = await PdfService.saveFile(docBytes, '$newName.doc');

        setState(() {
          _isConverting = false;
          _savedPath = savedPath;
          _progress = 1.0;
          _statusMessage = 'Saved as Word-compatible .doc file!';
        });
      } else {
        setState(() {
          _isConverting = false;
          _progress = 0;
          _statusMessage = '';
        });
      }

    } catch (e) {
      setState(() {
        _isConverting = false;
        _progress = 0;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final vPad = r.hp(2);
    final hPad = r.wp(r.isTablet || r.isExpanded ? 8 : 5);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(title: const Text('PDF to Word')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Color(0xFF6C5C8F), size: 36),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Extract text from PDF and save as a Word-compatible file.", style: TextStyle(color: Colors.black87, fontSize: r.sp(13)))),
                ],
              ),
            ),
            SizedBox(height: vPad * 1.5),
            AppButton(icon: Icons.attach_file, label: _selectedFile == null ? "Select PDF" : _selectedFile!.path.split(Platform.pathSeparator).last, onPressed: _isConverting ? null : _pickPdf),
            SizedBox(height: vPad),
            if (_selectedFile != null)
              AppButton(
                icon: Icons.autorenew,
                label: _isConverting ? "Converting..." : "Convert to Word (.doc)",
                onPressed: _isConverting ? null : _convert,
                filled: true,
                isLoading: _isConverting,
              ),
            if (_progress > 0) ...[
              SizedBox(height: vPad),
              LinearProgressIndicator(value: _progress, color: const Color(0xFF6C5C8F), backgroundColor: Colors.grey.shade200),
              SizedBox(height: vPad * 0.5),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
            if (_savedPath != null) ...[
              SizedBox(height: vPad * 1.5),
              Row(
                children: [
                  Expanded(child: AppButton(icon: Icons.remove_red_eye, label: "Open", onPressed: () => OpenFile.open(_savedPath!), filled: true)),
                  SizedBox(width: r.wp(3)),
                  Expanded(child: AppButton(icon: Icons.share, label: "Share", onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(_savedPath!)])))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
