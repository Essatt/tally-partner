import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import Models
import 'models/tally_event.dart';
import 'models/tally_log.dart';
import 'models/partner_config.dart';
import 'models/person.dart';
import 'models/budget.dart';

// Import Service
import 'services/tally_service.dart';

// Import Providers
import 'features/tallies/presentation/providers/tally_provider.dart';

// Import Pages
import 'features/tallies/presentation/pages/tallies_page.dart';
import 'features/people/presentation/pages/people_page.dart';
import 'features/stats/presentation/pages/stats_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TallyTypeAdapter());
  Hive.registerAdapter(TallyEventAdapter());
  Hive.registerAdapter(TallyLogAdapter());
  Hive.registerAdapter(PartnerConfigAdapter());
  Hive.registerAdapter(PersonAdapter());
  Hive.registerAdapter(BudgetAdapter());

  final tallyService = TallyService();
  await tallyService.init();

  // Run migration from old single-partner to new multi-person system
  await _migrateToMultiPerson(tallyService);

  runApp(
    ProviderScope(
      overrides: [
        tallyServiceProvider.overrideWithValue(tallyService),
      ],
      child: const TallyApp(),
    ),
  );
}

Future<void> _migrateToMultiPerson(TallyService service) async {
  final people = service.getPeople();
  final oldConfig = service.getPartnerConfig();

  // Only migrate if no people exist and old config has data
  if (people.isNotEmpty || oldConfig == null) return;

  // Create a Person from old PartnerConfig
  final person = Person(
    id: '',
    name: oldConfig.partnerName,
    label: 'partner',
    createdAt: DateTime.now(),
  );
  await service.addPerson(person);

  // Get the created person to obtain its generated ID
  final createdPeople = service.getPeople();
  if (createdPeople.isEmpty) return;
  final createdPerson = createdPeople.first;

  // Create a "General" budget with old config's limits
  final budget = Budget(
    id: '',
    personId: createdPerson.id,
    name: 'General',
    budgetLimit: oldConfig.budgetLimit,
    currentBalance: oldConfig.currentBalance,
    createdAt: DateTime.now(),
  );
  await service.addBudget(budget);

  // Get the created budget to obtain its generated ID
  final createdBudgets = service.getBudgetsForPerson(createdPerson.id);
  if (createdBudgets.isEmpty) return;
  final createdBudget = createdBudgets.first;

  // Update existing partner-type events to reference the new person/budget
  final events = service.getEvents();
  for (final event in events) {
    if (event.type != TallyType.standard && event.personId == null) {
      final updated = event.copyWith(
        personId: createdPerson.id,
        assignedBudgetIds: [createdBudget.id],
      );
      await service.updateEvent(updated);
    }
  }

  // Update existing logs for partner events with budget adjustments
  final logs = service.getLogs();
  final partnerEventIds = events
      .where((e) => e.type != TallyType.standard)
      .map((e) => e.id)
      .toSet();
  for (final log in logs) {
    if (partnerEventIds.contains(log.eventId) &&
        log.budgetAdjustments.isEmpty) {
      final updated = log.copyWith(
        budgetAdjustments: {createdBudget.id: log.valueAdjustment},
      );
      await service.addLog(updated);
    }
  }
}

class TallyApp extends StatelessWidget {
  const TallyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF007AFF);

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Tally Partner',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(lightColorScheme, Brightness.light),
      darkTheme: _buildTheme(darkColorScheme, Brightness.dark),
      home: const MainScreen(),
    );
  }

  ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0F0F13) : null,
      appBarTheme: AppBarTheme(
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 3 : 2,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 4,
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorShape: const StadiumBorder(),
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: isDark ? const Color(0xFF1A1A1F) : colorScheme.surface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        backgroundColor: colorScheme.surface,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'People',
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
        return const TalliesPage(key: ValueKey('tallies'));
      case 1:
        return const PeoplePage(key: ValueKey('people'));
      case 2:
        return const StatsPage(key: ValueKey('stats'));
      default:
        return const SizedBox.shrink();
    }
  }
}
