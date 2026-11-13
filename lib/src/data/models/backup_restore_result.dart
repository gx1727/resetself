class BackupRestoreResult {
  const BackupRestoreResult({
    required this.filePath,
    required this.restoredAt,
    required this.tableCount,
    required this.recordCount,
  });

  final String filePath;
  final DateTime restoredAt;
  final int tableCount;
  final int recordCount;
}
