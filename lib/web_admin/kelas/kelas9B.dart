import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas9B extends StatelessWidget {
  const Kelas9B({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Dimas Ardiansyah', 'waktu': '07:54', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Anisa Fitri', 'waktu': '08:12', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Yusuf Habibi', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Maya Safitri', 'waktu': '07:57', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Aldi Prasetyo', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': '-'},
      {'nama': 'Nisa Aulia', 'waktu': '08:18', 'status': 'Terlambat', 'suratIzin': 'Ada'},
      {'nama': 'Farhan Maulana', 'waktu': '08:02', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Ratna Sari', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
    ];

    return PageKelas(
      className: 'Kelas 9B',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}