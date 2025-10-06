import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas8B extends StatelessWidget {
  const Kelas8B({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Yoga Pratama', 'waktu': '07:52', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Lestari Wulan', 'waktu': '08:15', 'status': 'Terlambat', 'suratIzin': 'Ada'},
      {'nama': 'Fauzan Hakim', 'waktu': '08:03', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Mega Putri', 'waktu': '07:59', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Arif Setiawan', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Indah Permata', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Rendi Cahyono', 'waktu': '08:18', 'status': 'Terlambat', 'suratIzin': '-'},
    ];

    return PageKelas(
      className: 'Kelas 8B',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}