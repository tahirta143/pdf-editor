import 'package:flutter/material.dart';
import 'package:pdfeditorapp/user/setting/about/about.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';
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
    final r = ResponsiveHelper.of(context);
    final hPad = r.wp(4);
    final isWide = r.isTablet;

    Widget content = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(hPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Save location", style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  height: r.scale(40),
                  width: r.wp(85),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: isDocumentSelected ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.45,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.deepPurple, borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isDocumentSelected = false),
                              child: Center(
                                child: Text("Download", style: TextStyle(color: !isDocumentSelected ? Colors.white : const Color(0xFFD681F0), fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isDocumentSelected = true),
                              child: Center(
                                child: Text("Document", style: TextStyle(color: isDocumentSelected ? Colors.white : const Color(0xFFD681F0), fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Storage", style: TextStyle(fontSize: r.sp(15), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.storage, color: Colors.blue)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Cache Size", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("612.80 KB", style: TextStyle(fontSize: r.sp(12))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Clear temporary files, image cache, and PDF processing cache.", style: TextStyle(fontSize: r.sp(12))),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.delete_outline), label: const Text("Clear Cache")),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildListTile(r, Icons.privacy_tip, "Privacy Policy", "Learn how your data is used.", onTap: () => _openUrl(privacyUrl)),
            _buildDivider(),
            _buildListTile(r, Icons.description, "Terms & Conditions", "Read app terms and conditions.", onTap: () => _openUrl(termsUrl)),
            _buildDivider(),
            _buildListTile(r, Icons.star, "Rate this app", "Open Play Store to rate app.", onTap: () => _openUrl(playStoreUrl)),
            _buildDivider(),
            _buildListTile(r, Icons.info, "About PDF Guru", "Version 1.0.8 • App information", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const About()));
            }),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFD9CDBF),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        elevation: 0,
        centerTitle: true,
        title: Text("PDF Editor App", style: TextStyle(color: const Color(0xFFF50F10), fontWeight: FontWeight.bold, fontSize: r.sp(20))),
      ),
      body: isWide
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: content))
          : content,
    );
  }

  Widget _buildListTile(ResponsiveHelper r, IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: Icon(icon, color: Colors.black)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: r.sp(12))),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey.shade400);
  }
}