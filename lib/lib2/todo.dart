// main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:collection';

/// ---------- Models ----------
class Todo {
  final String id;
  String title;
  String? note;
  DateTime updatedAt;
  int version; // incremental, helps merges
  String updatedBy; // device id
  final bool isDeleted;

  Todo({
    required this.id,
    required this.title,
    this.note,
    DateTime? updatedAt,
    int? version,
    required this.updatedBy,
    this.isDeleted = false,
  })  : updatedAt = updatedAt ?? DateTime.now().toUtc(),
        version = version ?? 0;

  Todo copyWith({
    String? title,
    String? note,
    DateTime? updatedAt,
    int? version,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
        'version': version,
        'updatedBy': updatedBy,
        'isDeleted': isDeleted,
      };

  static Todo fromJson(Map<String, dynamic> js) => Todo(
        id: js['id'],
        title: js['title'],
        note: js['note'],
        updatedAt: DateTime.parse(js['updatedAt']).toUtc(),
        version: js['version'],
        updatedBy: js['updatedBy'],
        isDeleted: js['isDeleted'] ?? false,
      );

  @override
  String toString() => jsonEncode(toJson());
}

/// ---------- Interfaces (SOLID) ----------
abstract class ILocalStore {
  Future<void> saveTodo(Todo todo);
  Future<void> deleteTodo(String id); // 👈 now real delete (tombstone)
  Future<List<Todo>> getAll();
}

/// Simple in-memory store (for demo) — replace with Hive/SQLite for production
class InMemoryLocalStore implements ILocalStore {
  final Map<String, Todo> _map = {};
  @override
  Future<void> saveTodo(Todo todo) async {
    _map[todo.id] = todo;
  }

  @override
  Future<void> deleteTodo(String id) async {
    _map.remove(id);
  }

  @override
  Future<List<Todo>> getAll() async => _map.values.toList();
}

/// Event payload for pub-sub
class TodoEvent {
  final String originDeviceId;
  final Todo todo;
  final String type; // "update" | "delete"

  TodoEvent({
    required this.originDeviceId,
    required this.todo,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'originDeviceId': originDeviceId,
        'todo': todo.toJson(),
        'type': type,
      };

  static TodoEvent fromJson(Map<String, dynamic> js) => TodoEvent(
        originDeviceId: js['originDeviceId'],
        todo: Todo.fromJson(Map<String, dynamic>.from(js['todo'])),
        type: js['type'],
      );
}

/// ---------- Event Manager (pub-sub) + Mock WebSocket ----------
class EventManager {
  // Single broadcast stream for all devices. In real world this is ws server.
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  // Publish an event to the "network"
  void publishJson(String jsonPayload) {
    _controller.add(jsonPayload);
  }

  // close if needed
  Future<void> dispose() async {
    await _controller.close();
  }
}

/// MockWebSocket simulates network latency, online/offline toggles,
/// and relays events between devices.
class MockWebSocket {
  final EventManager manager;
  bool online = true;
  Duration latency;

  MockWebSocket({
    required this.manager,
    this.latency = const Duration(milliseconds: 600),
  });

  // Subscribe for incoming events (device will filter by itself)
  StreamSubscription subscribe(void Function(String) onData) {
    return manager.stream.listen((payload) {
      if (!online) return; // simulate network down
      // simulate latency
      Future.delayed(latency, () => onData(payload));
    });
  }

  // Send an outgoing event
  Future<void> send(String payload) async {
    if (!online) return;
    await Future.delayed(latency);
    manager.publishJson(payload);
  }
}

/// ---------- Debouncer (so we don't publish every keystroke) ----------
class Debouncer {
  final Duration delay;
  Timer? _timer;
  Debouncer({this.delay = const Duration(milliseconds: 700)});
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// ---------- SyncEngine + Repository ----------
/// SyncEngine is responsible for:
/// - Observing local edits
/// - Debouncing before publishing to event manager (when online)
/// - Receiving incoming events and merging into local store
class SyncEngine {
  final String deviceId;
  final ILocalStore localStore;
  final MockWebSocket socket;
  final ValueNotifier<List<Todo>> localTodosNotifier;

  final Debouncer _debouncer = Debouncer();
  final Queue<TodoEvent> _pendingSends = Queue();

  late final StreamSubscription _sub;

  SyncEngine({
    required this.deviceId,
    required this.localStore,
    required this.socket,
    required this.localTodosNotifier,
  }) {
    // subscribe to network events
    _sub = socket.subscribe((payload) {
      try {
        final parsed = jsonDecode(payload) as Map<String, dynamic>;
        final event = TodoEvent.fromJson(parsed);
        // ignore events that came FROM ME (we already applied)
        if (event.originDeviceId == deviceId) return;
        _handleIncoming(event);
      } catch (e) {
        debugPrint("Malformed event payload: $e");
      }
    });
  }

