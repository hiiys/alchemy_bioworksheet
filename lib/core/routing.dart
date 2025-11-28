import 'package:flutter/material.dart';

// App routing constants and navigation helpers

class AppRoutes {
  static const String home = '/';
  static const String sampleInfo = '/sample-info';
  static const String sampleList = '/sample-list';
  static const String registration = '/registration';
  static const String analysis = '/analysis';
  static const String export = '/export';
  static const String orderRegistration = '/order-registration';
}

class AppPageTitles {
  static const String home = 'Alchemy Biological Worksheet';
  static const String sampleInfo = 'Client Info';
  static const String sampleList = 'Sample List';
  static const String registration = 'Specimen Registration';
  static const String analysis = 'Macrobenthos Analysis';
  static const String export = 'Export Results';
  static const String orderRegistration = 'Order Registration';
}

// Navigation helper class
class AppNavigation {
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  static void navigateToSampleInfo(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.sampleInfo);
  }

  static void navigateToSampleList(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.sampleList);
  }

  static void navigateToRegistration(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.registration);
  }

  static void navigateToAnalysis(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.analysis);
  }

  static void navigateBack(BuildContext context) {
    Navigator.pop(context);
  }
}
