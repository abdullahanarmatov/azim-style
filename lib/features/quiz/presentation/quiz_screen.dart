import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/quiz_options.dart';
import '../domain/style_profile.dart';
import 'quiz_providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  static const _titles = [
    'Для кого подбираем?',
    'Куда будете носить?',
    'Какой стиль ближе?',
    'Бюджет на весь образ',
    'Размер и любимые цвета',
    'Что ещё важно знать?',
  ];
  static const _hints = [
    null,
    'Можно выбрать несколько',
    'Можно выбрать несколько',
    'Подберём вещи так, чтобы образ уложился в сумму',
    'Цвета — по желанию',
    'Рост, фигура, вещи, которые уже есть — по желанию',
  ];

  var _step = 0;
  late final _notes = TextEditingController(text: ref.read(quizProvider).notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  bool _canProceed(StyleProfile p) => switch (_step) {
        0 => p.gender != null,
        1 => p.occasions.isNotEmpty,
        2 => p.styles.isNotEmpty,
        3 => p.budget != null,
        4 => p.topSize != null,
        _ => true,
      };

  void _next() {
    if (_step < _titles.length - 1) {
      setState(() => _step++);
    } else {
      ref.read(quizProvider.notifier).setNotes(_notes.text.trim());
      context.push('/quiz/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(quizProvider);
    // "Пройти заново" on the result screen resets the profile and pops back.
    ref.listen(quizProvider, (_, next) {
      if (next.gender == null && _step != 0) {
        _notes.clear();
        setState(() => _step = 0);
      }
    });
    final quiz = ref.read(quizProvider.notifier);
    final theme = Theme.of(context);
    final last = _step == _titles.length - 1;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Шаг ${_step + 1} из ${_titles.length}'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (_step + 1) / _titles.length),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: ListView(
            key: ValueKey(_step),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Text(_titles[_step], style: theme.textTheme.headlineMedium),
              if (_hints[_step] != null) ...[
                const SizedBox(height: 8),
                Text(_hints[_step]!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 24),
              ...switch (_step) {
                0 => _options(QuizOptions.genders, (o) => profile.gender == o.id,
                    (o) => quiz.setGender(o.id)),
                1 => _options(QuizOptions.occasions,
                    (o) => profile.occasions.contains(o.id), (o) => quiz.toggleOccasion(o.id)),
                2 => _options(QuizOptions.styles, (o) => profile.styles.contains(o.id),
                    (o) => quiz.toggleStyle(o.id)),
                3 => _options(QuizOptions.budgets,
                    (o) => profile.budget == int.parse(o.id), (o) => quiz.setBudget(int.parse(o.id))),
                4 => [
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final s in QuizOptions.sizes)
                        ChoiceChip(
                          label: Text(s),
                          selected: profile.topSize == s,
                          onSelected: (_) => quiz.setSize(s),
                        ),
                    ]),
                    const SizedBox(height: 24),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in QuizOptions.colors)
                        FilterChip(
                          label: Text(c.label),
                          selected: profile.colors.contains(c.id),
                          onSelected: (_) => quiz.toggleColor(c.id),
                        ),
                    ]),
                  ],
                _ => [
                    TextField(
                      controller: _notes,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                          hintText: 'Например: рост 182, не люблю узкие джинсы'),
                    ),
                  ],
              },
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              onPressed: _canProceed(profile) ? _next : null,
              child: Text(last ? 'Показать образы' : 'Далее'),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _options(List<QuizOption> options, bool Function(QuizOption) selected,
          void Function(QuizOption) onTap) =>
      [
        for (final o in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(option: o, selected: selected(o), onTap: () => onTap(o)),
          ),
      ];
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, required this.selected, required this.onTap});
  final QuizOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.secondary.withValues(alpha: 0.14) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: selected ? scheme.secondary : scheme.outlineVariant,
            width: selected ? 1.5 : 1),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
        title: Text(option.label),
        subtitle: option.hint == null ? null : Text(option.hint!),
        trailing: Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          color: selected ? scheme.secondary : scheme.outline,
        ),
      ),
    );
  }
}
