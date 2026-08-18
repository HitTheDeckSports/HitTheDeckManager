import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/qr/inventory_qr_codec.dart';

class InventoryQrScannerScreen extends StatefulWidget {
  const InventoryQrScannerScreen({super.key});

  @override
  State<InventoryQrScannerScreen> createState() =>
      _InventoryQrScannerScreenState();
}

class _InventoryQrScannerScreenState extends State<InventoryQrScannerScreen> {
  late final MobileScannerController _scannerController;
  bool _isHandlingScan = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isHandlingScan) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;

      if (rawValue == null) {
        continue;
      }

      final itemId = InventoryQrCodec.tryParseInventoryItemId(rawValue);

      if (itemId == null) {
        setState(() {
          _errorMessage =
              'This QR code is not a valid Hit the Deck inventory code.';
        });
        continue;
      }

      _isHandlingScan = true;

      context.goNamed(
        AppRouteNames.inventoryDetail,
        pathParameters: {'itemId': itemId},
      );

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Scan Inventory QR',
      subtitle: 'Point the camera at a Hit the Deck inventory QR code.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                key: const Key('inventoryQrScanner'),
                controller: _scannerController,
                onDetect: _handleDetection,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              key: const Key('inventoryQrScannerError'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
