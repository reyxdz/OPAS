import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final double iconSize;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.iconSize = 28, // Adjust icon size here
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 25,
      left: 60, // Adjusting the navbar background
      right: 60, // Adjusting the navbar background
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 30),
            _NavItem(
              icon: Icons.home_outlined,
              filledIcon: Icons.home,
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
              iconSize: iconSize,
            ),
            const SizedBox(width: 40),
            _NavItem(
              icon: Icons.shopping_cart_outlined,
              filledIcon: Icons.shopping_cart,
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
              iconSize: iconSize,
            ),
            const SizedBox(width: 40),
            _NavItem(
              icon: Icons.description_outlined,
              filledIcon: Icons.description,
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
              iconSize: iconSize,
            ),
            const SizedBox(width: 40),
            _NavItem(
              icon: Icons.local_shipping_outlined,
              filledIcon: Icons.local_shipping,
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
              iconSize: iconSize,
            ),
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData filledIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;

  const _NavItem({
    required this.icon,
    required this.filledIcon,
    required this.isSelected,
    required this.onTap,
    this.iconSize = 30,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.isSelected ? widget.filledIcon : widget.icon,
          color: widget.isSelected
              ? const Color(0xFF00B464)
              : const Color(0xFFFAFAFA),
          size: widget.iconSize,
        ),
      ),
    );
  }
}