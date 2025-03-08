/// Interface for accessing configurations synchronously
abstract class SyncStore<T> {
  /// Get a configuration by key
  T? get(String key);

  /// Set a configuration
  void set(String key, T value);

  /// Get all configuration keys
  List<String> getKeys();
}

/// Interface for a configuration store that may expire
abstract class ConfigurationStore<T> extends SyncStore<T> {
  /// The salt used for obfuscation
  String? get salt;

  /// Whether the store has been initialized
  bool isInitialized();

  /// The format of the configurations
  String? getFormat();

  /// Check if the configuration has expired
  Future<bool> isExpired();

  /// Update the entire store with new configurations
  void update(Map<String, T> configurations, {String? salt, String? format});

  /// Clear all configurations
  void clear();
}

/// An in-memory implementation of ConfigurationStore
class InMemoryConfigurationStore<T> implements ConfigurationStore<T> {
  final Map<String, T> _store = {};
  String? _salt;
  bool _initialized = false;
  String? _format;

  @override
  T? get(String key) => _store[key];

  /// Get all configurations
  Map<String, T> getAll() => Map.from(_store);

  @override
  List<String> getKeys() => _store.keys.toList();

  @override
  bool isInitialized() => _initialized;

  @override
  String? get salt => _salt;

  @override
  void set(String key, T value) {
    _store[key] = value;
  }

  /// Set multiple configurations at once
  void setAll(Map<String, T> values) {
    _store.addAll(values);
  }

  /// Set the salt for obfuscation
  void setSalt(String salt) {
    _salt = salt;
  }

  /// Set whether the store has been initialized
  void setInitialized(bool initialized) {
    _initialized = initialized;
  }

  @override
  void clear() {
    _store.clear();
  }

  @override
  String? getFormat() {
    return _format;
  }

  @override
  Future<bool> isExpired() async {
    return false;
  }

  @override
  void update(Map<String, T> configurations, {String? salt, String? format}) {
    _store.clear();
    _store.addAll(configurations);
    if (salt != null) {
      _salt = salt;
    }
    if (format != null) {
      _format = format;
    }

    _initialized = true;
  }
}
