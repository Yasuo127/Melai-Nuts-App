// Kept only so unfinished non-customer modules that still import this path
// keep compiling. The real branch list now lives in `catalog_store.dart`
// (loaded from Supabase); the customer app does not import this file.
export '../catalog_store.dart' show kBranches;
