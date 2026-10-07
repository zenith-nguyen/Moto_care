import 'package:flutter/material.dart';

import '../models/home_destination.dart';
import '../theme/home_theme.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.selectedDestination,
    required this.onSelected,
    this.backgroundColor = HomeColors.surface,
    this.selectedIconColor = HomeColors.primary,
    this.unselectedIconColor = HomeColors.secondary,
    this.light = true,
  });

  final HomeDestination selectedDestination;
  final ValueChanged<HomeDestination> onSelected;
  final Color backgroundColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light ? HomeColors.surface : backgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final destination
                  in light
                      ? HomeDestination.homeNavigationItems
                      : HomeDestination.navigationItems)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: destination == selectedDestination,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSelected(destination),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    light && destination == selectedDestination
                                    ? HomeColors.selected
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                destination.icon,
                                color: light
                                    ? destination == selectedDestination
                                          ? HomeColors.primary
                                          : HomeColors.secondary
                                    : destination == selectedDestination
                                    ? selectedIconColor
                                    : unselectedIconColor,
                                size: light ? 24 : 30,
                              ),
                            ),
                            SizedBox(height: light ? 4 : 8),
                            Text(
                              light
                                  ? destination.navigationLabel
                                  : destination.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: light
                                    ? destination == selectedDestination
                                          ? HomeColors.text
                                          : HomeColors.secondary
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: destination == selectedDestination
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            if (!light) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: destination == selectedDestination
                                      ? Colors.white
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
