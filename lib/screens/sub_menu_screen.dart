import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tile_provider.dart';
import '../utils/responsive_utils.dart';

class SubMenuScreen extends StatelessWidget {
  final String title;
  final String parentId;
  const SubMenuScreen({super.key, required this.title, required this.parentId});
  @override
  Widget build(BuildContext context) {
    final tileProvider = context.watch<TileProvider>();
    final childTiles = tileProvider.getChildTiles(parentId);
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = ResponsiveUtils.getSubMenuColumns(
              constraints.maxWidth,
            );
            final padding = ResponsiveUtils.getGridPadding(
              constraints.maxWidth,
            );
            if (columns == 1) {
              return ListView.separated(
                padding: EdgeInsets.all(padding),
                itemCount: childTiles.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tile = childTiles[index];
                  return _buildListTile(context, tile);
                },
              );
            } else {
              return GridView.builder(
                padding: EdgeInsets.all(padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: childTiles.length,
                itemBuilder: (context, index) {
                  final tile = childTiles[index];
                  return _buildGridTile(context, tile);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, tile) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: tile.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  tile.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 20),
                ),
              )
            : const Icon(Icons.grid_view, size: 20),
      ),
      title: Text(
        tile.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Selected ${tile.title}')));
      },
    );
  }

  Widget _buildGridTile(BuildContext context, tile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Selected ${tile.title}')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: tile.imageUrl != null
                    ? Image.network(
                        tile.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 48),
                      )
                    : const Icon(Icons.grid_view, size: 48),
              ),
              const SizedBox(height: 12),
              Text(
                tile.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
