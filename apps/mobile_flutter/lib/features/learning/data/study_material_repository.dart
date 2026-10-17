import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../domain/models/study_material_model.dart';

class StudyMaterialRepository {
  final ApiClient _apiClient;

  StudyMaterialRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /* -------------------------------------------------------------------------- */
  /* FOLDERS                                                                    */
  /* -------------------------------------------------------------------------- */
  Future<List<MaterialFolderModel>> getFolders(String batchId, {String? parentId}) async {
    final response = await _apiClient.dio.get(
      Endpoints.batchFolders(batchId),
      queryParameters: {
        if (parentId != null) 'parentId': parentId,
      },
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((item) => MaterialFolderModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<MaterialFolderModel> createFolder(
    String batchId, {
    required String name,
    String? parentId,
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.batchFolders(batchId),
      data: {
        'name': name.trim(),
        if (parentId != null) 'parentId': parentId,
      },
    );
    return MaterialFolderModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteFolder(String folderId) async {
    await _apiClient.dio.delete(Endpoints.deleteFolder(folderId));
  }

  /* -------------------------------------------------------------------------- */
  /* MATERIALS                                                                  */
  /* -------------------------------------------------------------------------- */
  Future<StudyMaterialListResult> getMaterials(
    String batchId, {
    String? folderId,
    String? q,
    String? sort,
  }) async {
    final response = await _apiClient.dio.get(
      Endpoints.batchMaterials(batchId),
      queryParameters: {
        if (folderId != null) 'folderId': folderId,
        if (q != null && q.isNotEmpty) 'q': q,
        if (sort != null) 'sort': sort,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return StudyMaterialListResult.fromJson(data);
  }

  Future<StudyMaterialModel> uploadFileMaterial(
    String batchId, {
    required String title,
    String? description,
    String? folderId,
    bool isFree = false,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'title': title.trim(),
      if (description != null && description.isNotEmpty) 'description': description.trim(),
      if (folderId != null) 'folderId': folderId,
      'isFree': isFree.toString(),
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    final response = await _apiClient.dio.post(
      Endpoints.batchMaterials(batchId),
      data: formData,
    );
    return StudyMaterialModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StudyMaterialModel> addLinkMaterial(
    String batchId, {
    required String title,
    String? description,
    String? folderId,
    bool isFree = false,
    required String url,
    String? kind,
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.batchMaterials(batchId),
      data: {
        'title': title.trim(),
        if (description != null && description.isNotEmpty) 'description': description.trim(),
        if (folderId != null) 'folderId': folderId,
        'isFree': isFree,
        'url': url.trim(),
        if (kind != null) 'kind': kind,
      },
    );
    return StudyMaterialModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteMaterial(String materialId) async {
    await _apiClient.dio.delete(Endpoints.deleteMaterial(materialId));
  }

  Future<void> downloadFile(
    String materialId,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    await _apiClient.dio.download(
      Endpoints.downloadMaterial(materialId),
      savePath,
      onReceiveProgress: onProgress,
    );
  }
}
