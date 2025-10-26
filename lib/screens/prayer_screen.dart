import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
// PersistentStateService removed - using SharedPreferences directly
import '../models/prayer_model.dart';
import '../widgets/copy_share_widgets.dart';
import '../widgets/app_loading.dart';
import '../widgets/modern_app_bar.dart';
import '../constants/app_constants.dart';

class PrayerScreen extends StatefulWidget {
  final String? locationType;

  const PrayerScreen({super.key, this.locationType});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();

  // Factory constructor for route arguments
  static Widget fromRoute(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final category = args?['category'] as String?;
    return PrayerScreen(locationType: category);
  }
}

class _PrayerScreenState extends State<PrayerScreen>
    with RestorationMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Preserve state saat navigasi

  List<PrayerModel> _prayers = [];
  String _selectedCategory = 'semua';
  bool _isLoading = true;
  bool _isStateLoaded = false; // Flag to prevent animations during initial load
  final ScrollController _scrollController = ScrollController();

  // Categories menggunakan main categories + semua
  List<String> get _categories {
    return ['semua', ...AppConstants.allCategories];
  }

  @override
  String get restorationId => 'prayer_screen';

  @override
  void initState() {
    super.initState();
    _loadPersistentState();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore state from previous session
    if (initialRestore) {
      _loadPersistentState();
    }
  }

  @override
  void dispose() {
    _savePersistentState();
    _scrollController.dispose();
    super.dispose();
  }

  // Load persistent state
  Future<void> _loadPersistentState() async {
    try {
      // Use locationType from widget if provided, otherwise load from persistent state
      String initialCategory = widget.locationType ?? 'semua';

      // Load state from SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      if (widget.locationType == null) {
        initialCategory = prefs.getString('prayer_selectedCategory') ?? 'semua';
      }

      // Set state once to prevent animations
      if (mounted) {
        setState(() {
          _selectedCategory = initialCategory;
          _isStateLoaded = true; // Mark state as loaded
        });

        // Restore scroll position only if not from notification
        final scrollPosition = prefs.getDouble('prayer_scrollPosition');
        if (widget.locationType == null && scrollPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                scrollPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }

        debugPrint('Prayer state restored: category=$_selectedCategory');

        // Load prayers after state is loaded
        _loadPrayers();
      }
    } catch (e) {
      debugPrint('Error loading prayer state: $e');
      if (mounted) {
        setState(() {
          _selectedCategory = widget.locationType ?? 'semua';
          _isStateLoaded = true; // Mark as loaded even on error
        });
        // Load prayers even if state loading fails
        _loadPrayers();
      }
    }
  }

  // Save persistent state
  Future<void> _savePersistentState() async {
    try {
      // Save state to SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_selectedCategory', _selectedCategory);
      if (_scrollController.hasClients) {
        await prefs.setDouble(
            'prayer_scrollPosition', _scrollController.offset);
      }
      // Note: filters state removed - can be re-implemented if needed
    } catch (e) {
      debugPrint('Error saving prayer state: $e');
    }
  }

  Future<void> _loadPrayers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      List<PrayerModel> prayers;

      if (widget.locationType != null) {
        // Load prayers for specific location type
        prayers = await DatabaseService.instance.getAllPrayers();
        prayers = prayers
            .where((p) => p.locationType == widget.locationType)
            .toList();
      } else {
        // Load all prayers
        prayers = await DatabaseService.instance.getAllPrayers();
      }

      if (!mounted) return;
      setState(() {
        _prayers = prayers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prayers: $e')),
        );
      }
    }
  }

  List<PrayerModel> get _filteredPrayers {
    if (_selectedCategory == 'semua') {
      return _prayers;
    }
    return _prayers.where((p) => p.locationType == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ModernAppBar(
              title: 'Doa & Dzikir',
              subtitle: widget.locationType != null
                  ? 'Filter: ${_getCategoryDisplayName(widget.locationType!)}'
                  : 'Koleksi doa harian Anda',
              icon: Icons.menu_book,
              showBackButton: false,
            ),
            Expanded(
              child: _isStateLoaded
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await _loadPrayers();
                      },
                      child: Column(
                        children: [
                          _buildCategoryFilter(),
                          Expanded(
                            child: _isLoading
                                ? const AppLoading(message: 'Memuat doa...')
                                : _buildPrayersList(),
                          ),
                        ],
                      ),
                    )
                  : const AppLoading(message: 'Menyiapkan layar doa...'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final isFilteredByLocation = widget.locationType != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Filter dengan styling yang lebih jelas
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFilteredByLocation
                            ? 'Menampilkan: ${_getCategoryDisplayName(widget.locationType!)}'
                            : 'Pilih kategori doa',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFilteredByLocation || _selectedCategory != 'semua')
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = 'semua';
                      });
                      _savePersistentState();
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Category chips dengan styling lebih jelas
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _savePersistentState();
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.3)),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          Text(
                            _getCategoryDisplayName(category),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    if (category == 'semua') {
      return 'Semua Kategori';
    }
    // Category names dari AppConstants sudah readable
    return category;
  }

  Widget _buildPrayersList() {
    final filteredPrayers = _filteredPrayers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (filteredPrayers.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tidak Ada Doa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada doa untuk kategori ini',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'semua';
                  });
                  _savePersistentState();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredPrayers.length,
      itemBuilder: (context, index) {
        final prayer = filteredPrayers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildModernPrayerCard(prayer, index),
        );
      },
    );
  }

  Widget _buildModernPrayerCard(PrayerModel prayer, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.menu_book,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            prayer.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getCategoryDisplayName(prayer.locationType),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          iconColor: isDark ? Colors.white : Colors.black87,
          collapsedIconColor: isDark ? Colors.grey[400] : Colors.grey[600],
          children: [
            _buildPrayerContent(prayer),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerContent(PrayerModel prayer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Arabic text - styling lebih jelas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1B5E20).withOpacity(0.2)
                : Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.green.withOpacity(0.3)
                  : Colors.green.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Arab',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.green[300] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                prayer.arabicText,
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'Amiri',
                  height: 2.0,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Latin text - styling lebih jelas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blue.withOpacity(0.1)
                : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.text_fields,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Transliterasi',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                prayer.latinText,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                  color:
                      isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Indonesian text - styling lebih jelas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.orange.withOpacity(0.1)
                : Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Terjemahan Indonesia',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.orange[300] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                prayer.indonesianText,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color:
                      isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Reference section - styling lebih jelas
        if (prayer.reference != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.purple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.purple.withOpacity(0.3)
                    : Colors.purple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.purple,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referensi',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? Colors.purple[300] : Colors.purple[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prayer.reference!,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark ? Colors.purple[200] : Colors.purple[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Action buttons - styling lebih jelas dan simple
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _copyToClipboard(prayer);
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _sharePrayer(prayer);
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Bagikan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  CopyShareWidgets.showCopyShareDialog(
                    context: context,
                    prayer: prayer,
                  );
                  HapticFeedback.lightImpact();
                },
                icon: const Icon(Icons.more_horiz),
                color: Colors.black87,
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(PrayerModel prayer) {
    Clipboard.setData(ClipboardData(text: prayer.arabicText));
    _showModernSnackBar(
      'Doa berhasil disalin ke clipboard',
      Icons.check_circle,
      Colors.green,
    );
  }

  void _sharePrayer(PrayerModel prayer) {
    // In a real app, you would use share_plus package here
    _showModernSnackBar(
      'Fitur berbagi akan segera tersedia',
      Icons.info,
      Colors.blue,
    );
  }

  void _showModernSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
