import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:academic_project/presentation/theme/app_constants.dart';
import 'package:academic_project/presentation/profile/provider/profile_provider.dart';
import 'package:academic_project/presentation/profile/models/profile_models.dart';
import 'package:academic_project/presentation/library/provider/library_provider.dart';
import 'package:academic_project/domain/book.dart';
import 'package:academic_project/presentation/events/provider/events_provider.dart';
import 'package:academic_project/domain/event.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const List<String> _studyQuotes = [
    "The capacity to learn is a gift; the ability to learn is a skill; the willingness to learn is a choice.",
    "Focus on progress, not perfection. Every page read is a step forward.",
    "Your focus determines your reality. Stay present and keep pushing.",
    "Success is the sum of small efforts, repeated day in and day out.",
    "The secret of getting ahead is getting started.",
    "It always seems impossible until it's done.",
    "Education is the most powerful weapon which you can use to change the world."
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).fetchProfile();
      ref.read(booksProvider.notifier).fetchBooks();
      ref.read(eventsProvider.notifier).fetchAll();
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(profileProvider.notifier).fetchProfile(),
      ref.read(booksProvider.notifier).fetchBooks(),
      ref.read(eventsProvider.notifier).fetchAll(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final booksState = ref.watch(booksProvider);
    final eventsState = ref.watch(eventsProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1150;
    final isTablet = screenWidth >= 768 && screenWidth < 1150;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final quote = _studyQuotes[DateTime.now().day % _studyQuotes.length];

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppColors.indigo600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth > 768 ? AppSpacing.xl : AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Grid
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeCard(profileState, quote),
                              const SizedBox(height: AppSpacing.xl),
                              _buildCgpaSection(profileState),
                              const SizedBox(height: AppSpacing.xl),
                              _buildFavoriteBooksSection(booksState),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FocusTimerWidget(),
                              const SizedBox(height: AppSpacing.xl),
                              _buildScheduleSection(eventsState),
                              const SizedBox(height: AppSpacing.xl),
                              _buildAchievementsAndCertificatesSection(profileState),
                            ],
                          ),
                        ),
                      ],
                    )
                  else if (isTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeCard(profileState, quote),
                              const SizedBox(height: AppSpacing.xl),
                              _buildCgpaSection(profileState),
                              const SizedBox(height: AppSpacing.xl),
                              _buildFavoriteBooksSection(booksState),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FocusTimerWidget(),
                              const SizedBox(height: AppSpacing.xl),
                              _buildScheduleSection(eventsState),
                              const SizedBox(height: AppSpacing.xl),
                              _buildAchievementsAndCertificatesSection(profileState),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(profileState, quote),
                        const SizedBox(height: AppSpacing.xl),
                        const FocusTimerWidget(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildCgpaSection(profileState),
                        const SizedBox(height: AppSpacing.xl),
                        _buildScheduleSection(eventsState),
                        const SizedBox(height: AppSpacing.xl),
                        _buildFavoriteBooksSection(booksState),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAchievementsAndCertificatesSection(profileState),
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

  // Welcome Header Card Widget
  Widget _buildWelcomeCard(AsyncValue<ProfileDto> state, String quote) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return state.when(
      loading: () => _buildPulseSkeleton(height: 160),
      error: (err, stack) => _buildErrorCard('Welcome back!', 'Could not load profile details.'),
      data: (profile) {
        final name = profile.fullName ?? 'Student';
        final dept = profile.departmentName ?? 'Select department in profile';
        final batch = profile.batch ?? '';
        final semester = profile.semester ?? '';
        final rawImg = profile.profileImageUrl ?? '';
        
        final finalImgUrl = rawImg.isEmpty
            ? 'https://ui-avatars.com/api/?name=$name&background=4F46E5&color=fff&size=128'
            : (rawImg.startsWith('http') ? rawImg : '${AppConfig.apiBaseUrl}$rawImg');

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: isDark ? AppColors.gray700 : AppColors.blue200),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : AppColors.indigo700.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.gray700 : AppColors.indigo200, width: 3),
                      image: DecorationImage(
                        image: NetworkImage(finalImgUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: AppTextStyles.body.copyWith(
                            color: isDark ? AppColors.gray400 : AppColors.gray500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          name,
                          style: AppTextStyles.studentTitle.copyWith(
                            color: isDark ? Colors.white : AppColors.indigo900,
                            fontSize: 26,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.school, size: 14, color: AppColors.indigo500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${dept.isNotEmpty ? dept : "EduVision Student"}${batch.isNotEmpty ? " • Batch $batch" : ""}${semester.isNotEmpty ? " • $semester" : ""}',
                                style: AppTextStyles.smallMedium.copyWith(
                                  color: isDark ? AppColors.indigo400 : AppColors.indigo700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.gray900 : AppColors.indigo50,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: isDark ? AppColors.gray700 : AppColors.indigo200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.indigo600, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        '"$quote"',
                        style: AppTextStyles.small.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.indigo900,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // CGPA Display Widget (Non-Editable)
  Widget _buildCgpaSection(AsyncValue<ProfileDto> state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return state.when(
      loading: () => _buildPulseSkeleton(height: 220),
      error: (err, stack) => _buildErrorCard('CGPA Status', 'Could not load academic results.'),
      data: (profile) {
        final results = profile.academicResults;
        
        final validGpas = results
            .map((e) {
              if (e.gpa == null) return null;
              final val = e.gpa!.split('/').first.trim();
              return double.tryParse(val);
            })
            .whereType<double>()
            .toList();

        double currentCgpa = 0.0;
        if (validGpas.isNotEmpty) {
          currentCgpa = validGpas.reduce((a, b) => a + b) / validGpas.length;
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Performance',
                        style: AppTextStyles.subsectionHeading.copyWith(
                          color: isDark ? Colors.white : AppColors.gray900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Cumulative CGPA Overview',
                        style: AppTextStyles.extraSmall.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray900 : AppColors.indigo50,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: isDark ? AppColors.gray700 : AppColors.indigo200),
                    ),
                    child: Text(
                      'Non-Editable',
                      style: AppTextStyles.extraSmall.copyWith(color: AppColors.indigo600, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: (currentCgpa > 0.0 ? currentCgpa : 0.0) / 4.0,
                          strokeWidth: 10,
                          color: AppColors.indigo600,
                          backgroundColor: isDark ? AppColors.gray900 : AppColors.gray100,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentCgpa > 0.0 ? currentCgpa.toStringAsFixed(2) : '0.00',
                            style: AppTextStyles.studentTitle.copyWith(
                              color: isDark ? Colors.white : AppColors.gray900,
                              fontSize: 28,
                            ),
                          ),
                          Text(
                            '/ 4.00',
                            style: AppTextStyles.extraSmall.copyWith(
                              color: isDark ? AppColors.gray400 : AppColors.gray500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semester Breakdown',
                          style: AppTextStyles.smallMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.gray800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (results.isEmpty)
                          Text(
                            'No semester results added yet. Go to Profile > Academic Status to record your GPAs.',
                            style: AppTextStyles.small.copyWith(
                              color: isDark ? AppColors.gray400 : AppColors.gray500,
                            ),
                          )
                        else
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final res = results[index];
                                final sgpaVal = double.tryParse(res.gpa?.split('/').first.trim() ?? '0.0') ?? 0.0;
                                return Container(
                                  width: 95,
                                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.gray900 : AppColors.gray50,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${res.level ?? "L"}${res.term ?? "T"}',
                                        style: AppTextStyles.extraSmall.copyWith(
                                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sgpaVal.toStringAsFixed(2),
                                        style: AppTextStyles.smallMedium.copyWith(color: AppColors.indigo600, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // Favorite Books List Card Widget
  Widget _buildFavoriteBooksSection(AsyncValue<List<Book>> state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return state.when(
      loading: () => _buildPulseSkeleton(height: 250),
      error: (err, stack) => _buildErrorCard('My Favorites Shelf 📚', 'Could not load library books.'),
      data: (books) {
        final favorites = books.where((book) => book.isFavorite).toList();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: isDark ? AppColors.gray700 : AppColors.blue200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.01),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorite Books 📚',
                        style: AppTextStyles.subsectionHeading.copyWith(
                          color: isDark ? Colors.white : AppColors.gray900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Handpicked study resources & reads',
                        style: AppTextStyles.extraSmall.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Open Shelf'),
                    onPressed: () => context.go('/library'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.blue600),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (favorites.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray900 : AppColors.blue50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: isDark ? AppColors.gray700 : AppColors.blue100.withOpacity(0.7)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.bookmark_border, size: 44, color: AppColors.blue400),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No favorites marked yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.blue900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mark textbooks or reference PDFs as favorite in your Library to display them on your dashboard.',
                        style: AppTextStyles.small.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.gray500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () => context.go('/library'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue600,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        child: const Text('Browse Library'),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final book = favorites[index];
                      // Cover background color based on category or index
                      final List<Color> coverColors = [
                        AppColors.indigo700,
                        AppColors.blue700,
                        AppColors.purple700,
                        AppColors.green700,
                        AppColors.orange800,
                      ];
                      final coverColor = coverColors[index % coverColors.length];

                      return Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: AppSpacing.lg),
                        child: InkWell(
                          onTap: () => context.go('/library'),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: coverColor,
                                    borderRadius: BorderRadius.circular(AppRadius.xl),
                                    boxShadow: [
                                      BoxShadow(
                                        color: coverColor.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: 6,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.15),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(AppRadius.xl),
                                              bottomLeft: Radius.circular(AppRadius.xl),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.picture_as_pdf, color: AppColors.white, size: 28),
                                            const SizedBox(height: AppSpacing.sm),
                                            Text(
                                              book.title,
                                              style: AppTextStyles.extraSmall.copyWith(
                                                color: AppColors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                book.title,
                                style: AppTextStyles.smallMedium.copyWith(
                                  color: isDark ? Colors.white : AppColors.gray900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                book.author ?? 'Unknown Author',
                                style: AppTextStyles.extraSmall.copyWith(
                                  color: isDark ? AppColors.gray400 : AppColors.gray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // Schedule Timeline Widget
  Widget _buildScheduleSection(AsyncValue<List<Event>> state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return state.when(
      loading: () => _buildPulseSkeleton(height: 250),
      error: (err, stack) => _buildErrorCard('Upcoming Schedule 🗓️', 'Could not load schedule items.'),
      data: (events) {
        final upcomingEvents = events.where((e) => e.isUpcoming).toList()
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

        // Take only the top 4 upcoming schedule items
        final displayList = upcomingEvents.take(4).toList();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: isDark ? AppColors.gray700 : AppColors.green200),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : AppColors.green50.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Schedule 🗓️',
                        style: AppTextStyles.subsectionHeading.copyWith(
                          color: isDark ? Colors.white : AppColors.green900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Exams, deadlines and classes',
                        style: AppTextStyles.extraSmall.copyWith(
                          color: isDark ? AppColors.green400 : AppColors.green700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: isDark ? AppColors.green400 : AppColors.green700),
                    onPressed: () => context.go('/events'),
                    tooltip: 'Manage Events',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (displayList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray900 : AppColors.green50,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: isDark ? AppColors.gray700 : AppColors.green200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.today, size: 40, color: AppColors.green600),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No upcoming schedule',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.green900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep track of your examinations and deadlines here.',
                        style: AppTextStyles.small.copyWith(
                          color: isDark ? AppColors.gray400 : AppColors.green700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final ev = displayList[index];
                    
                    // Choose color and icon based on EventType
                    Color eventColor = AppColors.green600;
                    IconData eventIcon = Icons.class_outlined;
                    
                    switch (ev.type) {
                      case EventType.EXAM:
                        eventColor = AppColors.red500;
                        eventIcon = Icons.quiz_outlined;
                        break;
                      case EventType.DEADLINE:
                        eventColor = AppColors.orange500;
                        eventIcon = Icons.hourglass_bottom_outlined;
                        break;
                      case EventType.LECTURE:
                        eventColor = AppColors.blue600;
                        eventIcon = Icons.menu_book_outlined;
                        break;
                      case EventType.GROUP:
                        eventColor = AppColors.purple600;
                        eventIcon = Icons.groups_outlined;
                        break;
                      case EventType.OTHER:
                        eventColor = AppColors.green600;
                        eventIcon = Icons.today;
                        break;
                    }

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: eventColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: eventColor.withOpacity(0.3)),
                                ),
                                child: Icon(eventIcon, size: 16, color: eventColor),
                              ),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: isDark ? AppColors.gray700 : AppColors.gray200,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: eventColor.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ev.title,
                                          style: AppTextStyles.smallMedium.copyWith(
                                            color: isDark ? Colors.white : AppColors.gray900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: eventColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(AppRadius.full),
                                        ),
                                        child: Text(
                                          _getRelativeDate(ev.eventDate),
                                          style: AppTextStyles.extraSmall.copyWith(
                                            color: eventColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? AppColors.gray400 : AppColors.gray500),
                                      const SizedBox(width: 4),
                                      Text(
                                        ev.formattedDate,
                                        style: AppTextStyles.extraSmall.copyWith(
                                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                                        ),
                                      ),
                                      if (ev.startTime != null) ...[
                                        const SizedBox(width: 8),
                                        Icon(Icons.access_time_outlined, size: 12, color: isDark ? AppColors.gray400 : AppColors.gray500),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${ev.startTime}${ev.endTime != null ? " - ${ev.endTime}" : ""}',
                                          style: AppTextStyles.extraSmall.copyWith(
                                            color: isDark ? AppColors.gray400 : AppColors.gray600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (ev.location != null && ev.location!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 12, color: isDark ? AppColors.gray400 : AppColors.gray500),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            ev.location!,
                                            style: AppTextStyles.extraSmall.copyWith(
                                              color: isDark ? AppColors.gray400 : AppColors.gray600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ).animate().fadeIn(duration: 550.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // Achievements & Certificates section combined
  Widget _buildAchievementsAndCertificatesSection(AsyncValue<ProfileDto> state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return state.when(
      loading: () => _buildPulseSkeleton(height: 250),
      error: (err, stack) => _buildErrorCard('Achievements & Certificates', 'Could not load items.'),
      data: (profile) {
        final achievements = profile.achievements;
        final certificates = achievements.where((ach) => ach.certificateImageUrl != null && ach.certificateImageUrl!.isNotEmpty).toList();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(color: isDark ? AppColors.gray700 : AppColors.purple200),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : AppColors.purple50.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievements Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievements 🏆',
                        style: AppTextStyles.subsectionHeading.copyWith(
                          color: isDark ? Colors.white : AppColors.purple900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Academic & extracurricular milestones',
                        style: AppTextStyles.extraSmall.copyWith(
                          color: isDark ? AppColors.purple400 : AppColors.purple700,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/profile'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.purple700),
                    child: const Text('Update'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              
              if (achievements.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray900 : AppColors.purple50.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: isDark ? AppColors.gray700 : AppColors.purple200.withOpacity(0.5)),
                  ),
                  child: Text(
                    'No achievements listed. Add your achievements in the Profile tab.',
                    style: AppTextStyles.small.copyWith(
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: achievements.length.clamp(0, 3), // Show max 3 recent achievements
                  itemBuilder: (context, index) {
                    final ach = achievements[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.emoji_events_outlined, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ach.title ?? 'Achievement',
                                  style: AppTextStyles.smallMedium.copyWith(
                                    color: isDark ? Colors.white : AppColors.gray900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (ach.description != null && ach.description!.isNotEmpty)
                                  Text(
                                    ach.description!,
                                    style: AppTextStyles.extraSmall.copyWith(
                                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),
              Divider(color: isDark ? AppColors.gray700 : AppColors.gray200),
              const SizedBox(height: AppSpacing.md),

              // Certificates Title
              Text(
                'Certificates 📜',
                style: AppTextStyles.subsectionHeading.copyWith(
                  color: isDark ? Colors.white : AppColors.purple900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (certificates.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray900 : AppColors.purple50.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: isDark ? AppColors.gray700 : AppColors.purple200.withOpacity(0.5)),
                  ),
                  child: Text(
                    'No certificates uploaded yet.',
                    style: AppTextStyles.small.copyWith(
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: certificates.length.clamp(0, 4), // max 4 thumbnails
                  itemBuilder: (context, index) {
                    final cert = certificates[index];
                    final imgPath = cert.certificateImageUrl!;
                    final fullUrl = imgPath.startsWith('http') ? imgPath : '${AppConfig.apiBaseUrl}$imgPath';

                    return InkWell(
                      onTap: () => _showZoomableImageDialog(imgPath),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200),
                          image: DecorationImage(
                            image: NetworkImage(fullUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(AppRadius.lg - 1),
                                bottomRight: Radius.circular(AppRadius.lg - 1),
                              ),
                            ),
                            child: Text(
                              cert.title ?? 'Certificate',
                              style: AppTextStyles.extraSmall.copyWith(color: AppColors.white, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  // Zoomable certificate dialog
  void _showZoomableImageDialog(String imageUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                backgroundColor: isDark ? Colors.black87 : Colors.black54,
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

  // Helpers
  String _getRelativeDate(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final difference = eventDay.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1) {
      return 'In $difference days';
    } else {
      return '${difference.abs()} days ago';
    }
  }

  Widget _buildPulseSkeleton({required double height}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : AppColors.gray200,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .fade(begin: 0.5, end: 1.0, duration: 1000.ms);
  }

  Widget _buildErrorCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.red200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline, color: AppColors.red500),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Data Unavailable',
                style: TextStyle(color: AppColors.red900, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: const TextStyle(color: AppColors.red900, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(color: AppColors.red900, fontSize: 12)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// Focus Timer Widget - Pomodoro / Focus Sessions (Wow Factor widget)
// -------------------------------------------------------------
class FocusTimerWidget extends StatefulWidget {
  const FocusTimerWidget({super.key});

  @override
  State<FocusTimerWidget> createState() => _FocusTimerWidgetState();
}

class _FocusTimerWidgetState extends State<FocusTimerWidget> {
  static const int _focusDuration = 25 * 60; // 25 mins
  int _secondsRemaining = _focusDuration;
  bool _isRunning = false;
  Timer? _timer;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _secondsRemaining = _focusDuration;
          });
          _showCompletionSnackbar();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _focusDuration;
      _isRunning = false;
    });
  }

  void _showCompletionSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus Session complete! Time for a short break. 🎉'),
          backgroundColor: AppColors.indigo700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: isDark ? AppColors.gray700 : AppColors.indigo200),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : AppColors.indigo50.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.indigo600),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Study Focus Timer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: AppTextStyles.studentTitle.copyWith(
                      color: isDark ? Colors.white : AppColors.indigo900,
                      fontSize: 34,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    _isRunning ? 'Focus Session Active' : 'Start Focus Session (25m)',
                    style: AppTextStyles.extraSmall.copyWith(
                      color: _isRunning ? AppColors.indigo600 : (isDark ? AppColors.gray400 : AppColors.gray500),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    iconSize: 42,
                    color: AppColors.indigo600,
                    onPressed: _toggleTimer,
                  ),
                  if (!_isRunning && _secondsRemaining < _focusDuration)
                    IconButton(
                      icon: const Icon(Icons.replay),
                      iconSize: 24,
                      color: isDark ? AppColors.gray400 : AppColors.gray500,
                      onPressed: _resetTimer,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
