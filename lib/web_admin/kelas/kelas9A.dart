import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas9A extends StatelessWidget {
  const Kelas9A({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Fadhil Rahman', 'waktu': '07:50', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Sarah Maulida', 'waktu': '08:08', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Wahyu Hidayat', 'waktu': '07:58', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Putri Ayu', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Ilham Maulana', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Laila Sari', 'waktu': '08:15', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Fikri Ramadhan', 'waktu': '07:59', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Siska Dewi', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Rizal Fauzi', 'waktu': '08:01', 'status': 'Hadir', 'suratIzin': '-'},
    ];

    return PageKelas(
      className: 'Kelas 9A',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}