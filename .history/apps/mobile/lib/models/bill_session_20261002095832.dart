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
}
