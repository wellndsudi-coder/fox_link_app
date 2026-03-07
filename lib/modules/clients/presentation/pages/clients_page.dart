import 'package:flutter/material.dart';
import 'package:fox_link_app/core/theme/app_theme.dart';

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

              // Stats
              RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
              children: [
                TextSpan(
                  text: '${_clients.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foregroundColor,
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
                        color: AppTheme.mutedForeground,
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
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accentColor,
            child: Text(
              client.initials,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentForeground,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone, size: 12, color: AppTheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      '${client.phone} · ${client.visits} visitas',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 18, color: AppTheme.mutedForeground),
        ],
      ),
    );
  }
}
