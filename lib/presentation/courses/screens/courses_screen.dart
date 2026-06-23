import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/course.dart';
import '../../../data/course_remote_data_source.dart';
import '../../theme/app_constants.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _dataSource = CourseRemoteDataSource();

  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _dataSource.fetchCourses();
      setState(() {
        _courses = courses;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load courses. Make sure backend is running.')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCourse(String code, String title, double credits) async {
    final int ctCount = credits >= 3.0 ? 4 : 3;
    final newCourse = Course(
      code: code.trim(),
      title: title.trim(),
      credits: credits,
      ctMarks: List<double?>.filled(ctCount, null),
    );

    setState(() => _isLoading = true);
    try {
      final created = await _dataSource.createCourse(newCourse);
      setState(() {
        _courses.add(created);
      });
    } catch (e) {
      debugPrint('Error saving course: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCourse(int id) async {
    setState(() => _isLoading = true);
    try {
      await _dataSource.deleteCourse(id);
      setState(() {
        _courses.removeWhere((c) => c.id == id);
      });
    } catch (e) {
      debugPrint('Error deleting course: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCtMark(int courseId, int ctIndex, double? mark) async {
    final courseIndex = _courses.indexWhere((c) => c.id == courseId);
    if (courseIndex == -1) return;

    final course = _courses[courseIndex];
    // Create new list to avoid mutating state directly
    final newMarks = List<double?>.from(course.ctMarks);
    while (newMarks.length < course.maxCts) {
      newMarks.add(null);
    }
    newMarks[ctIndex] = mark;

    final updatedCourse = course.copyWith(ctMarks: newMarks);

    // Optimistic UI update
    setState(() {
      _courses[courseIndex] = updatedCourse;
    });

    try {
      await _dataSource.updateCourse(updatedCourse);
    } catch (e) {
      debugPrint('Error updating course mark: $e');
      // Revert on error
      setState(() {
        _courses[courseIndex] = course;
      });
    }
  }

  void _showAddCourseDialog() {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    double credits = 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                side: BorderSide(color: Colors.black.withOpacity(0.05)),
              ),
              title: const Text(
                'Add New Course',
                style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      style: const TextStyle(color: AppColors.gray900),
                      decoration: InputDecoration(
                        labelText: 'Course Code (e.g. CSE 311)',
                        labelStyle: const TextStyle(color: AppColors.gray500),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.indigo600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: AppColors.gray900),
                      decoration: InputDecoration(
                        labelText: 'Course Title (e.g. Database Systems)',
                        labelStyle: const TextStyle(color: AppColors.gray500),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.indigo600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Credits: $credits',
                          style: const TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w600),
                        ),
                        DropdownButton<double>(
                          dropdownColor: Colors.white,
                          value: credits,
                          items: const [
                            DropdownMenuItem(value: 0.75, child: Text('0.75 Credits', style: TextStyle(color: AppColors.gray900))),
                            DropdownMenuItem(value: 1.5, child: Text('1.5 Credits', style: TextStyle(color: AppColors.gray900))),
                            DropdownMenuItem(value: 2.0, child: Text('2.0 Credits', style: TextStyle(color: AppColors.gray900))),
                            DropdownMenuItem(value: 3.0, child: Text('3.0 Credits', style: TextStyle(color: AppColors.gray900))),
                            DropdownMenuItem(value: 4.0, child: Text('4.0 Credits', style: TextStyle(color: AppColors.gray900))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                credits = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (codeCtrl.text.isNotEmpty && titleCtrl.text.isNotEmpty) {
                      _addCourse(codeCtrl.text, titleCtrl.text, credits);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Course'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    double totalCredits = _courses.fold(0.0, (sum, item) => sum + item.credits);
    double maxCtPossibleScore = _courses.fold(0.0, (sum, item) {
      return sum + (item.countedCts * 20.0);
    });
    double currentCtTotalObtained = _courses.fold(0.0, (sum, item) {
      return sum + (item.calculateCtScore()['total'] as double);
    });

    return Scaffold(
      backgroundColor: AppColors.gray50, // Light mode background
      body: _isLoading && _courses.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.indigo600))
          : Stack(
              children: [
                // Top-right light blur circle
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                     width: 300,
                     height: 300,
                     decoration: BoxDecoration(
                       color: AppColors.indigo200.withOpacity(0.5),
                       shape: BoxShape.circle,
                     ),
                  ),
                ),

                SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Academic Courses',
                                        style: TextStyle(
                                          color: AppColors.gray900,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Manage Level/Term courses, track Class Test grades, and verify averages.',
                                        style: TextStyle(
                                          color: AppColors.gray500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _showAddCourseDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.indigo600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 20),
                                    label: const Text('Add Course', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),
                              _buildTermSummaryCard(totalCredits, currentCtTotalObtained, maxCtPossibleScore),
                            ],
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                        sliver: _courses.isEmpty
                            ? SliverToBoxAdapter(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 80),
                                  child: const Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.import_contacts_rounded, size: 64, color: AppColors.gray400),
                                        SizedBox(height: 16),
                                        Text(
                                          'No academic courses configured for this term yet.',
                                          style: TextStyle(color: AppColors.gray500, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isDesktop ? 2 : 1,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  mainAxisExtent: 310,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final course = _courses[index];
                                    return _buildCourseCard(course);
                                  },
                                  childCount: _courses.length,
                                ),
                              ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
                if (_isLoading && _courses.isNotEmpty)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: SafeArea(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: AppColors.indigo600, strokeWidth: 3),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTermSummaryCard(double credits, double obtained, double maxScore) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Term Credits',
                  style: TextStyle(color: AppColors.gray500, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${credits.toStringAsFixed(2)} CR',
                  style: const TextStyle(color: AppColors.gray900, fontSize: 36, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.black.withOpacity(0.05)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cumulative CT Obtained',
                  style: TextStyle(color: AppColors.gray500, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      obtained.toStringAsFixed(2),
                      style: const TextStyle(color: AppColors.green500, fontSize: 36, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      ' / ${maxScore.toStringAsFixed(0)} pts',
                      style: const TextStyle(color: AppColors.gray400, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.black.withOpacity(0.05)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Courses Registered',
                  style: TextStyle(color: AppColors.gray500, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_courses.length} courses',
                  style: const TextStyle(color: AppColors.gray900, fontSize: 36, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final ctScoreMap = course.calculateCtScore();
    final double totalCtScore = ctScoreMap['total'];
    final List<int> countedIndices = ctScoreMap['counted'];
    final List<int> discardedIndices = ctScoreMap['discarded'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.indigo50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.indigo200),
                      ),
                      child: Text(
                        course.code,
                        style: const TextStyle(color: AppColors.indigo700, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${course.credits} CR',
                      style: const TextStyle(color: AppColors.gray700, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red500, size: 20),
                    onPressed: () {
                      _showDeleteConfirmation(course.id!, course.title);
                    },
                    tooltip: 'Delete Course',
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Class Test Marks',
                style: TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                'Counts Best ${course.countedCts} of ${course.maxCts}',
                style: const TextStyle(color: AppColors.gray400, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(course.maxCts, (i) {
              final double? val = course.ctMarks.length > i ? course.ctMarks[i] : null;
              final bool isCounted = countedIndices.contains(i);
              final bool isDiscarded = discardedIndices.contains(i);
              
              final borderThemeColor = isCounted 
                  ? AppColors.green500
                  : (val != null ? AppColors.red400 : Colors.black.withOpacity(0.1));

              return Container(
                width: 65,
                decoration: BoxDecoration(
                  color: isCounted ? AppColors.emerald50.withOpacity(0.5) : AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderThemeColor,
                    width: isCounted ? 1.5 : 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'CT-${i + 1}',
                      style: TextStyle(
                        color: isCounted 
                            ? AppColors.green600
                            : (isDiscarded ? AppColors.gray400 : AppColors.gray500),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        decoration: isDiscarded ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 28,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isCounted ? AppColors.green700 : AppColors.gray800,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: isDiscarded ? TextDecoration.lineThrough : null,
                        ),
                        decoration: const InputDecoration(
                          hintText: '-',
                          hintStyle: TextStyle(color: AppColors.gray200),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (text) {
                          double? parsed = double.tryParse(text);
                          _updateCtMark(course.id!, i, parsed);
                        },
                        controller: TextEditingController(
                          text: val != null ? (val % 1 == 0 ? val.toInt().toString() : val.toString()) : '',
                        )..selection = TextSelection.fromPosition(
                            TextPosition(offset: val != null ? (val % 1 == 0 ? val.toInt().toString() : val.toString()).length : 0),
                          ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const Spacer(),
          Divider(color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Marks:',
                style: TextStyle(color: AppColors.gray600, fontSize: 13),
              ),
              Text(
                '${totalCtScore.toStringAsFixed(1)} / ${(course.countedCts * 20.0).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.green600,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int courseId, String courseTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
          title: const Text('Delete Course', style: TextStyle(color: AppColors.gray900)),
          content: Text(
            'Are you sure you want to delete "$courseTitle"? This will remove all stored CT grades.',
            style: const TextStyle(color: AppColors.gray600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red600),
              onPressed: () {
                _deleteCourse(courseId);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
