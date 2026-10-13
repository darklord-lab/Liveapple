import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/store_repository.dart';
import '../../domain/models/store_models.dart';

class StoreState {
  final bool isLoading;
  final bool isCheckingOut;
  final List<CourseOfferingModel> offerings;
  final List<PurchaseModel> purchases;
  final String searchQuery;
  final String selectedFilter; // 'ALL' | 'AVAILABLE' | 'PURCHASED' | 'FEATURED'
  final String sortOrder; // 'newest' | 'price_asc' | 'price_desc'
  final String? errorMessage;
  final Map<String, dynamic>? lastCheckoutResult;

  const StoreState({
    this.isLoading = false,
    this.isCheckingOut = false,
    this.offerings = const [],
    this.purchases = const [],
    this.searchQuery = '',
    this.selectedFilter = 'ALL',
    this.sortOrder = 'newest',
    this.errorMessage,
    this.lastCheckoutResult,
  });

  List<CourseOfferingModel> get featuredOfferings =>
      offerings.where((o) => o.isFeatured).toList();

  List<CourseOfferingModel> get filteredOfferings {
    var list = offerings;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((o) {
        final title = o.title.toLowerCase();
        final batch = (o.batchName ?? '').toLowerCase();
        final subject = (o.batchSubject ?? '').toLowerCase();
        return title.contains(q) || batch.contains(q) || subject.contains(q);
      }).toList();
    }

    if (selectedFilter == 'AVAILABLE') {
      list = list.where((o) => !o.isPurchased).toList();
    } else if (selectedFilter == 'PURCHASED') {
      list = list.where((o) => o.isPurchased).toList();
    } else if (selectedFilter == 'FEATURED') {
      list = list.where((o) => o.isFeatured).toList();
    }

    return list;
  }

  StoreState copyWith({
    bool? isLoading,
    bool? isCheckingOut,
    List<CourseOfferingModel>? offerings,
    List<PurchaseModel>? purchases,
    String? searchQuery,
    String? selectedFilter,
    String? sortOrder,
    String? errorMessage,
    Map<String, dynamic>? lastCheckoutResult,
  }) {
    return StoreState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      offerings: offerings ?? this.offerings,
      purchases: purchases ?? this.purchases,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      errorMessage: errorMessage,
      lastCheckoutResult: lastCheckoutResult,
    );
  }
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository();
});

final storeControllerProvider =
    StateNotifierProvider<StoreController, StoreState>((ref) {
  final repository = ref.watch(storeRepositoryProvider);
  return StoreController(repository: repository);
});

class StoreController extends StateNotifier<StoreState> {
  final StoreRepository _repository;

  StoreController({required StoreRepository repository})
      : _repository = repository,
        super(const StoreState()) {
    loadOfferings();
  }

  /// Load courses from API
  Future<void> loadOfferings({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final res = await _repository.getOfferings(
        sort: state.sortOrder,
      );
      state = state.copyWith(
        isLoading: false,
        offerings: res,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load previous purchases / invoices
  Future<void> loadPurchases() async {
    try {
      final res = await _repository.getPurchases();
      state = state.copyWith(purchases: res);
    } catch (e) {
      // Non-fatal
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSortOrder(String sort) {
    state = state.copyWith(sortOrder: sort);
    loadOfferings(showLoading: false);
  }

  /// Validate coupon code
  Future<CouponValidationResult> validateCoupon(String code, String offeringId) async {
    return _repository.validateCoupon(code, offeringId);
  }

  /// Checkout course offering
  Future<Map<String, dynamic>> checkoutCourse(
    String offeringId, {
    String? couponCode,
    String paymentMethod = 'MOCK',
  }) async {
    state = state.copyWith(isCheckingOut: true, errorMessage: null);
    try {
      final res = await _repository.checkout(
        offeringId,
        couponCode: couponCode,
        paymentMethod: paymentMethod,
      );

      // Optimistically update offering to purchased
      final updatedList = state.offerings.map((o) {
        if (o.id == offeringId) {
          return o.copyWith(isPurchased: true);
        }
        return o;
      }).toList();

      state = state.copyWith(
        isCheckingOut: false,
        offerings: updatedList,
        lastCheckoutResult: res,
      );

      // Reload purchases list
      loadPurchases();

      return res;
    } catch (e) {
      state = state.copyWith(
        isCheckingOut: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Fetch full invoice details
  Future<InvoiceModel> getInvoice(String purchaseId) async {
    return _repository.getInvoice(purchaseId);
  }
}
