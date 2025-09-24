import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/storage_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedData;
  bool isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text('This app needs camera permission to scan QR codes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue != scannedData) {
        setState(() {
          scannedData = barcode.rawValue;
        });
        _showScanResult(barcode.rawValue!);
      }
    }
  }

  void _showScanResult(String data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              SelectableText(
                data,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: data));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await StorageService.saveQRCode(data, 'Scanned QR Code', type: 'scanned');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QR Code saved')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      scannedData = null;
                    });
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Continue Scanning'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _toggleFlash() {
    cameraController.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onDetect,
                ),
                // QR Code scanning overlay - Simple square frame
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  Text(
                    'Position the QR code within the blue frame',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Align the QR code with the corner markers for best results',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}