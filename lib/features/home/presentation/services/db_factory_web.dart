import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<Database> openDatabaseWebCompatible(
  String path, {
  required int version,
  required Future<void> Function(Database db, int version) onCreate,
  Future<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
}) {
  final factory = createDatabaseFactoryFfiWeb(noWebWorker: true);
  return factory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    ),
  );
}
