import 'dart:async';
import 'rx_debug.dart';

/// Event priority.
///
/// Determines dispatch order:
/// high → normal → low
enum EventPriority { high, normal, low }

/// Callback signature for event listeners.
///
/// Parameters:
/// - eventID: event identifier
/// - uuid: unique event instance identifier
/// - data: event payload
typedef EventCallback<T> = Future<void> Function(
  int eventID,
  String uuid,
  T data,
);

/// Token used to unregister listeners.
///
/// Each token instance represents
/// a unique listener registration.
class EventToken {
  final String id = DateTime.now().microsecondsSinceEpoch.toString();
}

/// Internal wrapper used to store listener metadata.
class _EventWrapper {
  /// Wrapped callback with dynamic payload support.
  final Future<void> Function(int eventID, String uuid, dynamic data) wrapperCallback;

  /// Original callback reference.
  ///
  /// Used when removing listeners.
  final dynamic originalCallback;

  /// Optional listener token.
  final EventToken? token;

  _EventWrapper({required this.wrapperCallback, required this.originalCallback, this.token});
}

/// Internal event dispatch task.
class _EventTask {
  /// Module name.
  final String module;

  /// Event identifier.
  final int eventID;

  /// Event payload.
  final dynamic data;

  /// Event instance identifier.
  final String uuid;

  /// Dispatch priority.
  final EventPriority priority;

  /// Whether listeners should be executed in parallel.
  final bool parallel;

  _EventTask({
    required this.module,
    required this.eventID,
    required this.data,
    required this.uuid,
    required this.priority,
    required this.parallel,
  });
}

/// Global event bus.
///
/// Supports:
/// - Event publishing
/// - Event subscriptions
/// - One-time listeners
/// - Sticky events
/// - Priority scheduling
/// - Parallel dispatch
/// - Sequential dispatch
///
/// Example:
///
/// ```dart
/// RxEventBus.on<String>(
///   module: 'chat',
///   eventID: 1,
///   callback: (id, uuid, msg) async {
///     print(msg);
///   },
/// );
///
/// RxEventBus.notify(
///   module: 'chat',
///   eventID: 1,
///   data: 'Hello',
/// );
/// ```
class RxEventBus {
  /// Registered listeners.
  ///
  /// Structure:
  /// module -> eventID -> listeners
  static final Map<String, Map<int, List<_EventWrapper>>> _listeners = {};

  /// Sticky event cache.
  ///
  /// Stores the most recent sticky event
  /// for each module and event identifier.
  static final Map<String, Map<int, dynamic>> _sticky = {};

  /// Pending dispatch queue.
  static final List<_EventTask> _queue = [];

  /// Whether the queue is currently being processed.
  static bool _isProcessing = false;

  /// Registers an event listener.
  ///
  /// Parameters:
  /// - [module] Module name.
  /// - [eventID] Event identifier.
  /// - [callback] Listener callback.
  /// - [token] Optional token for later removal.
  /// - [sticky] Immediately receives the latest sticky event if available.
  static void on<T>({
    required String module,
    required int eventID,
    required EventCallback<T> callback,
    EventToken? token,
    bool sticky = false,
  }) {
    final moduleMap = _listeners.putIfAbsent(module, () => {});
    final list = moduleMap.putIfAbsent(eventID, () => []);

    if (list.any((e) => e.originalCallback == callback)) {
      RxDebug.log(
        '[$module] Listener already registered for event $eventID',
      );
      return;
    }

    final wrapper = _EventWrapper(
      wrapperCallback: (id, uuid, data) async {
        return await callback(id, uuid, data as T);
      },
      originalCallback: callback,
      token: token,
    );

    list.add(wrapper);

    if (sticky && _sticky[module]?[eventID] != null) {
      final stickyData = _sticky[module]![eventID];
      Future.microtask(() {
        try {
          callback(eventID, "sticky", stickyData as T);
        } catch (e) {
          RxDebug.log(' Sticky callback error: $e');
        }
      });
    }
  }

