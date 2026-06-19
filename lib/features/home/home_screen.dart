import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../config/theme.dart';
import '../../constants/app_strings.dart';
import '../../core/models/trip.dart';
import '../checklist/checklist_screen.dart';
import '../expenses/expenses_screen.dart';
import '../itinerary/itinerary_screen.dart';
import '../shopping/shopping_screen.dart';
import 'application/trips_notifier.dart';
import 'widgets/create_trip_sheet.dart';
import 'widgets/empty_trips_state.dart';
import 'widgets/featured_trip_banner.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/section_header.dart';
import 'widgets/trip_card.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = useState(0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: navIndex.value,
        children: const [
          _TripsTab(),
          ExpensesScreen(),
          ChecklistScreen(),
          ShoppingScreen(),
          ItineraryScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: navIndex.value,
        onTap: (i) => navIndex.value = i,
      ),
      floatingActionButton: navIndex.value == 0 ? const _TripsFAB() : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav widget
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: AppStrings.navHome,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet_rounded),
          label: AppStrings.navExpenses,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checklist_outlined),
          activeIcon: Icon(Icons.checklist_rounded),
          label: AppStrings.navChecklist,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag_rounded),
          label: AppStrings.navShopping,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map_rounded),
          label: AppStrings.navItinerary,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FAB for trips tab
// ---------------------------------------------------------------------------

class _TripsFAB extends StatelessWidget {
  const _TripsFAB();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => CreateTripSheet.show(context),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        AppStrings.addTrip,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trips tab — converts StatefulWidget to HookConsumerWidget
// ---------------------------------------------------------------------------

class _TripsTab extends HookConsumerWidget {
  const _TripsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);

    final ongoingTrips = trips.where((t) => t.status == TripStatus.ongoing);
    final ongoingTrip = ongoingTrips.isEmpty ? null : ongoingTrips.first;
    final upcomingTrips = trips.where((t) => t.status == TripStatus.upcoming).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final pastTrips = trips.where((t) => t.status == TripStatus.completed).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? AppStrings.greetingMorning
        : hour < 17
        ? AppStrings.greetingAfternoon
        : hour < 21
        ? AppStrings.greetingEvening
        : AppStrings.greetingNight;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          stretch: true,
          backgroundColor: AppColors.primaryDark,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            stretchModes: const [StretchMode.zoomBackground],
            background: _HeaderBackground(greeting: greeting),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: QuickStatsRow(
              totalTrips: trips.length,
              upcomingCount: upcomingTrips.length,
              completedCount: pastTrips.length,
            ),
          ),
        ),
        if (ongoingTrip != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: SectionHeader(title: AppStrings.sectionOngoing),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: FeaturedTripBanner(trip: ongoingTrip),
            ),
          ),
        ],
        if (upcomingTrips.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: SectionHeader(
                title: AppStrings.sectionUpcoming,
                showSeeAll: true,
                onSeeAll: () {},
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TripCard(trip: upcomingTrips[index]),
                childCount: upcomingTrips.length,
              ),
            ),
          ),
        ],
        if (pastTrips.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: SectionHeader(
                title: AppStrings.sectionPast,
                showSeeAll: true,
                onSeeAll: () {},
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => TripCard(trip: pastTrips[index]),
                childCount: pastTrips.length,
              ),
            ),
          ),
        ],
        if (trips.isEmpty)
          const SliverToBoxAdapter(child: EmptyTripsState()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header background widget — pure UI, stays StatelessWidget
// ---------------------------------------------------------------------------

class _HeaderBackground extends StatelessWidget {
  final String greeting;

  const _HeaderBackground({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$greeting 👋',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppStrings.userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        color: Colors.white54,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        AppStrings.greetingSubtitle,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
