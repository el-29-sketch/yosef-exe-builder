import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:window_manager/window_manager.dart';

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
  final Map<String, String> jawabanPilihan = {};
  final Map<String, TextEditingController> _essayControllers = {};

  List<QueryDocumentSnapshot> _shuffledSoal = [];
  bool _isShuffled = false;

  bool sudahDisubmit = false;
  late Timer _timer;
  late int _sisaDetik;

  late Stream<QuerySnapshot> _soalStream;
  StreamSubscription<DocumentSnapshot>? _pantauPerintahGuru;

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

    // BARU: Jika alasan kecurangan, masukkan nomor absen ke daftar blokir database ruangan
    if (alasan == 'kecurangan_pindah_tab') {
      try {
        await FirebaseFirestore.instance
            .collection('ruangan')
            .doc(widget.kodeRuangan)
            .update({
              'siswa_diblokir': FieldValue.arrayUnion([widget.absenSiswa]),
            });
      } catch (e) {
        // Jika dokumen ruangan belum ada field array-nya, buat menggunakan set merge
        await FirebaseFirestore.instance
            .collection('ruangan')
            .doc(widget.kodeRuangan)
            .set({
              'siswa_diblokir': [widget.absenSiswa],
            }, SetOptions(merge: true));
      }
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

      var listSoalAsli = snapshot.docs.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      int jumlahBenar = 0;
      int totalSoalPilgan = 0;
      Map<String, dynamic> rekapJawabanLengkap = {};

      for (int i = 0; i < listSoalAsli.length; i++) {
        final doc = listSoalAsli[i];
        final data = doc.data();
        final tipe = data['tipe_soal'] ?? 'pilgan';
        final kunci = data['KunciJawaban'] ?? '';
        final pertanyaan = data['pertanyaan'] ?? '';
        final jawabanSiswa = jawabanPilihan[doc.id] ?? '';

        bool isBenar = false;
        if (tipe == 'pilgan') {
          totalSoalPilgan++;
          if (jawabanSiswa == kunci) {
            jumlahBenar++;
            isBenar = true;
          }
        }

        rekapJawabanLengkap['soal_nomor_${i + 1}'] = {
          'pertanyaan': pertanyaan,
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
            'Sistem mendeteksi Anda keluar dari layar ujian. Nomor absen Anda telah diblokir dan ujian dibatalkan!';
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Menunggu soal dari guru...'),
                  );
                }

                var listSoalAsli = snapshot.data!.docs.toList()
                  ..sort((a, b) => a.id.compareTo(b.id));

                if (!_isShuffled ||
                    _shuffledSoal.length != listSoalAsli.length) {
                  _shuffledSoal = List.from(listSoalAsli)..shuffle();
                  _isShuffled = true;
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _shuffledSoal.length,
                  itemBuilder: (context, index) {
                    final docSoal = _shuffledSoal[index];
                    final String idSoal = docSoal.id;
                    final data = docSoal.data() as Map<String, dynamic>;
                    final String tipeSoal = data['tipe_soal'] ?? 'pilgan';
                    final String? jawabanUser = jawabanPilihan[idSoal];

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
                                if (data['opsi'] != null &&
                                    data['opsi'] is List) ...[
                                  ...List.generate(
                                    (data['opsi'] as List).length,
                                    (opsiIndex) {
                                      String abjad = String.fromCharCode(
                                        65 + opsiIndex,
                                      );
                                      return _buildOpsiModern(
                                        idSoal,
                                        abjad,
                                        data['opsi'][opsiIndex].toString(),
                                        jawabanUser,
                                      );
                                    },
                                  ),
                                ] else ...[
                                  _buildOpsiModern(
                                    idSoal,
                                    'A',
                                    data['opsiA'] ?? '',
                                    jawabanUser,
                                  ),
                                  _buildOpsiModern(
                                    idSoal,
                                    'B',
                                    data['opsiB'] ?? '',
                                    jawabanUser,
                                  ),
                                  _buildOpsiModern(
                                    idSoal,
                                    'C',
                                    data['opsiC'] ?? '',
                                    jawabanUser,
                                  ),
                                  _buildOpsiModern(
                                    idSoal,
                                    'D',
                                    data['opsiD'] ?? '',
                                    jawabanUser,
                                  ),
                                ],
                              ] else ...[
                                _buildKotakEsaiModern(idSoal),
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
    String idSoal,
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
            : () => setState(() => jawabanPilihan[idSoal] = label),
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

  Widget _buildKotakEsaiModern(String idSoal) {
    if (!_essayControllers.containsKey(idSoal)) {
      _essayControllers[idSoal] = TextEditingController(
        text: jawabanPilihan[idSoal] ?? '',
      );
    }

    return TextField(
      controller: _essayControllers[idSoal],
      enabled: !sudahDisubmit,
      maxLines: 5,
      onChanged: (val) => jawabanPilihan[idSoal] = val,
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
