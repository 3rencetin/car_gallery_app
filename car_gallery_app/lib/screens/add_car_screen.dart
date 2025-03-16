import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/db_service.dart';

class AddCarScreen extends StatefulWidget {
  final Car? car; // Varsa düzenlenecek araba, yoksa yeni eklenecek

  const AddCarScreen({Key? key, this.car}) : super(key: key);

  @override
  _AddCarScreenState createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;

  // Format para birimini bin ayırıcı nokta (.) ile
  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  void initState() {
    super.initState();
    _isEditing = widget.car != null;

    if (_isEditing) {
      _brandController.text = widget.car!.brand;
      _modelController.text = widget.car!.model;
      _yearController.text = widget.car!.year.toString();
      _colorController.text = widget.car!.color;
      _priceController.text =
          _isEditing
              ? _formatPrice(widget.car!.price)
              : widget.car!.price.toString();
      _imageUrlController.text = widget.car!.imageUrl;
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fiyat alanındaki noktaları kaldırıp parse edilebilir hale getiriyoruz
      String priceText = _priceController.text.trim().replaceAll('.', '');

      final car = Car(
        id: _isEditing ? widget.car!.id : null,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        color: _colorController.text.trim(),
        price: double.parse(priceText),
        imageUrl: _imageUrlController.text.trim(),
      );

      if (_isEditing) {
        await _dbService.updateCar(car);
      } else {
        await _dbService.insertCar(car);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(
        'Araba ${_isEditing ? 'güncellenirken' : 'eklenirken'} hata oluştu: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Fiyat alanı için değer değiştiğinde bin ayırıcı ile formatla
  void _onPriceChanged(String value) {
    if (value.isEmpty) return;

    // Tüm noktaları temizle
    String cleanValue = value.replaceAll('.', '');

    try {
      // Sayıya çevirip tekrar formatla
      double price = double.parse(cleanValue);
      String formattedPrice = _formatPrice(price);

      // Eğer formatlanmış değer ile giriş farklıysa, cursor'u doğru konuma getirerek güncelle
      if (formattedPrice != value) {
        // Cursor pozisyonunu hesapla
        int cursorPosition = _priceController.selection.start;
        // Yeni karakter sayısı ile eski karakter sayısı arasındaki fark
        int lengthDiff = formattedPrice.length - value.length;

        _priceController.text = formattedPrice;

        // Cursor pozisyonunu güncelle
        _priceController.selection = TextSelection.fromPosition(
          TextPosition(offset: cursorPosition + lengthDiff),
        );
      }
    } catch (e) {
      // Parse hatası durumunda değeri değiştirme
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Arabayı Düzenle' : 'Yeni Araba Ekle'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Marka',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen marka giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen model giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Yıl',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen yıl giriniz';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Geçerli bir yıl giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          labelText: 'Renk',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen renk giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Fiyat (TL)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _onPriceChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen fiyat giriniz';
                          }
                          // Noktaları kaldırarak geçerli bir sayı olup olmadığını kontrol et
                          String cleanValue = value.replaceAll('.', '');
                          if (double.tryParse(cleanValue) == null) {
                            return 'Geçerli bir fiyat giriniz';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Resim URL (İsteğe bağlı)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveCar,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isEditing ? 'Güncelle' : 'Kaydet',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
