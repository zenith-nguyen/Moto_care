import 'package:flutter/material.dart';

import '../theme/service_rating_theme.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.selectedStars,
    required this.onChanged,
  });
  final int selectedStars;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đánh giá $selectedStars trên 5 sao',
    child: Row(
      children: [
        for (var star = 1; star <= 5; star++)
          Expanded(
            child: Semantics(
              selected: selectedStars == star,
              child: IconButton(
                key: ValueKey('service-rating-star-$star'),
                tooltip: 'Đánh giá $star sao',
                onPressed: onChanged == null ? null : () => onChanged!(star),
                padding: const EdgeInsets.symmetric(vertical: 6),
                iconSize: 36,
                icon: Icon(
                  selectedStars >= star
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: selectedStars >= star
                      ? ServiceRatingColors.red
                      : const Color(0xFFD5D8DE),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
