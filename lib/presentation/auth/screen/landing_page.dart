import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      body: Stack(
        children: [
          // Dynamic Background Shapes
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlurCircle(400, const Color(0xFF6366F1).withOpacity(0.25)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildBlurCircle(350, const Color(0xFFEC4899).withOpacity(0.2)),
          ),
          Positioned(
            top: size.height * 0.35,
            left: size.width * 0.15,
            child: _buildBlurCircle(300, const Color(0xFF06B6D4).withOpacity(0.15)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  children: [
                    // Header Nav
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'EduVision',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => context.go('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 80),

                    // Hero Content
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stars_rounded, color: Color(0xFF818CF8), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Your ultimate study and academic workspace',
                                    style: TextStyle(
                                      color: Color(0xFFC7D2FE),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Empower Your Learning\nJourney With EduVision',
                              style: TextStyle(
                                fontSize: size.width < 600 ? 36 : 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15,
                                letterSpacing: -1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'A unified platform to manage smart notes, course progress, academic classes, libraries, and class test trackings. Seamlessly organize everything in one space.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.6),
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // Main CTA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () => context.go('/signup'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Create Free Account',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),

                    // Feature Grid
                    Text(
                      'Explore Key Workspace Features',
                      style: TextStyle(
                        fontSize: size.width < 600 ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    GridView.count(
                      crossAxisCount: size.width < 768 ? 1 : (size.width < 1024 ? 2 : 3),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: size.width < 768 ? 1.6 : 1.3,
                      children: [
                        _buildFeatureCard(
                          icon: Icons.dashboard_customize_outlined,
                          title: 'All-in-one Dashboard',
                          description: 'Track your overall academics, dynamic schedules, tasks, and recent updates at a glance.',
                          color: const Color(0xFF6366F1),
                        ),
                        _buildFeatureCard(
                          icon: Icons.note_alt_outlined,
                          title: 'Smart Notes',
                          description: 'Interactive and collaborative notebook space, rich editor with moveable components.',
                          color: const Color(0xFF06B6D4),
                        ),
                        _buildFeatureCard(
                          icon: Icons.book_outlined,
                          title: 'Course Tracker',
                          description: 'Set credits, dynamic class test marks calculations, and track best mark weightages easily.',
                          color: const Color(0xFFEC4899),
                        ),
                        _buildFeatureCard(
                          icon: Icons.library_books_outlined,
                          title: 'Resource Library',
                          description: 'Organize your academic materials, books, and download items directly without friction.',
                          color: const Color(0xFF10B981),
                        ),
                        _buildFeatureCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Dynamic Profiles',
                          description: 'Manage details, view stats, and access credentials or course paths directly.',
                          color: const Color(0xFFF59E0B),
                        ),
                        _buildFeatureCard(
                          icon: Icons.calendar_today_rounded,
                          title: 'Academic Events & Timelines',
                          description: 'Sync your exams, test routines, class terms, and calendar dates seamlessly.',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '© 2026 EduVision. All rights reserved.',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                          ),
                          Text(
                            'Designed for Premium Learning Experiences',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).move(
          duration: 7.seconds,
          begin: const Offset(-30, -30),
          end: const Offset(30, 30),
        );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
