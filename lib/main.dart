import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/utils/theme/controller/theme_controller.dart';
import 'package:new_flutter_firebase_webrtc/features/video_calling/screen/video_call_page.dart';
import 'package:provider/provider.dart';

import 'features/audio_recorder/provider/audio_recorder_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AudioRecorderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Flutter Firebase WebRTC',
      theme: themeNotifier.themeData,
      home: VideoCallPage(),
    );
  }
}

// {
// "builds": [
// {
// "src": "build/web/**",
// "use": "@vercel/static"
// }
// ],
// "routes": [
// { "src": "/(.*)", "dest": "/index.html" }
// ],
// "headers": [
// {
// "source": "/(.*)",
// "headers": [
// { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
// { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" }
// ]
// }
// ]
// }
