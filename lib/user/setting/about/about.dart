import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9CDBF),

      appBar: AppBar(
        title: const Text("About PDF Editor App"),
        centerTitle: true,
        backgroundColor: const Color(0xFFD9CDBF),
        foregroundColor: const Color(0xFFF50F10),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              const SizedBox(height: 20),

              /// APP ICON
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.red.shade100,
                child: const Icon(
                  Icons.picture_as_pdf,
                  size: 55,
                  color: Color(0xFFF50F10),
                ),
              ),

              const SizedBox(height: 20),

              /// APP NAME
              const Text(
                "PDF Editor App",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              /// VERSION
              const Text(
                "Version 1.0.8",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 20),

              /// DESCRIPTION
              const Text(
                "PDF Editor App is a powerful and easy-to-use tool designed to manage all your PDF needs in one place. "
                    "You can view, edit, convert, merge, split, and organize PDF files directly from your mobile device without any hassle.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 25),

              /// FEATURES BOX
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [

                    Text(
                      "Key Features",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text("• View PDF files with smooth performance"),
                    Text("• Edit and modify PDF documents easily"),
                    Text("• Merge multiple PDFs into one file"),
                    Text("• Split large PDF files"),
                    Text("• Convert images to PDF"),
                    Text("• Fast and lightweight performance"),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Divider(),

              /// DEVELOPER INFO
              const ListTile(
                leading: Icon(Icons.code),
                title: Text("Developer"),
                subtitle: Text("PDF Editor App Team"),
              ),

              const Divider(),

              /// SUPPORT INFO
              const ListTile(
                leading: Icon(Icons.email),
                title: Text("Support"),
                subtitle: Text("support@pdfeditorapp.com"),
              ),

              const Divider(),

              /// LEGAL INFO
              const ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text("Privacy & Policy"),
                subtitle: Text("Your data is safe and encrypted"),
              ),

              const ListTile(
                leading: Icon(Icons.description),
                title: Text("Terms of Use"),
                subtitle: Text("By using this app, you agree to our terms"),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}