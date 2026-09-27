import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    });
  }

  // NEW: get users the current user has chatted with
  Stream<List<String>> getRecentChatUserIds() {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    return _firestore
        .collection("chat_rooms")
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        // Return the ID of the person we are chatting with (not our own ID)
        return participants.firstWhere((id) => id != currentUserId,
            orElse: () => '');
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();

    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomID = ids.join('_');

    // NEW: Save participants in the chat room document so we can query recent chats later
    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      'participants': [currentUserId, receiverId],
    }, SetOptions(merge: true));

    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join("_");

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
