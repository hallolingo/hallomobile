import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hallomobil/constants/color/color_constants.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.WHITE,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildLeaderboard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.MAINCOLOR,
            ColorConstants.SECONDARY_COLOR,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: ColorConstants.WHITE,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.WHITE.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.leaderboard,
                  color: ColorConstants.WHITE,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                'Lider Tablosu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.WHITE,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'En yüksek skorlar',
            style: TextStyle(
              fontSize: 16,
              color: ColorConstants.WHITE.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .orderBy('score', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget();
        }

        List<DocumentSnapshot> users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            DocumentSnapshot user = users[index];
            Map<String, dynamic> userData = user.data() as Map<String, dynamic>;

            return _buildUserCard(user.id, userData, index + 1);
          },
        );
      },
    );
  }

  Widget _buildUserCard(
      String userId, Map<String, dynamic> userData, int rank) {
    bool isTopThree = rank <= 3;
    bool isCurrentUser = _auth.currentUser?.uid == userId;
    Color rankColor = _getRankColor(rank);
    IconData rankIcon = _getRankIcon(rank);

    String displayName = '';
    String email = userData['email'] ?? '';
    int score = userData['score'] ?? 0;

    // İsim belirleme mantığı
    if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
      displayName = userData['name'];
    } else if (email.isNotEmpty) {
      displayName = email.split('@')[0];
    } else {
      displayName = 'Anonim Kullanıcı';
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (rank * 50)),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? ColorConstants.MAINCOLOR.withOpacity(0.1)
            : isTopThree
                ? rankColor.withOpacity(0.1)
                : ColorConstants.WHITE,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? ColorConstants.MAINCOLOR
              : isTopThree
                  ? rankColor.withOpacity(0.3)
                  : Colors.grey.shade200,
          width: isCurrentUser
              ? 2
              : isTopThree
                  ? 2
                  : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentUser
                ? ColorConstants.MAINCOLOR.withOpacity(0.3)
                : isTopThree
                    ? rankColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: isCurrentUser
                ? 15
                : isTopThree
                    ? 12
                    : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isTopThree
                    ? LinearGradient(
                        colors: [rankColor, rankColor.withOpacity(0.7)],
                      )
                    : LinearGradient(
                        colors: [
                          ColorConstants.ACCENT_COLOR,
                          ColorConstants.ACCENT_COLOR.withOpacity(0.7)
                        ],
                      ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: isTopThree
                    ? Icon(
                        rankIcon,
                        color: ColorConstants.WHITE,
                        size: 24,
                      )
                    : Text(
                        '$rank',
                        style: const TextStyle(
                          color: ColorConstants.TEXT_COLOR,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (isCurrentUser)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ColorConstants.MAINCOLOR,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ColorConstants.WHITE, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: ColorConstants.WHITE,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrentUser
                      ? FontWeight.bold
                      : isTopThree
                          ? FontWeight.bold
                          : FontWeight.w600,
                  color: ColorConstants.TEXT_COLOR,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorConstants.MAINCOLOR,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sen',
                  style: TextStyle(
                    color: ColorConstants.WHITE,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: email.isNotEmpty
            ? Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorConstants.TEXT_COLOR.withOpacity(0.7),
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.MAINCOLOR,
                ColorConstants.SECONDARY_COLOR,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$score',
            style: const TextStyle(
              color: ColorConstants.WHITE,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return ColorConstants.MAINCOLOR;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return Icons.person;
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.MAINCOLOR),
          ),
          const SizedBox(height: 16),
          Text(
            'Lider tablosu yükleniyor...',
            style: TextStyle(
              color: ColorConstants.TEXT_COLOR,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Bir hata oluştu',
            style: TextStyle(
              color: ColorConstants.TEXT_COLOR,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lider tablosu yüklenirken hata oluştu',
            style: TextStyle(
              color: ColorConstants.TEXT_COLOR.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            color: ColorConstants.TEXT_COLOR.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz skor yok',
            style: TextStyle(
              color: ColorConstants.TEXT_COLOR,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk oyunu oynayan sen ol!',
            style: TextStyle(
              color: ColorConstants.TEXT_COLOR.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
