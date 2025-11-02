import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'artisan_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _metierController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();

  @override
  void dispose() {
    _metierController.dispose();
    _villeController.dispose();
    super.dispose();
  }

  void _openSearchResults() {
    final args = ArtisanListScreenArgs(
      metier: _metierController.text.trim().isEmpty
          ? null
          : _metierController.text.trim(),
      ville: _villeController.text.trim().isEmpty
          ? null
          : _villeController.text.trim(),
    );

    Navigator.of(context).pushNamed(
      AppRoutes.artisanList,
      arguments: args,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artisans Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.messaging),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trouvez un artisan pres de chez vous',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _metierController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Metier (ex: Menuisier, Electricien)',
                  prefixIcon: Icon(Icons.handyman_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _villeController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _openSearchResults(),
                decoration: const InputDecoration(
                  labelText: 'Ville ou Code postal',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openSearchResults,
                  icon: const Icon(Icons.search),
                  label: const Text('Rechercher'),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Text(
                    'Consultez les artisans recommandes, leurs realisations et contactez-les en quelques clics.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
