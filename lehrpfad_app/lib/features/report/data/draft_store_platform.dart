import 'draft_store.dart';
import 'draft_store_stub.dart'
    if (dart.library.io) 'draft_store_io.dart'
    as impl;

/// Plattform-Adapter: Dateien native, Speicher im Web.
ReportDraftStore createReportDraftStore() => impl.createReportDraftStore();
