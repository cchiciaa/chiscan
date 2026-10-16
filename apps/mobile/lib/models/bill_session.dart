class BillSession {
  const BillSession({
    required this.id,
    required this.title,
    required this.hostName,
    required this.grandTotalAmount,
    required this.participantCount,
  });

  final String id;
  final String title;
  final String hostName;
  final int grandTotalAmount;
  final int participantCount;

  BillSession copyWith({
    String? id,
    String? title,
    String? hostName,
    int? grandTotalAmount,
    int? participantCount,
  }) {
    return BillSession(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      grandTotalAmount: grandTotalAmount ?? this.grandTotalAmount,
      participantCount: participantCount ?? this.participantCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hostName': hostName,
      'grandTotalAmount': grandTotalAmount,
      'participantCount': participantCount,
    };
  }

  factory BillSession.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['title'] is! String ||
        json['hostName'] is! String) {
      throw const FormatException('Data JSON BillSession tidak lengkap atau tipe tidak valid.');
    }
    return BillSession(
      id: json['id'] as String,
      title: json['title'] as String,
      hostName: json['hostName'] as String,
      grandTotalAmount: (json['grandTotalAmount'] as num?)?.toInt() ?? 0,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          hostName == other.hostName &&
          grandTotalAmount == other.grandTotalAmount &&
          participantCount == other.participantCount;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      hostName.hashCode ^
      grandTotalAmount.hashCode ^
      participantCount.hashCode;
}
