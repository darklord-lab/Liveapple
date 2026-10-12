import 'package:flutter_test/flutter_test.dart';
import 'package:classora_mobile/features/liveclass/domain/class_participant.dart';

void main() {
  group('C3 Live Classroom Participants Deduplication & Sorting', () {
    test('Deduplicates multiple connections from the same user identity and increments deviceCount', () {
      final rawList = [
        ClassParticipant(identity: 'u1', name: 'Aarav Patel', role: 'STUDENT'),
        ClassParticipant(identity: 'u1', name: 'Aarav Patel', role: 'STUDENT'),
        ClassParticipant(identity: 'u2', name: 'Priya Sharma', role: 'STUDENT'),
      ];

      final deduped = ClassParticipant.deduplicateAndSort(rawList);

      expect(deduped.length, 2);
      final aarav = deduped.firstWhere((p) => p.identity == 'u1');
      expect(aarav.name, 'Aarav Patel');
      expect(aarav.deviceCount, 2);
    });

    test('Sorts host first, then raised hands, then alphabetical by name', () {
      final rawList = [
        ClassParticipant(identity: 's1', name: 'Rohan Verma', role: 'STUDENT', isHost: false, isHandRaised: false),
        ClassParticipant(identity: 't1', name: 'Prof. Rajesh Sharma', role: 'TEACHER', isHost: true),
        ClassParticipant(identity: 's2', name: 'Isha Gupta', role: 'STUDENT', isHost: false, isHandRaised: true),
        ClassParticipant(identity: 's3', name: 'Aarav Patel', role: 'STUDENT', isHost: false, isHandRaised: false),
      ];

      final sorted = ClassParticipant.deduplicateAndSort(rawList);

      expect(sorted.length, 4);
      // 1. Host first
      expect(sorted[0].identity, 't1');
      expect(sorted[0].name, 'Prof. Rajesh Sharma');
      expect(sorted[0].isHost, true);

      // 2. Raised hands next
      expect(sorted[1].identity, 's2');
      expect(sorted[1].name, 'Isha Gupta');
      expect(sorted[1].isHandRaised, true);

      // 3. Alphabetical among remaining: Aarav Patel before Rohan Verma
      expect(sorted[2].identity, 's3');
      expect(sorted[2].name, 'Aarav Patel');

      expect(sorted[3].identity, 's1');
      expect(sorted[3].name, 'Rohan Verma');
    });

    test('Correctly computes participant initials', () {
      final p1 = ClassParticipant(identity: '1', name: 'Prof. Rajesh Sharma');
      final p2 = ClassParticipant(identity: '2', name: 'Aarav');
      final p3 = ClassParticipant(identity: '3', name: '');

      expect(p1.initials, 'PR');
      expect(p2.initials, 'A');
      expect(p3.initials, '?');
    });
  });
}
