import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = 'macrobenthos_counter.db';
  static const _databaseVersion = 4;

  // Singleton instance
  static Database? _database;
  static DatabaseHelper? _instance;

  DatabaseHelper._internal();
  
  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureSchema(db);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create ProjectInfo table
    await db.execute('''
      CREATE TABLE project_info (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectName TEXT NOT NULL,
        client TEXT,
        date INTEGER NOT NULL,
        team TEXT,
        remarks TEXT
      )
    ''');

    // Create Sample table
    await db.execute('''
      CREATE TABLE sample (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stationId TEXT NOT NULL,
        date INTEGER NOT NULL,
        lat REAL,
        lon REAL,
        habitat TEXT,
        client TEXT,
        remarks TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        sampleType TEXT NOT NULL DEFAULT 'Macrobenthos'
      )
    ''');

    // Create Taxon table with hierarchical structure
    await db.execute('''
      CREATE TABLE taxon (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parentId INTEGER,
        name TEXT NOT NULL,
        rank TEXT,
        notes TEXT,
        specimenType TEXT NOT NULL DEFAULT 'Macrobenthos',
        FOREIGN KEY (parentId) REFERENCES taxon (id)
      )
    ''');

    // Create CountRecord table
    await db.execute('''
      CREATE TABLE count_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sampleId INTEGER NOT NULL,
        taxonId INTEGER NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        photoPath TEXT,
        FOREIGN KEY (sampleId) REFERENCES sample (id),
        FOREIGN KEY (taxonId) REFERENCES taxon (id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_sample_id ON count_record(sampleId)');
    await db.execute('CREATE INDEX idx_taxon_parent ON taxon(parentId)');
    await db.execute('CREATE INDEX idx_count_taxon ON count_record(taxonId)');
    await db.execute('CREATE INDEX idx_sample_type ON sample(sampleType)');
    await db.execute('CREATE INDEX idx_taxon_type ON taxon(specimenType)');

    await db.execute('''
      CREATE TABLE rank_definition (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        specimenType TEXT NOT NULL,
        name TEXT NOT NULL,
        sequence INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX idx_rank_def_unique ON rank_definition(specimenType, name)');
    await db.execute('CREATE INDEX idx_rank_def_seq ON rank_definition(specimenType, sequence)');

    await _seedDefaultRankDefinitions(db);

  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureSchema(db);
  }

  Future<void> _ensureSchema(Database db) async {
    final sampleCols = await db.rawQuery("PRAGMA table_info(sample)");
    final sampleColNames = sampleCols.map((c) => c['name'] as String).toSet();
    if (!sampleColNames.contains('client')) {
      await db.execute('ALTER TABLE sample ADD COLUMN client TEXT');
    }
    if (!sampleColNames.contains('completed')) {
      await db.execute('ALTER TABLE sample ADD COLUMN completed INTEGER NOT NULL DEFAULT 0');
    }
    if (!sampleColNames.contains('lat')) {
      await db.execute('ALTER TABLE sample ADD COLUMN lat REAL');
    }
    if (!sampleColNames.contains('lon')) {
      await db.execute('ALTER TABLE sample ADD COLUMN lon REAL');
    }
    if (!sampleColNames.contains('habitat')) {
      await db.execute('ALTER TABLE sample ADD COLUMN habitat TEXT');
    }
    if (!sampleColNames.contains('sampleType')) {
      await db.execute("ALTER TABLE sample ADD COLUMN sampleType TEXT NOT NULL DEFAULT 'Macrobenthos'");
    }

    final taxonCols = await db.rawQuery("PRAGMA table_info(taxon)");
    final taxonColNames = taxonCols.map((c) => c['name'] as String).toSet();
    if (!taxonColNames.contains('specimenType')) {
      await db.execute("ALTER TABLE taxon ADD COLUMN specimenType TEXT NOT NULL DEFAULT 'Macrobenthos'");
    }

    // Ensure indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sample_type ON sample(sampleType)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_taxon_type ON taxon(specimenType)');

    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final names = tables.map((e) => e['name'] as String).toSet();
    if (!names.contains('rank_definition')) {
      await db.execute('''
        CREATE TABLE rank_definition (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          specimenType TEXT NOT NULL,
          name TEXT NOT NULL,
          sequence INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE UNIQUE INDEX idx_rank_def_unique ON rank_definition(specimenType, name)');
      await db.execute('CREATE INDEX idx_rank_def_seq ON rank_definition(specimenType, sequence)');
    }
    await _seedDefaultRankDefinitions(db);
  }

  

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _seedDefaultRankDefinitions(Database db) async {
    final types = ['Phytoplankton', 'Zooplankton', 'Macrobenthos'];
    final defaults = ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'];
    for (final t in types) {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(1) FROM rank_definition WHERE specimenType = ?', [t])) ?? 0;
      if (count == 0) {
        int seq = 1;
        for (final name in defaults) {
          await db.insert('rank_definition', {
            'specimenType': t,
            'name': name,
            'sequence': seq,
          });
          seq++;
        }
      }
    }
  }
}
