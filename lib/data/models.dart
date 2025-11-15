// Data models for Macrobenthos Counter app

class ProjectInfo {
  final int? id;
  final String projectName;
  final String? client;
  final DateTime date;
  final String? team;
  final String? remarks;

  ProjectInfo({
    this.id,
    required this.projectName,
    this.client,
    required this.date,
    this.team,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectName': projectName,
      'client': client,
      'date': date.millisecondsSinceEpoch,
      'team': team,
      'remarks': remarks,
    };
  }

  factory ProjectInfo.fromMap(Map<String, dynamic> map) {
    return ProjectInfo(
      id: map['id'],
      projectName: map['projectName'],
      client: map['client'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      team: map['team'],
      remarks: map['remarks'],
    );
  }
}

class Sample {
  final int? id;
  final String stationId;
  final DateTime date;
  final double? lat;
  final double? lon;
  final String? habitat;
  final String? client;
  final String? remarks;
  final bool completed;
  final String sampleType; // Phytoplankton | Zooplankton | Macrobenthos

  Sample({
    this.id,
    required this.stationId,
    required this.date,
    this.lat,
    this.lon,
    this.habitat,
    this.client,
    this.remarks,
    this.completed = false,
    this.sampleType = 'Macrobenthos',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stationId': stationId,
      'date': date.millisecondsSinceEpoch,
      'lat': lat,
      'lon': lon,
      'habitat': habitat,
      'client': client,
      'remarks': remarks,
      'completed': completed ? 1 : 0,
      'sampleType': sampleType,
    };
  }

  factory Sample.fromMap(Map<String, dynamic> map) {
    return Sample(
      id: map['id'],
      stationId: map['stationId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      lat: map['lat'],
      lon: map['lon'],
      habitat: map['habitat'],
      client: map['client'],
      remarks: map['remarks'],
      completed: (map['completed'] ?? 0) == 1,
      sampleType: (map['sampleType'] ?? 'Macrobenthos') as String,
    );
  }
}

class Taxon {
  final int? id;
  final int? parentId;
  final String name;
  final String? rank;
  final String? notes;
  final String? specimenType; // Phytoplankton | Zooplankton | Macrobenthos

  Taxon({
    this.id,
    this.parentId,
    required this.name,
    this.rank,
    this.notes,
    this.specimenType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'rank': rank,
      'notes': notes,
      'specimenType': specimenType,
    };
  }

  factory Taxon.fromMap(Map<String, dynamic> map) {
    return Taxon(
      id: map['id'],
      parentId: map['parentId'],
      name: map['name'],
      rank: map['rank'],
      notes: map['notes'],
      specimenType: map['specimenType'],
    );
  }

  // Helper method to check if this taxon is a leaf (has no children)
  bool get isLeaf => false; // This will be determined by the tree structure

  // Helper method to check if this taxon is a root (has no parent)
  bool get isRoot => parentId == null;
}

class CountRecord {
  final int? id;
  final int sampleId;
  final int taxonId;
  final int count;
  final String? note;
  final String? photoPath;

  CountRecord({
    this.id,
    required this.sampleId,
    required this.taxonId,
    required this.count,
    this.note,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sampleId': sampleId,
      'taxonId': taxonId,
      'count': count,
      'note': note,
      'photoPath': photoPath,
    };
  }

  factory CountRecord.fromMap(Map<String, dynamic> map) {
    return CountRecord(
      id: map['id'],
      sampleId: map['sampleId'],
      taxonId: map['taxonId'],
      count: map['count'],
      note: map['note'],
      photoPath: map['photoPath'],
    );
  }
}
