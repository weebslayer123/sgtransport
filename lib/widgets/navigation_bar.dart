import 'package:flutter/material.dart';

class MyBottomNavigationBar extends StatefulWidget {
  MyBottomNavigationBar({super.key, required this.selectedIndexNavBar});
  int selectedIndexNavBar;

  @override
  State<MyBottomNavigationBar> createState() => _MyBottomNavigationBarState();
}

class _MyBottomNavigationBarState extends State<MyBottomNavigationBar> {
  void _onTap(int index) {
    widget.selectedIndexNavBar = index;
    setState(() {
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
      backgroundColor: Color(0xFF2B2B2C),
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
          label: 'Traffic Light',
          icon: Icon(Icons.traffic),
        ),
      ],
      currentIndex: widget.selectedIndexNavBar,
      onTap: _onTap,
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.black,
      selectedLabelStyle: TextStyle(color: Colors.white),
      unselectedLabelStyle: TextStyle(color: Colors.white),
      showUnselectedLabels: true,
    );
  }
}
