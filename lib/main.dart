import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:resizable_container/home_page.dart';
import 'providers/tile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/grid_state_provider.dart';
import 'providers/navigation_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set initial system UI style (dark icons for light background)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GridStateProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
