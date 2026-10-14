import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/search_service.dart';
import '../models/faq_question.dart';
import '../data/demo_faq_questions.dart';

final faqQuestionsProvider = Provider<List<FaqQuestion>>(
  (ref) => demoFaqQuestions,
);
final filteredFaqProvider = Provider.autoDispose
    .family<List<FaqQuestion>, (String, String?)>(
      (ref, selection) => List.unmodifiable(
        ref
            .watch(faqQuestionsProvider)
            .where(
              (question) =>
                  (selection.$2 == null || question.$1 == selection.$2) &&
                  normalizeServiceSearch('${question.$2} ${question.$3}')
                      .contains(normalizeServiceSearch(selection.$1)),
            ),
      ),
    );
