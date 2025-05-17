import 'package:flutter/material.dart';
import 'package:simple_tree/simple_tree.dart';

import '../pages/personal_center_page.dart';
import '../view/member_page.dart';
import '../view/vip_customer.dart';
import '../view/region_shanghai.dart';
import '../view/region_beijing.dart';
import '../view/customer_list.dart';

// '系统设置', '业务管理', '日常业务', '业务统计', '财务管理', '会员中心', '微信中心', '新消息'
final List<TreeNode> data = <TreeNode>[
  TreeNode(index: 0, name: '客户管理首页', style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold)),
  TreeNode(index: 1, name: '微信中心', style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold)),

  TreeNode(
    index: 2,
    name: '日常业务',
    style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
    children: [
      TreeNode(index: 2001, name: '收衣'),
      TreeNode(index: 2007, name: '取衣'),
      TreeNode(index: 2002, name: '办卡'),
      TreeNode(index: 2003, name: '充值'),
      TreeNode(index: 2004, name: '美团'),
      TreeNode(index: 2005, name: '上架'),
      TreeNode(index: 2006, name: '营业日报'),

      TreeNode(index: 2008, name: '门店配送'),
      TreeNode(index: 2009, name: '配件管理'),
      TreeNode(index: 2010, name: '库存'),
    ],
  ),

  TreeNode(index: 3, name: '业务管理', style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold)),
  TreeNode(index: 4, name: '财务管理', style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold)),
  TreeNode(index: 5, name: '业务统计', style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold)),

  TreeNode(
    index: 6,
    name: '会员中心',
    // children: [
    //   TreeNode(index: 6001, name: 'VIP客户'),
    //   TreeNode(index: 6002, name: '普通客户', children: [TreeNode(index: 60021, name: '上海客户'), TreeNode(index: 60022, name: '北京客户')]),
    // ],
  ),
  TreeNode(index: 7, name: '系统设置', style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold)),
];

final List<PageInfo> myAppPages = [
  PageInfo(index: 0, title: '客户管理首页', widget: CustomerListPage()),
  PageInfo(index: 6, title: '会员中心', widget: MemberPage()),
  PageInfo(index: 3, title: '业务管理', widget: ShanghaiCustomerPage()),
  PageInfo(index: 4, title: '财务管理', widget: const RegionBeijingPage()),
  PageInfo(index: 7, title: '系统设置', widget: PersonalCenterPage()),
];
