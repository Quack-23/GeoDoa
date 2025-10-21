import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/location_alarm_service.dart';
import 'services/loading_service.dart';
import 'services/offline_service.dart';
import 'services/state_management_service.dart';
import 'services/dark_mode_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/prayer_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/background_scan_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_loading.dart';

// Theme Manager
class ThemeManager extends ChangeNotifier {
  String _themeMode = 'light';

  String get themeMode => _themeMode;

  ThemeMode get themeModeData {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = prefs.getString('app_theme') ?? 'light';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setTheme(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme', theme);
      _themeMode = theme;

      // Update dark mode service
      if (theme == 'dark') {
        DarkModeService.instance.setDarkMode(true);
      } else if (theme == 'light') {
        DarkModeService.instance.setDarkMode(false);
      } else {
        DarkModeService.instance.setSystemDarkMode(true);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // Get theme data with accessibility and dark mode support
  ThemeData getThemeData(BuildContext context) {
    final isDark = _themeMode == 'dark' ||
        (_themeMode == 'system' &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    // Update dark mode service
    DarkModeService.instance.setDarkMode(isDark);

    // Use centralized AppTheme (Islamic modern)
    return AppTheme.getThemeData(isDark);
  }
}

// Helper function to initialize sample data only if needed
Future<void> _initializeSampleDataIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final sampleDataInserted = prefs.getBool('sample_data_inserted') ?? false;

    if (!sampleDataInserted) {
      await DatabaseService.instance.insertSampleData();
      await prefs.setBool('sample_data_inserted', true);
      ServiceLogger.info('Sample data inserted (first time only)');
    } else {
      ServiceLogger.info('Sample data already exists - skipping');
    }
  } catch (e) {
    ServiceLogger.error('Error checking sample data: $e');
  }
}

// Background services initialization (non-blocking)
void _initializeBackgroundServicesAsync() {
  Future.microtask(() async {
    try {
      // Start monitoring services
      MemoryLeakDetectionService.instance.startMonitoring();

      await Future.wait([
        BatteryOptimizationService.instance.startMonitoring(),
        ServiceReliabilityManager.instance.initialize(),
        AccessibilityService.instance.initialize(),
        ResponsiveDesignService.instance.initialize(),
        AnimationOptimizationService.instance.initialize(),
      ]);

      if (!kIsWeb) {
        await Future.wait([
          BackgroundCleanupService.instance.start(),
          SmartBackgroundService.instance.start(),
          OfflineDataSyncService.instance.initialize(),
          DataBackupService.instance.initialize(),
          DataRecoveryService.instance.initialize(),
        ]);
      }

      await ServiceReliabilityManager.instance.startMonitoring();
      ServiceLogger.info('Background services initialized');
    } catch (e) {
      ServiceLogger.error('Error initializing background services: $e');
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize logging service
    ServiceLogger.info('Starting Doa Maps application');

    // PHASE 1: Critical services only (parallel where possible)
    await Future.wait([
      EncryptionService.instance.initialize(),
      OfflineService.instance.initialize(),
      StateManagementService.instance.initialize(),
      DarkModeService.instance.initialize(),
    ]);
    ServiceLogger.info('Critical services initialized');

    // PHASE 2: Essential services for app functionality
    if (!kIsWeb) {
      // Initialize database ONCE (skip sample data if already exists)
      await DatabaseService.instance.initDatabase();
      await _initializeSampleDataIfNeeded(); // Only insert if database is empty
      ServiceLogger.info('Database initialized');

      // Initialize notification and alarm services in parallel
      await Future.wait([
        NotificationService.instance.initNotifications(),
        LocationAlarmService.instance.initializeAlarmService(),
      ]);
      ServiceLogger.info('Notification and alarm services initialized');
    }

    // PHASE 3: Background services (non-blocking)
    _initializeBackgroundServicesAsync();

    ServiceLogger.info('Essential services initialized - App ready');
  } catch (e) {
    ServiceLogger.critical('Failed to initialize application', error: e);
    // Continue running app even if some services fail
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StateManagementService.instance),
        ChangeNotifierProvider(create: (_) => LocationService.instance),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => LoadingService.instance),
        ChangeNotifierProvider(create: (_) => OfflineService.instance),
      ],
      child: const DoaMapsApp(),
    ),
  );
}

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper>
    with RestorationMixin {
  bool _isOnboardingCompleted = false;
  bool _isLoading = true;

  @override
  String get restorationId => 'onboarding_wrapper';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore state from previous session
    if (initialRestore) {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // Load theme immediately
      final themeManager = context.read<ThemeManager>();
      await themeManager.loadTheme();
    } catch (e) {
      debugPrint('Error initializing app: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: AppLoading(message: 'Menyiapkan aplikasi...'),
      );
    }

    return _isOnboardingCompleted
        ? const MainScreen()
        : const OnboardingScreen();
  }
}

