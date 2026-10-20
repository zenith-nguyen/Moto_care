import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Track nhỏ theo ảnh tham chiếu, với vùng chạm 48 logical pixels.
class RevoSwitch extends StatelessWidget {
  const RevoSwitch(
      {super.key, required this.value, required this.onChanged, this.label});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        toggled: value,
        enabled: onChanged != null,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 40,
                  height: 24,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      color: value ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(20)),
                  child: AnimatedAlign(
                      duration: const Duration(milliseconds: 160),
                      alignment:
                          value ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle))),
                ),
              )),
        ),
      );
}
