import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/tile_data.dart';
import 'widgets/tile_grid.dart';
import 'screens/sub_menu_screen.dart';
import 'providers/tile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/grid_state_provider.dart';
import 'providers/navigation_provider.dart';
import 'utils/responsive_utils.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Resizable Tiles',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TileProvider>().loadTiles();
      }
    });
  }

  void _handleTileTap(TileData tile) {
    final tileProvider = context.read<TileProvider>();
    final navigationProvider = context.read<NavigationProvider>();
    final children = tileProvider.getChildTiles(tile.id);
    if (children.isNotEmpty) {
      navigationProvider.navigateToTile(tile.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SubMenuScreen(title: tile.title, parentId: tile.id),
        ),
      ).then((_) {
        navigationProvider.navigateBack();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileProvider = context.watch<TileProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resizable Tiles',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tileProvider.refreshTiles(),
            tooltip: 'Reload tiles',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final maxContentWidth = ResponsiveUtils.getMaxContentWidth(
              screenWidth,
            );
            final targetWidth = screenWidth > maxContentWidth
                ? maxContentWidth
                : screenWidth;
            return Center(
              child: SizedBox(
                width: targetWidth,
                child: Consumer<TileProvider>(
                  builder: (context, tileProvider, child) {
                    if (tileProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (tileProvider.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tileProvider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => tileProvider.refreshTiles(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: TileGrid(onTileTap: _handleTileTap),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
