import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'support_tickets_page.dart';

class SupportChatPage extends StatefulWidget {
  final int? ticketId;
  final String? ticketNumber;

  const SupportChatPage({
    super.key,
    this.ticketId,
    this.ticketNumber,
  });

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _messages = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSending = false;
  Map<String, dynamic>? _replyingTo;
  File? _selectedImage;
  String? _imagePreviewPath;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _currentUser = await AuthService.getCurrentUser();

    if (widget.ticketId != null) {
      await _loadTicketAndMessages();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTicketAndMessages() async {
    try {
      final messages = await SupabaseService.getTicketMessages(widget.ticketId!);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imagePreviewPath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imagePreviewPath = null;
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty && _selectedImage == null) return;
    if (_currentUser == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      int ticketId = widget.ticketId ?? 0;

      // Create ticket if doesn't exist
      if (ticketId == 0) {
        final ticket = await SupabaseService.createSupportTicket(
          userId: int.parse(_currentUser!.id),
          subject: messageText.length > 50 ? messageText.substring(0, 50) : messageText,
          category: 'general',
        );

        if (ticket != null) {
          ticketId = ticket['id'];
        } else {
          throw Exception('Failed to create ticket');
        }
      }

      // Upload image if selected
      String? attachmentUrl;
      if (_selectedImage != null) {
        debugPrint('🔵 Uploading image from: ${_selectedImage!.path}');
        attachmentUrl = await SupabaseService.uploadSupportAttachment(
          _selectedImage!.path,
          ticketId,
        );

        if (attachmentUrl == null) {
          throw Exception('Failed to upload image');
        }
        debugPrint('🟢 Image uploaded to: $attachmentUrl');
      }

      // Send message
      final message = await SupabaseService.sendSupportMessage(
        ticketId: ticketId,
        senderId: int.parse(_currentUser!.id),
        message: messageText.isEmpty ? '[Image]' : messageText,
        senderType: 'customer',
        replyToId: _replyingTo?['id'],
        attachmentUrl: attachmentUrl,
      );

      if (message != null) {
        setState(() {
          _messages.add(message);
          _messageController.clear();
          _replyingTo = null;
          _selectedImage = null;
          _imagePreviewPath = null;
        });

        // Navigate to ticket if just created
        if (widget.ticketId == null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SupportChatPage(
                  ticketId: ticketId,
                  ticketNumber: message['ticket_id']?.toString(),
                ),
              ),
            );
          }
          return;
        }

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _setReplyTo(Map<String, dynamic> message) {
    setState(() {
      _replyingTo = message;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _viewFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isCurrentUser = message['sender_id'].toString() == _currentUser?.id;
    final alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isCurrentUser
        ? AppColors.primaryOrange
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200]);
    final textColor = isCurrentUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black);

    // Find replied message
    Map<String, dynamic>? repliedMessage;
    if (message['reply_to_id'] != null) {
      try {
        repliedMessage = _messages.firstWhere((m) => m['id'] == message['reply_to_id']);
      } catch (e) {
        // Message not found
      }
    }

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () => _setReplyTo(message),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Replied message preview
              if (repliedMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primaryOrange,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repliedMessage['sender_type'] == 'customer' ? 'You' : 'Support',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        repliedMessage['message'] ?? '',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              // Image attachment
              if (message['attachment_url'] != null) ...[
                GestureDetector(
                  onTap: () => _viewFullImage(message['attachment_url']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message['attachment_url'],
                      width: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Failed to load image', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (message['message'] != '[Image]') const SizedBox(height: 8),
              ],

              // Message text
              if (message['message'] != '[Image]')
                Text(
                  message['message'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 4),

              // Timestamp
              Text(
                _formatTime(message['created_at']),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Support Chat'),
            if (widget.ticketNumber != null)
              Text(
                widget.ticketNumber!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (widget.ticketId != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportTicketsPage(),
                  ),
                );
              },
              tooltip: 'View all tickets',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTicketAndMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages list
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.support_agent,
                                size: 80,
                                color: AppColors.primaryOrange.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start a conversation',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Send a message to our support team',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),

                // Reply preview bar
                if (_replyingTo != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[200],
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 40,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Replying to ${_replyingTo!['sender_type'] == 'customer' ? 'yourself' : 'support'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _replyingTo!['message'] ?? '',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _cancelReply,
                        ),
                      ],
                    ),
                  ),

                // Image preview (before sending)
                if (_imagePreviewPath != null)
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[100],
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePreviewPath!),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Image ready to send',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Message input
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _pickImage,
                        color: AppColors.primaryOrange,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.primaryOrange,
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                onPressed: _sendMessage,
                                padding: EdgeInsets.zero,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Full-screen image viewer
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 50),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
