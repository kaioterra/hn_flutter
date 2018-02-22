import 'dart:async';
import 'dart:io' show Directory;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:hn_flutter/sdk/services/abstract/local_storage_service.dart';
import 'package:hn_flutter/sdk/sqflite_vals.dart';

class LocalStorageServiceProd implements LocalStorageService {
  static final LocalStorageServiceProd _singleton = new LocalStorageServiceProd._internal();

  Directory _documentsDirectory;
  Map<String, Database> _databases = new Map();

  LocalStorageServiceProd._internal ();

  factory LocalStorageServiceProd () {
    return _singleton;
  }

  Future<Null> init () async {
    this._documentsDirectory = await getApplicationDocumentsDirectory();

    await Future.wait([
      this._initTableKeys(),
      this._initTableAccounts(),
    ]);
  }

  Future<Null> _initTableKeys () async {
    String keysPath = join(this._documentsDirectory.path, KEYS_DB);
    this._databases[KEYS_DB] = await openDatabase(keysPath, version: 1, onCreate: (Database db, int version) async {
      print('CREATING KEYS TABLE');
      await db.execute('CREATE TABLE $KEYS_TABLE ($KEYS_ID TEXT PRIMARY KEY, $KEYS_VALUE TEXT)');
    });
  }

  Future<Null> _initTableAccounts () async {
    String accountsPath = join(this._documentsDirectory.path, ACCOUNTS_DB);
    this._databases[ACCOUNTS_DB] = await openDatabase(accountsPath, version: 1, onCreate: (Database db, int version) async {
      print('CREATING ACCOUNTS TABLE');
      await db.execute('''
        CREATE TABLE $ACCOUNTS_TABLE
          ($ACCOUNTS_ID TEXT PRIMARY KEY, $ACCOUNTS_EMAIL TEXT, $ACCOUNTS_PASSWORD TEXT, $ACCOUNTS_ACCESS_COOKIE TEXT)
      ''');
    });
  }

  Map<String, Database> get databases => new Map.unmodifiable(this._databases);
}
