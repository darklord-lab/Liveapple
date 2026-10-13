import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../domain/models/store_models.dart';

class StoreRepository {
  final ApiClient _apiClient;

  StoreRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch offerings with optional search, filters, and sort
  Future<List<CourseOfferingModel>> getOfferings({
    String? search,
    String? batchId,
    bool? isFeatured,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? purchasedFilter,
  }) async {
    final queryParams = <String, dynamic>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (batchId != null && batchId.isNotEmpty) 'batchId': batchId,
      if (isFeatured != null) 'featured': isFeatured.toString(),
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (purchasedFilter != null && purchasedFilter.isNotEmpty) 'purchasedFilter': purchasedFilter,
    };

    final response = await _apiClient.dio.get(
      Endpoints.storeOfferings,
      queryParameters: queryParams,
    );

    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((item) => CourseOfferingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get single offering by ID
  Future<CourseOfferingModel> getOfferingById(String id) async {
    final response = await _apiClient.dio.get(Endpoints.storeOffering(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return CourseOfferingModel.fromJson(data);
  }

  /// Validate coupon code against offering
  Future<CouponValidationResult> validateCoupon(String code, String offeringId) async {
    final response = await _apiClient.dio.post(
      Endpoints.storeValidateCoupon,
      data: {
        'code': code.trim(),
        'offeringId': offeringId,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return CouponValidationResult.fromJson(data);
  }

  /// Initiate checkout (instant or order creation)
  Future<Map<String, dynamic>> checkout(
    String offeringId, {
    String? couponCode,
    String paymentMethod = 'MOCK',
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.storeCheckout,
      data: {
        'offeringId': offeringId,
        if (couponCode != null && couponCode.trim().isNotEmpty) 'couponCode': couponCode.trim(),
        'paymentMethod': paymentMethod,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Verify Razorpay payment signature
  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String offeringId,
    String? couponCode,
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.storeVerifyPayment,
      data: {
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'offeringId': offeringId,
        if (couponCode != null && couponCode.trim().isNotEmpty) 'couponCode': couponCode.trim(),
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// List user's purchases
  Future<List<PurchaseModel>> getPurchases() async {
    final response = await _apiClient.dio.get(Endpoints.storePurchases);
    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((item) => PurchaseModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Get detailed invoice
  Future<InvoiceModel> getInvoice(String purchaseId) async {
    final response = await _apiClient.dio.get(Endpoints.storeInvoice(purchaseId));
    final data = response.data['data'] as Map<String, dynamic>;
    return InvoiceModel.fromJson(data);
  }
}
