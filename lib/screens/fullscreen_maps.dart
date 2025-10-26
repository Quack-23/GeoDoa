import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../models/location_model.dart';
import '../constants/app_constants.dart';
import '../utils/location_count_cache.dart';
import 'dart:async';

class FullscreenMapsScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final LocationModel? focusLocation;

  const FullscreenMapsScreen({
    super.key,
    this.initialLocation,
    this.focusLocation,
  });

  @override
  State<FullscreenMapsScreen> createState() => _FullscreenMapsScreenState();
}

class _FullscreenMapsScreenState extends State<FullscreenMapsScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;
  LocationModel? _userHome;
  LocationModel? _userOffice;

  // User custom locations only (not scanned locations)
  List<LocationModel> _customLocations = [];

  // Search functionality
  bool _isSearchVisible = false;
  List<LocationModel> _searchResults = [];

  // Quick access popup
  bool _isQuickAccessVisible = false;

  // Offline maps sync
  DateTime? _lastMapSync;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _loadUserLocations();
    _loadCustomLocations();
    // ✅ OPTIMIZED: Check sync once saat init (no timer needed)
    _checkMapSyncStatus();

    // If there's a focus location, move to it after map is ready
    if (widget.focusLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(
              widget.focusLocation!.latitude, widget.focusLocation!.longitude),
          16.0,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // ✅ No timer to cancel (removed timer optimization)
    super.dispose();
  }

  // Load user home and office locations
  Future<void> _loadUserLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locations = await DatabaseService.instance.getAllLocations();

      // Load home from SharedPreferences
      if (prefs.containsKey('user_home_id')) {
        final homeId = prefs.getInt('user_home_id');
        _userHome = locations.where((loc) => loc.id == homeId).firstOrNull;
      }

      // Load office from SharedPreferences
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

        // Otherwise hide (scanned locations tidak ditampilkan di maps)
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

  // Check offline map sync status
  Future<void> _checkMapSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimestamp = prefs.getInt('last_map_sync');

      if (lastSyncTimestamp != null) {
        _lastMapSync = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);

        // Check if need to sync (7 days)
        final daysSinceSync = DateTime.now().difference(_lastMapSync!).inDays;
        if (daysSinceSync >= 7) {
          _syncOfflineMaps();
        }
      } else {
        // First time, sync now
        _syncOfflineMaps();
      }
    } catch (e) {
      debugPrint('Error checking map sync status: $e');
    }
  }

  // ✅ REMOVED: Timer optimization - check saat screen dibuka saja
  // No need for periodic background timer

  // Sync offline maps
  Future<void> _syncOfflineMaps() async {
    try {
      debugPrint('Syncing offline maps...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_map_sync', DateTime.now().millisecondsSinceEpoch);

      setState(() {
        _lastMapSync = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peta offline berhasil diperbarui'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error syncing offline maps: $e');
    }
  }

  // Build markers untuk semua lokasi
  List<Marker> _buildMarkers(LocationService locationService) {
    List<Marker> markers = [];

    // Marker untuk current location (user)
    if (locationService.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
          ),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.3),
              border: Border.all(color: Colors.blue, width: 3),
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 20),
          ),
        ),
      );
    }

    // Markers untuk semua lokasi dari database
    for (var location in _customLocations) {
      if (location.latitude != 0 && location.longitude != 0) {
        markers.add(
          Marker(
            point: LatLng(location.latitude, location.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showLocationDetails(location),
              child: _buildMarkerIcon(location),
            ),
          ),
        );
      }
    }

    return markers;
  }

  // Build marker icon berdasarkan tipe lokasi
  Widget _buildMarkerIcon(LocationModel location) {
    IconData icon;
    Color color;

    // Cek apakah ini home atau office
    bool isHome = _userHome?.id == location.id;
    bool isOffice = _userOffice?.id == location.id;

    if (isHome) {
      icon = Icons.home;
      color = Colors.green;
    } else if (isOffice) {
      icon = Icons.business;
      color = Colors.orange;
    } else {
      // Icon berdasarkan SubCategory
      switch (location.locationSubCategory) {
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
          icon = Icons.home_outlined;
          color = Colors.green.shade300;
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
          icon = Icons.business_outlined;
          color = Colors.orange.shade300;
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
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  // Build circles untuk radius lokasi
  List<CircleMarker> _buildCircles() {
    List<CircleMarker> circles = [];

    for (var location in _customLocations) {
      if (location.latitude != 0 && location.longitude != 0) {
        Color circleColor;

        // Warna berbeda untuk home/office
        bool isHome = _userHome?.id == location.id;
        bool isOffice = _userOffice?.id == location.id;

        if (isHome) {
          circleColor = Colors.green;
        } else if (isOffice) {
          circleColor = Colors.orange;
        } else {
          circleColor = Colors.blue;
        }

        circles.add(
          CircleMarker(
            point: LatLng(location.latitude, location.longitude),
            radius: location.radius,
            color: circleColor.withOpacity(0.1),
            borderColor: circleColor.withOpacity(0.3),
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    return circles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Peta Lokasi',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<LocationService>(
        builder: (context, locationService, child) {
          if (locationService.currentPosition != null) {
            _currentLocation = LatLng(
              locationService.currentPosition!.latitude,
              locationService.currentPosition!.longitude,
            );
          }

          return Stack(
            children: [
              // Fullscreen Maps
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _currentLocation ?? const LatLng(-6.2000, 106.8167),
                  initialZoom: 15.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  backgroundColor: Colors.grey.shade200,
                  onTap: (tapPosition, point) {
                    // Map tapped
                  },
                  onLongPress: (tapPosition, point) {
                    _showAddLocationDialog(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.doa_maps',
                    maxNativeZoom: 19,
                    maxZoom: 19,
                    errorTileCallback: (tile, error, stackTrace) {
                      if (!error
                          .toString()
                          .contains('Connection attempt cancelled')) {
                        debugPrint(
                            'Tile load error: ${error.toString().split(':').first}');
                      }
                    },
                    keepBuffer: 2,
                    tileSize: 256,
                  ),
                  // Marker layer untuk semua lokasi
                  MarkerLayer(
                    markers: _buildMarkers(locationService),
                  ),
                  // Circle layer untuk radius
                  CircleLayer(
                    circles: _buildCircles(),
                  ),
                ],
              ),
              // Search bar
              if (_isSearchVisible) _buildSearchBar(),
              // Floating action buttons
              // Modern FAB Stack
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  children: [
                    _buildModernFAB(
                      icon: Icons.my_location,
                      onPressed: () {
                        if (locationService.currentPosition != null) {
                          _mapController.move(
                            LatLng(
                              locationService.currentPosition!.latitude,
                              locationService.currentPosition!.longitude,
                            ),
                            16.0,
                          );
                        }
                      },
                      heroTag: 'myLocation',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildModernFAB(
                      icon: _isSearchVisible ? Icons.close : Icons.search,
                      onPressed: _toggleSearch,
                      heroTag: 'search',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _buildModernFAB(
                      icon: Icons.location_on,
                      onPressed: _toggleQuickAccess,
                      heroTag: 'quickAccess',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _buildModernFAB(
                      icon: Icons.help_outline,
                      onPressed: _showHelp,
                      heroTag: 'help',
                      color: Colors.grey.shade600,
                      size: 48,
                    ),
                  ],
                ),
              ),
              // Quick access popup
              if (_isQuickAccessVisible)
                Positioned(
                  right: 16,
                  bottom: 200,
                  child: _buildQuickAccessPopup(),
                ),
            ],
          );
        },
      ),
    );
  }

  // Build search bar
  // Modern FAB Builder
  Widget _buildModernFAB({
    required IconData icon,
    required VoidCallback onPressed,
    required String heroTag,
    required Color color,
    double size = 56,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // Modern Search Bar
  Widget _buildSearchBar() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari lokasi...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.clear, size: 18),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (_searchResults.isNotEmpty) ...[
              const Divider(height: 1),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final location = _searchResults[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        location.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${location.locationSubCategory} • ${location.realSub.replaceAll('_', ' ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      onTap: () => _moveToLocation(location),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Modern Quick Access Popup
  Widget _buildQuickAccessPopup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Akses Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLocationQuickAccessButton(
                  title: 'Rumah',
                  location: _userHome,
                  icon: Icons.home,
                  color: Colors.green,
                  onTap: () {
                    if (_userHome != null && _userHome!.latitude != 0) {
                      _mapController.move(
                        LatLng(_userHome!.latitude, _userHome!.longitude),
                        17.0,
                      );
                      _toggleQuickAccess();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi rumah belum diset'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLocationQuickAccessButton(
                  title: 'Kantor',
                  location: _userOffice,
                  icon: Icons.business,
                  color: Colors.blue,
                  onTap: () {
                    if (_userOffice != null && _userOffice!.latitude != 0) {
                      _mapController.move(
                        LatLng(_userOffice!.latitude, _userOffice!.longitude),
                        17.0,
                      );
                      _toggleQuickAccess();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi kantor belum diset'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modern Location Quick Access Button
  Widget _buildLocationQuickAccessButton({
    required String title,
    required LocationModel? location,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSet = location != null && location.latitude != 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSet
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSet ? null : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isSet ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSet
                      ? color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSet ? color : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSet ? color : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSet
                      ? color.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSet ? '✓ Tersimpan' : 'Belum Set',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSet ? color : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Toggle search visibility
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchResults.clear();
      }
    });
  }

  // Toggle quick access popup
  void _toggleQuickAccess() {
    setState(() {
      _isQuickAccessVisible = !_isQuickAccessVisible;
    });
  }

  // Search functionality
  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      final localResults =
          await DatabaseService.instance.searchLocations(query);

      List<LocationModel> geocodingResults = [];
      if (query.length > 3) {
        try {
          final locations = await locationFromAddress(query);
          geocodingResults = locations.map((location) {
            return LocationModel(
              name: query,
              locationCategory: 'Tempat Umum & Sosial',
              locationSubCategory: 'Lapangan & Gedung Acara',
              realSub: 'gedung_serbaguna',
              tags: const ['event', 'keramaian', 'doa_perlindungan'],
              latitude: location.latitude,
              longitude: location.longitude,
            );
          }).toList();
        } catch (e) {
          debugPrint('Geocoding error: $e');
        }
      }

      setState(() {
        _searchResults = [...localResults, ...geocodingResults];
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _searchResults.clear();
      });
    }
  }

  // Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
    });
  }

  // Move to location
  void _moveToLocation(LocationModel location) {
    final newLocation = LatLng(location.latitude, location.longitude);
    _mapController.move(newLocation, 16.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pindah ke ${location.name}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show location details dialog
  void _showLocationDetails(LocationModel location) {
    final bool isHome = _userHome?.id == location.id;
    final bool isOffice = _userOffice?.id == location.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _buildMarkerIcon(location),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                location.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Kategori', location.locationCategory),
            _buildInfoRow('Jenis', location.locationSubCategory),
            _buildInfoRow(
                'Detail', location.realSub.replaceAll('_', ' ').toUpperCase()),
            if (location.address != null)
              _buildInfoRow('Alamat', location.address!),
            _buildInfoRow('Radius', '${location.radius.toInt()} meter'),
            if (isHome)
              const Chip(
                label: Text('Rumah Saya'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              ),
            if (isOffice)
              const Chip(
                label: Text('Kantor Saya'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white),
              ),
          ],
        ),
        actions: [
          if (!isHome && !isOffice) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _setAsHome(location);
              },
              icon: const Icon(Icons.home),
              label: const Text('Set Rumah'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _setAsOffice(location);
              },
              icon: const Icon(Icons.business),
              label: const Text('Set Kantor'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Show add location dialog (TANPA RADIUS)
  void _showAddLocationDialog(LatLng point) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();

    // Hierarchical dropdown values
    String? selectedCategory;
    String? selectedSubCategory;
    String? selectedRealSub;

    // Get available categories
    final categories = AppConstants.allCategories;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Get subcategories based on selected category
          final subCategories = selectedCategory != null
              ? AppConstants.getSubCategories(selectedCategory!)
              : <Map<String, dynamic>>[];

          // Get realSubs based on selected category & subcategory
          final realSubs =
              (selectedCategory != null && selectedSubCategory != null)
                  ? AppConstants.getRealSubs(
                      selectedCategory!, selectedSubCategory!)
                  : <String>[];

          // Get tags for current selection
          final tags = (selectedCategory != null && selectedSubCategory != null)
              ? AppConstants.getTags(selectedCategory!, selectedSubCategory!)
              : <String>[];

          return AlertDialog(
            title: const Text('Tambah Lokasi Baru'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lokasi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                      hintText: 'Contoh: Masjid Al-Ikhlas',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat (opsional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // DROPDOWN 1: Category
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Utama',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    hint: const Text('Pilih kategori'),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                        selectedSubCategory = null;
                        selectedRealSub = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // DROPDOWN 2: SubCategory
                  if (selectedCategory != null) ...[
                    DropdownButtonFormField<String>(
                      value: selectedSubCategory,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Tempat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.apartment),
                      ),
                      hint: const Text('Pilih jenis tempat'),
                      items: subCategories.map((subCat) {
                        return DropdownMenuItem(
                          value: subCat['name'] as String,
                          child: Text(subCat['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSubCategory = value;
                          selectedRealSub = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // DROPDOWN 3: RealSub
                  if (selectedCategory != null &&
                      selectedSubCategory != null &&
                      realSubs.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedRealSub,
                      decoration: const InputDecoration(
                        labelText: 'Detail Spesifik (opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.filter_list),
                      ),
                      hint: const Text('Pilih detail'),
                      items: realSubs.map((realSub) {
                        return DropdownMenuItem(
                          value: realSub,
                          child:
                              Text(realSub.replaceAll('_', ' ').toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRealSub = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Info tags
                  if (tags.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.label,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Tags:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: tags.map((tag) {
                              return Chip(
                                label: Text(
                                  tag,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: Colors.green.shade50,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Location info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validasi
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nama lokasi harus diisi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedCategory == null || selectedSubCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pilih kategori dan jenis tempat'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Default realSub jika tidak dipilih
                  String finalRealSub = selectedRealSub ?? realSubs.first;

                  final newLocation = LocationModel(
                    name: nameController.text,
                    locationCategory: selectedCategory!,
                    locationSubCategory: selectedSubCategory!,
                    realSub: finalRealSub,
                    tags: tags,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    radius: 50, // default 50 meter
                    address: addressController.text.isEmpty
                        ? null
                        : addressController.text,
                    category: 'custom', // ✅ Mark as user-added custom location
                  );

                  try {
                    await DatabaseService.instance.insertLocation(newLocation);

                    // ✅ Invalidate cache after insert
                    LocationCountCache.invalidate();
                    debugPrint(
                        '✅ Cache invalidated after adding custom location');

                    await _loadCustomLocations();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lokasi berhasil ditambahkan'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error adding location: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menambahkan lokasi: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Set location as home
  Future<void> _setAsHome(LocationModel location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_home_id', location.id!);

      setState(() {
        _userHome = location;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${location.name} diset sebagai rumah'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting home: $e');
    }
  }

  // Set location as office
  Future<void> _setAsOffice(LocationModel location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_office_id', location.id!);

      setState(() {
        _userOffice = location;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${location.name} diset sebagai kantor'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error setting office: $e');
    }
  }

  // Show help dialog
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Panduan Peta'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                Icons.touch_app,
                'Tekan & Tahan Peta',
                'Long press pada peta untuk menambah lokasi baru',
              ),
              const Divider(),
              _buildHelpItem(
                Icons.location_on,
                'Tap Marker',
                'Tap marker untuk melihat detail dan set rumah/kantor',
              ),
              const Divider(),
              _buildHelpItem(
                Icons.search,
                'Cari Lokasi',
                'Gunakan tombol cari untuk mencari lokasi tersimpan',
              ),
              const Divider(),
              _buildHelpItem(
                Icons.my_location,
                'Lokasi Saya',
                'Tombol lokasi untuk kembali ke posisi Anda',
              ),
              const Divider(),
              _buildHelpItem(
                Icons.sync,
                'Sinkronisasi Offline',
                'Peta offline diperbarui otomatis setiap 7 hari',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
