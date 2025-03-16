import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/db_service.dart';
import '../services/preferences_service.dart';
import 'car_detail_screen.dart';
import 'add_car_screen.dart';

class CarListScreen extends StatefulWidget {
  const CarListScreen({Key? key}) : super(key: key);

  @override
  _CarListScreenState createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final PreferencesService _prefsService = PreferencesService();
  List<Car> _cars = [];
  List<Car> _filteredCars = [];
  List<Car> _favoriteCars = [];
  bool _isLoading = true;
  Map<String, dynamic> _filters = {};
  bool _isListView = false;
  bool _isFiltering = false;
  late AnimationController _animationController;

  // Filtre değişkenleri
  List<String> _availableBrands = ['Tümü'];
  String _selectedBrand = 'Tümü';

  RangeValues _priceRange = const RangeValues(0, 2000000);
  RangeValues _yearRange = const RangeValues(2015, 2023);

  List<String> _availableColors = ['Tümü'];
  String _selectedColor = 'Tümü';

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cars = await _dbService.getCars();
      final favCars = await _prefsService.getFavoriteCars();
      final lastFilters = await _prefsService.getLastFilters();

      // Marka ve renk seçeneklerini araç listesinden çıkar
      _updateAvailableBrands(cars);
      _updateAvailableColors(cars);

      // Fiyat aralığını araba verilerine göre ayarla
      if (cars.isNotEmpty) {
        double minPrice = cars
            .map((c) => c.price)
            .reduce((min, price) => price < min ? price : min);
        double maxPrice = cars
            .map((c) => c.price)
            .reduce((max, price) => price > max ? price : max);
        _priceRange = RangeValues(minPrice, maxPrice);

        int minYear = cars
            .map((c) => c.year)
            .reduce((min, year) => year < min ? year : min);
        int maxYear = cars
            .map((c) => c.year)
            .reduce((max, year) => year > max ? year : max);
        _yearRange = RangeValues(minYear.toDouble(), maxYear.toDouble());
      }

      // Son filtreleri yükle
      if (lastFilters.isNotEmpty) {
        _loadFilters(lastFilters);
      }

      setState(() {
        _cars = cars;
        _filteredCars = List.from(cars);
        _favoriteCars = favCars;
        _filters = lastFilters;
        _isLoading = false;
      });

