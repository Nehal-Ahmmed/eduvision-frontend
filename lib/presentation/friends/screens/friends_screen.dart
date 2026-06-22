import 'package:flutter/material.dart';
import '../../theme/app_constants.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchTerm = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      child: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 1024 ? AppSpacing.xl : AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1152),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Friends',
                  style: AppTextStyles.studentTitle.copyWith(
                    color: AppColors.blue900,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.gray400, size: 16),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    searchTerm = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search friends...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: AppColors.gray400),
                                ),
                                style: AppTextStyles.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Find Friends'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.blue900,
                    unselectedLabelColor: AppColors.gray600,
                    indicator: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, size: 16),
                            SizedBox(width: AppSpacing.sm),
                            Text('Friends (3)'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time, size: 16),
                            SizedBox(width: AppSpacing.sm),
                            Text('Requests (2)'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add, size: 16),
                            SizedBox(width: AppSpacing.sm),
                            Text('Suggestions'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Tab Content
                SizedBox(
                  height: 800,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFriendsTab(),
                      _buildRequestsTab(),
                      _buildSuggestionsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    final friends = [
      {
        'name': 'Tran Thi Lan',
        'major': 'Computer Science',
        'class': 'K64-CS',
        'mutual_friends': 12,
        'last_active': 'Active 2 hours ago',
        'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b1c0?w=100&h=100&fit=crop&crop=face',
      },
      {
        'name': 'Hoang Van Hung',
        'major': 'Information Technology',
        'class': 'K63-IT',
        'mutual_friends': 8,
        'last_active': 'Active 1 day ago',
        'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
      },
      {
        'name': 'Do Thi Mai',
        'major': 'Computer Science',
        'class': 'K64-CS',
        'mutual_friends': 15,
        'last_active': 'Active 30 minutes ago',
        'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1024) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 768) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: 1.3,
          ),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.blue200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.blue200, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(friend['image'] as String),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend['name'] as String,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.blue900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              friend['major'] as String,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.blue600,
                              ),
                            ),
                            Text(
                              friend['class'] as String,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                            Text(
                              friend['last_active'] as String,
                              style: AppTextStyles.extraSmall.copyWith(
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${friend['mutual_friends']} mutual friends',
                      style: AppTextStyles.extraSmall,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue600,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.person_remove, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final requests = [
      {
        'name': 'Le Van Duc',
        'major': 'Software Engineering',
        'class': 'K64-SE',
        'mutual_friends': 3,
        'sent_at': '1 hour ago',
        'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
      },
      {
        'name': 'Nguyen Thi Hoa',
        'major': 'Information Security',
        'class': 'K63-IS',
        'mutual_friends': 7,
        'sent_at': '3 hours ago',
        'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&h=100&fit=crop&crop=face',
      },
    ];

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.yellow200),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.yellow200, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(request['image'] as String),
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
                        request['name'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.yellow900,
                        ),
                      ),
                      Text(
                        '${request['major']} • ${request['class']}',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.yellow700,
                        ),
                      ),
                      Text(
                        'Sent request ${request['sent_at']}',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${request['mutual_friends']} mutual friends',
                          style: AppTextStyles.extraSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green600,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray700,
                        side: const BorderSide(color: AppColors.gray200),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsTab() {
    final suggestions = [
      {
        'name': 'Pham Minh Tuan',
        'major': 'Computer Science',
        'class': 'K64-CS',
        'mutual_friends': 5,
        'reason': 'Same class',
        'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face',
      },
      {
        'name': 'Vu Thi Linh',
        'major': 'Information Technology',
        'class': 'K63-IT',
        'mutual_friends': 9,
        'reason': 'Many mutual friends',
        'image': 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=100&h=100&fit=crop&crop=face',
      },
      {
        'name': 'Bui Van Nam',
        'major': 'Software Engineering',
        'class': 'K64-SE',
        'mutual_friends': 2,
        'reason': 'Same department',
        'image': 'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=100&h=100&fit=crop&crop=face',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1024) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 768) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: 1.2,
          ),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.green200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.green200, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(suggestion['image'] as String),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion['name'] as String,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.green900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              suggestion['major'] as String,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.green700,
                              ),
                            ),
                            Text(
                              suggestion['class'] as String,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.green400),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          suggestion['reason'] as String,
                          style: AppTextStyles.extraSmall.copyWith(
                            color: AppColors.green700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${suggestion['mutual_friends']} mutual friends',
                          style: AppTextStyles.extraSmall,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Add Friend'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green600,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          minimumSize: const Size(40, 40),
                        ),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
