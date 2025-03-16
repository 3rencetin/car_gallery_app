import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/preferences_service.dart';
import 'car_detail_screen.dart';

class RecentViewedScreen extends StatefulWidget {
  const RecentViewedScreen({Key? key}) : super(key: key);

  @override
  _RecentViewedScreenState createState() => _RecentViewedScreenState();
}

class _RecentViewedScreenState extends State<RecentViewedScreen> {
  final PreferencesService _prefsService = PreferencesService();
  List<Car> _recentCars = [];
  bool _isLoading = true;

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
    _loadRecentCars();
  }

  Future<void> _loadRecentCars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cars = await _prefsService.getRecentViewedCars();
      setState(() {
        _recentCars = cars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Son görüntülenen arabalar yüklenirken bir hata oluştu: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _clearRecentViewed() async {
    try {
      await _prefsService.saveRecentViewedCars([]);
      setState(() {
        _recentCars = [];
      });
    } catch (e) {
      _showError('Geçmiş temizlenirken bir hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Son Bakılan Arabalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecentCars,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _showClearDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _recentCars.isEmpty
              ? const Center(child: Text('Henüz hiç araba görüntülenmemiş.'))
              : ListView.builder(
                itemCount: _recentCars.length,
                itemBuilder: (context, index) {
                  final car = _recentCars[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading:
                          car.imageUrl.isNotEmpty
                              ? CircleAvatar(
                                backgroundImage: NetworkImage(car.imageUrl),
                                onBackgroundImageError: (_, __) {},
                              )
                              : CircleAvatar(child: Text(car.brand[0])),
                      title: Text('${car.brand} ${car.model}'),
                      subtitle: Text(
                        '${car.year} - ${car.color} - ${_formatPrice(car.price)} TL',
                      ),
                      trailing: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarDetailScreen(car: car),
                          ),
                        ).then((_) => _loadRecentCars());
                      },
                    ),
                  );
                },
              ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Geçmişi Temizle'),
          content: const Text(
            'Son görüntülenen arabaların geçmişini temizlemek istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Temizle'),
              onPressed: () {
                Navigator.of(context).pop();
                _clearRecentViewed();
              },
            ),
          ],
        );
      },
    );
  }
}
