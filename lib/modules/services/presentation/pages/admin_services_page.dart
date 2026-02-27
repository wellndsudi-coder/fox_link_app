import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/service_controller.dart';
import '../../domain/entities/service.dart';

class AdminServicesPage extends StatelessWidget {
  const AdminServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceController()..loadServices(),
      child: const _AdminServicesView(),
    );
  }
}

class _AdminServicesView extends StatelessWidget {
  const _AdminServicesView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.services.isEmpty
          ? const Center(child: Text('Nenhum serviço cadastrado'))
          : ListView.builder(
        itemCount: controller.services.length,
        itemBuilder: (_, index) {
          final service = controller.services[index];
          return _ServiceTile(service: service);
        },
      ),
    );
  }

  void _openForm(BuildContext context, {Service? service}) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ServiceController>(),
        child: ServiceFormDialog(service: service),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;

  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ServiceController>();

    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text(service.name.value),
        subtitle: Text(
          'R\$ ${service.basePrice.value.toStringAsFixed(2)} - '
              '${service.baseDuration.minutes} min',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: service.isActive,
              onChanged: (_) => controller.toggle(service),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<ServiceController>(),
                    child: ServiceFormDialog(service: service),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => controller.delete(service),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceFormDialog extends StatefulWidget {
  final Service? service;

  const ServiceFormDialog({super.key, this.service});

  @override
  State<ServiceFormDialog> createState() =>
      _ServiceFormDialogState();
}

class _ServiceFormDialogState
    extends State<ServiceFormDialog> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _price;
  late TextEditingController _duration;

  bool allowPriceChange = false;
  bool allowDurationChange = false;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(
        text: widget.service?.name.value ?? '');
    _price = TextEditingController(
        text: widget.service?.basePrice.value
            .toString() ??
            '');
    _duration = TextEditingController(
        text: widget.service?.baseDuration.minutes
            .toString() ??
            '');

    allowPriceChange =
        widget.service?.allowProfessionalChangePrice ??
            false;

    allowDurationChange =
        widget.service?.allowProfessionalChangeDuration ??
            false;
  }

  @override
  Widget build(BuildContext context) {
    final controller =
    context.read<ServiceController>();

    return AlertDialog(
      title: Text(
        widget.service == null
            ? 'Novo Serviço'
            : 'Editar Serviço',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration:
                const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                value!.isEmpty ? 'Obrigatório' : null,
              ),
              TextFormField(
                controller: _price,
                decoration:
                const InputDecoration(labelText: 'Preço'),
                keyboardType:
                TextInputType.number,
              ),
              TextFormField(
                controller: _duration,
                decoration:
                const InputDecoration(
                    labelText: 'Duração (min)'),
                keyboardType:
                TextInputType.number,
              ),
              SwitchListTile(
                title: const Text(
                    'Permitir alterar preço'),
                value: allowPriceChange,
                onChanged: (v) =>
                    setState(() =>
                    allowPriceChange = v),
              ),
              SwitchListTile(
                title: const Text(
                    'Permitir alterar duração'),
                value: allowDurationChange,
                onChanged: (v) =>
                    setState(() =>
                    allowDurationChange = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate())
              return;

            if (widget.service == null) {
              await controller.create(
                name: _name.text,
                price:
                double.parse(_price.text),
                duration:
                int.parse(_duration.text),
                allowChangePrice:
                allowPriceChange,
                allowChangeDuration:
                allowDurationChange,
              );
            } else {
              await controller.update(
                widget.service!.copyWith(
                  name: widget.service!.name,
                ),
              );
            }

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}