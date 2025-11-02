import 'package:flutter/material.dart';

import '../models/artisan.dart';
import '../services/api/artisan_api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/realisation_gallery.dart';
import '../widgets/rating_badge.dart';
import '../routes/app_routes.dart';

class ArtisanDetailScreenArgs {
  const ArtisanDetailScreenArgs({this.artisan, this.artisanId})
      : assert(artisan != null || artisanId != null,
            'Veuillez fournir un artisan ou un identifiant.');

  final Artisan? artisan;
  final String? artisanId;
}

class ArtisanDetailScreen extends StatefulWidget {
  const ArtisanDetailScreen({super.key});

  @override
  State<ArtisanDetailScreen> createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  final ArtisanApiService _artisanApiService = const ArtisanApiService();
  ArtisanDetailScreenArgs? _args;
  Artisan? _artisan;
  Future<Artisan>? _futureArtisan;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is ArtisanDetailScreenArgs) {
      _args = arguments;
      _artisan = arguments.artisan;

      final targetId = arguments.artisanId ?? _artisan?.id;
      final shouldFetch = targetId != null &&
          (arguments.artisan == null || arguments.artisan!.realisationList.isEmpty);

      if (shouldFetch && targetId != null) {
        final future = _loadArtisan(targetId);
        _futureArtisan = future;
        future.then((value) {
          if (!mounted) return;
          setState(() {
            _artisan = value;
          });
        }, onError: (_) {});
      }
    }

    _initialized = true;
  }

  Future<Artisan> _loadArtisan(String artisanId) {
    return _artisanApiService.fetchArtisanById(artisanId);
  }

  Future<void> _refresh() async {
    final targetId = _args?.artisanId ?? _artisan?.id;
    if (targetId == null) return;
    final future = _loadArtisan(targetId);
    setState(() {
      _futureArtisan = future;
    });
    final artisan = await future;
    if (!mounted) return;
    setState(() {
      _artisan = artisan;
    });
  }

  void _contactArtisan() {
    Navigator.of(context).pushNamed(AppRoutes.messaging);
  }

  @override
  Widget build(BuildContext context) {
    if (_futureArtisan != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_artisan?.fullName ?? 'Artisan')),
        body: FutureBuilder<Artisan>(
          future: _futureArtisan,
          initialData: _artisan,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Impossible de charger le detail de l\'artisan.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Reessayer'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
              return const Center(child: LoadingIndicator());
            }

            final artisan = snapshot.data;
            if (artisan == null) {
              return const Center(
                child: EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'Artisan introuvable',
                  message: 'L\'artisan demande n\'est plus disponible.',
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Stack(
                children: [
                  _ArtisanDetailBody(
                    artisan: artisan,
                    onContactPressed: _contactArtisan,
                    onRefresh: _refresh,
                  ),
                  const Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                  ),
                ],
              );
            }

            return _ArtisanDetailBody(
              artisan: artisan,
              onContactPressed: _contactArtisan,
              onRefresh: _refresh,
            );
          },
        ),
      );
    }

    if (_artisan != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_artisan!.fullName)),
        body: _ArtisanDetailBody(
          artisan: _artisan!,
          onContactPressed: _contactArtisan,
          onRefresh: _refresh,
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Artisan introuvable',
          message: 'Retournez a la liste des artisans et selectionnez un profil.',
        ),
      ),
    );
  }
}

class _ArtisanDetailBody extends StatelessWidget {
  const _ArtisanDetailBody({
    required this.artisan,
    required this.onContactPressed,
    required this.onRefresh,
  });

  final Artisan artisan;
  final VoidCallback onContactPressed;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: artisan.avatarUrl != null
                        ? NetworkImage(artisan.avatarUrl!)
                        : null,
                    child: artisan.avatarUrl == null
                        ? Text(
                            artisan.fullName.isNotEmpty
                                ? artisan.fullName.characters.first.toUpperCase()
                                : '?',
                            style: theme.textTheme.headlineSmall,
                          )
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artisan.fullName,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artisan.metier,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: 4),
                            Text(artisan.ville),
                          ],
                        ),
                        if (artisan.yearsOfExperience != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Chip(
                              avatar: const Icon(Icons.work_outline),
                              label: Text('${artisan.yearsOfExperience} ans d\'experience'),
                            ),
                          ),
                        if (artisan.note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: RatingBadge(value: artisan.note!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onContactPressed,
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Contacter l\'artisan'),
              ),
              const SizedBox(height: 24),
              Text(
                'Presentation',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                artisan.presentation ?? 'Aucune description fournie.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Realisations',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              RealisationGallery(realisations: artisan.realisationList),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
