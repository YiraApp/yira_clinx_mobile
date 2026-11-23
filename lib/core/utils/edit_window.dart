// Prescriptions, medical records and diet plans can be changed for one hour after they are saved;
// after that they are part of the patient's record and stay as written. The server refuses later
// changes with a 403, and the web shows the same rule (Clinicx-Frontend src/lib/edit-window.ts).

const int editWindowMinutes = 60;

class EditWindow {
  const EditWindow({required this.open, required this.minutesLeft, required this.message});

  /// Whether it can still be changed.
  final bool open;

  /// Whole minutes left to change it (0 once closed).
  final int minutesLeft;

  /// What to tell the doctor: "Edit (12 min left)" or why it can't be edited.
  final String message;
}

/// Reads a saved row's creation time from the API, which sends `CreatedAt` or `createdAt`.
DateTime? createdAtOf(Map<String, dynamic>? json) {
  if (json == null) return null;
  final raw = json['CreatedAt'] ?? json['createdAt'] ?? json['created_at'];
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

/// Whether something saved at [createdAt] may still be changed at [now]. An unknown age (old data
/// without a timestamp) stays editable, as on the web and the server.
EditWindow editWindowFor(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) {
    return const EditWindow(open: true, minutesLeft: editWindowMinutes, message: 'Edit');
  }
  final current = now ?? DateTime.now();
  final leftSeconds = editWindowMinutes * 60 - current.difference(createdAt).inSeconds;
  if (leftSeconds <= 0) {
    return const EditWindow(
      open: false,
      minutesLeft: 0,
      message: "Can't edit: changes are allowed only within $editWindowMinutes minutes of saving.",
    );
  }
  final minutes = (leftSeconds / 60).ceil().clamp(1, editWindowMinutes);
  return EditWindow(open: true, minutesLeft: minutes, message: 'Edit ($minutes min left)');
}
