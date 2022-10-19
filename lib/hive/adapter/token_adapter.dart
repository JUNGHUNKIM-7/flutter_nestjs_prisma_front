import 'package:hive/hive.dart';

part 'token_adapter.g.dart';

@HiveType(typeId: 1)
class HiveTokens {
  @HiveField(0)
  String? at;

  @HiveField(1)
  String? rt;

  @HiveField(2)
  String? updatedAt;
}
