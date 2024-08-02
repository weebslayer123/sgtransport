import 'package:flutter/material.dart';

class MyBottomNavigationBar extends StatefulWidget {
  MyBottomNavigationBar({super.key, required this.selectedIndexNavBar});
  int selectedIndexNavBar;

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  void _onTap(int index) {
    setState(() {
      widget.selectedIndexNavBar = index;
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/bus');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/train');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/taxi');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/expressway');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/faulty_traffic');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF2B2B2C),
      items: const [
        BottomNavigationBarItem(
          label: 'Bus',
          icon: Icon(Icons.directions_bus),
        ),
        BottomNavigationBarItem(
          label: 'Train',
          icon: Icon(Icons.directions_train),
        ),
        BottomNavigationBarItem(
          label: 'Taxi',
          icon: Icon(Icons.directions_car),
        ),
        BottomNavigationBarItem(
          label: 'ExpressWay',
          icon: Icon(Icons.map),
        ),
        BottomNavigationBarItem(
          label: 'Traffic',
          icon: Icon(Icons.traffic),
        ),
      ],
      currentIndex: widget.selectedIndexNavBar,
      onTap: _onTap,
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.black,
      selectedLabelStyle: const TextStyle(color: Colors.white),
      unselectedLabelStyle: const TextStyle(color: Colors.white),
      showUnselectedLabels: true,
    );
  }
}
