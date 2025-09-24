import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QRCodeData {
  final String id;
  final String data;
  final String title;
  final DateTime createdAt;
  final String type; // 'scanned' or 'generated'

  QRCodeData({
    required this.id,
    required this.data,
    required this.title,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      id: json['id'],
      data: json['data'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      type: json['type'],
    );
  }
}

class StorageService {
  static const String _qrCodesKey = 'saved_qr_codes';

  static Future<List<QRCodeData>> getSavedQRCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? qrCodesJson = prefs.getString(_qrCodesKey);
    
    if (qrCodesJson == null) {
      return [];
    }

    try {
      final List<dynamic> qrCodesList = json.decode(qrCodesJson);
      return qrCodesList
          .map((json) => QRCodeData.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveQRCode(String data, String title, {String type = 'generated'}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<QRCodeData> existingCodes = await getSavedQRCodes();
    
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final QRCodeData newCode = QRCodeData(
      id: id,
      data: data,
      title: title,
      createdAt: DateTime.now(),
      type: type,
    );

    existingCodes.insert(0, newCode); // Add to beginning of list
    
    final List<Map<String, dynamic>> qrCodesJson = 
        existingCodes.map((code) => code.toJson()).toList();
    
    await prefs.setString(_qrCodesKey, json.encode(qrCodesJson));
  }

  static Future<void> deleteQRCode(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<QRCodeData> existingCodes = await getSavedQRCodes();
    
    existingCodes.removeWhere((code) => code.id == id);
    
    final List<Map<String, dynamic>> qrCodesJson = 
        existingCodes.map((code) => code.toJson()).toList();
    
    await prefs.setString(_qrCodesKey, json.encode(qrCodesJson));
  }

  static Future<void> clearAllQRCodes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_qrCodesKey);
  }

  static Future<QRCodeData?> getQRCodeById(String id) async {
    final List<QRCodeData> codes = await getSavedQRCodes();
    try {
      return codes.firstWhere((code) => code.id == id);
    } catch (e) {
      return null;
    }
  }
}
