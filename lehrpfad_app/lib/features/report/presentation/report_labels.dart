import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../report_copy.dart';

/// Titel einer Meldung in Listen (Spec 8.1).
String reportTitle(ReportDraft d) {
  switch (d.kind) {
    case ReportKind.newTrail:
      final t = d.title?.trim();
      return t == null || t.isEmpty ? rt('report.hub.new') : t;
    case ReportKind.revision:
      return rt('report.title.revision', {'name': d.targetTrailName ?? ''});
    case ReportKind.quick:
      return switch (d.intent) {
        QuickIntent.movePoint => rt('report.title.move'),
        QuickIntent.addPoint => rt('report.title.add'),
        QuickIntent.hint => rt('report.title.hint'),
        _ => rt('report.title.other'),
      };
  }
}

/// Status-Chip: lokaler Zustand, nach dem Upload der Serverstand.
String reportStatusLabel(ReportDraft d) {
  switch (d.status) {
    case DraftStatus.recording:
      return rt('report.status.recording');
    case DraftStatus.paused:
      return rt('report.status.paused');
    case DraftStatus.review:
      return rt('report.status.draft');
    case DraftStatus.awaitingAccount:
      return rt('report.status.awaiting_account');
    case DraftStatus.queued:
      return rt('report.status.queued');
    case DraftStatus.uploading:
      return rt('report.status.uploading');
    case DraftStatus.failed:
      return rt('report.status.failed');
    case DraftStatus.submitted:
      return switch (d.serverStatus) {
        null || SubmissionStatus.submitted => rt('report.status.submitted'),
        SubmissionStatus.inReview => rt('report.status.in_review'),
        SubmissionStatus.needsInfo => rt('report.status.needs_info'),
        SubmissionStatus.approved => rt('report.status.approved'),
        SubmissionStatus.partiallyApproved => rt(
          'report.status.partially_approved',
        ),
        SubmissionStatus.rejected => rt('report.status.rejected'),
        SubmissionStatus.withdrawn => rt('report.status.withdrawn'),
      };
  }
}

enum ReportGroup { drafts, open, done }

ReportGroup reportGroup(ReportDraft d) {
  if (d.isLocalDraft) return ReportGroup.drafts;
  if (d.status == DraftStatus.submitted) {
    switch (d.serverStatus) {
      case SubmissionStatus.approved:
      case SubmissionStatus.partiallyApproved:
      case SubmissionStatus.rejected:
      case SubmissionStatus.withdrawn:
        return ReportGroup.done;
      default:
        return ReportGroup.open;
    }
  }
  return ReportGroup.open;
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
