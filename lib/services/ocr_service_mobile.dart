import 'dart:io';
import 'package:flutter/foundation.dart'; // [NEW] kIsWeb
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  // Metin tanıyıcıyı başlat (Latin alfabesi - Türkçe/İngilizce için)
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> scanReceipt(XFile imageFile) async {
    // Web platformunda OCR (şimdilik) desteklenmiyor
    // Ancak kullanıcı fotoğraf ekleyip manuel devam edebilir.
    if (kIsWeb) {
      // TODO: Web için OCR çözümü (Tesseract.js vb.) eklenebilir.
      return "Web Image Uploaded"; 
    }

    try {
      // 1. Resmi ML Kit'in anlayacağı formata çevir
      final inputImage = InputImage.fromFile(File(imageFile.path));

      // 2. İşlemi başlat ve sonucu bekle
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // 3. Sadece metni döndür
      return recognizedText.text;
    } catch (e) {
      return "Hata: Okuma başarısız oldu. ($e)";
    }
  }

  // İşimiz bitince kapatmak için (Hafıza sızıntısını önler)
  void dispose() {
    _textRecognizer.close();
  }
}
