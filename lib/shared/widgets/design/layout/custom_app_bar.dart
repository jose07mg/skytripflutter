import 'package:flutter/material.dart';
import 'package:skytrip/features/home/favoritos_page.dart';
import 'package:skytrip/features/home/mis_reservas_page.dart';
import 'package:skytrip/features/home/reviews_page.dart';
import 'package:skytrip/features/profile/profile_page.dart';

/// Branded AppBar used by inner pages.
/// Shows a back arrow (pops) when navigation history exists, then the SkyTrip
/// logo + title. Tapping the logo always navigates to /home.
class SkyTripAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showMenu;
  final Color backgroundColor;
  final PreferredSizeWidget? bottom;

  const SkyTripAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenu = true,
    this.backgroundColor = const Color(0xFF003B95),
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: canPop ? 0 : 12,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              tooltip: 'Inicio',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (r) => false),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        overflow: TextOverflow.ellipsis,
      ),
      actions: showMenu
          ? [
              ...?actions,
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'reservas':
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const MisReservasPage()));
                      break;
                    case 'favoritos':
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const FavoritosPage()));
                      break;
                    case 'reviews':
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ReviewsPage()));
                      break;
                    case 'perfil':
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ProfilePage()));
                      break;
                    case 'home':
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (r) => false);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'home',
                    child: Row(children: [
                      Icon(Icons.home_outlined, color: Color(0xFF003B95)),
                      SizedBox(width: 10),
                      Text('Inicio'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'reservas',
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: Colors.blue),
                      SizedBox(width: 10),
                      Text('Mis Reservas'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'favoritos',
                    child: Row(children: [
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Favoritos'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'reviews',
                    child: Row(children: [
                      Icon(Icons.star, color: Colors.orange),
                      SizedBox(width: 10),
                      Text('Valoraciones'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'perfil',
                    child: Row(children: [
                      Icon(Icons.person, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Mi Perfil'),
                    ]),
                  ),
                ],
              ),
            ]
          : actions,
      bottom: bottom,
    );
  }
}

// Keep old name as alias for backward compatibility
class CustomAppBar extends SkyTripAppBar {
  const CustomAppBar({
    super.key,
    required super.title,
    super.showMenu = true,
  });
}
