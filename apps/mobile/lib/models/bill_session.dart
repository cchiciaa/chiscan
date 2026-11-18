class BillParticipant {
  const BillParticipant({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory BillParticipant.fromJson(Map<String, dynamic> json) {
    return BillParticipant(
      id: json['id'] as String? ?? json['name'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class BillItem {
  const BillItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.allocatedParticipantIds = const [],
  });

  final String id;
  final String name;
  final int price;
  final int quantity;
  final List<String> allocatedParticipantIds;

  int get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'allocatedParticipantIds': allocatedParticipantIds,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) {
    final allocated = (json['allocatedParticipantIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    return BillItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      allocatedParticipantIds: allocated,
    );
  }
}

class BillShare {
  const BillShare({
    required this.participant,
    required this.amount,
  });

  final BillParticipant participant;
  final int amount;
}

class BillSession {
  const BillSession({
    required this.id,
    required this.title,
    required this.hostName,
    required this.grandTotalAmount,
    required this.participantCount,
    this.participants = const [],
    this.items = const [],
    this.taxBasisPoints = 0,
    this.serviceBasisPoints = 0,
    this.discountAmount = 0,
  });

  final String id;
  final String title;
  final String hostName;
  final int grandTotalAmount;
  final int participantCount;
  final List<BillParticipant> participants;
  final List<BillItem> items;
  final int taxBasisPoints;
  final int serviceBasisPoints;
  final int discountAmount;

  BillSession copyWith({
    String? id,
    String? title,
    String? hostName,
    int? grandTotalAmount,
    int? participantCount,
    List<BillParticipant>? participants,
    List<BillItem>? items,
    int? taxBasisPoints,
    int? serviceBasisPoints,
    int? discountAmount,
  }) {
    return BillSession(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      grandTotalAmount: grandTotalAmount ?? this.grandTotalAmount,
      participantCount: participantCount ?? this.participantCount,
      participants: participants ?? this.participants,
      items: items ?? this.items,
      taxBasisPoints: taxBasisPoints ?? this.taxBasisPoints,
      serviceBasisPoints: serviceBasisPoints ?? this.serviceBasisPoints,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  int get subtotalAmount =>
      items.fold<int>(0, (sum, item) => sum + item.totalPrice);

  int get calculatedGrandTotal {
    if (items.isEmpty) return grandTotalAmount;
    final tax = subtotalAmount * taxBasisPoints ~/ 10000;
    final service = subtotalAmount * serviceBasisPoints ~/ 10000;
    return subtotalAmount + tax + service - discountAmount;
  }

  List<BillShare> calculateShares() {
    if (participants.isEmpty) return const [];

    final shares = List<int>.filled(participants.length, 0);
    for (final item in items) {
      final selectedIds = item.allocatedParticipantIds;
      final recipients = selectedIds.isEmpty
          ? participants
          : participants.where((participant) => selectedIds.contains(participant.id)).toList();
      if (recipients.isEmpty) continue;
      final allocated = _allocateWholeAmount(item.totalPrice, recipients.length);
      for (var i = 0; i < recipients.length; i++) {
        final participantIndex =
            participants.indexWhere((participant) => participant.id == recipients[i].id);
        if (participantIndex >= 0) shares[participantIndex] += allocated[i];
      }
    }

    final taxAmount = subtotalAmount * taxBasisPoints ~/ 10000;
    final serviceAmount = subtotalAmount * serviceBasisPoints ~/ 10000;
    final taxShares = _allocateProportionally(taxAmount, shares);
    final serviceShares = _allocateProportionally(serviceAmount, shares);
    final discountShares = _allocateProportionally(discountAmount, shares);

    return List.generate(participants.length, (index) {
      final finalAmount =
          shares[index] + taxShares[index] + serviceShares[index] - discountShares[index];
      return BillShare(participant: participants[index], amount: finalAmount);
    });
  }

  List<int> _allocateProportionally(int target, List<int> weights) {
    if (target == 0) return List<int>.filled(weights.length, 0);
    final weightTotal = weights.fold<int>(0, (sum, value) => sum + value);
    if (weightTotal == 0) return _allocateWholeAmount(target, weights.length);

    final units = List<int>.filled(weights.length, 0);
    final remainders = List<int>.filled(weights.length, 0);
    var allocated = 0;
    for (var i = 0; i < weights.length; i++) {
      final numerator = target * weights[i];
      units[i] = numerator ~/ weightTotal;
      remainders[i] = numerator % weightTotal;
      allocated += units[i];
    }
    var remaining = target - allocated;
    final indices = List<int>.generate(weights.length, (index) => index);
    indices.sort((a, b) {
      final remainderCompare = remainders[b].compareTo(remainders[a]);
      return remainderCompare != 0 ? remainderCompare : a.compareTo(b);
    });
    for (var i = 0; i < remaining && i < indices.length; i++) {
      units[indices[i]]++;
    }
    return units;
  }

  List<int> _allocateWholeAmount(int amount, int count) {
    if (count <= 0) return const [];
    final quotient = amount ~/ count;
    final remainder = amount % count;
    return List.generate(count, (index) => quotient + (index < remainder ? 1 : 0));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'hostName': hostName,
      'grandTotalAmount': grandTotalAmount,
      'participantCount': participantCount,
      'participants': participants.map((participant) => participant.toJson()).toList(),
      'items': items.map((item) => item.toJson()).toList(),
      'taxBasisPoints': taxBasisPoints,
      'serviceBasisPoints': serviceBasisPoints,
      'discountAmount': discountAmount,
    };
  }

  factory BillSession.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['title'] is! String ||
        json['hostName'] is! String) {
      throw const FormatException('Data JSON BillSession tidak lengkap atau tipe tidak valid.');
    }
    final participants = (json['participants'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => BillParticipant.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => BillItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final storedTotal = (json['grandTotalAmount'] as num?)?.toInt() ?? 0;
    final subtotal = items.fold<int>(0, (sum, item) => sum + item.totalPrice);
    final taxBasisPoints = (json['taxBasisPoints'] as num?)?.toInt() ?? 0;
    final serviceBasisPoints = (json['serviceBasisPoints'] as num?)?.toInt() ?? 0;
    final discountAmount = (json['discountAmount'] as num?)?.toInt() ?? 0;
    final calculatedTotal = subtotal == 0
        ? storedTotal
        : subtotal +
            (subtotal * taxBasisPoints ~/ 10000) +
            (subtotal * serviceBasisPoints ~/ 10000) -
            discountAmount;
    return BillSession(
      id: json['id'] as String,
      title: json['title'] as String,
      hostName: json['hostName'] as String,
      grandTotalAmount: calculatedTotal,
      participantCount: participants.isEmpty
          ? ((json['participantCount'] as num?)?.toInt() ?? 0)
          : participants.length,
      participants: participants,
      items: items,
      taxBasisPoints: taxBasisPoints,
      serviceBasisPoints: serviceBasisPoints,
      discountAmount: discountAmount,
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
