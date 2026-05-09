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
import 'package:path/path.dart' as p;

class PdfToImageScreen extends StatefulWidget {
  const PdfToImageScreen({super.key});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageState();
}

class _PdfToImageState extends State<PdfToImageScreen> {
  File? selectedFile;
  Uint8List? fileBytes;
  List<Uint8List?> thumbnails = [];
  List<String> savedImagePaths = [];
  int totalPages = 0;
  bool isLoading = false;
  bool isProcessing = false;

  int _dpi = 150;
  String _format = 'png';

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        thumbnails = [];
        savedImagePaths = [];
        totalPages = 0;
        isLoading = true;
      });
      _loadThumbnails();
    }
  }

  Future<void> _loadThumbnails() async {
    if (selectedFile == null) return;
    try {
      fileBytes = await selectedFile!.readAsBytes();
      final document = PdfDocument(inputBytes: fileBytes);
      totalPages = document.pages.count;
      document.dispose();

      // FIX: if no pages found, stop loading immediately
      if (totalPages == 0) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No pages found in this PDF.")),
        );
        return;
      }

      setState(() => thumbnails = List.filled(totalPages, null));

      for (int i = 0; i < totalPages; i++) {
        final thumb = await PdfService.rasterizePage(fileBytes!, i);
        if (!mounted) return;
        setState(() => thumbnails[i] = thumb);
      }

      // FIX: set isLoading = false after all thumbnails are done,
      // not only on the last iteration (which broke if totalPages == 0).
      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not load PDF: $e")),
      );
    }
  }

  Future<void> convertPdfToImages() async {
    if (selectedFile == null) return;
    setState(() => isProcessing = true);
    try {
      final paths = await PdfService.pdfToImages(
        selectedFile!,
        dpi: _dpi,
        format: _format,
      );
      if (!mounted) return;
      setState(() {
        savedImagePaths = paths;
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Converted $totalPages pages to $_format!")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(title: const Text("PDF to Image")),
      body: Column(
        children: [
          if (selectedFile != null && savedImagePaths.isEmpty)
            _buildSettingsPanel(r),
          Expanded(
            child: Stack(
              children: [
                if (selectedFile == null)
                  _buildEmptyState(r)
                else if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (savedImagePaths.isNotEmpty)
                    _buildResultsGrid(r)
                  else
                    _buildPreviewGrid(r),
                if (isProcessing)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          if (selectedFile != null && savedImagePaths.isEmpty && !isLoading)
            Container(
              padding: EdgeInsets.all(r.wp(5)),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5))
                ],
              ),
              child: AppButton(
                icon: Icons.image,
                label: isProcessing ? "Converting..." : "Convert All Pages",
                onPressed: isProcessing ? null : convertPdfToImages,
                filled: true,
                isLoading: isProcessing,
              ),
            ),
        ],
      ),
      floatingActionButton: selectedFile == null
          ? FloatingActionButton(
        onPressed: pickPdf,
        backgroundColor: const Color(0xFF6C5C8F),
        child: const Icon(Icons.add_photo_alternate_outlined,
            color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildSettingsPanel(ResponsiveHelper r) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: r.wp(4), vertical: r.hp(1.5)),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Text("DPI:",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: r.sp(13))),
          SizedBox(width: r.wp(2)),
          _choiceChip(r, 75, "75"),
          SizedBox(width: r.wp(1)),
          _choiceChip(r, 150, "150"),
          SizedBox(width: r.wp(1)),
          _choiceChip(r, 220, "220"),
          const Spacer(),
          Text("Format:",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: r.sp(13))),
          SizedBox(width: r.wp(2)),
          _formatChip(r, 'png', "PNG"),
          SizedBox(width: r.wp(1)),
          _formatChip(r, 'jpg', "JPG"),
        ],
      ),
    );
  }

  Widget _choiceChip(ResponsiveHelper r, int value, String label) {
    final isSelected = _dpi == value;
    return GestureDetector(
      onTap: () => setState(() => _dpi = value),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: r.wp(3), vertical: r.hp(0.8)),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5C8F)
              : const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(r.scale(20)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: r.sp(12),
              color: isSelected ? Colors.white : const Color(0xFF6C5C8F),
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _formatChip(ResponsiveHelper r, String value, String label) {
    final isSelected = _format == value;
    return GestureDetector(
      onTap: () => setState(() => _format = value),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: r.wp(3), vertical: r.hp(0.8)),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5C8F)
              : const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(r.scale(20)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: r.sp(12),
              color: isSelected ? Colors.white : const Color(0xFF6C5C8F),
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ResponsiveHelper r) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined,
              size: r.scale(80), color: Colors.grey.shade300),
          SizedBox(height: r.hp(2)),
          Text("Open a PDF to convert to images",
              style:
              TextStyle(color: Colors.grey, fontSize: r.sp(14))),
          SizedBox(height: r.hp(3)),
          AppButton(
              icon: Icons.attach_file,
              label: "Select PDF",
              onPressed: pickPdf,
              fullWidth: false),
        ],
      ),
    );
  }

  Widget _buildPreviewGrid(ResponsiveHelper r) {
    final cols =
    r.isTablet ? 4 : (r.isExpanded ? 3 : (r.isLandscape ? 4 : 3));
    return GridView.builder(
      padding: EdgeInsets.all(r.wp(3)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: r.wp(2),
        mainAxisSpacing: r.wp(2),
        childAspectRatio: 0.75,
      ),
      itemCount: thumbnails.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(r.scale(8)),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(r.scale(7)),
                child: thumbnails[index] == null
                    ? const Center(child: CircularProgressIndicator())
                    : Image.memory(thumbnails[index]!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: r.wp(1.5), vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text("${index + 1}",
                      style: TextStyle(
                          fontSize: r.sp(10), color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsGrid(ResponsiveHelper r) {
    final cols = r.isTablet ? 3 : (r.isExpanded ? 3 : 2);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: r.wp(4), vertical: r.hp(1.5)),
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  color: Colors.green, size: r.scale(20)),
              SizedBox(width: r.wp(2)),
              Text("Conversion Successful!",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: r.sp(14))),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => savedImagePaths = []),
                icon: const Icon(Icons.refresh),
                label: const Text("Reset"),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(r.wp(3)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: r.wp(2),
              mainAxisSpacing: r.wp(2),
              childAspectRatio: 0.8,
            ),
            itemCount: savedImagePaths.length,
            itemBuilder: (context, index) {
              final path = savedImagePaths[index];
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                        Border.all(color: Colors.grey.shade300),
                        borderRadius:
                        BorderRadius.circular(r.scale(8)),
                      ),
                      child: ClipRRect(
                        borderRadius:
                        BorderRadius.circular(r.scale(7)),
                        child: Image.file(File(path),
                            fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SizedBox(height: r.hp(0.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_red_eye,
                            size: r.scale(18),
                            color: const Color(0xFF6C5C8F)),
                        onPressed: () => OpenFile.open(path),
                      ),
                      IconButton(
                        icon: Icon(Icons.share,
                            size: r.scale(18),
                            color: const Color(0xFF6C5C8F)),
                        onPressed: () => SharePlus.instance.share(
                            ShareParams(files: [XFile(path)])),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}