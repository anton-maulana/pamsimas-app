import 'package:pamsimas_app/pamsimas_app.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color? iconColor;

  const FilterButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppPalette.primaryBlue;
    final Color inactiveColor = AppPalette.textGrey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppPalette.bgBluePale : AppPalette.bgGreyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: iconColor ?? (active ? activeColor : inactiveColor),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? activeColor : inactiveColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? activeColor : inactiveColor,
            ),
          ],
        ),
      ),
    );
  }
}