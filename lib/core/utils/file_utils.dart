import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  // Check and request storage permission
  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Check and request manage external storage permission (for Android 11+)
  static Future<bool> requestManageExternalStorage() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  // Pick PDF file with improved error handling
  static Future<FilePickerResult?> pickPDFFile() async {
    try {
      // Request permissions
      final hasStoragePermission = await requestStoragePermission();
      final hasManagePermission = await requestManageExternalStorage();

      if (!hasStoragePermission && !hasManagePermission) {
        throw Exception('Storage permissions are required to pick files');
      }

      // Pick file with better configuration
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false,
        withReadStream: false,
        allowCompression: true,
      );

      return result;
    } catch (e) {
      throw Exception('Failed to pick file: ${e.toString()}');
    }
  }

  // Get file size in readable format
  static String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // Get downloads directory path
  static Future<String> getDownloadsPath() async {
    try {
      final Directory? downloadsDir = await getDownloadsDirectory();
      return downloadsDir?.path ?? '/storage/emulated/0/Download';
    } catch (e) {
      return '/storage/emulated/0/Download';
    }
  }

  // Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get file name from path
  static String getFileName(String filePath) {
    try {
      return File(filePath).uri.pathSegments.last;
    } catch (e) {
      return 'unknown_file';
    }
  }

  // Get directory from path
  static String getDirectory(String filePath) {
    try {
      return File(filePath).parent.path;
    } catch (e) {
      return 'unknown_directory';
    }
  }

  // Check if path is valid PDF file
  static bool isValidPDFFile(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.toLowerCase().endsWith('.pdf') && File(path).existsSync();
  }
}