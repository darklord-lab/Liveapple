import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/features/learning/domain/models/study_material_model.dart';

void main() {
  group('Study Material Model Suite', () {
    test('MaterialFolderModel parsing', () {
      final json = {
        'id': 'folder-1',
        'batchId': 'batch-101',
        'name': 'Chapter 1: Optics',
        'parentId': null,
        'createdAt': '2026-10-13T10:00:00.000Z',
        '_count': {
          'materials': 5,
          'children': 2,
        },
      };

      final folder = MaterialFolderModel.fromJson(json);

      expect(folder.id, 'folder-1');
      expect(folder.batchId, 'batch-101');
      expect(folder.name, 'Chapter 1: Optics');
      expect(folder.materialsCount, 5);
      expect(folder.childrenCount, 2);
    });

    test('StudyMaterialModel parsing & formatted getters', () {
      final json = {
        'id': 'mat-1',
        'batchId': 'batch-101',
        'folderId': 'folder-1',
        'title': 'Wave Optics Lecture Notes.pdf',
        'description': 'Handwritten notes',
        'kind': 'PDF',
        'fileName': 'Wave_Optics.pdf',
        'sizeBytes': 2500000, // ~2.4 MB
        'isFree': true,
        'uploadedById': 'teacher-1',
        'uploadedBy': {'name': 'Prof. Rajesh'},
        'folder': {'name': 'Chapter 1: Optics'},
        'createdAt': '2026-10-13T10:30:00.000Z',
      };

      final material = StudyMaterialModel.fromJson(json);

      expect(material.id, 'mat-1');
      expect(material.title, 'Wave Optics Lecture Notes.pdf');
      expect(material.isPdf, true);
      expect(material.isFree, true);
      expect(material.uploadedByName, 'Prof. Rajesh');
      expect(material.folderName, 'Chapter 1: Optics');
      expect(material.formattedSize, '2.4 MB');
    });

    test('StudyMaterialModel video link parsing', () {
      final json = {
        'id': 'mat-2',
        'batchId': 'batch-101',
        'title': 'Optics Animation Video',
        'kind': 'VIDEO_LINK',
        'url': 'https://youtube.com/watch?v=123',
        'isFree': false,
        'uploadedById': 'teacher-1',
        'createdAt': '2026-10-13T11:00:00.000Z',
      };

      final material = StudyMaterialModel.fromJson(json);

      expect(material.isVideo, true);
      expect(material.isLink, true);
      expect(material.isFree, false);
      expect(material.formattedSize, '');
    });

    test('StudyMaterialListResult parsing', () {
      final json = {
        'isEnrolled': false,
        'materials': [
          {
            'id': 'mat-free',
            'batchId': 'batch-101',
            'title': 'Sample Sheet',
            'kind': 'PDF',
            'isFree': true,
            'uploadedById': 'teacher-1',
            'createdAt': '2026-10-13T11:00:00.000Z',
          }
        ],
      };

      final result = StudyMaterialListResult.fromJson(json);

      expect(result.isEnrolled, false);
      expect(result.materials.length, 1);
      expect(result.materials.first.isFree, true);
    });
  });
}
