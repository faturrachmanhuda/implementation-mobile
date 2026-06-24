import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/model_transaction.dart';
import '../services/api_client.dart';

class ModelTransactionLoggingPage extends StatefulWidget {
  const ModelTransactionLoggingPage({super.key});

  static const routeName = '/model-transaction-logging';

  @override
  State<ModelTransactionLoggingPage> createState() =>
      _ModelTransactionLoggingPageState();
}

class _ModelTransactionLoggingPageState
    extends State<ModelTransactionLoggingPage> {
  bool _loading = true;
  String? _errorMessage;
  List<ModelTransaction> _transactions = const [];
  String _searchQuery = '';

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
      final transactions = await ApiServices.instance.fetchModelTransactions();
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Gagal memuat data log transaksi model.';
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  List<ModelTransaction> get _filteredTransactions {
    if (_searchQuery.trim().isEmpty) {
      return _transactions;
    }
    final q = _searchQuery.toLowerCase();
    return _transactions.where((t) {
      return t.idTransaksi.toLowerCase().contains(q) ||
          t.modelId.toLowerCase().contains(q) ||
          t.idSistem.toLowerCase().contains(q) ||
          t.prediksiModel.toLowerCase().contains(q) ||
          t.labelOutput.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        titleSpacing: 0,
        title: const Text(
          'Model Transaction Logging',
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          children: [
            _SummaryDashboard(transactions: _transactions),
            const SizedBox(height: 12),
            _SearchBar(
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
            const SizedBox(height: 12),
            if (!_loading && _errorMessage == null) ...[
              _TransactionCharts(transactions: filtered),
              const SizedBox(height: 12),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ErrorState(message: _errorMessage!, onRetry: _loadData)
            else if (filtered.isEmpty)
              const _EmptyState()
            else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  'Daftar Transaksi',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final t = filtered[index];
                  return _TransactionCard(
                    transaction: t,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _TransactionDetailSheet(transaction: t),
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: filtered.length,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionCharts extends StatelessWidget {
  const _TransactionCharts({required this.transactions});

  final List<ModelTransaction> transactions;

  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF0D9488),
    Color(0xFF2563EB),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF475569),
  ];

  @override
  Widget build(BuildContext context) {
    final modelCounts = _countBy(
      transactions,
      (transaction) => transaction.modelId,
    );
    final inputTypeCounts = _countBy(
      transactions,
      (transaction) => transaction.tipeDataInput,
    );

    return Column(
      children: [
        _ChartCard(
          title: 'Transaksi per Model',
          subtitle: 'Berdasarkan model_id',
          icon: Icons.bar_chart_rounded,
          child: _MiniBarChart(items: modelCounts, colors: _colors),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Tipe Data Input',
          subtitle: 'Teks, gambar, numerik, sensor',
          icon: Icons.pie_chart_rounded,
          child: _MiniPieChart(items: inputTypeCounts, colors: _colors),
        ),
      ],
    );
  }

  static List<_CountItem> _countBy(
    List<ModelTransaction> data,
    String Function(ModelTransaction transaction) selector,
  ) {
    final counts = <String, int>{};
    for (final transaction in data) {
      final label = selector(transaction).trim().isEmpty
          ? '-'
          : selector(transaction).trim();
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final items =
        counts.entries
            .map((entry) => _CountItem(entry.key, entry.value))
            .toList()
          ..sort((a, b) {
            final countCompare = b.count.compareTo(a.count);
            if (countCompare != 0) return countCompare;
            return a.label.compareTo(b.label);
          });

    if (items.length <= 6) {
      return items;
    }

    final shown = items.take(5).toList();
    final otherCount = items
        .skip(5)
        .fold<int>(0, (total, item) => total + item.count);
    return [...shown, _CountItem('Lainnya', otherCount)];
  }
}

class _CountItem {
  const _CountItem(this.label, this.count);

  final String label;
  final int count;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED), size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.items, required this.colors});

  final List<_CountItem> items;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _ChartEmpty(message: 'Belum ada transaksi model.');
    }

    final maxCount = items.map((item) => item.count).reduce(math.max);

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              child: _BarItem(
                item: items[index],
                maxCount: maxCount,
                color: colors[index % colors.length],
              ),
            ),
            if (index != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.item,
    required this.maxCount,
    required this.color,
  });

  final _CountItem item;
  final int maxCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${item.count}',
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: ratio.clamp(0.08, 1.0),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 44),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 30,
          child: Text(
            _shortLabel(item.label),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPieChart extends StatelessWidget {
  const _MiniPieChart({required this.items, required this.colors});

  final List<_CountItem> items;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _ChartEmpty(message: 'Belum ada tipe data input.');
    }

    final total = items.fold<int>(0, (sum, item) => sum + item.count);

    return Row(
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: CustomPaint(
            painter: _PieChartPainter(items: items, colors: colors),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'transaksi',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++)
                _PieLegendItem(
                  item: items[index],
                  total: total,
                  color: colors[index % colors.length],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PieLegendItem extends StatelessWidget {
  const _PieLegendItem({
    required this.item,
    required this.total,
    required this.color,
  });

  final _CountItem item;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : item.count / total * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({required this.items, required this.colors});

  final List<_CountItem> items;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) return;

    final rect = Offset.zero & size;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    var start = -math.pi / 2;

    for (var index = 0; index < items.length; index++) {
      final sweep = (items[index].count / total) * math.pi * 2;
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, start, sweep, true, paint);
      canvas.drawArc(rect, start, sweep, true, strokePaint);
      start += sweep;
    }

    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.28,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.colors != colors;
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _shortLabel(String value) {
  final label = value.trim().isEmpty ? '-' : value.trim();
  return label.length <= 12 ? label : '${label.substring(0, 11)}.';
}

class _SummaryDashboard extends StatelessWidget {
  const _SummaryDashboard({required this.transactions});

  final List<ModelTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final total = transactions.length;
    double avgConfidence = 0.0;
    double avgLatency = 0.0;

    if (total > 0) {
      final confs = transactions
          .map((t) => t.probabilitasSkor)
          .whereType<double>()
          .toList();
      if (confs.isNotEmpty) {
        avgConfidence = confs.reduce((a, b) => a + b) / confs.length;
      }

      final lats = transactions
          .map((t) => t.waktuInferensiMs)
          .whereType<int>()
          .toList();
      if (lats.isNotEmpty) {
        avgLatency = lats.reduce((a, b) => a + b) / lats.length;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Transaksi',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Total Log',
                  value: '$total',
                  icon: Icons.history_toggle_off,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'Avg Akurasi',
                  value: '${(avgConfidence * 100).toStringAsFixed(1)}%',
                  icon: Icons.done_all,
                  color: const Color(0xFF0D9488),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'Avg Latency',
                  value: '${avgLatency.round()} ms',
                  icon: Icons.speed,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Cari berdasarkan ID Transaksi, Model, atau Sistem...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.onTap});

  final ModelTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final conf = (transaction.probabilitasSkor ?? 0.0) * 100;
    final isMatch =
        transaction.prediksiModel.trim().toLowerCase() ==
            transaction.groundTruth.trim().toLowerCase() &&
        transaction.groundTruth.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction.idTransaksi.isEmpty
                              ? 'TX-${transaction.id}'
                              : transaction.idTransaksi,
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _LatencyBadge(latency: transaction.waktuInferensiMs),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    transaction.modelId,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Sistem: ',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        transaction.idSistem.isEmpty
                            ? '-'
                            : transaction.idSistem,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PREDIKSI MODEL',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              transaction.prediksiModel.isEmpty
                                  ? '-'
                                  : transaction.prediksiModel,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'GROUND TRUTH',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (isMatch) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF0D9488),
                                    size: 11,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              transaction.groundTruth.isEmpty
                                  ? 'Belum dinilai'
                                  : transaction.groundTruth,
                              style: TextStyle(
                                color: transaction.groundTruth.isEmpty
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF1E293B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: transaction.probabilitasSkor ?? 0.0,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1F5F9),
                            color: conf > 85
                                ? const Color(0xFF0D9488)
                                : conf > 60
                                ? const Color(0xFFEab308)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${conf.toStringAsFixed(1)}% Conf.',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LatencyBadge extends StatelessWidget {
  const _LatencyBadge({required this.latency});

  final int? latency;

  @override
  Widget build(BuildContext context) {
    if (latency == null) return const SizedBox.shrink();

    Color bgColor = const Color(0xFFF0FDF4);
    Color textColor = const Color(0xFF16A34A);

    if (latency! > 300) {
      bgColor = const Color(0xFFFEF2F2);
      textColor = const Color(0xFFDC2626);
    } else if (latency! > 100) {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: textColor, size: 12),
          const SizedBox(width: 2),
          Text(
            '$latency ms',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({required this.transaction});

  final ModelTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final conf = (transaction.probabilitasSkor ?? 0.0) * 100;
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
            transaction.idTransaksi.isEmpty
                ? 'Transaksi #${transaction.id}'
                : transaction.idTransaksi,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          _DetailRow(label: 'Model ID', value: transaction.modelId),
          _DetailRow(label: 'Sistem ID', value: transaction.idSistem),
          _DetailRow(
            label: 'Tipe Data Input',
            value: transaction.tipeDataInput,
          ),
          _DetailRow(label: 'Prediksi Model', value: transaction.prediksiModel),
          _DetailRow(label: 'Label Output', value: transaction.labelOutput),
          _DetailRow(
            label: 'Skor Probabilitas (Confidence)',
            value:
                '${conf.toStringAsFixed(1)}% (${transaction.probabilitasSkor ?? 0.0})',
          ),
          _DetailRow(
            label: 'Ground Truth',
            value: transaction.groundTruth.isEmpty
                ? 'Belum dimasukkan'
                : transaction.groundTruth,
            strong: transaction.groundTruth.isNotEmpty,
          ),
          _DetailRow(label: 'Sumber Data', value: transaction.sumberData),
          _DetailRow(
            label: 'Waktu Inferensi',
            value: transaction.waktuInferensiMs == null
                ? '-'
                : '${transaction.waktuInferensiMs} ms',
          ),
          _DetailRow(
            label: 'Konteks Permintaan',
            value: transaction.konteksPermintaan.isEmpty
                ? '-'
                : transaction.konteksPermintaan,
          ),
          _DetailRow(
            label: 'Waktu Dibuat',
            value: _formatFullDate(transaction.timestamp),
          ),
        ],
      ),
    );
  }

  static String _formatFullDate(DateTime val) {
    return '${val.day.toString().padLeft(2, '0')}-${val.month.toString().padLeft(2, '0')}-${val.year} '
        '${val.hour.toString().padLeft(2, '0')}:${val.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: strong
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.article_outlined,
                color: Color(0xFF7C3AED),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Log Transaksi',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Data transaksi model akan dimuat secara otomatis dari sistem server eksternal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
