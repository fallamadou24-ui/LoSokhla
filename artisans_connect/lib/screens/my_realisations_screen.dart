import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/realisation.dart';
import '../services/api/api_exception.dart';
import '../services/api/artisan_api_service.dart';
import '../services/storage/storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';

class MyRealisationsScreenArgs {
  const MyRealisationsScreenArgs({this.artisanId});

  final String? artisanId;
}

class MyRealisationsScreen extends StatefulWidget {
  const MyRealisationsScreen({super.key});

  @override
  State<MyRealisationsScreen> createState() => _MyRealisationsScreenState();
}

class _MyRealisationsScreenState extends State<MyRealisationsScreen> {
  final ArtisanApiService _artisanApiService = ArtisanApiService();

  List<Realisation> _realisations = const [];
  bool _isLoading = false;
  Object? _error;
  bool _initialized = false;
  late String _artisanId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MyRealisationsScreenArgs && args.artisanId != null) {
      _artisanId = args.artisanId!;
    } else {
      _artisanId = 'me';
    }

    _initialized = true;
    _loadRealisations();
  }

  Future<void> _loadRealisations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = _artisanId == 'me'
          ? await _artisanApiService.fetchMyRealisations()
          : await _artisanApiService.fetchRealisations(_artisanId);
      setState(() {
        _realisations = list;
      });
    } on ApiException catch (error) {
      setState(() {
        _error = error;
      });
    } catch (error) {
      setState(() {
        _error = error;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddRealisation() async {
    final created = await showModalBottomSheet<Realisation>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddRealisationSheet(
          artisanId: _artisanId,
          artisanApiService: _artisanApiService,
        ),
      ),
    );

    if (created != null) {
      setState(() {
        _realisations = List<Realisation>.from(_realisations)..insert(0, created);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Realisation ajoutee avec succes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes realisations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddRealisation,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une realisation'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRealisations,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _realisations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(child: LoadingIndicator()),
          ),
        ],
      );
    }

    if (_error != null && _realisations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.error_outline,
            title: 'Impossible de charger vos realisations',
            message: _error.toString(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadRealisations,
            child: const Text('Reessayer'),
          ),
        ],
      );
    }

    if (_realisations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyState(
            icon: Icons.collections_outlined,
            title: 'Aucune realisation',
            message: 'Publiez vos projets pour les mettre en avant aupres des particuliers.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _realisations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _realisations[index];
        return _RealisationCard(realisation: item);
      },
    );
  }
}

class _RealisationCard extends StatelessWidget {
  const _RealisationCard({required this.realisation});

  final Realisation realisation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  realisation.mediaType == RealisationMediaType.video
                      ? Icons.videocam_outlined
                      : Icons.photo_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    realisation.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (realisation.description != null && realisation.description!.isNotEmpty)
              Text(
                realisation.description!,
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                  ),
                  child: realisation.mediaType == RealisationMediaType.video
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_outline, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'Video disponible',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : Image.network(
                          realisation.mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              'Apercu indisponible',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            if (realisation.completedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      realisation.completedAt!.toLocal().toIso8601String(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddRealisationSheet extends StatefulWidget {
  const _AddRealisationSheet({
    required this.artisanId,
    required this.artisanApiService,
  });

  final String artisanId;
  final ArtisanApiService artisanApiService;

  @override
  State<_AddRealisationSheet> createState() => _AddRealisationSheetState();
}

class _AddRealisationSheetState extends State<_AddRealisationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final StorageService _storageService = const StorageService();

  RealisationMediaType _mediaType = RealisationMediaType.photo;
  File? _selectedFile;
  String? _uploadError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nouvelle realisation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RealisationMediaType>(
                value: _mediaType,
                decoration: const InputDecoration(
                  labelText: 'Type de media',
                ),
                items: const [
                  DropdownMenuItem(
                    value: RealisationMediaType.photo,
                    child: Text('Photo'),
                  ),
                  DropdownMenuItem(
                    value: RealisationMediaType.video,
                    child: Text('Video'),
                  ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _mediaType = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_selectedFile != null
                    ? _selectedFile!.path.split('/').last
                    : 'Selectionner un fichier'),
              ),
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _uploadError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_isSubmitting ? 'Publication...' : 'Publier la realisation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _uploadError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: _mediaType == RealisationMediaType.photo
            ? FileType.image
            : FileType.video,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
      });
    } catch (error) {
      setState(() {
        _uploadError = 'Echec de la selection du fichier.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      setState(() {
        _uploadError = 'Veuillez selectionner un fichier.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadError = null;
    });

    try {
      final mediaUrl = await _storageService.uploadMedia(
        file: _selectedFile!,
        mediaType: _mediaType,
      );

      final created = await widget.artisanApiService.createRealisation(
        artisanId: widget.artisanId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        mediaType: _mediaType,
        mediaUrl: mediaUrl,
      );

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ApiException catch (error) {
      setState(() {
        _uploadError = error.message;
      });
    } catch (_) {
      setState(() {
        _uploadError = 'Echec de la publication de la realisation.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
