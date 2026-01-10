import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeacherData();
  }

  void _loadTeacherData() {
    context.read<LanguageLearningBloc>().add(LoadTeacherDashboard());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.pureWhite.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'My Lessons'),
            Tab(text: 'Earnings'),
            Tab(text: 'Students'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLessonsTab(),
          _buildEarningsTab(),
          _buildStudentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewLesson,
        backgroundColor: AppColors.richGold,
        icon: const Icon(Icons.add, color: AppColors.deepBlack),
        label: const Text(
          'Create Lesson',
          style: TextStyle(
            color: AppColors.deepBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
      builder: (context, state) {
        // Use mock data for now
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              _buildStatsGrid(),
              const SizedBox(height: 24),

              // Tier Progress
              _buildTierProgressCard(),
              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivitySection(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActionsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Students',
          '1,234',
          Icons.people,
          AppColors.infoBlue,
          '+12% this month',
        ),
        _buildStatCard(
          'Published Lessons',
          '24',
          Icons.book,
          AppColors.successGreen,
          '3 drafts pending',
        ),
        _buildStatCard(
          'Monthly Earnings',
          '\$2,450',
          Icons.monetization_on,
          AppColors.richGold,
          '+8% vs last month',
        ),
        _buildStatCard(
          'Average Rating',
          '4.8',
          Icons.star,
          AppColors.warningAmber,
          '156 reviews',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.pureWhite.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withOpacity(0.2),
            AppColors.charcoal,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: AppColors.deepBlack,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Professional Tier',
                        style: TextStyle(
                          color: AppColors.richGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '65% revenue share',
                        style: TextStyle(
                          color: AppColors.pureWhite.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: _showTierInfo,
                child: const Text(
                  'View Tiers',
                  style: TextStyle(color: AppColors.richGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress to Expert Tier',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: AppColors.pureWhite.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.richGold,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '850 / 1,000 students needed',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.richGold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'New enrollment',
                'Maria enrolled in "Spanish for Dating"',
                '2 min ago',
                Icons.person_add,
                AppColors.successGreen,
              ),
              const Divider(color: AppColors.deepBlack, height: 1),
              _buildActivityItem(
                'New review',
                'Carlos rated "Flirting Phrases" 5 stars',
                '1 hour ago',
                Icons.star,
                AppColors.warningAmber,
              ),
              const Divider(color: AppColors.deepBlack, height: 1),
              _buildActivityItem(
                'Earnings',
                'You earned 150 coins from lesson sales',
                '3 hours ago',
                Icons.monetization_on,
                AppColors.richGold,
              ),
              const Divider(color: AppColors.deepBlack, height: 1),
              _buildActivityItem(
                'Lesson completed',
                '5 students completed "Greetings 101"',
                '5 hours ago',
                Icons.check_circle,
                AppColors.infoBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Create Lesson',
                Icons.add_box,
                AppColors.successGreen,
                _createNewLesson,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'View Analytics',
                Icons.analytics,
                AppColors.infoBlue,
                () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Withdraw',
                Icons.account_balance_wallet,
                AppColors.richGold,
                _showWithdrawDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildLessonFilterChip('All', true),
              _buildLessonFilterChip('Published', false),
              _buildLessonFilterChip('Draft', false),
              _buildLessonFilterChip('Under Review', false),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Lesson cards
        _buildTeacherLessonCard(
          'Spanish for Dating - Week 1',
          'Published',
          AppColors.successGreen,
          '234 enrollments',
          4.8,
        ),
        _buildTeacherLessonCard(
          'Flirting Phrases in French',
          'Published',
          AppColors.successGreen,
          '189 enrollments',
          4.9,
        ),
        _buildTeacherLessonCard(
          'Italian Romance Vocabulary',
          'Draft',
          AppColors.warningAmber,
          '0 enrollments',
          0,
        ),
        _buildTeacherLessonCard(
          'Portuguese Love Expressions',
          'Under Review',
          AppColors.infoBlue,
          'Pending approval',
          0,
        ),
      ],
    );
  }

  Widget _buildLessonFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {},
        backgroundColor: AppColors.charcoal,
        selectedColor: AppColors.richGold,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.deepBlack : AppColors.pureWhite,
        ),
        checkmarkColor: AppColors.deepBlack,
      ),
    );
  }

  Widget _buildTeacherLessonCard(
    String title,
    String status,
    Color statusColor,
    String subtitle,
    double rating,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.pureWhite.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              if (rating > 0)
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warningAmber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        color: AppColors.warningAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.pureWhite,
                    side: BorderSide(color: AppColors.pureWhite.withOpacity(0.3)),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.richGold,
                    side: const BorderSide(color: AppColors.richGold),
                  ),
                  child: const Text('Analytics'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Earnings Overview Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: AppColors.deepBlack,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '\$1,245.50',
                style: TextStyle(
                  color: AppColors.deepBlack,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showWithdrawDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlack,
                  foregroundColor: AppColors.richGold,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Withdraw Funds'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Earnings Breakdown
        Row(
          children: [
            Expanded(
              child: _buildEarningsStat('This Month', '\$485.00', '+12%'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEarningsStat('Last Month', '\$432.50', '+8%'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent Transactions
        const Text(
          'Recent Transactions',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTransactionItem(
          'Spanish Dating Lesson',
          '+\$12.50',
          'Dec 10, 2024',
          true,
        ),
        _buildTransactionItem(
          'French Flirting Phrases',
          '+\$8.75',
          'Dec 10, 2024',
          true,
        ),
        _buildTransactionItem(
          'Withdrawal to PayPal',
          '-\$500.00',
          'Dec 8, 2024',
          false,
        ),
        _buildTransactionItem(
          'Italian Romance Vocab',
          '+\$15.00',
          'Dec 7, 2024',
          true,
        ),
      ],
    );
  }

  Widget _buildEarningsStat(String label, String amount, String change) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: const TextStyle(
              color: AppColors.successGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    String title,
    String amount,
    String date,
    bool isCredit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: AppColors.pureWhite.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              color: isCredit ? AppColors.successGreen : AppColors.errorRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Student Stats
        Row(
          children: [
            Expanded(
              child: _buildStudentStat('Total Students', '1,234'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStudentStat('Active This Week', '456'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Top Students
        const Text(
          'Top Performing Students',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildStudentCard('Maria Garcia', '12 lessons completed', 4850),
        _buildStudentCard('Carlos Rodriguez', '10 lessons completed', 4200),
        _buildStudentCard('Sophie Martin', '9 lessons completed', 3890),
        _buildStudentCard('Luca Rossi', '8 lessons completed', 3450),
        _buildStudentCard('Emma Wilson', '7 lessons completed', 3100),
      ],
    );
  }

  Widget _buildStudentStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(String name, String progress, int xp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.richGold.withOpacity(0.2),
            child: Text(
              name[0],
              style: const TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  progress,
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.richGold, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.bold,
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

  void _createNewLesson() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateLessonScreen(),
      ),
    );
  }

  void _showTierInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Tiers',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildTierRow('Starter', '50%', '0-100 students'),
            _buildTierRow('Professional', '65%', '100-500 students'),
            _buildTierRow('Expert', '75%', '500-1000 students'),
            _buildTierRow('Master', '80%', '1000+ students'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(String tier, String share, String requirement) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tier,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            share,
            style: const TextStyle(
              color: AppColors.richGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            requirement,
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text(
          'Withdraw Funds',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: AppColors.pureWhite.withOpacity(0.6)),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: AppColors.richGold),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.pureWhite.withOpacity(0.3)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.richGold),
                ),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.pureWhite),
            ),
            const SizedBox(height: 16),
            Text(
              'Minimum withdrawal: \$50.00',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.pureWhite),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal request submitted!'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

class CreateLessonScreen extends StatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  LessonLevel _selectedLevel = LessonLevel.beginner;
  LessonCategory _selectedCategory = LessonCategory.greetings;
  String _selectedLanguage = 'es';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: const Text(
          'Create New Lesson',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text(
              'Save Draft',
              style: TextStyle(color: AppColors.richGold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Lesson Title',
                hintText: 'e.g., "Spanish Greetings for Dating"',
              ),
              style: const TextStyle(color: AppColors.pureWhite),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What will students learn?',
              ),
              style: const TextStyle(color: AppColors.pureWhite),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 24),

            // Language Selection
            const Text(
              'Target Language',
              style: TextStyle(
                color: AppColors.richGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(),
              dropdownColor: AppColors.charcoal,
              style: const TextStyle(color: AppColors.pureWhite),
              items: const [
                DropdownMenuItem(value: 'es', child: Text('Spanish')),
                DropdownMenuItem(value: 'fr', child: Text('French')),
                DropdownMenuItem(value: 'it', child: Text('Italian')),
                DropdownMenuItem(value: 'de', child: Text('German')),
                DropdownMenuItem(value: 'pt', child: Text('Portuguese')),
                DropdownMenuItem(value: 'ja', child: Text('Japanese')),
                DropdownMenuItem(value: 'ko', child: Text('Korean')),
                DropdownMenuItem(value: 'zh', child: Text('Chinese')),
              ],
              onChanged: (value) =>
                  setState(() => _selectedLanguage = value ?? 'es'),
            ),
            const SizedBox(height: 24),

            // Level Selection
            const Text(
              'Difficulty Level',
              style: TextStyle(
                color: AppColors.richGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: LessonLevel.values.take(4).map((level) {
                final isSelected = _selectedLevel == level;
                return ChoiceChip(
                  label: Text(level.displayName),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedLevel = level),
                  backgroundColor: AppColors.charcoal,
                  selectedColor: AppColors.richGold,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppColors.deepBlack : AppColors.pureWhite,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Category Selection
            const Text(
              'Category',
              style: TextStyle(
                color: AppColors.richGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LessonCategory.values.take(8).map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text('${category.emoji} ${category.displayName}'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  backgroundColor: AppColors.charcoal,
                  selectedColor: AppColors.richGold,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppColors.deepBlack : AppColors.pureWhite,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Add Content Button
            OutlinedButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add),
              label: const Text('Add Lesson Section'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.richGold,
                side: const BorderSide(color: AppColors.richGold),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _submitForReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Submit for Review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _addSection() {
    // Navigate to section editor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Section editor coming soon!'),
        backgroundColor: AppColors.infoBlue,
      ),
    );
  }

  void _submitForReview() {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.charcoal,
          title: const Text(
            'Submit for Review?',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          content: Text(
            'Your lesson will be reviewed by our team before it goes live. This usually takes 24-48 hours.',
            style: TextStyle(color: AppColors.pureWhite.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.pureWhite),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lesson submitted for review!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
    }
  }
}
