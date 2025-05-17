import 'package:dio/dio.dart';
import 'package:rxflare/rxflare.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(baseUrl: 'http://127.0.0.1:9091', connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10), headers: {'Content-Type': 'application/json'}),
  );

  static Future<List<dynamic>> fetchStoreRankings() async {
    try {
      final response = await _dio.get('/store-rankings');
      return response.data;
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      // final response = await _dio.post('/login', data: {
      //   'username': username,
      //   'password': password,
      // });
      // return response.data;
      Map<String, dynamic> myMap = {};

      myMap['token'] = 'ok';
      return myMap;
    } catch (e) {
      print('Login failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchUserInfo() async {
    try {
      final response = await _dio.post('/api/user/info');
      return response.data;
      // final data =
      //     '{code: 0, data: [{age: 21, birthday: 2000/4/5, cardid: 110119118117221, id: 1, phone: 138000000, xm: 张三}, {age: 90, birthday: 2025/9/2, cardid: 119119118228112, id: 2, phone: 13900000000, xm: 李四}, {age: 45, birthday: 2022/2/2, cardid: 119808678903, id: 3, phone: 13200000000, xm: 王二麻子}], msg: succ}';

      // return data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<void> fetchTodayYifuInfo() async {
    try {
      final response = await _dio.post('/api/server/yifuinfo', data: {'today': '20250516'});
      // {code: 0, data: [{cardid: 80203, cardname: 七折卡, count: 2, id: 1, name: 李艾想, payed: 未付, pdid: 21736, phone: 138000000, price: 165.0}, {cardid: 80922, cardname: 八折卡, count: 9, id: 2, name: 王女士, payed: 刷卡, pdid: 21735, phone: 1390000000, price: 200.0}], msg: succ}
      final data = response.data as Map<String, dynamic>;

      RxSimpleEvent.executeEvent(1001, data);
    } catch (e) {}
  }

  static Future<void> yifuInfoDetail(int pdid) async {
    try {
      final response = await _dio.post('/api/server/yifuinfodetail', data: {'pdid': pdid});
      //  {code: 0, data: [{color: 浅色, guayihao: 453, id: 1, memo: 油渍划伤, name: 羽绒马甲, pdid: 21736, region: 输送, server: 普洗, 条码号: 248173}, {color: 黑色, guayihao: 445, id: 2, memo: 油渍, name: 羽绒上衣, pdid: 21736, region: 输送线, server: 精洗, 条码号: 248174}], msg: succ}
      final data = response.data as Map<String, dynamic>;

      print("发射--------------》");
      RxSimpleEvent.executeEvent(1002, data);
    } catch (e) {}
  }
}
