import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';

/// Lista de profissionais do time (admin).
class AdminTeamListPage extends StatelessWidget {
  const AdminTeamListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getIt<ProfessionalRemoteDataSource>().getProfessionals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pros = snapshot.data ?? [];
          if (pros.isEmpty) {
            return const Center(child: Text('Nenhum profissional cadastrado.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pros.length,
            itemBuilder: (context, i) {
              final p = pros[i];
              final name = p['name'] as String? ?? 'Sem nome';
              final email = p['email'] as String? ?? '';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary(context),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppColors.onPrimary(context)),
                  ),
                ),
                title: Text(name),
                subtitle: email.isNotEmpty ? Text(email) : null,
              );
            },
          );
        },
      ),
    );
  }
}
