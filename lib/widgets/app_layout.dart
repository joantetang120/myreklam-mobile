import 'package:flutter/material.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart';

class AppLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Function(int) onTabTapped;

  const AppLayout({
    super.key,
    required this.body,
    required this.onTabTapped,
    this.currentIndex = 0,
    this.appBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      appBar: appBar,
      body: body,
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
      ),
    );
  }
}
