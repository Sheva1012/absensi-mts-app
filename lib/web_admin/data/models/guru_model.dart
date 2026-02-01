import 'package:web_admin_mts/web_admin/core/constants.dart';

/// Model representing a teacher (Guru)
class Guru {
  final int id;
  final String nip;
  final String nama;
  final String? email;
  final String? noHp;
  final String status;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Guru({
    required this.id,
    required this.nip,
    required this.nama,
    this.email,
    this.noHp,
    required this.status,
    this.fotoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Guru from JSON (typically from Supabase)
  factory Guru.fromJson(Map<String, dynamic> json) {
    return Guru(
      id: json[GuruColumns.id] as int,
      nip: json[GuruColumns.nip] as String? ?? '',
      nama: json[GuruColumns.nama] as String? ?? '',
      email: json[GuruColumns.email] as String?,
      noHp: json[GuruColumns.noHp] as String?,
      status: json[GuruColumns.status] as String? ?? 'aktif',
      fotoUrl: json[GuruColumns.fotoUrl] as String?,
      createdAt: json[GuruColumns.createdAt] != null
          ? DateTime.parse(json[GuruColumns.createdAt] as String)
          : DateTime.now(),
      updatedAt: json[GuruColumns.updatedAt] != null
          ? DateTime.parse(json[GuruColumns.updatedAt] as String)
          : null,
    );
  }

  /// Convert Guru to JSON for sending to Supabase
  Map<String, dynamic> toJson() => {
    GuruColumns.id: id,
    GuruColumns.nip: nip,
    GuruColumns.nama: nama,
    GuruColumns.email: email,
    GuruColumns.noHp: noHp,
    GuruColumns.status: status,
    GuruColumns.fotoUrl: fotoUrl,
    GuruColumns.createdAt: createdAt.toIso8601String(),
    GuruColumns.updatedAt: updatedAt?.toIso8601String(),
  };

  /// Create a copy of this Guru with some fields replaced
  Guru copyWith({
    int? id,
    String? nip,
    String? nama,
    String? email,
    String? noHp,
    String? status,
    String? fotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guru(
      id: id ?? this.id,
      nip: nip ?? this.nip,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      status: status ?? this.status,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Guru(id: $id, nip: $nip, nama: $nama)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Guru &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nip == other.nip;

  @override
  int get hashCode => id.hashCode ^ nip.hashCode;
}
