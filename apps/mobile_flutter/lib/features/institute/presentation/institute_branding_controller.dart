import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../auth/domain/user_model.dart';
import '../data/institute_content_repository.dart';
import '../domain/institute_branding_model.dart';
import '../domain/institute_link_model.dart';

class InstituteBrandingState {
  final bool isLoading;
  final bool isSaving;
  final InstituteBrandingModel branding;
  final List<InstituteLinkModel> links;
  final String? error;
  final String? successMessage;

  const InstituteBrandingState({
    this.isLoading = false,
    this.isSaving = false,
    required this.branding,
    this.links = const [],
    this.error,
    this.successMessage,
  });

  InstituteBrandingState copyWith({
    bool? isLoading,
    bool? isSaving,
    InstituteBrandingModel? branding,
    List<InstituteLinkModel>? links,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return InstituteBrandingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      branding: branding ?? this.branding,
      links: links ?? this.links,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class InstituteBrandingController extends StateNotifier<InstituteBrandingState> {
  final InstituteContentRepository _repository;
  final SecureStorageService _storage;

  InstituteBrandingController({
    InstituteContentRepository? repository,
    SecureStorageService? storage,
    bool autoInitialize = true,
  })  : _repository = repository ?? InstituteContentRepository(),
        _storage = storage ?? SecureStorageService(),
        super(InstituteBrandingState(branding: InstituteBrandingModel.defaultBranding())) {
    if (autoInitialize) {
      _initializeBranding();
    }
  }

  Future<void> _initializeBranding() async {
    try {
      final cachedJson = await _storage.getInstituteBranding();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final cached = InstituteBrandingModel.deserialize(cachedJson);
        if (cached != null) {
          state = state.copyWith(branding: cached);
        }
      }
    } catch (_) {}
  }

  /// Synchronize branding from currently authenticated user
  Future<void> syncFromUser(UserModel user) async {
    if (user.institute != null) {
      final userInst = user.institute!;
      final updated = state.branding.copyWith(
        id: userInst.id,
        name: userInst.name,
        slug: userInst.slug,
        code: userInst.code ?? state.branding.code,
        logoUrl: userInst.logoUrl,
        primaryColor: userInst.primaryColor ?? state.branding.primaryColor,
        tagline: userInst.tagline,
      );
      state = state.copyWith(branding: updated);
      await _storage.saveInstituteBranding(updated.serialize());
      if (updated.code != null && updated.code!.isNotEmpty) {
        await _storage.saveInstituteCode(updated.code!);
      }
    }
  }

  /// Verify and apply a code entered by the student / user
  Future<bool> applyCode(String code) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final result = await _repository.lookupInstitute(code);
      final verifiedBranding = result['institute'] as InstituteBrandingModel;
      final links = result['links'] as List<InstituteLinkModel>;

      state = state.copyWith(
        isLoading: false,
        branding: verifiedBranding,
        links: links,
        successMessage: 'Connected to ${verifiedBranding.name}!',
      );

      // Persist locally
      await _storage.saveInstituteCode(verifiedBranding.effectiveCode);
      await _storage.saveInstituteBranding(verifiedBranding.serialize());
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Fetch authenticated branding from server
  Future<void> loadServerBranding() async {
    try {
      final branding = await _repository.getBranding();
      state = state.copyWith(branding: branding);
      await _storage.saveInstituteBranding(branding.serialize());
      if (branding.code != null) {
        await _storage.saveInstituteCode(branding.code!);
      }
    } catch (_) {}
  }

  /// Admin updates white-label branding details
  Future<bool> updateBranding({
    String? name,
    String? code,
    String? logoUrl,
    String? primaryColor,
    String? tagline,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final updated = await _repository.updateBranding(
        name: name,
        code: code,
        logoUrl: logoUrl,
        primaryColor: primaryColor,
        tagline: tagline,
      );

      state = state.copyWith(
        isSaving: false,
        branding: updated,
        successMessage: 'Branding updated successfully!',
      );

      await _storage.saveInstituteBranding(updated.serialize());
      if (updated.code != null) {
        await _storage.saveInstituteCode(updated.code!);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearFeedback() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final instituteBrandingProvider =
    StateNotifierProvider<InstituteBrandingController, InstituteBrandingState>((ref) {
  return InstituteBrandingController();
});
