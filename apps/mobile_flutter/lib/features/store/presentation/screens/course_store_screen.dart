import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/filter_sort_sheet.dart';
import '../../domain/models/store_models.dart';
import '../controllers/store_controller.dart';
import '../widgets/checkout_modal_sheet.dart';
import '../widgets/invoice_dialog.dart';

class CourseStoreScreen extends ConsumerStatefulWidget {
  const CourseStoreScreen({super.key});

  @override
  ConsumerState<CourseStoreScreen> createState() => _CourseStoreScreenState();
}

class _CourseStoreScreenState extends ConsumerState<CourseStoreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSortSheet(StoreState state) async {
    final selection = await showFilterSortSheet<String>(
      context: context,
      title: 'Filter & Sort Courses',
      filters: [
        FilterConfig<String>(
          id: 'status',
          title: 'Course Availability',
          options: [
            FilterItem(
              value: 'ALL',
              label: 'All Courses',
              count: state.offerings.length,
            ),
            FilterItem(
              value: 'AVAILABLE',
              label: 'Available to Enroll',
              count: state.offerings.where((o) => !o.isPurchased).length,
            ),
            FilterItem(
              value: 'PURCHASED',
              label: 'Already Enrolled',
              count: state.offerings.where((o) => o.isPurchased).length,
            ),
            FilterItem(
              value: 'FEATURED',
              label: 'Featured Courses',
              count: state.offerings.where((o) => o.isFeatured).length,
            ),
          ],
          initialValue: state.selectedFilter,
          defaultValue: 'ALL',
        ),
      ],
      sort: SortConfig<String>(
        title: 'Sort By',
        options: const [
          SortOptionItem(value: 'newest', label: 'Newest First', icon: Icons.schedule_rounded),
          SortOptionItem(value: 'price_asc', label: 'Price: Low to High', icon: Icons.arrow_upward_rounded),
          SortOptionItem(value: 'price_desc', label: 'Price: High to Low', icon: Icons.arrow_downward_rounded),
        ],
        initialValue: state.sortOrder,
        defaultValue: 'newest',
      ),
    );

