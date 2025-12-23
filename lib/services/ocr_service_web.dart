import 'package:image_picker/image_picker.dart';

class OcrService {
  Future<String> scanReceipt(XFile imageFile) async {
    // Web'de OCR şimdilik desteklenmiyor, doğrudan AI'ya gönderiliyor.
    return "Web Image Uploaded";
  }

  void dispose() {
    // Web'de temizlenecek bir şey yok.
  }
}
