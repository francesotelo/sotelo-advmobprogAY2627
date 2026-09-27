import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;

  // State variables for Swipe-to-Reply
  String? _replyingToMsg;
  String? _replyingToSender;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    return _auth.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // Format the message if it's a reply
    String finalMessage = text;
    if (_replyingToMsg != null) {
      finalMessage =
          'Replying to $_replyingToSender:\n"$_replyingToMsg"\n\n$text';
    }

    try {
      await _chatService.sendMessage(receiverId, finalMessage);
      _msgCtrl.clear();

      // Clear the reply state
      setState(() {
        _replyingToMsg = null;
        _replyingToSender = null;
      });

      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName =
        (widget.tappedUser['firstName'] ?? 'User').toString();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final currentUserId = snap.data ?? '';

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: const Color(0xFF3949AB),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: Colors.white24,
                  child: Text(
                    tappedUserName.isNotEmpty
                        ? tappedUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10.w),
                CustomText(
                  text: tappedUserName,
                  fontSize: 18.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                          child: Text('Say hi! 👋',
                              style: TextStyle(color: Colors.grey)));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                          vertical: 16.h, horizontal: 12.w),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;

                        final isSending = docs[index].metadata.hasPendingWrites;
                        final docId = docs[index].id;

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          // SWIPE TO REPLY DISMISSIBLE
                          child: Dismissible(
                            key: Key(docId),
                            direction: isMe
                                ? DismissDirection.endToStart
                                : DismissDirection.startToEnd,
                            confirmDismiss: (direction) async {
                              // Prevent deletion and trigger reply UI
                              setState(() {
                                _replyingToMsg = msgText.replaceAll(
                                    RegExp(r'Replying to.*?\n".*?"\n\n'),
                                    ''); // Strip previous reply quotes
                                _replyingToSender =
                                    isMe ? 'You' : tappedUserName;
                              });
                              _msgFocus.requestFocus();
                              return false; // Snaps the bubble back into place
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: 16.w),
                              child: const Icon(Icons.reply_rounded,
                                  color: Colors.grey),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 16.w),
                              child: const Icon(Icons.reply_rounded,
                                  color: Colors.grey),
                            ),
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12.h, horizontal: 16.w),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? const Color(0xFF3949AB)
                                            : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft:
                                              Radius.circular(isMe ? 16 : 0),
                                          bottomRight:
                                              Radius.circular(isMe ? 0 : 16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        msgText,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    if (isMe)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isSending
                                                ? 'sending...'
                                                : 'Delivered ',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.grey.shade600,
                                              fontStyle: isSending
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                          ),
                                          if (!isSending)
                                            Icon(Icons.done_all,
                                                size: 14.sp,
                                                color: Colors.blue),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Message Input Area with Reply Banner
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2))
                  ],
                ),
                child: Column(
                  children: [
                    // REPLY BANNER
                    if (_replyingToMsg != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(
                              left: BorderSide(
                                  color: const Color(0xFF3949AB), width: 4.w)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.reply_rounded,
                                color: const Color(0xFF3949AB), size: 20.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Replying to $_replyingToSender',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF3949AB),
                                        fontSize: 12.sp),
                                  ),
                                  Text(
                                    _replyingToMsg!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 12.sp),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: 18.sp, color: Colors.grey),
                              onPressed: () => setState(() {
                                _replyingToMsg = null;
                                _replyingToSender = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    // TEXT FIELD
                    Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 24.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              focusNode: _msgFocus,
                              textInputAction: TextInputAction.send,
                              maxLines: 3,
                              minLines: 1,
                              onSubmitted: (_) =>
                                  _send(currentUserId, tappedUserId),
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20.w, vertical: 10.h),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.r),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3949AB)),
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.white),
                              onPressed: () =>
                                  _send(currentUserId, tappedUserId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
