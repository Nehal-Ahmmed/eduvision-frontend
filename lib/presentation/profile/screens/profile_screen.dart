import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../theme/app_constants.dart';
import '../models/profile_models.dart';
import '../provider/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientMiddle,
            AppColors.gradientEnd,
          ],
        ),
      ),
      child: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    // Premium Header Card
                    _buildPremiumHeader(profile),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // TabBar selection
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.indigo600,
                        unselectedLabelColor: AppColors.gray500,
                        indicatorColor: AppColors.indigo600,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(icon: Icon(Icons.person), text: 'Personal & Socials'),
                          Tab(icon: Icon(Icons.school), text: 'Academic Status'),
                          Tab(icon: Icon(Icons.analytics), text: 'CGPA Dashboard'),
                          Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // TabBarView Content
                    SizedBox(
                      height: 720,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPersonalAndSocialsTab(profile),
                          _buildAcademicStatusTab(profile),
                          _buildCgpaDashboardTab(profile),
                          _buildAchievementsTab(profile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Header UI
  Widget _buildPremiumHeader(ProfileDto profile) {
    String name = profile.fullName ?? 'Set your name';
    String studentId = profile.studentId ?? 'Set Student ID';
    String dept = profile.departmentName ?? 'Department';
    String university = profile.universityName ?? 'University';
    String rawImageUrl = profile.profileImageUrl ?? '';
    
    String finalImageUrl = rawImageUrl.isEmpty
        ? 'https://ui-avatars.com/api/?name=${profile.fullName ?? "User"}&background=4F46E5&color=fff&size=128'
        : (rawImageUrl.startsWith('http')
              ? rawImageUrl
              : '${AppConfig.apiBaseUrl}$rawImageUrl');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo800, AppColors.blue700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo900.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        children: [
          // Avatar with hover action
          GestureDetector(
            onTap: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final bytes = await image.readAsBytes();
                ref.read(profileProvider.notifier).uploadProfileImage(bytes, image.name);
              }
            },
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 4),
                    image: DecorationImage(
                      image: NetworkImage(finalImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.indigo600, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          // Info Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                      onPressed: () => _showEditBasicInfoDialog(profile),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  university,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _buildHeaderBadge(dept, Icons.school),
                    const SizedBox(width: AppSpacing.sm),
                    _buildHeaderBadge(studentId, Icons.badge),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper Card Builder
  Widget _buildTabCard({required String title, required IconData icon, required List<Widget> children, VoidCallback? onEdit}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.indigo600, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.indigo600, size: 20),
                  onPressed: onEdit,
                ),
            ],
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.gray200),
          ...children,
        ],
      ),
    );
  }

  // 1. Personal & Socials Tab
  Widget _buildPersonalAndSocialsTab(ProfileDto profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Details
        Expanded(
          flex: 3,
          child: _buildTabCard(
            title: 'Personal Details',
            icon: Icons.person_outline,
            onEdit: () => _showEditPersonalDialog(profile),
            children: [
              _buildDetailItem(Icons.phone, 'Phone Number', profile.phone ?? 'Not specified'),
              _buildDetailItem(Icons.cake, 'Date of Birth', profile.birthday ?? 'Not specified'),
              _buildDetailItem(Icons.wc, 'Gender', profile.gender ?? 'Not specified'),
              _buildDetailItem(Icons.location_on, 'Permanent Address', profile.address ?? 'Not specified'),
              _buildDetailItem(Icons.alternate_email, 'Additional Contact Info', profile.contactInformation ?? 'Not specified'),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Social Media Links
        Expanded(
          flex: 2,
          child: _buildTabCard(
            title: 'Social & Web Links',
            icon: Icons.public,
            onEdit: () => _showEditSocialsDialog(profile),
            children: [
              _buildSocialRow(Icons.code, 'GitHub', profile.githubUrl),
              _buildSocialRow(Icons.link, 'LinkedIn', profile.linkedinUrl),
              _buildSocialRow(Icons.language, 'Portfolio Website', profile.websiteUrl),
              _buildSocialRow(Icons.facebook, 'Facebook', profile.facebookUrl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gray400, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray900),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSocialRow(IconData icon, String label, String? url) {
    final bool hasUrl = url != null && url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: hasUrl ? () => _launchURL(url) : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: hasUrl ? AppColors.indigo50.withOpacity(0.4) : AppColors.gray50,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: hasUrl ? AppColors.indigo200 : AppColors.gray200),
          ),
          child: Row(
            children: [
              Icon(icon, color: hasUrl ? AppColors.indigo600 : AppColors.gray400, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, color: hasUrl ? AppColors.indigo800 : AppColors.gray500, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      hasUrl ? url : 'Link not set',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUrl ? AppColors.indigo900 : AppColors.gray400,
                        decoration: hasUrl ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUrl) const Icon(Icons.open_in_new, size: 14, color: AppColors.indigo600),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  // 2. Academic Status Tab
  Widget _buildAcademicStatusTab(ProfileDto profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enrollment Details
        Expanded(
          child: _buildTabCard(
            title: 'Academic Status',
            icon: Icons.history_edu,
            onEdit: () => _showEditAcademicDialog(profile),
            children: [
              _buildDetailItem(Icons.apartment, 'University Name', profile.universityName ?? 'Not specified'),
              _buildDetailItem(Icons.category, 'Department', profile.departmentName ?? 'Not specified'),
              _buildDetailItem(Icons.calendar_today, 'Batch', profile.batch ?? 'Not specified'),
              _buildDetailItem(Icons.timelapse, 'Semester / Term', profile.semester ?? 'Not specified'),
              _buildDetailItem(Icons.grid_view, 'Section', profile.section ?? 'Not specified'),
              _buildDetailItem(Icons.auto_awesome_motion, 'Academic Year', profile.academicYear ?? 'Not specified'),
            ],
          ),
        ),
      ],
    );
  }

  // 3. CGPA Dashboard & Simulator Tab
  Widget _buildCgpaDashboardTab(ProfileDto profile) {
    final results = profile.academicResults;
    double? currentCgpa;
    
    // Parse GPAs to compute overall cumulative CGPA
    final validGpas = results
        .map((e) {
          if (e.gpa == null) return null;
          final val = e.gpa!.split('/').first.trim();
          return double.tryParse(val);
        })
        .whereType<double>()
        .toList();

    if (validGpas.isNotEmpty) {
      currentCgpa = validGpas.reduce((a, b) => a + b) / validGpas.length;
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CGPA Summary gauge
              Expanded(
                flex: 2,
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Cumulative CGPA',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray500),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: (currentCgpa ?? 0.0) / 4.0,
                              strokeWidth: 12,
                              color: AppColors.indigo600,
                              backgroundColor: AppColors.gray100,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentCgpa != null ? currentCgpa.toStringAsFixed(2) : '0.00',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.gray900),
                              ),
                              const Text('Scale: 4.00', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Calculated from ${validGpas.length} semesters',
                        style: const TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // SGPA Trend Bar Chart
              Expanded(
                flex: 3,
                child: Container(
                  height: 320,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Semester GPA History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                          IconButton(
                            icon: const Icon(Icons.add, color: AppColors.indigo600, size: 20),
                            onPressed: () => _showAddAcademicResultDialog(profile),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.md),
                      Expanded(
                        child: results.isEmpty
                            ? const Center(child: Text('No semester records added yet.', style: TextStyle(color: AppColors.gray400)))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: results.map((res) {
                                  final double val = double.tryParse(res.gpa?.split('/').first.trim() ?? '0.0') ?? 0.0;
                                  final double pctHeight = (val / 4.0) * 160;
                                  return Tooltip(
                                    message: 'GPA: ${res.gpa}',
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          val.toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.indigo600),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 32,
                                          height: pctHeight.clamp(10, 160),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [AppColors.indigo600, AppColors.indigo400],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'L${res.level ?? ""}T${res.term ?? ""}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gray600),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Interactive Simulator
          CgpaSimulatorWidget(initialCgpa: currentCgpa ?? 0.0, initialSemesters: validGpas.length),
        ],
      ),
    );
  }

  // 4. Achievements & Portfolio Tab
  Widget _buildAchievementsTab(ProfileDto profile) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.indigo600,
        label: const Text('Add Achievement', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddAchievementDialog(profile),
      ),
      body: profile.achievements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.emoji_events_outlined, size: 64, color: AppColors.gray400),
                  SizedBox(height: 12),
                  Text('No achievements listed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray500)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
                childAspectRatio: 1.45,
              ),
              itemCount: profile.achievements.length,
              itemBuilder: (context, index) {
                final ach = profile.achievements[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.military_tech, color: Colors.orange, size: 28),
                          // Certificate image or upload button
                          ach.certificateImageUrl != null && ach.certificateImageUrl!.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => _showZoomableImageDialog(ach.certificateImageUrl!),
                                  child: Container(
                                    width: 50,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.gray400),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          ach.certificateImageUrl!.startsWith('http')
                                              ? ach.certificateImageUrl!
                                              : '${AppConfig.apiBaseUrl}${ach.certificateImageUrl}',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                )
                              : TextButton.icon(
                                  icon: const Icon(Icons.upload_file, size: 14),
                                  label: const Text('Add Certificate', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _pickAndUploadCertificate(index),
                                ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        ach.title ?? 'Achievement Name',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          ach.description ?? 'No description provided.',
                          style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _pickAndUploadCertificate(int achievementIndex) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      ref.read(profileProvider.notifier).uploadCertificateImage(achievementIndex, bytes, file.name);
    }
  }

  void _showZoomableImageDialog(String imageUrl) {
    final fullUrl = imageUrl.startsWith('http') ? imageUrl : '${AppConfig.apiBaseUrl}$imageUrl';
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.network(fullUrl, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }



  // Dialogs helper actions
  void _showEditBasicInfoDialog(ProfileDto profile) {
    final nameCtrl = TextEditingController(text: profile.fullName);
    final idCtrl = TextEditingController(text: profile.studentId);
    final deptCtrl = TextEditingController(text: profile.departmentName);
    final uniCtrl = TextEditingController(text: profile.universityName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Basic Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: uniCtrl, decoration: const InputDecoration(labelText: 'University Name')),
            TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
            TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Student ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateProfile(profile.copyWith(
                fullName: nameCtrl.text,
                universityName: uniCtrl.text,
                departmentName: deptCtrl.text,
                studentId: idCtrl.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditPersonalDialog(ProfileDto profile) {
    final phoneCtrl = TextEditingController(text: profile.phone);
    final birthCtrl = TextEditingController(text: profile.birthday);
    final genderCtrl = TextEditingController(text: profile.gender);
    final addressCtrl = TextEditingController(text: profile.address);
    final contactCtrl = TextEditingController(text: profile.contactInformation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Personal Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              TextField(controller: birthCtrl, decoration: const InputDecoration(labelText: 'Birthday (YYYY-MM-DD)')),
              TextField(controller: genderCtrl, decoration: const InputDecoration(labelText: 'Gender')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Permanent Address')),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Additional Contact Email/Info')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateProfile(profile.copyWith(
                phone: phoneCtrl.text,
                birthday: birthCtrl.text,
                gender: genderCtrl.text,
                address: addressCtrl.text,
                contactInformation: contactCtrl.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditSocialsDialog(ProfileDto profile) {
    final gitCtrl = TextEditingController(text: profile.githubUrl);
    final linkCtrl = TextEditingController(text: profile.linkedinUrl);
    final webCtrl = TextEditingController(text: profile.websiteUrl);
    final fbCtrl = TextEditingController(text: profile.facebookUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Social Links'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: gitCtrl, decoration: const InputDecoration(labelText: 'GitHub Profile URL')),
            TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'LinkedIn Profile URL')),
            TextField(controller: webCtrl, decoration: const InputDecoration(labelText: 'Portfolio Website URL')),
            TextField(controller: fbCtrl, decoration: const InputDecoration(labelText: 'Facebook Profile URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateProfile(profile.copyWith(
                githubUrl: gitCtrl.text,
                linkedinUrl: linkCtrl.text,
                websiteUrl: webCtrl.text,
                facebookUrl: fbCtrl.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditAcademicDialog(ProfileDto profile) {
    final batchCtrl = TextEditingController(text: profile.batch);
    final semCtrl = TextEditingController(text: profile.semester);
    final secCtrl = TextEditingController(text: profile.section);
    final yearCtrl = TextEditingController(text: profile.academicYear);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Academic Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch')),
            TextField(controller: semCtrl, decoration: const InputDecoration(labelText: 'Semester/Term')),
            TextField(controller: secCtrl, decoration: const InputDecoration(labelText: 'Section')),
            TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Academic Year')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateProfile(profile.copyWith(
                batch: batchCtrl.text,
                semester: semCtrl.text,
                section: secCtrl.text,
                academicYear: yearCtrl.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddAcademicResultDialog(ProfileDto profile) {
    final levelCtrl = TextEditingController();
    final termCtrl = TextEditingController();
    final gpaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Academic Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: levelCtrl, decoration: const InputDecoration(labelText: 'Level (e.g. 1)')),
            TextField(controller: termCtrl, decoration: const InputDecoration(labelText: 'Term (e.g. 2)')),
            TextField(controller: gpaCtrl, decoration: const InputDecoration(labelText: 'GPA (e.g. 3.75)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newResults = List<AcademicResultDto>.from(profile.academicResults)
                ..add(AcademicResultDto(
                  level: levelCtrl.text,
                  term: termCtrl.text,
                  gpa: gpaCtrl.text,
                ));
              ref.read(profileProvider.notifier).updateProfile(profile.copyWith(academicResults: newResults));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddAchievementDialog(ProfileDto profile) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Achievement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title / Competitions')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newAch = List<AchievementDto>.from(profile.achievements)
                ..add(AchievementDto(
                  title: titleCtrl.text,
                  description: descCtrl.text,
                ));
              ref.read(profileProvider.notifier).updateProfile(profile.copyWith(achievements: newAch));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Custom CGPA Simulator & Target Projection Widget
// ----------------------------------------------------
class CgpaSimulatorWidget extends StatefulWidget {
  final double initialCgpa;
  final int initialSemesters;

  const CgpaSimulatorWidget({super.key, required this.initialCgpa, required this.initialSemesters});

  @override
  State<CgpaSimulatorWidget> createState() => _CgpaSimulatorWidgetState();
}

class _CgpaSimulatorWidgetState extends State<CgpaSimulatorWidget> {
  final List<Map<String, dynamic>> _simulatedCourses = [];
  final _nameController = TextEditingController();
  final _creditController = TextEditingController();
  String _selectedGrade = 'A+';

  final Map<String, double> _gradeScale = {
    'A+': 4.00,
    'A': 3.75,
    'A-': 3.50,
    'B+': 3.25,
    'B': 3.00,
    'B-': 2.75,
    'C+': 2.50,
    'C': 2.25,
    'D': 2.00,
    'F': 0.00,
  };

  void _addCourse() {
    final String name = _nameController.text.trim();
    final double? credits = double.tryParse(_creditController.text.trim());
    if (name.isNotEmpty && credits != null && credits > 0) {
      setState(() {
        _simulatedCourses.add({
          'name': name,
          'credits': credits,
          'grade': _selectedGrade,
          'point': _gradeScale[_selectedGrade] ?? 0.0,
        });
        _nameController.clear();
        _creditController.clear();
      });
    }
  }

  void _removeCourse(int index) {
    setState(() {
      _simulatedCourses.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalSimCredits = 0.0;
    double totalSimPoints = 0.0;
    for (var course in _simulatedCourses) {
      final double cr = course['credits'];
      final double pt = course['point'];
      totalSimCredits += cr;
      totalSimPoints += (cr * pt);
    }

    final double simulatedSgpa = totalSimCredits > 0 ? (totalSimPoints / totalSimCredits) : 0.0;
    
    // CGPA Projection math
    // Assuming each previous semester had an average of 15 credits
    final double previousCredits = widget.initialSemesters * 15.0;
    final double previousPoints = previousCredits * widget.initialCgpa;

    final double projectedCgpa = (previousCredits + totalSimCredits) > 0
        ? ((previousPoints + totalSimPoints) / (previousCredits + totalSimCredits))
        : widget.initialCgpa;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Interactive CGPA Calculator & Simulator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
          const Text('Simulate target grades for your active semester courses to project your cumulative CGPA.', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
          const Divider(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Simulator Inputs & Added Courses
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Course Name/Code', hintText: 'e.g. CSE-3101'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: _creditController,
                            decoration: const InputDecoration(labelText: 'Credit Hours', hintText: 'e.g. 3.0'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        DropdownButton<String>(
                          value: _selectedGrade,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGrade = val);
                          },
                          items: _gradeScale.keys.map((grade) {
                            return DropdownMenuItem<String>(value: grade, child: Text('$grade (${_gradeScale[grade]?.toStringAsFixed(2)})'));
                          }).toList(),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo600),
                          onPressed: _addCourse,
                          child: const Text('Add', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _simulatedCourses.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: Center(child: Text('No courses added to simulator yet.', style: TextStyle(color: AppColors.gray400, fontSize: 13))),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _simulatedCourses.length,
                            itemBuilder: (context, index) {
                              final course = _simulatedCourses[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  title: Text(course['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${course['credits']} Credits  •  Expected Grade: ${course['grade']}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _removeCourse(index),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              // Right: Simulation Projections
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.indigo50.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.indigo200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Simulation Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.indigo900)),
                      const SizedBox(height: AppSpacing.md),
                      _buildSimResultRow('Simulated Term GPA:', simulatedSgpa.toStringAsFixed(3)),
                      _buildSimResultRow('Simulated Credits Added:', totalSimCredits.toStringAsFixed(1)),
                      const Divider(color: AppColors.indigo200),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSimResultRow('Projected Cumulative CGPA:', projectedCgpa.toStringAsFixed(3), isHighlight: true),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'This projects how your CGPA will change. We assume ${widget.initialSemesters * 15} baseline credits from your ${widget.initialSemesters} completed semesters.',
                        style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimResultRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isHighlight ? AppColors.indigo900 : AppColors.gray700, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 15, color: isHighlight ? AppColors.indigo700 : AppColors.gray900, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
