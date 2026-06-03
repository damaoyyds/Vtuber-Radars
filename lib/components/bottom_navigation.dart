import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.radar),
          label: '我的雷达',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: '发现',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: '消息',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '我的',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF8B5CF6),
      unselectedItemColor: Colors.grey,
      onTap: onTap,
      backgroundColor: Colors.white,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    );
  }
}