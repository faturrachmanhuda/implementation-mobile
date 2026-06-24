import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/project.dart';
import '../services/api_client.dart';
import '../services/app_session.dart';
import 'environment_monitoring_page.dart';
import 'fitur_seleksi.dart';
import 'implementation_log_page.dart';
import 'maintenance_notes_page.dart';
import 'model_transaction_logging_page.dart';
import 'performance_monitoring_page.dart';
import 'profil_page.dart';

class ProjectSeleksiPage extends StatefulWidget {
  const ProjectSeleksiPage({super.key});

  static const routeName = '/project-seleksi';

  @override
  State<ProjectSeleksiPage> createState() => _ProjectSeleksiPageState();
}

class _ProjectSeleksiPageState extends State<ProjectSeleksiPage> {
  final _searchController = TextEditingController();
  List<Project> _projects = const [];
  String _keyword = '';
  String _selectedProjectId = '';
  bool _loading = true;
  String? _errorMessage;

  List<Project> get _filteredProjects {
    final keyword = _keyword.trim().toLowerCase();
    if (keyword.isEmpty) {
      return _projects;
    }

    return _projects.where((project) {
      final searchable = [
        project.id,
        project.name,
        project.description,
        project.createdAt,
      ].join(' ').toLowerCase();
      return searchable.contains(keyword);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final projects = await ApiServices.instance.fetchProjects();
      if (!mounted) {
        return;
      }
      setState(() {
        _projects = projects;
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
        _errorMessage = 'Tidak bisa memuat project dari Django API.';
      });
    }
  }

  Future<void> _refreshProjects() async {
    FocusScope.of(context).unfocus();
    setState(() => _keyword = _searchController.text);
    await _loadProjects();
  }

  Future<void> _selectProject(Project project) async {
    try {
      await ApiServices.instance.selectProject(project);
      if (!mounted) {
        return;
      }
      setState(() => _selectedProjectId = project.id);
      AppSession.activeProjectId = project.id;
      AppSession.activeProjectName = project.name;
      AppSession.activeProjectNotificationFingerprint =
          project.notificationFingerprint;
      AppSession.activeProjectNotificationMessage = project.notificationMessage;
      Navigator.of(context).pushReplacementNamed(
        FiturSeleksiPage.routeName,
        arguments: project.toRouteData(),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak bisa memilih project di Django API.'),
          ),
        );
      }
    }
  }

  Future<void> _openDetailSheet(Project project) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ProjectDetailSheet(project: project);
      },
    );
  }

  Future<void> _openProjectReport(Project project) async {
    final uri = Uri.parse('${ApiServices.instance.baseUrl}/project-report/')
        .replace(
          queryParameters: {
            'project_id': project.id,
            'project_name': project.name,
            'print': '1',
          },
        );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka laporan project.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka laporan project.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = _filteredProjects;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FB),
      drawer: const _ProjectNavigationDrawer(),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FBFF), Color(0xFFEDF2FB)],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Builder(
                  builder: (headerContext) {
                    return _ProjectHeader(
                      onMenuTap: () => Scaffold.of(headerContext).openDrawer(),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProjectToolbar(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _keyword = value),
                        onRefresh: _refreshProjects,
                      ),
                      const SizedBox(height: 14),
                      _SummaryRow(
                        count: projects.length,
                        activeProjectId: _selectedProjectId,
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ProjectLoadingState(),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ProjectErrorState(
                    message: _errorMessage!,
                    onRetry: _loadProjects,
                  ),
                )
              else if (projects.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyProjectState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return _ProjectCard(
                        project: project,
                        active: project.id == _selectedProjectId,
                        onSelect: () => _selectProject(project),
                        onDetail: () => _openDetailSheet(project),
                        onPrint: () => _openProjectReport(project),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: projects.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDBE3F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x141E293B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.menu_rounded,
            tooltip: 'Buka menu navigasi',
            onPressed: onMenuTap,
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332563EB),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.folder_open_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Project',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'System Implementation Platform',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(ProfilPage.routeName),
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: const Color(0xFF1E293B), size: 22),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF8FAFC),
        fixedSize: const Size(38, 38),
        minimumSize: const Size(38, 38),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: Color(0xFFDBE3F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ProjectNavigationDrawer extends StatelessWidget {
  const _ProjectNavigationDrawer();

  bool get _hasActiveProject => AppSession.activeProjectId.trim().isNotEmpty;

  String get _projectName {
    final name = AppSession.activeProjectName.trim();
    if (name.isNotEmpty) return name;
    final id = AppSession.activeProjectId.trim();
    if (id.isNotEmpty) return id;
    return 'Belum ada project aktif';
  }

  String get _projectId {
    final id = AppSession.activeProjectId.trim();
    return id.isEmpty ? '-' : id;
  }

  Map<String, String> get _activeProjectRouteData => {
    'id': AppSession.activeProjectId,
    'name': AppSession.activeProjectName,
    'notificationFingerprint': AppSession.activeProjectNotificationFingerprint,
    'notificationMessage': AppSession.activeProjectNotificationMessage,
  };

  void _openRoute(
    BuildContext context,
    String routeName, {
    bool replace = false,
    Object? arguments,
  }) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (replace) {
      navigator.pushReplacementNamed(routeName, arguments: arguments);
    } else {
      navigator.pushNamed(routeName, arguments: arguments);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const _DrawerHeader(),
            const SizedBox(height: 16),
            _DrawerProfileCard(
              name: AppSession.userName,
              email: AppSession.userEmail,
            ),
            const SizedBox(height: 12),
            _DrawerProjectCard(
              projectId: _projectId,
              projectName: _projectName,
            ),
            const SizedBox(height: 20),
            const _DrawerSectionLabel('Menu Utama'),
            _DrawerNavItem(
              icon: Icons.folder_open_outlined,
              title: 'Pilih Project',
              active: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerNavItem(
              icon: Icons.home_outlined,
              title: 'Menu Dashboard',
              enabled: _hasActiveProject,
              onTap: () => _openRoute(
                context,
                FiturSeleksiPage.routeName,
                replace: true,
                arguments: _activeProjectRouteData,
              ),
            ),
            _DrawerNavItem(
              icon: Icons.description_outlined,
              title: 'Implementation Log',
              enabled: _hasActiveProject,
              onTap: () => _openRoute(context, ImplementationLogPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.article_outlined,
              title: 'Model Transaction Log',
              enabled: _hasActiveProject,
              onTap: () =>
                  _openRoute(context, ModelTransactionLoggingPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.public_outlined,
              title: 'Environment Monitoring',
              enabled: _hasActiveProject,
              onTap: () =>
                  _openRoute(context, EnvironmentMonitoringPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.assignment_outlined,
              title: 'Maintenance Notes',
              enabled: _hasActiveProject,
              onTap: () => _openRoute(context, MaintenanceNotesPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.trending_up,
              title: 'Performance Monitoring',
              enabled: _hasActiveProject,
              onTap: () =>
                  _openRoute(context, PerformanceMonitoringPage.routeName),
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 14),
            const _DrawerSectionLabel('Sistem'),
            _DrawerNavItem(
              icon: Icons.account_circle_outlined,
              title: 'Profile Akun',
              onTap: () => _openRoute(context, ProfilPage.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.description_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Implementation',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Platform Monitoring',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Tutup menu navigasi',
          icon: const Icon(Icons.close_rounded, size: 21),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF334155),
            fixedSize: const Size(36, 36),
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerProfileCard extends StatelessWidget {
  const _DrawerProfileCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'User' : name.trim();
    final displayEmail = email.trim().isEmpty ? '-' : email.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Text(
              displayName.characters.first.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
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

class _DrawerProjectCard extends StatelessWidget {
  const _DrawerProjectCard({
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Terpilih',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            projectName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            projectId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = !enabled
        ? const Color(0xFFCBD5E1)
        : active
        ? const Color(0xFF2563EB)
        : const Color(0xFF334155);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: active && enabled ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectToolbar extends StatelessWidget {
  const _ProjectToolbar({
    required this.controller,
    required this.onChanged,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari project...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDBE3F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: onRefresh,
            tooltip: 'Refresh daftar project',
            icon: const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFEFF6FF),
              fixedSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.count, required this.activeProjectId});

  final int count;
  final String activeProjectId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Menampilkan $count project',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (activeProjectId.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const ShapeDecoration(
              color: Color(0xFFF0FDF4),
              shape: StadiumBorder(side: BorderSide(color: Color(0xFFBBF7D0))),
            ),
            child: Text(
              'Project aktif: $activeProjectId',
              style: const TextStyle(
                color: Color(0xFF166534),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.active,
    required this.onSelect,
    required this.onDetail,
    required this.onPrint,
  });

  final Project project;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onDetail;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onSelect,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? const Color(0xFF86EFAC) : const Color(0xFFDBE3F0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x142563EB),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (active) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x2422C55E),
                            blurRadius: 8,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  _ProjectIdChip(id: project.id, active: active),
                  const Spacer(),
                  IconButton(
                    onPressed: onDetail,
                    tooltip: 'Lihat detail project',
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      backgroundColor: Colors.white,
                      fixedSize: const Size(38, 38),
                      minimumSize: const Size(38, 38),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onPrint,
                    tooltip: 'Cetak laporan semua data project',
                    icon: const Icon(Icons.local_print_shop_outlined, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      backgroundColor: Colors.white,
                      fixedSize: const Size(38, 38),
                      minimumSize: const Size(38, 38),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                project.name,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF94A3B8),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    project.createdAt,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
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

class _ProjectIdChip extends StatelessWidget {
  const _ProjectIdChip({required this.id, required this.active});

  final String id;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Text(
        id,
        style: TextStyle(
          color: active ? const Color(0xFF166534) : const Color(0xFF1D4ED8),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ProjectDetailSheet extends StatelessWidget {
  const _ProjectDetailSheet({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFDBE3F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E0F172A),
              blurRadius: 68,
              offset: Offset(0, 28),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: const ShapeDecoration(
                color: Color(0xFFE2E8F0),
                shape: StadiumBorder(),
              ),
            ),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                color: Color(0xFF2563EB),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Detail Project',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informasi lengkap project yang dipilih.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetInfo(label: 'ID Project', value: project.id),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _SheetInfo(label: 'Nama Project', value: project.name),
                  const Divider(color: Color(0xFFE2E8F0), height: 20),
                  _SheetInfo(
                    label: 'Deskripsi',
                    value: project.description,
                    regular: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetInfo extends StatelessWidget {
  const _SheetInfo({
    required this.label,
    required this.value,
    this.regular = false,
  });

  final String label;
  final String value;
  final bool regular;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontSize: regular ? 13 : 15,
            fontWeight: regular ? FontWeight.w600 : FontWeight.w900,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ProjectLoadingState extends StatelessWidget {
  const _ProjectLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF2563EB),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat daftar project...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectErrorState extends StatelessWidget {
  const _ProjectErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFEA580C),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat project',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjectState extends StatelessWidget {
  const _EmptyProjectState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Icon(
                Icons.folder_off_outlined,
                color: Color(0xFF2563EB),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada project ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba ubah kata kunci pencarian Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
