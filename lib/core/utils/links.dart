import 'package:url_launcher/url_launcher.dart';

import '../config/brand.dart';

Future<void> openInstagram() =>
    launchUrl(Uri.parse(Brand.instagramUrl), mode: LaunchMode.externalApplication);

Future<void> openWhatsApp([String text = '']) => launchUrl(
      Uri.parse('https://wa.me/${Brand.whatsappPhone}?text=${Uri.encodeComponent(text)}'),
      mode: LaunchMode.externalApplication,
    );
