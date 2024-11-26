import 'package:flutter/material.dart';
import 'package:mynotes_phone/src/text_editor.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:mynotes_phone/src/documents.dart';
import 'package:uuid/uuid.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late PersistentTabController _controller;
  String randomId = Uuid().v4();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens() {
    return [
      const DocumentsPage(),
      TextEditor(id: randomId, key: ValueKey(randomId)),
      const Center(child: Text("Profile Screen")),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: ("Home"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.create_new_folder),
        title: ("New"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person),
        title: ("Profile"),
        activeColorPrimary: Colors.blue,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  void _onNavBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // If you want to rerender the "Home" tab, you can add logic here.
    if (_selectedIndex == 0) {
      setState(() {
        randomId = Uuid().v4();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      navBarStyle: NavBarStyle.style1,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      backgroundColor: Colors.white,
      onItemSelected: _onNavBarItemTapped,
    );
  }
}
