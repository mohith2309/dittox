import 'package:flutter/material.dart';

import '../../utils/app_optimizations.dart';
import '../../utils/color_pallets.dart';
import '../../utils/favorite_stores_store.dart';
import '../../widgets/common/pill_appbar_title.dart';

class FavoritesScreen extends StatefulWidget {
  static const routeName = '/favorites';

  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FavoriteStore> _favorites = const <FavoriteStore>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favorites = await FavoriteStoresStore.load();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _loading = false;
    });
  }

  Future<void> _remove(String id) async {
    await FavoriteStoresStore.remove(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Favorites',
          icon: Icons.favorite_rounded,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Icon(Icons.favorite_border_rounded,
                          size: 72, color: ColorPallets.textSecondary),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No favorite stores yet',
                          style: TextStyle(
                            color: ColorPallets.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : EfficientListView(
                    // Performance: Uses EfficientListView for optimized list rendering
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final store = _favorites[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.storefront_rounded,
                              color: ColorPallets.deepBlue),
                          title: Text(store.name),
                          subtitle: store.address.isEmpty
                              ? null
                              : Text(store.address),
                          trailing: IconButton(
                            tooltip: 'Remove favorite',
                            onPressed: () => _remove(store.id),
                            icon: const Icon(Icons.favorite_rounded,
                                color: ColorPallets.deepBlue),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
