import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfEditorScreen extends StatefulWidget {
  const PdfEditorScreen({super.key});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {

  File? selectedFile;

  List<_TextItem> textItems = [];
  _TextItem? selectedItem;

  /// PICK PDF
  Future<void> pickPDF() async { try { FilePickerResult? result = await FilePicker.pickFiles( type: FileType.custom, allowedExtensions: ['pdf'], ); if (result != null && result.files.isNotEmpty) { final file = result.files.first; if (file.path != null) { setState(() { selectedFile = File(file.path!); }); } } } catch (e) { debugPrint("File picker error: $e"); } }

  /// ADD TEXT
  void addText() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Text"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                textItems.add(
                  _TextItem(
                    text: controller.text,
                    position: const Offset(100, 100),
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  /// EDIT TEXT
  void editText(_TextItem item) {
    TextEditingController controller =
    TextEditingController(text: item.text);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Text"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                item.text = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  /// SAVE PDF
  Future<void> savePdf() async {
    if (selectedFile == null) return;

    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;

    /// Draw white background
    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width,
          page.getClientSize().height),
    );

    /// Draw text items
    for (var item in textItems) {
      final font = PdfStandardFont(
        PdfFontFamily.helvetica,
        item.fontSize,
        style: _getFontStyle(item),
      );

      graphics.drawString(
        item.text,
        font,
        bounds: Rect.fromLTWH(
          item.position.dx,
          item.position.dy,
          300,
          50,
        ),
      );
    }

    /// Save file
    final directory = Directory('/storage/emulated/0/Download');
    final file = File(
        '${directory.path}/edited_${DateTime.now().millisecondsSinceEpoch}.pdf');

    await file.writeAsBytes(await document.save());
    document.dispose();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved: ${file.path}")),
    );
  }

  PdfFontStyle _getFontStyle(_TextItem item) {
    PdfFontStyle style = PdfFontStyle.regular;

    if (item.isBold) style = PdfFontStyle.bold;
    if (item.isItalic) style = PdfFontStyle.italic;

    return style;
  }

  /// TOOLBAR
  Widget buildToolbar() {
    if (selectedItem == null) return const SizedBox();

    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.black87,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            IconButton(
              icon: Icon(Icons.format_bold,
                  color: selectedItem!.isBold ? Colors.blue : Colors.white),
              onPressed: () {
                setState(() {
                  selectedItem!.isBold = !selectedItem!.isBold;
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.format_italic,
                  color: selectedItem!.isItalic ? Colors.blue : Colors.white),
              onPressed: () {
                setState(() {
                  selectedItem!.isItalic = !selectedItem!.isItalic;
                });
              },
            ),

            IconButton(
              icon: Icon(Icons.format_underline,
                  color: selectedItem!.isUnderline ? Colors.blue : Colors.white),
              onPressed: () {
                setState(() {
                  selectedItem!.isUnderline = !selectedItem!.isUnderline;
                });
              },
            ),

            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                setState(() {
                  selectedItem!.fontSize += 2;
                });
              },
            ),

            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: () {
                setState(() {
                  selectedItem!.fontSize -= 2;
                });
              },
            ),

            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  textItems.remove(selectedItem);
                  selectedItem = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Editor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: pickPDF,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addText,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: savePdf,
          ),
        ],
      ),

      body: selectedFile == null
          ? const Center(child: Text("Pick a PDF"))
          : Stack(
        children: [

          /// PDF VIEW
          SfPdfViewer.file(selectedFile!),

          /// TEXT LAYERS
          ...textItems.map((item) {
            return Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedItem = item;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    item.position += details.delta;
                  });
                },
                onLongPress: () => editText(item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: selectedItem == item
                        ? Border.all(color: Colors.blue)
                        : null,
                  ),
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: item.fontSize,
                      fontWeight: item.isBold
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontStyle: item.isItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      decoration: item.isUnderline
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            );
          }),

          buildToolbar(),
        ],
      ),
    );
  }
}

/// MODEL
class _TextItem {
  String text;
  Offset position;

  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  double fontSize = 18;

  _TextItem({
    required this.text,
    required this.position,
  });
}