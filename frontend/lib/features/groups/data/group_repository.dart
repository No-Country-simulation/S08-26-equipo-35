import '../../../core/network/api_client.dart';
import 'group.dart';
import 'group_detail.dart';

class GroupRepository {
  GroupRepository._();
  static final instance = GroupRepository._();

  Future<List<Group>> listGroups() async {
    final response = await ApiClient.get('/list', authenticated: true);
    final list = response as List<dynamic>;
    return list.map((item) => Group.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<GroupDetail> groupDetail(String groupId) async {
    final response = await ApiClient.get('/detail/$groupId', authenticated: true);
    return GroupDetail.fromJson(response as Map<String, dynamic>);
  }
}
