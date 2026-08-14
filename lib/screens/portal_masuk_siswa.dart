import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'layar_ujian_siswa.dart';

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
    String absenSiswa = _absenController.text.trim();

    try {
      final docRuangan = await FirebaseFirestore.instance
          .collection('ruangan')
          .doc(kodeYangDiketik)
          .get();

      if (!docRuangan.exists) {
        setState(() => _sedangMengecek = false);
        _showError('Kode Ruangan Tidak Ditemukan!');
        return;
      }

      final dataRuangan = docRuangan.data()!;
      final bool ujianDimulai = dataRuangan['ujian_dimulai'] ?? false;
      final int durasi = dataRuangan['durasi_menit'] ?? 15;

      // BARU: Cek apakah nomor absen ini masuk dalam daftar blokir (diskualifikasi)
      List<dynamic> daftarBlokir = dataRuangan['siswa_diblokir'] ?? [];
      if (daftarBlokir.contains(absenSiswa)) {
        setState(() => _sedangMengecek = false);
        _tampilkanPeringatanBlokir();
        return;
      }

      if (!ujianDimulai) {
        setState(() => _sedangMengecek = false);
        _showError(
          'Ujian belum dibuka oleh Guru di ruangan ini. Tunggu aba-aba!',
        );
        return;
      }

      setState(() => _sedangMengecek = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LayarUjianSiswa(
            kodeRuangan: kodeYangDiketik,
            durasiMenit: durasi,
            namaSiswa: _namaController.text.trim().toUpperCase(),
            kelasSiswa: _kelasController.text.trim().toUpperCase(),
            absenSiswa: absenSiswa,
          ),
        ),
      );
    } catch (e) {
      setState(() => _sedangMengecek = false);
      _showError('Terjadi kesalahan koneksi: $e');
    }
  }

  // BARU: Dialog khusus jika siswa mencoba masuk saat diblokir
  void _tampilkanPeringatanBlokir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              'Akses Ditolak!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Nomor absen Anda tercatat melakukan kecurangan (keluar layar ujian) dan telah didiskualifikasi.\n\nSilakan lapor kepada Guru pengawas untuk meminta persetujuan membuka blokir.',
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
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
