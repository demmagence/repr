import 'package:flutter/material.dart';

// KineticCard: iOS-style container with subtle borders
class KineticCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;

  const KineticCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 24.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// KineticIconButton: Circular icon button with iOS-like press effect
class KineticIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final double size;

  const KineticIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E20), // Slightly lighter than cardBg for buttons
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFF27272A), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: icon),
        ),
      ),
    );
  }
}

// CircularProgressBadge: Custom circular progress painter for the "1" badge
class CircularProgressBadge extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final double size;

  const CircularProgressBadge({
    super.key,
    required this.progress,
    required this.label,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.5,
            backgroundColor: Colors.white12,
            color: Colors.white,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// KineticBottomNav: Custom bottom navigation matching the HTML design
class KineticBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KineticBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(
          top: BorderSide(color: Color(0xFF27272A), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, 'Home'),
              _buildNavItem(1, Icons.bar_chart_rounded, 'Analytics'),
              _buildNavItem(2, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xFF8E8E93),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }
}
