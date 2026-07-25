import 'dart:async';

/// Represents the active operational lifecycle state of the synchronization engine.
enum SyncStateMachineState {
  /// Engine is inactive and waiting for trigger events or network restoration.
  idle,

  /// Engine is validating queues, checking connectivity, and preparing batch payloads.
  preparing,

  /// Engine is actively transmitting local offline records to the Laravel cloud API.
  uploading,

  /// Engine is fetching remote server changes and dictionaries.
  downloading,

  /// Engine is evaluating version metadata, ETag checksums, and revision numbers.
  comparing,

  /// Engine identified one or more concurrency conflicts requiring resolution.
  conflictDetected,

  /// Engine is executing configured policies (`ServerWins`, `ClientWins`, `Merge`).
  resolving,

  /// Engine is combining non-conflicting dictionary fields via the merge engine.
  merging,

  /// Synchronization cycle completed successfully across both upload and download directions.
  completed,

  /// Synchronization cycle encountered a fatal error or network disconnection.
  failed,

  /// Synchronization cycle was explicitly aborted before finishing.
  cancelled,
}

/// Manages and broadcasts transitions across synchronization engine lifecycle states.
class SyncStateMachine {
  final StreamController<SyncStateMachineState> _stateController =
      StreamController<SyncStateMachineState>.broadcast();
  SyncStateMachineState _currentState = SyncStateMachineState.idle;

  /// Retrieves the instantaneous state of the synchronization engine.
  SyncStateMachineState get currentState => _currentState;

  /// Stream emitting state updates whenever the engine transitions.
  Stream<SyncStateMachineState> get onStateChanged => _stateController.stream;

  /// Transitions the engine to [newState] and notifies broadcast listeners.
  void transitionTo(SyncStateMachineState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Disposes broadcast controller resources upon application shutdown.
  void dispose() {
    _stateController.close();
  }
}