  /// Dispatches an event.
  ///
  /// Parameters:
  /// - [module] Module name.
  /// - [eventID] Event identifier.
  /// - [data] Event payload.
  /// - [uuid] Optional event instance identifier.
  /// - [priority] Dispatch priority.
  /// - [parallel] Whether listeners execute concurrently.
  /// - [sticky] Whether to cache as a sticky event.
  /// - [delay] Optional dispatch delay.
  static void notify<T>({
    required String module,
    required int eventID,
    required T data,
    String uuid = "",
    EventPriority priority = EventPriority.normal,
    bool parallel = true,
    bool sticky = false,
    Duration? delay,
  }) {
    if (sticky) {
      _sticky.putIfAbsent(module, () => {})[eventID] = data;
    }

    final task = _EventTask(
      module: module,
      eventID: eventID,
      data: data,
      uuid: uuid,
      priority: priority,
      parallel: parallel,
    );

    if (delay != null) {
      Future.delayed(delay, () => _enqueue(task));
    } else {
      _enqueue(task);
    }
  }

  /// RxEventBus.once`<String>`(
  ///   module: 'chat',
  ///   eventID: 2,
  ///   callback: (id, uuid, msg) async {
  ///     print('Received once: $msg');
  ///   },
  /// );
  /// Registers a one-time event listener.
  ///
  /// The listener is automatically removed
  /// after receiving the first event.
  static void once<T>({
    required String module,
    required int eventID,
    required EventCallback<T> callback,
    bool sticky = false,
  }) {
    late EventCallback<T> wrapper;

    wrapper = (
      int id,
      String uuid,
      T data,
    ) async {
      off(
        module: module,
        eventID: eventID,
        callback: wrapper,
      );

      await callback(
        id,
        uuid,
        data,
      );
    };

    on<T>(
      module: module,
      eventID: eventID,
      callback: wrapper,
      sticky: sticky,
    );
  }

  ///Join the team internally
  static void _enqueue(_EventTask task) {
    _queue.add(task);
    _queue.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    _processQueue();
  }

  ///internal processing queue
  static void _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      final listeners = _listeners[task.module]?[task.eventID];
      if (listeners == null || listeners.isEmpty) continue;

      RxDebug.log(" Distribution event ${task.eventID} (${task.priority})");

      if (task.parallel) {
        await Future.wait(
          listeners.map((e) async {
            try {
              await e.wrapperCallback(task.eventID, task.uuid, task.data);
            } catch (e, s) {
              RxDebug.log(' Concurrent execution error: $e\n$s');
            }
          }),
        );
      } else {
        for (final e in List.from(listeners)) {
          try {
            await e.wrapperCallback(task.eventID, task.uuid, task.data);
          } catch (e, s) {
            RxDebug.log(' Serial execution error: $e\n$s');
          }
        }
      }
    }

    _isProcessing = false;
  }

  /// Removes event listeners.
  ///
  /// If [callback] is null,
  /// all listeners registered for the specified
  /// module and event identifier are removed.
  static void off({required String module, required int eventID, dynamic callback}) {
    final list = _listeners[module]?[eventID];
    if (list == null) return;

    if (callback == null) {
      list.clear();
    } else {
      list.removeWhere((e) => e.originalCallback == callback);
    }
  }

  /// Removes all listeners associated
  /// with the specified [token].
  static void offByToken(EventToken token) {
    for (final moduleMap in _listeners.values) {
      for (final list in moduleMap.values) {
        list.removeWhere((e) => e.token == token);
      }
    }
    RxDebug.log('The listener has been removed through Token.');
  }

  /// Clears all listeners,
  /// sticky events,
  /// and pending tasks.
  static void clearAll() {
    _listeners.clear();
    _sticky.clear();
    _queue.clear();
    RxDebug.log('Empty event bus.');
  }
}
