import 'dart:async';
import 'dart:io';

import '../../models/realisation.dart';
import '../api/api_exception.dart';

class StorageService {
  const StorageService();

  static const int _maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

  Future<String> uploadMedia({
    required File file,
    required RealisationMediaType mediaType,
  }) async {
    if (!await file.exists()) {
      throw const ApiException('Le fichier selectionne est introuvable.');
    }

    final length = await file.length();
    if (length > _maxFileSizeBytes) {
      throw const ApiException('Le fichier est trop volumineux (maximum 25MB).');
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));

    final extension = mediaType == RealisationMediaType.video ? 'mp4' : 'jpg';
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : 'media_${DateTime.now().millisecondsSinceEpoch}.$extension';

    return 'https://cdn.artisans-connect.dev/realisations/$fileName';
  }
}
