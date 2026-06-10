import 'package:flutter/material.dart';
import 'savings_model.dart';
import 'database_helper.dart';
import 'add_savings_page.dart';

class HomePage extends StatefulWidget {
  // Ditambahkan named constructor key agar mendukung pencantuman GlobalKey dari luar
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

// 1. Tanda underscore (_) dihapus agar menjadi kelas State Publik
class HomePageState extends State<HomePage> {
  List<SavingsEntry> _savings = [];
  double _total = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSavings();
  }

  // 2. Fungsi diubah dari _loadSavings menjadi loadSavings (Publik)
  void loadSavings() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      List<SavingsEntry> savings = await DatabaseHelper().getSavings();
      double total = await DatabaseHelper().getTotalSavings();
      if (mounted) {
        setState(() {
          _savings = savings;
          _total = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load savings: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteSavings(int id) async {
    await DatabaseHelper().deleteSavings(id);
    loadSavings();
  }

  String _formatPrice(double price) {
    String priceStr = price.abs().toStringAsFixed(0);
    String formatted = '';
    int length = priceStr.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) formatted += '.';
      formatted += priceStr[i];
    }
    return price < 0 ? "-Rp $formatted" : "Rp $formatted";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Wealth',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sisa Saldo Bersih',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatPrice(_total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Aktivitas Terakhir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF203A43),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Color(0xFF2C5364),
                              size: 30,
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddSavingsPage(),
                                ),
                              );
                              loadSavings();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _savings.isEmpty
                            ? Center(
                                child: Text(
                                  "Belum ada transaksi.\nYuk, mulai tambah pemasukan!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: _savings.length,
                                itemBuilder: (context, index) {
                                  return _buildSavingsCard(_savings[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsCard(SavingsEntry entry) {
    // 3. Menghapus entry.type karena model aslimu mendeteksi pengeluaran dari nominal negatif (< 0)
    final isExpense = entry.amount < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isExpense ? Colors.red.shade50 : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            isExpense ? Icons.arrow_downward : Icons.wallet,
            color: isExpense ? Colors.red : const Color(0xFF2196F3),
          ),
        ),
        title: Text(
          "${isExpense ? '- ' : '+ '}${_formatPrice(entry.amount)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isExpense ? Colors.red.shade700 : const Color(0xFF2C5364),
          ),
        ),
        subtitle: Text(
          entry.description,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () => _deleteSavings(entry.id!),
        ),
      ),
    );
  }
}
