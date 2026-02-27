import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';

class EditTenantPage extends StatefulWidget {
  const EditTenantPage({super.key});

  @override
  State<EditTenantPage> createState() => _EditTenantPageState();
}

class _EditTenantPageState extends State<EditTenantPage> {
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _session = getIt<TenantSession>();

  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });

      await _tenantRemote.uploadLogo(
        tenantId: _session.tenantId!,
        file: _image!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logo atualizada")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Salão")),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickImage,
          child: const Text("Alterar Logo"),
        ),
      ),
    );
  }
}