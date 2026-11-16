/// Single source of truth for quiz answers. Ids are stored in the DB and sent
/// to the AI stylist; labels are shown to the client.
class QuizOption {
  const QuizOption(this.id, this.label, [this.hint]);
  final String id;
  final String label;
  final String? hint;
}

class QuizOptions {
  const QuizOptions._();

  static const genders = [
    QuizOption('male', 'Мужской'),
    QuizOption('female', 'Женский'),
  ];

  static const occasions = [
    QuizOption('work', 'Работа и встречи'),
    QuizOption('everyday', 'Каждый день'),
    QuizOption('date', 'Свидание'),
    QuizOption('event', 'Мероприятие'),
    QuizOption('travel', 'Путешествия'),
  ];

  static const styles = [
    QuizOption('classic', 'Классика', 'пиджаки, брюки, лоферы'),
    QuizOption('minimal', 'Минимализм', 'чистые линии, мало деталей'),
    QuizOption('smart', 'Смарт-кэжуал', 'между офисом и выходными'),
    QuizOption('casual', 'Кэжуал', 'джинсы, рубашки, кеды'),
    QuizOption('street', 'Стритвир', 'оверсайз, худи, карго'),
  ];

  static const budgets = [
    QuizOption('60000', 'до 60 000'),
    QuizOption('120000', 'до 120 000'),
    QuizOption('200000', 'до 200 000'),
    QuizOption('1000000', 'Без ограничений'),
  ];

  static const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  static const colors = [
    QuizOption('black', 'Чёрный'),
    QuizOption('white', 'Белый'),
    QuizOption('beige', 'Бежевый'),
    QuizOption('camel', 'Кэмел'),
    QuizOption('grey', 'Серый'),
    QuizOption('blue', 'Синий'),
    QuizOption('khaki', 'Хаки'),
    QuizOption('brown', 'Коричневый'),
  ];

  static String styleLabel(String id) =>
      styles.firstWhere((o) => o.id == id, orElse: () => QuizOption(id, id)).label;
}
