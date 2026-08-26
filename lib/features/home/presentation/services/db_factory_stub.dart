import 'package:sqflite/sqflite.dart';

Future<Database> openDatabaseWebCompatible(
  String path, {
  required int version,
  required Future<void> Function(Database db, int version) onCreate,
  Future<void> Function(Database db, int oldVersion, int newVersion)? onUpgrade,
}) {
  return openDatabase(
    path,
    version: version,
    onCreate: onCreate,
    onUpgrade: onUpgrade,
  );
}
