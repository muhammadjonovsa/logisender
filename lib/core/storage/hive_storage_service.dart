import 'package:hive_flutter/hive_flutter.dart';

/// Centralized Hive storage manager for local persistent data.
class HiveStorageService {
  static Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<Box<dynamic>> openBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    return await Hive.openBox(name);
  }

  Future<void> put(String boxName, dynamic key, dynamic value) async {
    final box = await openBox(boxName);
    await box.put(key, value);
  }

  Future<dynamic> get(String boxName, dynamic key) async {
    final box = await openBox(boxName);
    return box.get(key);
  }

  Future<List<dynamic>> getAll(String boxName) async {
    final box = await openBox(boxName);
    return box.values.toList();
  }

  Future<void> delete(String boxName, dynamic key) async {
    final box = await openBox(boxName);
    await box.delete(key);
  }

  Future<void> deleteAll(String boxName, List<dynamic> keys) async {
    final box = await openBox(boxName);
    await box.deleteAll(keys);
  }

  Future<void> clear(String boxName) async {
    final box = await openBox(boxName);
    await box.clear();
  }

  Future<void> putAll(String boxName, Map<dynamic, dynamic> entries) async {
    final box = await openBox(boxName);
    await box.putAll(entries);
  }

  Future<void> compact(String boxName) async {
    final box = await openBox(boxName);
    await box.compact();
  }
}
