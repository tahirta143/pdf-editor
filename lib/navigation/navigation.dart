import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:pdfeditorapp/user/home/home.dart';
import 'package:pdfeditorapp/user/setting/setting.dart';
import 'package:pdfeditorapp/utils/responsive_helper.dart';

class Navigationbar extends StatefulWidget {
  const Navigationbar({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<Navigationbar> {
  int _selectedIndex = 0;
  late PageController _pageController;

  static final List<Widget> _widgetOptions = <Widget>[
    Home(),
    Setting(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final navHeight = r.hp(8).clamp(56.0, 80.0);
    final iconSize = r.scale(28);
    final labelFontSize = r.sp(11);

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _widgetOptions,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.white,
        buttonBackgroundColor: const Color(0xFFF50F10),
        height: navHeight,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        index: _selectedIndex,
        items: <Widget>[
          _buildNavItem(Icons.home, 'Home', 0, iconSize, labelFontSize),
          _buildNavItem(Icons.person, 'Setting', 1, iconSize, labelFontSize),
        ],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, double iconSize, double labelFontSize) {
    final isSelected = _selectedIndex == index;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: isSelected ? Colors.white : Colors.black),
        if (!isSelected)
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
      ],
    );
  }
}
