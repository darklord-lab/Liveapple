import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../domain/models/learning_models.dart';

class LearningRepository {
  final ApiClient _apiClient;

  LearningRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /* -------------------------------------------------------------------------- */
  /* RECORDINGS                                                                 */
  /* -------------------------------------------------------------------------- */
  Future<List<RecordingModel>> getRecordings({String? batchId}) async {
    final response = await _apiClient.dio.get(
      Endpoints.recordings,
      queryParameters: {
        if (batchId != null) 'batchId': batchId,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final list = data['recordings'] as List<dynamic>? ?? [];
    return list.map((item) => RecordingModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<RecordingModel> saveRecording({
    required String liveClassId,
    required String videoUrl,
    String? title,
    int? durationSec,
    double? fileSizeMb,
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.recordings,
      data: {
        'liveClassId': liveClassId,
        'videoUrl': videoUrl,
        if (title != null) 'title': title,
        if (durationSec != null) 'durationSec': durationSec,
        if (fileSizeMb != null) 'fileSizeMb': fileSizeMb,
      },
    );
    return RecordingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /* -------------------------------------------------------------------------- */
  /* ATTENDANCE                                                                 */
  /* -------------------------------------------------------------------------- */
  Future<void> joinLiveClass(String classId) async {
    await _apiClient.dio.post(Endpoints.attendanceJoin, data: {'classId': classId});
  }

  Future<void> leaveLiveClass(String classId) async {
    await _apiClient.dio.post(Endpoints.attendanceLeave, data: {'classId': classId});
  }

  Future<AttendanceSummaryModel> getMyAttendanceSummary() async {
    final response = await _apiClient.dio.get(Endpoints.attendanceMySummary);
    return AttendanceSummaryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AttendanceClassRosterModel> getClassRoster(String classId) async {
    final response = await _apiClient.dio.get('${Endpoints.attendanceClass}/$classId');
    return AttendanceClassRosterModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /* -------------------------------------------------------------------------- */
  /* ASSIGNMENTS                                                                */
  /* -------------------------------------------------------------------------- */
  Future<List<AssignmentModel>> getAssignments({String? batchId}) async {
    final response = await _apiClient.dio.get(
      Endpoints.assignments,
      queryParameters: {
        if (batchId != null) 'batchId': batchId,
      },
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((item) => AssignmentModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AssignmentModel> createAssignment({
    required String batchId,
    required String title,
    required String description,
    required DateTime dueDate,
    String? attachmentUrl,
    int maxMarks = 100,
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.assignments,
      data: {
        'batchId': batchId,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
        'maxMarks': maxMarks,
      },
    );
    return AssignmentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required String fileUrl,
  }) async {
    await _apiClient.dio.post(
      '${Endpoints.assignments}/$assignmentId/submit',
      data: {'fileUrl': fileUrl},
    );
  }

  Future<void> gradeSubmission({
    required String submissionId,
    required int marksObtained,
    String? feedback,
  }) async {
    await _apiClient.dio.patch(
      '${Endpoints.assignments}/submissions/$submissionId/grade',
      data: {
        'marksObtained': marksObtained,
        if (feedback != null) 'feedback': feedback,
      },
    );
  }

  /* -------------------------------------------------------------------------- */
  /* CBT TESTS                                                                  */
  /* -------------------------------------------------------------------------- */
  Future<List<CbtTestModel>> getTests({String? batchId}) async {
    final response = await _apiClient.dio.get(
      Endpoints.tests,
      queryParameters: {
        if (batchId != null) 'batchId': batchId,
      },
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((item) => CbtTestModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CbtTestModel> getTestDetails(String testId) async {
    final response = await _apiClient.dio.get('${Endpoints.tests}/$testId');
    return CbtTestModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CbtTestModel> createTest({
    required String batchId,
    required String title,
    String? description,
    int durationMin = 30,
    required List<Map<String, dynamic>> questions,
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.tests,
      data: {
        'batchId': batchId,
        'title': title,
        if (description != null) 'description': description,
        'durationMin': durationMin,
        'questions': questions,
      },
    );
    return CbtTestModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> startTest(String testId) async {
    await _apiClient.dio.post('${Endpoints.tests}/$testId/start');
  }

  Future<Map<String, dynamic>> submitTestAnswers({
    required String testId,
    required Map<String, String> answers,
  }) async {
    final response = await _apiClient.dio.post(
      '${Endpoints.tests}/$testId/submit',
      data: {'answers': answers},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /* -------------------------------------------------------------------------- */
  /* FEES & PAYMENTS                                                            */
  /* -------------------------------------------------------------------------- */
  Future<List<FeePlanModel>> getFeePlans({String? batchId}) async {
    final response = await _apiClient.dio.get(
      Endpoints.feePlans,
      queryParameters: {
        if (batchId != null) 'batchId': batchId,
      },
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((item) => FeePlanModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<FeePlanModel> createFeePlan({
    required String name,
    required double amount,
    String interval = 'MONTHLY',
    String? batchId,
    String? description,
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.feePlans,
      data: {
        'name': name,
        'amount': amount,
        'interval': interval,
        if (batchId != null) 'batchId': batchId,
        if (description != null) 'description': description,
      },
    );
    return FeePlanModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaymentReceiptModel> payFee({
    String? feePlanId,
    required double amount,
    String paymentMethod = 'UPI',
  }) async {
    final response = await _apiClient.dio.post(
      Endpoints.feePay,
      data: {
        if (feePlanId != null) 'feePlanId': feePlanId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      },
    );
    return PaymentReceiptModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StudentDuesModel> getMyDues() async {
    final response = await _apiClient.dio.get(Endpoints.feeDues);
    return StudentDuesModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getFinancialReport() async {
    final response = await _apiClient.dio.get(Endpoints.feeReports);
    return response.data['data'] as Map<String, dynamic>;
  }
}
