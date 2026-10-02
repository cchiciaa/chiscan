class BillSessionValidation {
  const BillSessionValidation({this.titleError, this.hostNameError});

  final String? titleError;
  final String? hostNameError;

  bool get isValid => titleError == null && hostNameError == null;
}

BillSessionValidation validateBillSession({required String title, required String hostName}) {
  return BillSessionValidation(
    titleError: title.trim().isEmpty ? 'Nama sesi wajib diisi.' : null,
    hostNameError: hostName.trim().isEmpty ? 'Nama host wajib diisi.' : null,
  );
}
