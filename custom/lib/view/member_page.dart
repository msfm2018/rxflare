import 'package:flutter/material.dart';

class MemberPage extends StatefulWidget {
  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController birthdayCtrl = TextEditingController();
  final TextEditingController cardCtrl = TextEditingController();

  List<Map<String, dynamic>> members = [];

  Future<void> addMember() async {
    nameCtrl.clear();
    phoneCtrl.clear();
    birthdayCtrl.clear();
    cardCtrl.clear();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('会员管理')),
      body: Column(
        children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(labelText: '姓名')),
          TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: '电话')),
          TextField(controller: birthdayCtrl, decoration: InputDecoration(labelText: '生日 YYYY-MM-DD')),
          TextField(controller: cardCtrl, decoration: InputDecoration(labelText: '卡号')),
          ElevatedButton(onPressed: addMember, child: Text('新增会员')),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (_, i) => ListTile(title: Text(members[i]['name']), subtitle: Text('电话: ${members[i]['phone']} 生日: ${members[i]['birthday']}')),
            ),
          ),
        ],
      ),
    );
  }
}
