// Builds a real PDF of the generated timetable - one page per
// section - and opens the device's native Save/Print/Share dialog.
// This is genuinely useful on a phone: an admin can generate a
// timetable, export it, and share it straight to WhatsApp/email/
// Drive without ever leaving the app.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
const _periodsPerDay = 6;

Future<void> exportTimetablePdf(
  Map<String, Map<String, Map<int, dynamic>>> data,
  List<String> sectionNames,
) async {
  final doc = pw.Document();

  for (final section in sectionNames) {
    final sectionData = data[section]!;

    final headers = ['Period', ..._days];
    final rows = List.generate(_periodsPerDay, (i) {
      final period = i + 1;
      return [
        'P$period',
        ..._days.map((day) {
          final entry = sectionData[day]?[period];
          if (entry == null) return 'Free';
          return '${entry['subject']}\n${entry['faculty']}\n(${entry['room']})';
        }),
      ];
    });

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Timetable - $section',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo100),
                columnWidths: {0: const pw.FixedColumnWidth(50)},
              ),
            ],
          );
        },
      ),
    );
  }

  await Printing.layoutPdf(onLayout: (format) async => doc.save());
}
