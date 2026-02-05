import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resizable_container/home_page.dart';
import 'providers/tile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/grid_state_provider.dart';
import 'providers/navigation_provider.dart';

void main() {
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

