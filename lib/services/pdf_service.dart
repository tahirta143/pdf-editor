import 'dart:io';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' as pdfx;

class PdfService {
  /// Save PDF bytes to a file in the app's documents directory or downloads
  static Future<String> savePdf(List<int> bytes, String fileName) async {
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final path = p.join(directory!.path, fileName);
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  /// Convert Images to PDF
  static Future<String> imagesToPdf(List<File> images, String outputName) async {
    // Create a new PDF document
    final PdfDocument document = PdfDocument();

    for (var imageFile in images) {
      // Add a page to the document
      final PdfPage page = document.pages.add();
      
      // Load the image
      final PdfBitmap image = PdfBitmap(await imageFile.readAsBytes());
      
      // Draw the image to the page
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
      );
    }

    // Save the document
    final List<int> bytes = await document.save();
    
    // Dispose the document
    document.dispose();

    // Save to file
    return await savePdf(bytes, "$outputName.pdf");
  }

  /// Merge multiple PDFs
  static Future<String> mergePdfs(List<File> files, String outputName) async {
    final PdfDocument document = PdfDocument();

    for (var file in files) {
      final PdfDocument inputDoc = PdfDocument(inputBytes: await file.readAsBytes());
      
      // Merge all pages from inputDoc to document
      for (int i = 0; i < inputDoc.pages.count; i++) {
        // Create a template from the page
        final PdfPage page = inputDoc.pages[i];
        final PdfTemplate template = page.createTemplate();
        
        // Add new page to master doc and draw template
        final PdfPage newPage = document.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      
      inputDoc.dispose();
    }

    final List<int> bytes = await document.save();
    document.dispose();

    return await savePdf(bytes, "$outputName.pdf");
  }

  /// Compress PDF
  static Future<String> compressPdf(File file, String outputName) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    
    // Set compression level
    document.compressionLevel = PdfCompressionLevel.best;
    
    // Save with compression
    final List<int> bytes = await document.save();
    document.dispose();

    return await savePdf(bytes, "compressed_$outputName.pdf");
  }

  /// Split PDF into multiple documents based on page ranges
  /// ranges: "1-2, 3-4"
  static Future<List<String>> splitPdf(File file, String ranges) async {
    final PdfDocument inputDoc = PdfDocument(inputBytes: await file.readAsBytes());
    List<String> savedPaths = [];
    
    final List<String> rangeList = ranges.split(',');
    int count = 1;

    for (var range in rangeList) {
      final parts = range.trim().split('-');
      int start = int.parse(parts[0]) - 1;
      int end = parts.length > 1 ? int.parse(parts[1]) - 1 : start;

      final PdfDocument outputDoc = PdfDocument();
      for (int i = start; i <= end; i++) {
        if (i >= 0 && i < inputDoc.pages.count) {
          final PdfPage page = inputDoc.pages[i];
          final PdfTemplate template = page.createTemplate();
          final PdfPage newPage = outputDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      final List<int> bytes = await outputDoc.save();
      outputDoc.dispose();
      
      final path = await savePdf(bytes, "split_${count}_${p.basename(file.path)}");
      savedPaths.add(path);
      count++;
    }

    inputDoc.dispose();
    return savedPaths;
  }

  /// Protect PDF with a password
  static Future<String> protectPdf(File file, String password, String outputName) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    
    // Set security
    final PdfSecurity security = document.security;
    security.userPassword = password;
    security.ownerPassword = password;
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    
    final List<int> bytes = await document.save();
    document.dispose();

    return await savePdf(bytes, "protected_$outputName.pdf");
  }

  /// Unlock PDF (remove password)
  static Future<String> unlockPdf(File file, String password, String outputName) async {
    // Syncfusion requires the password to open a protected document
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes(), password: password);
    
    // Remove security by saving it without any security settings
    // document.security is already initialized, but saving it fresh usually works.
    // In Syncfusion Flutter, you might need to create a new doc if security doesn't clear easily.
    
    final PdfDocument newDoc = PdfDocument();
    for (int i = 0; i < document.pages.count; i++) {
      final PdfTemplate template = document.pages[i].createTemplate();
      newDoc.pages.add().graphics.drawPdfTemplate(template, const Offset(0, 0));
    }

    final List<int> bytes = await newDoc.save();
    document.dispose();
    newDoc.dispose();

    return await savePdf(bytes, "unlocked_$outputName.pdf");
  }

  /// Delete pages from PDF
  static Future<String> deletePages(File file, List<int> pageIndices, String outputName) async {
    final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
    
    // Sort indices in descending order to avoid index shift issues
    pageIndices.sort((a, b) => b.compareTo(a));
    
    for (var index in pageIndices) {
      if (index >= 0 && index < document.pages.count) {
        document.pages.removeAt(index);
      }
    }

    final List<int> bytes = await document.save();
    document.dispose();

    return await savePdf(bytes, "modified_$outputName.pdf");
  }

  /// Convert PDF pages to Images
  static Future<List<String>> pdfToImages(File file) async {
    final document = await pdfx.PdfDocument.openFile(file.path);
    List<String> savedImagePaths = [];
    
    final Directory tempDir = await getTemporaryDirectory();
    
    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: pdfx.PdfPageImageFormat.jpeg,
      );
      
      if (pageImage != null) {
        final path = p.join(tempDir.path, "page_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg");
        final imageFile = File(path);
        await imageFile.writeAsBytes(pageImage.bytes);
        savedImagePaths.add(path);
      }
      await page.close();
    }
    await document.close();
    return savedImagePaths;
  }

  /// Crop PDF pages (Re-implemented using template approach)
  static Future<String> cropPdf(File file, Rect cropRect, String outputName) async {
    final PdfDocument inputDoc = PdfDocument(inputBytes: await file.readAsBytes());
    final PdfDocument outputDoc = PdfDocument();
    
    // Set the output page size to the crop rectangle's size
    outputDoc.pageSettings.size = Size(cropRect.width, cropRect.height);
    outputDoc.pageSettings.margins.all = 0;

    for (int i = 0; i < inputDoc.pages.count; i++) {
      final PdfPage page = inputDoc.pages[i];
      final PdfTemplate template = page.createTemplate();
      
      final PdfPage newPage = outputDoc.pages.add();
      // Draw the template with an offset to achieve the "crop" effect
      newPage.graphics.drawPdfTemplate(
        template, 
        Offset(-cropRect.left, -cropRect.top),
      );
    }

    final List<int> bytes = await outputDoc.save();
    inputDoc.dispose();
    outputDoc.dispose();

    return await savePdf(bytes, "cropped_$outputName.pdf");
  }
}
