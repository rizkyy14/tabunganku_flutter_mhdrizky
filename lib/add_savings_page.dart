import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'savings_model.dart';
import 'database_helper.dart';
import 'notification_helper.dart'; // 1. PERBAIKAN: Import helper notifikasi agar bisa dipanggil

class AddSavingsPage extends StatefulWidget {
  const AddSavingsPage({super.key}); // Tambahkan constructor key yang standar

  @override
  _AddSavingsPageState createState() => _AddSavingsPageState();
}

class _AddSavingsPageState extends State<AddSavingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'pemasukan'; // Default transaksi
  double _currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBalance();
  }

  void _fetchCurrentBalance() async {
    double balance = await DatabaseHelper().getTotalSavings();
    setState(() {
      _currentBalance = balance;
    });
  }

  // Fungsi helper untuk memformat angka nominal menjadi format ribuan (Contoh: 50.000)
  String _formatNumber(double price) {
    String priceStr = price.toStringAsFixed(0);
    String formatted = '';
    int length = priceStr.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) formatted += '.';
      formatted += priceStr[i];
    }
    return formatted;
  }

  void _saveSavings() async {
    if (_formKey.currentState!.validate()) {
      double amount = double.parse(_amountController.text);

      // Proteksi Validasi: Pengeluaran tidak boleh melebihi sisa saldo saat ini
      if (_transactionType == 'pengeluaran' && amount > _currentBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal! Saldo saat ini (Rp ${_formatNumber(_currentBalance)}) tidak mencukupi.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      String description = _descriptionController.text;
      String date = _selectedDate.toIso8601String();

      // 1. Simpan data transaksi ke Database SQLite
      await DatabaseHelper().insertSavings(
        SavingsEntry(
          amount: amount,
          date: date,
          description: description,
          type: _transactionType,
        ),
      );

      // 2. Tampilkan Notifikasi Utama: Transaksi Sukses Dicatat
      String formattedAmount = _formatNumber(amount);
      await NotificationHelper.showNotification(
        id:
            DateTime.now().millisecondsSinceEpoch ~/
            1000, // ID unik berbasis timestamp detik
        title: _transactionType == 'pemasukan'
            ? 'Transaksi Berhasil Dicatat! 💰'
            : 'Pengeluaran Dicatat! 💸',
        body: _transactionType == 'pemasukan'
            ? 'Berhasil menyimpan sebesar Rp $formattedAmount untuk "$description"'
            : 'Berhasil mencatat pengeluaran Rp $formattedAmount untuk "$description"',
      );

      // 3. LOGIKA NOTIFIKASI PENYEMANGAT WISHLIST (Hanya dipicu jika menambah pemasukan)
      if (_transactionType == 'pemasukan') {
        // Ambil saldo total terbaru setelah penambahan dan semua list wishlist
        double updatedTotalBalance = await DatabaseHelper().getTotalSavings();
        var wishlistList = await DatabaseHelper().getWishlist();

        for (var item in wishlistList) {
          if (item.price > 0) {
            // Hitung persentase progres wishlist tersebut
            double progress = updatedTotalBalance / item.price;

            // Kondisi: Progres sudah berjalan 80% (0.8) atau lebih, DAN belum lunas (kurang dari 100% / 1.0)
            if (progress >= 0.8 && progress < 1.0) {
              // Beri sedikit delay (1.5 detik) agar notifikasi tidak menumpuk berbarengan di layar
              await Future.delayed(const Duration(milliseconds: 1500));

              await NotificationHelper.showNotification(
                id:
                    (item.id ?? 0) +
                    1000, // ID unik khusus pembeda agar tidak menimpa notif utama
                title: 'Dikit lagi impianmu terwujud! 🔥',
                body:
                    'Wishlist "${item.itemName}" kamu udah berjalan ${(progress * 100).toStringAsFixed(0)}%! Ayo menabung terus, dikit lagi tercapai nih! 💪✨',
              );

              break; // Cukup bunyikan satu notifikasi dari wishlist terdekat saja agar tidak terjadi spamming info
            }
          }
        }
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text(
          'Input Transaksi',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- PILIHAN JENIS TRANSAKSI ---
                      const Text(
                        "Jenis Transaksi",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Pemasukan')),
                              selected: _transactionType == 'pemasukan',
                              selectedColor: const Color(0xFF2C5364),
                              labelStyle: TextStyle(
                                color: _transactionType == 'pemasukan'
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(
                                    () => _transactionType = 'pemasukan',
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Pengeluaran')),
                              selected: _transactionType == 'pengeluaran',
                              selectedColor: Colors.redAccent,
                              labelStyle: TextStyle(
                                color: _transactionType == 'pengeluaran'
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setState(
                                    () => _transactionType = 'pengeluaran',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Nominal (Rp)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: "Contoh: 50000",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Isi nominal dulu'
                            : null,
                      ),
                      const SizedBox(height: 25),

                      const Text(
                        "Keterangan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: "Misal: Saku kuliah / Beli bensin",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.notes),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Kasih keterangan dikit'
                            : null,
                      ),
                      const SizedBox(height: 25),

                      const Text(
                        "Pilih Tanggal",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        //  Ramos: const Color(0xFF0F2027),
                        tileColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        leading: const Icon(Icons.calendar_today),
                        title: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                        trailing: const Icon(Icons.edit, size: 18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _saveSavings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C5364),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Simpan Sekarang',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
