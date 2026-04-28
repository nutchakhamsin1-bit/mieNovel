import 'package:flutter/material.dart';
import 'package:mie_project/admin/MemberDetailPage.dart';
import 'package:mie_project/services/db_helper.dart';

class Managemember extends StatefulWidget {
  const Managemember({super.key});

  @override
  State<Managemember> createState() => _ManagememberState();
}

class _ManagememberState extends State<Managemember> {
  late Future<List<Map<String, dynamic>>> usersFuture;

  @override
  void initState() {
    super.initState();
    usersFuture = DBHelper.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการสมาชิก')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: usersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text("ยังไม่มีสมาชิก"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];

              return ListTile(
                leading: Icon(
                  u['status'] == 'active' ? Icons.person : Icons.person_off,
                  color: u['status'] == 'active' ? Colors.green : Colors.grey,
                ),
                title: Text("${u['name']} ${u['surname']}"),
                subtitle: Text(u['email']),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberDetailPage(
                        userId: u['user_id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
