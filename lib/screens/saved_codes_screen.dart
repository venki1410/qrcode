import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import '../services/storage_service.dart';

class SavedCodesScreen extends StatefulWidget {
  const SavedCodesScreen({super.key});

  @override
  State<SavedCodesScreen> createState() => _SavedCodesScreenState();
}

class _SavedCodesScreenState extends State<SavedCodesScreen> {
  List<QRCodeData> _savedCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCodes();
  }

  Future<void> _loadSavedCodes() async {
    setState(() {
      _isLoading = true;
    });
    
    final codes = await StorageService.getSavedQRCodes();
    setState(() {
      _savedCodes = codes;
      _isLoading = false;
    });
  }

  Future<void> _deleteQRCode(String id) async {
    await StorageService.deleteQRCode(id);
    _loadSavedCodes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code deleted')),
      );
    }
  }

  Future<void> _shareQRCode(String data) async {
    try {
      // Generate QR code image
      final qrImage = await _generateQRImage(data);
      
      // Save image to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(qrImage);
      
      // Share both text and image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: data,
        subject: 'QR Code',
      );
    } catch (e) {
      // Fallback to text-only sharing if image generation fails
      await Share.share(
        data,
        subject: 'QR Code',
      );
    }
  }

  Future<Uint8List> _generateQRImage(String data) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      
      // QR code size and padding
      final qrSize = 300.0;
      final padding = 40.0;
      final totalSize = qrSize + (padding * 2);
      
      // Create QR painter
      final qrPainter = QrPainter.withQr(
        qr: qrCode,
        color: Colors.black,
        emptyColor: Colors.white,
        gapless: false,
      );

      // Generate QR code image with padding
      final picData = await qrPainter.toImageData(totalSize);
      return picData!.buffer.asUint8List();
    }
    throw Exception('Invalid QR Code data');
  }

  Future<void> _clearAllCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Codes'),
          content: const Text('Are you sure you want to delete all saved QR codes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await StorageService.clearAllQRCodes();
      _loadSavedCodes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All QR codes deleted')),
        );
      }
    }
  }

  void _showQRCodeDetails(QRCodeData qrCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(qrCode.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: qrCode.data,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Content:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  qrCode.data,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Created: ${_formatDate(qrCode.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Type: ${qrCode.type}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrCode.data));
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      _shareQRCode(qrCode.data);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteQRCode(qrCode.id);
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved QR Codes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_savedCodes.isNotEmpty)
            IconButton(
              onPressed: _clearAllCodes,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedCodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved QR codes',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan or generate QR codes to see them here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedCodes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedCodes.length,
                    itemBuilder: (context, index) {
                      final qrCode = _savedCodes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: QrImageView(
                              data: qrCode.data,
                              version: QrVersions.auto,
                              size: 50,
                            ),
                          ),
                          title: Text(
                            qrCode.data,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                qrCode.type == 'scanned'
                                    ? Icons.qr_code_scanner
                                    : Icons.qr_code,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${qrCode.type} • ${_formatDate(qrCode.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'copy') {
                                Clipboard.setData(ClipboardData(text: qrCode.data));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied to clipboard')),
                                );
                              } else if (value == 'share') {
                                _shareQRCode(qrCode.data);
                              } else if (value == 'delete') {
                                _deleteQRCode(qrCode.id);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'copy',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy),
                                    SizedBox(width: 8),
                                    Text('Copy'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showQRCodeDetails(qrCode),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

