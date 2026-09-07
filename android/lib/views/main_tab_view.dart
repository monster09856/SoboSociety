import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/sobo_theme.dart';
import 'admin/admin_today_view.dart';
import 'ai/ai_chat_view.dart';
import 'member/account_view.dart';
import 'member/booking_view.dart';
import 'member/my_bookings_view.dart';
import 'member/packages_view.dart';
import 'member/workshops_view.dart';

class MainTabView extends StatefulWidget {
  final bool isAdmin;
  const MainTabView({super.key, this.isAdmin = false});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationService().registerDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const BookingView(),
      const MyBookingsView(),
      const WorkshopsView(),
      const PackagesView(),
      const AccountView(),
      const AIChatView(),
      if (widget.isAdmin) const AdminTodayView(),
    ];

    final List<BottomNavigationBarItem> items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_rounded),
        label: 'Program',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.confirmation_number_rounded),
        label: 'Derslerim',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome_rounded),
        label: 'Workshop',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.card_membership_rounded),
        label: 'Paketler',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Hesabım',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.psychology_rounded),
        label: 'Sobo AI',
      ),
      if (widget.isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Yönetici',
        ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex.clamp(0, pages.length - 1),
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, items.length - 1),
        onTap: (int index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: SoboTheme.espresso,
        unselectedItemColor: SoboTheme.secondary,
        selectedLabelStyle: SoboTheme.fontSans(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: SoboTheme.fontSans(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
