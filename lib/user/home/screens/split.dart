import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfState();
}

class _SplitPdfState extends State<SplitPdfScreen> {
  File? selectedFile;
  Uint8List? fileBytes;
  List<Uint8List?> thumbnails = [];
  RangeValues _currentRange = const RangeValues(1, 1);
  int totalPages = 0;
  bool isLoading = false;
  bool isProcessing = false;
  String? savedPath;

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        thumbnails = [];
        savedPath = null;
        isLoading = true;
      });
      _loadThumbnails();
    }
  }

  Future<void> _loadThumbnails() async {
    if (selectedFile == null) return;
    fileBytes = await selectedFile!.readAsBytes();
    final document = PdfDocument(inputBytes: fileBytes);
    totalPages = document.pages.count;
    document.dispose();

    setState(() {
      thumbnails = List.filled(totalPages, null);
      _currentRange = RangeValues(1, totalPages.toDouble());
    });

    for (int i = 0; i < totalPages; i++) {
      final thumb = await PdfService.rasterizePage(fileBytes!, i);
      if (!mounted) return;
      setState(() {
        thumbnails[i] = thumb;
        if (i == totalPages - 1) isLoading = false;
      });
    }
  }

  Future<void> processSplitAndSave() async {
    if (selectedFile == null) return;
    setState(() => isProcessing = true);

    try {
      final start = _currentRange.start.toInt();
      final end = _currentRange.end.toInt();
      
      // Step 1: Process and get bytes
      // Generate a list of indices for the range
      final List<int> pageIndices = [];
      for (int i = start - 1; i < end; i++) {
        pageIndices.add(i);
      }
      
      final bytes = await PdfService.extractPagesBytes(selectedFile!, pageIndices);

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final originalName = selectedFile!.path.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
      final newName = await PdfService.showSaveAsDialog(context, "split_${start}_to_${end}_$originalName");

      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);
        
        setState(() {
          savedPath = path;
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Split Successful!")));
      } else {
        setState(() => isProcessing = false);
      }
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final vPad = r.hp(2);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(title: const Text("Split PDF")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(r.wp(4)),
            child: Row(
              children: [
                Expanded(child: AppButton(icon: Icons.attach_file, label: "Pick PDF", onPressed: pickPdf)),
                SizedBox(width: r.wp(3)),
                Expanded(child: AppButton(icon: Icons.call_split, label: "Split", onPressed: selectedFile == null || isProcessing ? null : processSplitAndSave, filled: true, isLoading: isProcessing)),
              ],
            ),
          ),
          if (selectedFile != null && totalPages > 1) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.wp(5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Range: ${_currentRange.start.toInt()} - ${_currentRange.end.toInt()} / $totalPages",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: r.sp(15))),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF6C5C8F),
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: const Color(0xFF6C5C8F),
                      overlayColor: const Color(0xFF6C5C8F).withOpacity(0.15),
                    ),
                    child: RangeSlider(
                      values: _currentRange,
                      min: 1,
                      max: totalPages.toDouble(),
                      divisions: totalPages > 1 ? totalPages - 1 : 1,
                      onChanged: (values) => setState(() => _currentRange = values),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                if (selectedFile == null) _buildEmptyState(r) else _buildGrid(),
                if (isProcessing) const Center(child: CircularProgressIndicator()),
                if (savedPath != null) _buildSaveSuccessOverlay(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ResponsiveHelper r) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call_split, size: r.scale(80), color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("Pick a PDF to select split range", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: thumbnails.length,
      itemBuilder: (context, index) {
        final pageNum = index + 1;
        final isInRange = pageNum >= _currentRange.start && pageNum <= _currentRange.end;
        
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: isInRange ? Colors.purple : Colors.grey.shade300, width: isInRange ? 2 : 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              thumbnails[index] == null
                  ? const Center(child: CircularProgressIndicator())
                  : Image.memory(thumbnails[index]!, fit: BoxFit.cover),
              if (isInRange)
                Container(
                  color: Colors.purple.withOpacity(0.1),
                ),
              Positioned(
                top: 5,
                left: 5,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: isInRange ? Colors.purple : Colors.black54,
                  child: Text("$pageNum", style: const TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveSuccessOverlay(ResponsiveHelper r) {
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: r.scale(80)),
            const SizedBox(height: 20),
            Text("PDF Split Successfully!", style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(icon: Icons.remove_red_eye, label: "Open", onPressed: () => OpenFile.open(savedPath!), filled: true, fullWidth: false),
                SizedBox(width: r.wp(3)),
                AppButton(icon: Icons.share, label: "Share", onPressed: () => SharePlus.instance.share(ShareParams(files: [XFile(savedPath!)])), fullWidth: false),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () => setState(() => savedPath = null), child: const Text("Dismiss")),
          ],
        ),
      ),
    );
  }
}
