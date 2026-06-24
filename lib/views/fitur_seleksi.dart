import 'package:flutter/material.dart';

import '../services/app_session.dart';
import 'environment_monitoring_page.dart';
import 'implementation_log_page.dart';
import 'maintenance_notes_page.dart';
import 'model_transaction_logging_page.dart';
import 'performance_monitoring_page.dart';
import 'profil_page.dart';
import 'project_seleksi.dart';
import 'halaman_awal.dart';
class FiturSeleksiPage extends StatefulWidget {
  const FiturSeleksiPage({super.key});

  static const routeName = '/fitur-seleksi';

  @override
  State<FiturSeleksiPage> createState() => _FiturSeleksiPageState();
}

class _FiturSeleksiPageState extends State<FiturSeleksiPage> {
  static final Map<String, _ProjectStatus> _projectStatusById = {};

  @override
  Widget build(BuildContext context) {
    final routeData = ModalRoute.of(context)?.settings.arguments;
    final project = routeData is Map
        ? routeData.cast<String, String>()
        : const <String, String>{
            'id': 'SIP-001',
            'name': 'Smart Campus Monitoring',
          };
    final notificationFingerprint =
        (project['notificationFingerprint'] ?? '').trim().isNotEmpty
        ? (project['notificationFingerprint'] ?? '').trim()
        : AppSession.activeProjectNotificationFingerprint.trim();
    final notificationMessage =
        (project['notificationMessage'] ?? '').trim().isNotEmpty
        ? (project['notificationMessage'] ?? '').trim()
        : AppSession.activeProjectNotificationMessage.trim();
    final hasNotification =
        notificationFingerprint.isNotEmpty &&
        !AppSession.seenProjectNotificationFingerprints.contains(
          notificationFingerprint,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FB),
      drawer: _MenuNavigationDrawer(project: project),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Builder(
                builder: (headerContext) {
                  return _MenuHeader(
                    projectName: project['name'] ?? '',
                    hasNotification: hasNotification,
                    notificationMessage: notificationMessage,
                    onMenuTap: () => Scaffold.of(headerContext).openDrawer(),
                    onNotificationTap: () {
                      AppSession.seenProjectNotificationFingerprints.add(
                        notificationFingerprint,
                      );
                      setState(() {});
                      ScaffoldMessenger.of(headerContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            notificationMessage.isEmpty
                                ? 'Ada data baru dari refining project.'
                                : notificationMessage,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              sliver: SliverToBoxAdapter(
                child: _ProjectStatusCard(
                  projectName: project['name'] ?? 'Tidak ada',
                  status:
                      _projectStatusById[project['id']] ??
                      _ProjectStatus.belumSelesai,
                  onStatusChanged: (status) {
                    setState(() {
                      _projectStatusById[project['id'] ?? '-'] = status;
                    });
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
              sliver: SliverToBoxAdapter(
                child: Container(
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
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _features.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      itemBuilder: (context, index) {
                        final feature = _features[index];
                        return _FeatureListItem(feature: feature);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProjectStatus {
  belumSelesai,
  maintenance,
  selesai;

  String get label {
    return switch (this) {
      _ProjectStatus.belumSelesai => 'Belum Selesai',
      _ProjectStatus.maintenance => 'Maintenance',
      _ProjectStatus.selesai => 'Selesai',
    };
  }

  Color get color {
    return switch (this) {
      _ProjectStatus.belumSelesai => const Color(0xFF2563EB),
      _ProjectStatus.maintenance => const Color(0xFFD97706),
      _ProjectStatus.selesai => const Color(0xFF16A34A),
    };
  }
}

class _ProjectStatusCard extends StatelessWidget {
  const _ProjectStatusCard({
    required this.projectName,
    required this.status,
    required this.onStatusChanged,
  });

  final String projectName;
  final _ProjectStatus status;
  final ValueChanged<_ProjectStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDBE3F0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1E293B),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Project',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      projectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ProjectStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _ProjectStatus.values.map((item) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == _ProjectStatus.values.last ? 0 : 8,
                  ),
                  child: _StatusOptionButton(
                    status: item,
                    active: item == status,
                    onTap: () => onStatusChanged(item),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProjectStatusChip extends StatelessWidget {
  const _ProjectStatusChip({required this.status});

  final _ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusOptionButton extends StatelessWidget {
  const _StatusOptionButton({
    required this.status,
    required this.active,
    required this.onTap,
  });

  final _ProjectStatus status;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? Colors.white : const Color(0xFF475569),
        backgroundColor: active ? status.color : Colors.white,
        side: BorderSide(
          color: active ? status.color : const Color(0xFFCBD5E1),
        ),
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
      child: Text(status.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.projectName,
    required this.hasNotification,
    required this.notificationMessage,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  final String projectName;
  final bool hasNotification;
  final String notificationMessage;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const SizedBox(width: 6),
          Expanded(child: _BrandBlock(projectName: projectName)),
          const SizedBox(width: 6),
          if (hasNotification) ...[
            _NotificationBell(
              message: notificationMessage,
              onTap: onNotificationTap,
            ),
            const SizedBox(width: 8),
          ],
          const _UserBox(),
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.message, required this.onTap});

  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message.isEmpty
          ? 'Ada data baru dari refining project'
          : message,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onTap,
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFB45309),
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFEF3C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                border: Border.all(color: Colors.white, width: 1.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    final subtitle = projectName.trim().isEmpty
        ? 'System Implementation Platform'
        : projectName.trim();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          child: const Icon(Icons.home_outlined, color: Colors.white, size: 23),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Monitoring',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserBox extends StatelessWidget {
  const _UserBox();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).pushNamed(ProfilPage.routeName),
      icon: const Icon(
        Icons.account_circle_outlined,
        color: Color(0xFF1E293B),
        size: 22,
      ),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFEFF6FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _MenuNavigationDrawer extends StatelessWidget {
  const _MenuNavigationDrawer({required this.project});

  final Map<String, String> project;

  String get _projectName {
    final routeName = (project['name'] ?? '').trim();
    if (routeName.isNotEmpty) return routeName;
    final sessionName = AppSession.activeProjectName.trim();
    if (sessionName.isNotEmpty) return sessionName;
    return 'Belum ada project';
  }

  String get _projectId {
    final routeId = (project['id'] ?? '').trim();
    if (routeId.isNotEmpty) return routeId;
    final sessionId = AppSession.activeProjectId.trim();
    if (sessionId.isNotEmpty) return sessionId;
    return '-';
  }

  void _openRoute(
    BuildContext context,
    String routeName, {
    bool replace = false,
  }) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (replace) {
      navigator.pushReplacementNamed(routeName);
    } else {
      navigator.pushNamed(routeName);
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
              onTap: () => _openRoute(
                context,
                ProjectSeleksiPage.routeName,
                replace: true,
              ),
            ),
            _DrawerNavItem(
              icon: Icons.home_outlined,
              title: 'Menu Dashboard',
              active: true,
              onTap: () => Navigator.of(context).pop(),
            ),
            _DrawerNavItem(
              icon: Icons.description_outlined,
              title: 'Implementation Log',
              onTap: () => _openRoute(context, ImplementationLogPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.article_outlined,
              title: 'Model Transaction Log',
              onTap: () =>
                  _openRoute(context, ModelTransactionLoggingPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.public_outlined,
              title: 'Environment Monitoring',
              onTap: () =>
                  _openRoute(context, EnvironmentMonitoringPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.assignment_outlined,
              title: 'Maintenance Notes',
              onTap: () => _openRoute(context, MaintenanceNotesPage.routeName),
            ),
            _DrawerNavItem(
              icon: Icons.trending_up,
              title: 'Performance Monitoring',
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
            _DrawerNavItem(
              icon: Icons.info_outline,
              title: 'Tentang Kami',
              onTap: () {
                Navigator.of(context).pop(); // Tutup drawer
                showAboutSheet(context);
              },
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
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final foreground = active
        ? const Color(0xFF2563EB)
        : const Color(0xFF334155);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
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

class _FeatureListItem extends StatelessWidget {
  const _FeatureListItem({required this.feature});

  final _FeatureItem feature;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (feature.title == 'Environment Monitoring') {
            Navigator.of(
              context,
            ).pushNamed(EnvironmentMonitoringPage.routeName);
            return;
          }
          if (feature.title == 'Implementation Log') {
            Navigator.of(context).pushNamed(ImplementationLogPage.routeName);
            return;
          }
          if (feature.title == 'Maintenance Notes') {
            Navigator.of(context).pushNamed(MaintenanceNotesPage.routeName);
            return;
          }
          if (feature.title == 'Model Transaction Logging') {
            Navigator.of(
              context,
            ).pushNamed(ModelTransactionLoggingPage.routeName);
            return;
          }
          if (feature.title == 'Performance Monitoring') {
            Navigator.of(
              context,
            ).pushNamed(PerformanceMonitoringPage.routeName);
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${feature.title} dipilih')));
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12, left: 2, right: 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(
                  feature.icon,
                  color: feature.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      feature.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

const _features = [
  _FeatureItem(
    title: 'Implementation Log',
    description: 'Merekam aktivitas implementasi sistem cerdas',
    icon: Icons.description_outlined,
    color: Color(0xFF2563EB), // Blue
  ),
  _FeatureItem(
    title: 'Model Transaction Logging',
    description:
        'Merekam data transaksi model baik fitur input maupun label output',
    icon: Icons.article_outlined,
    color: Color(0xFF7C3AED), // Purple
  ),
  _FeatureItem(
    title: 'Environment Monitoring',
    description:
        'Merekam data lingkungan yang relevan dengan konteks implementasi sistem cerdas',
    icon: Icons.public_outlined,
    color: Color(0xFF059669), // Emerald/Green
  ),
  _FeatureItem(
    title: 'Maintenance Notes',
    description: 'Merekam masukan catatan dari pemelihara sistem cerdas',
    icon: Icons.assignment_outlined,
    color: Color(0xFFF59E0B), // Amber/Yellow
  ),
  _FeatureItem(
    title: 'Performance Monitoring',
    description: 'Memantau kinerja sistem cerdas terpasang',
    icon: Icons.trending_up,
    color: Color(0xFFDC2626), // Red
  ),
];
