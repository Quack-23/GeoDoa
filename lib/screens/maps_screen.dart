import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';
import 'fullscreen_maps.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Preserve state saat navigasi

  final MapController _mapController = MapController();
  LocationModel? _userHome;
  LocationModel? _userOffice;
  List<LocationModel> _customLocations = []; // User-added custom pins only
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserLocations(),
      _loadCustomLocations(),
      _loadCurrentAddress(),
    ]);
  }

  Future<void> _loadUserLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locations = await DatabaseService.instance.getAllLocations();

      if (prefs.containsKey('user_home_id')) {
        final homeId = prefs.getInt('user_home_id');
        _userHome = locations.where((loc) => loc.id == homeId).firstOrNull;
      }

      if (prefs.containsKey('user_office_id')) {
        final officeId = prefs.getInt('user_office_id');
        _userOffice = locations.where((loc) => loc.id == officeId).firstOrNull;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading user locations: $e');
    }
  }

  // ✅ Load ONLY user-added custom locations (not scanned locations)
  Future<void> _loadCustomLocations() async {
    try {
      final allLocations = await DatabaseService.instance.getAllLocations();

      // Filter: Only show user-added custom pins
      // category = 'custom' OR category = 'favorite' OR manually added
      final customOnly = allLocations.where((loc) {
        // Show if marked as custom/favorite
        if (loc.category == 'custom' || loc.category == 'favorite') return true;

        // Show home & office (always show)
        if (loc.id == _userHome?.id || loc.id == _userOffice?.id) return true;

        // Otherwise hide (scanned locations tidak ditampilkan)
        return false;
      }).toList();

      if (mounted) {
        setState(() {
          _customLocations = customOnly;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom locations: $e');
    }
  }

  Future<void> _loadCurrentAddress() async {
    try {
      // Load alamat terakhir yang disimpan
      final prefs = await SharedPreferences.getInstance();
      final address = prefs.getString('current_address');
      if (mounted && address != null) {
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      debugPrint('Error loading current address: $e');
    }
  }

  Widget _getLocationIcon(String subCategory) {
    IconData icon;
    Color color;

    switch (subCategory) {
      case 'Masjid':
        icon = Icons.mosque;
        color = Colors.teal;
        break;
      case 'Musholla':
        icon = Icons.mosque;
        color = Colors.teal.shade300;
        break;
      case 'Pesantren':
        icon = Icons.school;
        color = Colors.green.shade700;
        break;
      case 'Sekolah':
        icon = Icons.school;
        color = Colors.purple;
        break;
      case 'Universitas':
        icon = Icons.apartment;
        color = Colors.deepPurple;
        break;
      case 'Kursus & Pelatihan':
        icon = Icons.menu_book;
        color = Colors.indigo;
        break;
      case 'Rumah Sakit':
        icon = Icons.local_hospital;
        color = Colors.red;
        break;
      case 'Klinik':
        icon = Icons.medical_services;
        color = Colors.red.shade300;
        break;
      case 'Apotek':
        icon = Icons.local_pharmacy;
        color = Colors.pink;
        break;
      case 'Rumah':
        icon = Icons.home;
        color = Colors.green;
        break;
      case 'Kos / Asrama':
        icon = Icons.bed;
        color = Colors.blue.shade300;
        break;
      case 'Kontrakan':
        icon = Icons.house_outlined;
        color = Colors.cyan;
        break;
      case 'Kantor':
        icon = Icons.business;
        color = Colors.orange;
        break;
      case 'Toko & Bisnis':
        icon = Icons.store;
        color = Colors.amber.shade700;
        break;
      case 'Bengkel & Pabrik':
        icon = Icons.build;
        color = Colors.brown;
        break;
      case 'Restoran / Rumah Makan':
        icon = Icons.restaurant;
        color = Colors.deepOrange;
        break;
      case 'Pasar & Mall':
        icon = Icons.shopping_bag;
        color = Colors.amber;
        break;
      case 'Tempat Wisata':
        icon = Icons.landscape;
        color = Colors.lightGreen;
        break;
      case 'Terminal':
        icon = Icons.directions_bus;
        color = Colors.indigo;
        break;
      case 'Stasiun':
        icon = Icons.train;
        color = Colors.indigo.shade300;
        break;
      case 'Bandara & Pelabuhan':
        icon = Icons.flight;
        color = Colors.lightBlue;
        break;
      case 'SPBU':
        icon = Icons.local_gas_station;
        color = Colors.red.shade400;
        break;
      case 'Balai Desa / Pemerintahan':
        icon = Icons.account_balance;
        color = Colors.blueGrey;
        break;
      case 'Makam & Ziarah':
        icon = Icons.park;
        color = Colors.grey.shade600;
        break;
      case 'Lapangan & Gedung Acara':
        icon = Icons.place;
        color = Colors.blue;
        break;
      case 'Jalan & Perjalanan':
        icon = Icons.route;
        color = Colors.grey;
        break;
      case 'Taman & Alam':
        icon = Icons.nature;
        color = Colors.green;
        break;
      default:
        icon = Icons.location_on;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(isDark),
                  const SizedBox(height: 20),

                  // Preview Maps (Kotak)
                  _buildMapPreview(isDark),
                  const SizedBox(height: 20),

                  // Container Lokasi Terkini
                  _buildCurrentLocationCard(isDark),
                  const SizedBox(height: 20),

                  // Container Daftar Lokasi
                  _buildLocationsList(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom App Bar
  Widget _buildCustomAppBar(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peta Lokasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola lokasi favorit Anda',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.add_location_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FullscreenMapsScreen(),
                ),
              ).then((_) => _loadData());
            },
            tooltip: 'Tambah Lokasi',
          ),
        ),
      ],
    );
  }

  // Preview Maps (Kotak - Bisa Diklik ke Fullscreen)
  Widget _buildMapPreview(bool isDark) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        LatLng? currentLocation;
        if (locationService.currentPosition != null) {
          currentLocation = LatLng(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullscreenMapsScreen(
                  initialLocation: currentLocation,
                ),
              ),
            ).then((_) => _loadData());
          },
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          currentLocation ?? const LatLng(-6.2000, 106.8167),
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // Disable interaction
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.doa_maps',
                      ),
                      if (currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentLocation,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withOpacity(0.3),
                                  border:
                                      Border.all(color: Colors.blue, width: 3),
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Overlay untuk tap
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Button untuk fullscreen
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, size: 18, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Buka Peta',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
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
      },
    );
  }

  // Container Lokasi Terkini
  Widget _buildCurrentLocationCard(bool isDark) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        final hasLocation = locationService.currentPosition != null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withOpacity(0.05) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Terkini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLocation
                          ? _currentAddress ?? 'Memuat alamat...'
                          : 'Lokasi tidak tersedia',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Container Daftar Lokasi
  Widget _buildLocationsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pin Lokasi Kamu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FullscreenMapsScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add_location_alt, size: 20),
              label: const Text('Tambah Pin'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Klik tombol "Tambah Pin" untuk menandai lokasi penting kamu di peta',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // Jika belum ada lokasi custom
        if (_customLocations.isEmpty) _buildEmptyState(isDark),

        // Jika ada lokasi custom
        if (_customLocations.isNotEmpty) ...[
          // Lokasi Rumah & Kantor (Special)
          if (_userHome != null || _userOffice != null) ...[
            Text(
              'Lokasi Favorit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (_userHome != null)
              _buildLocationCard(_userHome!, isDark, isHome: true),
            if (_userOffice != null)
              _buildLocationCard(_userOffice!, isDark, isOffice: true),
            const SizedBox(height: 16),
          ],

          // Pin Lokasi Custom Lainnya
          if (_customLocations
              .where(
                  (loc) => loc.id != _userHome?.id && loc.id != _userOffice?.id)
              .isNotEmpty) ...[
            Text(
              'Pin Lokasi Lainnya (${_customLocations.where((loc) => loc.id != _userHome?.id && loc.id != _userOffice?.id).length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _customLocations.length,
              itemBuilder: (context, index) {
                final location = _customLocations[index];
                // Skip home & office karena sudah ditampilkan di atas
                if (location.id == _userHome?.id ||
                    location.id == _userOffice?.id) {
                  return const SizedBox.shrink();
                }
                return _buildLocationCard(location, isDark);
              },
            ),
          ],
        ],

        const SizedBox(height: 16),
        // Tag Info
        _buildTagsInfo(isDark),
      ],
    );
  }

  // ✅ Empty State - Belum Ada Pin Custom
  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Pin Lokasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tandai lokasi penting kamu dengan pin di peta.\nContoh: Rumah, Kantor, Gym, Tempat Favorit',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FullscreenMapsScreen(),
                ),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Tambah Pin Lokasi Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '💡 Tips: Tap & hold di peta untuk menambah pin',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Location Card
  Widget _buildLocationCard(
    LocationModel location,
    bool isDark, {
    bool isHome = false,
    bool isOffice = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHome
              ? Colors.green
              : isOffice
                  ? Colors.orange
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
          width: isHome || isOffice ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullscreenMapsScreen(
                  initialLocation:
                      LatLng(location.latitude, location.longitude),
                  focusLocation: location,
                ),
              ),
            ).then((_) => _loadData());
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _getLocationIcon(location.locationSubCategory),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              location.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (isHome)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'RUMAH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          if (isOffice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'KANTOR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${location.locationSubCategory} • ${location.realSub.replaceAll('_', ' ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (location.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          location.address!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tags Info
  Widget _buildTagsInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tag Lokasi yang Tersedia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blue[300] : Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTagChip('🕌 Masjid', isDark),
              _buildTagChip('🕌 Musholla', isDark),
              _buildTagChip('🏫 Sekolah', isDark),
              _buildTagChip('🎓 Universitas', isDark),
              _buildTagChip('🏥 Rumah Sakit', isDark),
              _buildTagChip('🏠 Rumah', isDark),
              _buildTagChip('🏢 Kantor', isDark),
              _buildTagChip('🛒 Pasar', isDark),
              _buildTagChip('🍽️ Restoran', isDark),
              _buildTagChip('☕ Cafe', isDark),
              _buildTagChip('🚉 Terminal', isDark),
              _buildTagChip('🚂 Stasiun', isDark),
              _buildTagChip('✈️ Bandara', isDark),
              _buildTagChip('📍 Tempat Umum', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.blue[300] : Colors.blue[800],
        ),
      ),
    );
  }
}
