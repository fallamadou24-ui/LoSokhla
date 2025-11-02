import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../api/api_exception.dart';

class AudioService {
  AudioService({Record? recorder}) : _recorder = recorder ?? Record();

  final Record _recorder;
  String? _currentFilePath;

  Future<File> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const ApiException('Permission microphone refusee. Verifiez les reglages de l\'appareil.');
    }

    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(directory.path, 'audio_notes'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final filePath = p.join(audioDir.path, fileName);
    _currentFilePath = filePath;

    await _recorder.start(
      path: filePath,
      encoder: AudioEncoder.aacLc,
      bitRate: 96000,
      samplingRate: 44100,
    );

    return File(filePath);
  }

  Future<File?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) {
      return null;
    }

    _currentFilePath = null;
    return File(path);
  }

  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentFilePath = null;
    }
  }

  Future<String> uploadRecording(File file) async {
    if (!await file.exists()) {
      throw const ApiException('Le fichier audio a envoyer est introuvable.');
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));

    final baseName = p.basename(file.path);
    return 'https://cdn.artisans-connect.dev/audio/$baseName';
  }

  Future<bool> isRecording() {
    return _recorder.isRecording();
  }

  void dispose() {
    _recorder.dispose();
  }
}
