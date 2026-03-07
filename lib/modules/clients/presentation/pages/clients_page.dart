import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';
import 'package:fox_link_app/core/theme/app_colors.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _searchController = TextEditingController();
  final _clients = <_ClientItem>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
              TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: AppColors.mutedForeground(context),
              ),
              filled: true,
              fillColor: AppColors.fillColor(context),
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

              // Stats
              RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground(context),
              ),
              children: [
                TextSpan(
                  text: '${_clients.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const TextSpan(text: ' clientes'),
              ],
              ),
            ),

              const SizedBox(height: 16),

              // List
              if (_clients.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nenhum cliente cadastrado',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ),
                )
              else
                ..._clients.map((c) => _ClientTile(client: c)),

              const SizedBox(height: 72),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: abrir tela de novo cliente
            },
            backgroundColor: AppColors.primary(context),
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _ClientItem {
  final String name;
  final String phone;
  final int visits;
  final String initials;

  _ClientItem({
    required this.name,
    required this.phone,
    required this.visits,
    required this.initials,
  });
}

class _ClientTile extends StatelessWidget {
  final _ClientItem client;

  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent(context),
            child: Text(
              client.initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accentForeground(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone, size: 12, color: AppColors.mutedForeground(context)),
                    const SizedBox(width: 4),
                    Text(
                      '${client.phone} · ${client.visits} visitas',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 18, color: AppColors.mutedForeground(context)),
        ],
      ),
    );
  }
}
