import 'package:flutter/material.dart';
import '../../screens/menu_screen.dart';
import '../../utils/ui_color_utils.dart';

// App bar for the home screen
class HomeAppBar extends StatelessWidget {
  static const double height = 56.0; // Standard AppBar height (kToolbarHeight)

  final Color bgColor;

  const HomeAppBar({
    super.key,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.star_border,
              color: getTextColor(bgColor),
            ),
            onPressed: () {
              // TODO: Implement star functionality
            },
          ),
          Text(
            'Palletator',
            style: TextStyle(
              color: getTextColor(bgColor),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Hero(
            tag: 'menuButton',
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: getTextColor(bgColor),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const MenuScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0); // Start from right
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
