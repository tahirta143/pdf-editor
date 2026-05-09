import 'package:flutter/material.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
import 'package:pdfeditorapp/user/home/screens/compress.dart';
import 'package:pdfeditorapp/user/home/screens/crop.dart';
import 'package:pdfeditorapp/user/home/screens/delete_pages.dart';
import 'package:pdfeditorapp/user/home/screens/extract_pages.dart';
import 'package:pdfeditorapp/user/home/screens/fill_sign.dart';
import 'package:pdfeditorapp/user/home/screens/html_pdf.dart';
import 'package:pdfeditorapp/user/home/screens/image_pdf.dart';
import 'package:pdfeditorapp/user/home/screens/merge.dart';
import 'package:pdfeditorapp/user/home/screens/pdf_editor.dart';
import 'package:pdfeditorapp/user/home/screens/pdf_image.dart';
import 'package:pdfeditorapp/user/home/screens/pdf_word.dart';
import 'package:pdfeditorapp/user/home/screens/protect.dart';
import 'package:pdfeditorapp/user/home/screens/split.dart';
import 'package:pdfeditorapp/user/home/screens/unlock.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> tools = [
    {
      "title": "PDF Editor",
      "subtitle": "Edit text, pages, images",
      "icon": Icons.edit_document,
      "color1": const Color(0xFF5B6CFF),
      "color2": const Color(0xFF8A2BE2),
    },
    {
      "title": "Compress",
      "subtitle": "Reduce file size",
      "icon": Icons.compress,
      "color1": const Color(0xFF00C853),
      "color2": const Color(0xFFB2FF59),
    },
    {
      "title": "Delete Pages",
      "subtitle": "Remove pages from PDF",
      "icon": Icons.delete_forever,
      "color1": const Color(0xFFFF3D00),
      "color2": const Color(0xFFD50000),
    },
    {
      "title": "Merge",
      "subtitle": "Combine PDFs & images",
      "icon": Icons.merge,
      "color1": const Color(0xFF3F51B5),
      "color2": const Color(0xFF2196F3),
    },
    {
      "title": "Split",
      "subtitle": "Split or extract pages",
      "icon": Icons.call_split,
      "color1": const Color(0xFFFF9800),
      "color2": const Color(0xFFFFC107),
    },
    {
      "title": "Crop",
      "subtitle": "Trim PDF margins",
      "icon": Icons.crop,
      "color1": const Color(0xFF00BCD4),
      "color2": const Color(0xFFB2EBF2),
    },
    {
      "title": "Fill & Sign",
      "subtitle": "Add signature to PDF",
      "icon": Icons.draw,
      "color1": const Color(0xFF7E57C2),
      "color2": const Color(0xFFCE93D8),
    },
    {
      "title": "PDF to Word",
      "subtitle": "Convert PDF to DOC",
      "icon": Icons.picture_as_pdf,
      "color1": const Color(0xFF2196F3),
      "color2": const Color(0xFF64B5F6),
    },
    {
      "title": "Extract Pages",
      "subtitle": "Extract selected pages",
      "icon": Icons.content_cut,
      "color1": const Color(0xFFFFB300),
      "color2": const Color(0xFFFFE082),
    },
    {
      "title": "Protect",
      "subtitle": "Add password to PDF",
      "icon": Icons.lock,
      "color1": const Color(0xFFD32F2F),
      "color2": const Color(0xFFEF5350),
    },
    {
      "title": "Unlock",
      "subtitle": "Remove PDF password",
      "icon": Icons.lock_open,
      "color1": const Color(0xFF43A047),
      "color2": const Color(0xFF81C784),
    },
    {
      "title": "PDF to Image",
      "subtitle": "Export pages as images",
      "icon": Icons.image,
      "color1": const Color(0xFF3F51B5),
      "color2": const Color(0xFF90CAF9),
    },
    {
      "title": "HTML to PDF",
      "subtitle": "Convert webpage to PDF",
      "icon": Icons.language,
      "color1": const Color(0xFF6A1B9A),
      "color2": const Color(0xFFBA68C8),
    },
    {
      "title": "Image to PDF",
      "subtitle": "Convert images to PDF",
      "icon": Icons.photo_library,
      "color1": const Color(0xFF26A69A),
      "color2": const Color(0xFFA7FFEB),
    },
  ];

  final List<Widget> screens = [
    const PdfEditorScreen(),
    const CompressPdfScreen(),
    const DeletePagesScreen(),
    const MergePdfScreen(),
    const SplitPdfScreen(),
    const CropPdfScreen(),
    const FillAndSignScreen(),
    const PdfToWordScreen(),
    const ExtractPagesScreen(),
    const ProtectPdfScreen(),
    const UnlockPdfScreen(),
    const PdfToImageScreen(),
    const HtmlToPdfScreen(),
    const ImageToPdfScreen(),
  ];

  int _crossAxisCount(ResponsiveHelper r) {
    if (r.isLandscape) {
      switch (r.breakpoint) {
        case Breakpoint.compact:
        case Breakpoint.standard:
          return 4;
        case Breakpoint.expanded:
          return 5;
        case Breakpoint.tablet:
          return 6;
      }
    }
    switch (r.breakpoint) {
      case Breakpoint.compact:
      case Breakpoint.standard:
        return 3;
      case Breakpoint.expanded:
        return 4;
      case Breakpoint.tablet:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final headerHeight = r.isLandscape ? r.hp(25) : r.hp(18);
    final crossCount = _crossAxisCount(r);

    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: Text(
          "PDF Editor App",
          style: TextStyle(
            fontSize: r.sp(22),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black87,
            shadows: const [
              Shadow(blurRadius: 6, color: Colors.black12, offset: Offset(1, 2))
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
            child: Image.asset(
              "assets/images/img.png",
              height: headerHeight,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r.wp(3)),
              child: GridView.builder(
                itemCount: tools.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = tools[index];
                  return _buildCard(
                    r,
                    index,
                    item["title"],
                    item["subtitle"],
                    item["icon"],
                    item["color1"],
                    item["color2"],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      ResponsiveHelper r,
      int index,
      String title,
      String subtitle,
      IconData icon,
      Color c1,
      Color c2,
      ) {
    final iconSize = r.scale(45);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screens[index]),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: iconSize,
                width: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [c1, c2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: iconSize * 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: r.sp(11),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.sp(9),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}