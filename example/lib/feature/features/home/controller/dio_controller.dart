// Dio + CancelToken 标准对接（生产级）

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';

final dioClient = dio.Dio();

/// ======================================================
/// model
/// ======================================================

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String website;
  final String company;

  UserModel({required this.id, required this.name, required this.email, required this.phone, required this.website, required this.company});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map["id"] ?? 0,
      name: map["name"] ?? "",
      email: map["email"] ?? "",
      phone: map["phone"] ?? "",
      website: map["website"] ?? "",
      company: map["company"]?["name"] ?? "",
    );
  }
}

/// ======================================================
/// controller
/// ======================================================

class DioController {
  final users = <UserModel>[].obs;

  late final usersFuture = RxFuture<List<UserModel>>((cancelToken) => fetchUsers(cancelToken), maxRetries: 2, retryDelay: const Duration(seconds: 1));

  Future<List<UserModel>> fetchUsers(CancelToken? rxToken) async {
    final dioCancel = dio.CancelToken();

    /// RxFuture cancel -> dio cancel
    rxToken?.onCancel = () {
      dioCancel.cancel("request canceled");
    };

    final res = await dioClient.get("https://jsonplaceholder.typicode.com/users", cancelToken: dioCancel);

    final list = (res.data as List).map((e) => UserModel.fromMap(e)).toList();

    users.value = list;

    return list;
  }

  void dispose() {
    usersFuture.dispose();
    users.dispose();
  }
}

/// ======================================================
/// page
/// ======================================================

class DioPage extends StatelessWidget {
  const DioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RxParent<DioController>(dependency: DioController(), child: const DioView());
  }
}

/// ======================================================
/// view
/// ======================================================

class DioView extends StatefulWidget {
  const DioView({super.key});

  @override
  State<DioView> createState() => _DioViewState();
}

class _DioViewState extends State<DioView> {
  late DioController c;

  @override
  void initState() {
    super.initState();

    c = RxObjMgr.find<DioController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RxFuture + Dio Demo"),
        actions: [
          Rx(() {
            if (c.usersFuture.isRefreshing) {
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                c.usersFuture.refresh(force: true);
              },
            );
          }),
        ],
      ),
      body: Rx(() {
        /// 初次加载
        if (c.usersFuture.isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        /// 错误状态
        if (c.usersFuture.hasError && c.users.value.isEmpty) {
          return _ErrorView(
            error: c.usersFuture.error,
            onRetry: () {
              c.usersFuture.retry();
            },
          );
        }

        final list = c.users.value;

        /// 空状态
        if (list.isEmpty) {
          return const Center(child: Text("暂无数据"));
        }

        /// 列表
        return RefreshIndicator(
          onRefresh: () async {
            c.usersFuture.refresh(force: true);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final user = list[index];

              return _UserCard(user: user);
            },
          ),
        );
      }),
    );
  }
}

/// ======================================================
/// user card
/// ======================================================

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: .05))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, child: Text(user.name.substring(0, 1))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user.company, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.email_outlined, text: user.email),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.phone_outlined, text: user.phone),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.language_outlined, text: user.website),
        ],
      ),
    );
  }
}

/// ======================================================
/// info row
/// ======================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// ======================================================
/// error view
/// ======================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text("$error", textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text("重试")),
          ],
        ),
      ),
    );
  }
}
