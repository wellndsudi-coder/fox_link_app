import 'package:flutter/material.dart';

import '../../../dashboard/presentation/pages/professional_dashboard.dart';
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
    const ProfessionalDashboard(),
    const ProfessionalServicesPage(),
    const ProfessionalAvailabilityPage(),
    const ProfessionalFinancePage(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _pages[_currentIndex],
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