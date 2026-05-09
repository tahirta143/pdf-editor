import 'package:flutter/material.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class HtmlToPdfScreen extends StatefulWidget {
  const HtmlToPdfScreen({super.key});

  @override
  State<HtmlToPdfScreen> createState() => _HtmlToPdfState();
}

class _HtmlToPdfState extends State<HtmlToPdfScreen> {
  final TextEditingController _htmlController = TextEditingController();
  bool _isConverting = false;
  String? _savedPath;
  String? _statusMessage;

  Future<void> _convertHtmlToPdf() async {
    final html = _htmlController.text.trim();
    if (html.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter or paste HTML content")),
      );
      return;
    }

    setState(() {
      _isConverting = true;
      _savedPath = null;
      _statusMessage = "Converting HTML to PDF...";
    });

    try {
      // Step 1: Process and get bytes
      final bytes = await PdfService.htmlToPdfBytes(html);

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final newName = await PdfService.showSaveAsDialog(context, "web_content");

      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);

        setState(() {
          _isConverting = false;
          _savedPath = path;
          _statusMessage = "Conversion successful!";
        });
      } else {
        setState(() {
          _isConverting = false;
          _statusMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isConverting = false;
        _statusMessage = "Error: $e";
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
      appBar: AppBar(title: const Text("HTML to PDF")),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Paste HTML Content", style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.bold)),
            SizedBox(height: vPad * 0.75),
            TextField(
              controller: _htmlController,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: "<html><body><h1>Hello World</h1></body></html>",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFE1BEE7))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF6C5C8F), width: 2)),
                fillColor: const Color(0xFFEDE7F6).withOpacity(0.3),
                filled: true,
              ),
            ),
            SizedBox(height: vPad * 1.5),
            AppButton(
              icon: Icons.code,
              label: _isConverting ? "Converting..." : "Convert to PDF",
              onPressed: _isConverting ? null : _convertHtmlToPdf,
              filled: true,
              isLoading: _isConverting,
            ),
            if (_statusMessage != null) ...[
              SizedBox(height: vPad),
              Center(child: Text(_statusMessage!, style: TextStyle(color: _savedPath != null ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
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
