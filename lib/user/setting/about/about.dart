import 'package:flutter/material.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final hPad = r.wp(4);

    Widget content = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(hPad),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: r.scale(55),
              backgroundColor: Colors.red.shade100,
              child: Icon(Icons.picture_as_pdf, size: r.scale(55), color: const Color(0xFFF50F10)),
            ),
            const SizedBox(height: 20),
            Text("PDF Editor App", style: TextStyle(fontSize: r.sp(22), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Version 1.0.8", style: TextStyle(fontSize: r.sp(14), color: Colors.black54)),
            const SizedBox(height: 20),
            Text(
              "PDF Editor App is a powerful and easy-to-use tool designed to manage all your PDF needs in one place. "
              "You can view, edit, convert, merge, split, and organize PDF files directly from your mobile device without any hassle.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: r.sp(13), height: 1.5),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Key Features", style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("• View PDF files with smooth performance", style: TextStyle(fontSize: r.sp(13))),
                  Text("• Edit and modify PDF documents easily", style: TextStyle(fontSize: r.sp(13))),
                  Text("• Merge multiple PDFs into one file", style: TextStyle(fontSize: r.sp(13))),
                  Text("• Split large PDF files", style: TextStyle(fontSize: r.sp(13))),
                  Text("• Convert images to PDF", style: TextStyle(fontSize: r.sp(13))),
                  Text("• Fast and lightweight performance", style: TextStyle(fontSize: r.sp(13))),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Divider(),
            const ListTile(leading: Icon(Icons.code), title: Text("Developer"), subtitle: Text("PDF Editor App Team")),
            const Divider(),
            const ListTile(leading: Icon(Icons.email), title: Text("Support"), subtitle: Text("support@pdfeditorapp.com")),
            const Divider(),
            const ListTile(leading: Icon(Icons.privacy_tip), title: Text("Privacy & Policy"), subtitle: Text("Your data is safe and encrypted")),
            const ListTile(leading: Icon(Icons.description), title: Text("Terms of Use"), subtitle: Text("By using this app, you agree to our terms")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFD9CDBF),
      appBar: AppBar(
        title: const Text("About PDF Editor App"),
        centerTitle: true,
        backgroundColor: const Color(0xFFD9CDBF),
        foregroundColor: const Color(0xFFF50F10),
        elevation: 0,
      ),
      body: r.isTablet
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: content))
          : content,
    );
  }
}