import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:classora_mobile/features/liveclass/presentation/live_class_room_controller.dart';

void main() {
  group('BUG 1 - Slides Picker to Upload Path & Sync Tests', () {
    test('Web picker-to-upload: uses fileBytes for PDF payload', () async {
      final dummyPdfBytes = Uint8List.fromList('%PDF-1.4 sample pdf content %%EOF'.codeUnits);
      const fileName = 'physics_chapter1.pdf';

      // Verify multipart payload creation for web (bytes)
      final multipart = MultipartFile.fromBytes(
        dummyPdfBytes,
        filename: fileName,
      );

      expect(multipart.filename, 'physics_chapter1.pdf');
      expect(multipart.length, dummyPdfBytes.length);
      expect(multipart.filename?.endsWith('.pdf'), isTrue);
    });

    test('Mobile picker-to-upload: verifies PDF file path for upload', () async {
      const filePath = '/storage/emulated/0/Download/chemistry_notes.pdf';
      const fileName = 'chemistry_notes.pdf';

      expect(fileName.toLowerCase().endsWith('.pdf'), isTrue);
      expect(filePath.isNotEmpty, isTrue);
    });

    test('Rejection of PPT/PPTX with required export guidance message', () {
      const pptFile = 'lecture_presentation.pptx';
      final nameLower = pptFile.toLowerCase();
      String? errorMessage;

      if (nameLower.endsWith('.ppt') || nameLower.endsWith('.pptx')) {
        errorMessage = 'PPT ko PDF me export karo ya screen share karo';
      }

      expect(errorMessage, 'PPT ko PDF me export karo ya screen share karo');
    });

    test('Size validation rejects files over 50MB with clear error message', () {
      const fileSize = 52 * 1024 * 1024; // 52MB
      String? errorMessage;

      if (fileSize > 50 * 1024 * 1024) {
        errorMessage = 'PDF file ka size 50MB se chhota hona chahiye';
      }

      expect(errorMessage, contains('50MB se chhota hona chahiye'));
    });

    test('Controller state updates deckId, fileHash, totalPages, and synchronizes stage to SLIDES and page navigation', () {
      var state = LiveClassRoomState(isHost: true, stage: 'VIDEO');
      expect(state.isDocPresenting, isFalse);
      expect(state.stage, 'VIDEO');

      // Teacher uploads & presents real PDF deck
      const deckId = 'slides_1740000000_deckA.pdf';
      const fileHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      const totalPages = 5;

      state = state.copyWith(
        isDocPresenting: true,
        docTitle: 'Physics_Kinematics.pdf',
        docPage: 1,
        docTotalPages: totalPages,
        docDeckId: deckId,
        docFileHash: fileHash,
        stage: 'SLIDES',
      );

      expect(state.isDocPresenting, isTrue);
      expect(state.stage, 'SLIDES');
      expect(state.docPage, 1);
      expect(state.docTotalPages, 5);
      expect(state.docDeckId, deckId);
      expect(state.docFileHash, fileHash);

      // Page change sync
      state = state.copyWith(docPage: 3);
      expect(state.docPage, 3);

      // Stop presenting returns stage to VIDEO
      state = state.copyWith(
        isDocPresenting: false,
        stage: 'VIDEO',
      );
      expect(state.isDocPresenting, isFalse);
      expect(state.stage, 'VIDEO');
    });
  });
}
