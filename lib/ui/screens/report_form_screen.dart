import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../models/incident_enums.dart';
import '../../state/incident_providers.dart';
import '../widgets/dashed_box.dart';

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

  String _shortLabel(IncidentCategory c) => switch (c) {
        IncidentCategory.facilities => 'Facilities',
        IncidentCategory.water => 'Water',
        IncidentCategory.electricity => 'Electricity',
        IncidentCategory.furniture => 'Furniture',
        IncidentCategory.sanitation => 'Sanitation',
        IncidentCategory.safety => 'Safety',
        IncidentCategory.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    ref.listen(reportFormControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) _snack(friendlyError(next.error));
    });
    final submitting = ref.watch(reportFormControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const _Label('Select a category'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = (constraints.maxWidth - 20) / 3;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in IncidentCategory.values)
                        _CategoryTile(
                          width: tileWidth,
                          icon: c.icon,
                          label: _shortLabel(c),
                          selected: _category == c,
                          onTap: submitting
                              ? null
                              : () => setState(() {
                                    _category = c;
                                    _categoryMissing = false;
                                  }),
                        ),
                    ],
                  );
                },
              ),
              if (_categoryMissing)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Choose a category',
                    style: TextStyle(color: Color(0xFFC53030), fontSize: 12),
                  ),
                ),
              const SizedBox(height: 18),
              const _Label('Title'),
              TextFormField(
                controller: _title,
                enabled: !submitting,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe the issue...',
                  counterText: '',
                ),
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Validators.title,
              ),
              const SizedBox(height: 16),
              const _Label('Description'),
              TextFormField(
                controller: _description,
                enabled: !submitting,
                decoration: const InputDecoration(
                  hintText: 'Provide more details about the issue...\n'
                      'e.g. what happened, when, impact, etc.',
                  counterText: '',
                ),
                minLines: 4,
                maxLines: 6,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.description,
              ),
              const SizedBox(height: 16),
              const _Label('Location'),
              TextFormField(
                controller: _location,
                enabled: !submitting,
                decoration: const InputDecoration(
                  hintText: 'e.g. Block B, Room 204',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  counterText: '',
                ),
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.location,
              ),
              const SizedBox(height: 16),
              const _Label('Add a photo', optional: true),
              if (_image == null)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: submitting ? null : _choosePhotoSource,
                    child: const DashedBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.muted),
                          SizedBox(height: 6),
                          Text('Tap to add a photo',
                              style: TextStyle(color: AppColors.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
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
              const SizedBox(height: 28),
              FilledButton(
                onPressed: submitting ? null : _submit,
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          children: [
            if (optional)
              const TextSpan(
                text: '  (optional)',
                style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.muted, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    return SizedBox(
      width: width,
      height: 72,
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
