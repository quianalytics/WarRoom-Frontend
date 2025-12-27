import 'package:dio/dio.dart';
import '../../../core/observability/error_reporter.dart';
import '../../../core/api/api_client.dart';
import '../models/api_list.dart';
import '../models/team.dart';
import '../models/draft_pick.dart';
import '../models/prospect.dart';
import '../models/team_needs.dart';

class DraftRepository {
  DraftRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  final Dio _dio;

  Future<List<Team>> fetchTeams() async {
    try {
      final res = await _dio.get('/teams');
      final parsed = ApiListResponse<Team>.fromJson(
        res.data as Map<String, dynamic>,
        (j) => Team.fromJson(j as Map<String, dynamic>),
      );
      return parsed.results;
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'DraftRepository.fetchTeams');
      rethrow;
    }
  }

  Future<Map<String, List<String>>> fetchTeamNeeds(int year) async {
    try {
      final res = await _dio.get('/teams/needs/$year');
      final parsed = ApiListResponse<TeamNeedsEntry>.fromJson(
        res.data as Map<String, dynamic>,
        (j) => TeamNeedsEntry.fromJson(j as Map<String, dynamic>),
      );
      return {
        for (final entry in parsed.results)
          entry.teamAbbr.toUpperCase(): entry.needs,
      };
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'DraftRepository.fetchTeamNeeds');
      rethrow;
    }
  }

  Future<List<DraftPick>> fetchDraftOrder(int year) async {
    try {
      final res = await _dio.get('/draft/$year/picks');
      final parsed = ApiListResponse<DraftPick>.fromJson(
        res.data as Map<String, dynamic>,
        (j) => DraftPick.fromJson(j as Map<String, dynamic>),
      );
      return parsed.results;
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'DraftRepository.fetchDraftOrder');
      rethrow;
    }
  }

  Future<List<Prospect>> fetchProspects(int year) async {
    try {
      final res = await _dio.get('/prospects');
      final parsed = ApiListResponse<Prospect>.fromJson(
        res.data as Map<String, dynamic>,
        (j) => Prospect.fromJson(j as Map<String, dynamic>),
      );
      return parsed.results;
    } catch (e, st) {
      ErrorReporter.report(e, st, context: 'DraftRepository.fetchProspects');
      rethrow;
    }
  }
}
