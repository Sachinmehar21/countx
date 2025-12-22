import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/local_storage_service.dart';
import 'models/counter_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CountXApp());
}

class CountXApp extends StatelessWidget {
  const CountXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CountX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mint green color
  static const Color mintGreen = Color(0xFF00E676);

  // Local storage service
  final LocalStorageService _storageService = LocalStorageService();

  // Counter state
  int _count = 0;
  String _counterName = 'Count';
  String? _currentCounterId;

  // Time filter state
  bool _isYearView = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // List of counters for swipe
  List<Counter> _counters = [];
  int _currentCounterIndex = 0;

  // Stats state
  bool _statsExpanded = false;
  final ScrollController _scrollController = ScrollController();

  // Dark mode state
  bool _isDarkMode = false;

  // Loading state
  bool _isLoading = true;

  // Archived counters state
  bool _archivedExpanded = false;
  List<Counter> _archivedCounters = [];

  // Stats data
  Map<int, int> _monthlyData = {};
  Map<DateTime, int> _yearlyHeatmapData = {};
  int _statsYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    // Set dark mode based on system theme
    _isDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    _loadCounters();
  }

  void _loadCounters() {
    _storageService.getCounters().listen(
      (counters) {
        setState(() {
          _counters = counters;
          _isLoading = false;
          
          if (_counters.isEmpty) {
            // Create default counter if none exists
            _createDefaultCounter();
          } else {
            // Set current counter
            if (_currentCounterIndex >= _counters.length) {
              _currentCounterIndex = 0;
            }
            _currentCounterId = _counters[_currentCounterIndex].id;
            _counterName = _counters[_currentCounterIndex].name;
            _loadCount();
          }
        });
        // Load archived counters
        _loadArchivedCounters();
      },
      onError: (e) {
        print('Error loading counters: $e');
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  void _loadArchivedCounters() {
    _storageService.getArchivedCounters().listen(
      (counters) {
        setState(() {
          _archivedCounters = counters;
        });
      },
    );
  }

  Future<void> _createDefaultCounter() async {
    final id = await _storageService.addCounter('Count');
    setState(() {
      _currentCounterId = id;
      _counterName = 'Count';
    });
    _loadCounters();
  }

  Future<void> _loadCount() async {
    if (_currentCounterId == null) return;
    
    int count;
    if (_isYearView) {
      count = await _storageService.getYearCount(_currentCounterId!, _selectedYear);
    } else {
      count = await _storageService.getMonthCount(_currentCounterId!, _selectedYear, _selectedMonth);
    }
    setState(() {
      _count = count;
    });
    
    // Load stats data
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    if (_currentCounterId == null) return;
    
    final monthlyData = await _storageService.getMonthlyCountsForYear(_currentCounterId!, _statsYear);
    final yearlyData = await _storageService.getDailyCountsForYear(_currentCounterId!, _statsYear);
    
    setState(() {
      _monthlyData = monthlyData;
      _yearlyHeatmapData = yearlyData;
    });
  }

  void _increment() async {
    if (_currentCounterId == null) return;
    HapticFeedback.lightImpact();
    
    await _storageService.addEntry(_currentCounterId!);
    setState(() {
      _count++;
    });
    _loadStatsData();
  }

  void _decrement() async {
    if (_currentCounterId == null || _count <= 0) return;
    HapticFeedback.lightImpact();
    
    await _storageService.removeLastEntry(_currentCounterId!);
    setState(() {
      _count--;
    });
    _loadStatsData();
  }

  void _toggleTimeFilter() {
    HapticFeedback.selectionClick();
    setState(() {
      _isYearView = !_isYearView;
    });
    _loadCount();
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    _loadCount();
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
    _loadCount();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: _isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _isDarkMode ? Colors.white24 : Colors.black12),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.add,
              title: 'Add New Counter',
              onTap: () {
                Navigator.pop(context);
                _showAddCounterDialog();
              },
            ),
            _buildMenuItem(
              icon: Icons.edit_outlined,
              title: 'Edit/Rename Counter',
              onTap: () {
                Navigator.pop(context);
                _showEditCounterDialog();
              },
            ),
            _buildMenuItem(
              icon: Icons.archive_outlined,
              title: 'Archive Counter',
              onTap: () async {
                Navigator.pop(context);
                if (_currentCounterId != null && _counters.length > 1) {
                  await _storageService.archiveCounter(_currentCounterId!);
                  _loadCounters();
                }
              },
            ),
            _buildMenuItem(
              icon: Icons.download_outlined,
              title: 'Export Data (CSV)',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 1, color: _isDarkMode ? Colors.white24 : Colors.black12),
            const SizedBox(height: 8),
            // Archived Counters Section
            _buildArchivedSection(),
            Divider(height: 1, color: _isDarkMode ? Colors.white24 : Colors.black12),
            const SizedBox(height: 8),
            _buildDarkModeToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _isDarkMode ? Colors.white70 : Colors.black87),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildArchivedSection() {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.archive_outlined,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
          title: Text(
            'Archived Counters',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          trailing: Icon(
            _archivedExpanded ? Icons.expand_less : Icons.expand_more,
            color: _isDarkMode ? Colors.white70 : Colors.black87,
          ),
          onTap: () {
            setState(() {
              _archivedExpanded = !_archivedExpanded;
            });
          },
        ),
        if (_archivedExpanded)
          _archivedCounters.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'No archived counters',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                  ),
                )
              : Column(
                  children: _archivedCounters.map((counter) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 56, right: 8),
                      title: Text(
                        counter.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.unarchive_outlined,
                          color: mintGreen,
                        ),
                        onPressed: () async {
                          await _storageService.unarchiveCounter(counter.id);
                          _loadCounters();
                        },
                      ),
                    );
                  }).toList(),
                ),
      ],
    );
  }

  Widget _buildDarkModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.brightness_6_outlined, color: _isDarkMode ? Colors.white70 : Colors.black87),
          const SizedBox(width: 16),
          Text(
            'Dark Mode',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              Navigator.pop(context);
            },
            activeColor: mintGreen,
          ),
        ],
      ),
    );
  }

  void _showAddCounterDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Add New Counter', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Counter name',
            hintStyle: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _isDarkMode ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _storageService.addCounter(controller.text);
                Navigator.pop(context);
                _loadCounters();
              }
            },
            child: const Text('Add', style: TextStyle(color: mintGreen)),
          ),
        ],
      ),
    );
  }

  void _showEditCounterDialog() {
    final controller = TextEditingController(text: _counterName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Edit Counter Name', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Counter name',
            hintStyle: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _isDarkMode ? Colors.white24 : Colors.black26),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && _currentCounterId != null) {
                await _storageService.updateCounterName(_currentCounterId!, controller.text);
                setState(() {
                  _counterName = controller.text;
                });
                Navigator.pop(context);
                _loadCounters();
              }
            },
            child: const Text('Save', style: TextStyle(color: mintGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final textColorSecondary = _isDarkMode ? Colors.white70 : Colors.black54;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: mintGreen),
        ),
      );
    }
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: _buildDrawer(),
      bottomNavigationBar: _statsExpanded ? null : Container(
        color: bgColor,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _statsExpanded = true;
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Stats',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_up,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _openMenu();
          },
          child: _counters.isEmpty
              ? Center(
                  child: Text(
                    'Loading...',
                    style: GoogleFonts.poppins(color: textColor),
                  ),
                )
              : PageView.builder(
                  itemCount: _counters.length,
                  onPageChanged: (index) async {
                    setState(() {
                      _currentCounterIndex = index;
                      _currentCounterId = _counters[index].id;
                      _counterName = _counters[index].name;
                    });
                    await _loadCount();
                  },
                  itemBuilder: (context, index) {
                    return _buildCounterPage(textColor, textColorSecondary);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCounterPage(Color textColor, Color textColorSecondary) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Header with menu button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _openMenu,
                  icon: Icon(Icons.menu, size: 28, color: textColor),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // App Title
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
              children: [
                TextSpan(
                  text: 'Count',
                  style: TextStyle(color: textColor),
                ),
                const TextSpan(
                  text: 'X',
                  style: TextStyle(color: mintGreen),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Main Counter Circle
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: mintGreen,
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Counter Name
                  Text(
                    _counterName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Counter Value with +/- buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button
                      GestureDetector(
                        onTap: _decrement,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '−',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: textColorSecondary,
                            ),
                          ),
                        ),
                      ),

                      // Count Value
                      SizedBox(
                        width: 140,
                        child: Text(
                          '$_count',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 80,
                            fontWeight: FontWeight.w300,
                            color: textColor,
                          ),
                        ),
                      ),

                      // Plus button
                      GestureDetector(
                        onTap: _increment,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '+',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              color: textColorSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Time Filter
                  GestureDetector(
                    onTap: _toggleTimeFilter,
                    child: _isYearView
                        ? Text(
                            'This Year',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textColorSecondary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _previousMonth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.chevron_left,
                                    size: 20,
                                    color: textColorSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                _getMonthName(_selectedMonth),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: textColorSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: _nextMonth,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: textColorSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

        // Stats Section (inline, scrollable)
        if (_statsExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collapse button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _statsExpanded = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Stats',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: textColor,
                        ),
                      ],
                    ),
                  ),
                ),
                // Year selector for stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: textColor),
                          onPressed: () {
                            setState(() {
                              _statsYear--;
                            });
                            _loadStatsData();
                          },
                        ),
                        Text(
                          '$_statsYear',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: textColor),
                          onPressed: _statsYear < DateTime.now().year ? () {
                            setState(() {
                              _statsYear++;
                            });
                            _loadStatsData();
                          } : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Monthly Bar Graph
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildMonthlyGraph(textColor, textColorSecondary),
                ),
                
                const SizedBox(height: 24),
                Text(
                  'Yearly Heatmap',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                
                // GitHub-style Heatmap
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildYearlyHeatmap(textColor, textColorSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyGraph(Color textColor, Color textColorSecondary) {
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final maxValue = _monthlyData.values.isEmpty ? 1 : _monthlyData.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (index) {
              final month = index + 1;
              final value = _monthlyData[month] ?? 0;
              final heightPercent = maxValue > 0 ? value / maxValue : 0.0;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (value > 0)
                        Text(
                          '$value',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: textColorSecondary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: heightPercent == 0 ? 0.02 : heightPercent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: value > 0 ? mintGreen : (_isDarkMode ? Colors.white24 : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: months.map((m) => Expanded(
            child: Text(
              m,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: textColorSecondary,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildYearlyHeatmap(Color textColor, Color textColorSecondary) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['M', '', 'W', '', 'F', '', 'S'];
    
    // Find first day of year and calculate weeks
    final firstDayOfYear = DateTime(_statsYear, 1, 1);
    final lastDayOfYear = DateTime(_statsYear, 12, 31);
    
    // Calculate max value for color intensity
    final maxValue = _yearlyHeatmapData.values.isEmpty ? 1 : _yearlyHeatmapData.values.reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels + Heatmap grid
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels (Mon, Wed, Fri, Sun)
            Column(
              children: days.map((d) => Container(
                height: 14,
                width: 20,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  d,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: textColorSecondary,
                  ),
                ),
              )).toList(),
            ),
            
            // Scrollable heatmap
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildHeatmapWeeks(firstDayOfYear, lastDayOfYear, maxValue),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less', style: GoogleFonts.poppins(fontSize: 10, color: textColorSecondary)),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              final intensity = i / 4;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _getHeatmapColor(intensity),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text('More', style: GoogleFonts.poppins(fontSize: 10, color: textColorSecondary)),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildHeatmapWeeks(DateTime firstDay, DateTime lastDay, int maxValue) {
    List<Widget> weeks = [];
    
    // Start from the first day of the year
    DateTime current = firstDay;
    
    // Adjust to start from Monday of the week containing Jan 1
    int daysToSubtract = (current.weekday - 1) % 7;
    current = current.subtract(Duration(days: daysToSubtract));
    
    int currentMonth = -1;
    
    while (current.isBefore(lastDay) || current.isAtSameMomentAs(lastDay)) {
      // Check if we need to add month label
      DateTime weekStart = current;
      
      List<Widget> weekDays = [];
      for (int i = 0; i < 7; i++) {
        DateTime day = current.add(Duration(days: i));
        
        // Only show days within the year
        if (day.year == _statsYear) {
          final dayKey = DateTime(day.year, day.month, day.day);
          final value = _yearlyHeatmapData[dayKey] ?? 0;
          final intensity = maxValue > 0 ? value / maxValue : 0.0;
          final monthName = _getShortMonthName(day.month);
          
          weekDays.add(
            Tooltip(
              message: '${day.day} $monthName: $value',
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: _getHeatmapColor(intensity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        } else {
          weekDays.add(
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.all(1),
            ),
          );
        }
      }
      
      weeks.add(
        Column(
          children: weekDays,
        ),
      );
      
      current = current.add(const Duration(days: 7));
    }
    
    return weeks;
  }

  String _getShortMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 0) {
      return _isDarkMode ? Colors.white12 : Colors.grey[300]!;
    }
    
    // Mint green with varying opacity
    if (intensity < 0.25) {
      return mintGreen.withOpacity(0.3);
    } else if (intensity < 0.5) {
      return mintGreen.withOpacity(0.5);
    } else if (intensity < 0.75) {
      return mintGreen.withOpacity(0.7);
    } else {
      return mintGreen;
    }
  }
}
