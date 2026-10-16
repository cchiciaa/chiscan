enum LocationPermissionStatus {
  granted,
  denied,
  cancelled,
}

class RestaurantLocation {
  const RestaurantLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
}

class LocationResult {
  const LocationResult({
    required this.isSuccess,
    this.location,
    this.errorMessage,
    this.isCancelled = false,
    this.isPermissionDenied = false,
  });

  final bool isSuccess;
  final RestaurantLocation? location;
  final String? errorMessage;
  final bool isCancelled;
  final bool isPermissionDenied;

  factory LocationResult.cancelled() => const LocationResult(
        isSuccess: false,
        isCancelled: true,
        errorMessage: 'Pencarian lokasi dibatalkan oleh pengguna.',
      );

  factory LocationResult.permissionDenied() => const LocationResult(
        isSuccess: false,
        isPermissionDenied: true,
        errorMessage: 'Izin lokasi perangkat tidak diizinkan. Silakan aktifkan izin lokasi.',
      );

  factory LocationResult.failure(String message) => LocationResult(
        isSuccess: false,
        errorMessage: message,
      );

  factory LocationResult.success(RestaurantLocation location) => LocationResult(
        isSuccess: true,
        location: location,
      );
}

class LocationService {
  LocationService({LocationPermissionStatus initialPermission = LocationPermissionStatus.granted})
      : _permissionStatus = initialPermission;

  LocationPermissionStatus _permissionStatus;

  LocationPermissionStatus get permissionStatus => _permissionStatus;

  void setPermissionStatusForTesting(LocationPermissionStatus status) {
    _permissionStatus = status;
  }

  Future<LocationPermissionStatus> requestLocationPermission() async {
    return _permissionStatus;
  }

  Future<LocationResult> detectCurrentRestaurantLocation({
    bool simulateUserCancellation = false,
    bool simulateGpsDisabled = false,
  }) async {
    if (simulateUserCancellation) {
      return LocationResult.cancelled();
    }

    if (_permissionStatus != LocationPermissionStatus.granted) {
      return LocationResult.permissionDenied();
    }

    if (simulateGpsDisabled) {
      return LocationResult.failure('Layanan GPS perangkat sedang dinonaktifkan.');
    }

    // Simulasi delay pembacaan satelit GPS & reverse geocoding
    await Future<void>.delayed(const Duration(milliseconds: 150));

    return LocationResult.success(
      const RestaurantLocation(
        name: 'Sederhana Bintaro Sektor 9',
        address: 'Jl. Bintaro Utama 9 No. 12, Tangerang Selatan',
        latitude: -6.2842,
        longitude: 106.7118,
      ),
    );
  }
}
