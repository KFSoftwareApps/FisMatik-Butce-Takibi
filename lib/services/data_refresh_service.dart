import 'dart:async';

class DataRefreshService {
  static final DataRefreshService _instance = DataRefreshService._internal();
  factory DataRefreshService() => _instance;
  DataRefreshService._internal();

  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  void notifyUpdate() {
    _updateController.add(null);
  }

  void dispose() {
    _updateController.close();
  }
}
