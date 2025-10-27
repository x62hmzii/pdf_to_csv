import 'dart:io';
import 'package:agr_converter/core/utils/file_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/conversion_repository.dart';
import '../../domain/entities/conversion_entity.dart';

class ConversionNotifier extends StateNotifier<ConversionState> {
  final ConversionRepository _repository;

  ConversionNotifier(this._repository) : super(ConversionState.initial());

  // Pick PDF file with improved error handling
  Future<void> pickPDFFile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await FileUtils.pickPDFFile();

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Validate file
        if (!FileUtils.isValidPDFFile(filePath)) {
          throw Exception('Selected file is not a valid PDF');
        }

        final file = File(filePath);
        final fileSize = await file.length();

        state = state.copyWith(
          selectedFile: file,
          fileName: result.files.single.name,
          fileSize: fileSize,
          isLoading: false,
          conversionResult: null,
        );
      } else {
        // User cancelled file selection
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to pick file: ${e.toString()}',
      );
    }
  }

  // Convert PDF to CSV
  Future<void> convertToCSV() async {
    if (state.selectedFile == null) {
      state = state.copyWith(error: 'No file selected');
      return;
    }

    state = state.copyWith(
        isLoading: true,
        error: null,
        conversionResult: null
    );

    try {
      final result = await _repository.convertPDFToCSV(
          state.selectedFile!,
          state.fileName.replaceAll('.pdf', '')
      );

      // Create conversion entity
      final conversion = ConversionEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: state.fileName,
        filePath: result['filePath'] ?? '',
        convertedAt: DateTime.now(),
        fileSize: state.fileSize,
        isSuccessful: true,
        rowCount: result['rowCount'] ?? 0,
        columnCount: result['columnCount'] ?? 0,
        metadata: result['metadata'] ?? {},
      );

      state = state.copyWith(
        isLoading: false,
        conversionResult: result,
        conversionHistory: [...state.conversionHistory, conversion],
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Conversion failed: ${e.toString()}',
      );
    }
  }

  // Clear selection
  void clearSelection() {
    state = state.copyWith(
      selectedFile: null,
      fileName: '',
      fileSize: 0,
      conversionResult: null,
      error: null,
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

class ConversionState {
  final bool isLoading;
  final File? selectedFile;
  final String fileName;
  final int fileSize;
  final Map<String, dynamic>? conversionResult;
  final String? error;
  final List<ConversionEntity> conversionHistory;

  // Computed properties
  File? get convertedFile {
    if (conversionResult != null && conversionResult!['filePath'] != null) {
      return File(conversionResult!['filePath']);
    }
    return null;
  }

  bool get hasFileSelected => selectedFile != null;
  bool get isConversionSuccessful => conversionResult != null && conversionResult!['success'] == true;

  ConversionState({
    required this.isLoading,
    this.selectedFile,
    required this.fileName,
    required this.fileSize,
    this.conversionResult,
    this.error,
    required this.conversionHistory,
  });

  factory ConversionState.initial() => ConversionState(
    isLoading: false,
    fileName: '',
    fileSize: 0,
    conversionHistory: [],
  );

  ConversionState copyWith({
    bool? isLoading,
    File? selectedFile,
    String? fileName,
    int? fileSize,
    Map<String, dynamic>? conversionResult,
    String? error,
    List<ConversionEntity>? conversionHistory,
  }) {
    return ConversionState(
      isLoading: isLoading ?? this.isLoading,
      selectedFile: selectedFile ?? this.selectedFile,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      conversionResult: conversionResult ?? this.conversionResult,
      error: error ?? this.error,
      conversionHistory: conversionHistory ?? this.conversionHistory,
    );
  }
}

// Provider - Alternative syntax
final conversionProvider = StateNotifierProvider<ConversionNotifier, ConversionState>((ref) {
  return ConversionNotifier(ConversionRepository());
});
