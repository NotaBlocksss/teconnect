import 'package:flutter/material.dart';
import 'admin_inicio_screen.dart';
import 'admin_usuarios_screen.dart';
import 'admin_tickets_screen.dart';
import 'admin_config_screen.dart';
import '../invoices/admin_invoices_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
        AdminInicioScreen(
          onNavigateToTickets: () {
            if (mounted) {
              setState(() {
                _currentIndex = 2;
              });
            }
          },
          onNavigateToUsers: () {
            if (mounted) {
              setState(() {
                _currentIndex = 1;
              });
            }
          },
        ),
        const AdminUsuariosScreen(),
        const AdminTicketsScreen(),
        const AdminInvoicesScreen(),
        const AdminConfigScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    // Validar que el índice esté dentro del rango válido
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);
    
    return Scaffold(
      body: _screens[safeIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) {
            if (index >= 0 && index < _screens.length) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent),
              label: 'Tickets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Facturas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Configuración',
            ),
          ],
        ),
      ),
    );
  }
}

