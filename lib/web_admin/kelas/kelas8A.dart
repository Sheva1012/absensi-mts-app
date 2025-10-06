import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas8A extends StatelessWidget {
  const Kelas8A({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Muhammad Rifqi', 'waktu': '07:58', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Siti Nurhaliza', 'waktu': '08:12', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Ahmad Fadli', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Rina Kartika', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Bayu Prakoso', 'waktu': '07:55', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Dina Amelia', 'waktu': '08:20', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Rangga Aditya', 'waktu': '08:01', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Novi Rahmawati', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': '-'},
    ];

    return PageKelas(
      className: 'Kelas 8A',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}