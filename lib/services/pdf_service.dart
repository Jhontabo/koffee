import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/registro_finca.dart';

class PdfService {
  static Future<void> generateReport({
    required String title,
    required List<RegistroFinca> registros,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    // Load fonts (using standard fonts for simplicity)
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Calculate totals
    double totalRojo = 0;

    for (var reg in registros) {
      totalRojo += reg.kilosRojo;
    }

    // Format numbers
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) => [
          _buildHeader(title, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildSummary(totalRojo, currencyFormat),
          pw.SizedBox(height: 20),
          pw.Text(
            'Detalle de Registros',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildTable(registros, dateFormat),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Share directly (WhatsApp, Email, etc.)
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'Reporte_Koffee_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, DateTime start, DateTime end) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Koffee - Registro Agrícola',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.brown900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
        ),
        pw.Text(
          'Periodo: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _buildSummary(double rojo, NumberFormat currency) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Café Rojo',
            '${rojo.toStringAsFixed(2)} kg',
            PdfColors.red800,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
    List<RegistroFinca> registros,
    DateFormat dateFormat,
  ) {
    return pw.Table.fromTextArray(
      headers: ['Fecha', 'Finca', 'Kilos'],
      data: registros.map((reg) {
        return [
          dateFormat.format(reg.fecha),
          reg.finca,
          '${reg.kilosRojo.toStringAsFixed(2)} kg',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.brown900),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generado por App Koffee',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }
}
