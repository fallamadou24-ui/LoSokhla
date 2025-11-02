import 'package:flutter/material.dart';

import '../models/realisation.dart';

class RealisationGallery extends StatelessWidget {
  const RealisationGallery({
    super.key,
    required this.realisations,
  });

  final List<Realisation> realisations;

  @override
  Widget build(BuildContext context) {
    if (realisations.isEmpty) {
      return const Text('Aucune realisation publiee pour le moment.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 4 / 3,
      ),
      itemCount: realisations.length,
      itemBuilder: (context, index) {
        final realisation = realisations[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Ink.image(
                image: NetworkImage(realisation.mediaUrl),
                fit: BoxFit.cover,
                child: InkWell(
                  onTap: () {
                    // TODO: ouvrir une visionneuse plein ecran.
                  },
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                right: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          realisation.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (realisation.description != null)
                          Text(
                            realisation.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (realisation.mediaType == RealisationMediaType.video)
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
