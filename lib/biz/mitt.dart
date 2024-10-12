typedef EventType = String;

typedef Handler<T> = void Function(T event);
typedef WildcardHandler<T> = void Function(EventType type, T event);

class EventEmitter<Events extends Map<EventType, dynamic>> {
  Map<EventType, List<dynamic>> _handlers = {};

  /// Register an event handler for a specific type.
  void on<Key extends EventType>(Key type, Handler handler) {
    _handlers[type] ??= [];
    _handlers[type]!.add(handler);
  }

  /// Remove an event handler for a specific type.
  void off<Key extends EventType>(Key type, Handler? handler) {
    if (handler != null && _handlers[type] != null) {
      _handlers[type]!.remove(handler);
    } else {
      _handlers[type]?.clear();
    }
  }

  /// Emit an event of a specific type.
  void emit<Key extends EventType>(Key type, Events event) {
    final handlers = _handlers[type];
    if (handlers != null) {
      for (final handler in List.from(handlers)) {
        if (handler is Handler) {
          handler(event);
        }
      }
    }
  }

  void dispose() {
    _handlers = {};
  }
}
