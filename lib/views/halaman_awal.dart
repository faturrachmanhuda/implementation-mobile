import 'package:flutter/material.dart';

import 'login_dan_buat_akun_page.dart';

class HalamanAwal extends StatelessWidget {
  const HalamanAwal({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF172554), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: _InfoButton(onPressed: () => showAboutSheet(context)),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _AppMark(),
                        const SizedBox(height: 24),
                        const Text(
                          'System Implementation Platform',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kelola implementasi, monitoring, dan pemeliharaan sistem cerdas dalam satu aplikasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFDBEAFE),
                            fontSize: 14,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(LoginDanBuatAkunPage.routeName),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1D4ED8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('Login/Daftar'),
                          ),
                        ),
                      ],
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
}

void showAboutSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AboutSheet(),
  );
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Tentang Kami',
      icon: const Icon(Icons.info_outline, color: Colors.white, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        shape: const CircleBorder(),
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: const Icon(Icons.memory_rounded, color: Colors.white, size: 42),
    );
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD8E2F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: const [
                _AboutHeader(),
                SizedBox(height: 14),
                _InfoCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Tentang Aplikasi',
                  body:
                      'System Implementation Platform adalah platform manajemen terpadu untuk membantu proses implementasi, monitoring, dan pemeliharaan sistem cerdas secara lebih terstruktur, efisien, dan mudah dipahami.',
                ),
                SizedBox(height: 12),
                _InfoCard(
                  icon: Icons.visibility_outlined,
                  title: 'Visi',
                  body:
                      'Menjadi platform implementasi sistem cerdas terdepan yang memberdayakan organisasi di seluruh Indonesia untuk mengadopsi teknologi AI secara efisien, transparan, dan berkelanjutan.',
                ),
                SizedBox(height: 12),
                _MissionCard(),
                SizedBox(height: 12),
                _TeamCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.info_outline,
            color: Color(0xFF2563EB),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentang Kami',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Visi, misi, dan tim pengembang aplikasi.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard();

  static const _missions = [
    'Menyederhanakan proses implementasi sistem cerdas dengan alat yang mudah digunakan.',
    'Menyediakan monitoring real-time untuk memastikan keandalan sistem secara konsisten.',
    'Mendukung kolaborasi tim lintas fungsi dalam mengelola siklus hidup AI.',
    'Mendorong inovasi berbasis data melalui analitik yang mendalam dan actionable.',
  ];

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.task_alt_outlined, title: 'Misi'),
          const SizedBox(height: 10),
          ...List.generate(_missions.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _missions.length - 1 ? 0 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _missions[index],
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard();

  static const _members = [
    ('Tubagus Razan Habibie Al Jibran', '064102400034'),
    ('Dimas Alip Priyono', '064102400032'),
    ('Teuku Raziqa', '064102400004'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.groups_outlined,
            title: 'Hubungi Kami',
          ),
          const SizedBox(height: 10),
          ...List.generate(_members.length, (index) {
            final member = _members[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _members.length - 1 ? 0 : 8,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(
                      Icons.person_outline,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.$1,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          member.$2,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.child});

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
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
