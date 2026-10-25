import 'observation.dart';

abstract class ObservationRepository {
  Future<ObservationPage> listBySession({
    required int testSessionId,
    int page,
    int pageSize,
  });

  Future<CounselorObservation> latestForSession(int testSessionId);

  Future<CounselorObservation> create(ObservationDraft draft);
}
