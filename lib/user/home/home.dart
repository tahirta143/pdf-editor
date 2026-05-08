import 'package:flutter/material.dart';
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
      "color1": Color(0xFF5B6CFF),
      "color2": Color(0xFF8A2BE2),
    },
    {
      "title": "Compress",
      "subtitle": "Reduce file size",
      "icon": Icons.compress,
      "color1": Color(0xFF00C853),
      "color2": Color(0xFFB2FF59),
    },
    {
      "title": "Delete Pages",
      "subtitle": "Remove pages from PDF",
      "icon": Icons.delete_forever,
      "color1": Color(0xFFFF3D00),
      "color2": Color(0xFFD50000),
    },
    {
      "title": "Merge",
      "subtitle": "Combine PDFs & images",
      "icon": Icons.merge,
      "color1": Color(0xFF3F51B5),
      "color2": Color(0xFF2196F3),
    },
    {
      "title": "Split",
      "subtitle": "Split or extract pages",
      "icon": Icons.call_split,
      "color1": Color(0xFFFF9800),
      "color2": Color(0xFFFFC107),
    },
    {
      "title": "Crop",
      "subtitle": "Trim PDF margins",
      "icon": Icons.crop,
      "color1": Color(0xFF00BCD4),
      "color2": Color(0xFFB2EBF2),
    },
    {
      "title": "Fill & Sign",
      "subtitle": "Add signature to PDF",
      "icon": Icons.draw,
      "color1": Color(0xFF7E57C2),
      "color2": Color(0xFFCE93D8),
    },
    {
      "title": "PDF to Word",
      "subtitle": "Convert PDF to DOC",
      "icon": Icons.picture_as_pdf,
      "color1": Color(0xFF2196F3),
      "color2": Color(0xFF64B5F6),
    },
    {
      "title": "Extract Pages",
      "subtitle": "Extract selected pages",
      "icon": Icons.content_cut,
      "color1": Color(0xFFFFB300),
      "color2": Color(0xFFFFE082),
    },
    {
      "title": "Protect",
      "subtitle": "Add password to PDF",
      "icon": Icons.lock,
      "color1": Color(0xFFD32F2F),
      "color2": Color(0xFFEF5350),
    },
    {
      "title": "Unlock",
      "subtitle": "Remove PDF password",
      "icon": Icons.lock_open,
      "color1": Color(0xFF43A047),
      "color2": Color(0xFF81C784),
    },
    {
      "title": "PDF to Image",
      "subtitle": "Export pages as images",
      "icon": Icons.image,
      "color1": Color(0xFF3F51B5),
      "color2": Color(0xFF90CAF9),
    },
    {
      "title": "HTML to PDF",
      "subtitle": "Convert webpage to PDF",
      "icon": Icons.language,
      "color1": Color(0xFF6A1B9A),
      "color2": Color(0xFFBA68C8),
    },
    {
      "title": "Image to PDF",
      "subtitle": "Convert images to PDF",
      "icon": Icons.photo_library,
      "color1": Color(0xFF26A69A),
      "color2": Color(0xFFA7FFEB),
    },
  ];


  final List<Widget> screens = [
    const PdfEditorScreen(),
    const CompressPdfPage(),
    const delete_pages(),
    const merge(),
    const split(),
    const crop(),
    const fill_sign(),
    const pdf_word(),
    const extract_pages(),
    const protect(),
    const unlock(),
    const pdf_image(),
    const html_pdf(),
    const image_pdf(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE6),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        title: const Text(
          "PDF Editor App",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.black87,
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.black12,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),

      body: Column(
        children: [

          /// TOP BACKGROUND DESIGN (like your image)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
            child: Image.asset(
              "assets/images/img.png",
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 10),

          /// GRID
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: tools.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = tools[index];

                  return _buildCard(
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
      int index,
      String title,
      String subtitle,
      IconData icon,
      Color c1,
      Color c2,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => screens[index],
          ),
        );
      },
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

              /// ICON GRADIENT CIRCLE
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [c1, c2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white),
              ),

              const SizedBox(height: 10),

              /// TITLE
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 5),

              /// SUBTITLE
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
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