class BackupExportResult {
  const BackupExportResult({
    required this.filePath,
    required this.exportedAt,
    required this.tableCount,
    required this.recordCount,
  });

  final String filePath;
  final DateTime exportedAt;
  final int tableCount;
  final int recordCount;
}
