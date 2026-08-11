import 'dart:async';
import 'package:flutter/foundation.dart'; // Menggunakan ini agar aman untuk Web
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Deteksi Desktop yang 100% Aman untuk Web
  bool isDesktopOS =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  if (isDesktopOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 800),
      center: true,
      title: 'Yosef Examination System',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const YosefExamApp());
}

class YosefExamApp extends StatelessWidget {
  const YosefExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yosef Examination System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFF10B981),
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Bagian cardTheme biang keroknya sudah saya musnahkan dari sini!
      ),
      home: const HalamanPilihPeran(),
    );
  }
}

// ==========================================
// 1. HALAMAN PILIH PERAN & KEAMANAN GURU
// ==========================================
class HalamanPilihPeran extends StatelessWidget {
  const HalamanPilihPeran({super.key});

  void _mintaPinGuru(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    const String pinRahasia = "admin123";

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

// ==========================================
// 2. DASHBOARD GURU
// ==========================================
class DashboardGuru extends StatefulWidget {
  final String kodeRuangan;

  const DashboardGuru({super.key, required this.kodeRuangan});

  @override
  State<DashboardGuru> createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  final TextEditingController _menitController = TextEditingController();
  final TextEditingController _pertanyaanController = TextEditingController();
  final TextEditingController _opsiAController = TextEditingController();
  final TextEditingController _opsiBController = TextEditingController();
  final TextEditingController _opsiCController = TextEditingController();
  final TextEditingController _opsiDController = TextEditingController();

  String _tipeSoal = 'Pilihan Ganda';
  String _kunciPilihan = 'A';

  Future<void> _tambahSoalManual() async {
    if (_pertanyaanController.text.isEmpty) {
      _showModernSnackbar('Pertanyaan tidak boleh kosong!', Colors.orange);
      return;
    }
    if (_tipeSoal == 'Pilihan Ganda' &&
        (_opsiAController.text.isEmpty ||
            _opsiBController.text.isEmpty ||
            _opsiCController.text.isEmpty ||
            _opsiDController.text.isEmpty)) {
      _showModernSnackbar('Semua Opsi A, B, C, D harus diisi!', Colors.orange);
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Preview Soal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tipe: $_tipeSoal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pertanyaan:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                _pertanyaanController.text.trim(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (_tipeSoal == 'Pilihan Ganda') ...[
                _buildPreviewOpsi('A', _opsiAController.text),
                _buildPreviewOpsi('B', _opsiBController.text),
                _buildPreviewOpsi('C', _opsiCController.text),
                _buildPreviewOpsi('D', _opsiDController.text),
                const SizedBox(height: 16),
                Text(
                  'Kunci Jawaban: $_kunciPilihan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '[Kotak isian esai siswa]',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal/Edit',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('soal')
          .add({
            'tipe_soal': _tipeSoal == 'Pilihan Ganda' ? 'pilgan' : 'esai',
            'pertanyaan': _pertanyaanController.text.trim(),
            'opsiA': _tipeSoal == 'Pilihan Ganda'
                ? _opsiAController.text.trim()
                : '',
            'opsiB': _tipeSoal == 'Pilihan Ganda'
                ? _opsiBController.text.trim()
                : '',
            'opsiC': _tipeSoal == 'Pilihan Ganda'
                ? _opsiCController.text.trim()
                : '',
            'opsiD': _tipeSoal == 'Pilihan Ganda'
                ? _opsiDController.text.trim()
                : '',
            'KunciJawaban': _tipeSoal == 'Pilihan Ganda' ? _kunciPilihan : '',
          });

      _pertanyaanController.clear();
      _opsiAController.clear();
      _opsiBController.clear();
      _opsiCController.clear();
      _opsiDController.clear();
      if (mounted)
        _showModernSnackbar(
          'Soal berhasil disimpan ke Ruangan ${widget.kodeRuangan}!',
          Colors.green,
        );
    }
  }

  Widget _buildPreviewOpsi(String label, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label. ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(teks.trim())),
        ],
      ),
    );
  }

  void _showModernSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _hapusSemuaData() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Reset Sistem?'),
          ],
        ),
        content: Text(
          'Hapus seluruh SOAL dan HASIL UJIAN siswa HANYA dari Ruangan ${widget.kodeRuangan} secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      var snapshotSoal = await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('soal')
          .get();
      for (var doc in snapshotSoal.docs) await doc.reference.delete();
      var snapshotHasil = await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('hasil')
          .get();
      for (var doc in snapshotHasil.docs) await doc.reference.delete();

      if (mounted)
        _showModernSnackbar(
          'Ruangan ${widget.kodeRuangan} telah dibersihkan!',
          Colors.red,
        );
    }
  }

  Future<void> _aturDanMulaiUjian() async {
    String menitTeks = _menitController.text.trim();
    int? menitUjian = int.tryParse(menitTeks);
    if (menitUjian == null || menitUjian <= 0)
      return _showModernSnackbar(
        'Durasi WAJIB diisi angka valid!',
        Colors.orange,
      );

    await FirebaseFirestore.instance
        .collection('ruangan')
        .doc(widget.kodeRuangan)
        .set({
          'durasi_menit': menitUjian,
          'ujian_dimulai': true,
        }, SetOptions(merge: true));

    _showModernSnackbar(
      'Ujian DIBUKA! Siswa sekarang bisa masuk ke Ruangan ${widget.kodeRuangan}.',
      const Color(0xFF4F46E5),
    );
  }

  Future<void> _tutupUjian() async {
    await FirebaseFirestore.instance
        .collection('ruangan')
        .doc(widget.kodeRuangan)
        .set({'ujian_dimulai': false}, SetOptions(merge: true));

    _showModernSnackbar('Ujian DITUTUP. Akses siswa ditarik!', Colors.red);
  }

  void _tampilkanDetailJawaban(
    BuildContext context,
    Map<String, dynamic> dataSiswa,
  ) {
    final Map<String, dynamic> detail = dataSiswa['jawaban_detail'] ?? {};
    var sortedKeys = detail.keys.toList()
      ..sort((a, b) {
        int numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        int numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Review: ${dataSiswa['nama']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 600,
          child: detail.isEmpty
              ? const Text('Tidak ada detail jawaban.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    String key = sortedKeys[index];
                    var item = detail[key];

                    String jawabanSiswa = '';
                    String tipe = 'pilgan';
                    String status = '';
                    String kunci = '';

                    if (item is Map<String, dynamic>) {
                      jawabanSiswa = item['jawaban_siswa'] ?? '';
                      tipe = item['tipe'] ?? 'pilgan';
                      status = item['status'] ?? '';
                      kunci = item['kunci'] ?? '';
                    } else if (item is String) {
                      jawabanSiswa = item;
                    }

                    Color cardColor = Colors.grey.shade50;
                    Widget trailingIcon = const SizedBox();

                    if (tipe == 'pilgan') {
                      if (status == 'benar') {
                        cardColor = Colors.green.shade50;
                        trailingIcon = const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 32,
                        );
                      } else if (status == 'salah') {
                        cardColor = Colors.red.shade50;
                        trailingIcon = const Icon(
                          Icons.cancel_rounded,
                          color: Colors.red,
                          size: 32,
                        );
                      }
                    } else if (tipe == 'esai') {
                      cardColor = Colors.orange.shade50;
                      trailingIcon = const Icon(
                        Icons.article_rounded,
                        color: Colors.orange,
                        size: 32,
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    key.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    jawabanSiswa.isEmpty
                                        ? '(Tidak dijawab)'
                                        : jawabanSiswa,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (tipe == 'pilgan' &&
                                      status == 'salah') ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Kunci Benar: $kunci',
                                        style: TextStyle(
                                          color: Colors.red.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            trailingIcon,
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup Review'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Dashboard Guru - Ruang: ${widget.kodeRuangan}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            tabs: [
              Tab(
                icon: Icon(Icons.dashboard_customize_rounded),
                text: 'Manajemen Ujian',
              ),
              Tab(
                icon: Icon(Icons.analytics_rounded),
                text: 'Hasil Ujian Live',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildTabManajemenUjian(), _buildTabHasilUjian()],
        ),
      ),
    );
  }

  Widget _buildTabManajemenUjian() {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    Widget panelPengaturan = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings_suggest_rounded, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text(
                  'Pengaturan Ujian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            TextField(
              controller: _menitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durasi Ujian (Menit)',
                prefixIcon: Icon(Icons.timer_rounded),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _aturDanMulaiUjian,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('BUKA UJIAN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _tutupUjian,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('TUTUP UJIAN'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _hapusSemuaData,
                icon: const Icon(Icons.delete_sweep_rounded),
                label: const Text('RESET SEMUA DATA RUANGAN'),
              ),
            ),
          ],
        ),
      ),
    );

    Widget panelInputSoal = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.post_add_rounded, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text(
                  'Input Soal Ujian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            DropdownButtonFormField<String>(
              value: _tipeSoal,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: const [
                DropdownMenuItem(
                  value: 'Pilihan Ganda',
                  child: Text('Pilihan Ganda (A, B, C, D)'),
                ),
                DropdownMenuItem(
                  value: 'Esai',
                  child: Text('Esai (Teks Panjang)'),
                ),
              ],
              onChanged: (val) => setState(() => _tipeSoal = val!),
              decoration: const InputDecoration(labelText: 'Tipe Soal'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pertanyaanController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Tuliskan Pertanyaan...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (_tipeSoal == 'Pilihan Ganda') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _opsiAController,
                      decoration: const InputDecoration(labelText: 'Opsi A'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _opsiBController,
                      decoration: const InputDecoration(labelText: 'Opsi B'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _opsiCController,
                      decoration: const InputDecoration(labelText: 'Opsi C'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _opsiDController,
                      decoration: const InputDecoration(labelText: 'Opsi D'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _kunciPilihan,
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Kunci Jawaban: A')),
                  DropdownMenuItem(value: 'B', child: Text('Kunci Jawaban: B')),
                  DropdownMenuItem(value: 'C', child: Text('Kunci Jawaban: C')),
                  DropdownMenuItem(value: 'D', child: Text('Kunci Jawaban: D')),
                ],
                onChanged: (val) => setState(() => _kunciPilihan = val!),
                decoration: const InputDecoration(
                  labelText: 'Pilih Kunci yang Benar',
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Siswa akan mendapatkan kotak teks kosong untuk menjawab. Kunci jawaban tidak diperlukan.',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                onPressed: _tambahSoalManual,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Simpan Soal ke Database'),
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: panelPengaturan),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: panelInputSoal),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    panelPengaturan,
                    const SizedBox(height: 24),
                    panelInputSoal,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTabHasilUjian() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.radar_rounded, color: Colors.green.shade600),
              const SizedBox(width: 10),
              const Text(
                'Live Monitoring Nilai Siswa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ruangan')
                .doc(widget.kodeRuangan)
                .collection('hasil')
                .orderBy('waktu_submit', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada siswa yang mengumpulkan.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final listHasil = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: listHasil.length,
                itemBuilder: (context, index) {
                  final data = listHasil[index].data() as Map<String, dynamic>;
                  final String nama = data['nama'] ?? 'Tanpa Nama';
                  final String kelas = data['kelas'] ?? '-';
                  final String absen = data['absen'] ?? '-';
                  final double skorPilgan = data['skor_pilgan'] ?? 0.0;
                  final String alasan = data['alasan'] ?? '';

                  String statusTeks = 'Selesai Mandiri';
                  Color statusColor = const Color(0xFF10B981);
                  IconData statusIcon = Icons.check_circle_rounded;

                  if (alasan == 'waktu') {
                    statusTeks = 'Waktu Habis';
                    statusColor = Colors.orange.shade600;
                    statusIcon = Icons.timer_off_rounded;
                  } else if (alasan == 'guru') {
                    statusTeks = 'Ditutup Guru';
                    statusColor = Colors.red.shade500;
                    statusIcon = Icons.stop_circle_rounded;
                  } else if (alasan == 'kecurangan_pindah_tab') {
                    statusTeks = 'TERCIDUK CURANG!';
                    statusColor = Colors.red.shade900;
                    statusIcon = Icons.warning_rounded;
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _tampilkanDetailJawaban(context, data),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(
                                0xFF4F46E5,
                              ).withOpacity(0.1),
                              child: Text(
                                absen,
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nama,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kelas: $kelas',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 14,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusTeks,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'SKOR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  skorPilgan.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: skorPilgan >= 70
                                        ? const Color(0xFF10B981)
                                        : Colors.red.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. PORTAL MASUK SISWA
// ==========================================
class PortalMasukSiswa extends StatefulWidget {
  const PortalMasukSiswa({super.key});

  @override
  State<PortalMasukSiswa> createState() => _PortalMasukSiswaState();
}

class _PortalMasukSiswaState extends State<PortalMasukSiswa> {
  final TextEditingController _kodeInputController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _absenController = TextEditingController();
  bool _sedangMengecek = false;

  Future<void> _cekKodeDanMasuk() async {
    if (_namaController.text.isEmpty ||
        _kelasController.text.isEmpty ||
        _absenController.text.isEmpty ||
        _kodeInputController.text.isEmpty) {
      _showError('Semua kolom identitas dan kode wajib diisi!');
      return;
    }

    setState(() => _sedangMengecek = true);
    String kodeYangDiketik = _kodeInputController.text.trim().toUpperCase();
    final doc = await FirebaseFirestore.instance
        .collection('ruangan')
        .doc(kodeYangDiketik)
        .get();
    setState(() => _sedangMengecek = false);

    if (doc.exists) {
      final data = doc.data()!;
      final bool ujianDimulai = data['ujian_dimulai'] ?? false;
      final int durasi = data['durasi_menit'] ?? 15;

      if (!ujianDimulai) {
        _showError(
          'Ujian belum dibuka oleh Guru di ruangan ini. Tunggu aba-aba!',
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LayarUjianSiswa(
            kodeRuangan: kodeYangDiketik,
            durasiMenit: durasi,
            namaSiswa: _namaController.text.trim().toUpperCase(),
            kelasSiswa: _kelasController.text.trim().toUpperCase(),
            absenSiswa: _absenController.text.trim(),
          ),
        ),
      );
    } else {
      _showError('Kode Ruangan Tidak Ditemukan!');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Portal Masuk Siswa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF10B981), Color(0xFF047857)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Card(
                elevation: 12,
                shadowColor: Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_rounded,
                          size: 50,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Identitas Peserta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _namaController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _kelasController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Kelas',
                                prefixIcon: Icon(Icons.class_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _absenController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'No. Absen',
                                prefixIcon: Icon(
                                  Icons.format_list_numbered_rounded,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _kodeInputController,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: 'KODE RUANGAN',
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          onPressed: _sedangMengecek ? null : _cekKodeDanMasuk,
                          child: _sedangMengecek
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'MASUK KE UJIAN',
                                  style: TextStyle(
                                    fontSize: 18,
                                    letterSpacing: 1,
                                  ),
                                ),
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

// ==========================================
// 4. LAYAR UJIAN SISWA (PENGAMANAN MAKSIMAL DESKTOP & MOBILE)
// ==========================================
class LayarUjianSiswa extends StatefulWidget {
  final String kodeRuangan;
  final int durasiMenit;
  final String namaSiswa;
  final String kelasSiswa;
  final String absenSiswa;

  const LayarUjianSiswa({
    super.key,
    required this.kodeRuangan,
    required this.durasiMenit,
    required this.namaSiswa,
    required this.kelasSiswa,
    required this.absenSiswa,
  });

  @override
  State<LayarUjianSiswa> createState() => _LayarUjianSiswaState();
}

class _LayarUjianSiswaState extends State<LayarUjianSiswa>
    with WidgetsBindingObserver, WindowListener {
  final Map<int, String> jawabanPilihan = {};
  final Map<int, TextEditingController> _essayControllers = {};

  bool sudahDisubmit = false;
  late Timer _timer;
  late int _sisaDetik;

  late Stream<QuerySnapshot> _soalStream;
  StreamSubscription<DocumentSnapshot>? _pantauPerintahGuru;

  // Cek apakah dijalankan di Desktop dengan aman untuk web
  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (isDesktop) {
      windowManager.addListener(this);
      _kunciLayarDesktop();
    }

    _sisaDetik = widget.durasiMenit * 60;
    _soalStream = FirebaseFirestore.instance
        .collection('ruangan')
        .doc(widget.kodeRuangan)
        .collection('soal')
        .snapshots();

    _mulaiTimer();
    _pantauStatusUjianDariGuru();
  }

  Future<void> _kunciLayarDesktop() async {
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setPreventClose(true);
  }

  Future<void> _bukaKunciLayarDesktop() async {
    await windowManager.setFullScreen(false);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setPreventClose(false);
  }

  @override
  void onWindowBlur() {
    if (!sudahDisubmit) {
      _kumpulkanJawabanOtomatis('kecurangan_pindah_tab');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        !sudahDisubmit) {
      _kumpulkanJawabanOtomatis('kecurangan_pindah_tab');
    }
  }

  void _pantauStatusUjianDariGuru() {
    _pantauPerintahGuru = FirebaseFirestore.instance
        .collection('ruangan')
        .doc(widget.kodeRuangan)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            bool ujianMasihAktif =
                snapshot.data().toString().contains('ujian_dimulai: true')
                ? snapshot['ujian_dimulai']
                : false;
            if (!ujianMasihAktif && !sudahDisubmit) {
              _kumpulkanJawabanOtomatis('guru');
            }
          }
        });
  }

  void _mulaiTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sisaDetik > 0) {
        setState(() => _sisaDetik--);
      } else {
        if (!sudahDisubmit) _kumpulkanJawabanOtomatis('waktu');
      }
    });
  }

  Future<void> _kumpulkanJawabanOtomatis(String alasan) async {
    if (sudahDisubmit) return;
    setState(() => sudahDisubmit = true);
    _timer.cancel();

    if (isDesktop) {
      await _bukaKunciLayarDesktop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('soal')
          .get();
      final listSoal = snapshot.docs;

      int jumlahBenar = 0;
      int totalSoalPilgan = 0;
      Map<String, dynamic> rekapJawabanLengkap = {};

      for (int i = 0; i < listSoal.length; i++) {
        final data = listSoal[i].data();
        final tipe = data['tipe_soal'] ?? 'pilgan';
        final kunci = data['KunciJawaban'] ?? '';
        final jawabanSiswa = jawabanPilihan[i] ?? '';

        bool isBenar = false;
        if (tipe == 'pilgan') {
          totalSoalPilgan++;
          if (jawabanSiswa == kunci) {
            jumlahBenar++;
            isBenar = true;
          }
        }

        rekapJawabanLengkap['soal_nomor_${i + 1}'] = {
          'jawaban_siswa': jawabanSiswa,
          'kunci': kunci,
          'tipe': tipe,
          'status': tipe == 'pilgan' ? (isBenar ? 'benar' : 'salah') : 'esai',
        };
      }

      double skorAkhirPilgan = totalSoalPilgan == 0
          ? 0
          : (jumlahBenar / totalSoalPilgan) * 100;
      if (alasan == 'kecurangan_pindah_tab') skorAkhirPilgan = 0.0;

      await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('hasil')
          .add({
            'nama': widget.namaSiswa,
            'kelas': widget.kelasSiswa,
            'absen': widget.absenSiswa,
            'skor_pilgan': skorAkhirPilgan,
            'jawaban_detail': rekapJawabanLengkap,
            'alasan': alasan,
            'waktu_submit': FieldValue.serverTimestamp(),
          });

      if (mounted) Navigator.pop(context);

      String judul = 'Terkumpul!';
      String pesan = 'Ujian selesai. Jawaban Anda telah terkirim.';
      IconData iconRes = Icons.check_circle_rounded;
      Color colorRes = Colors.green;

      if (alasan == 'kecurangan_pindah_tab') {
        judul = 'TERCIDUK CURANG!';
        pesan =
            'Sistem mendeteksi Anda keluar dari layar ujian. Ujian dibatalkan dan jawaban ditarik otomatis!';
        iconRes = Icons.warning_rounded;
        colorRes = Colors.red;
      } else if (alasan == 'waktu') {
        judul = 'Waktu Habis!';
        pesan = 'Waktu ujian berakhir. Jawaban otomatis dikumpulkan.';
        iconRes = Icons.timer_off_rounded;
        colorRes = Colors.orange;
      } else if (alasan == 'guru') {
        judul = 'Ujian Ditutup!';
        pesan = 'Guru telah menutup sesi ujian.';
        iconRes = Icons.stop_circle_rounded;
        colorRes = Colors.red;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconRes, size: 80, color: colorRes),
                const SizedBox(height: 20),
                Text(
                  judul,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: colorRes,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pesan,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorRes,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Kembali ke Menu Utama'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pantauPerintahGuru?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (isDesktop) {
      windowManager.removeListener(this);
      _bukaKunciLayarDesktop();
    }
    for (var controller in _essayControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatWaktu(int detik) {
    int menit = detik ~/ 60;
    int sisaDetik = detik % 60;
    return '${menit.toString().padLeft(2, '0')}:${sisaDetik.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.namaSiswa,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${widget.kelasSiswa} • Absen: ${widget.absenSiswa} • Ruang: ${widget.kodeRuangan}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  sudahDisubmit ? 'SELESAI' : _formatWaktu(_sisaDetik),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.red.shade600,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'JANGAN KELUAR ATAU MEMBUKA APLIKASI LAIN! ANDA AKAN OTOMATIS DIDISKUALIFIKASI!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _soalStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(
                    child: Text('Menunggu soal dari guru...'),
                  );

                final listSoal = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listSoal.length,
                  itemBuilder: (context, index) {
                    final data = listSoal[index].data() as Map<String, dynamic>;
                    final String tipeSoal = data['tipe_soal'] ?? 'pilgan';
                    final String? jawabanUser = jawabanPilihan[index];

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Soal No. ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tipeSoal == 'esai'
                                          ? Colors.orange.shade100
                                          : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tipeSoal == 'esai'
                                          ? 'ESAI'
                                          : 'PILIHAN GANDA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: tipeSoal == 'esai'
                                            ? Colors.orange.shade800
                                            : Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 30),
                              Text(
                                data['pertanyaan'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (tipeSoal == 'pilgan') ...[
                                _buildOpsiModern(
                                  index,
                                  'A',
                                  data['opsiA'] ?? '',
                                  jawabanUser,
                                ),
                                _buildOpsiModern(
                                  index,
                                  'B',
                                  data['opsiB'] ?? '',
                                  jawabanUser,
                                ),
                                _buildOpsiModern(
                                  index,
                                  'C',
                                  data['opsiC'] ?? '',
                                  jawabanUser,
                                ),
                                _buildOpsiModern(
                                  index,
                                  'D',
                                  data['opsiD'] ?? '',
                                  jawabanUser,
                                ),
                              ] else ...[
                                _buildKotakEsaiModern(index),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sudahDisubmit
                          ? Colors.grey
                          : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed: sudahDisubmit
                        ? null
                        : () => _kumpulkanJawabanOtomatis('siswa'),
                    icon: Icon(
                      sudahDisubmit
                          ? Icons.check_circle_rounded
                          : Icons.send_rounded,
                    ),
                    label: Text(
                      sudahDisubmit
                          ? 'JAWABAN TELAH TERKIRIM'
                          : 'KUMPULKAN JAWABAN',
                      style: const TextStyle(fontSize: 18, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpsiModern(
    int indexSoal,
    String label,
    String teks,
    String? jawabanUser,
  ) {
    if (teks.isEmpty) return const SizedBox.shrink();
    bool isSelected = jawabanUser == label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: sudahDisubmit
            ? null
            : () => setState(() => jawabanPilihan[indexSoal] = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981).withOpacity(0.1)
                : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  teks,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.black87 : Colors.black54,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKotakEsaiModern(int indexSoal) {
    if (!_essayControllers.containsKey(indexSoal)) {
      _essayControllers[indexSoal] = TextEditingController(
        text: jawabanPilihan[indexSoal] ?? '',
      );
    }

    return TextField(
      controller: _essayControllers[indexSoal],
      enabled: !sudahDisubmit,
      maxLines: 5,
      onChanged: (val) => jawabanPilihan[indexSoal] = val,
      decoration: InputDecoration(
        hintText: sudahDisubmit
            ? 'Waktu habis, tidak bisa mengetik.'
            : 'Ketik jawaban esai Anda secara lengkap di sini...',
        filled: true,
        fillColor: sudahDisubmit
            ? Colors.grey.shade100
            : Colors.blueGrey.shade50.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
