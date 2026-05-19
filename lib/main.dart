import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:mie_project/screen/novel_title.dart';
// import 'package:mie_project/screen/read_novel.dart';
//import 'package:mie_project/admin/noveldetailpage.dart';
import 'package:mie_project/screen/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:mie_project/screen/login.dart';
//import 'package:mie_project/screen/ai_recommend.dart';
import 'package:mie_project/services/db_helper.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  await DBHelper.initDb();

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mie Project',
      theme: ThemeData(textTheme: GoogleFonts.sarabunTextTheme()),
      home: SplashScreen(),
    );
  }
}
