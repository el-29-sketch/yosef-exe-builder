import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';

class DashboardGuru extends StatefulWidget {
  final String kodeRuangan;

  const DashboardGuru({super.key, required this.kodeRuangan});

  @override
  State<DashboardGuru> createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  final TextEditingController _menitController = TextEditingController();
  final TextEditingController _pertanyaanController = TextEditingController();

  List<TextEditingController> _opsiControllers = [
    TextEditingController(), // A
    TextEditingController(), // B
    TextEditingController(), // C
    TextEditingController(), // D
  ];

  String _tipeSoal = 'Pilihan Ganda';
  int _kunciJawabanIndex = 0;

  @override
  void dispose() {
    _menitController.dispose();
    _pertanyaanController.dispose();
    for (var controller in _opsiControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _tambahSoalManual() async {
    if (_pertanyaanController.text.isEmpty) {
      _showModernSnackbar('Pertanyaan tidak boleh kosong!', Colors.orange);
      return;
    }

    if (_tipeSoal == 'Pilihan Ganda') {
      bool adaOpsiKosong = _opsiControllers.any((c) => c.text.trim().isEmpty);
      if (adaOpsiKosong) {
        _showModernSnackbar(
          'Semua kotak pilihan ganda harus diisi!',
          Colors.orange,
        );
        return;
      }
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
                ...List.generate(_opsiControllers.length, (index) {
                  String abjad = String.fromCharCode(65 + index);
                  return _buildPreviewOpsi(abjad, _opsiControllers[index].text);
                }),
                const SizedBox(height: 16),
                Text(
                  'Kunci Jawaban: ${String.fromCharCode(65 + _kunciJawabanIndex)}',
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
      List<String> semuaOpsiText = _opsiControllers
          .map((c) => c.text.trim())
          .toList();
      String stringKunciJawaban = String.fromCharCode(65 + _kunciJawabanIndex);

      await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('soal')
          .add({
            'tipe_soal': _tipeSoal == 'Pilihan Ganda' ? 'pilgan' : 'esai',
            'pertanyaan': _pertanyaanController.text.trim(),
            'opsi': _tipeSoal == 'Pilihan Ganda' ? semuaOpsiText : [],
            'KunciJawaban': _tipeSoal == 'Pilihan Ganda'
                ? stringKunciJawaban
                : '',
            'dibuat_pada': FieldValue.serverTimestamp(),
          });

      _pertanyaanController.clear();
      for (var controller in _opsiControllers) {
        controller.clear();
      }
      setState(() {
        _kunciJawabanIndex = 0;
      });

      if (mounted) {
        _showModernSnackbar(
          'Soal berhasil disimpan ke Ruangan ${widget.kodeRuangan}!',
          Colors.green,
        );
      }
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

      if (mounted) {
        _showModernSnackbar(
          'Ruangan ${widget.kodeRuangan} telah dibersihkan!',
          Colors.red,
        );
      }
    }
  }

  Future<void> _aturDanMulaiUjian() async {
    String menitTeks = _menitController.text.trim();
    int? menitUjian = int.tryParse(menitTeks);
    if (menitUjian == null || menitUjian <= 0) {
      return _showModernSnackbar(
        'Durasi WAJIB diisi angka valid!',
        Colors.orange,
      );
    }

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

  Future<void> _exportKeExcel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      var snapshotSoal = await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('soal')
          .get();
      var snapshotHasil = await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(widget.kodeRuangan)
          .collection('hasil')
          .orderBy('nama')
          .get();

      var listSoalUrut = snapshotSoal.docs.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      var excel = Excel.createExcel();
      var sheet = excel['Hasil Ujian'];
      excel.setDefaultSheet('Hasil Ujian');

      List<CellValue> headers = [
        TextCellValue('No'),
        TextCellValue('Nama Lengkap'),
        TextCellValue('Kelas'),
        TextCellValue('Absen'),
        TextCellValue('Skor Pilgan'),
        TextCellValue('Status Ujian'),
      ];

      for (int i = 0; i < listSoalUrut.length; i++) {
        var qData = listSoalUrut[i].data();
        String pertanyaanAsli =
            qData['pertanyaan']?.toString() ?? 'Soal ${i + 1}';
        headers.add(TextCellValue(pertanyaanAsli));
      }
      sheet.appendRow(headers);

      int nomor = 1;
      for (var doc in snapshotHasil.docs) {
        var data = doc.data();
        var detail = data['jawaban_detail'] as Map<String, dynamic>? ?? {};

        String status = 'Selesai';
        if (data['alasan'] == 'waktu') status = 'Waktu Habis';
        if (data['alasan'] == 'guru') status = 'Ditutup Guru';
        if (data['alasan'] == 'kecurangan_pindah_tab') {
          status = 'TERCIDUK CURANG';
        }

        List<CellValue> barisSiswa = [
          IntCellValue(nomor++),
          TextCellValue(data['nama']?.toString() ?? ''),
          TextCellValue(data['kelas']?.toString() ?? ''),
          TextCellValue(data['absen']?.toString() ?? ''),
          DoubleCellValue(
            double.tryParse(data['skor_pilgan']?.toString() ?? '0') ?? 0.0,
          ),
          TextCellValue(status),
        ];

        for (int i = 1; i <= listSoalUrut.length; i++) {
          String key = 'soal_nomor_$i';
          String jawabanSiswa = '';
          if (detail.containsKey(key)) {
            var item = detail[key];
            if (item is Map) {
              jawabanSiswa = item['jawaban_siswa']?.toString() ?? '';
            } else {
              jawabanSiswa = item.toString();
            }
          }
          barisSiswa.add(TextCellValue(jawabanSiswa));
        }

        sheet.appendRow(barisSiswa);
      }

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        Uint8List bytes = Uint8List.fromList(fileBytes);
        await FileSaver.instance.saveFile(
          name: 'Hasil_Ujian_Ruang_${widget.kodeRuangan}.xlsx',
          bytes: bytes,
          mimeType: MimeType.microsoftExcel,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        _showModernSnackbar(
          'Berhasil mengekspor hasil ke Excel!',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showModernSnackbar('Gagal mengekspor: $e', Colors.red);
      }
    }
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
                    String teksPertanyaan = '';

                    if (item is Map<String, dynamic>) {
                      jawabanSiswa = item['jawaban_siswa'] ?? '';
                      tipe = item['tipe'] ?? 'pilgan';
                      status = item['status'] ?? '';
                      kunci = item['kunci'] ?? '';
                      teksPertanyaan = item['pertanyaan'] ?? '';
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
                                  const SizedBox(height: 6),
                                  if (teksPertanyaan.isNotEmpty)
                                    Text(
                                      teksPertanyaan,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  const Divider(),
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

    // PANEL SISWA TERBLOKIR (Diperbaiki agar teks tidak overflow)
    Widget panelSiswaTerblokir = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gpp_bad_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Siswa Terblokir (Curang)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ruangan')
                  .doc(widget.kodeRuangan)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('Belum ada data.');
                }
                var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                List<dynamic> daftarBlokir = data['siswa_diblokir'] ?? [];

                if (daftarBlokir.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green),
                        SizedBox(width: 10),
                        // DIPERBAIKI: Menggunakan Expanded agar teks otomatis membungkus ke bawah
                        Expanded(
                          child: Text(
                            'Aman! Tidak ada siswa yang terindikasi curang.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: daftarBlokir.length,
                  itemBuilder: (context, index) {
                    String noAbsen = daftarBlokir[index].toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Menggunakan Expanded agar teks absen tidak menabrak tombol
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Absen: $noAbsen',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tombol Buka Blokir dengan ukuran ringkas
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              side: BorderSide(color: Colors.red.shade300),
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('ruangan')
                                  .doc(widget.kodeRuangan)
                                  .update({
                                    'siswa_diblokir': FieldValue.arrayRemove([
                                      noAbsen,
                                    ]),
                                  });
                              _showModernSnackbar(
                                'Blokir absen $noAbsen berhasil dibuka!',
                                Colors.green,
                              );
                            },
                            icon: const Icon(Icons.lock_open_rounded, size: 14),
                            label: const Text(
                              'Buka',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
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
                  child: Text('Pilihan Ganda (Dinamis)'),
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
            const SizedBox(height: 24),

            if (_tipeSoal == 'Pilihan Ganda') ...[
              const Text(
                'Pilihan Jawaban (Tandai bulat hijau untuk kunci jawaban):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              ...List.generate(_opsiControllers.length, (index) {
                String abjad = String.fromCharCode(65 + index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _kunciJawabanIndex,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) =>
                            setState(() => _kunciJawabanIndex = val!),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _opsiControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Opsi $abjad',
                            prefixText: '$abjad. ',
                          ),
                        ),
                      ),
                      if (_opsiControllers.length > 2)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _opsiControllers[index].dispose();
                              _opsiControllers.removeAt(index);
                              if (_kunciJawabanIndex >=
                                  _opsiControllers.length) {
                                _kunciJawabanIndex =
                                    _opsiControllers.length - 1;
                              }
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _opsiControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Tambah Pilihan Baru'),
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

    Widget panelDaftarSoal = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt_rounded, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text(
                  'Daftar Soal Tersimpan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 30),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ruangan')
                  .doc(widget.kodeRuangan)
                  .collection('soal')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty)
                  return const Text('Belum ada soal dibuat.');

                var listSoal = snapshot.data!.docs.toList()
                  ..sort((a, b) => a.id.compareTo(b.id));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listSoal.length,
                  itemBuilder: (context, index) {
                    var doc = listSoal[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF4F46E5,
                          ).withOpacity(0.1),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          data['pertanyaan'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          data['tipe_soal'] == 'pilgan'
                              ? 'Kunci: ${data['KunciJawaban']}'
                              : 'Esai',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            doc.reference.delete();
                            _showModernSnackbar(
                              'Soal berhasil dihapus',
                              Colors.red,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
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
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          panelPengaturan,
                          const SizedBox(height: 24),
                          panelSiswaTerblokir,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          panelInputSoal,
                          const SizedBox(height: 24),
                          panelDaftarSoal,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    panelPengaturan,
                    const SizedBox(height: 24),
                    panelSiswaTerblokir,
                    const SizedBox(height: 24),
                    panelInputSoal,
                    const SizedBox(height: 24),
                    panelDaftarSoal,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _exportKeExcel,
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text('Export Excel'),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
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
