import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Models/transaction.dart';

class AnalyticsTrendsScreen extends StatefulWidget {
  const AnalyticsTrendsScreen({super.key});

  @override
  State<AnalyticsTrendsScreen> createState() => _AnalyticsTrendsScreenState();
}

class _AnalyticsTrendsScreenState extends State<AnalyticsTrendsScreen> {
  bool _loading = true;
  List<TransactionModel> _all = [];

  // Filter State
  String? _selectedCategory;
  List<String> _categories = [];

  String _selectedRange = "6 Months";
  final List<String> _rangeOptions = [
    "3 Months",
    "6 Months",
    "1 Year",
    "All Time",
  ];

  // Chart Data
  List<FlSpot> _spots = [];
  double _maxY = 100;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .orderBy('date', descending: false) // Oldest first for chart
          .get();

      setState(() {
        _all = snap.docs
            .map((e) => TransactionModel.fromMap(e.id, e.data()))
            .where((tx) => tx.senderId == user.uid) // Only expenses
            .toList();

        // Extract unique categories
        final cats = _all.map((e) => e.category ?? "Other").toSet().toList()
          ..sort();
        _categories = ["All Categories", ...cats];

        _selectedCategory = "All Categories";
        _prepareChartData();
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading trends: $e");
      setState(() => _loading = false);
    }
  }

  void _prepareChartData() {
    if (_selectedCategory == null) return;

    final Map<int, double> monthlySum = {};

    for (var tx in _all) {
      if (_selectedCategory == "All Categories" ||
          tx.category == _selectedCategory) {
        final key = tx.date.year * 100 + tx.date.month;
        monthlySum[key] = (monthlySum[key] ?? 0) + tx.amount.abs();
      }
    }

    final sortedKeys = monthlySum.keys.toList()..sort();

    // Filter keys based on range
    int count;
    switch (_selectedRange) {
      case "3 Months":
        count = 3;
        break;
      case "6 Months":
        count = 6;
        break;
      case "1 Year":
        count = 12;
        break;
      default:
        count = 9999;
        break; // All Time
    }

    final displayKeys = sortedKeys.length > count
        ? sortedKeys.sublist(sortedKeys.length - count)
        : sortedKeys;

    List<FlSpot> spots = [];
    double maxVal = 0;

    for (int i = 0; i < displayKeys.length; i++) {
      final key = displayKeys[i];
      final val = monthlySum[key]!;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxVal) maxVal = val;
    }

    setState(() {
      _spots = spots;
      _maxY = maxVal > 0 ? maxVal * 1.2 : 100;
    });
  }

  String _getMonthLabel(int index) {
    if (_spots.isEmpty) return "";
    if (_selectedCategory == null) return "";

    final Map<int, double> monthlySum = {};
    for (var tx in _all) {
      if (_selectedCategory == "All Categories" ||
          tx.category == _selectedCategory) {
        final key = tx.date.year * 100 + tx.date.month;
        monthlySum[key] = (monthlySum[key] ?? 0) + tx.amount;
      }
    }
    final sortedKeys = monthlySum.keys.toList()..sort();

    int count;
    switch (_selectedRange) {
      case "3 Months":
        count = 3;
        break;
      case "6 Months":
        count = 6;
        break;
      case "1 Year":
        count = 12;
        break;
      default:
        count = 9999;
        break;
    }

    final displayKeys = sortedKeys.length > count
        ? sortedKeys.sublist(sortedKeys.length - count)
        : sortedKeys;

    if (index < 0 || index >= displayKeys.length) return "";

    final key = displayKeys[index];
    final year = key ~/ 100;
    final month = key % 100;

    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[month]}\n$year";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E), // Midnight Void
            const Color(0xFF16213E).withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "Category Trends",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Card
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                // Category Filter
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: Colors.white70,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          dropdownColor: const Color(0xFF16213E),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedCategory = v;
                                _prepareChartData();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                SizedBox(height: 12.h),
                // Range Filter
                Row(
                  children: [
                    Icon(Icons.date_range, color: Colors.white70, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRange,
                          dropdownColor: const Color(0xFF16213E),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                          items: _rangeOptions.map((r) {
                            return DropdownMenuItem(value: r, child: Text(r));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedRange = v;
                                _prepareChartData();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          // Chart Card
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(16.w, 32.h, 24.w, 16.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05), // Dark Glass
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.show_chart,
                        color: const Color(0xFF00E5FF),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Spending Over Time",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  Expanded(
                    child: _spots.isEmpty
                        ? Center(
                            child: Text(
                              "Not enough data",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14.sp,
                              ),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: _maxY / 5,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (val, meta) {
                                      final idx = val.toInt();
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          _getMonthLabel(idx),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.5,
                                            ),
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: _maxY / 5,
                                    getTitlesWidget: (val, meta) {
                                      return Text(
                                        "${(val / 1000).toStringAsFixed(1)}k",
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontSize: 10.sp,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: _spots.length > 1
                                  ? (_spots.length - 1).toDouble()
                                  : 1,
                              minY: 0,
                              maxY: _maxY,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _spots,
                                  isCurved: true,
                                  color: const Color(0xFF00E5FF),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF00E5FF,
                                        ).withValues(alpha: 0.2),
                                        const Color(
                                          0xFF00E5FF,
                                        ).withValues(alpha: 0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
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
          SizedBox(height: 30.h),
        ],
      ),
    );
  }
}
