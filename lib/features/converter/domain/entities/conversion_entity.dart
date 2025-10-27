class ConversionEntity {
  final String id;
  final String fileName;
  final String filePath;
  final DateTime convertedAt;
  final int fileSize;
  final bool isSuccessful;
  final int rowCount;
  final int columnCount;
  final Map<String, dynamic> metadata;

  ConversionEntity({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.convertedAt,
    required this.fileSize,
    required this.isSuccessful,
    required this.rowCount,
    required this.columnCount,
    required this.metadata,
  });

  // Helper method to get display name
  String get displayName {
    if (fileName.length > 20) {
      return '${fileName.substring(0, 20)}...';
    }
    return fileName;
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'convertedAt': convertedAt.toIso8601String(),
      'fileSize': fileSize,
      'isSuccessful': isSuccessful,
      'rowCount': rowCount,
      'columnCount': columnCount,
      'metadata': metadata,
    };
  }

  // Create from map
  factory ConversionEntity.fromMap(Map<String, dynamic> map) {
    return ConversionEntity(
      id: map['id'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      convertedAt: DateTime.parse(map['convertedAt'] as String? ?? DateTime.now().toIso8601String()),
      fileSize: map['fileSize'] as int? ?? 0,
      isSuccessful: map['isSuccessful'] as bool? ?? false,
      rowCount: map['rowCount'] as int? ?? 0,
      columnCount: map['columnCount'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }
}