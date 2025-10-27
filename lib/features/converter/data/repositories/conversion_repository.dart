import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class ConversionRepository {

  // Main conversion method
  Future<Map<String, dynamic>> convertPDFToCSV(File pdfFile, String fileName) async {
    try {
      // Extract text from PDF
      final String extractedText = await _extractPDFText(pdfFile);

      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from the PDF');
      }

      // Parse text to CSV data
      final List<List<dynamic>> csvData = _parseToCSVData(extractedText);

      if (csvData.length <= 1) {
        throw Exception('No structured data found in PDF');
      }

      // Convert to CSV string and save
      final String filePath = await _saveAsCSV(csvData, fileName);

      return {
        'success': true,
        'filePath': filePath,
        'rowCount': csvData.length - 1,
        'columnCount': csvData.isNotEmpty ? csvData[0].length : 0,
        'metadata': {
          'originalFileName': fileName,
          'extractedTextLength': extractedText.length,
          'csvRows': csvData.length,
          'csvColumns': csvData.isNotEmpty ? csvData[0].length : 0,
          'conversionTimestamp': DateTime.now().toIso8601String(),
        },
      };

    } catch (e) {
      rethrow;
    }
  }

  // Extract text from PDF using Syncfusion
  Future<String> _extractPDFText(File file) async {
    try {
      final List<int> bytes = await file.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();
      return _cleanExtractedText(text);
    } catch (e) {
      throw Exception('PDF text extraction failed');
    }
  }

  // Clean extracted text
  String _cleanExtractedText(String rawText) {
    return rawText
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'Page \d+ of \d+'), '')
        .trim();
  }

  // Parse extracted text to CSV data
  List<List<dynamic>> _parseToCSVData(String text) {
    final List<String> lines = text.split('\n');

    // Try to detect table structure first
    final List<List<dynamic>> tableData = _extractTableData(lines);

    if (tableData.isNotEmpty && tableData.length > 1) {
      return tableData;
    }

    // Fallback to line-by-line parsing
    return _parseLinesToCSV(lines);
  }

  // Extract table data from lines
  List<List<dynamic>> _extractTableData(List<String> lines) {
    final List<List<dynamic>> csvData = [];
    List<String>? headers;
    final List<List<String>> rows = [];

    bool inTable = false;

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.isEmpty) continue;

      // Detect table header
      if (!inTable && _isTableHeader(line)) {
        inTable = true;
        headers = _extractHeaders(line);
        if (headers.isNotEmpty) {
          csvData.add(headers);
        }
        continue;
      }

      // Process table rows
      if (inTable && _isTableRow(line)) {
        final List<String> rowData = _parseTableRow(line, headers ?? []);
        if (rowData.isNotEmpty && rowData.any((cell) => cell.isNotEmpty)) {
          rows.add(rowData);
        }
      }

      // Detect table end
      if (inTable && _isTableEnd(line)) {
        inTable = false;
        // Add all collected rows
        csvData.addAll(rows);
        rows.clear();
      }
    }

    // Add any remaining rows
    if (rows.isNotEmpty && csvData.isNotEmpty) {
      csvData.addAll(rows);
    }

    return csvData;
  }

  // Parse lines to CSV (fallback method)
  List<List<dynamic>> _parseLinesToCSV(List<String> lines) {
    final List<List<dynamic>> csvData = [];

    // Add default headers for bank statements
    csvData.add([
      'Date',
      'Description',
      'Credit Amount',
      'Debit Amount',
      'Balance',
      'Reference'
    ]);

    // Process each line for transaction data
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();

      if (_isTransactionLine(line)) {
        final List<String> transaction = _parseTransactionLine(line, lines, i);
        if (transaction.isNotEmpty && transaction.any((cell) => cell.isNotEmpty)) {
          csvData.add(transaction);
        }
      }
    }

    return csvData;
  }

  bool _isTableHeader(String line) {
    final headerPatterns = [
      'Booking Date',
      'Transaction Date',
      'Description',
      'Credit',
      'Debit',
      'Balance',
      'Available Balance',
      'Amount',
    ];

    final lowerLine = line.toLowerCase();
    return headerPatterns.any((pattern) => lowerLine.contains(pattern.toLowerCase()));
  }

  List<String> _extractHeaders(String headerLine) {
    return ['Booking Date', 'Description', 'Credit', 'Debit', 'Available Balance'];
  }

  bool _isTableRow(String line) {
    return RegExp(r'^\d{1,2}[A-Za-z]{3} \d{4}').hasMatch(line) ||
        RegExp(r'PKR?[\d,]+\.?\d*').hasMatch(line);
  }

  bool _isTableEnd(String line) {
    return line.contains('---') ||
        line.contains('Page') ||
        line.isEmpty;
  }

  List<String> _parseTableRow(String line, List<String> headers) {
    final List<String> row = List.filled(headers.length, '');

    try {
      // Extract date
      final dateMatch = RegExp(r'\d{1,2}[A-Za-z]{3} \d{4}').firstMatch(line);
      if (dateMatch != null) {
        row[0] = dateMatch.group(0)!;
      }

      // Extract amounts
      final amountMatches = RegExp(r'PKR?([\d,]+\.?\d*)').allMatches(line);
      final List<String> amounts = [];

      for (final match in amountMatches) {
        amounts.add('PKR${match.group(1)}');
      }

      // Assign amounts to appropriate columns
      if (amounts.isNotEmpty) {
        if (line.contains('-') && row[3].isEmpty) {
          row[3] = amounts[0]; // Debit
        } else if (line.contains('+') && row[2].isEmpty) {
          row[2] = amounts[0]; // Credit
        } else if (row[4].isEmpty) {
          row[4] = amounts.length > 1 ? amounts[1] : amounts[0]; // Balance
        }
      }

      // Extract description
      String description = line;
      description = description.replaceAll(RegExp(r'PKR?[\d,]+\.?\d*'), '');
      description = description.replaceAll(RegExp(r'\d{1,2}[A-Za-z]{3} \d{4}'), '');
      description = description.replaceAll(RegExp(r'[+-]'), '');
      row[1] = description.trim();

    } catch (e) {
      // Error handled silently
    }

    return row;
  }

  bool _isTransactionLine(String line) {
    return RegExp(r'\d{1,2}[A-Za-z]{3} \d{4}').hasMatch(line) &&
        (line.contains('PKR') || line.contains('.00'));
  }

  List<String> _parseTransactionLine(String line, List<String> allLines, int currentIndex) {
    final List<String> transaction = List.filled(6, '');

    try {
      // Extract date
      final dateMatch = RegExp(r'\d{1,2}[A-Za-z]{3} \d{4}').firstMatch(line);
      if (dateMatch != null) {
        transaction[0] = dateMatch.group(0)!;
      }

      // Combine multi-line descriptions
      String fullDescription = line;
      int nextIndex = currentIndex + 1;

      while (nextIndex < allLines.length &&
          !_isTransactionLine(allLines[nextIndex]) &&
          !allLines[nextIndex].contains('Booking Date')) {
        fullDescription += ' ${allLines[nextIndex].trim()}';
        nextIndex++;
      }

      // Extract amounts
      final amountPattern = RegExp(r'PKR?([\d,]+\.?\d*)');
      final amountMatches = amountPattern.allMatches(fullDescription);
      final amounts = amountMatches.map((m) => 'PKR${m.group(1)}').toList();

      // Determine credit/debit
      final bool isCredit = fullDescription.contains('+');
      final bool isDebit = fullDescription.contains('-');

      if (amounts.isNotEmpty) {
        if (isCredit) {
          transaction[2] = amounts[0]; // Credit
        } else if (isDebit) {
          transaction[3] = amounts[0]; // Debit
        }

        // Balance is usually the last amount
        if (amounts.length > 1) {
          transaction[4] = amounts.last;
        }
      }

      // Extract description
      String description = fullDescription;
      description = description.replaceAll(RegExp(r'PKR?[\d,]+\.?\d*'), '');
      description = description.replaceAll(RegExp(r'\d{1,2}[A-Za-z]{3} \d{4}'), '');
      description = description.replaceAll(RegExp(r'[+-]'), '');
      transaction[1] = description.trim();

    } catch (e) {
      // Error handled silently
    }

    return transaction;
  }

  // Save CSV data to file
  Future<String> _saveAsCSV(List<List<dynamic>> csvData, String fileName) async {
    try {
      // Convert to CSV string
      const ListToCsvConverter converter = ListToCsvConverter();
      final String csvString = converter.convert(csvData);

      // Get downloads directory
      final Directory? downloadsDir = await getDownloadsDirectory();
      final String saveDir = downloadsDir?.path ?? '/storage/emulated/0/Download';
      final Directory directory = Directory(saveDir);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final String csvFileName = '${cleanFileName}_converted_$timestamp.csv';
      final String filePath = '${directory.path}/$csvFileName';

      // Save file
      final File csvFile = File(filePath);
      await csvFile.writeAsString(csvString, flush: true);

      return filePath;

    } catch (e) {
      throw Exception('Failed to save CSV file');
    }
  }
}