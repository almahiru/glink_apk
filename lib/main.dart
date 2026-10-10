import 'package:flutter/material.dart';

void main() => runApp(const IspApp());

// ---------- Model & State (data contoh, ganti dengan API ISP Anda) ----------

class Paket {
  final String nama;
  final int mbps;
  final int harga;
  const Paket(this.nama, this.mbps, this.harga);
}

class Tagihan {
  final String periode;
  final int jumlah;
  bool lunas;
  Tagihan(this.periode, this.jumlah, {this.lunas = false});
}

class Tiket {
  final String judul;
  final String deskripsi;
  String status;
  Tiket(this.judul, this.deskripsi, {this.status = 'Dibuka'});
}

const daftarPaket = [
  Paket('Home 10', 10, 150000),
  Paket('Home 20', 20, 250000),
  Paket('Home 50', 50, 400000),
  Paket('Home 100', 100, 650000),
];

class AppState extends ChangeNotifier {
  Paket paketAktif = daftarPaket[1];
  final List<Tagihan> tagihan = [
    Tagihan('Oktober 2026', 250000),
    Tagihan('September 2026', 250000, lunas: true),
    Tagihan('Agustus 2026', 250000, lunas: true),
  ];
  final List<Tiket> tiket = [];

  int get totalBelumLunas =>
      tagihan.where((t) => !t.lunas).fold(0, (s, t) => s + t.jumlah);

  void gantiPaket(Paket p) {
    paketAktif = p;
    notifyListeners();
  }

  void bayar(Tagihan t) {
    t.lunas = true;
    notifyListeners();
  }

  void buatTiket(String judul, String deskripsi) {
    tiket.insert(0, Tiket(judul, deskripsi));
    notifyListeners();
  }
}

String rp(int v) =>
    'Rp ${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

// ---------- App ----------

class IspApp extends StatelessWidget {
  const IspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelanggan ISP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0B6EFD),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final state = AppState();
  int idx = 0;
  static const titles = ['Beranda', 'Tagihan', 'Tiket Gangguan', 'Profil'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      BerandaPage(state),
      TagihanPage(state),
      TiketPage(state),
      const ProfilPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(titles[idx])),
      body: ListenableBuilder(
        listenable: state,
        builder: (_, __) => pages[idx],
      ),
      floatingActionButton: idx == 2
          ? FloatingActionButton.extended(
              onPressed: () => dialogBuatTiket(context, state),
              icon: const Icon(Icons.add),
              label: const Text('Lapor gangguan'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Tagihan'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), label: 'Tiket'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

// ---------- Beranda ----------

class BerandaPage extends StatelessWidget {
  final AppState s;
  const BerandaPage(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paket aktif'),
                const SizedBox(height: 4),
                Text(s.paketAktif.nama,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('${s.paketAktif.mbps} Mbps  •  ${rp(s.paketAktif.harga)}/bulan'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => pilihPaket(context, s),
                  child: const Text('Ganti paket'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              s.totalBelumLunas > 0 ? Icons.warning_amber : Icons.check_circle,
              color: s.totalBelumLunas > 0 ? Colors.orange : Colors.green,
            ),
            title: Text(s.totalBelumLunas > 0
                ? 'Tagihan belum dibayar'
                : 'Semua tagihan lunas'),
            subtitle: s.totalBelumLunas > 0 ? Text(rp(s.totalBelumLunas)) : null,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.wifi, color: Colors.green),
            title: const Text('Status koneksi'),
            subtitle: const Text('Aktif'),
          ),
        ),
      ],
    );
  }
}

void pilihPaket(BuildContext context, AppState s) {
  showModalBottomSheet(
    context: context,
    builder: (_) => ListView(
      shrinkWrap: true,
      children: [
        for (final p in daftarPaket)
          ListTile(
            title: Text('${p.nama} • ${p.mbps} Mbps'),
            subtitle: Text('${rp(p.harga)}/bulan'),
            trailing: p.nama == s.paketAktif.nama
                ? const Icon(Icons.check)
                : null,
            onTap: () {
              s.gantiPaket(p);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Paket diganti ke ${p.nama}')),
              );
            },
          ),
      ],
    ),
  );
}

// ---------- Tagihan ----------

class TagihanPage extends StatelessWidget {
  final AppState s;
  const TagihanPage(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final t in s.tagihan)
          Card(
            child: ListTile(
              title: Text(t.periode),
              subtitle: Text(rp(t.jumlah)),
              trailing: t.lunas
                  ? const Chip(label: Text('Lunas'))
                  : FilledButton(
                      onPressed: () => dialogBayar(context, s, t),
                      child: const Text('Bayar'),
                    ),
            ),
          ),
      ],
    );
  }
}

void dialogBayar(BuildContext context, AppState s, Tagihan t) {
  showModalBottomSheet(
    context: context,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Bayar ${t.periode} • ${rp(t.jumlah)}',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final m in const ['Virtual Account', 'QRIS', 'E-wallet'])
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(m),
            // TODO: hubungkan ke payment gateway (Midtrans/Xendit/dll)
            onTap: () {
              s.bayar(t);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pembayaran via $m berhasil (simulasi)')),
              );
            },
          ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

// ---------- Tiket ----------

class TiketPage extends StatelessWidget {
  final AppState s;
  const TiketPage(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    if (s.tiket.isEmpty) {
      return const Center(child: Text('Belum ada laporan gangguan'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final t in s.tiket)
          Card(
            child: ListTile(
              title: Text(t.judul),
              subtitle: Text(t.deskripsi),
              trailing: Chip(label: Text(t.status)),
            ),
          ),
      ],
    );
  }
}

void dialogBuatTiket(BuildContext context, AppState s) {
  final judul = TextEditingController();
  final desk = TextEditingController();
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Lapor gangguan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: judul,
            decoration: const InputDecoration(labelText: 'Judul (mis. Internet mati)'),
          ),
          TextField(
            controller: desk,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Deskripsi'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: () {
            if (judul.text.trim().isEmpty) return;
            s.buatTiket(judul.text.trim(), desk.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Kirim'),
        ),
      ],
    ),
  );
}

// ---------- Profil ----------

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(leading: Icon(Icons.badge_outlined), title: Text('ID Pelanggan'), subtitle: Text('PLG-000123')),
        ListTile(leading: Icon(Icons.person_outline), title: Text('Nama'), subtitle: Text('Nama Pelanggan')),
        ListTile(leading: Icon(Icons.home_outlined), title: Text('Alamat pemasangan'), subtitle: Text('Jl. Contoh No. 1')),
        ListTile(leading: Icon(Icons.phone_outlined), title: Text('No. HP'), subtitle: Text('08xxxxxxxxxx')),
      ],
    );
  }
}
