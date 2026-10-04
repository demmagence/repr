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

// KineticBottomNav: Responsive floating pill bottom navigation matching Stitch designs
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        bottom: bottomInset > 0 ? bottomInset : 16.0,
        top: 6.0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(36.0),
          border: Border.all(
            color: const Color(0xFF27272A),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16.0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.grid_view_rounded, 'Workouts'),
            _buildNavItem(1, Icons.fitness_center_rounded, 'Train'),
            _buildNavItem(2, Icons.calendar_today_rounded, 'History'),
            _buildNavItem(3, Icons.show_chart_rounded, 'Metrics'),
            _buildNavItem(4, Icons.settings_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    const activeColor = Colors.white;
    const inactiveColor = Color(0xFF71717A);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
