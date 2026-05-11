import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors, Color, Offset, BuildContext, showDialog, AlertDialog, TextField, TextEditingController, TextButton, ElevatedButton, InputDecoration, Rect, Size, Navigator, Text;
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static bool isEncryptedPdfError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('encrypted document') ||
        message.contains('password is invalid');
  }

  static Future<String?> showPasswordDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "PDF Password",
            hintText: "Enter password",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3E5F5),
              foregroundColor: const Color(0xFF7E57C2),
            ),
            child: const Text("Unlock"),
          ),
        ],
      ),
    );
  }

  /// Request storage permission (Android) and return the Downloads directory
  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        await Permission.manageExternalStorage.request();
      }

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) return extDir;
    }
    return await getApplicationDocumentsDirectory();
  }

  static Future<String> savePdf(List<int> bytes, String fileName) async {
    final directory = await _getDownloadsDirectory();
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = "$fileName.pdf";
    }
    final path = p.join(directory.path, fileName);
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  static Future<String> saveFile(List<int> bytes, String fileName) async {
    final directory = await _getDownloadsDirectory();
    final path = p.join(directory.path, fileName);
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  /// Show a dialog to let the user edit the filename before saving
  static Future<String?> showSaveAsDialog(BuildContext context, String initialName) async {
    final controller = TextEditingController(text: initialName);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Save PDF"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "File Name",
            hintText: "Enter file name",
            suffixText: ".pdf",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3E5F5), foregroundColor: const Color(0xFF7E57C2)),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Rasterize a specific page to an image (for thumbnails)
  static Future<Uint8List?> rasterizePage(Uint8List pdfBytes, int pageIndex) async {
    try {
      await for (final page in Printing.raster(pdfBytes, pages: [pageIndex], dpi: 100)) {
        return await page.toPng();
      }
    } catch (e) {
      debugPrint("Rasterize error: $e");
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAP-TO-EDIT: Find text at a tapped PDF coordinate
  // ─────────────────────────────────────────────────────────────────────────

  /// Searches all text lines on [pageIndex] and returns the line whose bounds
  /// contain [tapPosition] (PDF-space points). A [hitRadius] tolerance is used
  /// to make small text easier to tap.
  ///
  /// Returns a record with the original text and its bounding rect, or null
  /// when nothing is found near the tap.
  static Future<({String text, Rect bounds})?> findTextAtPosition(
      File file,
      int pageIndex,
      Offset tapPosition, {
        String? password,
        double hitRadius = 8.0,
      }) async {
    final PdfDocument doc = PdfDocument(
      inputBytes: await file.readAsBytes(),
      password: password,
    );
    try {
      final PdfTextExtractor extractor = PdfTextExtractor(doc);
      final List<TextLine> lines = extractor.extractTextLines(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );

      // Exact hit first
      for (final TextLine line in lines) {
        if (line.bounds.contains(tapPosition)) {
          return (text: line.text, bounds: line.bounds);
        }
      }

      // Tolerance hit — pick nearest centre within hitRadius
      ({String text, Rect bounds})? best;
      double bestDist = double.infinity;
      for (final TextLine line in lines) {
        final Rect expanded = Rect.fromLTRB(
          line.bounds.left - hitRadius,
          line.bounds.top - hitRadius,
          line.bounds.right + hitRadius,
          line.bounds.bottom + hitRadius,
        );
        if (expanded.contains(tapPosition)) {
          final Offset centre = line.bounds.center;
          final double dist = (centre - tapPosition).distance;
          if (dist < bestDist) {
            bestDist = dist;
            best = (text: line.text, bounds: line.bounds);
          }
        }
      }
      return best;
    } catch (e) {
      debugPrint("findTextAtPosition error: $e");
      return null;
    } finally {
      doc.dispose();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAP-TO-EDIT: Replace text at known bounds
  // ─────────────────────────────────────────────────────────────────────────

  /// Whites-out the original text area on [pageIndex] and draws [newText]
  /// at the same position with the given styling.
  ///
  /// Font size is estimated from the line height so the replacement text
  /// visually matches the original size.
  static Future<List<int>> editTextAtBounds(
      File file,
      int pageIndex,
      Rect bounds,
      String newText, {
        bool isBold = false,
        bool isItalic = false,
        bool isUnderlined = false,
        Color color = Colors.black,
        String? password,
      }) async {
    final PdfDocument doc = PdfDocument(
      inputBytes: await file.readAsBytes(),
      password: password,
    );

    final PdfPage page = doc.pages[pageIndex.clamp(0, doc.pages.count - 1)];

    // ── 1. White-out the original text area ─────────────────────────────
    // Add a small vertical padding so ascenders/descenders are fully covered.
    final Rect whiteoutRect = Rect.fromLTRB(
      bounds.left - 1,
      bounds.top - 2,
      bounds.right + 1,
      bounds.bottom + 2,
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: whiteoutRect,
    );

    // ── 2. Estimate font size from line height ──────────────────────────
    // PDF line height ≈ font size * 1.2, so font ≈ height / 1.2
    final double fontSize = (bounds.height / 1.2).clamp(6.0, 72.0);

    // ── 3. Build font with requested styles ────────────────────────────
    final List<PdfFontStyle> styles = [];
    if (isBold) styles.add(PdfFontStyle.bold);
    if (isItalic) styles.add(PdfFontStyle.italic);
    if (isUnderlined) styles.add(PdfFontStyle.underline);

    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      fontSize,
      multiStyle: styles.isNotEmpty ? styles : null,
    );

    // ── 4. Draw the new text at the same position ───────────────────────
    final double pageWidth = page.getClientSize().width;
    page.graphics.drawString(
      newText,
      font,
      brush: PdfSolidBrush(
        PdfColor(
          (color.r * 255.0).round().clamp(0, 255),
          (color.g * 255.0).round().clamp(0, 255),
          (color.b * 255.0).round().clamp(0, 255),
        ),
      ),
      bounds: Rect.fromLTWH(
        bounds.left,
        bounds.top,
        // Allow text to flow rightward if it's longer than original
        (pageWidth - bounds.left).clamp(bounds.width, pageWidth - bounds.left),
        bounds.height + 4,
      ),
    );

    final List<int> bytes = await doc.save();
    doc.dispose();
    return bytes;
  }

  /// Convert Images to PDF
  static Future<List<int>> imagesToPdfBytes(List<File> images) async {
    final PdfDocument document = PdfDocument();
    for (var imageFile in images) {
      final PdfPage page = document.pages.add();
      final PdfBitmap image = PdfBitmap(await imageFile.readAsBytes());
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
      );
    }
    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// Merge multiple PDFs
  static Future<List<int>> mergePdfsBytes(List<File> files) async {
    final PdfDocument document = PdfDocument();
    for (var file in files) {
      final PdfDocument inputDoc = PdfDocument(inputBytes: await file.readAsBytes());
      for (int i = 0; i < inputDoc.pages.count; i++) {
        final PdfPage page = inputDoc.pages[i];
        final PdfTemplate template = page.createTemplate();
        final PdfPage newPage = document.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      inputDoc.dispose();
    }
    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// Compress PDF
  static Future<List<int>> compressPdfBytes(
      File file, {
        double quality = 50,
        String? password,
      }) async {
    final Uint8List inputBytes = await file.readAsBytes();
    final PdfDocument sourceDoc = PdfDocument(
      inputBytes: inputBytes,
      password: password,
    );
    final Uint8List unlockedBytes = Uint8List.fromList(await sourceDoc.save());
    final List<Size> pageSizes = List<Size>.generate(
      sourceDoc.pages.count,
          (index) => sourceDoc.pages[index].getClientSize(),
    );
    sourceDoc.dispose();

    final double clampedQuality = quality.clamp(1, 100);
    final List<double> candidateDpis = <double>[
      (30 + ((clampedQuality / 100) * 160)),
      (24 + ((clampedQuality / 100) * 130)),
      (18 + ((clampedQuality / 100) * 100)),
    ].map((e) => e.clamp(12, 220).toDouble()).toList();

    List<int>? bestRasterBytes;
    for (final dpi in candidateDpis) {
      final List<int>? bytes = await _compressViaRaster(unlockedBytes, pageSizes, dpi);
      if (bytes == null) continue;
      if (bestRasterBytes == null || bytes.length < bestRasterBytes.length) {
        bestRasterBytes = bytes;
      }
    }

    final List<int> templateBytes = await _rebuildPdfForCompression(unlockedBytes, password: null);

    List<int> bestBytes = templateBytes;
    if (bestRasterBytes != null && bestRasterBytes.length < bestBytes.length) {
      bestBytes = bestRasterBytes;
    }
    if (inputBytes.length < bestBytes.length) return inputBytes;
    return bestBytes;
  }

  static Future<List<int>?> _compressViaRaster(
      Uint8List inputBytes,
      List<Size> pageSizes,
      double dpi,
      ) async {
    final PdfDocument rasterCompressedDoc = PdfDocument();
    rasterCompressedDoc.compressionLevel = PdfCompressionLevel.best;

    int pageIndex = 0;
    try {
      await for (final page in Printing.raster(inputBytes, dpi: dpi)) {
        if (pageIndex >= pageSizes.length) break;
        final Uint8List imageBytes = await page.toPng();
        final Size pageSize = pageSizes[pageIndex];
        rasterCompressedDoc.pageSettings.size = pageSize;
        rasterCompressedDoc.pageSettings.margins.all = 0;
        final PdfPage newPage = rasterCompressedDoc.pages.add();
        newPage.graphics.drawImage(
          PdfBitmap(imageBytes),
          Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
        );
        pageIndex++;
      }
      if (pageIndex == 0) {
        rasterCompressedDoc.dispose();
        return null;
      }
      final List<int> result = await rasterCompressedDoc.save();
      rasterCompressedDoc.dispose();
      return result;
    } catch (_) {
      rasterCompressedDoc.dispose();
      return null;
    }
  }

  static Future<List<int>> _rebuildPdfForCompression(
      Uint8List inputBytes, {
        String? password,
      }) async {
    final PdfDocument inputDoc = PdfDocument(inputBytes: inputBytes, password: password);
    final PdfDocument outputDoc = PdfDocument();
    outputDoc.compressionLevel = PdfCompressionLevel.best;

    for (int i = 0; i < inputDoc.pages.count; i++) {
      final PdfPage page = inputDoc.pages[i];
      final PdfTemplate template = page.createTemplate();
      final PdfPage newPage = outputDoc.pages.add();
      newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
    }

    final List<int> bytes = await outputDoc.save();
    inputDoc.dispose();
    outputDoc.dispose();
    return bytes;
  }

  /// Extract specific pages from PDF
  static Future<List<int>> extractPagesBytes(File file, List<int> pageIndices) async {
    final PdfDocument inputDoc = PdfDocument(inputBytes: await file.readAsBytes());
    final PdfDocument outputDoc = PdfDocument();
    outputDoc.compressionLevel = PdfCompressionLevel.best;

    for (var index in pageIndices) {
      if (index >= 0 && index < inputDoc.pages.count) {
        final PdfPage page = inputDoc.pages[index];
        final PdfTemplate template = page.createTemplate();
        final PdfPage newPage = outputDoc.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
    }

    final List<int> bytes = await outputDoc.save();
    inputDoc.dispose();
    outputDoc.dispose();
    return bytes;
  }

  /// Convert PDF pages to Images
  static Future<List<String>> pdfToImages(File file, {int dpi = 150, String format = 'png'}) async {
    final List<String> savedImagePaths = [];
    final Directory tempDir = await getTemporaryDirectory();
    final Uint8List pdfBytes = await file.readAsBytes();

    int pageCount = 0;
    await for (final page in Printing.raster(pdfBytes, dpi: dpi.toDouble())) {
      final Uint8List imageBytes = await page.toPng();
      final String extension = (format.toLowerCase() == 'jpg' || format.toLowerCase() == 'jpeg') ? 'jpg' : 'png';
      final path = p.join(tempDir.path, "page_${pageCount + 1}_${DateTime.now().millisecondsSinceEpoch}.$extension");
      await File(path).writeAsBytes(imageBytes);
      savedImagePaths.add(path);
      pageCount++;
    }

    return savedImagePaths;
  }

  /// Convert HTML string to PDF
  static Future<List<int>> htmlToPdfBytes(String htmlContent) async {
    return await Printing.convertHtml(
      html: htmlContent,
      format: pw.PdfPageFormat.a4,
    );
  }

  /// Extract Text
  static Future<String> extractText(File file) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      if (pageText.trim().isNotEmpty) {
        buffer.writeln('--- Page ${i + 1} ---');
        buffer.writeln(pageText);
        buffer.writeln();
      }
    }
    document.dispose();
    return buffer.toString();
  }

  /// Add text to PDF (new annotation at a fixed position)
  static Future<List<int>> addTextToPdfBytes(
      File file,
      String text,
      Offset position, {
        int pageIndex = 0,
        bool isBold = false,
        bool isItalic = false,
        bool isUnderlined = false,
        Color color = Colors.black,
        double fontSize = 20,
      }) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    final int validPageIndex = pageIndex.clamp(0, document.pages.count - 1);
    final PdfPage page = document.pages[validPageIndex];

    final List<PdfFontStyle> styles = [];
    if (isBold) styles.add(PdfFontStyle.bold);
    if (isItalic) styles.add(PdfFontStyle.italic);
    if (isUnderlined) styles.add(PdfFontStyle.underline);

    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      fontSize,
      multiStyle: styles.isNotEmpty ? styles : null,
    );

    page.graphics.drawString(
      text,
      font,
      brush: PdfSolidBrush(
        PdfColor(
          (color.r * 255.0).round().clamp(0, 255),
          (color.g * 255.0).round().clamp(0, 255),
          (color.b * 255.0).round().clamp(0, 255),
        ),
      ),
      bounds: Rect.fromLTWH(position.dx, position.dy, page.getClientSize().width - position.dx, fontSize * 2),
    );

    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// Protect PDF with a password
  static Future<List<int>> protectPdfBytes(File file, String password) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    final PdfSecurity security = document.security;
    security.userPassword = password;
    security.ownerPassword = password;
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// Unlock PDF (remove password)
  static Future<List<int>> unlockPdfBytes(File file, String password) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes(), password: password);
    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// Delete pages from PDF
  static Future<List<int>> deletePagesBytes(File file, List<int> pageIndices) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    pageIndices.sort((a, b) => b.compareTo(a));
    for (var index in pageIndices) {
      if (index >= 0 && index < document.pages.count) {
        document.pages.removeAt(index);
      }
    }
    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// Crop PDF pages
  static Future<List<int>> cropPdfBytes(
      File file,
      Rect normalizedCropRect, {
        Size? outputPageSize,
        bool fitToPage = false,
        String? password,
        int? pageIndex,
      }) async {
    final PdfDocument inputDoc = PdfDocument(
      inputBytes: await file.readAsBytes(),
      password: password,
    );
    final PdfDocument outputDoc = PdfDocument();
    outputDoc.compressionLevel = PdfCompressionLevel.best;
    outputDoc.pageSettings.margins.all = 0;

    for (int i = 0; i < inputDoc.pages.count; i++) {
      if (pageIndex != null && i != pageIndex) continue;
      final PdfPage page = inputDoc.pages[i];
      final PdfTemplate template = page.createTemplate();
      final Size pageSize = page.getClientSize();
      final double left = normalizedCropRect.left.clamp(0.0, 1.0) * pageSize.width;
      final double top = normalizedCropRect.top.clamp(0.0, 1.0) * pageSize.height;
      final double right = normalizedCropRect.right.clamp(0.0, 1.0) * pageSize.width;
      final double bottom = normalizedCropRect.bottom.clamp(0.0, 1.0) * pageSize.height;
      final Rect cropRect = Rect.fromLTRB(
        left, top,
        right > left ? right : left + 1,
        bottom > top ? bottom : top + 1,
      );

      final Size targetPageSize = outputPageSize ?? Size(cropRect.width, cropRect.height);
      outputDoc.pageSettings.size = targetPageSize;
      outputDoc.pageSettings.margins.all = 0;
      final PdfPage newPage = outputDoc.pages.add();
      double offsetX = -cropRect.left + ((targetPageSize.width - cropRect.width) / 2);
      double offsetY = -cropRect.top + ((targetPageSize.height - cropRect.height) / 2);

      if (fitToPage && outputPageSize != null) {
        final double scaleX = targetPageSize.width / cropRect.width;
        final double scaleY = targetPageSize.height / cropRect.height;
        final double scale = scaleX < scaleY ? scaleX : scaleY;
        offsetX = -cropRect.left * scale + ((targetPageSize.width - (cropRect.width * scale)) / 2);
        offsetY = -cropRect.top * scale + ((targetPageSize.height - (cropRect.height * scale)) / 2);
        newPage.graphics.drawPdfTemplate(
          template,
          Offset(offsetX, offsetY),
          Size(pageSize.width * scale, pageSize.height * scale),
        );
      } else {
        newPage.graphics.drawPdfTemplate(template, Offset(offsetX, offsetY));
      }
    }

    final List<int> bytes = await outputDoc.save();
    inputDoc.dispose();
    outputDoc.dispose();
    return bytes;
  }

  static Future<Size> getFirstPageSize(File file, {String? password}) async {
    final PdfDocument document = PdfDocument(
      inputBytes: await file.readAsBytes(),
      password: password,
    );
    if (document.pages.count == 0) {
      document.dispose();
      return const Size(1, 1);
    }
    final Size size = document.pages[0].getClientSize();
    document.dispose();
    return size;
  }

  static Future<Size> getPageSize(File file, {required int pageIndex, String? password}) async {
    final PdfDocument document = PdfDocument(
      inputBytes: await file.readAsBytes(),
      password: password,
    );
    if (document.pages.count == 0) {
      document.dispose();
      return const Size(1, 1);
    }
    final int safeIndex = pageIndex.clamp(0, document.pages.count - 1);
    final Size size = document.pages[safeIndex].getClientSize();
    document.dispose();
    return size;
  }

  static Future<int> getPageCount(File file) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    final int count = document.pages.count;
    document.dispose();
    return count;
  }

  static Future<int> getPageCountWithPassword(File file, {String? password}) async {
    final PdfDocument document = PdfDocument(
      inputBytes: await file.readAsBytes(),
      password: password,
    );
    final int count = document.pages.count;
    document.dispose();
    return count;
  }

  static Future<Uint8List> buildPreviewPdfBytes(File file, {String? password}) async {
    final Uint8List inputBytes = await file.readAsBytes();
    if (password == null || password.isEmpty) return inputBytes;
    final PdfDocument doc = PdfDocument(inputBytes: inputBytes, password: password);
    final List<int> bytes = await doc.save();
    doc.dispose();
    return Uint8List.fromList(bytes);
  }
}