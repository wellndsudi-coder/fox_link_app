import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/config/plan_config.dart';
import 'package:fox_link_app/modules/professionals/infra/datasources/professional_remote_datasource.dart';

class ProfessionalsPage extends StatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  State<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends State<ProfessionalsPage> {
  final _professionalRemote = getIt<ProfessionalRemoteDataSource>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int _currentCount = 0;
  int _maxAllowed = 0;
  String _currentPlan = '';

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadLimits() async {
    _currentPlan = await _professionalRemote.getCurrentPlan();
    _currentCount = await _professionalRemote.getCurrentCount();
    _maxAllowed = PlanConfig.maxProfessionals(_currentPlan);
    setState(() {});
  }

  Future<void> _createProfessional() async {
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      if (name.isEmpty || email.isEmpty) {
        throw Exception('Nome e email são obrigatórios.');
      }
      await _professionalRemote.createProfessional(name: name, email: email);
      _nameController.clear();
      _emailController.clear();
      await _loadLimits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convite enviado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _delete(String id) async {
    await _professionalRemote.deleteProfessional(id);
    await _loadLimits();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar profissional...',
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: AppTheme.mutedForeground,
              ),
              filled: true,
              fillColor: AppTheme.secondaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Limits
          Text(
            'Plano: $_currentPlan | $_currentCount / $_maxAllowed usados',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedForeground,
            ),
          ),

          const SizedBox(height: 16),

          // Add form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Nome do profissional',
                    filled: true,
                    fillColor: AppTheme.secondaryColor,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email do profissional',
                    filled: true,
                    fillColor: AppTheme.secondaryColor,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createProfessional,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                    child: const Text('Enviar convite'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // List
          StreamBuilder<QuerySnapshot>(
            stream: _professionalRemote.streamProfessionals(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nenhum profissional cadastrado',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final name = doc['name'] as String? ?? '';
                  final email = doc['email'] as String? ?? '';
                  final initials = name.length >= 2
                      ? name.substring(0, 2).toUpperCase()
                      : name.toUpperCase();
                  return _ProfessionalTile(
                    name: name,
                    email: email,
                    initials: initials,
                    onDelete: () => _delete(doc.id),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfessionalTile extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final VoidCallback onDelete;

  const _ProfessionalTile({
    required this.name,
    required this.email,
    required this.initials,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foregroundColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSm),
                      ),
                      child: Text(
                        'Ativo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: AppTheme.mutedForeground,
            ),
            onPressed: onDelete,
          ),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppTheme.mutedForeground,
          ),
        ],
      ),
    );
  }
}
