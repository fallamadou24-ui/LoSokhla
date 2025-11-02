import 'package:flutter/material.dart';

import '../models/artisan.dart';
import '../routes/app_routes.dart';
import '../services/api/artisan_api_service.dart';
import '../widgets/artisan_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'artisan_detail_screen.dart';

class ArtisanListScreenArgs {
  const ArtisanListScreenArgs({this.metier, this.ville});

  final String? metier;
  final String? ville;
}

class ArtisanListScreen extends StatefulWidget {
  const ArtisanListScreen({super.key});

  @override
  State<ArtisanListScreen> createState() => _ArtisanListScreenState();
}

class _ArtisanListScreenState extends State<ArtisanListScreen> {
  final ArtisanApiService _artisanApiService = const ArtisanApiService();
  Future<List<Artisan>>? _futureArtisans;
  ArtisanListScreenArgs? _args;
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is ArtisanListScreenArgs) {
      _args = arguments;
    }

    _futureArtisans = _loadArtisans();
    _didLoad = true;
  }

  Future<List<Artisan>> _loadArtisans() {
    return _artisanApiService.fetchArtisans(
      metier: _args?.metier,
      ville: _args?.ville,
    );
  }

  Future<void> _refresh() async {
    final future = _loadArtisans();
    setState(() {
      _futureArtisans = future;
    });
    await future.then((_) {}, onError: (_) {});
  }

  void _openDetails(Artisan artisan) {
    Navigator.of(context).pushNamed(
      AppRoutes.artisanDetail,
      arguments: ArtisanDetailScreenArgs(artisan: artisan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleBuffer = StringBuffer('Artisans');
    if (_args?.metier != null) {
      titleBuffer.write(' - ${_args!.metier}');
    }
    if (_args?.ville != null) {
      titleBuffer.write(' (${_args!.ville})');
    }

    return Scaffold(
      appBar: AppBar(title: Text(titleBuffer.toString())),
      body: FutureBuilder<List<Artisan>>(
        future: _futureArtisans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de charger les artisans pour le moment.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            );
          }

          final artisans = snapshot.data ?? const <Artisan>[];
          if (artisans.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Aucun artisan trouve',
                    message:
                        'Ajustez vos criteres de recherche ou reessayez plus tard.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final artisan = artisans[index];
                return ArtisanCard(
                  artisan: artisan,
                  onTap: () => _openDetails(artisan),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: artisans.length,
            ),
          );
        },
      ),
    );
  }
}