    if (selection != null) {
      final notifier = ref.read(storeControllerProvider.notifier);
      notifier.setFilter(selection.getFilter('status', 'ALL'));
      if (selection.sortValue != null) {
        notifier.setSortOrder(selection.sortValue!);
      }
    }
  }

  void _showPurchasesSheet() {
    ref.read(storeControllerProvider.notifier).loadPurchases();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(storeControllerProvider);

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.skyBlue, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Purchase Receipts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.slate500, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderLight, height: 1),
                Expanded(
                  child: state.purchases.isEmpty
                      ? const Center(
                          child: Text(
                            'No purchase receipts yet.',
                            style: TextStyle(color: AppColors.textMutedLight),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.purchases.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final purchase = state.purchases[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          purchase.courseTitle ?? 'Course Package',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Invoice: ${purchase.invoiceNo}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Amount: ₹${purchase.amount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.skyBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final invoice = await ref
                                            .read(storeControllerProvider.notifier)
                                            .getInvoice(purchase.id);
                                        if (context.mounted) {
                                          InvoiceDialog.show(context, invoice);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to load invoice: $e')),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.skyBlue,
                                      side: const BorderSide(color: AppColors.skyBlue),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: const Size(60, 36),
                                    ),
                                    child: const Text('View Receipt', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeControllerProvider);
    final notifier = ref.read(storeControllerProvider.notifier);

    // Active filters
    final activeChips = <ActiveFilterChipData>[];
    if (state.selectedFilter != 'ALL') {
      final label = state.selectedFilter == 'AVAILABLE'
          ? 'Available to Enroll'
          : state.selectedFilter == 'PURCHASED'
              ? 'Enrolled'
              : 'Featured';
      activeChips.add(
        ActiveFilterChipData(
          label: label,
          onRemoved: () => notifier.setFilter('ALL'),
        ),
      );
    }
    if (state.sortOrder != 'newest') {
      final label = state.sortOrder == 'price_asc'
          ? 'Price: Low to High'
          : 'Price: High to Low';
      activeChips.add(
        ActiveFilterChipData(
          label: label,
          onRemoved: () => notifier.setSortOrder('newest'),
        ),
      );
    }

    final courses = state.filteredOfferings;
    final featuredCourses = state.featuredOfferings;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.skyBlue,
        elevation: 0,
        title: const Text(
          'Course Store',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
            tooltip: 'My Receipts',
            onPressed: _showPurchasesSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.skyBlue,
        onRefresh: () => notifier.loadOfferings(showLoading: false),
        child: CustomScrollView(
          slivers: [
            // Search & Filter header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: notifier.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search courses, batches...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
                            prefixIcon: const Icon(Icons.search, color: AppColors.slate500, size: 20),
                            suffixIcon: state.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: AppColors.slate500),
                                    onPressed: () {
                                      _searchController.clear();
                                      notifier.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilterBadgeButton(
                      activeCount: (state.selectedFilter != 'ALL' ? 1 : 0) +
                          (state.sortOrder != 'newest' ? 1 : 0),
                      onPressed: () => _openFilterSortSheet(state),
                    ),
                  ],
                ),
              ),
            ),

            // Active filters bar
            if (activeChips.isNotEmpty)
              SliverToBoxAdapter(
                child: ActiveFiltersBar(
                  chips: activeChips,
                  onClearAll: () {
                    notifier.setFilter('ALL');
                    notifier.setSortOrder('newest');
                  },
                ),
              ),

            // Featured Carousel Banner
            if (featuredCourses.isNotEmpty && state.selectedFilter != 'PURCHASED')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, color: AppColors.warning, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Featured Courses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: featuredCourses.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final course = featuredCourses[index];
                            return _buildFeaturedCard(context, course);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // All Courses list header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Courses (${courses.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ),

            // Content: Loading, Empty, or List
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.skyBlue)),
              )
            else if (courses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.storefront_outlined, size: 32, color: AppColors.slate400),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No courses found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try adjusting your search or filters.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedLight),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchQuery('');
                            notifier.setFilter('ALL');
                            notifier.setSortOrder('newest');
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.skyBlue),
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final course = courses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCourseCard(context, course),
                      );
                    },
                    childCount: courses.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, CourseOfferingModel course) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0A9BE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0A9BE8),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HOT DEAL',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (course.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${course.discountPercent}% OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            course.batchName ?? 'Classroom',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      '₹${course.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (course.hasDiscount)
                      Text(
                        '₹${course.mrp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () {
                  if (course.isPurchased) {
                    context.push('/batches/${course.batchId}');
                  } else {
                    CheckoutModalSheet.show(context, offering: course);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.skyBlueDark,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  course.isPurchased ? 'View' : 'Enroll',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseOfferingModel course) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: course.isPurchased ? AppColors.success.withValues(alpha: 0.3) : AppColors.borderLight,
          width: course.isPurchased ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badges row
          Row(
            children: [
              if (course.batchSubject != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.batchSubject!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.skyBlueDark,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (course.isFeatured) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const Spacer(),
              if (course.hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${course.discountPercent}% OFF',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Course Title
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),

          if (course.batchName != null) ...[
            const SizedBox(height: 3),
            Text(
              'Batch: ${course.batchName!}${course.teacherName != null ? " • ${course.teacherName}" : ""}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
            ),
          ],

          if (course.description != null && course.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              course.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.3),
            ),
          ],

          const SizedBox(height: 12),

          // Features pill row
          const Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_rounded, size: 14, color: AppColors.liveRed),
                  SizedBox(width: 4),
                  Text('Live Classes', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 14, color: AppColors.skyBlue),
                  SizedBox(width: 4),
                  Text('Notes & Material', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined, size: 14, color: AppColors.tileRecordings),
                  SizedBox(width: 4),
                  Text('CBT Tests', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.borderLight, height: 1),
          ),

          // Price & Action Button Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          '₹${course.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        if (course.hasDiscount)
                          Text(
                            '₹${course.mrp.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    if (course.hasDiscount)
                      Text(
                        'Save ₹${(course.mrp - course.price).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (course.isPurchased)
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to batch study view
                    context.push('/batches/${course.batchId}');
                  },
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  label: const Text('Enrolled ✓'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    CheckoutModalSheet.show(context, offering: course);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('ENROLL NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
