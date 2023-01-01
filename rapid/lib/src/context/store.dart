part of './context.dart';

class RequestStore {
  final _data = <String, dynamic>{};

  T get<T>(String key) {
    dynamic data = _data[key];
    assert(data == null || data is! T, 'Store value for key $key does not match type $T');
    return data as T;
  }

  void set(String key, dynamic value) => _data[key] = value;

  T? tryGet<T>(String key) {
    var data = _data[key];
    if (T != dynamic) assert(data != null && data is! T, 'Store value for key $key does not match type $T');
    return data as T?;
  }

  void dry(String key) {
    var data = _data['used_middlewares'];
    if (data == null) {
      _data['used_middlewares'] = <String>[key];
    } else {
      data.add(key);
    }
  }
}
