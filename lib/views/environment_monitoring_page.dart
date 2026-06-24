import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/environment_record.dart';
import '../services/api_client.dart';

class EnvironmentMonitoringPage extends StatefulWidget {
  const EnvironmentMonitoringPage({super.key});

  static const routeName = '/environment-monitoring';

  @override
  State<EnvironmentMonitoringPage> createState() =>
      _EnvironmentMonitoringPageState();
}

class _EnvironmentMonitoringPageState extends State<EnvironmentMonitoringPage> {
  bool _loading = true;
  String? _errorMessage;
  List<EnvironmentRecord> _records = const [];

  List<EnvironmentRecord> get _timeline {
    final items = [..._records];
    items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
      final records = await ApiServices.instance.fetchEnvironmentRecords();
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
        _errorMessage = 'Gagal memuat data environment monitoring.';
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
      backgroundColor: const Color(0xFFEAF7F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        title: const Text(
          'Environment Monitoring',
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
        color: const Color(0xFF0D9488),
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            _SummaryPanel(records: timeline, latest: latest),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 36),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                ),
              )
            else if (_errorMessage != null)
              _ErrorState(message: _errorMessage!, onRetry: _loadData)
            else if (timeline.isEmpty)
              const _EmptyState()
            else ...[
              _ChartSection(
                title: 'Utilization',
                subtitle: 'CPU, memory, dan disk usage',
                child: _MultiSeriesChart(
                  points: timeline
                      .map((item) => _formatShortDate(item.timestamp))
                      .toList(),
                  series: [
                    _ChartSeries(
                      label: 'CPU',
                      color: const Color(0xFF2563EB),
                      values: timeline.map((item) => item.cpuUsage).toList(),
                    ),
                    _ChartSeries(
                      label: 'Memory',
                      color: const Color(0xFFBE185D),
                      values: timeline.map((item) => item.memoryUsage).toList(),
                    ),
                    _ChartSeries(
                      label: 'Disk',
                      color: const Color(0xFFCA8A04),
                      values: timeline.map((item) => item.diskUsage).toList(),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                  valueSuffix: '%',
                ),
              ),
              const SizedBox(height: 12),
              _ChartSection(
                title: 'Response Time',
                subtitle: 'Latency sistem dalam millisecond',
                child: _SingleSeriesChart(
                  points: timeline
                      .map((item) => _formatShortDate(item.timestamp))
                      .toList(),
                  values: timeline
                      .map((item) => item.responseTime.toDouble())
                      .toList(),
                  color: const Color(0xFF0F766E),
                  valueSuffix: ' ms',
                ),
              ),
              const SizedBox(height: 12),
              _HealthSection(records: timeline),
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
              _RecordHistoryList(records: timeline.reversed.toList()),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.records, required this.latest});

  final List<EnvironmentRecord> records;
  final EnvironmentRecord? latest;

  @override
  Widget build(BuildContext context) {
    final avgCpu = _average(records.map((item) => item.cpuUsage));
    final avgMemory = _average(records.map((item) => item.memoryUsage));
    final avgDisk = _average(records.map((item) => item.diskUsage));
    final avgResponse = _average(records.map((item) => item.responseTime));
    final health = latest == null
        ? _HealthStatus.empty()
        : _HealthStatus.fromRecord(latest!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2614B8A6),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(health.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Health',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      health.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${records.length} record',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            latest == null
                ? 'Data environment belum tersedia.'
                : 'Update ${_formatDateTime(latest!.timestamp)} - uptime ${latest!.uptime.isEmpty ? '-' : latest!.uptime}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      icon: Icons.memory_outlined,
                      label: 'Avg CPU',
                      value: _formatPercent(avgCpu),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      icon: Icons.developer_board_outlined,
                      label: 'Avg Memory',
                      value: _formatPercent(avgMemory),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      icon: Icons.storage_outlined,
                      label: 'Avg Disk',
                      value: _formatPercent(avgDisk),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _SummaryMetric(
                      icon: Icons.speed_outlined,
                      label: 'Avg Response',
                      value: avgResponse == null
                          ? '-'
                          : '${avgResponse.round()} ms',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        border: Border.all(color: const Color(0xFFDDEAE7)),
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
      return const _ChartEmpty(message: 'Data grafik belum tersedia.');
    }

    return Column(
      children: [
        SizedBox(
          height: 172,
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
            final values = item.values.whereType<double>().toList();
            final latest = values.isEmpty
                ? '-'
                : '${values.last.toStringAsFixed(1)}$valueSuffix';
            return _LegendItem(
              label: item.label,
              value: latest,
              color: item.color,
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
      return const _ChartEmpty(message: 'Data grafik belum tersedia.');
    }
    final maxY = math.max(1.0, nonNull.reduce(math.max) * 1.2).toDouble();
    final latest = nonNull.last;

    return Column(
      children: [
        SizedBox(
          height: 158,
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
          child: _LegendItem(
            label: 'Terbaru',
            value: '${latest.round()}$valueSuffix',
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $value',
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
    if (points.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _AxisText(points.first),
      );
    }
    if (points.length == 2) {
      return Row(
        children: [
          Expanded(child: _AxisText(points.first)),
          Expanded(child: _AxisText(points.last, align: TextAlign.right)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _AxisText(points.first)),
        Expanded(
          child: _AxisText(points[points.length ~/ 2], align: TextAlign.center),
        ),
        Expanded(child: _AxisText(points.last, align: TextAlign.right)),
      ],
    );
  }
}

class _AxisText extends StatelessWidget {
  const _AxisText(this.text, {this.align = TextAlign.left});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
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

class _HealthSection extends StatelessWidget {
  const _HealthSection({required this.records});

  final List<EnvironmentRecord> records;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      _HealthStatus.normal(),
      _HealthStatus.warning(),
      _HealthStatus.critical(),
    ];
    final counts = {
      for (final status in statuses)
        status.key: records
            .where(
              (record) => _HealthStatus.fromRecord(record).key == status.key,
            )
            .length,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Kondisi',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...statuses.map(
            (status) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _HealthBar(
                status: status,
                count: counts[status.key] ?? 0,
                total: records.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({
    required this.status,
    required this.count,
    required this.total,
  });

  final _HealthStatus status;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;

    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Row(
            children: [
              Icon(status.icon, color: status.color, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: fraction,
              color: status.color,
              backgroundColor: status.color.withValues(alpha: 0.12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordHistoryList extends StatelessWidget {
  const _RecordHistoryList({required this.records});

  final List<EnvironmentRecord> records;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: records
          .map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecordCard(record: record),
            ),
          )
          .toList(),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final EnvironmentRecord record;

  @override
  Widget build(BuildContext context) {
    final health = _HealthStatus.fromRecord(record);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _RecordDetailSheet(record: record),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDEAE7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(status: health),
                  const Spacer(),
                  Text(
                    _formatDateTime(record.timestamp),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InlineGauge(
                      label: 'CPU',
                      value: record.cpuUsage,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InlineGauge(
                      label: 'Mem',
                      value: record.memoryUsage,
                      color: const Color(0xFFBE185D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InlineGauge(
                      label: 'Disk',
                      value: record.diskUsage,
                      color: const Color(0xFFCA8A04),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.speed_outlined,
                    color: _responseColor(record.responseTime),
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${record.responseTime} ms',
                    style: TextStyle(
                      color: _responseColor(record.responseTime),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    record.uptime.isEmpty
                        ? 'Uptime -'
                        : 'Uptime ${record.uptime}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineGauge extends StatelessWidget {
  const _InlineGauge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _HealthStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordDetailSheet extends StatelessWidget {
  const _RecordDetailSheet({required this.record});

  final EnvironmentRecord record;

  @override
  Widget build(BuildContext context) {
    final health = _HealthStatus.fromRecord(record);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Detail Environment',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusBadge(status: health),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(record.timestamp),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _DetailGauge(
              label: 'CPU Usage',
              value: record.cpuUsage,
              color: const Color(0xFF2563EB),
            ),
            _DetailGauge(
              label: 'Memory Usage',
              value: record.memoryUsage,
              color: const Color(0xFFBE185D),
            ),
            _DetailGauge(
              label: 'Disk Usage',
              value: record.diskUsage,
              color: const Color(0xFFCA8A04),
            ),
            const SizedBox(height: 6),
            _detailRow('Response Time', '${record.responseTime} ms'),
            _detailRow('Uptime', record.uptime.isEmpty ? '-' : record.uptime),
            _detailRow(
              'Project ID',
              record.projectId.isEmpty ? '-' : record.projectId,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailGauge extends StatelessWidget {
  const _DetailGauge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _InlineGauge(label: label, value: value, color: color),
    );
  }
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 118,
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

class _HealthStatus {
  const _HealthStatus({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String key;
  final String label;
  final Color color;
  final IconData icon;

  factory _HealthStatus.empty() {
    return const _HealthStatus(
      key: 'empty',
      label: 'Belum Ada Data',
      color: Color(0xFF64748B),
      icon: Icons.public_outlined,
    );
  }

  factory _HealthStatus.normal() {
    return const _HealthStatus(
      key: 'normal',
      label: 'Normal',
      color: Color(0xFF16A34A),
      icon: Icons.check_circle_outline,
    );
  }

  factory _HealthStatus.warning() {
    return const _HealthStatus(
      key: 'warning',
      label: 'Warning',
      color: Color(0xFFD97706),
      icon: Icons.warning_amber_rounded,
    );
  }

  factory _HealthStatus.critical() {
    return const _HealthStatus(
      key: 'critical',
      label: 'Kritis',
      color: Color(0xFFDC2626),
      icon: Icons.error_outline,
    );
  }

  factory _HealthStatus.fromRecord(EnvironmentRecord record) {
    if (record.cpuUsage >= 85 ||
        record.memoryUsage >= 90 ||
        record.diskUsage >= 92 ||
        record.responseTime >= 450) {
      return _HealthStatus.critical();
    }
    if (record.cpuUsage >= 70 ||
        record.memoryUsage >= 75 ||
        record.diskUsage >= 80 ||
        record.responseTime >= 250) {
      return _HealthStatus.warning();
    }
    return _HealthStatus.normal();
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
        border: Border.all(color: const Color(0xFFDDEAE7)),
      ),
      child: const Text(
        'Belum ada data environment. Data akan muncul saat record dari API tersedia.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

double? _average(Iterable<num> values) {
  final items = values.toList();
  if (items.isEmpty) {
    return null;
  }
  return items.fold<double>(0, (sum, item) => sum + item.toDouble()) /
      items.length;
}

String _formatPercent(double? value) {
  if (value == null) {
    return '-';
  }
  return '${value.toStringAsFixed(1)}%';
}

String _formatShortDate(DateTime value) {
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
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  return '$day ${months[local.month - 1]}';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatShortDate(local)}, $hour:$minute';
}

Color _responseColor(int value) {
  if (value >= 450) {
    return const Color(0xFFDC2626);
  }
  if (value >= 250) {
    return const Color(0xFFD97706);
  }
  return const Color(0xFF16A34A);
}
