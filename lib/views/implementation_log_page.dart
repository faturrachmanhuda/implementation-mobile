import 'dart:async';

import 'package:flutter/material.dart';

import '../models/implementation_log.dart';
import '../services/api_client.dart';

class ImplementationLogPage extends StatefulWidget {
  const ImplementationLogPage({super.key});

  static const routeName = '/implementation-log';

  @override
  State<ImplementationLogPage> createState() => _ImplementationLogPageState();
}

class _ImplementationLogPageState extends State<ImplementationLogPage> {
  bool _loading = true;
  bool _refreshing = false;
  String? _errorMessage;
  List<ImplementationLog> _logs = const [];
  String _searchQuery = '';
  String _statusFilter = '';
  Timer? _autoRefreshTimer;

  List<ImplementationLog> get _filteredLogs {
    final query = _searchQuery.trim().toLowerCase();
    return _logs.where((log) {
      final matchesStatus =
          _statusFilter.isEmpty || log.status == _statusFilter;
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;
      return log.aktivitas.toLowerCase().contains(query) ||
          log.penanggungJawab.toLowerCase().contains(query) ||
          log.namaSistem.toLowerCase().contains(query) ||
          log.lokasiDeployment.toLowerCase().contains(query) ||
          log.versi.toLowerCase().contains(query) ||
          log.hasil.toLowerCase().contains(query);
    }).toList();
  }

  int get _processCount => _logs.where((log) => log.status == 'proses').length;
  int get _doneCount => _logs.where((log) => log.status == 'selesai').length;
  int get _pendingCount => _logs.where((log) => log.status == 'pending').length;

  @override
  void initState() {
    super.initState();
    _loadData();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _loadData(showLoading: false),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    try {
      final logs = await ApiServices.instance.fetchImplementationLogs();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (showLoading || _logs.isEmpty) {
        setState(() {
          _errorMessage = error.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (showLoading || _logs.isEmpty) {
        setState(() {
          _errorMessage = 'Gagal memuat implementation log.';
          _loading = false;
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        titleSpacing: 0,
        title: const Text(
          'Implementation Log',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
          children: [
            _SummaryDashboard(
              total: _logs.length,
              process: _processCount,
              done: _doneCount,
              pending: _pendingCount,
            ),
            const SizedBox(height: 12),
            _LogFilterBar(
              selectedStatus: _statusFilter,
              onSearchChanged: (value) => setState(() => _searchQuery = value),
              onStatusChanged: (value) => setState(() => _statusFilter = value),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 52),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _MessageState(
                icon: Icons.error_outline,
                title: 'Tidak Bisa Memuat Data',
                message: _errorMessage!,
                action: _loadData,
              )
            else if (_logs.isEmpty)
              _MessageState(
                icon: Icons.description_outlined,
                title: 'Belum Ada Implementation Log',
                message:
                    'Aktivitas implementasi akan muncul saat tersedia dari API.',
                action: _loadData,
              )
            else if (_filteredLogs.isEmpty)
              _MessageState(
                icon: Icons.search_off_rounded,
                title: 'Log Tidak Ditemukan',
                message: 'Coba ubah kata pencarian atau filter status.',
                action: () => setState(() {
                  _searchQuery = '';
                  _statusFilter = '';
                }),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Daftar Aktivitas (${_filteredLogs.length})',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ..._filteredLogs.map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ImplementationLogCard(log: log),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryDashboard extends StatelessWidget {
  const _SummaryDashboard({
    required this.total,
    required this.process,
    required this.done,
    required this.pending,
  });

  final int total;
  final int process;
  final int done;
  final int pending;

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
            'Ringkasan Log',
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
                  label: 'Total',
                  value: '$total',
                  icon: Icons.description_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'Proses',
                  value: '$process',
                  icon: Icons.autorenew_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'Selesai',
                  value: '$done',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'Pending',
                  value: '$pending',
                  icon: Icons.pause_circle_outline_rounded,
                  color: const Color(0xFF64748B),
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
        Icon(icon, color: color, size: 19),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LogFilterBar extends StatelessWidget {
  const _LogFilterBar({
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  static const _filters = [
    ('', 'Semua'),
    ('proses', 'Proses'),
    ('selesai', 'Selesai'),
    ('pending', 'Pending'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Cari aktivitas, staff, sistem...',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: Icon(
                Icons.search,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              filled: true,
              fillColor: Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final selected = selectedStatus == filter.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(filter.$2),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: selected
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFFEFF6FF),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFE2E8F0),
                    ),
                    shape: const StadiumBorder(),
                    onSelected: (_) => onStatusChanged(filter.$1),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

void _showImplementationLogDetails(BuildContext context, ImplementationLog log) {
  final status = _LogStatus.from(log.status);
  final hasil = _ResultStatus.from(log.hasil);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 26,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFE2E8F0),
                      shape: StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Detail Implementation',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoLine(
                  icon: Icons.assignment_outlined,
                  text: log.aktivitas.isEmpty ? '-' : log.aktivitas,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatusBadge(status: status),
                    const SizedBox(width: 8),
                    _ResultBadge(status: hasil),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 16),
                _InfoLine(
                  icon: Icons.person_outline,
                  text: log.penanggungJawab.isEmpty ? '-' : log.penanggungJawab,
                ),
                _InfoLine(
                  icon: Icons.memory_outlined,
                  text: log.namaSistem.isEmpty ? '-' : log.namaSistem,
                ),
                if (log.lokasiDeployment.trim().isNotEmpty)
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    text: log.lokasiDeployment,
                  ),
                if (log.catatan.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Catatan',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      log.catatan,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ImplementationLogCard extends StatelessWidget {
  const _ImplementationLogCard({required this.log});

  final ImplementationLog log;

  @override
  Widget build(BuildContext context) {
    final status = _LogStatus.from(log.status);
    final hasil = _ResultStatus.from(log.hasil);

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
            onTap: () => _showImplementationLogDetails(context, log),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 68,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                log.aktivitas.isEmpty ? '-' : log.aktivitas,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MiniPill(
                              icon: Icons.calendar_today_outlined,
                              text: log.tanggal.isEmpty ? '-' : log.tanggal,
                            ),
                            _MiniPill(
                              icon: Icons.sell_outlined,
                              text: log.versi.isEmpty ? '-' : log.versi,
                            ),
                            _ResultBadge(status: hasil),
                          ],
                        ),
                      ],
                    ),
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

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 11),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogStatus {
  const _LogStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static _LogStatus from(String status) {
    return switch (status) {
      'selesai' => const _LogStatus(
        label: 'Selesai',
        color: Color(0xFF16A34A),
        icon: Icons.check_circle_outline_rounded,
      ),
      'pending' => const _LogStatus(
        label: 'Pending',
        color: Color(0xFF64748B),
        icon: Icons.pause_circle_outline_rounded,
      ),
      _ => const _LogStatus(
        label: 'Proses',
        color: Color(0xFFD97706),
        icon: Icons.autorenew_rounded,
      ),
    };
  }
}

class _ResultStatus {
  const _ResultStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static _ResultStatus from(String result) {
    return switch (result) {
      'gagal' => const _ResultStatus(
        label: 'Gagal',
        color: Color(0xFFDC2626),
        icon: Icons.cancel_outlined,
      ),
      _ => const _ResultStatus(
        label: 'Berhasil',
        color: Color(0xFF16A34A),
        icon: Icons.verified_outlined,
      ),
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _LogStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 10),
          const SizedBox(width: 3),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.status});

  final _ResultStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 11),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF94A3B8), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: action,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

