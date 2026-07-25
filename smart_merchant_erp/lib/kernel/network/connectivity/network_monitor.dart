import 'dart:async';

/// Represents the physical network connectivity status of the device running the ERP application.
enum NetworkStatus {
  /// Device has active network connectivity and can communicate with the Laravel cloud server.
  online,

  /// Device is disconnected from the network (`Offline-First mode`).
  offline,

  /// Connectivity status is currently being determined or initializing.
  unknown,
}

/// Abstract contract decoupling network monitoring detection from business logic and sync scheduling.
abstract interface class NetworkMonitorContract {
  /// Retrieves the current instantaneous network status.
  Future<NetworkStatus> get currentStatus;

  /// Stream emitting connectivity updates whenever the network status transitions.
  Stream<NetworkStatus> get onStatusChanged;
}

/// Standard implementation of [NetworkMonitorContract] managing connectivity stream notifications.
class NetworkMonitorImpl implements NetworkMonitorContract {
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.online;

  @override
  Future<NetworkStatus> get currentStatus async => _currentStatus;

  @override
  Stream<NetworkStatus> get onStatusChanged => _statusController.stream;

  /// Internal hook for device platform adapters or connectivity plugins to push status updates.
  void updateStatus(NetworkStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }
  }

  /// Disposes internal broadcast controller resources.
  void dispose() {
    _statusController.close();
  }
}
