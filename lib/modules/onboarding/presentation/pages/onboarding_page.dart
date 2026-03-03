import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/injection/injection.dart';
import 'package:fox_link_app/core/session/tenant_session.dart';
import 'package:fox_link_app/modules/users/infra/datasources/user_remote_datasource.dart';
import 'package:fox_link_app/modules/tenant/infra/datasources/tenant_remote_datasource.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/admin_dashboard.dart';
import 'package:fox_link_app/modules/dashboard/presentation/pages/client_dashboard.dart';
import 'select_tenant_page.dart';


enum AccountType { salonOwner, client }

class OnboardingPage extends StatelessWidget {
  final String uid;
  final String email;

  const OnboardingPage({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Conta")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 40),

            const Text(
              "Você quer criar:",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                title: const Text("Criar Salão"),
                subtitle: const Text("Gerenciar serviços e profissionais"),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _CreateSalonPage(
                        uid: uid,
                        email: email,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                title: const Text("Criar Conta como Cliente"),
                subtitle: const Text("Agendar serviços em um salão"),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelectTenantPage(
                        uid: uid,
                        email: email,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================
/// Criar Salão com Upload de Logo
/// ===============================================
class _CreateSalonPage extends StatefulWidget {
  final String uid;
  final String email;

  const _CreateSalonPage({
    required this.uid,
    required this.email,
  });

  @override
  State<_CreateSalonPage> createState() =>
      _CreateSalonPageState();
}

class _CreateSalonPageState extends State<_CreateSalonPage> {

  final _salonName = TextEditingController();
  final _tenantRemote = getIt<TenantRemoteDataSource>();
  final _userRemote = getIt<UserRemoteDataSource>();
  final _session = getIt<TenantSession>();

  File? selectedImage;
  bool isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (file != null) {
      setState(() {
        selectedImage = File(file.path);
      });
    }
  }

  Future<void> _create() async {
    if (_salonName.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    final tenantId = await _tenantRemote.createTenant(
      name: _salonName.text.trim(),
      ownerId: widget.uid,
    );

    if (selectedImage != null) {
      final logoUrl = await _tenantRemote.uploadLogo(
        tenantId: tenantId,
        file: selectedImage!,
      );

      await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .update({'logoUrl': logoUrl});
    }

    await _userRemote.createUser(
      uid: widget.uid,
      email: widget.email,
      role: 'admin',
      tenantId: tenantId,
    );

    _session.setSession(
      tenantId: tenantId,
      role: 'admin',
      uid: widget.uid,
      email: widget.email,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDashboard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final initial =
    _salonName.text.isEmpty
        ? "S"
        : _salonName.text[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text("Criar Salão")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundImage:
                selectedImage != null
                    ? FileImage(selectedImage!)
                    : null,
                child: selectedImage == null
                    ? Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            const Text("Toque para adicionar logo"),

            const SizedBox(height: 30),

            TextField(
              controller: _salonName,
              decoration: const InputDecoration(
                labelText: "Nome do salão",
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoading ? null : _create,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Criar"),
            ),
          ],
        ),
      ),
    );
  }
}