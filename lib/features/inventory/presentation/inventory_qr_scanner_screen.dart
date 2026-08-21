import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/app_page.dart';
import '../application/qr/inventory_qr_scan_resolver.dart';
import 'providers/inventory_providers.dart';

class InventoryQrScannerScreen extends ConsumerStatefulWidget {
  const InventoryQrScannerScreen({super.key});

  @override
  ConsumerState<InventoryQrScannerScreen> createState() =>
      _InventoryQrScannerScreenState();
}

class _InventoryQrScannerScreenState
    extends ConsumerState<InventoryQrScannerScreen> {
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

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isHandlingScan) {
      return;
    }

    String? rawValue;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value != null && value.trim().isNotEmpty) {
        rawValue = value;
        break;
      }
    }

    if (rawValue == null) {
      return;
    }

    setState(() {
      _isHandlingScan = true;
      _errorMessage = null;
    });

    try {
      final resolver = InventoryQrScanResolver(
        repository: ref.read(inventoryRepositoryProvider),
      );

      final result = await resolver.resolve(rawValue);

      if (!mounted) {
        return;
      }

      switch (result.type) {
        case InventoryQrScanResultType.invalidCode:
          setState(() {
            _isHandlingScan = false;
            _errorMessage =
                'This QR code is not a valid Hit the Deck inventory code.';
          });
          return;

        case InventoryQrScanResultType.itemNotFound:
          setState(() {
            _isHandlingScan = false;
            _errorMessage =
                'The inventory item for this QR code could not be found.';
          });
          return;

        case InventoryQrScanResultType.valid:
          final itemId = result.itemId;

          if (itemId == null) {
            setState(() {
              _isHandlingScan = false;
              _errorMessage = 'The scanned inventory code could not be opened.';
            });
            return;
          }

          await _scannerController.stop();

          if (!mounted) {
            return;
          }

          context.goNamed(
            AppRouteNames.inventoryDetail,
            pathParameters: {'itemId': itemId},
          );
          return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isHandlingScan = false;
        _errorMessage =
            'Unable to verify this inventory code. Please try again.';
      });
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
          if (_isHandlingScan) ...[
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Checking inventory...',
                  key: Key('inventoryQrScannerChecking'),
                ),
              ],
            ),
          ],
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
