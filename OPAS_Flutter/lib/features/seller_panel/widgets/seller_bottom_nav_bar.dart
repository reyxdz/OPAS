import 'package:flutter/material.dart';

class SellerBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final double iconSize;

  const SellerBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.iconSize = 28, // Matching buyer's icon size
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 25,
      // Use 30px side inset so the nav bar lines up visually with the
      // FloatingActionButton in `seller_home_screen.dart` (which uses
      // right: 30). This keeps the floating add button visually aligned
      // with the right edge of the nav card.
      left: 30,
      right: 30,
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              filledIcon: Icons.home,
              isSelected: selectedIndex == 0,
              onTap: () => onTap(0),
              iconSize: iconSize,
            ),
            _NavItem(
              icon: Icons.inventory_2_outlined,
              filledIcon: Icons.inventory_2,
              isSelected: selectedIndex == 1,
              onTap: () => onTap(1),
              iconSize: iconSize,
            ),
            _NavItem(
              icon: Icons.add_box_outlined,
              filledIcon: Icons.add_box,
              isSelected: selectedIndex == 2,
              onTap: () => onTap(2),
              iconSize: iconSize,
            ),
            _NavItem(
              icon: Icons.local_shipping_outlined,
              filledIcon: Icons.local_shipping,
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
              iconSize: iconSize,
            ),
            _NavItem(
              icon: Icons.trending_up_outlined,
              filledIcon: Icons.trending_up,
              isSelected: selectedIndex == 4,
              onTap: () => onTap(4),
              iconSize: iconSize,
            ),
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
