import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connect_safecity/model/contactsm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  String contactTable = 'contact_table';
  String colId = 'id';
  String colContactName = 'name';
  String colContactNumber = 'number';

  DatabaseHelper._createInstance();

  static DatabaseHelper? _databaseHelper;

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper._createInstance();
    }
    return _databaseHelper!;
  }

  static Database? _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    String directoryPath = await getDatabasesPath();
    String dbLocation = join(directoryPath, 'contact.db');

    var contactDatabase =
        await openDatabase(dbLocation, version: 1, onCreate: _createDbTable);
    return contactDatabase;
  }

  void _createDbTable(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE $contactTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colContactName TEXT, $colContactNumber TEXT)');
  }

  Future<List<Map<String, dynamic>>> getContactMapList() async {
    Database db = await this.database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT * FROM $contactTable ORDER BY $colId ASC');
    return result;
  }

  Future<int> insertContact(TContact contact) async {
    Database db = await this.database;
    var result = await db.insert(contactTable, contact.toMap());
    return result;
  }

  Future<int> updateContact(TContact contact) async {
    Database db = await this.database;
    var result = await db.update(contactTable, contact.toMap(),
        where: '$colId = ?', whereArgs: [contact.id]);
    return result;
  }

  Future<int> deleteContact(int id) async {
    Database db = await this.database;
    int result =
        await db.rawDelete('DELETE FROM $contactTable WHERE $colId = $id');
    return result;
  }

  Future<int> getCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery('SELECT COUNT(*) FROM $contactTable');
    int result = Sqflite.firstIntValue(x)!;
    return result;
  }

  Future<List<TContact>> getContactList() async {
    var contactMapList = await getContactMapList();
    int count = contactMapList.length;

    List<TContact> contactList = <TContact>[];

    for (int i = 0; i < count; i++) {
      contactList.add(TContact.fromMapObject(contactMapList[i]));
    }

    return contactList;
  }

  Future<void> saveTrustedContactsToDatabase(
      String currentUserId, List<TContact> trustedContacts) async {
    try {
      Map<String, dynamic> trustedContactsData = {};

      for (int i = 0; i < trustedContacts.length; i++) {
        trustedContactsData['TrustedContactName${i + 1}'] =
            trustedContacts[i].name;
        trustedContactsData['TrustedContactNumber${i + 1}'] =
            trustedContacts[i].number;
      }

      // Update or create the document in the TrustedContacts collection
      await FirebaseFirestore.instance
          .collection('TrustedContacts')
          .doc(currentUserId)
          .set(trustedContactsData, SetOptions(merge: true));
    } catch (e) {
      print("Error saving trusted contacts: $e");
      throw Exception("Failed to save trusted contacts");
    }
  }

  saveTrustedContact(String currentUserId, TContact newContact) {}
}
