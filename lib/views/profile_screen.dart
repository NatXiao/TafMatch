import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/review_model.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/review_provider.dart';
import 'package:taf_match/providers/skill_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/repositories/firestore_user_repository.dart';
import 'package:taf_match/utils/theme.dart';
import 'package:taf_match/views/edit_profile_screen.dart';
import 'package:taf_match/views/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _userRepository = FirestoreUserRepository();
  bool _saving = false;
  int _userRating = 0;

  Future<Map<String, UserModel>>? _authorsFuture;
  String _authorIdsKey = '';
  String? _listeningTargetUserId;

  Future<UserModel?>? _viewedUserFuture;
  String? _loadedUserId;

  String _targetUserId = '';


  Future<void> _publish() async {
    if (_saving) return; // block re-entrant taps immediately, synchronously

    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _saving = true);
    final targetUserId = context.read<AuthProvider>().user?.uid ?? '';
    final review = Review(
      id: '',
      authorId: targetUserId,
      targetUserId: _targetUserId,
      rating: _userRating,
      comment: _reviewController.text.trim(),
    );
    try {
      await context.read<ReviewProvider>().addReview(review);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not publish review: $e')));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authUid = context.read<AuthProvider>().user?.uid ?? '';
    _targetUserId = widget.userId ?? authUid;
    final isOwnProfile = _targetUserId == authUid;

    // For our own profile, UserProvider is the live source of truth (kept in
    // sync by EditProfileScreen), so we don't need a separate one-shot fetch.
    if (!isOwnProfile &&
        _targetUserId.isNotEmpty &&
        _targetUserId != _loadedUserId) {
      _loadedUserId = _targetUserId;
      _viewedUserFuture = _userRepository.getProfile(_targetUserId);
    }

    if (_targetUserId.isNotEmpty && _targetUserId != _listeningTargetUserId) {
      _listeningTargetUserId = _targetUserId;
      Provider.of<ReviewProvider>(context, listen: false)
          .listenToUserReviews(_targetUserId);
    }
    final skillProvider = context.read<SkillProvider>();
    if (skillProvider.skills.isEmpty && !skillProvider.isLoading) {
      skillProvider.loadSkills();
    }
  }


  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final userProvider = Provider.of<UserProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final reviews = reviewProvider.reviews;
    final authorIds = reviews.map((review) => review.authorId).toSet().toList();
    final authorIdsKey = authorIds.join('|');

    if (authorIdsKey != _authorIdsKey) {
      _authorIdsKey = authorIdsKey;
      _authorsFuture = userProvider.getUsersByIds(authorIds);
    }

    final isOwnProfile =
      _targetUserId == (context.read<AuthProvider>().user?.uid ?? '');

    final avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: colors.text,
        title: Text(
          "Profile",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: colors.text),
        ),
        actions: [
          if (isOwnProfile)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isOwnProfile
            // Own profile: UserProvider is already `watch`ed via userProvider
            // above, so this rebuilds live as soon as the profile changes.
            ? _buildBody(
                context,
                colors,
                userProvider.profile,
                reviews,
                avgRating,
                isOwnProfile,
                
              )
            : FutureBuilder<UserModel?>(
                future: _viewedUserFuture,
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;

                  if (userSnapshot.connectionState == ConnectionState.waiting &&
                      user == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return _buildBody(
                    context,
                    colors,
                    user,
                    reviews,
                    avgRating,
                    isOwnProfile
                  );
                },
              ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppColors colors,
    UserModel? user,
    List<Review> reviews,
    double avgRating,
    bool isOwnProfile,
  ) {
    final skills = context.watch<SkillProvider>().namesForIds(user?.skills ?? []);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header -------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.avatar,
                  backgroundImage:
                      user?.profilePictureUrl.isNotEmpty == true
                          ? NetworkImage(user!.profilePictureUrl)
                          : null,
                  child: user?.profilePictureUrl.isEmpty != false
                      ? Icon(Icons.person, color: colors.muted, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colors.text),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                          child : Text(
                            user?.role ?? '',
                            style: TextStyle(fontSize: 14, color: colors.muted),
                          )
                        ),
                        const SizedBox(width: 12),
                        if (isOwnProfile)
                          InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                              ),
                            ),
                          )
                        ]
                      ),
                      const SizedBox(height: 6),
                      if (reviews.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.star,
                                size: 16, color: colors.accent),
                            const SizedBox(width: 4),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.text),
                            ),
                            Text(
                              '  ·  ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                              style: TextStyle(color: colors.muted),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Rate this person ---------------------------------------
            if (!isOwnProfile)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.softAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rate this person",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.text),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < _userRating;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 30,
                          onPressed: () =>
                              setState(() => _userRating = i + 1),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: filled ? colors.accent : colors.muted,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    _input(context, _reviewController,
                        hint: 'Add a comment...', maxLines: 2,
                        validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a review';
                      }
                      return null;
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _saving ? null : _publish,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Submit rating',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // --- Skills --------------------------------------------------
            Text(
              "SKILLS",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: colors.muted),
            ),
            const SizedBox(height: 10),
            if (skills.isEmpty)
              Text('No skills added yet',
                  style: TextStyle(color: colors.muted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((s) => Chip(
                          label: Text(s,
                              style: TextStyle(color: colors.text)),
                          backgroundColor: colors.softAccent,
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),

            const SizedBox(height: 24),

            // --- Reviews ---------------------------------------------------
            Text(
              "REVIEWS",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: colors.muted),
            ),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, UserModel>>(
              future: _authorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Text('Unable to load reviews');
                }
                if (reviews.isEmpty) {
                  return Text('No reviews yet',
                      style: TextStyle(color: colors.muted));
                }
                return Column(
                  children: reviews
                      .map((review) => _buildUserCard(
                            colors,
                            review,
                            snapshot.data?[review.authorId],
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _input(BuildContext context, TextEditingController c,
    {String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator}) {
  final colors = Theme.of(context).extension<AppColors>()!;
  return TextFormField(
    controller: c,
    maxLines: maxLines,
    keyboardType: keyboard,
    readOnly: readOnly,
    onTap: onTap,
    validator: validator,
    style: TextStyle(fontSize: 15, color: colors.text),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 15, color: colors.muted),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accent, width: 1.5)),
    ),
  );
}

Widget _buildUserCard(AppColors colors, Review review, UserModel? reviewer) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colors.avatar,
          backgroundImage: reviewer?.profilePictureUrl.isNotEmpty == true
              ? NetworkImage(reviewer!.profilePictureUrl)
              : null,
          child: reviewer?.profilePictureUrl.isEmpty != false
              ? Icon(Icons.person, color: colors.muted, size: 20)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reviewer?.fullName ?? 'Unknown user',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: colors.text),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < review.rating;
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 16,
                        color: filled ? colors.accent : colors.muted,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                review.comment,
                style: TextStyle(color: colors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}