import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas7B extends StatelessWidget {
  const Kelas7B({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Ahmad Yusuf', 'waktu': '07:58', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Siti Aminah', 'waktu': '08:10', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Rizki Pratama', 'waktu': '08:02', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Putri Wulandari', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Dimas Anggara', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
    ];

    return PageKelas(
      className: 'Kelas 7B',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}