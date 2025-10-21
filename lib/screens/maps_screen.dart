import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/persistent_state_service.dart';
import '../models/location_model.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with RestorationMixin {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentLocation;
  LocationModel? _userHome;
  LocationModel? _userOffice;

  // Search functionality
  bool _isSearchVisible = false;
  List<LocationModel> _searchResults = [];

  // Quick access popup
  bool _isQuickAccessVisible = false;

  @override
  String get restorationId => 'maps_screen';

  @override
  void initState() {
    super.initState();
    _loadPersistentState();
    _loadUserLocations();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore state from previous session
    if (initialRestore) {
      _loadPersistentState();
      _loadUserLocations();
    }
  }

  @override
  void dispose() {
    _savePersistentState();
    _searchController.dispose();
    super.dispose();
  }

  // Load persistent state
  Future<void> _loadPersistentState() async {
    try {
      final state = await PersistentStateService.instance.getMapsState();
      if (state != null && mounted) {
        setState(() {
          _currentLocation = LatLng(state['latitude'], state['longitude']);
        });

        // Restore map position
        _mapController.move(_currentLocation!, state['zoom']);

        debugPrint(
            'Maps state restored: ${_currentLocation}, zoom: ${state['zoom']}');
      }
    } catch (e) {
      debugPrint('Error loading maps state: $e');
    }
  }

  // Load user home and office locations
  Future<void> _loadUserLocations() async {
    try {
      final locations = await DatabaseService.instance.getAllLocations();
      _userHome = locations.firstWhere(
        (loc) => loc.type == 'rumah',
        orElse: () => LocationModel(
          name: 'Rumah',
          type: 'rumah',
          latitude: 0,
          longitude: 0,
          radius: 50,
        ),
      );
      _userOffice = locations.firstWhere(
        (loc) => loc.type == 'kantor',
        orElse: () => LocationModel(
          name: 'Kantor',
          type: 'kantor',
          latitude: 0,
          longitude: 0,
          radius: 50,
        ),
      );
    } catch (e) {
      debugPrint('Error loading user locations: $e');
    }
  }

  // Save persistent state
  Future<void> _savePersistentState() async {
    try {
      if (_currentLocation != null) {
        await PersistentStateService.instance.saveMapsState(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          zoom: _mapController.camera.zoom,
          markers: _markers
              .map((marker) => {
                    'latitude': marker.point.latitude,
                    'longitude': marker.point.longitude,
                    'name': marker.key.toString(),
                  })
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error saving maps state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocationService>(
        builder: (context, locationService, child) {
          if (locationService.currentPosition != null) {
            final newLocation = LatLng(
              locationService.currentPosition!.latitude,
              locationService.currentPosition!.longitude,
            );

            // Update current location and save state if changed
            if (_currentLocation != newLocation) {
              _currentLocation = newLocation;
              _savePersistentState();
            }
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _currentLocation ?? const LatLng(-6.2000, 106.8167),
                  initialZoom: 15.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                  onTap: (tapPosition, point) {
                    // Map tapped
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.doa_maps',
                  ),
                ],
              ),
              // Search bar
              if (_isSearchVisible) _buildSearchBar(),
              // Floating action buttons
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
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
                      child: const Icon(Icons.my_location),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      onPressed: _toggleSearch,
                      child:
                          Icon(_isSearchVisible ? Icons.close : Icons.search),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      onPressed: _toggleQuickAccess,
                      child: const Icon(Icons.location_on),
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
  Widget _buildSearchBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari lokasi...',
                      border: InputBorder.none,
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (query) {
                      // Search submitted - functionality can be added later
                    },
                  ),
                ),
                IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final location = _searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(location.name),
                      subtitle: Text(location.type.toUpperCase()),
                      onTap: () => _moveToLocation(location),
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

  // Build quick access popup
  Widget _buildQuickAccessPopup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Akses Cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
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
                        _toggleQuickAccess(); // Close popup after navigation
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
                        _toggleQuickAccess(); // Close popup after navigation
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
      ),
    );
  }

  // Build location quick access button
  Widget _buildLocationQuickAccessButton({
    required String title,
    required LocationModel? location,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSet = location != null && location.latitude != 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSet ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSet ? color : Colors.grey,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSet ? color : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSet ? color : Colors.grey,
              ),
            ),
            Text(
              isSet ? 'Set' : 'Belum Set',
              style: TextStyle(
                fontSize: 10,
                color: isSet ? color : Colors.grey,
              ),
            ),
          ],
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
      // Search in local database first
      final localResults =
          await DatabaseService.instance.searchLocations(query);

      // Search using geocoding
      List<LocationModel> geocodingResults = [];
      if (query.length > 3) {
        try {
          final locations = await locationFromAddress(query);
          geocodingResults = locations.map((location) {
            return LocationModel(
              name: query,
              type: 'tempat_umum',
              latitude: location.latitude,
              longitude: location.longitude,
              radius: 50,
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
}
