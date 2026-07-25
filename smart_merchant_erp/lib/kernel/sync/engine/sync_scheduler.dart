import 'dart:async';
import '../../network/connectivity/network_monitor.dart';

/// Events that trigger background processing of the synchronization queue.
enum SyncScheduleTrigger {
  /// User or cashier initiated a manual sync request from the UI.
  manualSync,

  /// Application finished cold start and initialized its dependency injection container.
  applicationStartup,

  /// Physical device connectivity transitioned from offline to online.
  connectivityRestored,

  /// Periodic background check interval elapsed.
  periodicBackgroundCheck,

  /// Application transitioned from background to active foreground state.
  applicationResume,
}

/// Contract for scheduling and triggering background synchronization runs.
abstract interface class SyncSchedulerContract {
  /// Manually dispatches a synchronization trigger.
  void trigger(SyncScheduleTrigger triggerType);

  /// Starts a periodic background timer emitting [SyncScheduleTrigger.periodicBackgroundCheck].
  void startPeriodicCheck(Duration interval);

  /// Stops the active periodic check timer.
  void stopPeriodicCheck();

  /// Stream emitting schedule triggers for the background worker to consume.
  Stream<SyncScheduleTrigger> get onTriggered;
}

/// Configurable scheduler listening to connectivity changes, timers, and lifecycle events.
class SyncScheduler implements SyncSchedulerContract {
  final StreamController<SyncScheduleTrigger> _triggerController =
      StreamController<SyncScheduleTrigger>.broadcast();
  final NetworkMonitorContract? _networkMonitor;
  StreamSubscription<NetworkStatus>? _networkSubscription;
  Timer? _periodicTimer;
  bool _isRunning = false;

  SyncScheduler({NetworkMonitorContract? networkMonitor})
    : _networkMonitor = networkMonitor {
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    final monitor = _networkMonitor;
    if (monitor == null) {
      return;
    }
    _networkSubscription = monitor.onStatusChanged.listen((status) {
      if (status == NetworkStatus.online) {
        trigger(SyncScheduleTrigger.connectivityRestored);
      }
    });
  }

  @override
  void trigger(SyncScheduleTrigger triggerType) {
    if (_triggerController.isClosed) {
      return;
    }
    _triggerController.add(triggerType);
  }

  @override
  void startPeriodicCheck(Duration interval) {
    stopPeriodicCheck();
    _isRunning = true;
    _periodicTimer = Timer.periodic(interval, (_) {
      if (_isRunning) {
        trigger(SyncScheduleTrigger.periodicBackgroundCheck);
      }
    });
  }

  @override
  void stopPeriodicCheck() {
    _isRunning = false;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  @override
  Stream<SyncScheduleTrigger> get onTriggered => _triggerController.stream;

  /// Disposes timers and stream subscriptions upon shutdown.
  void dispose() {
    stopPeriodicCheck();
    _networkSubscription?.cancel();
    _triggerController.close();
  }
}
