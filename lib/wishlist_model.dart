class WishlistItem {
  int? id;
  String itemName;
  double price;
  String targetDate;
  String? imagePath; // 1. Tambahkan properti imagePath (bisa bernilai null)

  WishlistItem({
    this.id,
    required this.itemName,
    required this.price,
    required this.targetDate,
    this.imagePath, // 2. Masukkan ke constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'price': price,
      'targetDate': targetDate,
      'imagePath': imagePath, // 3. Daftarkan ke fungsi Map SQL
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'],
      itemName: map['itemName'],
      price: map['price'],
      targetDate: map['targetDate'],
      imagePath: map['imagePath'], // 4. Baca dari field database
    );
  }
}