      if (lastFilters.isNotEmpty) {
        _applyFilters();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Veriler yüklenirken bir hata oluştu: $e');
    }
  }

  void _loadFilters(Map<String, dynamic> filters) {
    if (filters.containsKey('brand')) {
      _selectedBrand = filters['brand'];
    }

    if (filters.containsKey('color')) {
      _selectedColor = filters['color'];
    }

    if (filters.containsKey('priceMin') && filters.containsKey('priceMax')) {
      _priceRange = RangeValues(
        filters['priceMin'].toDouble(),
        filters['priceMax'].toDouble(),
      );
    }

    if (filters.containsKey('yearMin') && filters.containsKey('yearMax')) {
      _yearRange = RangeValues(
        filters['yearMin'].toDouble(),
        filters['yearMax'].toDouble(),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _toggleFavorite(Car car) async {
    setState(() {
      if (_favoriteCars.any((c) => c.id == car.id)) {
        _favoriteCars.removeWhere((c) => c.id == car.id);
      } else {
        _favoriteCars.add(car);
      }
    });

    await _prefsService.saveFavoriteCars(_favoriteCars);
  }

  Future<void> _viewCarDetails(Car car) async {
    // Son görüntülenen arabaları güncelle
    List<Car> recentCars = await _prefsService.getRecentViewedCars();

    // Eğer zaten listede varsa, önce onu kaldır
    recentCars.removeWhere((c) => c.id == car.id);

    // Başa ekle (en son görüntülenen araç en üstte olacak)
    recentCars.insert(0, car);

    // Sadece son 10 aracı tut
    if (recentCars.length > 10) {
      recentCars = recentCars.sublist(0, 10);
    }

    await _prefsService.saveRecentViewedCars(recentCars);

    // Detay ekranına git
    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  CarDetailScreen(car: car),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ).then((_) => _loadData());
    }
  }

  void _toggleViewMode() {
    setState(() {
      _isListView = !_isListView;
      if (_isListView) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _isFiltering = true;
      _filteredCars =
          _cars.where((car) {
            bool passFilter = true;

            // Marka filtresi
            if (_selectedBrand != 'Tümü') {
              passFilter = passFilter && car.brand == _selectedBrand;
            }

            // Renk filtresi
            if (_selectedColor != 'Tümü') {
              passFilter = passFilter && car.color == _selectedColor;
            }

            // Fiyat aralığı filtresi
            passFilter =
                passFilter &&
                car.price >= _priceRange.start &&
                car.price <= _priceRange.end;

            // Yıl aralığı filtresi
            passFilter =
                passFilter &&
                car.year >= _yearRange.start.toInt() &&
                car.year <= _yearRange.end.toInt();

            return passFilter;
          }).toList();
    });

    // Filtreleri kaydet
    _saveFilters();
  }

  void _resetFilters() {
    setState(() {
      _selectedBrand = 'Tümü';
      _selectedColor = 'Tümü';

      if (_cars.isNotEmpty) {
        double minPrice = _cars
            .map((c) => c.price)
            .reduce((min, price) => price < min ? price : min);
        double maxPrice = _cars
            .map((c) => c.price)
            .reduce((max, price) => price > max ? price : max);
        _priceRange = RangeValues(minPrice, maxPrice);

        int minYear = _cars
            .map((c) => c.year)
            .reduce((min, year) => year < min ? year : min);
        int maxYear = _cars
            .map((c) => c.year)
            .reduce((max, year) => year > max ? year : max);
        _yearRange = RangeValues(minYear.toDouble(), maxYear.toDouble());
      }

      _filteredCars = List.from(_cars);
      _isFiltering = false;
      _filters = {};
    });

    _prefsService.saveLastFilters({});
  }

  Future<void> _saveFilters() async {
    final filters = {
      'brand': _selectedBrand,
      'color': _selectedColor,
      'priceMin': _priceRange.start,
      'priceMax': _priceRange.end,
      'yearMin': _yearRange.start.toInt(),
      'yearMax': _yearRange.end.toInt(),
    };

    setState(() {
      _filters = filters;
    });

    await _prefsService.saveLastFilters(filters);
  }

  // Mevcut araçlardan marka listesini güncelle
  void _updateAvailableBrands(List<Car> cars) {
    Set<String> brands = {'Tümü'};
    for (var car in cars) {
      if (car.brand.isNotEmpty) {
        brands.add(car.brand);
      }
    }
    setState(() {
      _availableBrands = brands.toList()..sort();
      // "Tümü" seçeneğini her zaman listenin başına ekle
      if (_availableBrands.remove('Tümü')) {
        _availableBrands.insert(0, 'Tümü');
      }
    });
  }

  // Mevcut araçlardan renk listesini güncelle
  void _updateAvailableColors(List<Car> cars) {
    Set<String> colors = {'Tümü'};
    for (var car in cars) {
      if (car.color.isNotEmpty) {
        colors.add(car.color);
      }
    }
    setState(() {
      _availableColors = colors.toList()..sort();
      // "Tümü" seçeneğini her zaman listenin başına ekle
      if (_availableColors.remove('Tümü')) {
        _availableColors.insert(0, 'Tümü');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PREMIUM ARAÇ GALERİSİ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.list_view,
              progress: _animationController,
            ),
            onPressed: _toggleViewMode,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              if (_isFiltering)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cars.isEmpty
              ? _buildEmptyState()
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isFiltering)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filtrelenen Araçlar: ${_filteredCars.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _resetFilters();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Filtreleri Temizle'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child:
                        _filteredCars.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_alt_off,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Filtreye uygun araç bulunamadı',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _resetFilters,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Filtreleri Temizle'),
                                  ),
                                ],
                              ),
                            )
                            : _isListView
                            ? _buildListView()
                            : _buildGridView(),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCarScreen()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('YENİ ARAÇ'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz hiç araba eklenmemiş',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCarScreen()),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.add),
            label: const Text('YENİ ARAÇ EKLE'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredCars.length,
      itemBuilder: (context, index) {
        final car = _filteredCars[index];
        final isFavorite = _favoriteCars.any((c) => c.id == car.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 4,
            child: InkWell(
              onTap: () => _viewCarDetails(car),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child:
                            car.imageUrl.isNotEmpty
                                ? Image.network(
                                  car.imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.directions_car,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _toggleFavorite(car),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          child: Text(
                            '${car.brand} ${car.model}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${car.year}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.color_lens,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              car.color,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatPrice(car.price)} TL',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredCars.length,
      itemBuilder: (context, index) {
        final car = _filteredCars[index];
        final isFavorite = _favoriteCars.any((c) => c.id == car.id);

        return Card(
          elevation: 4,
          child: InkWell(
            onTap: () => _viewCarDetails(car),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          car.imageUrl.isNotEmpty
                              ? Image.network(
                                car.imageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              )
                              : Container(
                                height: 120,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.directions_car,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 20,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(car),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.brand} ${car.model}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${car.year} - ${car.color}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatPrice(car.price)} TL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Araç Filtrele',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: [
                          const Text(
                            'Marka',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children:
                                _availableBrands.map((brand) {
                                  return FilterChip(
                                    label: Text(brand),
                                    selected: _selectedBrand == brand,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedBrand = brand;
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Renk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children:
                                _availableColors.map((color) {
                                  return FilterChip(
                                    label: Text(color),
                                    selected: _selectedColor == color,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedColor = color;
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Fiyat Aralığı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_formatPrice(_priceRange.start)} TL',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_formatPrice(_priceRange.end)} TL',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min:
                                _cars.isEmpty
                                    ? 0
                                    : _cars
                                        .map((c) => c.price)
                                        .reduce(
                                          (min, price) =>
                                              price < min ? price : min,
                                        ),
                            max:
                                _cars.isEmpty
                                    ? 2000000
                                    : _cars
                                        .map((c) => c.price)
                                        .reduce(
                                          (max, price) =>
                                              price > max ? price : max,
                                        ),
                            divisions: 20,
                            labels: RangeLabels(
                              '${_formatPrice(_priceRange.start)} TL',
                              '${_formatPrice(_priceRange.end)} TL',
                            ),
                            onChanged: (RangeValues values) {
                              setState(() {
                                _priceRange = values;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Model Yılı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_yearRange.start.toInt()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_yearRange.end.toInt()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: _yearRange,
                            min:
                                _cars.isEmpty
                                    ? 2015
                                    : _cars
                                        .map((c) => c.year)
                                        .reduce(
                                          (min, year) =>
                                              year < min ? year : min,
                                        )
                                        .toDouble(),
                            max:
                                _cars.isEmpty
                                    ? 2023
                                    : _cars
                                        .map((c) => c.year)
                                        .reduce(
                                          (max, year) =>
                                              year > max ? year : max,
                                        )
                                        .toDouble(),
                            divisions:
                                (_cars.isEmpty
                                        ? 8
                                        : (_cars
                                                .map((c) => c.year)
                                                .reduce(
                                                  (max, year) =>
                                                      year > max ? year : max,
                                                ) -
                                            _cars
                                                .map((c) => c.year)
                                                .reduce(
                                                  (min, year) =>
                                                      year < min ? year : min,
                                                )))
                                    .toInt(),
                            labels: RangeLabels(
                              '${_yearRange.start.toInt()}',
                              '${_yearRange.end.toInt()}',
                            ),
                            onChanged: (RangeValues values) {
                              setState(() {
                                _yearRange = values;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedBrand = 'Tümü';
                                _selectedColor = 'Tümü';

                                if (_cars.isNotEmpty) {
                                  double minPrice = _cars
                                      .map((c) => c.price)
                                      .reduce(
                                        (min, price) =>
                                            price < min ? price : min,
                                      );
                                  double maxPrice = _cars
                                      .map((c) => c.price)
                                      .reduce(
                                        (max, price) =>
                                            price > max ? price : max,
                                      );
                                  _priceRange = RangeValues(minPrice, maxPrice);

                                  int minYear = _cars
                                      .map((c) => c.year)
                                      .reduce(
                                        (min, year) => year < min ? year : min,
                                      );
                                  int maxYear = _cars
                                      .map((c) => c.year)
                                      .reduce(
                                        (max, year) => year > max ? year : max,
                                      );
                                  _yearRange = RangeValues(
                                    minYear.toDouble(),
                                    maxYear.toDouble(),
                                  );
                                }
                              });
                            },
                            child: const Text('Sıfırla'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            child: const Text('Filtreleri Uygula'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
