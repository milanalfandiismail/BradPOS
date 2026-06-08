import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'web_database_adapter.dart' as web_sql;

class DbUtils {
  static dynamic getConflictAlgorithmReplace() {
    return kIsWeb ? web_sql.ConflictAlgorithm.replace : sqlite.ConflictAlgorithm.replace;
  }

  static int? firstIntValue(List<Map<String, dynamic>> list) {
    return kIsWeb ? web_sql.Sqflite.firstIntValue(list) : sqlite.Sqflite.firstIntValue(list);
  }
}
