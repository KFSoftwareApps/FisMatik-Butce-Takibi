import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Function(String message, bool isSuccess)? onPurchaseCompleted;

  void init() {
    // Web'de mağaza dinleyicisi yoktur.
  }

  Future<void> buyProduct(String tierId) async {
    // Web platformunda doğrudan Shopier linkine yönlendiriyoruz
    await openWebPaymentLink(tierId);
  }

  Future<void> openWebPaymentLink(String tierId) async {
    final Map<String, String> customWebLinks = {
      'premium': 'https://www.shopier.com/kfsoftware/42431387',
      'limitless': 'https://www.shopier.com/kfsoftware/42431458',
      'limitless_family': 'https://www.shopier.com/kfsoftware/42431491',
    };

    final String? shopierLink = customWebLinks[tierId];
    if (shopierLink != null && shopierLink.isNotEmpty) {
      final Uri url = Uri.parse(shopierLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void dispose() {}
}
