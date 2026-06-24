import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/app_session.dart';
import 'login_dan_buat_akun_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  static const routeName = '/profil';

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final profile = await ApiServices.instance.fetchProfile();
      _applyProfile(profile);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Gagal memuat profil dari server.');
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  void _applyProfile(ProfileResult profile) {
    AppSession.userName = profile.name;
    AppSession.userEmail = profile.email;
    AppSession.profilePictureUrl = profile.profilePictureUrl;
    AppSession.activeProjectId = profile.activeProjectId;
    AppSession.activeProjectName = profile.activeProjectName;
  }

  Future<void> _openNameEditor() async {
    final controller = TextEditingController(text: AppSession.userName);
    await _openEditorSheet(
      title: 'Ganti Nama',
      description: 'Perbarui nama yang ditampilkan di akun Anda.',
      fields: [
        _EditorFieldData(
          label: 'Nama lengkap',
          hint: 'Masukkan nama lengkap',
          controller: controller,
        ),
      ],
      onSave: () async {
        final value = controller.text.trim();
        if (value.isEmpty) {
          return 'Nama tidak boleh kosong.';
        }
        try {
          final profile = await ApiServices.instance.updateProfileName(value);
          if (!mounted) {
            return 'Halaman profil sudah ditutup.';
          }
          setState(() => _applyProfile(profile));
          _showMessage('Nama berhasil diperbarui.');
          return null; // success
        } on ApiException catch (error) {
          return error.message;
        } catch (_) {
          return 'Gagal memperbarui nama.';
        }
      },
    );
  }

  Future<void> _openEmailEditor() async {
    final controller = TextEditingController(text: AppSession.userEmail);
    await _openEditorSheet(
      title: 'Ganti Email',
      description: 'Perbarui email login yang digunakan pada aplikasi.',
      fields: [
        _EditorFieldData(
          label: 'Email',
          hint: 'nama@email.com',
          keyboardType: TextInputType.emailAddress,
          controller: controller,
        ),
      ],
      onSave: () async {
        final value = controller.text.trim();
        if (value.isEmpty || !value.contains('@')) {
          return 'Email tidak valid.';
        }
        try {
          final profile = await ApiServices.instance.updateProfileEmail(value);
          if (!mounted) {
            return 'Halaman profil sudah ditutup.';
          }
          setState(() => _applyProfile(profile));
          _showMessage('Email berhasil diperbarui.');
          return null; // success
        } on ApiException catch (error) {
          return error.message;
        } catch (_) {
          return 'Gagal memperbarui email.';
        }
      },
    );
  }

  Future<void> _openPasswordEditor() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    var currentStep = 0;
    var saving = false;
    String? localError;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final isSummaryStep = currentStep == 3;

              bool validateStep() {
                if (currentStep == 0 && currentController.text.isEmpty) {
                  setSheetState(() {
                    localError = 'Password saat ini wajib diisi.';
                  });
                  return false;
                }
                if (currentStep == 1 && newController.text.isEmpty) {
                  setSheetState(() {
                    localError = 'Password baru wajib diisi.';
                  });
                  return false;
                }
                if (currentStep == 2) {
                  if (confirmController.text.isEmpty) {
                    setSheetState(() {
                      localError = 'Konfirmasi password wajib diisi.';
                    });
                    return false;
                  }
                  if (newController.text != confirmController.text) {
                    setSheetState(() {
                      localError = 'Konfirmasi password tidak cocok.';
                    });
                    return false;
                  }
                }
                setSheetState(() {
                  localError = null;
                });
                return true;
              }

              Widget stepContent() {
                if (currentStep == 0) {
                  return _EditorField(
                    data: _EditorFieldData(
                      label: 'Password saat ini',
                      hint: 'Masukkan password saat ini',
                      obscureText: true,
                      controller: currentController,
                    ),
                  );
                }
                if (currentStep == 1) {
                  return _EditorField(
                    data: _EditorFieldData(
                      label: 'Password baru',
                      hint: 'Masukkan password baru',
                      obscureText: true,
                      controller: newController,
                    ),
                  );
                }
                if (currentStep == 2) {
                  return _EditorField(
                    data: _EditorFieldData(
                      label: 'Konfirmasi password baru',
                      hint: 'Ulangi password baru',
                      obscureText: true,
                      controller: confirmController,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PasswordSummaryRow(
                      label: 'Password saat ini',
                      value: currentController.text.isEmpty
                          ? 'Belum diisi'
                          : 'Sudah diisi',
                    ),
                    _PasswordSummaryRow(
                      label: 'Password baru',
                      value: newController.text.isEmpty
                          ? 'Belum diisi'
                          : '${newController.text.length} karakter',
                    ),
                    _PasswordSummaryRow(
                      label: 'Konfirmasi',
                      value: newController.text == confirmController.text
                          ? 'Cocok'
                          : 'Tidak cocok',
                    ),
                  ],
                );
              }

              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
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
                          'Ganti Password',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selesaikan setiap langkah secara berurutan.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _PasswordStepIndicator(currentStep: currentStep),
                        const SizedBox(height: 18),
                        stepContent(),
                        if (localError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            localError!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () {
                                          setSheetState(() {
                                            currentStep -= 1;
                                            localError = null;
                                          });
                                        },
                                  child: const Text('Kembali'),
                                ),
                              ),
                            if (currentStep > 0) const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: saving
                                    ? null
                                    : () async {
                                        if (!isSummaryStep) {
                                          if (!validateStep()) {
                                            return;
                                          }
                                          setSheetState(() => currentStep += 1);
                                          return;
                                        }

                                        if (currentController.text.isEmpty ||
                                            newController.text.isEmpty ||
                                            confirmController.text.isEmpty) {
                                          setSheetState(() {
                                            localError = 'Semua kolom password wajib diisi.';
                                          });
                                          return;
                                        }
                                        if (newController.text !=
                                            confirmController.text) {
                                          setSheetState(() {
                                            localError = 'Konfirmasi password tidak cocok.';
                                          });
                                          return;
                                        }

                                        setSheetState(() {
                                          saving = true;
                                          localError = null;
                                        });

                                        String? errorMsg;
                                        try {
                                          await ApiServices.instance
                                              .updateProfilePassword(
                                                currentPassword: currentController.text,
                                                newPassword: newController.text,
                                                confirmPassword: confirmController.text,
                                              );
                                        } on ApiException catch (error) {
                                          errorMsg = error.message;
                                        } catch (_) {
                                          errorMsg = 'Gagal memperbarui password.';
                                        }

                                        if (!sheetContext.mounted) return;

                                        if (errorMsg == null) {
                                          Navigator.of(sheetContext).pop();
                                          Future.microtask(() {
                                            if (mounted) {
                                              _showMessage('Password berhasil diperbarui.');
                                            }
                                          });
                                        } else {
                                          setSheetState(() {
                                            saving = false;
                                            localError = errorMsg;
                                          });
                                        }
                                      },
                                child: saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(isSummaryStep ? 'Simpan' : 'Lanjut'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    }
  }

  Future<void> _openPhotoEditor() async {
    final profilePictureUrl = AppSession.profilePictureUrl.trim();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
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
                  'Ganti Foto Profil',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambil gambar lewat kamera atau upload foto baru dari perangkat Anda.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF172554), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332563EB),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: profilePictureUrl.isNotEmpty
                        ? Image.network(
                            profilePictureUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _ProfileInitial(name: AppSession.userName);
                            },
                          )
                        : _ProfileInitial(name: AppSession.userName),
                  ),
                ),
                const SizedBox(height: 28),
                _PhotoSourceTile(
                  icon: Icons.photo_library_outlined,
                  iconBackground: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF7C3AED),
                  title: 'Pilih dari Galeri',
                  subtitle: 'Upload foto dari perangkat Anda',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                const SizedBox(height: 10),
                _PhotoSourceTile(
                  icon: Icons.camera_alt_outlined,
                  iconBackground: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Ambil Foto',
                  subtitle: 'Gunakan kamera untuk foto profil baru',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );

    if (source == null || !mounted) {
      return;
    }

    await _pickAndUploadProfilePhoto(source);
  }

  Future<void> _pickAndUploadProfilePhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null || !mounted) {
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mengunggah foto...',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final profile = await ApiServices.instance.updateProfilePhoto(image.path);
      if (!mounted) {
        return;
      }
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      setState(() {
        _applyProfile(profile);
      });
      _showMessage('Foto profil berhasil diperbarui.');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      _showMessage('Gagal memperbarui foto profil.');
    }
  }

  Future<void> _openEditorSheet({
    required String title,
    required String description,
    required List<_EditorFieldData> fields,
    required Future<String?> Function() onSave,
  }) async {
    String? localError;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
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
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...fields.map((field) => _EditorField(data: field)),
                      if (localError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          localError!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  setSheetState(() {
                                    saving = true;
                                    localError = null;
                                  });
                                  
                                  final errorMsg = await onSave();
                                  
                                  if (!sheetContext.mounted) {
                                    return;
                                  }
                                  
                                  if (errorMsg == null) {
                                    Navigator.of(sheetContext).pop();
                                  } else {
                                    setSheetState(() {
                                      saving = false;
                                      localError = errorMsg;
                                    });
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _logout() {
    AppSession.clear();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginDanBuatAkunPage.routeName, (route) => false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final name = AppSession.userName.trim().isEmpty
        ? 'User'
        : AppSession.userName.trim();
    final email = AppSession.userEmail.trim().isEmpty
        ? '-'
        : AppSession.userEmail.trim();
    final projectName = AppSession.activeProjectName.trim();
    final projectId = AppSession.activeProjectId.trim();
    final profilePictureUrl = AppSession.profilePictureUrl.trim();
    final projectText = projectName.isNotEmpty
        ? projectName
        : (projectId.isNotEmpty ? projectId : '');

    return Scaffold(
      backgroundColor: const Color(0xFFEDF2FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
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
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      iconSize: 18,
                      color: const Color(0xFF2563EB),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        side: const BorderSide(color: Color(0xFFDBEAFE)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Profil',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF172554),
                        Color(0xFF1E3A8A),
                        Color(0xFF1D4ED8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3D2563EB),
                        blurRadius: 48,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 28,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: profilePictureUrl.isNotEmpty
                                ? Image.network(
                                    profilePictureUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _ProfileInitial(name: name);
                                    },
                                  )
                                : _ProfileInitial(name: name),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Color(0xE6FFFFFF),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (projectText.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: const StadiumBorder(
                              side: BorderSide(color: Color(0x2EFFFFFF)),
                            ),
                          ),
                          child: Text(
                            projectText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _MenuItem(
                    icon: Icons.image_outlined,
                    title: 'Ganti Foto Profil',
                    subtitle: 'Upload atau ambil foto baru',
                    onTap: _openPhotoEditor,
                  ),
                  _MenuItem(
                    icon: Icons.badge_outlined,
                    title: 'Ganti Nama',
                    subtitle: 'Perbarui nama akun',
                    onTap: _openNameEditor,
                  ),
                  _MenuItem(
                    icon: Icons.email_outlined,
                    title: 'Ganti Email',
                    subtitle: 'Ubah email login',
                    onTap: _openEmailEditor,
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Ganti Password',
                    subtitle: 'Amankan akun dengan password baru',
                    onTap: _openPasswordEditor,
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFFF1F2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            if (_loadingProfile)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 26),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
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

class _ProfileInitial extends StatelessWidget {
  const _ProfileInitial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase();
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStepIndicator extends StatelessWidget {
  const _PasswordStepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index == currentStep;
        final isDone = index < currentStep;
        final color = isActive || isDone
            ? const Color(0xFF2563EB)
            : const Color(0xFFCBD5E1);

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive || isDone
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF8FAFC),
                  border: Border.all(color: color),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              if (index < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: isDone
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _PasswordSummaryRow extends StatelessWidget {
  const _PasswordSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorFieldData {
  const _EditorFieldData({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
}

class _EditorField extends StatefulWidget {
  const _EditorField({super.key, required this.data});

  final _EditorFieldData data;

  @override
  State<_EditorField> createState() => _EditorFieldState();
}

class _EditorFieldState extends State<_EditorField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.data.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data.label,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.data.controller,
            keyboardType: widget.data.keyboardType,
            obscureText: _obscureText,
            decoration: InputDecoration(
              hintText: widget.data.hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDBE3F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
              suffixIcon: widget.data.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
