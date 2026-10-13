import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/study_material_repository.dart';
import '../../domain/models/study_material_model.dart';

class StudyMaterialState {
  final bool isLoading;
  final bool isUploading;
  final String? error;
  final String? currentBatchId;
  final List<MaterialFolderModel> folders;
  final List<StudyMaterialModel> materials;
  final MaterialFolderModel? currentFolder;
  final List<MaterialFolderModel> folderPath;
  final bool isEnrolled;
  final String searchQuery;
  final String sortOption;

  const StudyMaterialState({
    this.isLoading = false,
    this.isUploading = false,
    this.error,
    this.currentBatchId,
    this.folders = const [],
    this.materials = const [],
    this.currentFolder,
    this.folderPath = const [],
    this.isEnrolled = true,
    this.searchQuery = '',
    this.sortOption = 'newest',
  });

  StudyMaterialState copyWith({
    bool? isLoading,
    bool? isUploading,
    String? error,
    bool clearError = false,
    String? currentBatchId,
    List<MaterialFolderModel>? folders,
    List<StudyMaterialModel>? materials,
    MaterialFolderModel? currentFolder,
    bool clearFolder = false,
    List<MaterialFolderModel>? folderPath,
    bool? isEnrolled,
    String? searchQuery,
    String? sortOption,
  }) {
    return StudyMaterialState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
      currentBatchId: currentBatchId ?? this.currentBatchId,
      folders: folders ?? this.folders,
      materials: materials ?? this.materials,
      currentFolder: clearFolder ? null : (currentFolder ?? this.currentFolder),
      folderPath: folderPath ?? this.folderPath,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class StudyMaterialNotifier extends StateNotifier<StudyMaterialState> {
  final StudyMaterialRepository _repo;

  StudyMaterialNotifier({StudyMaterialRepository? repo})
      : _repo = repo ?? StudyMaterialRepository(),
        super(const StudyMaterialState());

  Future<void> loadBatch(
    String batchId, {
    String? folderId,
    bool resetFolder = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentBatchId: batchId,
      clearFolder: resetFolder,
      folderPath: resetFolder ? [] : null,
    );

    try {
      final targetFolderId = resetFolder ? null : (folderId ?? state.currentFolder?.id);

      // Load folders and materials in parallel
      final foldersFuture = _repo.getFolders(batchId, parentId: targetFolderId);
      final materialsFuture = _repo.getMaterials(
        batchId,
        folderId: targetFolderId,
        q: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        sort: state.sortOption,
      );

      final results = await Future.wait([foldersFuture, materialsFuture]);
      final folders = results[0] as List<MaterialFolderModel>;
      final matResult = results[1] as StudyMaterialListResult;

      state = state.copyWith(
        isLoading: false,
        folders: folders,
        materials: matResult.materials,
        isEnrolled: matResult.isEnrolled,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void openFolder(MaterialFolderModel folder) {
    final newPath = List<MaterialFolderModel>.from(state.folderPath)..add(folder);
    state = state.copyWith(
      currentFolder: folder,
      folderPath: newPath,
    );
    if (state.currentBatchId != null) {
      loadBatch(state.currentBatchId!, folderId: folder.id);
    }
  }

  void navigateUp() {
    if (state.folderPath.isEmpty) return;

    final newPath = List<MaterialFolderModel>.from(state.folderPath)..removeLast();
    final parent = newPath.isNotEmpty ? newPath.last : null;

    state = state.copyWith(
      currentFolder: parent,
      clearFolder: parent == null,
      folderPath: newPath,
    );

    if (state.currentBatchId != null) {
      loadBatch(state.currentBatchId!, folderId: parent?.id);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    if (state.currentBatchId != null) {
      loadBatch(state.currentBatchId!);
    }
  }

  void setSortOption(String sort) {
    state = state.copyWith(sortOption: sort);
    if (state.currentBatchId != null) {
      loadBatch(state.currentBatchId!);
    }
  }

  Future<bool> createFolder(String name) async {
    if (state.currentBatchId == null) return false;
    try {
      state = state.copyWith(isUploading: true, clearError: true);
      await _repo.createFolder(
        state.currentBatchId!,
        name: name,
        parentId: state.currentFolder?.id,
      );
      state = state.copyWith(isUploading: false);
      await loadBatch(state.currentBatchId!);
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadFile({
    required String title,
    String? description,
    bool isFree = false,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    if (state.currentBatchId == null) return false;
    try {
      state = state.copyWith(isUploading: true, clearError: true);
      await _repo.uploadFileMaterial(
        state.currentBatchId!,
        title: title,
        description: description,
        folderId: state.currentFolder?.id,
        isFree: isFree,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      state = state.copyWith(isUploading: false);
      await loadBatch(state.currentBatchId!);
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addLink({
    required String title,
    String? description,
    required String url,
    bool isFree = false,
    String? kind,
  }) async {
    if (state.currentBatchId == null) return false;
    try {
      state = state.copyWith(isUploading: true, clearError: true);
      await _repo.addLinkMaterial(
        state.currentBatchId!,
        title: title,
        description: description,
        folderId: state.currentFolder?.id,
        isFree: isFree,
        url: url,
        kind: kind,
      );
      state = state.copyWith(isUploading: false);
      await loadBatch(state.currentBatchId!);
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteMaterial(String materialId) async {
    try {
      await _repo.deleteMaterial(materialId);
      if (state.currentBatchId != null) {
        await loadBatch(state.currentBatchId!);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteFolder(String folderId) async {
    try {
      await _repo.deleteFolder(folderId);
      if (state.currentBatchId != null) {
        await loadBatch(state.currentBatchId!);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> downloadFile(String materialId, String savePath) async {
    await _repo.downloadFile(materialId, savePath);
  }
}

final studyMaterialProvider =
    StateNotifierProvider<StudyMaterialNotifier, StudyMaterialState>((ref) {
  return StudyMaterialNotifier();
});