class DoaMapsApp extends StatelessWidget {
  const DoaMapsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup navigator key for notifications
    NotificationService.navigatorKey = GlobalKey<NavigatorState>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationService.instance),
        ChangeNotifierProvider(create: (_) => NotificationService.instance),
      ],
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            navigatorKey: NotificationService.navigatorKey,
            title: 'Doa Geofencing - Tracking Lokasi & Doa Islam',
            theme: themeManager.getThemeData(context),
            themeMode: themeManager.themeModeData,

            // Custom theme untuk Doa Maps dengan tema hijau Islam
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  // App Bar Theme
                  appBarTheme: AppBarTheme(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    titleTextStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    // Status bar with colored background
                    systemOverlayStyle: SystemUiOverlayStyle(
                      statusBarColor: Theme.of(context).colorScheme.primary,
                      statusBarIconBrightness: Brightness.light, // Android
                      statusBarBrightness:
                          Theme.of(context).brightness == Brightness.dark
                              ? Brightness.dark // iOS text light on dark bg
                              : Brightness.light, // iOS text dark on light bg
                    ),
                  ),

                  // Card Theme
                  cardTheme: CardThemeData(
                    color: Theme.of(context).colorScheme.surface,
                    elevation:
                        Theme.of(context).brightness == Brightness.dark ? 8 : 4,
                    shadowColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(
                            Theme.of(context).brightness == Brightness.dark
                                ? 0.5
                                : 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: Theme.of(context).brightness == Brightness.dark
                          ? BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                  ),

                  // Elevated Button Theme
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: Theme.of(context).brightness == Brightness.dark
                          ? 4
                          : 2,
                      shadowColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Floating Action Button Theme
                  floatingActionButtonTheme: FloatingActionButtonThemeData(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation:
                        Theme.of(context).brightness == Brightness.dark ? 8 : 4,
                  ),

                  // Bottom Navigation Bar Theme
                  bottomNavigationBarTheme: BottomNavigationBarThemeData(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedItemColor: Theme.of(context).colorScheme.primary,
                    unselectedItemColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                    type: BottomNavigationBarType.fixed,
                    elevation: Theme.of(context).brightness == Brightness.dark
                        ? 12
                        : 8,
                    selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ),
                child: child!,
              );
            },
            home: const OnboardingWrapper(),
            routes: {
              '/main': (context) => const MainScreen(),
              '/home': (context) => const MainScreen(),
              '/maps': (context) => const MapsScreen(),
              '/prayer': (context) => PrayerScreen.fromRoute(context),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            debugShowCheckedModeBanner: false,
            // Optimize app startup - prevent splash screen on resume
            restorationScopeId: 'doa_geofencing_app',
            onGenerateRoute: (settings) {
              // Handle deep links and navigation state restoration
              return MaterialPageRoute(
                builder: (context) => const OnboardingWrapper(),
                settings: settings,
              );
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RestorationMixin {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    const HomeScreen(),
    const BackgroundScanScreen(),
    const PrayerScreen(),
    const MapsScreen(),
    const ProfileScreen(),
  ];

  @override
  String get restorationId => 'main_screen';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // Restore selected tab index
    if (oldBucket != null) {
      final savedIndex = oldBucket.read('selectedIndex') ?? 0;
      _selectedIndex = savedIndex;
      // Jump to saved page without animation during restoration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(savedIndex);
        }
      });
    }
  }

  void _onTabChanged(int index) {
    // Animate to the selected page when bottom nav is tapped
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(), // Smooth swipe physics
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onTabChanged,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 24,
          // Completely disable all animations
          enableFeedback: false,
          mouseCursor: SystemMouseCursors.click,
          // Disable animations and add custom styling for dark mode
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0D0D0D)
              : null,
          elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 8,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          // Custom colors for better contrast in dark mode
          selectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF00E676) // Neon green for selected
              : Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF666666) // Gray for unselected
              : Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
