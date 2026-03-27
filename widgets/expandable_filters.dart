import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExpandableFilters extends StatefulWidget {
  final Widget child;
  final String title;

  const ExpandableFilters({
    super.key,
    required this.child,
    this.title = 'Filtros',
  });

  @override
  State<ExpandableFilters> createState() => _ExpandableFiltersState();
}

class _ExpandableFiltersState extends State<ExpandableFilters>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: _toggleExpansion,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : AppTheme.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.darkGray,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white70 : AppTheme.gray,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          child: Container(
            padding: const EdgeInsets.only(top: 12),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

