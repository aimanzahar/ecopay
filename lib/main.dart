import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'services/language_service.dart';
import 'screens/touch_n_go_homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize language service
  final languageService = LanguageService();
  await languageService.initialize();
  
  runApp(MyApp(languageService: languageService));
}

class MyApp extends StatelessWidget {
  final LanguageService languageService;
  
  const MyApp({super.key, required this.languageService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: languageService,
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'EcoPay',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageService.supportedLocales,
            locale: languageService.currentLocale,
            home: const TouchNGoHomepage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
