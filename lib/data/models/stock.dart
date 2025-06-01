// Stock data model
class Stock {
  final String name;
  final int quantity;
  final String category;
  final String expiryDate;

  Stock({
    required this.name,
    required this.quantity,
    required this.category,
    required this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'category': category,
      'expiryDate': expiryDate,
    };
  }

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      name: map['name'],
      quantity: map['quantity'],
      category: map['category'],
      expiryDate: map['expiryDate'],
    );
  }
}
