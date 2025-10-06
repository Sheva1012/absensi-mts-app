import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas7C extends StatelessWidget {
  const Kelas7C({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Faisal Abdullah', 'waktu': '07:55', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Nadia Safira', 'waktu': '08:20', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Irfan Hakim', 'waktu': '08:01', 'status': 'Hadir', 'suratIzin': '-'},
    ];

    return PageKelas(
      className: 'Kelas 7C',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}