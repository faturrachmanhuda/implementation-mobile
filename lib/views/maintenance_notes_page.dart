import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/maintenance_note.dart';
import '../services/api_client.dart';
import '../services/app_session.dart';

class MaintenanceNotesPage extends StatefulWidget {
  const MaintenanceNotesPage({super.key});

  static const routeName = '/maintenance-notes';

  @override
  State<MaintenanceNotesPage> createState() => _MaintenanceNotesPageState();
}

class _MaintenanceNotesPageState extends State<MaintenanceNotesPage> {
  bool _loading = true;
  String? _errorMessage;
  List<MaintenanceNote> _notes = const [];
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
      final notes = await ApiServices.instance.fetchMaintenanceNotes();
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Gagal memuat maintenance notes.';
      });
    }
  }

  List<MaintenanceNote> get _filtered {
    if (_searchQuery.trim().isEmpty) return _notes;
    final q = _searchQuery.toLowerCase();
    return _notes.where((n) {
      return n.judul.toLowerCase().contains(q) ||
          n.deskripsi.toLowerCase().contains(q) ||
          n.staff.toLowerCase().contains(q) ||
          n.status.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _deleteNote(MaintenanceNote note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Catatan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('Hapus "${note.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await ApiServices.instance.deleteMaintenanceNote(note.id);
      _showSnack('Catatan berhasil dihapus.');
      _loadData();
    } on ApiException catch (e) {
      setState(() => _loading = false);
      _showSnack(e.message);
    } catch (_) {
      setState(() => _loading = false);
      _showSnack('Gagal menghapus catatan.');
    }
  }

  void _showFormSheet([MaintenanceNote? note]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NoteFormSheet(
        note: note,
        onSaved: () {
          _showSnack(
            note == null
                ? 'Catatan berhasil ditambahkan!'
                : 'Catatan berhasil diperbarui!',
          );
          _loadData();
        },
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Summary counts ──────────────────────────────────────────────
  int get _scheduledCount =>
      _notes.where((n) => n.status == 'scheduled').length;
  int get _onProgressCount =>
      _notes.where((n) => n.status == 'on_progress').length;
  int get _completedCount =>
      _notes.where((n) => n.status == 'completed').length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        titleSpacing: 0,
        title: const Text(
          'Maintenance Notes',
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
        onRefresh: () => _loadData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          children: [
            // ── Summary dashboard ──────────────────────────────────
            _SummaryDashboard(
              total: _notes.length,
              scheduled: _scheduledCount,
              onProgress: _onProgressCount,
              completed: _completedCount,
            ),
            const SizedBox(height: 12),
            // ── Search bar ─────────────────────────────────────────
            _SearchBar(onChanged: (v) => setState(() => _searchQuery = v)),
            const SizedBox(height: 12),
            // ── Content ───────────────────────────────────────────
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
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'Daftar Catatan (${filtered.length})',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, i) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final note = filtered[index];
                  return _NoteCard(
                    note: note,
                    onTap: () => _showDetail(context, note),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Catatan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, MaintenanceNote note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NoteDetailSheet(
        note: note,
        onEdit: () {
          Navigator.of(context).pop();
          _showFormSheet(note);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _deleteNote(note);
        },
      ),
    );
  }
}

// ── Summary Dashboard ─────────────────────────────────────────────────────────

class _SummaryDashboard extends StatelessWidget {
  const _SummaryDashboard({
    required this.total,
    required this.scheduled,
    required this.onProgress,
    required this.completed,
  });

  final int total;
  final int scheduled;
  final int onProgress;
  final int completed;

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
            'Ringkasan Catatan',
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
                  icon: Icons.notes_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'Scheduled',
                  value: '$scheduled',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'On Progress',
                  value: '$onProgress',
                  icon: Icons.autorenew_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _MetricItem(
                  label: 'Selesai',
                  value: '$completed',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16A34A),
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

// ── Search Bar ────────────────────────────────────────────────────────────────

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
          hintText: 'Cari judul, deskripsi, atau status...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Note Status Helper ────────────────────────────────────────────────────────

class _NoteStatus {
  const _NoteStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  static _NoteStatus from(String status) {
    return switch (status) {
      'on_progress' => const _NoteStatus(
        label: 'On Progress',
        color: Color(0xFFD97706),
        icon: Icons.autorenew_rounded,
      ),
      'completed' => const _NoteStatus(
        label: 'Completed',
        color: Color(0xFF16A34A),
        icon: Icons.check_circle_outline_rounded,
      ),
      _ => const _NoteStatus(
        label: 'Scheduled',
        color: Color(0xFF2563EB),
        icon: Icons.schedule_rounded,
      ),
    };
  }
}

// ── Note Card ─────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final MaintenanceNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _NoteStatus.from(note.status);

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
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    height: 52,
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
                                note.judul,
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
                        const SizedBox(height: 5),
                        Text(
                          note.deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        if (note.fungsi.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: note.fungsi.map((f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD8B4FE), width: 0.5),
                              ),
                              child: Text(
                                f,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note.createdAt,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (note.attachmentCount > 0) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${note.attachmentCount} lampiran',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
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
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _NoteStatus status;

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

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _NoteDetailSheet extends StatelessWidget {
  const _NoteDetailSheet({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final MaintenanceNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = _NoteStatus.from(note.status);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.90,
      minChildSize: 0.35,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    // Header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.judul,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: status),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF2563EB),
                            size: 18,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(34, 34),
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF2F2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(34, 34),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            note.staff.isEmpty ? '-' : note.staff,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.createdAt,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _SectionLabel('Deskripsi'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        note.deskripsi.isEmpty ? '-' : note.deskripsi,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
                      ),
                    ),
                    if (note.attachments.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SectionLabel('Lampiran (${note.attachmentCount})'),
                      const SizedBox(height: 8),
                      ...note.attachments.map(
                        (att) => _AttachmentRow(attachment: att),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment});

  final MaintenanceNoteAttachment attachment;

  void _openAttachment(BuildContext context) async {
    final fullUrl = attachment.url.startsWith('http')
        ? attachment.url
        : '${ApiServices.instance.baseUrl}${attachment.url}';

    if (attachment.isImage) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.black.withValues(alpha: 0.9)),
              ),
              InteractiveViewer(
                child: Image.network(
                  fullUrl,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Gagal memuat gambar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      try {
        final uri = Uri.parse(fullUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $fullUrl';
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka berkas: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openAttachment(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: attachment.isImage
                      ? const Color(0xFFEDE9FE)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  attachment.isImage
                      ? Icons.image_outlined
                      : Icons.insert_drive_file_outlined,
                  size: 16,
                  color: attachment.isImage
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error & Empty States ──────────────────────────────────────────────────────

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
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.build_circle_outlined,
                color: Color(0xFF7C3AED),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Maintenance Notes',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Catatan pemeliharaan sistem akan\nmuncul di sini setelah ditambahkan.',
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

// ── Form Bottom Sheet ─────────────────────────────────────────────────────────

class _NoteFormSheet extends StatefulWidget {
  const _NoteFormSheet({this.note, required this.onSaved});

  final MaintenanceNote? note;
  final VoidCallback onSaved;

  @override
  State<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends State<_NoteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulCtrl;
  late final TextEditingController _deskripsiCtrl;
  String _status = 'scheduled';
  bool _saving = false;
  final List<String> _selectedFiles = [];
  List<String> _availableFungsi = [];
  List<String> _selectedFungsi = [];
  bool _loadingFungsi = false;

  bool get _isEditing => widget.note != null;

  static const _statusOptions = [
    ('scheduled', 'Scheduled'),
    ('on_progress', 'On Progress'),
    ('completed', 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _judulCtrl = TextEditingController(text: widget.note?.judul ?? '');
    _deskripsiCtrl = TextEditingController(text: widget.note?.deskripsi ?? '');
    _status = widget.note?.status ?? 'scheduled';
    _selectedFungsi = List<String>.from(widget.note?.fungsi ?? []);
    _fetchICFunctions();
  }

  Future<void> _fetchICFunctions() async {
    setState(() => _loadingFungsi = true);
    try {
      _availableFungsi = await ApiServices.instance.fetchICFunctions();
    } catch (e) {
      debugPrint('Failed to fetch IC functions: $e');
    }
    if (mounted) setState(() => _loadingFungsi = false);
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final picker = ImagePicker();

    // Show source chooser bottom sheet
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text(
                  'Pilih gambar dari galeri perangkat',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF0284C7),
                  ),
                ),
                title: const Text(
                  'Ambil Foto',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text(
                  'Gunakan kamera untuk mengambil foto',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await picker.pickMultiImage(
          imageQuality: 85,
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(
              images
                  .map((f) => f.path)
                  .where((p) => !_selectedFiles.contains(p)),
            );
          });
        }
      } else {
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (image != null && !_selectedFiles.contains(image.path)) {
          setState(() => _selectedFiles.add(image.path));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await ApiServices.instance.updateMaintenanceNote(
          widget.note!.id,
          judul: _judulCtrl.text.trim(),
          deskripsi: _deskripsiCtrl.text.trim(),
          status: _status,
          fungsi: _selectedFungsi,
          filePaths: _selectedFiles,
        );
      } else {
        await ApiServices.instance.createMaintenanceNote(
          judul: _judulCtrl.text.trim(),
          deskripsi: _deskripsiCtrl.text.trim(),
          status: _status,
          fungsi: _selectedFungsi,
          filePaths: _selectedFiles,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved();
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('Error submit note: $e');
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan catatan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit Catatan' : 'Tambah Catatan Baru',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _ReadOnlyStaffField(
                name: AppSession.userName.trim().isEmpty
                    ? 'User'
                    : AppSession.userName.trim(),
              ),
              const SizedBox(height: 14),
              // Judul
              _buildLabel('Judul'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _judulCtrl,
                decoration: _inputDecoration('Masukkan judul catatan'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              // Deskripsi
              _buildLabel('Deskripsi'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                decoration: _inputDecoration('Masukkan deskripsi'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              // Status
              _buildLabel('Status'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    isExpanded: true,
                    items: _statusOptions.map((e) {
                      return DropdownMenuItem(
                        value: e.$1,
                        child: Text(
                          e.$2,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Fungsi / Feature IC
              _buildLabel('Fungsi Terkait (IC)'),
              const SizedBox(height: 6),
              _loadingFungsi
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)),
                        ),
                      ),
                    )
                  : _availableFungsi.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Tidak ada fungsi IC yang ditemukan.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _availableFungsi.map((f) {
                            final selected = _selectedFungsi.contains(f);
                            return FilterChip(
                              label: Text(f, style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : const Color(0xFF475569),
                              )),
                              selected: selected,
                              selectedColor: const Color(0xFF7C3AED),
                              backgroundColor: const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: selected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedFungsi.add(f);
                                  } else {
                                    _selectedFungsi.remove(f);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 14),
              // Upload Files Section
              _buildLabel('Lampiran Gambar'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickFiles,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFF7C3AED),
                        size: 24,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tambah Foto dari Galeri / Kamera',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final path = _selectedFiles[index];
                    final name = path.split('/').last;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            color: Color(0xFF64748B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeFile(index),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 22),
              // Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Simpan Perubahan' : 'Tambah Catatan',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF475569),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
    );
  }
}

class _ReadOnlyStaffField extends StatelessWidget {
  const _ReadOnlyStaffField({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: name,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Staff',
        hintText: 'Nama akun login',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}
