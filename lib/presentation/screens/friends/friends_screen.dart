import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geoquiz_battle/core/theme/app_colors.dart';
import 'package:geoquiz_battle/presentation/providers/friends_provider.dart';
import 'package:geoquiz_battle/presentation/providers/friend_user_provider.dart';
import 'package:geoquiz_battle/presentation/providers/multiplayer_provider.dart';
import 'package:geoquiz_battle/domain/entities/user.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 2) {
      // Clear search when switching to Add Friend tab
      _searchController.clear();
      ref.read(friendsProvider.notifier).clearSearch();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(friendsProvider.notifier).searchUsers(_searchController.text);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(friendsProvider.notifier).refresh();
  }

  void _showRemoveDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Eliminar amigo',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.onSurface,
            ),
          ),
          content: Text(
            'Estas seguro de que quieres eliminar a ${user.displayName} de tu lista de amigos?',
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.workSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pop();
                    ref
                        .read(friendsProvider.notifier)
                        .removeFriend(user.userId);
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Eliminar',
                      style: GoogleFonts.workSans(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onError,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Challenge Friend ────────────────────────────────────────────────────

  Future<void> _challengeFriend(User user) async {
    await ref.read(multiplayerProvider.notifier).challengeFriend(
          user.userId,
          friendName: user.displayName,
          friendElo: user.elo,
        );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _rankColor(String rank) {
    switch (rank) {
      case 'Diamond':
        return AppColors.rankDiamond;
      case 'Platinum':
        return AppColors.rankPlatinum;
      case 'Gold':
        return AppColors.rankGold;
      case 'Silver':
        return AppColors.rankSilver;
      default:
        return AppColors.rankBronze;
    }
  }

  Widget _buildAvatar(User user, {double radius = 24}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceContainer,
      backgroundImage:
          user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
      child: user.photoUrl == null
          ? Text(
              _initials(user.displayName),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.7,
                color: AppColors.onSurfaceVariant,
              ),
            )
          : null,
    );
  }

  Widget _buildRankBadge(String rank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _rankColor(rank).withOpacity(0.15),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        rank,
        style: GoogleFonts.workSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _rankColor(rank),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Friend Card ──────────────────────────────────────────────────────────

  Widget _buildFriendCard(User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ambientShadow(),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${user.elo}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRankBadge(user.rank),
                  ],
                ),
              ],
            ),
          ),
          // Challenge button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _challengeFriend(user),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.sports_esports,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.person_remove_outlined,
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
              size: 22,
            ),
            onPressed: () => _showRemoveDialog(user),
            tooltip: 'Eliminar amigo',
          ),
        ],
      ),
    );
  }

  // ── Request Card ─────────────────────────────────────────────────────────

  Widget _buildRequestCard(AsyncValue<User?> userAsync, String requestId) {
    final user = userAsync.valueOrNull;
    if (user == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.ambientShadow(),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ambientShadow(),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'quiere ser tu amigo',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Accept button
          Container(
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref
                    .read(friendsProvider.notifier)
                    .acceptFriendRequest(requestId),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: AppColors.onError,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Reject button
          Container(
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref
                    .read(friendsProvider.notifier)
                    .rejectFriendRequest(requestId),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.onErrorContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Result Card ───────────────────────────────────────────────────

  Widget _buildSearchResultCard(User user, FriendsState friendsState) {
    final alreadySent = friendsState.sentRequests.contains(user.userId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ambientShadow(),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${user.elo}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRankBadge(user.rank),
                  ],
                ),
              ],
            ),
          ),
          if (alreadySent)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: AppColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Enviada',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          AppColors.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ref
                      .read(friendsProvider.notifier)
                      .sendFriendRequest(user.userId),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    child: Text(
                      'Enviar solicitud',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Search Field ─────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Busca jugadores por su nombre',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant.withOpacity(0.5),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(friendsProvider.notifier).clearSearch();
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Bottom Navigation Bar ────────────────────────────────────────────────

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(31)),
        child: BottomNavigationBar(
          currentIndex: 2,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor:
              AppColors.onSurfaceVariant.withOpacity(0.5),
          selectedLabelStyle: GoogleFonts.workSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          unselectedLabelStyle: GoogleFonts.workSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/matchmaking/casual');
                break;
              case 2:
                // Already on Friends
                break;
              case 3:
                context.go('/history');
                break;
              case 4:
                // TODO: Navigate to profile
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_martial_arts),
              label: 'BATTLE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'FRIENDS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories),
              label: 'JOURNAL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation Rail (wide screens) ──────────────────────────────────────

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: 2,
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primary.withOpacity(0.1),
      labelType: NavigationRailLabelType.all,
      minWidth: 72,
      selectedIconTheme:
          IconThemeData(color: AppColors.primary, size: 24),
      unselectedIconTheme: IconThemeData(
          color: AppColors.onSurfaceVariant.withOpacity(0.5), size: 24),
      selectedLabelTextStyle: GoogleFonts.workSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 1,
      ),
      unselectedLabelTextStyle: GoogleFonts.workSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant.withOpacity(0.5),
        letterSpacing: 1,
      ),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/matchmaking/casual');
            break;
          case 2:
            break;
          case 3:
            context.go('/history');
            break;
          case 4:
            break;
        }
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.explore),
          selectedIcon: Icon(Icons.explore),
          label: Text('HOME'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sports_martial_arts),
          selectedIcon: Icon(Icons.sports_martial_arts),
          label: Text('BATTLE'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.group),
          selectedIcon: Icon(Icons.group),
          label: Text('FRIENDS'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.auto_stories),
          selectedIcon: Icon(Icons.auto_stories),
          label: Text('JOURNAL'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person),
          selectedIcon: Icon(Icons.person),
          label: Text('PROFILE'),
        ),
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);
    final isWide = MediaQuery.of(context).size.width >= 640;

    // Listen for friend challenge state transitions and navigate to game
    ref.listen<MultiplayerState>(multiplayerProvider, (prev, next) {
      if (prev?.status != MultiplayerStatus.playing &&
          next.status == MultiplayerStatus.playing &&
          next.mode == MultiplayerMode.friendChallenge) {
        context.go('/multiplayer-game');
      }
      if (next.status == MultiplayerStatus.error &&
          next.mode == MultiplayerMode.friendChallenge) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.errorMessage ?? 'Error al crear reto',
              style: GoogleFonts.workSans(
                fontSize: 13,
                color: AppColors.onError,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    });

    // Show error snackbar (only once per unique error)
    if (friendsState.errorMessage != null &&
        friendsState.errorMessage != _lastShownError) {
      _lastShownError = friendsState.errorMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendsState.errorMessage!,
              style: GoogleFonts.workSans(
                fontSize: 13,
                color: AppColors.onError,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'AMIGOS',
          style: GoogleFonts.workSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              AppColors.onSurfaceVariant.withOpacity(0.5),
          labelStyle: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
          unselectedLabelStyle: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'AMIGOS'),
            Tab(text: 'SOLICITUDES'),
            Tab(text: 'BUSCAR'),
          ],
        ),
      ),
      body: isWide
          ? Row(
              children: [
                _buildNavigationRail(context),
                const VerticalDivider(
                  width: 1,
                  thickness: 0,
                  color: Colors.transparent,
                ),
                Expanded(child: _buildTabContent(friendsState)),
              ],
            )
          : _buildTabContent(friendsState),
      bottomNavigationBar:
          isWide ? null : _buildBottomNavBar(context),
    );
  }

  Widget _buildTabContent(FriendsState friendsState) {
    return TabBarView(
      controller: _tabController,
      physics: const BouncingScrollPhysics(),
      children: [
        // ── Tab 1: Friends List ───────────────────────────
        friendsState.isLoading
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerLowest,
                onRefresh: _handleRefresh,
                child: friendsState.friends.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _buildEmptyState(
                            icon: Icons.group_outlined,
                            title: 'No tienes amigos todavia',
                            subtitle:
                                'Busca jugadores o espera solicitudes',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: friendsState.friends.length,
                        itemBuilder: (context, index) {
                          return _buildFriendCard(
                              friendsState.friends[index]);
                        },
                      ),
              ),

        // ── Tab 2: Pending Requests ───────────────────────
        friendsState.pendingRequests.isEmpty
            ? _buildEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No tienes solicitudes pendientes',
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: friendsState.pendingRequests.length,
                itemBuilder: (context, index) {
                  final requestId =
                      friendsState.pendingRequests[index];
                  final userAsync =
                      ref.watch(friendUserProvider(requestId));
                  return _buildRequestCard(userAsync, requestId);
                },
              ),

        // ── Tab 3: Add Friend (Search) ────────────────────
        Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: friendsState.isSearching
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _searchController.text.length < 2
                      ? _buildEmptyState(
                          icon: Icons.search,
                          title: 'Busca jugadores por su nombre',
                        )
                      : friendsState.searchResults.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.person_search_outlined,
                              title: 'No se encontraron jugadores',
                            )
                          : ListView.builder(
                              physics:
                                  const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(
                                  bottom: 16),
                              itemCount:
                                  friendsState.searchResults.length,
                              itemBuilder: (context, index) {
                                return _buildSearchResultCard(
                                  friendsState
                                      .searchResults[index],
                                  friendsState,
                                );
                              },
                            ),
            ),
          ],
        ),
      ],
    );
  }
}
