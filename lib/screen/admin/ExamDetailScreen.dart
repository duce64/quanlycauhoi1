import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterquiz/configdomain.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExamDetailScreen extends StatefulWidget {
  final String examId;
  final String title;

  const ExamDetailScreen({
    Key? key,
    required this.examId,
    required this.title,
  }) : super(key: key);

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  List<Result> results = [];
  bool isLoading = true;
  double minScoreFilter = 0;

  @override
  void initState() {
    super.initState();
    loadResults();
  }

  Future<void> loadResults() async {
    try {
      final res = await http.get(
        Uri.parse(
            '${AppConstants.baseUrl}/api/results/by-test/${widget.examId}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          results = data.map((e) => Result.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Lỗi tải dữ liệu');
      }
    } catch (e) {
      print("Lỗi: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> exportToPDF(List<Result> results) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Báo cáo kết quả: ${widget.title}',
                style: pw.TextStyle(font: ttf, fontSize: 20)),
            pw.SizedBox(height: 12),
            ...results.map((r) => pw.Text(
                  '${r.username} - ${r.score} điểm - ${r.status} - ${formatDate(r.date)}',
                  style: pw.TextStyle(font: ttf),
                )),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final filteredResults =
        results.where((r) => r.score >= minScoreFilter).toList();
    final int passed =
        filteredResults.where((r) => r.status == 'Passed').length;
    final int failed = filteredResults.length - passed;
    final int total = filteredResults.length;
    final double passPercent = total > 0 ? (passed / total) * 100 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F1FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.teal),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF002856))),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => exportToPDF(filteredResults),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.teal),
                  )
                ],
              ),
            ),

            // Nội dung
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lọc điểm
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Lọc theo điểm:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              DropdownButton<double>(
                                value: minScoreFilter,
                                items: [0.0, 50.0, 60.0, 70.0, 80.0]
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text('> $e'),
                                        ))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => minScoreFilter = value!),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Biểu đồ tròn
                          SizedBox(
                            height: 200,
                            child: total == 0
                                ? const Center(
                                    child: Text(
                                      'Chưa có dữ liệu để hiển thị biểu đồ',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        PieChartSectionData(
                                          value: passed.toDouble(),
                                          title:
                                              '${passPercent.toStringAsFixed(1)}% Passed',
                                          color: Colors.green,
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        PieChartSectionData(
                                          value: failed.toDouble(),
                                          title: '$failed Failed',
                                          color: Colors.redAccent,
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Biểu đồ cột
                          SizedBox(
                            height: 220,
                            child: total == 0
                                ? const Center(
                                    child: Text(
                                      'Chưa có dữ liệu để hiển thị biểu đồ cột',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            interval: 20,
                                            getTitlesWidget: (value, _) =>
                                                Text('${value.toInt()}'),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, _) {
                                              final index = value.toInt();
                                              if (index < 0 ||
                                                  index >=
                                                      filteredResults.length)
                                                return const SizedBox();
                                              return RotatedBox(
                                                quarterTurns: 1,
                                                child: Text(
                                                  filteredResults[index]
                                                      .username,
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        rightTitles: AxisTitles(),
                                        topTitles: AxisTitles(),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barGroups: filteredResults
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final r = entry.value;
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: r.score,
                                              width: 18,
                                              color: r.status == 'Passed'
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 24),
                          const Text(
                            'Danh sách kết quả:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredResults.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final r = filteredResults[index];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(r.username),
                                subtitle:
                                    Text('Điểm: ${r.score} - ${r.status}'),
                                trailing: Text(
                                  formatDate(r.date),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class Result {
  final String username;
  final double score;
  final String status;
  final DateTime date;

  Result({
    required this.username,
    required this.score,
    required this.status,
    required this.date,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      username: json['userId']['username'],
      score: (json['score'] as num).toDouble(),
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }
}
