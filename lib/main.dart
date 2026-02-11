import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import Models
import 'models/tally_event.dart';
import 'models/tally_log.dart';
import 'models/partner_config.dart';

// Import Service
import 'services/tally_service.dart';

// Import Providers
import 'features/tallies/presentation/providers/tally_provider.dart';

// Import Pages
import 'features/tallies/presentation/pages/tallies_page.dart';
import 'features/partner/presentation/pages/partner_budget_page.dart';
import 'features/stats/presentation/pages/stats_page.dart';

// Import generated adapters
// These are part files and should not be imported directly.

// --- Main Entry Point ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(TallyTypeAdapter());
  Hive.registerAdapter(TallyEventAdapter());
  Hive.registerAdapter(TallyLogAdapter());
  Hive.registerAdapter(PartnerConfigAdapter());

  // TallyService will manage opening/closing boxes.
  // We initialize it here to ensure boxes are ready for first use.
  final tallyService = TallyService();
  await tallyService.init(); // Initialize service to open boxes.

  runApp(
    ProviderScope(
      overrides: [
        tallyServiceProvider.overrideWithValue(tallyService),
      ],
      child: const TallyApp(),
    ),
  );
}

// --- App Shell ---

class TallyApp extends StatelessWidget {
  const TallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TallyApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // Apple Blue
          brightness: Brightness.light,
        ),
        fontFamily: '.SF Pro Text', // Fallbacks to system fonts if not available
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF007AFF),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// --- MainScreen - Navigation Container ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Default to Tallies

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: NavigationBar(
        height: 80,
        backgroundColor: Colors.white,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Tallies',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const TalliesPage();
      case 1:
        return const PartnerBudgetPage();
      case 2:
        return const StatsPage();
      default:
        return const SizedBox.shrink();
    }
  }
}
