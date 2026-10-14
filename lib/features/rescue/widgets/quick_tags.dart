import 'package:flutter/material.dart';

import '../models/service_rating.dart';
import '../theme/service_rating_theme.dart';

class QuickTags extends StatelessWidget {
  const QuickTags({
    super.key,
    required this.tags,
    required this.selectedIds,
    required this.onChanged,
  });
  final List<QuickRatingTag> tags;
  final Set<String> selectedIds;
  final void Function(String, bool)? onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final tag in tags)
        FilterChip(
          key: ValueKey('service-rating-tag-${tag.id}'),
          label: Text(tag.label),
          selected: selectedIds.contains(tag.id),
          onSelected: onChanged == null
              ? null
              : (value) => onChanged!(tag.id, value),
          showCheckmark: false,
          selectedColor: ServiceRatingColors.selected,
          backgroundColor: Colors.white,
          shape: const StadiumBorder(),
          side: BorderSide(
            color: selectedIds.contains(tag.id)
                ? ServiceRatingColors.red
                : ServiceRatingColors.border,
          ),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamilyFallback: const ['Apple Color Emoji', 'Noto Color Emoji'],
            color: selectedIds.contains(tag.id)
                ? ServiceRatingColors.red
                : const Color(0xFF555961),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
    ],
  );
}
