import '../../../core/network/api_client.dart';
import 'group.dart';
import 'group_detail.dart';

class GroupRepository {
  GroupRepository._();
  static final instance = GroupRepository._();

  Future<List<Group>> listGroups() async {
    final response = await ApiClient.get('/list', authenticated: true);
    if (response is! List<dynamic>) {
      return [];
    }
    return response.map((item) => Group.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<GroupDetail> groupDetail(String groupId) async {
    final response = await ApiClient.get('/detail/$groupId', authenticated: true);
    return GroupDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<Group> createGroup(String name) async {
    final response = await ApiClient.post('/create', {'name': name}, authenticated: true);
    if (response['group_id'] == null) {
      throw ApiException(0, 'Respuesta inesperada del servidor.');
    }
    return Group.fromJson(response);
  }

  Future<void> updateGroupName(String groupId, String groupName) async {
    await ApiClient.patch('/$groupId', {'group_name': groupName}, authenticated: true);
  }
}
