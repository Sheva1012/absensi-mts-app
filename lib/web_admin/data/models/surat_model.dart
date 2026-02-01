import 'package:web_admin_mts/web_admin/core/constants.dart';

/// Model representing an absence letter (Surat Keterangan)
class Surat {
  final int id;
  final int siswaId;
  final LetterType tipe;
  final DateTime tanggal;
  final String? alasan;
  final String? keterangan;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Surat({
    required this.id,
    required this.siswaId,
    required this.tipe,
    required this.tanggal,
    this.alasan,
    this.keterangan,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Surat from JSON (typically from Supabase)
  factory Surat.fromJson(Map<String, dynamic> json) {
    return Surat(
      id: json[SuratColumns.id] as int,
      siswaId: json[SuratColumns.siswaId] as int,
      tipe: LetterType.fromValue(
        json[SuratColumns.tipe] as String? ?? 'izin',
      ),
      tanggal: json[SuratColumns.tanggal] != null
          ? DateTime.parse(json[SuratColumns.tanggal] as String)
          : DateTime.now(),
      alasan: json[SuratColumns.alasan] as String?,
      keterangan: json[SuratColumns.keterangan] as String?,
      createdAt: json[SuratColumns.createdAt] != null
          ? DateTime.parse(json[SuratColumns.createdAt] as String)
          : DateTime.now(),
      updatedAt: json[SuratColumns.updatedAt] != null
          ? DateTime.parse(json[SuratColumns.updatedAt] as String)
          : null,
    );
  }

  /// Convert Surat to JSON for sending to Supabase
  Map<String, dynamic> toJson() => {
    SuratColumns.id: id,
    SuratColumns.siswaId: siswaId,
    SuratColumns.tipe: tipe.value,
    SuratColumns.tanggal: tanggal.toIso8601String(),
    SuratColumns.alasan: alasan,
    SuratColumns.keterangan: keterangan,
    SuratColumns.createdAt: createdAt.toIso8601String(),
    SuratColumns.updatedAt: updatedAt?.toIso8601String(),
  };

  /// Create a copy of this Surat with some fields replaced
  Surat copyWith({
    int? id,
    int? siswaId,
    LetterType? tipe,
    DateTime? tanggal,
    String? alasan,
    String? keterangan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Surat(
      id: id ?? this.id,
      siswaId: siswaId ?? this.siswaId,
      tipe: tipe ?? this.tipe,
      tanggal: tanggal ?? this.tanggal,
      alasan: alasan ?? this.alasan,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Surat(id: $id, siswaId: $siswaId, tipe: ${tipe.value}, tanggal: $tanggal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Surat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          siswaId == other.siswaId &&
          tipe == other.tipe;

  @override
  int get hashCode => id.hashCode ^ siswaId.hashCode ^ tipe.hashCode;
}
