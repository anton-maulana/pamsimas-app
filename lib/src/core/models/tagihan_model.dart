// ─── Model ────────────────────────────────────────────────────────────────────

enum StatusTagihan { lunas, belumBayar }

class TagihanItem {
  final String id;
  final String nama;
  final String rt;
  final String rw;
  final String alamat;
  final double meterSebelumnya;
  final double meterSaatIni;
  final double pemakaian;
  final int tarif;
  final int totalTagihan;
  final StatusTagihan status;
  final DateTime tanggalCatat;
  final DateTime? tanggalBayar;
  final String petugas;

  const TagihanItem({
    required this.id,
    required this.nama,
    required this.rt,
    required this.rw,
    required this.alamat,
    required this.meterSebelumnya,
    required this.meterSaatIni,
    required this.pemakaian,
    this.tarif = 3500,
    required this.totalTagihan,
    required this.status,
    required this.tanggalCatat,
    this.tanggalBayar,
    required this.petugas,
  });
}
