import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/user_guide.dart';

class ExportService {
  Future<String> exportToPdf(UserGuide guide) async {
    final doc = pw.Document(title: guide.title, author: 'DocGen');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              guide.title,
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if (guide.description.isNotEmpty)
            pw.Paragraph(
              text: guide.description,
              style: const pw.TextStyle(fontSize: 14),
            ),
          pw.Paragraph(
            text: 'Generated on ${_formatDate(guide.createdAt)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Divider(),
          pw.SizedBox(height: 20),
          ...guide.steps.expand(
            (step) => [
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Step ${step.order + 1}: ${step.title}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (step.screenshot != null)
                pw.Center(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 10),
                    constraints: const pw.BoxConstraints(maxHeight: 300),
                    child: pw.Image(pw.MemoryImage(step.screenshot!)),
                  ),
                ),
              pw.Paragraph(
                text: step.description,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final safeName = guide.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());

    return file.path;
  }

  Future<String> exportToMarkdown(UserGuide guide) async {
    final buffer = StringBuffer()
      ..writeln('# ${guide.title}')
      ..writeln();

    if (guide.description.isNotEmpty) {
      buffer
        ..writeln(guide.description)
        ..writeln();
    }

    buffer
      ..writeln('*Generated on ${_formatDate(guide.createdAt)}*')
      ..writeln()
      ..writeln('---')
      ..writeln();

    for (final step in guide.steps) {
      buffer
        ..writeln('## Step ${step.order + 1}: ${step.title}')
        ..writeln();
      if (step.screenshot != null) {
        buffer
          ..writeln(
            '![Step ${step.order + 1}](screenshots/step_${step.order + 1}.jpg)',
          )
          ..writeln();
      }
      buffer
        ..writeln(step.description)
        ..writeln();
    }

    final dir = await getApplicationDocumentsDirectory();
    final safeName = guide.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}.md';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    if (guide.steps.any((s) => s.screenshot != null)) {
      final screenshotsDir = Directory('${dir.path}/screenshots');
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }
      for (final step in guide.steps) {
        if (step.screenshot != null) {
          final imgFile = File(
            '${screenshotsDir.path}/step_${step.order + 1}.jpg',
          );
          await imgFile.writeAsBytes(step.screenshot!);
        }
      }
    }

    return file.path;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