  void dispose() {
    _sub.cancel();
    _debouncer.cancel();
  }

  /// Called when local user edits a todo
  Future<void> onLocalEdit(Todo t) async {
    // increment version & updatedAt
    final newVersion = t.version + 1;
    final updated = t.copyWith(
      version: newVersion,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: deviceId,
    );
    // persist locally first (offline-first)
    await localStore.saveTodo(updated);
    await _refreshLocalNotifier();

    // queue the item to be sent after debounce
    _pendingSends.removeWhere(
      (e) => e.todo.id == updated.id,
    ); // replace existing
    _pendingSends.add(
      TodoEvent(type: 'update', todo: updated, originDeviceId: deviceId),
    );

    // debounce sending; after settle, send all pending
    _debouncer.call(() async {
      if (!socket.online) {
        // remain queued; will be retried when network toggles; for demo we leave it here
        debugPrint(
          "$deviceId: offline - holding ${_pendingSends.length} items",
        );
        return;
      }
      while (_pendingSends.isNotEmpty) {
        final next = _pendingSends.removeFirst();
        // final event = TodoEvent(
        //   originDeviceId: deviceId,
        //   todo: next.todo,
        //   type: next.type,
        // );
        await socket.send(jsonEncode(next.toJson()));
      }
    });
  }

  /// Called when an event arrives from other device
  Future<void> _handleIncoming(TodoEvent event) async {
    final incomingTodo = event.todo;

    // Handle delete events
    if (event.type == "delete") {
      await localStore.deleteTodo(incomingTodo.id);
      await _refreshLocalNotifier();
      debugPrint(
        "$deviceId: applied remote delete for ${incomingTodo.id} from ${event.originDeviceId}",
      );
      return;
    }

    // Handle update events - merge strategy: Last-write-wins by version then timestamp
    final all = await localStore.getAll();
    final existing = all.firstWhere(
      (e) => e.id == incomingTodo.id,
      orElse: () =>
          Todo(id: incomingTodo.id, title: '', updatedBy: incomingTodo.updatedBy),
    );

    bool shouldApply = false;
    if (existing.title == '') {
      // new to-do
      shouldApply = true;
    } else {
      // compare version primary, then updatedAt
      if (incomingTodo.version > existing.version) {
        shouldApply = true;
      } else if (incomingTodo.version == existing.version &&
          incomingTodo.updatedAt.isAfter(existing.updatedAt)) {
        shouldApply = true;
      }
    }

    if (shouldApply) {
      debugPrint(
        "$deviceId: applying remote change for ${incomingTodo.id} from ${event.originDeviceId}",
      );
      await localStore.saveTodo(incomingTodo);
      await _refreshLocalNotifier();
    } else {
      debugPrint("$deviceId: ignored remote change for ${incomingTodo.id} (stale)");
    }
  }

  Future<void> _refreshLocalNotifier() async {
    final data = await localStore.getAll();
    data.sort((a, b) => a.title.compareTo(b.title));
    localTodosNotifier.value = data.toList();
  }

  // initial load
  Future<void> loadInitial() async {
    await _refreshLocalNotifier();
  }

  Future<void> delete(String id) async {
    // Get the todo before deleting it so we can send it in the event
    final all = await localStore.getAll();
    final toDelete = all.firstWhere((t) => t.id == id);

    // Delete from local store
    await localStore.deleteTodo(id);
    await _refreshLocalNotifier();

    // Queue the delete event to be sent
    final deleteEvent = TodoEvent(
      type: "delete",
      todo: toDelete,
      originDeviceId: deviceId,
    );

    // Remove any existing update events for this todo since we're deleting it
    _pendingSends.removeWhere((e) => e.todo.id == toDelete.id);

    // Add the delete event to pending sends
    _pendingSends.add(deleteEvent);

    // Try to send immediately (will be queued if offline)
    _debouncer.call(() async {
      if (!socket.online) {
        debugPrint(
          "$deviceId: offline - holding ${_pendingSends.length} items (including delete)",
        );
        return;
      }
      while (_pendingSends.isNotEmpty) {
        final next = _pendingSends.removeFirst();
        await socket.send(jsonEncode(next.toJson()));
      }
    });
  }

