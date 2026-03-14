import 'package:flutter/material.dart';
import 'package:fox_link_app/modules/master/presentation/controllers/master_controller.dart';

class MasterUsersPage extends StatefulWidget {
  final MasterController controller;

  const MasterUsersPage({super.key, required this.controller});

  @override
  State<MasterUsersPage> createState() => _MasterUsersPageState();
}

class _MasterUsersPageState extends State<MasterUsersPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading && widget.controller.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = widget.controller.users;
        return RefreshIndicator(
          onRefresh: () => widget.controller.loadUsers(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Card(
              child: users.isEmpty
                  ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Nenhum usuário encontrado')),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nome')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Tenant')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: users.map((u) {
                      return DataRow(cells: [
                        DataCell(Text(u.name)),
                        DataCell(Text(u.email)),
                        DataCell(Text(u.tenantName.isEmpty ? '-' : u.tenantName)),
                        DataCell(Text(u.role)),
                        DataCell(Text(u.status)),
                      ]);
                    }).toList(),
                  ),
                ),
            ),
          ),
        );
      },
    );
  }
}
