import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors.dart';
import '../../core/validators.dart';
import '../../models/incident_enums.dart';
import '../../state/incident_providers.dart';

/// Form for submitting a new incident report, with an optional photo.
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  // Local, screen-only UI state: setState is the right tool here.
  IncidentCategory? _category;
  bool _categoryMissing = false;
  File? _image;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70, // Smaller uploads on mobile data.
        maxWidth: 1600,
      );
      if (picked != null) setState(() => _image = File(picked.path));
    } catch (_) {
      _snack('Couldn\'t open the ${source == ImageSource.camera ? 'camera' : 'gallery'}. '
          'Check the app\'s permissions in Settings.');
    }
  }

  void _choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState!.validate();
    setState(() => _categoryMissing = _category == null);
    if (!formValid || _category == null) return;

    final ok = await ref.read(reportFormControllerProvider.notifier).submit(
          title: _title.text,
          description: _description.text,
          category: _category!,
          location: _location.text,
          image: _image,
        );
    if (ok && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Report submitted. Follow its progress under "My reports".'),
      ));
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(reportFormControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) _snack(friendlyError(next.error));
    });
    final submitting = ref.watch(reportFormControllerProvider).isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report a problem')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('What kind of problem is it?', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in IncidentCategory.values)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 18),
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: submitting
                          ? null
                          : (_) => setState(() {
                                _category = c;
                                _categoryMissing = false;
                              }),
                    ),
                ],
              ),
              if (_categoryMissing)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text('Choose a category',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                enabled: !submitting,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. No water in Block C toilets',
                ),
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Validators.title,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _location,
                enabled: !submitting,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Library, 2nd floor, room 204',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Validators.location,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                enabled: !submitting,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What happened, since when, and how it affects people',
                  alignLabelWithHint: true,
                ),
                minLines: 4,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.description,
              ),
              const SizedBox(height: 16),
              Text('Photo (optional)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_image == null)
                OutlinedButton.icon(
                  onPressed: submitting ? null : _choosePhotoSource,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add a photo'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        tooltip: 'Remove photo',
                        onPressed: submitting ? null : () => setState(() => _image = null),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: submitting ? null : _submit,
                icon: submitting
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(submitting ? 'Submitting…' : 'Submit report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
