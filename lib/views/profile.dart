
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:taf_match/models/review_model.dart';
import 'package:taf_match/models/user_model.dart';
import 'package:taf_match/providers/auth_provider.dart';
import 'package:taf_match/providers/review_provider.dart';
import 'package:taf_match/providers/user_provider.dart';
import 'package:taf_match/views/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  ProfileScreenState createState() => ProfileScreenState();
  
}

class ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _reviewController = TextEditingController();
  Future<Map<String, UserModel>>? _authorsFuture;
  String _authorIdsKey = '';
  String? _listeningTargetUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context).profile;
    if (user != null && user.uid != _listeningTargetUserId) {
      _listeningTargetUserId = user.uid;
      Provider.of<ReviewProvider>(context, listen: false)
          .listenToUserReviews(user.uid);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.profile;
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final reviews = reviewProvider.reviews;
    final authorIds = reviews.map((review) => review.authorId).toSet().toList();
    final authorIdsKey = authorIds.join('|');
    if (authorIdsKey != _authorIdsKey) {
      _authorIdsKey = authorIdsKey;
      _authorsFuture = userProvider.getUsersByIds(authorIds);
    }

  return Scaffold(
      appBar: AppBar(
        title: Text("Jobs"),
        actions: [
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
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: user?.profilePictureUrl.isNotEmpty == true
                        ? NetworkImage(user!.profilePictureUrl)
                        : null,
                    child: user?.profilePictureUrl.isEmpty == true
                        ? const Icon(Icons.person)
                        : null,
                  ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Full Name : ${user?.fullName ?? ''}",
                    ),
                    Text(
                      "Email : ${user?.email ?? ''}",
                    ),
                    Text(
                      "Role : ${user?.role ?? ''}",
                    ),
                  ],
                ),
              ]),

              Text(
                "Rate this person",
              ),
              TextFormField(
                controller: _reviewController,
                decoration: InputDecoration(
                  labelText: 'Review',
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide(
                      color: Colors.black,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an review';
                  }
                  return null;
                },
              ),

              Text(
                "Skills",
              ),
              
              Text(
                "Reviews",
              ),
              Expanded(
                child: FutureBuilder<Map<String, UserModel>>(
                  future: _authorsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Unable to load reviews'));
                    }
                    return ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return _buildUserCard(
                          review,
                          snapshot.data?[review.authorId],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildUserCard(Review review, UserModel? reviewer) {
  return Card(
    child: ListTile(
      title: Text(reviewer?.fullName ?? 'Unknown user'),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: reviewer?.profilePictureUrl.isNotEmpty == true
            ? NetworkImage(reviewer!.profilePictureUrl)
            : null,
        child: reviewer?.profilePictureUrl.isEmpty == true
            ? const Icon(Icons.person)
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rating: ${review.rating}'),
          Text('Comment: ${review.comment}'),
        ],
      ),
    ),
  );
}
