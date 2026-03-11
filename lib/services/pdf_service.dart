import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/coffee_record.dart';
import '../models/worker_record.dart';

class PdfService {
  static Future<void> generateReport({
    required String title,
    required List<CoffeeRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    // Load fonts (using standard fonts for simplicity)
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Calculate totals
    double totalSeco = 0;
    double totalVenta = 0;

    for (var record in records) {
      totalSeco += record.dryCoffeeKg;
      totalVenta += record.total;
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
          _buildSummary(totalSeco, totalVenta, currencyFormat),
          pw.SizedBox(height: 20),
          pw.Text(
            'Detalle de Registros',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Farm', 'Kilos Seco', 'Precio/kg', 'Total'],
            headerStyle: pw.TextStyle(
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
            'Total Café Seco',
            '${dryKg.toStringAsFixed(2)} kg',
            PdfColors.brown600,
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
            fontSize: 14,
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

  static Future<void> generateWorkerPaymentReport({
    required String title,
    required List<WorkerRecord> records,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    final Map<String, List<WorkerRecord>> workersMap = {};
    for (var record in records) {
      if (workersMap.containsKey(record.workerName)) {
        workersMap[record.workerName]!.add(record);
      } else {
        workersMap[record.workerName] = [record];
      }
    }

    double totalGeneral = 0;
    for (var record in records) {
      totalGeneral += record.total;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) => [
          _buildWorkerPaymentHeader(title, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildWorkerPaymentSummary(totalGeneral, currencyFormat),
          pw.SizedBox(height: 20),
          pw.Text(
            'Detalle por Worker',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...workersMap.entries.map((entry) {
            final workerName = entry.key;
            final workerRecords = entry.value;
            final totalWorker = workerRecords.fold(
              0.0,
              (sum, record) => sum + record.total,
            );
            final workerKilograms = workerRecords.fold(
              0.0,
              (sum, record) => sum + record.kilograms,
            );

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColors.brown50,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          workerName,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        pw.Text(
                          '${workerKilograms.toStringAsFixed(1)} kg - ${currencyFormat.format(totalWorker)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  pw.TableHelper.fromTextArray(
                    headers: ['Fecha', 'Farm', 'Kilos', 'Precio/kg', 'Total'],
                    data: workerRecords.map((record) {
                      return [
                        dateFormat.format(record.date),
                        record.farmName,
                        '${record.kilograms.toStringAsFixed(1)} kg',
                        currencyFormat.format(record.pricePerKg),
                        currencyFormat.format(record.total),
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.brown900,
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'Pago_Jornaleros_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildWorkerPaymentHeader(
    String title,
    DateTime start,
    DateTime end,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Koffee - Pago Jornaleros',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.brown900,
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

  static pw.Widget _buildWorkerPaymentSummary(double total, NumberFormat currency) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.green50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Column(
            children: [
              pw.Text(
                'TOTAL A PAGAR',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                currency.format(total),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
