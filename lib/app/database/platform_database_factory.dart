import 'package:sqflite/sqflite.dart';

import 'platform_database_factory_stub.dart'
    if (dart.library.ffi) 'platform_database_factory_io.dart'
    as impl;

/// A fábrica de banco certa para a plataforma, ou `null` se não houver
/// SQLite disponível (web).
///
/// Android, iOS e macOS usam o plugin `sqflite`; Linux e Windows usam o
/// SQLite do sistema via FFI (`sqflite_common_ffi`).
DatabaseFactory? platformDatabaseFactory() => impl.platformDatabaseFactory();
