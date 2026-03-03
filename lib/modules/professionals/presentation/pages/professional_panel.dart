import 'package:flutter/material.dart';

// 🔥 ALTERAÇÃO 1: Removido ProfessionalDashboard
// import '../../../dashboard/presentation/pages/professional_dashboard.dart';

// 🔥 ALTERAÇÃO 2: Importada nova agenda
import '../../../scheduling/presentation/pages/professional_agenda_page.dart';

import '../../../availability/presentation/pages/professional_availability_page.dart';
import 'professional_services_page.dart';
import 'professional_finance_page.dart';

class ProfessionalPanel extends StatefulWidget {
  const ProfessionalPanel({super.key});

  @override
  State<ProfessionalPanel> createState() =>
      _ProfessionalPanelState();
}

class _ProfessionalPanelState
    extends State<ProfessionalPanel> {

  int _currentIndex = 0;

  late final List<Widget> _pages = [
    // 🔥 ALTERAÇÃO 3: Agora a aba Agenda usa ProfessionalAgendaPage
    const ProfessionalAgendaPage(),
    const ProfessionalServicesPage(),
    const ProfessionalAvailabilityPage(),
    const ProfessionalFinancePage(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // 🔥 ALTERAÇÃO 4 (melhoria): usando IndexedStack para manter estado das páginas
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Agenda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: "Serviços",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: "Disponibilidade",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Financeiro",
          ),
        ],
      ),
    );
  }
}