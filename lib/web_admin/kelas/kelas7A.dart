import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas7A extends StatelessWidget {
  const Kelas7A({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Andi Doe', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Budi Smith', 'waktu': '08:05', 'status': 'Terlambat', 'suratIzin': 'Ada'},
      {'nama': 'Citra Johnson', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Dewi Fitriani', 'waktu': '07:55', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Eka Pratama', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': '-'},
      {'nama': 'Fajar Nugroho', 'waktu': '08:15', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Gilang Ramadhan', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Hani Indah', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
    ];

    return PageKelas(
      className: 'Kelas 7A',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}