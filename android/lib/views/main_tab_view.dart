import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    NotificationService().registerDeviceToken();
  }

  bool _onScrollNotification(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse) {
      if (_isNavVisible) {
        setState(() => _isNavVisible = false);
      }
    } else if (notification.direction == ScrollDirection.forward) {
      if (!_isNavVisible) {
        setState(() => _isNavVisible = true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      const BookingView(),
      const MyBookingsView(),
      const WorkshopsView(),
      const PackagesView(),
      const AccountView(),
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
      if (widget.isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Yönetici',
        ),
    ];

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScrollNotification,
        child: IndexedStack(
          index: _currentIndex.clamp(0, pages.length - 1),
          children: pages,
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        offset: _isNavVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isNavVisible ? 1.0 : 0.0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: SoboTheme.line, width: 0.8)),
            ),
            child: SafeArea(
              top: false,
              child: BottomNavigationBar(
                currentIndex: _currentIndex.clamp(0, items.length - 1),
                onTap: (int index) {
                  setState(() {
                    _currentIndex = index;
                    _isNavVisible = true;
                  });
                },
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: SoboTheme.espresso,
                unselectedItemColor: SoboTheme.secondary,
                selectedLabelStyle: SoboTheme.fontSans(fontSize: 10.5, fontWeight: FontWeight.bold),
                unselectedLabelStyle: SoboTheme.fontSans(fontSize: 10),
                type: BottomNavigationBarType.fixed,
                items: items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


