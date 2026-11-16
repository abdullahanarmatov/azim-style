import 'package:intl/intl.dart';

import '../config/brand.dart';

final _format = NumberFormat.decimalPattern('ru');

/// Formats an integer amount: 24900 -> "24 900 ₸".
String formatMoney(int amount) =>
    '${_format.format(amount)} ${Brand.currencySymbol}';
