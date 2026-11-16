import 'package:material_ui/material_ui.dart';

import '../config/brand.dart';
import '../theme/app_colors.dart';

class StylistAvatar extends StatelessWidget {
  const StylistAvatar({super.key, this.radius = 28});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = Brand.stylistName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.camel,
      child: Text(initials,
          style: TextStyle(
              color: AppColors.paper,
              fontWeight: FontWeight.w600,
              fontSize: radius * 0.7)),
    );
  }
}
