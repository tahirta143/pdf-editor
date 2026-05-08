import 'package:flutter/material.dart';
import 'package:pdfeditorapp/user/setting/about/about.dart';
import 'package:url_launcher/url_launcher.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool isDocumentSelected = true;

  final Uri privacyUrl =
  Uri.parse("https://pdfguru.pro/policy");

  final Uri termsUrl =
  Uri.parse("https://pdfguru.pro/terms");

  final Uri playStoreUrl = Uri.parse(
      "https://play.google.com/store/apps/details?id=maker.ilove.sedja.pdf.guru.pro");

  Future<void> _openUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not launch $url";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9CDBF),

      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PDF Editor App",
          style: TextStyle(
            color: Color(0xFFF50F10),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Save location",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Center(
                child: Container(
                  height: 40,
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [

                      /// ANIMATED PURPLE SLIDER
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: isDocumentSelected
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.45,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),

                      /// BUTTON ROW
                      Row(
                        children: [

                          /// DOWNLOAD
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isDocumentSelected = false;
                                });
                              },
                              child: Center(
                                child: Text(
                                  "Download",
                                  style: TextStyle(
                                    color: !isDocumentSelected
                                        ? Colors.white
                                        : Color(0xFFD681F0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          /// DOCUMENT
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isDocumentSelected = true;
                                });
                              },
                              child: Center(
                                child: Text(
                                  "Document",
                                  style: TextStyle(
                                    color: isDocumentSelected
                                        ? Colors.white
                                        : Color(0xFFD681F0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Storage",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.storage, color: Colors.blue),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cache Size",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("612.80 KB"),
                          ],
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Clear temporary files, image cache, and PDF processing cache.",
                      style: TextStyle(fontSize: 12),
                    ),

                    const SizedBox(height: 15),

                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Clear Cache"),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildListTile(
                Icons.privacy_tip,
                "Privacy Policy",
                "Learn how your data is used.",
                onTap: () => _openUrl(privacyUrl),
              ),

              _buildDivider(),

              _buildListTile(
                Icons.description,
                "Terms & Conditions",
                "Read app terms and conditions.",
                onTap: () => _openUrl(termsUrl),
              ),

              _buildDivider(),

              _buildListTile(
                Icons.star,
                "Rate this app",
                "Open Play Store to rate app.",
                onTap: () => _openUrl(playStoreUrl),
              ),

              _buildDivider(),

              _buildListTile(
                Icons.info,
                "About PDF Guru",
                "Version 1.0.8 • App information",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => About()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildListTile(
      IconData icon,
      String title,
      String subtitle, {
        required VoidCallback onTap,
      }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade200,
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade400);
  }
}