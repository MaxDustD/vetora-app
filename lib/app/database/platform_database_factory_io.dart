import 'dart:io';

import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseFactory? platformDatabaseFactory() {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactorySqflitePlugin;
}
