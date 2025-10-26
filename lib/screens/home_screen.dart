import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/loading_service.dart';
import '../services/scan_statistics_service.dart';
import '../services/simple_background_scan_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Preserve state saat navigasi

  // User & Settings
  String _userName = 'User';

  // Statistics
  int _totalScans = 0;
  int _totalLocations =
      0; // ✅ Jumlah lokasi UNIK yang dikunjungi user (dari scan history)

  // ✅ REMOVED: Background scan status variables (now using StreamBuilder)
  // bool _isBackgroundScanActive = false;
  // String _backgroundScanStatus = 'Tidak aktif';
  // DateTime? _lastBackgroundScan;

  // Recent Data (Riwayat Scan)
  List<ScanHistoryItem> _recentHistory = [];

  // ✅ OPTIMIZED: UI State - show UI immediately, load data in background
  bool _dataReady = false; // ← Track when data is loaded

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ Load data in background (non-blocking)
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh dashboard saat app kembali ke foreground
      _loadDashboardData();
    }
  }

  // ========== NAVIGATION HELPERS ==========
  void _navigateToTab(String routeName) {
    // Navigate using named routes
    Navigator.pushNamed(context, routeName).then((_) => _loadDashboardData());
  }

  // ✅ Load all dashboard data (optimized - removed background scan polling)
  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user data
      final userName = prefs.getString('user_name') ?? 'User';

      // ✅ Load statistics dengan efficient queries (parallel)
      final results = await Future.wait([
        ScanStatisticsService.instance.getTotalScans(),
        ScanStatisticsService.instance
            .getUniqueVisitedLocationsCount(), // ✅ Lokasi UNIK yang dikunjungi
        ScanStatisticsService.instance.getScanHistory(limit: 10),
      ]);

      final totalScans = results[0] as int;
      final totalLocations =
          results[1] as int; // ✅ Dari scan history, bukan database
      final recentHistory = results[2] as List<ScanHistoryItem>;

      // ✅ REMOVED: Background scan status loading (now handled by StreamBuilder)

      if (mounted) {
        setState(() {
          _userName = userName;
          _totalScans = totalScans;
          _totalLocations = totalLocations;
          _recentHistory = recentHistory;
          _dataReady = true; // ✅ Mark data as ready
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _dataReady = true; // Still show UI even on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ OPTIMIZED: Always show UI, never blocking!
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Show skeleton while data loading
                    _dataReady
                        ? _buildHeader(isDark)
                        : _buildHeaderSkeleton(isDark),
                    const SizedBox(height: 20),
                    _dataReady
                        ? _buildFavoriteLocationCard(isDark)
                        : _buildCardSkeleton(isDark, height: 180),
                    const SizedBox(height: 20),
                    _dataReady
                        ? _buildStatsCards(isDark)
                        : _buildStatsCardsSkeleton(isDark),
                    const SizedBox(height: 20),
                    _buildQuickActions(isDark), // Always show (no data needed)
                    const SizedBox(height: 20),
                    _buildBackgroundScanStatus(
                        isDark), // StreamBuilder (always show)
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          // ✅ OPTIMIZED: Use Selector instead of Consumer for granular updates
          Selector<LoadingService, bool>(
            selector: (context, service) =>
                service.isLoadingForKey('scan_locations'),
            builder: (context, isLoading, child) {
              if (!isLoading) return const SizedBox.shrink();
              return const LoadingOverlay(
                loadingKey: 'scan_locations',
                child: SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper: Get time of day greeting
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'pagi';
    if (hour >= 11 && hour < 15) return 'siang';
    if (hour >= 15 && hour < 18) return 'sore';
    return 'malam';
  }

  // Helper: Get emoji based on time
  String _getTimeEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return '🌅';
    if (hour >= 11 && hour < 15) return '☀️';
    if (hour >= 15 && hour < 18) return '🌆';
    return '🌙';
  }

  // ✅ Modern Header dengan Greeting Dynamic
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0D47A1),
                  const Color(0xFF1976D2),
                ]
              : [
                  const Color(0xFF1976D2),
                  const Color(0xFF42A5F5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  _getTimeEmoji(),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assalamualaikum',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selamat ${_getTimeOfDay()}, $_userName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Ayo mulai aktivitasmu hari ini! 💪',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Favorite Location Card (Most Visited)
  Widget _buildFavoriteLocationCard(bool isDark) {
    final favoriteLocation = _getMostFrequentLocation();
    final hasData = favoriteLocation != 'Belum ada data';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasData
              ? isDark
                  ? [
                      const Color(0xFF6A1B9A),
                      const Color(0xFF8E24AA),
                    ]
                  : [
                      const Color(0xFF8E24AA),
                      const Color(0xFFAB47BC),
                    ]
              : [
                  Colors.grey.shade300,
                  Colors.grey.shade400,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hasData
                ? const Color(0xFF8E24AA).withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasData ? Icons.star_rounded : Icons.location_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasData ? 'Lokasi Favorit' : 'Belum Ada Riwayat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData
                          ? 'Tempat yang paling sering kamu kunjungi'
                          : 'Mulai scan untuk melihat lokasi favoritmu',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasData ? Icons.place : Icons.explore_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasData ? favoriteLocation : 'Belum ada lokasi terbaru',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasData) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kunjungan terbanyak 🔥',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Modern Stats Cards Grid
  Widget _buildStatsCards(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: Colors.teal, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Aktivitasmu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                icon: Icons.place,
                label: 'Lokasi Dikunjungi',
                value: _totalLocations
                    .toString(), // ✅ Lokasi UNIK yang pernah dikunjungi user
                color: const Color(0xFFFF6F00),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernStatCard(
                icon: Icons.radar,
                label: 'Total Scan',
                value: _totalScans.toString(),
                color: const Color(0xFF0277BD),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Modern Stat Card Builder
  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Get most frequent location dari scan history
  String _getMostFrequentLocation() {
    if (_recentHistory.isEmpty) return '-';

    // Count frequency
    Map<String, int> locationCount = {};
    for (var item in _recentHistory) {
      if (item.locationName.isNotEmpty) {
        locationCount[item.locationName] =
            (locationCount[item.locationName] ?? 0) + 1;
      }
    }

    if (locationCount.isEmpty) return '-';

    // Find most frequent
    var mostFrequent =
        locationCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    return mostFrequent.key;
  }

  // ✅ Note: _totalLocations now shows unique visited locations from scan history
  // NOT total locations from database (getAllLocation)

  // ✅ Background Scan Status (Live) - USE STREAMBUILDER (Fix Issue #1)
  Widget _buildBackgroundScanStatus(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ StreamBuilder untuk real-time status updates (no lag, no timer)
          StreamBuilder<Map<String, dynamic>>(
            stream: SimpleBackgroundScanService.instance.statusStream,
            initialData:
                SimpleBackgroundScanService.instance.getBackgroundScanStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data ?? {};
              final isActive = status['isActive'] == true;
              final lastScanTime = status['lastScanTime'] != null
                  ? DateTime.tryParse(status['lastScanTime'])
                  : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isActive ? Icons.radar : Icons.radar_outlined,
                          color: isActive ? Colors.green : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Background Scan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        isActive ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Aktif' : 'Tidak Aktif',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        isActive ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isActive ? 'ON' : 'OFF',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (lastScanTime != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Scan terakhir: ${_formatTimeAgo(lastScanTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.blue[300] : Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ Quick Actions Grid (Improved UI)
  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apps_rounded,
                    color: Colors.indigo, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Akses Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Grid 4 kolom - Modern & Compact
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _buildModernQuickActionButton(
              icon: Icons.map_outlined,
              label: 'Maps',
              color: const Color(0xFF1976D2),
              isDark: isDark,
              onTap: () => _navigateToTab('/maps'),
            ),
            _buildModernQuickActionButton(
              icon: Icons.radar_outlined,
              label: 'Scan',
              color: const Color(0xFF7B1FA2),
              isDark: isDark,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        'Geser ke kanan atau tap icon Scan di bawah ⬇️'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF7B1FA2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildModernQuickActionButton(
              icon: Icons.menu_book_outlined,
              label: 'Doa',
              color: const Color(0xFF388E3C),
              isDark: isDark,
              onTap: () => _navigateToTab('/prayer'),
            ),
            _buildModernQuickActionButton(
              icon: Icons.alarm,
              label: 'Alarm',
              color: const Color(0xFF00796B),
              isDark: isDark,
              onTap: () => _navigateToTab('/alarm_personalization'),
            ),
            _buildModernQuickActionButton(
              icon: Icons.person_outline,
              label: 'Profile',
              color: const Color(0xFFE64A19),
              isDark: isDark,
              onTap: () => _navigateToTab('/profile'),
            ),
            _buildModernQuickActionButton(
              icon: Icons.settings_outlined,
              label: 'Setting',
              color: const Color(0xFF455A64),
              isDark: isDark,
              onTap: () => _navigateToTab('/settings'),
            ),
          ],
        ),
      ],
    );
  }

  // Modern Quick Action Button
  Widget _buildModernQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== SKELETON LOADING WIDGETS ==========

  // ✅ Skeleton for Header
  Widget _buildHeaderSkeleton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 250,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Generic skeleton card
  Widget _buildCardSkeleton(bool isDark, {double height = 150}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // ✅ Skeleton for Stats Cards
  Widget _buildStatsCardsSkeleton(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else {
      return '${difference.inDays}h lalu';
    }
  }
}
