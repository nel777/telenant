import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telenant/authentication/login.dart';
import 'package:telenant/home/admin/landingpage.dart';
import 'package:telenant/home/homepage.dart';
import 'package:telenant/home/transients_list.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loggedIn = false;
  String email = '';
  @override
  void initState() {
    fetchData();
    super.initState();
  }

  void fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString('userEmail'));
    if (prefs.getString('userEmail') != null) {
      setState(() {
        loggedIn = true;
        email = prefs.getString('userEmail').toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: FlexThemeData.light(
        colors: const FlexSchemeColor(
          // Custom colors
          primary: Color(0xFFF29F58),
          primaryContainer: Color(0xFFD0E4FF),
          primaryLightRef: Color(0xFFF29F58),
          secondary: Color(0xFFAB4459),
          secondaryContainer: Color(0xFFFFDBCF),
          secondaryLightRef: Color(0xFFAB4459),
          tertiary: Color(0xFF441752),
          tertiaryContainer: Color(0xFF95F0FF),
          tertiaryLightRef: Color(0xFF441752),
          appBarColor: Color(0xFFFFDBCF),
          error: Color(0xFFBA1A1A),
          errorContainer: Color(0xFFFFDAD6),
        ),
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        textTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      darkTheme: FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xFF9FC9FF),
          primaryContainer: Color(0xFF00325B),
          primaryLightRef: Color(0xFFF29F58),
          secondary: Color(0xFFFFB59D),
          secondaryContainer: Color(0xFF872100),
          secondaryLightRef: Color(0xFFAB4459),
          tertiary: Color(0xFF86D2E1),
          tertiaryContainer: Color(0xFF004E59),
          tertiaryLightRef: Color(0xFF441752),
          appBarColor: Color(0xFFFFDBCF),
          error: Color(0xFFFFB4AB),
          errorContainer: Color(0xFF93000A),
        ),
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnColors: true,
          useM2StyleDividerInM3: true,
          inputDecoratorIsFilled: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          alignedDropdown: true,
          navigationRailUseIndicator: true,
          navigationRailLabelType: NavigationRailLabelType.all,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        textTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      home: loggedIn
          ? email.contains('telenant.admin.com')
              ? const AdminHomeView()
              : const HomePage()
          : const LoginPage(),
    );
  }
}
