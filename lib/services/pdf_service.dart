import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/coffee_record.dart';

class PdfService {
  static Future<void> generateReport({
    required String title,
    required List<CoffeeRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    double totalSeco = 0;
    double totalVenta = 0;

    for (var record in records) {
      totalSeco += record.dryCoffeeKg;
      totalVenta += record.total;
    }

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
          _buildSummary(totalSeco, totalVenta, currencyFormat),
          pw.SizedBox(height: 20),
          pw.Text(
            'Detalle de Registros',
            style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Finca', 'Kilos Seco', 'Precio/kg', 'Total'],
            headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown900),
            data: records.map((record) {
              return [
                dateFormat.format(record.date),
                record.farmName,
                '${record.dryCoffeeKg.toStringAsFixed(2)} kg',
                currencyFormat.format(record.pricePerKg),
                currencyFormat.format(record.total),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'Reporte_Koffee_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, DateTime start, DateTime end) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Koffee - Registro Agrícola',
          style: const pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF2E1C14),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
        ),
        pw.Text(
          'Periodo: ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _buildSummary(
    double dryKg,
    double sales,
    NumberFormat currency,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Café Seco',
            '${dryKg.toStringAsFixed(2)} kg',
            PdfColors.brown700,
          ),
          _buildSummaryItem(
            'Total Venta',
            currency.format(sales),
            PdfColors.green800,
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
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
              'Generado por Koffee App',
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
