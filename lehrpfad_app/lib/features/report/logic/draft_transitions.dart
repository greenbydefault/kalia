import '../domain/report_enums.dart';

/// Ereignisse, die den Status eines Entwurfs ändern (Spec 13.2, S1 bis S14).
enum DraftEvent {
  pause, // S1
  resume, // S2
  finishAndReview, // S3
  continueRecording, // S4 (direkt nach Beenden)
  submitSignedIn, // S5
  submitSignedOut, // S6
  signInSucceeded, // S7
  queueStarts, // S8
  uploadComplete, // S9
  uploadNetworkError, // S10 (Netzfehler oder HTTP 5xx)
  upload401, // S11
  uploadRejected, // S12 (invalid_payload, too_large, limit_open, limit_daily)
  edit, // S13
  systemKilledReview, // S14 (R15 „Prüfen und einreichen“)
}

/// Zulässiger Übergang oder `null`, wenn das Ereignis im Status nicht gilt.
DraftStatus? nextDraftStatus(DraftStatus from, DraftEvent event) {
  switch (event) {
    case DraftEvent.pause:
      return from == DraftStatus.recording ? DraftStatus.paused : null;
    case DraftEvent.resume:
      return from == DraftStatus.paused ? DraftStatus.recording : null;
    case DraftEvent.finishAndReview:
    case DraftEvent.systemKilledReview:
      return from == DraftStatus.recording || from == DraftStatus.paused
          ? DraftStatus.review
          : null;
    case DraftEvent.continueRecording:
      return from == DraftStatus.review ? DraftStatus.recording : null;
    case DraftEvent.submitSignedIn:
      return from == DraftStatus.review ? DraftStatus.queued : null;
    case DraftEvent.submitSignedOut:
      return from == DraftStatus.review ? DraftStatus.awaitingAccount : null;
    case DraftEvent.signInSucceeded:
      return from == DraftStatus.awaitingAccount ? DraftStatus.queued : null;
    case DraftEvent.queueStarts:
      return from == DraftStatus.queued ? DraftStatus.uploading : null;
    case DraftEvent.uploadComplete:
      return from == DraftStatus.uploading ? DraftStatus.submitted : null;
    case DraftEvent.uploadNetworkError:
      return from == DraftStatus.uploading ? DraftStatus.queued : null;
    case DraftEvent.upload401:
      return from == DraftStatus.uploading ? DraftStatus.awaitingAccount : null;
    case DraftEvent.uploadRejected:
      return from == DraftStatus.uploading ? DraftStatus.failed : null;
    case DraftEvent.edit:
      return from == DraftStatus.failed ? DraftStatus.review : null;
  }
}
