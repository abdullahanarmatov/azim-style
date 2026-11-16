import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:azim_style/app.dart';
import 'package:azim_style/features/auth/data/auth_repository.dart';
import 'package:azim_style/features/auth/domain/app_user.dart';
import 'package:azim_style/features/catalog/data/catalog_repository.dart';
import 'package:azim_style/features/catalog/data/mock_catalog.dart';
import 'package:azim_style/features/chat/data/chat_repository.dart';

Future<void> setUpTestEnv() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('ru');
}

/// Pumps the whole app on a phone-sized screen with instant mock backends.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  AppUser? signedInAs,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      catalogRepositoryProvider
          .overrideWithValue(MockCatalogRepository(latency: Duration.zero)),
      authRepositoryProvider
          .overrideWithValue(MockAuthRepository(initialUser: signedInAs)),
      chatRepositoryProvider
          .overrideWithValue(MockChatRepository(replyDelay: Duration.zero)),
    ],
    child: const StylistApp(),
  ));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(StylistApp)));
}
