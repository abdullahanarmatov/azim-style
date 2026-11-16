import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stylist_ai_repository.dart';
import '../domain/style_profile.dart';

final quizProvider = NotifierProvider<QuizController, StyleProfile>(QuizController.new);

class QuizController extends Notifier<StyleProfile> {
  @override
  StyleProfile build() => const StyleProfile();

  void setGender(String v) => state = state.copyWith(gender: v);
  void toggleOccasion(String v) => state = state.copyWith(occasions: _toggle(state.occasions, v));
  void toggleStyle(String v) => state = state.copyWith(styles: _toggle(state.styles, v));
  void toggleColor(String v) => state = state.copyWith(colors: _toggle(state.colors, v));
  void setBudget(int v) => state = state.copyWith(budget: v);
  void setSize(String v) => state = state.copyWith(topSize: v);
  void setNotes(String v) => state = state.copyWith(notes: v);
  void reset() => state = const StyleProfile();

  static Set<String> _toggle(Set<String> set, String v) =>
      set.contains(v) ? ({...set}..remove(v)) : {...set, v};
}

final recommendationProvider = FutureProvider.autoDispose<Recommendation>(
  (ref) => ref.watch(stylistAiRepositoryProvider).recommend(ref.read(quizProvider)),
);
