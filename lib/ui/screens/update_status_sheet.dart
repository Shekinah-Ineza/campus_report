import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../state/incident_providers.dart';
import '../widgets/status_chip.dart';

/// Staff-only bottom sheet for changing a report's status with a note.
class UpdateStatusSheet extends ConsumerStatefulWidget {
  const UpdateStatusSheet({super.key, required this.incident});

  final Incident incident;

  @override
  ConsumerState<UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<UpdateStatusSheet> {
  late IncidentStatus _selected = widget.incident.status;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref
        .read(statusUpdateControllerProvider.notifier)
        .updateStatus(widget.incident, _selected, _note.text);
    if (ok && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('Status changed to ${_selected.label}.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(statusUpdateControllerProvider);
    final saving = saveState.isLoading;
    final theme = Theme.of(context);
    final unchanged = _selected == widget.incident.status;

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update status', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.incident.title,
                  style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in IncidentStatus.values)
                    ChoiceChip(
                      avatar: Icon(s.icon, size: 18, color: statusColor(s, theme.colorScheme)),
                      label: Text(s.label),
                      selected: _selected == s,
                      onSelected: saving ? null : (_) => setState(() => _selected = s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                enabled: !saving,
                decoration: const InputDecoration(
                  labelText: 'Note for the reporter (optional)',
                  hintText: 'e.g. Plumber booked for Thursday morning',
                ),
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              // Errors show inside the sheet; a SnackBar would be hidden behind it.
              if (saveState.hasError && !saving) ...[
                Text(friendlyError(saveState.error),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              FilledButton(
                onPressed: saving || unchanged ? null : _save,
                child: saving
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(unchanged ? 'Choose a new status' : 'Save as ${_selected.label}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
