import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'dart:async';
import 'dart:typed_data';
import '../services/storage_service.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  String _qrData = 'Hello World!';
  Color _foregroundColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _qrSize = 200.0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _textController.text = _qrData;
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _qrData = _textController.text.isNotEmpty ? _textController.text : 'Hello World!';
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }


  Future<void> _saveQRCode() async {
    if (_qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text first')),
      );
      return;
    }

    try {
      // Save to storage
      await StorageService.saveQRCode(_qrData, 'Generated QR Code');
      
      // Save to gallery
      final qrImage = await _generateQRImage();
      await Gal.putImageBytes(qrImage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code saved to gallery and app storage')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving QR Code: $e')),
        );
      }
    }
  }

  Future<Uint8List> _generateQRImage() async {
    final qrValidationResult = QrValidator.validate(
      data: _qrData,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: _foregroundColor,
        emptyColor: _backgroundColor,
        gapless: false,
      );

      final picData = await painter.toImageData(_qrSize);
      return picData!.buffer.asUint8List();
    }
    throw Exception('Invalid QR Code data');
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _qrData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // QR Code Preview at top
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // QR Code Preview
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Live QR Code',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _textController.text.isEmpty
                                ? Container(
                                    width: _qrSize,
                                    height: _qrSize,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.qr_code,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Start typing to generate QR code',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : QrImageView(
                                    data: _qrData,
                                    version: QrVersions.auto,
                                    size: _qrSize,
                                    foregroundColor: _foregroundColor,
                                    backgroundColor: _backgroundColor,
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy Text'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _saveQRCode,
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Customization options
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customize QR Code',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Foreground Color'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: _foregroundColor,
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Slider(
                                            value: _foregroundColor == Colors.black ? 0.0 : 1.0,
                                            onChanged: (value) {
                                              setState(() {
                                                _foregroundColor = value < 0.5 ? Colors.black : Colors.blue;
                                              });
                                            },
                                            divisions: 1,
                                            label: _foregroundColor == Colors.black ? 'Black' : 'Blue',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Background Color'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: _backgroundColor,
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Slider(
                                            value: _backgroundColor == Colors.white ? 0.0 : 1.0,
                                            onChanged: (value) {
                                              setState(() {
                                                _backgroundColor = value < 0.5 ? Colors.white : Colors.grey.shade100;
                                              });
                                            },
                                            divisions: 1,
                                            label: _backgroundColor == Colors.white ? 'White' : 'Light Grey',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Size: ${_qrSize.toInt()}px'),
                              Slider(
                                value: _qrSize,
                                min: 100,
                                max: 300,
                                divisions: 20,
                                onChanged: (value) {
                                  setState(() {
                                    _qrSize = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed input section at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Enter text, URL, or any data...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                    suffixIcon: Icon(Icons.qr_code, color: Colors.blue),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
