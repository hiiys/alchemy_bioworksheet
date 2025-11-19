import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_state.dart';
import 'core/routing.dart';
import 'core/theme.dart';
import 'ui/home/home_page.dart';
import 'ui/sample_info/sample_info_page.dart';
import 'ui/sample_list/sample_list_page.dart';
import 'ui/registration/registration_page.dart';
import 'ui/analysis/analysis_page.dart';
import 'ui/export/export_page.dart';
import 'ui/order/order_registration_page.dart';

class AlchemyBioworksheetApp extends StatelessWidget {
  const AlchemyBioworksheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState()..initialize(),
      child: MaterialApp(
        title: 'Alchemy Bioworksheet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.home,
        routes: {
          AppRoutes.home: (context) => const HomePage(),
          AppRoutes.sampleInfo: (context) => const SampleInfoPage(),
          AppRoutes.sampleList: (context) => const SampleListPage(),
          AppRoutes.registration: (context) => const RegistrationPage(),
          AppRoutes.analysis: (context) => const AnalysisPage(),
          AppRoutes.export: (context) => const ExportPage(),
          AppRoutes.orderRegistration: (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            final type = args?['specimenType'] as String? ?? 'Macrobenthos';
            return OrderRegistrationPage(specimenType: type);
          },
        },
      ),
    );
  }
}
