import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfeditorapp/services/pdf_service.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/utils/app_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfState();
}

class _MergePdfState extends State<MergePdfScreen> {
  List<File> selectedFiles = [];
  Map<String, Uint8List?> thumbnails = {};
  bool isProcessing = false;
  String? savedPath;

  Future<void> pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      final newFiles = result.paths.where((path) => path != null).map((path) => File(path!)).toList();
      setState(() {
        selectedFiles.addAll(newFiles);
        savedPath = null;
      });
      _loadThumbnails(newFiles);
    }
  }

  Future<void> _loadThumbnails(List<File> files) async {
    for (var file in files) {
      if (!thumbnails.containsKey(file.path)) {
        final bytes = await file.readAsBytes();
        final thumb = await PdfService.rasterizePage(bytes, 0);
        if (!mounted) return;
        setState(() {
          thumbnails[file.path] = thumb;
        });
      }
    }
  }

  Future<void> processMergeAndSave() async {
    if (selectedFiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least 2 PDFs to merge")));
      return;
    }
    setState(() => isProcessing = true);

    try {
      // Step 1: Process and get bytes
      final bytes = await PdfService.mergePdfsBytes(selectedFiles);

      if (!mounted) return;

      // Step 2: Show Rename Dialog
      final newName = await PdfService.showSaveAsDialog(context, "Merged_Document");

      if (newName != null && newName.isNotEmpty) {
        // Step 3: Save to disk
        final path = await PdfService.savePdf(bytes, newName);
        
        setState(() {
          savedPath = path;
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDFs Merged Successfully!")));
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
      appBar: AppBar(
        title: const Text("Merge PDFs"),
        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(r.wp(4)),
            child: Row(
              children: [
                Expanded(child: AppButton(icon: Icons.attach_file, label: "Pick PDFs", onPressed: pickPdfs)),
                SizedBox(width: r.wp(3)),
                Expanded(child: AppButton(icon: Icons.unfold_more, label: "Merge", onPressed: selectedFiles.length < 2 || isProcessing ? null : processMergeAndSave, filled: true, isLoading: isProcessing)),
              ],
            ),
          ),
          const Text("Tap to remove · drag to reorder", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                _buildFileGrid(),
                if (isProcessing) const Center(child: CircularProgressIndicator()),
                if (savedPath != null) _buildSaveSuccessOverlay(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      scrollDirection: Axis.vertical,
      itemCount: selectedFiles.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = selectedFiles.removeAt(oldIndex);
          selectedFiles.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final file = selectedFiles[index];
        final fileName = file.path.split(Platform.pathSeparator).last;
        return Padding(
          key: ValueKey(file.path),
          padding: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Stack(
              children: [
                Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: thumbnails[file.path] == null
                      ? const Icon(Icons.picture_as_pdf, color: Colors.grey)
                      : Image.memory(thumbnails[file.path]!, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 2,
                  left: 2,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.black54,
                    child: Text("${index + 1}", style: const TextStyle(fontSize: 8, color: Colors.white)),
                  ),
                ),
              ],
            ),
            title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() => selectedFiles.removeAt(index)),
                ),
                const Icon(Icons.drag_handle, color: Colors.grey),
              ],
            ),
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
            Text("PDFs Merged Successfully!", style: TextStyle(fontSize: r.sp(17), fontWeight: FontWeight.bold)),
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
