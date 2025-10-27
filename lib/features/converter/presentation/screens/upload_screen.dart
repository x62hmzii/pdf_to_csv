import 'dart:io';
import 'package:agr_converter/core/constants/app_constants.dart';
import 'package:agr_converter/core/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import '../providers/conversion_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionProvider);
    final notifier = ref.read(conversionProvider.notifier);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Upload PDF'),
        backgroundColor: AppConstants.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upload Card
            _buildUploadCard(state, notifier, context),

            const SizedBox(height: 20),

            // Conversion Button
            if (state.selectedFile != null)
              _buildConversionButton(state, notifier, context),

            // Result Section
            if (state.conversionResult != null && state.conversionResult!['success'] == true)
              _buildResultSection(state, notifier, context),

            // Error Message
            if (state.error != null)
              _buildErrorMessage(state, notifier),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(ConversionState state, ConversionNotifier notifier, BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: GradientBoxBorder(
            gradient: AppConstants.primaryGradient,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload,
              size: 50,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 15),
            Text(
              state.selectedFile != null ? state.fileName : 'Select PDF File',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (state.selectedFile != null) ...[
              const SizedBox(height: 8),
              Text(
                'Size: ${FileUtils.getFileSize(state.fileSize)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textColor.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: state.isLoading ? null : () => notifier.pickPDFFile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              ),
              child: state.isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text(
                'Choose PDF',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (state.selectedFile != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => notifier.clearSelection(),
                child: const Text(
                  'Clear Selection',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversionButton(ConversionState state, ConversionNotifier notifier, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => notifier.convertToCSV(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.isLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Text(
          'Convert to CSV',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(ConversionState state, ConversionNotifier notifier, BuildContext context) {
    final filePath = state.conversionResult!['filePath'];
    final rowCount = state.conversionResult!['rowCount'] ?? 0;
    final columnCount = state.conversionResult!['columnCount'] ?? 0;
    final fileName = File(filePath).uri.pathSegments.last;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Conversion Successful!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // File Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rows: $rowCount | Columns: $columnCount',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                // Open File Button
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => _openCSVFile(filePath, context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new, size: 16),
                          SizedBox(width: 5),
                          Text(
                            'Open',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Share File Button
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _shareCSVFile(filePath, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, size: 16),
                          SizedBox(width: 5),
                          Text(
                            'Share',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ConversionState state, ConversionNotifier notifier) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => notifier.clearError(),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Open CSV file
  Future<void> _openCSVFile(String filePath, BuildContext context) async {
    try {
      final result = await OpenFile.open(filePath);

      switch (result.type) {
        case ResultType.done:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File opened successfully'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case ResultType.noAppToOpen:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No app found to open CSV files'),
              backgroundColor: Colors.orange,
            ),
          );
          break;
        case ResultType.fileNotFound:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case ResultType.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied to open file'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case ResultType.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error opening file'),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Share CSV file
  Future<void> _shareCSVFile(String filePath, BuildContext context) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(filePath)], text: 'Converted CSV File');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found for sharing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}