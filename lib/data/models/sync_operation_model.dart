// lib/data/models/sync_operation_model.dart
class SyncOperationModel {
  final int? id;
  final String userId;
  final String entityType;
  final String entityId;
  final String operationType;
  final String? payload;
  final DateTime timestamp;

  SyncOperationModel({
    this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    this.payload,
    required this.timestamp,
  });

  factory SyncOperationModel.fromMap(Map<String, dynamic> map) {
    return SyncOperationModel(
      id: map['id'],
      userId: map['userId'],
      entityType: map['entityType'],
      entityId: map['entityId'],
      operationType: map['operationType'],
      payload: map['payload'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'operationType': operationType,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}