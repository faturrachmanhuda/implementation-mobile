import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/performance_record.dart';
import '../services/api_client.dart';

class PerformanceMonitoringPage extends StatefulWidget {
  const PerformanceMonitoringPage({super.key});

  static const routeName = '/performance-monitoring';

  @override
  State<PerformanceMonitoringPage> createState() =>
      _PerformanceMonitoringPageState();
}

class _PerformanceMonitoringPageState extends State<PerformanceMonitoringPage> {
  bool _loading = true;
  String? _errorMessage;
  List<PerformanceRecord> _records = const [];

  List<PerformanceRecord> get _timeline {
    final items = [..._records];
    items.sort((a, b) => a.timeline.compareTo(b.timeline));
    return items;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final records = await ApiServices.instance.fetchPerformanceRecords();
      if (!mounted) {
        return;
      }
      setState(() {
        _records = records;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = 'Gagal memuat data performance monitoring.';
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timeline;
    final latest = timeline.isEmpty ? null : timeline.last;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        titleSpacing: 0,
        title: const Text(
          'Performance Monitoring',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _SummaryStrip(records: timeline, latest: latest),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ErrorState(message: _errorMessage!, onRetry: _loadData)
            else if (timeline.isEmpty)
              const _EmptyState()
            else ...[
              _ChartSection(
                title: 'Kualitas Model',
                subtitle: 'Akurasi, Presisi, Recall, F1 Score',
                child: _MultiSeriesChart(
                  points: timeline
                      .map((item) => _formatDate(item.timeline))
                      .toList(),
                  series: [
                    _ChartSeries(
                      label: 'Akurasi',
                      color: const Color(0xFF4F46E5),
                      values: timeline
                          .map((item) => _toPercent(item.accuracy))
                          .toList(),
                    ),
                    _ChartSeries(
                      label: 'Presisi',
                      color: const Color(0xFF0EA5E9),
                      values: timeline
                          .map((item) => _toPercent(item.precision))
                          .toList(),
                    ),
                    _ChartSeries(
                      label: 'Recall',
                      color: const Color(0xFF22C55E),
                      values: timeline
                          .map((item) => _toPercent(item.recall))
                          .toList(),
                    ),
                    _ChartSeries(
                      label: 'F1',
                      color: const Color(0xFFF59E0B),
                      values: timeline
                          .map((item) => _toPercent(item.f1Score))
                          .toList(),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                  valueSuffix: '%',
                ),
              ),
              const SizedBox(height: 12),
              _ChartSection(
                title: 'Latency',
                subtitle: 'Response time (ms)',
                child: _SingleSeriesChart(
                  points: timeline
                      .map((item) => _formatDate(item.timeline))
                      .toList(),
                  values: timeline
                      .map((item) => item.latencyMs?.toDouble())
                      .toList(),
                  color: const Color(0xFFEF4444),
                  valueSuffix: ' ms',
                ),
              ),
              const SizedBox(height: 12),
              _ChartSection(
                title: 'Throughput',
                subtitle: 'Request per detik',
                child: _SingleSeriesChart(
                  points: timeline
                      .map((item) => _formatDate(item.timeline))
                      .toList(),
                  values: timeline.map((item) => item.throughput).toList(),
                  color: const Color(0xFF14B8A6),
                  valueSuffix: ' req/s',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Riwayat Ringkas',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _RecordHistoryTable(records: timeline.reversed.toList()),
            ],
          ],
        ),
      ),
    );
  }

  static double? _toPercent(double? value) =>
      value == null ? null : value * 100;

  static String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = value.day.toString().padLeft(2, '0');
    return '$day ${months[value.month - 1]}';
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.records, required this.latest});

  final List<PerformanceRecord> records;
  final PerformanceRecord? latest;

  @override
  Widget build(BuildContext context) {
    final avgAcc = _average(records.map((item) => item.accuracy).toList());
    final avgLatency = _average(
      records.map((item) => item.latencyMs?.toDouble()).toList(),
    );
    final avgThroughput = _average(
      records.map((item) => item.throughput).toList(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        children: [
          _SummaryItem(label: 'Total', value: '${records.length} record'),
          _SummaryItem(
            label: 'Avg Akurasi',
            value: avgAcc == null
                ? '-'
                : '${(avgAcc * 100).toStringAsFixed(1)}%',
          ),
          _SummaryItem(
            label: 'Avg Latency',
            value: avgLatency == null ? '-' : '${avgLatency.round()} ms',
          ),
          _SummaryItem(
            label: 'Avg Throughput',
            value: avgThroughput == null
                ? '-'
                : '${avgThroughput.toStringAsFixed(1)} /s',
          ),
          if (latest != null)
            _SummaryItem(
              label: 'Status Terbaru',
              value: _statusLabel(latest!.status),
            ),
        ],
      ),
    );
  }

  static double? _average(List<double?> values) {
    final nonNull = values.whereType<double>().toList();
    if (nonNull.isEmpty) {
      return null;
    }
    return nonNull.reduce((a, b) => a + b) / nonNull.length;
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'perlu_perhatian':
        return 'Perlu Perhatian';
      case 'kritis':
        return 'Kritis';
      default:
        return 'Baik';
    }
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChartSeries {
  const _ChartSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double?> values;
}

class _MultiSeriesChart extends StatelessWidget {
  const _MultiSeriesChart({
    required this.points,
    required this.series,
    required this.minY,
    required this.maxY,
    required this.valueSuffix,
  });

  final List<String> points;
  final List<_ChartSeries> series;
  final double minY;
  final double maxY;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final hasData = series.any(
      (item) => item.values.whereType<double>().isNotEmpty,
    );
    if (!hasData) {
      return const _ChartEmpty(message: 'Data belum tersedia.');
    }

    return Column(
      children: [
        SizedBox(
          height: 170,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              series: series
                  .map(
                    (item) =>
                        _PainterSeries(color: item.color, values: item.values),
                  )
                  .toList(),
              minY: minY,
              maxY: maxY,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _XAxisLabels(points: points),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: series.map((item) {
            final last = item.values.whereType<double>().isEmpty
                ? '-'
                : '${item.values.whereType<double>().last.toStringAsFixed(1)}$valueSuffix';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.label} $last',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SingleSeriesChart extends StatelessWidget {
  const _SingleSeriesChart({
    required this.points,
    required this.values,
    required this.color,
    required this.valueSuffix,
  });

  final List<String> points;
  final List<double?> values;
  final Color color;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final nonNull = values.whereType<double>().toList();
    if (nonNull.isEmpty) {
      return const _ChartEmpty(message: 'Data belum tersedia.');
    }
    final maxY = math.max(1.0, nonNull.reduce(math.max) * 1.2).toDouble();
    final latest = nonNull.last;

    return Column(
      children: [
        SizedBox(
          height: 160,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              series: [_PainterSeries(color: color, values: values)],
              minY: 0,
              maxY: maxY,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _XAxisLabels(points: points),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Terbaru: ${latest.toStringAsFixed(latest < 10 ? 2 : 1)}$valueSuffix',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  const _XAxisLabels({required this.points});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    final first = points.first;
    final middle = points[points.length ~/ 2];
    final last = points.last;

    return Row(
      children: [
        Expanded(
          child: Text(
            first,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            middle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            last,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _PainterSeries {
  const _PainterSeries({required this.color, required this.values});

  final Color color;
  final List<double?> values;
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.series,
    required this.minY,
    required this.maxY,
  });

  final List<_PainterSeries> series;
  final double minY;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(8, 8, 8, 14);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;
    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = padding.top + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );
    }

    final range = (maxY - minY).abs() < 0.0001 ? 1.0 : maxY - minY;

    for (final item in series) {
      final path = Path();
      bool started = false;
      Offset? lastPoint;

      for (var i = 0; i < item.values.length; i++) {
        final value = item.values[i];
        if (value == null) {
          started = false;
          continue;
        }
        final dx = item.values.length == 1
            ? padding.left + chartWidth / 2
            : padding.left + chartWidth * i / (item.values.length - 1);
        final normalized = ((value - minY) / range).clamp(0.0, 1.0);
        final dy = padding.top + chartHeight * (1 - normalized);
        final point = Offset(dx, dy);

        if (!started) {
          path.moveTo(point.dx, point.dy);
          started = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
        lastPoint = point;
      }

      final linePaint = Paint()
        ..color = item.color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      if (lastPoint != null) {
        final dotPaint = Paint()..color = item.color;
        canvas.drawCircle(lastPoint, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RecordHistoryTable extends StatelessWidget {
  const _RecordHistoryTable({required this.records});

  final List<PerformanceRecord> records;

  @override
  Widget build(BuildContext context) {
    String pct(double? value) =>
        value == null ? '-' : '${(value * 100).toStringAsFixed(1)}%';

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = records[index];
        final status = _RecordStatus.from(record.status);
        final accuracyPercent = pct(record.accuracy);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _RecordDetailSheet(record: record),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Beautiful vertical indicator bar:
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: status.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    record.systemName.isEmpty
                                        ? 'Tanpa nama sistem'
                                        : record.systemName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _PerformanceMonitoringPageState._formatDate(
                                    record.timeline,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _MiniMetricBadge(
                                  icon: Icons.done_all,
                                  label: 'Akurasi: $accuracyPercent',
                                  color: const Color(0xFF4F46E5),
                                ),
                                _MiniMetricBadge(
                                  icon: Icons.bolt,
                                  label: record.latencyMs == null
                                      ? 'Latency: -'
                                      : '${record.latencyMs} ms',
                                  color: const Color(0xFFEF4444),
                                ),
                                _StatusBadge(
                                  label: status.label,
                                  color: status.color,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniMetricBadge extends StatelessWidget {
  const _MiniMetricBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecordStatus {
  const _RecordStatus({required this.label, required this.color});

  final String label;
  final Color color;

  static _RecordStatus from(String status) {
    return switch (status) {
      'kritis' => const _RecordStatus(
        label: 'Kritis',
        color: Color(0xFFDC2626),
      ),
      'perlu_perhatian' => const _RecordStatus(
        label: 'Perlu Perhatian',
        color: Color(0xFFD97706),
      ),
      _ => const _RecordStatus(label: 'Baik', color: Color(0xFF16A34A)),
    };
  }
}

class _RecordDetailSheet extends StatelessWidget {
  const _RecordDetailSheet({required this.record});

  final PerformanceRecord record;

  @override
  Widget build(BuildContext context) {
    String pct(double? value) =>
        value == null ? '-' : '${(value * 100).toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            record.systemName.isEmpty ? 'Detail Record' : record.systemName,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow('Akurasi', pct(record.accuracy)),
          _detailRow('Presisi', pct(record.precision)),
          _detailRow('Recall', pct(record.recall)),
          _detailRow('F1 Score', pct(record.f1Score)),
          _detailRow(
            'Latency',
            record.latencyMs == null ? '-' : '${record.latencyMs} ms',
          ),
          _detailRow(
            'Throughput',
            record.throughput == null
                ? '-'
                : '${record.throughput!.toStringAsFixed(1)} req/s',
          ),
          _detailRow(
            'Error Rate',
            record.errorRate == null
                ? '-'
                : '${record.errorRate!.toStringAsFixed(2)}%',
          ),
          if (record.note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Catatan Tambahan',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                record.note,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gagal memuat data',
            style: TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        'Belum ada data performa. Nanti data akan otomatis muncul dari API.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
