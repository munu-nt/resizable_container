import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:resizable_container/providers/navigation_provider.dart';
import 'package:resizable_container/providers/tile_provider.dart';

import 'package:resizable_container/providers/grid_state_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/responsive_utils.dart';

import 'models/tile_data.dart';
import 'widgets/tile_grid.dart';
import 'screens/sub_menu_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TileProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GridStateProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: Consumer<ThemeProvider>(
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
      ),
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    // Theme-aware status bar styling
    // iOS: statusBarBrightness describes the BACKGROUND, not icons
    //      Brightness.light background → dark icons, Brightness.dark background → light icons
    // Android: statusBarIconBrightness directly controls icon color
    final overlayStyle = isDark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.dark, // iOS: dark background → light icons
            statusBarIconBrightness: Brightness.light, // Android: light icons
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light, // iOS: light background → dark icons
            statusBarIconBrightness: Brightness.dark, // Android: dark icons
            systemNavigationBarIconBrightness: Brightness.dark,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Resizable Tiles',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.light
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: themeProvider.themeMode == ThemeMode.light
                      ? 'Switch to dark mode'
                      : 'Switch to light mode',
                );
              },
            ),
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
                        return _buildShimmerLoading(targetWidth, isDark);
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
                      if (tileProvider.displayedTiles.isEmpty) {
                        return _buildEmptyState(isDark);
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
      ),
    );
  }

  // Shimmer loading skeleton (#27)
  Widget _buildShimmerLoading(double width, bool isDark) {
    final columns = ResponsiveUtils.getGridColumns(width);
    final padding = ResponsiveUtils.getGridPadding(width);
    final cellWidth = (width - (padding * 2)) / columns;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            return Container(
              width: cellWidth,
              height: cellWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          },
        ),
      ),
    );
  }

  // Empty state illustration (#28)
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.grey.shade800.withValues(alpha: 0.5)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dashboard_customize_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tiles yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your dashboard is empty.\nAdd some tiles to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.read<TileProvider>().refreshTiles(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reload Tiles'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
