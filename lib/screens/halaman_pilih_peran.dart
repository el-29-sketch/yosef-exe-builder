import 'package:flutter/material.dart';
import 'dashboard_guru.dart';
import 'portal_masuk_siswa.dart';

class HalamanPilihPeran extends StatelessWidget {
  const HalamanPilihPeran({super.key});

  void _mintaPinGuru(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    const String pinRahasia = "HanyaGuruYangTahu_1951";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isObscured = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF4F46E5)),
                  SizedBox(width: 10),
                  Text(
                    'Otorisasi Guru',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Masukkan PIN Admin untuk mengakses sistem:'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    obscureText: isObscured,
                    decoration: InputDecoration(
                      hintText: 'PIN Rahasia',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscured ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => isObscured = !isObscured),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (pinController.text == pinRahasia) {
                      Navigator.pop(context);
                      _mintaKodeRuanganGuru(context);
                    } else {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.white),
                              SizedBox(width: 10),
                              Text('AKSES DITOLAK! PIN salah.'),
                            ],
                          ),
                          backgroundColor: Colors.red.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Lanjut'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mintaKodeRuanganGuru(BuildContext context) {
    final TextEditingController roomController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.meeting_room_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Text(
                'Pilih/Buat Ruangan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan Kode Ruangan untuk dikelola (Cth: FISIKA10). Jika belum ada, sistem akan membuatkannya.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: roomController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'KODE RUANGAN',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (roomController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardGuru(
                        kodeRuangan: roomController.text.trim().toUpperCase(),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Masuk Ruangan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 60,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Yosef Exam System',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih portal akses Anda untuk melanjutkan',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _mintaPinGuru(context),
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                          label: const Text('Portal Guru'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PortalMasukSiswa(),
                            ),
                          ),
                          icon: const Icon(Icons.person_rounded),
                          label: const Text('Portal Siswa'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
