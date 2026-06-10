import 'package:flutter/material.dart';
import 'savings_model.dart';
import 'database_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<SavingsEntry> _historyList = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  void loadHistory() async {
    List<SavingsEntry> data = await DatabaseHelper().getSavings();
    if (mounted) {
      setState(() {
        _historyList = data;
      });
    }
  }

  String _formatPrice(double price) {
    // Menggunakan abs() agar format ribuan aman dari gangguan tanda minus beneran
    String priceStr = price.abs().toStringAsFixed(0);
    String formatted = '';
    int length = priceStr.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) formatted += '.';
      formatted += priceStr[i];
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Histori Aktivitas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: _historyList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Belum ada rekam transaksi apapun.",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                final item = _historyList[index];

                // FIX LOGIKA: Kita kembalikan ke sistem pengecekan teks 'pemasukan'
                // karena nominal amount di DB kamu semuanya disimpan bernilai positif.
                final isIncome = item.type == 'pemasukan';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      "${isIncome ? '+ ' : '- '}Rp ${_formatPrice(item.amount)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isIncome
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    subtitle: Text(
                      item.description,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Text(
                      item.date.split('T')[0],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
