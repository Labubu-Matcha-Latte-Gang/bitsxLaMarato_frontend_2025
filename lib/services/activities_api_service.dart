import '../models/activity_models.dart';
import 'api_service.dart';

class ActivitiesApiService {
  const ActivitiesApiService();

  Future<List<Activity>> fetchRecommendedActivities() async {
    try {
      final activity = await ApiService.getRecommendedActivity();
      if (activity.id.isEmpty && activity.title.isEmpty) {
        return [];
      }
      return [activity];
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Activity>> searchActivities({
    String? query,
    String? type,
    double? difficulty,
    double? difficultyMin,
    double? difficultyMax,
    String? id,
    String? title,
  }) async {
    try {
      final params = ActivityQueryParams(
        id: id,
        title: title,
        activityType: type,
        difficulty: difficulty,
        difficultyMin: difficultyMin,
        difficultyMax: difficultyMax,
        search: query,
      );

      return ApiService.listActivities(query: params);
    } catch (_) {
      rethrow;
    }
  }
}
