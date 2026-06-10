import 'package:flutter/material.dart';
import 'wishlist_model.dart';
import 'database_helper.dart';
import 'add_wishlist_page.dart';
import 'dart:io';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  WishlistPageState createState() => WishlistPageState();
}

class WishlistPageState extends State<WishlistPage> {
  List<WishlistItem> _wishlist = [];
  double _totalSavings = 0.0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    List<WishlistItem> wishlist = await DatabaseHelper().getWishlist();
    double total = await DatabaseHelper().getTotalSavings();
    if (mounted) {
      setState(() {
        _wishlist = wishlist;
        _totalSavings = total;
      });
    }
  }

  void _deleteWishlist(int id) async {
    await DatabaseHelper().deleteWishlist(id);
    loadData();
  }

  String _formatPrice(double price) {
    String priceStr = price.toStringAsFixed(0);
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 40,
              left: 25,
              right: 25,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C5364), Color(0xFF203A43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Target Impian",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Total Tabungan Tersedia",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "Rp ${_formatPrice(_totalSavings)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Column(
                children: [
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Wishlist Saya",
                          style: TextStyle(
                            color: Color(0xFF203A43),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_wishlist.length} Item",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _wishlist.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _wishlist.length,
                            itemBuilder: (context, index) {
                              return _buildWishlistCard(_wishlist[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddWishlistPage()),
          ).then((_) => loadData());
        },
        backgroundColor: const Color(0xFF2C5364),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Tambah Impian",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildWishlistCard(WishlistItem item) {
    double progress = _totalSavings / item.price;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    DateTime target = DateTime.parse(item.targetDate);
    int daysLeft = target.difference(DateTime.now()).inDays;
    double remaining = item.price - _totalSavings;

    String estimate = remaining <= 0
        ? "Tercapai!"
        : "Rp ${_formatPrice(remaining / (daysLeft <= 0 ? 1 : daysLeft))}/hari";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === FIX DI SINI: Deteksi path file gambar secara dinamis ===
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child:
                item.imagePath != null &&
                    item.imagePath!.isNotEmpty &&
                    File(item.imagePath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(item.imagePath!),
                      fit: BoxFit
                          .cover, // Memotong gambar rapi memenuhi aspek rasio kotak
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    size: 26,
                  ),
          ),
          // ==========================================================
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.itemName,
                        style: const TextStyle(
                          color: Color(0xFF203A43),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteWishlist(item.id!),
                      child: const Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Target: Rp ${_formatPrice(item.price)}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C5364), Color(0xFF48AFDB)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      estimate,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: Color(0xFF2C5364),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            "Mulai list impianmu!",
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
