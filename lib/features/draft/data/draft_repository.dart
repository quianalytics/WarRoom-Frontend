import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/api_list.dart';
import '../models/team.dart';
import '../models/draft_pick.dart';
import '../models/prospect.dart';

class DraftRepository {
  DraftRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  final Dio _dio;

  Future<List<Team>> fetchTeams() async {
    final res = await _dio.get('/teams');
    final parsed = ApiListResponse<Team>.fromJson(
      res.data as Map<String, dynamic>,
      (j) => Team.fromJson(j as Map<String, dynamic>),
    );
    return parsed.results;
  }

  Future<List<DraftPick>> fetchDraftOrder(int year) async {
    final res = await _dio.get('/draft/$year/picks');
    final parsed = ApiListResponse<DraftPick>.fromJson(
      res.data as Map<String, dynamic>,
      (j) => DraftPick.fromJson(j as Map<String, dynamic>),
    );
    return parsed.results;
  }

  Future<List<Prospect>> fetchProspects(int year) async {
    final res = await _dio.get('/prospects');
    final parsed = ApiListResponse<Prospect>.fromJson(
      res.data as Map<String, dynamic>,
      (j) => Prospect.fromJson(j as Map<String, dynamic>),
    );
    return parsed.results;
  }
}