  // On network regained, flush pending sends
  Future<void> onNetworkRestored() async {
    // try flush queued items
    if (_pendingSends.isEmpty) return;
    while (_pendingSends.isNotEmpty) {
      final next = _pendingSends.removeFirst();
      final event = TodoEvent(
        originDeviceId: deviceId,
        todo: next.todo,
        type: next.type,
      );
      await socket.send(jsonEncode(event.toJson()));
    }
  }
}

/// ---------- UI: simulate two devices ----------
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final EventManager manager = EventManager();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create two mock websockets sharing the same EventManager (like two devices connecting to same server)
    final socketA = MockWebSocket(
      manager: manager,
      latency: const Duration(milliseconds: 500),
    );
    final socketB = MockWebSocket(
      manager: manager,
      latency: const Duration(milliseconds: 800),
    );

    // Local stores (separate per device to simulate device storage)
    final storeA = InMemoryLocalStore();
    final storeB = InMemoryLocalStore();

    // Notifiers for UI
    final notifierA = ValueNotifier<List<Todo>>([]);
    final notifierB = ValueNotifier<List<Todo>>([]);

    final syncA = SyncEngine(
      deviceId: 'Device-A',
      localStore: storeA,
      socket: socketA,
      localTodosNotifier: notifierA,
    );
    final syncB = SyncEngine(
      deviceId: 'Device-B',
      localStore: storeB,
      socket: socketB,
      localTodosNotifier: notifierB,
    );

    // Prepopulate some shared todos (simulate initial sync)
    final initial = [
      Todo(id: 't1', title: 'Pay rent', updatedBy: 'system', version: 0),
      Todo(id: 't2', title: 'Buy groceries', updatedBy: 'system', version: 0),
    ];
    // Save into both stores (in real life they'd sync from backend)
    Future.wait([
      for (var t in initial) storeA.saveTodo(t),
      for (var t in initial) storeB.saveTodo(t),
    ]).then((_) {
      syncA.loadInitial();
      syncB.loadInitial();
    });

    return MaterialApp(
      title: 'Offline-first Todo (Multi-device Mock)',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Offline-first Todo (two devices demo)'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DevicePanel(
                  deviceId: 'Device-A',
                  syncEngine: syncA,
                  socket: socketA,
                  notifier: notifierA,
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: DevicePanel(
                  deviceId: 'Device-B',
                  syncEngine: syncB,
                  socket: socketB,
                  notifier: notifierB,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DevicePanel extends StatefulWidget {
  final String deviceId;
  final SyncEngine syncEngine;
  final MockWebSocket socket;
  final ValueNotifier<List<Todo>> notifier;

  const DevicePanel({
    super.key,
    required this.deviceId,
    required this.syncEngine,
    required this.socket,
    required this.notifier,
  });

  @override
  State<DevicePanel> createState() => _DevicePanelState();
}

class _DevicePanelState extends State<DevicePanel> {
  late final TextEditingController _newController;
  @override
  void initState() {
    super.initState();
    _newController = TextEditingController();
  }

  @override
  void dispose() {
    _newController.dispose();
    widget.syncEngine.dispose();
    super.dispose();
  }

  void _toggleNetwork(bool value) {
    setState(() {
      widget.socket.online = value;
      if (value) {
        widget.syncEngine.onNetworkRestored();
      }
    });
  }

  Future<void> _createTodo() async {
    final text = _newController.text.trim();
    if (text.isEmpty) return;
    final t = Todo(
      id: const Uuid().v4(),
      title: text,
      updatedBy: widget.deviceId,
      version: 0,
    );
    _newController.clear();
    await widget.syncEngine.localStore.saveTodo(t);
    await widget.syncEngine.loadInitial();
    // Immediately schedule send via syncEngine API
    await widget.syncEngine.onLocalEdit(t);
  }

  Future<void> _editTodoInline(Todo todo) async {
    final controller = TextEditingController(text: todo.title);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit (${widget.deviceId})'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final updated = todo.copyWith(title: result, updatedBy: widget.deviceId);
      await widget.syncEngine.onLocalEdit(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.deviceId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                const Text('Network:'),
                Switch(value: widget.socket.online, onChanged: _toggleNetwork),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    // Simulate manual "receive remote" (in case offline)
                    await widget.syncEngine.onNetworkRestored();
                  },
                  child: const Text('Sync Now'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newController,
                    decoration: const InputDecoration(hintText: 'New todo...'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createTodo,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder<List<Todo>>(
                valueListenable: widget.notifier,
                builder: (context, todos, _) {
                  if (todos.isEmpty)
                    return const Center(child: Text('No todos'));
                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (ctx, i) {
                      final t = todos[i];
                      return ListTile(
                        title: Text(t.title),
                        subtitle: Text(
                          'v${t.version} • ${t.updatedBy} • ${t.updatedAt.toLocal()}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => widget.syncEngine.delete(t.id),
                        ),
                        onTap: () => _editTodoInline(t),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
