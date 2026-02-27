import 'package:flutter/material.dart';
import '../../../scheduling/presentation/pages/create_appointment_page.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cliente")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Dashboard Cliente 👦",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Novo Agendamento"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateAppointmentPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}