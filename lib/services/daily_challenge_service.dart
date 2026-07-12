import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/question.dart';
import 'auth_service.dart';

class DailyChallengeStatus {
  const DailyChallengeStatus({
    required this.canPlayToday,
    required this.currentStreak,
    required this.target,
    required this.rewardsGranted,
    required this.creditBalance,
    required this.distribution,
    required this.timeline,
  });

  final bool canPlayToday;
  final int currentStreak;
  final int target;
  final int rewardsGranted;
  final int creditBalance;
  final Map<String, int> distribution;
  final List<Map<String, dynamic>> timeline;

  factory DailyChallengeStatus.fromJson(Map<String, dynamic> json) {
    final distRaw = (json['difficulty_distribution'] as Map<String, dynamic>?) ?? const {};
    final timelineRaw = (json['timeline'] as List<dynamic>?) ?? const [];

    return DailyChallengeStatus(
      canPlayToday: json['can_play_today'] as bool? ?? false,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 10,
      rewardsGranted: (json['rewards_granted'] as num?)?.toInt() ?? 0,
      creditBalance: (json['credit_balance'] as num?)?.toInt() ?? 0,
      distribution: {
        'easy': (distRaw['easy'] as num?)?.toInt() ?? 0,
        'medium': (distRaw['medium'] as num?)?.toInt() ?? 0,
        'hard': (distRaw['hard'] as num?)?.toInt() ?? 0,
      },
      timeline: timelineRaw
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
    );
  }
}

class DailyChallengeQuiz {
  const DailyChallengeQuiz({
    required this.questions,
  });

  final List<Question> questions;

  factory DailyChallengeQuiz.fromJson(Map<String, dynamic> json) {
    final list = (json['questions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Question.fromJson)
        .toList(growable: false);
    return DailyChallengeQuiz(questions: list);
  }
}

class DailyChallengeCompletion {
  const DailyChallengeCompletion({
    required this.rewardGranted,
    required this.currentStreak,
    required this.target,
    required this.newCreditBalance,
    required this.rewardsGranted,
  });

  final bool rewardGranted;
  final int currentStreak;
  final int target;
  final int newCreditBalance;
  final int rewardsGranted;

  factory DailyChallengeCompletion.fromJson(Map<String, dynamic> json) {
    return DailyChallengeCompletion(
      rewardGranted: json['reward_granted'] as bool? ?? false,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 10,
      newCreditBalance: (json['new_credit_balance'] as num?)?.toInt() ?? 0,
      rewardsGranted: (json['rewards_granted'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyChallengeService {
  DailyChallengeService({required this.authService});

  final AuthService authService;
  final String baseUrl = ApiConfig.baseUrl;

  Future<http.Response> _authorizedGet(String url) async {
    final headers = await authService.getAuthHeaders();
    http.Response response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(
          ApiConfig.connectionTimeout,
          onTimeout: () => throw Exception('Connection timeout'),
        );

    if (response.statusCode == 401) {
      final refreshed = await authService.refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await authService.getAuthHeaders();
        response = await http
            .get(Uri.parse(url), headers: retryHeaders)
            .timeout(
              ApiConfig.connectionTimeout,
              onTimeout: () => throw Exception('Connection timeout'),
            );
      }
    }

    return response;
  }

  Future<http.Response> _authorizedPost(String url, Map<String, dynamic> payload) async {
    final headers = await authService.getAuthHeaders();
    http.Response response = await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(payload))
        .timeout(
          ApiConfig.connectionTimeout,
          onTimeout: () => throw Exception('Connection timeout'),
        );

    if (response.statusCode == 401) {
      final refreshed = await authService.refreshAccessToken();
      if (refreshed) {
        final retryHeaders = await authService.getAuthHeaders();
        response = await http
            .post(Uri.parse(url), headers: retryHeaders, body: jsonEncode(payload))
            .timeout(
              ApiConfig.connectionTimeout,
              onTimeout: () => throw Exception('Connection timeout'),
            );
      }
    }

    return response;
  }

  Future<DailyChallengeStatus> getStatus() async {
    final response = await _authorizedGet('$baseUrl${ApiConfig.dailyChallengeStatusEndpoint}');
    if (response.statusCode != 200) {
      throw Exception('Failed to load daily challenge status: ${response.statusCode}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    return DailyChallengeStatus.fromJson(body);
  }

  Future<DailyChallengeQuiz> getQuestions() async {
    final response = await _authorizedPost('$baseUrl${ApiConfig.dailyChallengeQuestionsEndpoint}', const {});
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['error']?.toString() ?? 'Failed to load daily challenge questions');
    }
    return DailyChallengeQuiz.fromJson(body);
  }

  Future<DailyChallengeCompletion> complete({required List<int> answers}) async {
    final response = await _authorizedPost(
      '$baseUrl${ApiConfig.dailyChallengeCompleteEndpoint}',
      <String, dynamic>{'answers': answers},
    );
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(body['error']?.toString() ?? 'Failed to complete daily challenge');
    }
    return DailyChallengeCompletion.fromJson(body);
  }
}
