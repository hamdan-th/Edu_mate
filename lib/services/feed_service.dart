import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_post_model.dart';

class FeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<List<FeedPostModel>> streamPublicFeed({
    String filter = 'For You',
    String searchQuery = '',
  }) {
    return _firestore
        .collection('posts')
        .where('visibility', isEqualTo: 'public')
        .snapshots()
        .asyncMap((snapshot) async {
          List<FeedPostModel> posts = snapshot.docs
              .map((doc) => FeedPostModel.fromMap(doc.data(), doc.id))
              .where((post) => post.isValidPublicPost)
              .toList();
          
          if (searchQuery.trim().isNotEmpty) {
            final query = searchQuery.trim().toLowerCase();
            posts = posts.where((post) {
              return post.groupName.toLowerCase().contains(query) ||
                     post.authorName.toLowerCase().contains(query) ||
                     post.contentText.toLowerCase().contains(query);
            }).toList();
          }

          String? userCollegeId;
          String? userSpecId;
          if ((filter == 'Academic' || filter == 'For You') && _auth.currentUser != null) {
            try {
               final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
               if (userDoc.exists) {
                 final data = userDoc.data();
                 userCollegeId = data?['collegeId']?.toString();
                 userSpecId = data?['specializationId']?.toString();
               }
            } catch (_) {}
          }

          if (filter == 'Recent') {
             posts.sort((a, b) {
               final timeA = a.createdAt?.millisecondsSinceEpoch ?? 0;
               final timeB = b.createdAt?.millisecondsSinceEpoch ?? 0;
               return timeB.compareTo(timeA);
             });
          } else if (filter == 'Popular') {
             posts.sort((a, b) {
               if (b.likesCount != a.likesCount) {
                 return b.likesCount.compareTo(a.likesCount);
               }
               final timeA = a.createdAt?.millisecondsSinceEpoch ?? 0;
               final timeB = b.createdAt?.millisecondsSinceEpoch ?? 0;
               return timeB.compareTo(timeA);
             });
          } else if (filter == 'Academic') {
             posts.sort((a, b) {
               bool matchA = (a.collegeId == userCollegeId && userCollegeId != null);
               bool matchB = (b.collegeId == userCollegeId && userCollegeId != null);
               if (matchA && !matchB) return -1;
               if (!matchA && matchB) return 1;
               
               final timeA = a.createdAt?.millisecondsSinceEpoch ?? 0;
               final timeB = b.createdAt?.millisecondsSinceEpoch ?? 0;
               return timeB.compareTo(timeA);
             });
          } else {
             // For You (default)
             posts.sort((a, b) {
               double getScore(FeedPostModel p) {
                 double score = 0;
                 if (p.collegeId == userCollegeId && userCollegeId != null && userCollegeId.isNotEmpty) score += 50;
                 if (p.specializationId == userSpecId && userSpecId != null && userSpecId.isNotEmpty) score += 100;
                 score += p.likesCount * 2;
                 final now = DateTime.now().millisecondsSinceEpoch;
                 final postTime = p.createdAt?.millisecondsSinceEpoch ?? 0;
                 final ageInDays = (now - postTime) / (1000 * 60 * 60 * 24);
                 score -= ageInDays * 2;
                 return score;
               }
               return getScore(b).compareTo(getScore(a));
             });
          }
          
          return posts;
        });
  }

  /// Deletes a post. Only the author should call this.
  static Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  /// Updates the text content of a post. Only the author should call this.
  static Future<void> updatePost({
    required String postId,
    required String newText,
  }) async {
    await _firestore.collection('posts').doc(postId).update({
      'contentText': newText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Submits a report for a post.
  static Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    await _firestore.collection('comment_reports').add({
      'type': 'post',
      'postId': postId,
      'reportedBy': uid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
