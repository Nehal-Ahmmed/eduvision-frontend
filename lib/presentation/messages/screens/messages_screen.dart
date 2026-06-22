import 'package:flutter/material.dart';
import '../../theme/app_constants.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String selectedChatId = 'chat-1';
  String searchTerm = '';
  TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1024) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildConversationsList(320),
        Expanded(child: _buildChatArea()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Row(
      children: [
        _buildConversationsList(320),
        Expanded(child: _buildChatArea()),
      ],
    );
  }

  Widget _buildConversationsList(double width) {
    final conversations = _getConversations();

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.blue200),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.blue200),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Messages',
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: AppColors.blue900,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.blue600,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Search
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray200),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.gray400, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchTerm = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search conversations...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: AppColors.gray400),
                          ),
                          style: AppTextStyles.small,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Conversations
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final isSelected = selectedChatId == conversation['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedChatId = conversation['id'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blue100 : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.blue200 : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            if (conversation['type'] == 'group')
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.blue500,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: AppColors.white,
                                  size: 24,
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      conversation['avatar'] as String,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (conversation['unread_count'] as int > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.red500,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${conversation['unread_count']}',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation['name'] as String,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.gray900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    conversation['time'] as String,
                                    style: AppTextStyles.extraSmall.copyWith(
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation['lastMessage'] as String,
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.gray600,
                                        fontWeight: conversation['unread_count'] as int > 0
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (conversation['isRead'] as bool)
                                    const Icon(
                                      Icons.done_all,
                                      size: 16,
                                      color: AppColors.blue500,
                                    ),
                                ],
                              ),
                              if (conversation['type'] == 'group')
                                Text(
                                  '${conversation['member_count']} members',
                                  style: AppTextStyles.extraSmall.copyWith(
                                    color: AppColors.gray400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    final selectedConversation = _getConversations().firstWhere(
      (conv) => conv['id'] == selectedChatId,
    );

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.blue200),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (selectedConversation['type'] == 'group')
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.blue500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people,
                        color: AppColors.white,
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            selectedConversation['avatar'] as String,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedConversation['name'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        selectedConversation['type'] == 'group'
                            ? '${selectedConversation['member_count']} members'
                            : selectedConversation['status'] as String,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.call, size: 16),
                    color: AppColors.gray700,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.videocam, size: 16),
                    color: AppColors.gray700,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, size: 16),
                    color: AppColors.gray700,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: Container(
            color: AppColors.gray50,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _getMessages().length,
              itemBuilder: (context, index) {
                final message = _getMessages()[index];
                final isSent = message['isSent'] as bool;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: isSent
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSent) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                message['avatar'] as String? ?? '',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSent ? AppColors.blue500 : AppColors.gray100,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppRadius.xl),
                            topRight: const Radius.circular(AppRadius.xl),
                            bottomLeft: Radius.circular(isSent ? AppRadius.xl : AppRadius.sm),
                            bottomRight: Radius.circular(isSent ? AppRadius.sm : AppRadius.xl),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['content'] as String,
                              style: AppTextStyles.small.copyWith(
                                color: isSent ? AppColors.white : AppColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message['time'] as String,
                                  style: AppTextStyles.extraSmall.copyWith(
                                    color: isSent
                                        ? AppColors.blue100
                                        : AppColors.gray500,
                                  ),
                                ),
                                if (isSent) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message['isRead'] as bool
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 12,
                                    color: AppColors.blue100,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        // Message Input
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.blue200),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.attach_file, size: 16),
                color: AppColors.gray700,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.gray400),
                    ),
                    style: AppTextStyles.body,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        // Send message
                        messageController.clear();
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.emoji_emotions_outlined, size: 16),
                color: AppColors.gray700,
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: IconButton(
                  onPressed: () {
                    if (messageController.text.trim().isNotEmpty) {
                      // Send message
                      messageController.clear();
                    }
                  },
                  icon: const Icon(Icons.send, size: 16),
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getConversations() {
    return [
      {
        'id': 'chat-1',
        'type': 'direct',
        'name': 'Tran Thi Lan',
        'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b1c0?w=100&h=100&fit=crop&crop=face',
        'lastMessage': 'Can you send me the Data Structures materials?',
        'time': '14:30',
        'unread_count': 2,
        'isRead': false,
        'status': 'Active 5 minutes ago',
      },
      {
        'id': 'chat-2',
        'type': 'direct',
        'name': 'Hoang Van Hung',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
        'lastMessage': 'Thanks for helping me with the homework!',
        'time': '12:15',
        'unread_count': 0,
        'isRead': true,
        'status': 'Active 2 hours ago',
      },
      {
        'id': 'group-1',
        'type': 'group',
        'name': 'K64-CS Study Group',
        'avatar': '',
        'lastMessage': 'Do Thi Mai: Is anyone going to class tomorrow?',
        'time': '16:45',
        'unread_count': 0,
        'isRead': true,
        'member_count': 15,
      },
    ];
  }

  List<Map<String, dynamic>> _getMessages() {
    return [
      {
        'content': 'Hi! I need help with Data Structures homework',
        'time': '14:25',
        'isSent': false,
        'isRead': true,
        'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b1c0?w=100&h=100&fit=crop&crop=face',
      },
      {
        'content': 'Hi Lan! Which homework are you asking about?',
        'time': '14:26',
        'isSent': true,
        'isRead': true,
      },
      {
        'content': 'The one about binary trees. I\'m stuck on the traverse part',
        'time': '14:28',
        'isSent': false,
        'isRead': true,
        'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b1c0?w=100&h=100&fit=crop&crop=face',
      },
      {
        'content': 'I understand. Traverse has 3 types: inorder, preorder, postorder. Which one do you need?',
        'time': '14:29',
        'isSent': true,
        'isRead': true,
      },
      {
        'content': 'Can you send me the Data Structures materials?',
        'time': '14:30',
        'isSent': false,
        'isRead': false,
        'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b1c0?w=100&h=100&fit=crop&crop=face',
      },
    ];
  }
}
