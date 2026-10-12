import 'package:flutter/material.dart';

import '../models/home_destination.dart';
import '../theme/home_theme.dart';
import '../theme/revo_home_theme.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.selectedDestination,
    required this.onSelected,
    this.backgroundColor = HomeColors.surface,
    this.selectedIconColor = HomeColors.primary,
    this.selectedBackgroundColor = HomeColors.selected,
    this.unselectedIconColor = HomeColors.secondary,
    this.light = true,
    this.floatingSelectedColor = RevoHomeColors.navigationSelected,
    this.floatingSelectedBackgroundColor =
        RevoHomeColors.navigationSelectedBackground,
  });

  final HomeDestination selectedDestination;
  final ValueChanged<HomeDestination> onSelected;
  final Color backgroundColor;
  final Color selectedIconColor;
  final Color selectedBackgroundColor;
  final Color unselectedIconColor;
  final bool light;
  final Color floatingSelectedColor;
  final Color floatingSelectedBackgroundColor;

  @override
  Widget build(BuildContext context) {
    if (light) return _buildFloatingBar(context);
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
                                    ? selectedBackgroundColor
                                    : Colors.transparent,
                              ),
                              child: Icon(
                                destination.icon,
                                color: light
                                    ? destination == selectedDestination
                                          ? selectedIconColor
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

  Widget _buildFloatingBar(BuildContext context) => SafeArea(
    top: false,
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: RevoHomeColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final destination
                        in HomeDestination.homeNavigationItems)
                      Expanded(
                        child: Semantics(
                          selected: destination == selectedDestination,
                          button: true,
                          child: InkWell(
                            onTap: () => onSelected(destination),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 3,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: destination == selectedDestination
                                          ? floatingSelectedBackgroundColor
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      destination.navigationIcon,
                                      size: 21,
                                      color: destination == selectedDestination
                                          ? floatingSelectedColor
                                          : RevoHomeColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    destination.navigationLabel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: destination == selectedDestination
                                          ? floatingSelectedColor
                                          : RevoHomeColors.muted,
                                      fontWeight:
                                          destination == selectedDestination
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
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
          ),
        ),
      ),
    ),
  );
}
