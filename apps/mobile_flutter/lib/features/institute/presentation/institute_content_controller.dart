import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../data/institute_content_repository.dart';
import '../domain/institute_link_model.dart';
import '../domain/testimonial_model.dart';

/* -------------------------------------------------------------------------- */
/* REPOSITORY PROVIDER                                                        */
/* -------------------------------------------------------------------------- */
final instituteContentRepositoryProvider = Provider<InstituteContentRepository>((ref) {
  return InstituteContentRepository();
});

/* -------------------------------------------------------------------------- */
/* INSTITUTE LINKS STATE & NOTIFIER                                           */
/* -------------------------------------------------------------------------- */
class InstituteLinksState {
  final List<InstituteLinkModel> links;
  final bool isLoading;
  final String? errorMessage;

  const InstituteLinksState({
    this.links = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  InstituteLinksState copyWith({
    List<InstituteLinkModel>? links,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InstituteLinksState(
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class InstituteLinksNotifier extends StateNotifier<InstituteLinksState> {
  final InstituteContentRepository _repo;

  InstituteLinksNotifier(this._repo) : super(const InstituteLinksState());

  Future<void> loadLinks({bool all = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getLinks(all: all);
      state = state.copyWith(links: list, isLoading: false);
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<bool> createLink({
    required String title,
    required String platform,
    required String url,
    String? icon,
    int? order,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await _repo.createLink(
        title: title,
        platform: platform,
        url: url,
        icon: icon,
        order: order,
        isActive: isActive,
      );
      state = state.copyWith(
        links: [...state.links, created],
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> updateLink(
    String id, {
    String? title,
    String? platform,
    String? url,
    String? icon,
    int? order,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repo.updateLink(
        id,
        title: title,
        platform: platform,
        url: url,
        icon: icon,
        order: order,
        isActive: isActive,
      );
      state = state.copyWith(
        links: state.links.map((l) => l.id == id ? updated : l).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> deleteLink(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.deleteLink(id);
      state = state.copyWith(
        links: state.links.where((l) => l.id != id).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }
}

final instituteLinksProvider =
    StateNotifierProvider<InstituteLinksNotifier, InstituteLinksState>((ref) {
  final repo = ref.watch(instituteContentRepositoryProvider);
  return InstituteLinksNotifier(repo);
});

/* -------------------------------------------------------------------------- */
/* TESTIMONIALS STATE & NOTIFIER                                              */
/* -------------------------------------------------------------------------- */
class TestimonialsState {
  final List<TestimonialModel> testimonials;
  final bool isLoading;
  final String? errorMessage;

  const TestimonialsState({
    this.testimonials = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TestimonialsState copyWith({
    List<TestimonialModel>? testimonials,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TestimonialsState(
      testimonials: testimonials ?? this.testimonials,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TestimonialsNotifier extends StateNotifier<TestimonialsState> {
  final InstituteContentRepository _repo;

  TestimonialsNotifier(this._repo) : super(const TestimonialsState());

  Future<void> loadTestimonials({bool all = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getTestimonials(all: all);
      state = state.copyWith(testimonials: list, isLoading: false);
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  Future<bool> createTestimonial({
    required String studentName,
    String? batchOrExam,
    required String quote,
    String? avatarUrl,
    int? rating,
    int? order,
    bool? isPublished,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final created = await _repo.createTestimonial(
        studentName: studentName,
        batchOrExam: batchOrExam,
        quote: quote,
        avatarUrl: avatarUrl,
        rating: rating,
        order: order,
        isPublished: isPublished,
      );
      state = state.copyWith(
        testimonials: [created, ...state.testimonials],
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> updateTestimonial(
    String id, {
    String? studentName,
    String? batchOrExam,
    String? quote,
    String? avatarUrl,
    int? rating,
    int? order,
    bool? isPublished,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repo.updateTestimonial(
        id,
        studentName: studentName,
        batchOrExam: batchOrExam,
        quote: quote,
        avatarUrl: avatarUrl,
        rating: rating,
        order: order,
        isPublished: isPublished,
      );
      state = state.copyWith(
        testimonials: state.testimonials.map((t) => t.id == id ? updated : t).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> deleteTestimonial(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.deleteTestimonial(id);
      state = state.copyWith(
        testimonials: state.testimonials.where((t) => t.id != id).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }
}

final testimonialsProvider =
    StateNotifierProvider<TestimonialsNotifier, TestimonialsState>((ref) {
  final repo = ref.watch(instituteContentRepositoryProvider);
  return TestimonialsNotifier(repo);
});
