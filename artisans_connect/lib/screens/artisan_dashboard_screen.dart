import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class ArtisanDashboardScreen extends StatelessWidget {
  const ArtisanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord artisan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue sur votre espace artisan.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Publiez vos realisations, repondez aux clients et mettez a jour votre profil.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.myRealisations),
              icon: const Icon(Icons.collections_outlined),
              label: const Text('Gerer mes realisations'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.messaging),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Consulter la messagerie'),
            ),
          ],
        ),
      ),
    );
  }
}
