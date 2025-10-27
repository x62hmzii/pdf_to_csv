import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PDFParserService {

  // Main method to extract text from PDF using Syncfusion
  Future<String> extractCompleteText(File file) async {
    try {
      // Use Syncfusion for PDF text extraction
      String text = await _extractWithSyncfusion(file);

      final cleanedText = _cleanExtractedText(text);

      return cleanedText;
    } catch (e) {
      throw Exception('PDF text extraction failed: $e');
    }
  }

  // Extract using Syncfusion PDF
  Future<String> _extractWithSyncfusion(File file) async {
    try {
      final List<int> bytes = await file.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('PDF extraction failed: $e');
    }
  }

  // Check if extracted text contains table-like data
  bool _containsTableData(String text) {
    final patterns = [
      'Booking Date',
      'Description',
      'Credit',
      'Debit',
      'Balance',
      'Transaction',
      'Amount',
      'PKR',
      'Rs',
    ];

    int matches = 0;
    for (var pattern in patterns) {
      if (text.contains(pattern)) matches++;
    }

    final datePattern = RegExp(r'\d{1,2}[A-Za-z]{3} \d{4}');
    final amountPattern = RegExp(r'[\d,]+\.\d{2}');

    if (datePattern.hasMatch(text)) matches++;
    if (amountPattern.hasMatch(text)) matches++;

    return matches >= 3;
  }

  // Clean and normalize extracted text
  String _cleanExtractedText(String rawText) {
    String cleaned = rawText
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();

    // Remove common PDF artifacts
    cleaned = cleaned
        .replaceAll(RegExp(r'Page \d+ of \d+'), '')
        .replaceAll(RegExp(r'\u0000'), '')
        .replaceAll(RegExp(r'\f'), '')
        .trim();

    return cleaned;
  }

  // Enhanced table detection for bank statements
  List<PDFTable> detectTables(String text) {
    final List<PDFTable> tables = [];
    final List<String> lines = text.split('\n');

    List<String> currentHeaders = [];
    List<List<String>> currentRows = [];
    bool inTable = false;

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.isEmpty) continue;

      // Detect table header
      if (!inTable && _isTableHeader(line)) {
        inTable = true;
        currentHeaders = _extractHeaders(line);
        continue;
      }

      // Process table rows
      if (inTable) {
        if (_isTableRow(line)) {
          final List<String> rowData = _parseTableRow(line, currentHeaders);
          if (rowData.isNotEmpty) {
            currentRows.add(rowData);
          }
        } else if (_isTableEnd(line) || _isTableHeader(line)) {
          // End current table and start new one
          if (currentHeaders.isNotEmpty && currentRows.isNotEmpty) {
            tables.add(PDFTable(headers: currentHeaders, rows: currentRows));
          }
          currentHeaders = _isTableHeader(line) ? _extractHeaders(line) : [];
          currentRows = [];
          inTable = _isTableHeader(line);
        }
      }
    }

    // Add final table
    if (currentHeaders.isNotEmpty && currentRows.isNotEmpty) {
      tables.add(PDFTable(headers: currentHeaders, rows: currentRows));
    }

    return tables;
  }

  // Improved header detection
  bool _isTableHeader(String line) {
    final headerPatterns = [
      'Booking Date',
      'Transaction Date',
      'Description',
      'Particulars',
      'Credit',
      'Debit',
      'Withdrawal',
      'Deposit',
      'Balance',
      'Available Balance',
      'Amount',
      'Value Date',
      'Reference',
    ];

    final lowerLine = line.toLowerCase();
    return headerPatterns.any((pattern) => lowerLine.contains(pattern.toLowerCase()));
  }

  // Extract headers with improved logic
  List<String> _extractHeaders(String headerLine) {
    // Split by common delimiters in table headers
    final List<String> potentialHeaders = headerLine.split(RegExp(r'\s{2,}|\t'));

    // Filter and clean headers
    return potentialHeaders
        .where((header) => header.trim().isNotEmpty)
        .map((header) => header.trim())
        .toList();
  }

  // Improved table row detection
  bool _isTableRow(String line) {
    // Check for date patterns
    final hasDate = RegExp(r'^\d{1,2}[A-Za-z]{3} \d{4}').hasMatch(line) ||
        RegExp(r'^\d{1,2}/\d{1,2}/\d{4}').hasMatch(line) ||
        RegExp(r'^[A-Za-z]{3} \d{1,2}, \d{4}').hasMatch(line);

    // Check for amount patterns
    final hasAmount = RegExp(r'PKR?[\d,]+\.?\d*').hasMatch(line) ||
        RegExp(r'Rs?\.?[\d,]+\.?\d*').hasMatch(line) ||
        RegExp(r'[\d,]+\.\d{2}').hasMatch(line);

    return hasDate || (hasAmount && line.length > 5);
  }

  // Enhanced table row parsing
  List<String> _parseTableRow(String line, List<String> headers) {
    final List<String> rowData = List.filled(headers.length, '');

    try {
      // Extract date (first column)
      final dateMatch = RegExp(r'(\d{1,2}[A-Za-z]{3} \d{4}|\d{1,2}/\d{1,2}/\d{4}|[A-Za-z]{3} \d{1,2}, \d{4})').firstMatch(line);
      if (dateMatch != null) {
        rowData[0] = dateMatch.group(0)!;
      }

      // Extract amounts with proper sign detection
      final amountMatches = RegExp(r'([+-]?)\s*(PKR?|Rs?\.?)?\s*([\d,]+\.?\d*)').allMatches(line);
      final List<String> amounts = [];

      for (final match in amountMatches) {
        final sign = match.group(1) ?? '';
        final currency = match.group(2) ?? '';
        final amount = match.group(3) ?? '';
        amounts.add('$sign$currency$amount');
      }

      // Assign amounts based on context
      if (amounts.isNotEmpty) {
        // Simple heuristic: negative amounts are debits, positive are credits
        for (String amount in amounts) {
          if (amount.contains('-') && rowData[3].isEmpty) {
            rowData[3] = amount; // Debit
          } else if ((amount.contains('+') || !amount.contains('-')) && rowData[2].isEmpty) {
            rowData[2] = amount.replaceFirst('+', ''); // Credit
          } else if (rowData[4].isEmpty) {
            rowData[4] = amount; // Balance
          }
        }
      }

      // Extract description (remaining text after removing dates and amounts)
      String description = line;
      description = description.replaceAll(RegExp(r'([+-]?)\s*(PKR?|Rs?\.?)?\s*([\d,]+\.?\d*)'), '');
      description = description.replaceAll(RegExp(r'(\d{1,2}[A-Za-z]{3} \d{4}|\d{1,2}/\d{1,2}/\d{4}|[A-Za-z]{3} \d{1,2}, \d{4})'), '');
      description = description.replaceAll(RegExp(r'^\s*-\s*'), ''); // Remove leading dashes
      rowData[1] = description.trim();

    } catch (e) {
      // Error handled silently in production
    }

    return rowData;
  }

  // Check for table end
  bool _isTableEnd(String line) {
    return line.contains('---') ||
        line.contains('***') ||
        line.toLowerCase().contains('total') ||
        line.toLowerCase().contains('page') ||
        line.toLowerCase().contains('continued');
  }
}

class PDFTable {
  final List<String> headers;
  final List<List<String>> rows;

  PDFTable({
    required this.headers,
    this.rows = const [],
  });
}