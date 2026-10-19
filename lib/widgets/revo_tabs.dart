import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RevoTabs extends StatelessWidget {
  const RevoTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  selected: selected == i,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected == i
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: appText(
                          12,
                          weight:
                              selected == i ? FontWeight.w600 : FontWeight.w500,
                          color:
                              selected == i ? Colors.white : AppColors.textSub,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
