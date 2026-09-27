import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserEmail;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
    _searchChatController.addListener(() {
      setState(() {
        _searchText = _searchChatController.text.toLowerCase();
      });
    });
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadCurrentUserEmail() async {
    setState(() {
      _currentUserEmail = _auth.currentUser?.email;
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Reusable list builder for both "Recent Chats" and "All Contacts"
  Widget _buildUserList(List<Map<String, dynamic>> users, String emptyMessage) {
    if (users.isEmpty) {
      return Center(
        child: CustomText(
          text: emptyMessage,
          fontSize: 16.sp,
          color: Colors.grey.shade600,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return GestureDetector(
          onTap: () {
            _searchChatController.clear();
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  currentUserEmail: _currentUserEmail ?? '',
                  tappedUser: user,
                ),
              ),
            );
          },
          child: Card(
            elevation: 1,
            margin: EdgeInsets.only(bottom: 12.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              leading: CircleAvatar(
                radius: 22.r,
                backgroundColor: const Color(0xFF3949AB),
                child: CustomText(
                  text: user['firstName'] != null &&
                          user['firstName'].toString().isNotEmpty
                      ? user['firstName'].toString()[0].toUpperCase()
                      : '?',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              title: CustomText(
                text: user['firstName'] ?? 'Unknown User',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              subtitle: CustomText(
                text: user['email'] ?? 'No email',
                fontSize: 13.sp,
                color: Colors.grey.shade500,
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showContactsList = _searchFocusNode.hasFocus || _searchText.isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const CustomText(
              text: 'Messages', fontSize: 20, color: Colors.white),
          backgroundColor: const Color(0xFF3949AB),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _searchChatController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF3949AB)),
                  suffixIcon: _searchChatController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel, color: Colors.grey),
                          onPressed: () {
                            _searchChatController.clear();
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _searchText = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        const BorderSide(color: Color(0xFF3949AB), width: 1.5),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getUsersStream(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return Center(
                        child: CustomText(
                            text: 'Error loading users', fontSize: 16.sp));
                  }

                  final allUsers = userSnapshot.data!;

                  // ACTIVE SEARCH VIEW (Show all filtered contacts)
                  if (showContactsList) {
                    final filteredUsers = allUsers.where((user) {
                      final email = (user['email'] ?? '').toString();
                      final firstName = (user['firstName'] ?? '').toString();
                      final isNotCurrentUser = email != _currentUserEmail;
                      final matchesSearch = _searchText.isEmpty ||
                          firstName.toLowerCase().contains(_searchText) ||
                          email.toLowerCase().contains(_searchText);
                      return isNotCurrentUser && matchesSearch;
                    }).toList();

                    return _buildUserList(
                        filteredUsers, 'No users match your search.');
                  }

                  // DEFAULT VIEW (Recent Chats)
                  return StreamBuilder<List<String>>(
                      stream: _chatService.getRecentChatUserIds(),
                      builder: (context, chatSnapshot) {
                        if (chatSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator.adaptive());
                        }

                        final recentUserIds = chatSnapshot.data ?? [];

                        if (recentUserIds.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 60.sp, color: Colors.grey.shade300),
                                SizedBox(height: 16.h),
                                CustomText(
                                  text: 'No Messages Yet',
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                                SizedBox(height: 8.h),
                                CustomText(
                                  text:
                                      'Tap the search bar to find someone to chat with!',
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ],
                            ),
                          );
                        }

                        // Filter allUsers to only include those in recentUserIds
                        final recentUsers = allUsers.where((user) {
                          final uid = (user['uid'] ?? '').toString();
                          return recentUserIds.contains(uid) &&
                              user['email'] != _currentUserEmail;
                        }).toList();

                        return _buildUserList(
                            recentUsers, 'You have no recent chats.');
                      });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
