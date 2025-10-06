import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas8C extends StatelessWidget {
  const Kelas8C({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Hendra Wijaya', 'waktu': '07:56', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Tia Rahayu', 'waktu': '08:10', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Kevin Saputra', 'waktu': '08:02', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Wulan Sari', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Denny Firmansyah', 'waktu': '07:58', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Riska Anggraini', 'waktu': '08:22', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Agung Prasetyo', 'waktu': '08:01', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Lina Marlina', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': '-'},
      {'nama': 'Bima Sakti', 'waktu': '07:55', 'status': 'Hadir', 'suratIzin': '-'},
    ];

    return PageKelas(
      className: 'Kelas 8C',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}