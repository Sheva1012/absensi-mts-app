import 'package:flutter/material.dart';
import 'page_kelas.dart';

class Kelas9C extends StatelessWidget {
  const Kelas9C({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSiswa = [
      {'nama': 'Hadi Susanto', 'waktu': '07:56', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Eka Fitriani', 'waktu': '08:14', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Riski Firmansyah', 'waktu': '08:01', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Dewi Kusuma', 'waktu': '07:59', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Reza Pahlevi', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': 'Ada'},
      {'nama': 'Fitri Handayani', 'waktu': '08:20', 'status': 'Terlambat', 'suratIzin': '-'},
      {'nama': 'Aditya Nugraha', 'waktu': '08:00', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Vina Melinda', 'waktu': '-', 'status': 'Tidak Hadir', 'suratIzin': '-'},
      {'nama': 'Galang Pratama', 'waktu': '07:58', 'status': 'Hadir', 'suratIzin': '-'},
      {'nama': 'Zahra Amalia', 'waktu': '08:03', 'status': 'Hadir', 'suratIzin': '-'},
    ];

    return PageKelas(
      className: 'Kelas 9C',
      adminName: 'Admin User',
      schoolName: 'MTs Sunan Gunung Jati',
      studentData: dataSiswa,
    );
  }
}