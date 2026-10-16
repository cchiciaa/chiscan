enum CameraPermissionStatus {
  granted,
  denied,
  cancelled,
}

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final int price;
  final int quantity;

  int get totalPrice => price * quantity;
}

class ReceiptScanResult {
  const ReceiptScanResult({
    required this.isSuccess,
    this.merchantName,
    this.items = const [],
    this.totalAmount = 0,
    this.errorMessage,
    this.isCancelled = false,
    this.isPermissionDenied = false,
  });

  final bool isSuccess;
  final String? merchantName;
  final List<ReceiptItem> items;
  final int totalAmount;
  final String? errorMessage;
  final bool isCancelled;
  final bool isPermissionDenied;

  factory ReceiptScanResult.cancelled() => const ReceiptScanResult(
        isSuccess: false,
        isCancelled: true,
        errorMessage: 'Pemindaian struk dibatalkan oleh pengguna.',
      );

  factory ReceiptScanResult.permissionDenied() => const ReceiptScanResult(
        isSuccess: false,
        isPermissionDenied: true,
        errorMessage: 'Izin kamera ditolak. Silakan berikan izin di pengaturan perangkat.',
      );

  factory ReceiptScanResult.failure(String message) => ReceiptScanResult(
        isSuccess: false,
        errorMessage: message,
      );

  factory ReceiptScanResult.success({
    required String merchantName,
    required List<ReceiptItem> items,
  }) {
    final total = items.fold<int>(0, (sum, item) => sum + item.totalPrice);
    return ReceiptScanResult(
      isSuccess: true,
      merchantName: merchantName,
      items: items,
      totalAmount: total,
    );
  }
}

class CameraScanService {
  CameraScanService({CameraPermissionStatus initialPermission = CameraPermissionStatus.granted})
      : _permissionStatus = initialPermission;

  CameraPermissionStatus _permissionStatus;

  CameraPermissionStatus get permissionStatus => _permissionStatus;

  Future<CameraPermissionStatus> requestCameraPermission() async {
    // Simulasi pemeriksaan status izin kamera pada device
    return _permissionStatus;
  }

  void setPermissionStatusForTesting(CameraPermissionStatus status) {
    _permissionStatus = status;
  }

  Future<ReceiptScanResult> captureAndScanReceipt({bool simulateUserCancellation = false}) async {
    if (simulateUserCancellation) {
      return ReceiptScanResult.cancelled();
    }

    if (_permissionStatus != CameraPermissionStatus.granted) {
      return ReceiptScanResult.permissionDenied();
    }

    // Simulasi delay pemrosesan citra struk via OCR
    await Future<void>.delayed(const Duration(milliseconds: 150));

    return ReceiptScanResult.success(
      merchantName: 'Kopi Kenangan Senopati',
      items: const [
        ReceiptItem(name: 'Kopi Kenangan Mantan', price: 22000, quantity: 2),
        ReceiptItem(name: 'Roti Coklat Klasik', price: 14000, quantity: 1),
        ReceiptItem(name: 'Americano Dingin', price: 18000, quantity: 1),
      ],
    );
  }
}
