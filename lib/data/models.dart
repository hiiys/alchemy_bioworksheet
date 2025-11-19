// Data models for Alchemy Bioworksheet app

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
  final int? orderId;
  final String stationId;
  final DateTime date;
  final double? lat;
  final double? lon;
  final String? habitat;
  final String? client;
  final String? biologistId;
  final String? remarks;
  final bool completed;
  final String sampleType; // Phytoplankton | Zooplankton | Macrobenthos
  final String? sampleMarking;
  final String? receiveId;
  final DateTime? analyzedDate;

  Sample({
    this.id,
    this.orderId,
    required this.stationId,
    required this.date,
    this.lat,
    this.lon,
    this.habitat,
    this.client,
    this.biologistId,
    this.remarks,
    this.completed = false,
    this.sampleType = 'Macrobenthos',
    this.sampleMarking,
    this.receiveId,
    this.analyzedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'stationId': stationId,
      'date': date.millisecondsSinceEpoch,
      'lat': lat,
      'lon': lon,
      'habitat': habitat,
      'client': client,
      'biologistId': biologistId,
      'remarks': remarks,
      'completed': completed ? 1 : 0,
      'sampleType': sampleType,
      'sampleMarking': sampleMarking,
      'receiveId': receiveId,
      'analyzedDate': analyzedDate?.millisecondsSinceEpoch,
    };
  }

  factory Sample.fromMap(Map<String, dynamic> map) {
    return Sample(
      id: map['id'],
      orderId: map['orderId'],
      stationId: map['stationId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      lat: map['lat'],
      lon: map['lon'],
      habitat: map['habitat'],
      client: map['client'],
      biologistId: map['biologistId'],
      remarks: map['remarks'],
      completed: (map['completed'] ?? 0) == 1,
      sampleType: (map['sampleType'] ?? 'Macrobenthos') as String,
      sampleMarking: map['sampleMarking'],
      receiveId: map['receiveId'],
      analyzedDate: map['analyzedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['analyzedDate'])
          : null,
    );
  }
}

class OrderInfo {
  final int? id;
  final String clientName;
  final String? clientAddress;
  final String specimenType;
  final int numberOfSamples;
  final int? numberOfReplicates;
  final DateTime? dateReceived;
  final DateTime? dateAnalysis;
  final String? gearUsed;
  final String? areaOfGrab;
  final String? sieveSize;
  final String? netDiameter;
  final String? netMesh;
  final String? towType;
  final String? filteredVolume;
  final String? methodAnalysis;
  final String? reportNo;
  final String? referenceId;
  final String? comments;
  OrderInfo({
    this.id,
    required this.clientName,
    this.clientAddress,
    required this.specimenType,
    required this.numberOfSamples,
    this.numberOfReplicates,
    this.dateReceived,
    this.dateAnalysis,
    this.gearUsed,
    this.areaOfGrab,
    this.sieveSize,
    this.netDiameter,
    this.netMesh,
    this.towType,
    this.filteredVolume,
    this.methodAnalysis,
    this.reportNo,
    this.referenceId,
    this.comments,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'clientName': clientName,
    'clientAddress': clientAddress,
    'specimenType': specimenType,
    'numberOfSamples': numberOfSamples,
    'numberOfReplicates': numberOfReplicates,
    'dateReceived': dateReceived?.millisecondsSinceEpoch,
    'dateAnalysis': dateAnalysis?.millisecondsSinceEpoch,
    'gearUsed': gearUsed,
    'areaOfGrab': areaOfGrab,
    'sieveSize': sieveSize,
    'netDiameter': netDiameter,
    'netMesh': netMesh,
    'towType': towType,
    'filteredVolume': filteredVolume,
    'methodAnalysis': methodAnalysis,
    'reportNo': reportNo,
    'referenceId': referenceId,
    'comments': comments,
  };
  factory OrderInfo.fromMap(Map<String, dynamic> m) => OrderInfo(
    id: m['id'] as int?,
    clientName: m['clientName'] as String,
    clientAddress: m['clientAddress'] as String?,
    specimenType: m['specimenType'] as String,
    numberOfSamples: (m['numberOfSamples'] ?? 0) as int,
    numberOfReplicates: m['numberOfReplicates'] as int?,
    dateReceived: m['dateReceived'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['dateReceived'] as int)
        : null,
    dateAnalysis: m['dateAnalysis'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['dateAnalysis'] as int)
        : null,
    gearUsed: m['gearUsed'] as String?,
    areaOfGrab: m['areaOfGrab'] as String?,
    sieveSize: m['sieveSize'] as String?,
    netDiameter: m['netDiameter'] as String?,
    netMesh: m['netMesh'] as String?,
    towType: m['towType'] as String?,
    filteredVolume: m['filteredVolume'] as String?,
    methodAnalysis: m['methodAnalysis'] as String?,
    reportNo: m['reportNo'] as String?,
    referenceId: m['referenceId'] as String?,
    comments: m['comments'] as String?,
  );
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

class PendingChange {
  final int? id;
  final String changeType; // 'create', 'update', 'delete'
  final String specimenType;
  final int? taxonId;
  final String? oldData; // JSON string of old taxon data
  final String? newData; // JSON string of new taxon data
  final DateTime timestamp;
  final String? deviceId;
  final bool synced;

  PendingChange({
    this.id,
    required this.changeType,
    required this.specimenType,
    this.taxonId,
    this.oldData,
    this.newData,
    required this.timestamp,
    this.deviceId,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'changeType': changeType,
      'specimenType': specimenType,
      'taxonId': taxonId,
      'oldData': oldData,
      'newData': newData,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceId': deviceId,
      'synced': synced ? 1 : 0,
    };
  }

  factory PendingChange.fromMap(Map<String, dynamic> map) {
    return PendingChange(
      id: map['id'],
      changeType: map['changeType'],
      specimenType: map['specimenType'],
      taxonId: map['taxonId'],
      oldData: map['oldData'],
      newData: map['newData'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      deviceId: map['deviceId'],
      synced: (map['synced'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'changeType': changeType,
      'specimenType': specimenType,
      'taxonId': taxonId,
      'oldData': oldData,
      'newData': newData,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'status': 'pending', // pending, approved, rejected
    };
  }
}
