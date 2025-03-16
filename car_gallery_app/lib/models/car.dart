class Car {
  final int? id;
  final String brand;
  final String model;
  final int year;
  final String color;
  final double price;
  final String imageUrl;

  Car({
    this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.price,
    required this.imageUrl,
  });

  // Map'ten Car nesnesi oluşturma
  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'],
      brand: map['brand'],
      model: map['model'],
      year: map['year'],
      color: map['color'],
      price: map['price'],
      imageUrl: map['imageUrl'],
    );
  }

  // Car'ı Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  // JSON için String temsilini oluşturma
  @override
  String toString() {
    return 'Car{id: $id, brand: $brand, model: $model, year: $year, color: $color, price: $price}';
  }
}
