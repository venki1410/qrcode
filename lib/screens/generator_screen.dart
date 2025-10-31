import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/storage_service.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  static const double _qrMaxSize = 250.0;
  static const double _embeddedOverlaySize = 60.0; // fixed center logo size
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String _qrData = '';
  Color _foregroundColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _qrSize = _qrMaxSize;
  Timer? _debounceTimer;
  XFile? _embeddedImage;
  ui.Image? _embeddedImageData;
  Uint8List? _embeddedImageBytes;

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
          _qrData = _textController.text.isNotEmpty ? _textController.text : '';
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    _labelController.dispose();
    _embeddedImageData?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
      );
      
      if (image != null) {
        setState(() {
          _embeddedImage = image;
        });
        _loadImageData(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _loadImageData(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      
      setState(() {
        _embeddedImageData?.dispose();
        _embeddedImageData = frameInfo.image;
        _embeddedImageBytes = imageBytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
      }
    }
  }

  void _removeEmbeddedImage() {
    setState(() {
      _embeddedImage = null;
      _embeddedImageData?.dispose();
      _embeddedImageData = null;
      _embeddedImageBytes = null;
    });
  }

  void _showForegroundColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick Foreground Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _foregroundColor,
              onColorChanged: (Color color) {
                setState(() {
                  _foregroundColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick Background Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _backgroundColor,
              onColorChanged: (Color color) {
                setState(() {
                  _backgroundColor = color;
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
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
    // Use higher error correction when embedded image is present
    final errorCorrectionLevel = _embeddedImageData != null 
        ? QrErrorCorrectLevel.H 
        : QrErrorCorrectLevel.L;
    
    final qrValidationResult = QrValidator.validate(
      data: _qrData,
      version: QrVersions.auto,
      errorCorrectionLevel: errorCorrectionLevel,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: _foregroundColor,
        emptyColor: Colors.white, // Use white for QR code background
        gapless: true,
        embeddedImage: _embeddedImageData,
        embeddedImageStyle: _embeddedImageData != null
            ? const QrEmbeddedImageStyle(
                size: Size(60, 60),
              )
            : null,
      );

      final double renderSize = math.min(_qrSize, _qrMaxSize);
      final padding = 40.0; // Padding around QR code
      final qrTotalSize = renderSize + (padding * 2);
      
      // Calculate label height if label exists
      double labelHeight = 0.0;
      double labelSpace = 0.0;
      if (_labelController.text.isNotEmpty) {
        labelSpace = 12.0; // Reduced space above label
        final textPainter = TextPainter(
          text: TextSpan(
            text: _labelController.text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _foregroundColor,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: qrTotalSize - (padding * 2));
        labelHeight = textPainter.height;
      }
      
      final totalHeight = qrTotalSize + labelSpace + labelHeight + padding;

      // Generate QR code image
      final qrPicData = await painter.toImageData(renderSize);
      final qrImage = await decodeImageFromList(qrPicData!.buffer.asUint8List());

      // Create a new image with padding and label
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Fill background with white
      canvas.drawRect(
        Rect.fromLTWH(0, 0, qrTotalSize, totalHeight),
        Paint()..color = Colors.white,
      );
      
      // Draw QR code in the center (horizontally)
      canvas.drawImage(
        qrImage,
        Offset(padding, padding),
        Paint(),
      );
      
      // Draw label text below QR code if it exists
      if (_labelController.text.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: _labelController.text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _foregroundColor,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: qrTotalSize - (padding * 2));
        // Center the text horizontally
        final textX = (qrTotalSize - textPainter.width) / 2;
        textPainter.paint(
          canvas,
          Offset(
            textX,
            qrTotalSize + labelSpace,
          ),
        );
      }
      
      // Convert to image
      final picture = recorder.endRecording();
      final paddedImage = await picture.toImage(qrTotalSize.toInt(), totalHeight.toInt());
      final byteData = await paddedImage.toByteData(format: ui.ImageByteFormat.png);
      
      qrImage.dispose();
      
      return byteData!.buffer.asUint8List();
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
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      QrImageView(
                                        data: _qrData,
                                        version: QrVersions.auto,
                                        size: math.min(_qrSize, _qrMaxSize),
                                        foregroundColor: _foregroundColor,
                                        backgroundColor: _backgroundColor,
                                        errorCorrectionLevel: _embeddedImageBytes != null 
                                            ? QrErrorCorrectLevel.H 
                                            : QrErrorCorrectLevel.L,
                                        embeddedImage: _embeddedImageBytes != null
                                            ? MemoryImage(_embeddedImageBytes!)
                                            : null,
                                        embeddedImageStyle: _embeddedImageBytes != null
                                            ? const QrEmbeddedImageStyle(
                                                size: Size(_embeddedOverlaySize, _embeddedOverlaySize),
                                              )
                                            : null,
                                      ),
                                      if (_labelController.text.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          _labelController.text,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _foregroundColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
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
                              ElevatedButton.icon(
                                onPressed: _saveQRCode,
                                icon: const Icon(Icons.save, color: Colors.black),
                                label: const Text('Save', style: TextStyle(color: Colors.black)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
                                  ),
                                ),
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
                                    OutlinedButton(
                                      onPressed: _showForegroundColorPicker,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: _foregroundColor,
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: const Color(0xFFE5E5E5)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '#${_foregroundColor.value.toRadixString(16).substring(2).toUpperCase()}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
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
                                    OutlinedButton(
                                      onPressed: _showBackgroundColorPicker,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: _backgroundColor,
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: const Color(0xFFE5E5E5)),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '#${_backgroundColor.value.toRadixString(16).substring(2).toUpperCase()}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.chevron_right),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Label Text',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _labelController,
                            decoration: const InputDecoration(
                              hintText: 'Enter label text to show below QR code',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Embedded Image',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (_embeddedImage != null) ...[
                                Expanded(
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_embeddedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _removeEmbeddedImage,
                                  tooltip: 'Remove image',
                                ),
                              ] else
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.image),
                                    label: const Text('Upload Image'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_embeddedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Image will be placed at the center of QR code',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
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
                  decoration: InputDecoration(
                    hintText: 'Type here...',
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    prefixIcon: Icon(
                      Icons.qr_code,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2.5,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(6)),
                    ),
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
