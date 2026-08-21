import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'inventory_label_data.dart';
import 'inventory_label_template.dart';

final class InventoryLabelPdfGenerator {
  const InventoryLabelPdfGenerator._();

  static Future<Uint8List> generateSingleLabelSheet({
    required InventoryLabelData label,
    required InventoryLabelTemplate template,
    required int startingPosition,
  }) async {
    final slot = template.slotForPosition(startingPosition);

    final document = pw.Document();

    final pageFormat = PdfPageFormat(
      template.pageWidthInches * PdfPageFormat.inch,
      template.pageHeightInches * PdfPageFormat.inch,
      marginAll: 0,
    );

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned(
                left: slot.leftInches * PdfPageFormat.inch,
                top: slot.topInches * PdfPageFormat.inch,
                child: _buildLabel(
                  label: label,
                  width: slot.widthInches * PdfPageFormat.inch,
                  height: slot.heightInches * PdfPageFormat.inch,
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _buildLabel({
    required InventoryLabelData label,
    required double width,
    required double height,
  }) {
    const paddingInches = 0.045;
    final padding = paddingInches * PdfPageFormat.inch;

    final qrSize = height - (padding * 2);

    return pw.SizedBox(
      width: width,
      height: height,
      child: pw.Padding(
        padding: pw.EdgeInsets.all(padding),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: label.qrValue,
              width: qrSize,
              height: qrSize,
            ),
            pw.SizedBox(width: 6),
            pw.Expanded(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    label.inventoryNumber,
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    label.displayName,
                    maxLines: 2,
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
