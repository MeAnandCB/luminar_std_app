import 'dart:io';
import 'package:luminar_std/core/utils/app_utils.dart';
import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/core/utils/logger_utils.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:luminar_std/presentation/chat_screen/widgets/audio_player.dart';
import 'package:luminar_std/presentation/chat_screen/widgets/forward_message.dart';

import 'package:record/record.dart';
import 'dart:math' as _math;

import 'package:luminar_std/presentation/chat_screen/widgets/preseigner_url.dart';
import 'package:luminar_std/repository/chat_list_screen/models/chat.dart';
import 'package:luminar_std/repository/chat_list_screen/models/message.dart';
import 'package:luminar_std/repository/chat_list_screen/models/user.dart';
import 'package:luminar_std/repository/chat_list_screen/service/api_service.dart';
import 'package:luminar_std/repository/chat_list_screen/service/websocket_service.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as pathLib;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:luminar_std/presentation/widgets/status_screens.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final User currentUser;
  final String websocketUrl;
  final ChatApiService apiService;
  final WebSocketService? webSocketService;

  const ChatScreen({
    super.key,
    required this.chat,
    required this.currentUser,
    required this.websocketUrl,
    required this.apiService,
    this.webSocketService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<Message> _messages = [];
  late WebSocketService _webSocketService;
  late ScrollController _scrollController;
  bool _isLoadingMessages = true;
  String? _error;
  late Timer _pollTimer;
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _deleteSubscription;

  // ── Emoji picker state ────────────────────────────────────────────────────
  bool _showEmojiPicker = false;

  // ── Reply state ────────────────────────────────────────────────────────────
  Message? _replyingTo;
  late AnimationController _replyBarAnim;
  late Animation<double> _replyBarFade;

  // ── Upload state ───────────────────────────────────────────────────────────
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;
  late FileUploadService _fileUploadService;

  bool _isPicking = false;

  // ── Caption / image preview state ─────────────────────────────────────────
  File? _pendingImageFile;
  String _captionText = '';
  final TextEditingController _captionController = TextEditingController();
  bool _isDownloading = false;
  String? _downloadingUrl;

  // ── All chats (for forward sheet) ─────────────────────────────────────────
  List<Chat> _allChats = [];

  // ── Edit state ─────────────────────────────────────────────────────────────
  Message? _editingMessage;
  bool _isEditing = false;
  late AnimationController _editBarAnim;
  late Animation<double> _editBarFade;

  // ── Voice recording state (WhatsApp-style inline) ─────────────────────────
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isVoiceRecording = false; // mic held down / recording active
  bool _voiceLocked = false; // swiped up to lock (hands-free mode)
  bool _voiceCancelled = false; // swiped left to cancel
  Duration _voiceElapsed = Duration.zero;
  String? _voiceFilePath;
  Timer? _voiceTimer;
  Timer? _voiceAmpTimer;
  double _micDragDx = 0.0; // horizontal drag (left = cancel)
  double _micDragDy = 0.0; // vertical drag (up = lock)
  final List<double> _voiceBars = List.filled(28, 2.0);
  final _voiceRng = _math.Random();
  late AnimationController _voiceBarAnim; // blink dot

  // Pagination
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 50;

  // Swipe-to-reply tracking per message
  final Map<String, double> _swipeDx = {};
  final Map<String, AnimationController> _swipeReturnAnims = {};
  final Map<String, bool> _swipeTriggered = {};

  List<Message> get _mainMessages => List.from(_messages);

  @override
  void initState() {
    super.initState();

    _fileUploadService = FileUploadService(baseUrl: widget.apiService.baseUrl, token: widget.apiService.token);

    _replyBarAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _replyBarFade = CurvedAnimation(parent: _replyBarAnim, curve: Curves.easeOut);

    _editBarAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _editBarFade = CurvedAnimation(parent: _editBarAnim, curve: Curves.easeOut);

    _voiceBarAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    });

    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });

    _messageController.addListener(() => setState(() {}));

    _webSocketService =
        widget.webSocketService ??
        WebSocketService(url: widget.websocketUrl, currentUser: widget.currentUser, apiService: widget.apiService);

    _webSocketService.onConnected = () => _webSocketService.updateUserStatus(true);

    _messageSubscription = _webSocketService.messageStream.listen((message) {
      if (message.chatId.toString() == widget.chat.uid && mounted) {
        if (message.isDeleted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.uid == message.uid);
            if (index != -1) _messages[index] = message;
          });
        } else {
          final exists = _messages.any((m) => m.uid == message.uid);
          if (!exists) {
            setState(() => _messages.insert(0, message));
            _scrollToBottom();
          }
        }
      }
    });

    _deleteSubscription = _webSocketService.deleteStream.listen((deleteData) {
      final chatUid = deleteData['chat_uid'];
      final messageUid = deleteData['message_uid'];
      if (chatUid == widget.chat.uid && mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.uid == messageUid);
          if (index != -1) {
            final originalMessage = _messages[index];
            _messages[index] = originalMessage.copyWith(
              isDeleted: true,
              content: '',
              messageType: 'text',
              deletedAt: DateTime.now(),
            );
          }
        });
      }
    });

    if (widget.chat.chatType == ChatType.individual && widget.chat.otherParticipant != null) {
      _statusSubscription = _webSocketService.statusStream.listen((s) {
        if (s['user_id'] == widget.chat.otherParticipant!.id && mounted) {
          setState(() {});
        }
      });
    }

    if (widget.webSocketService == null) _webSocketService.connect();
    _loadMessages();
    _startPolling();
    _loadAllChats(); // ← NEW
  }

  @override
  void dispose() {
    _replyBarAnim.dispose();
    _editBarAnim.dispose();
    _voiceBarAnim.dispose();
    _voiceTimer?.cancel();
    _voiceAmpTimer?.cancel();
    _audioRecorder.dispose();
    _messageFocusNode.dispose();
    for (final c in _swipeReturnAnims.values) {
      c.dispose();
    }
    try {
      _pollTimer.cancel();
    } catch (_) {}
    _statusSubscription?.cancel();
    _messageSubscription?.cancel();
    _deleteSubscription?.cancel();
    if (widget.webSocketService == null) _webSocketService.disconnect();
    _messageController.dispose();
    _captionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Load all chats for forward sheet ──────────────────────────────────────
  Future<void> _loadAllChats() async {
    try {
      final response = await widget.apiService.fetchChats();
      if (mounted && response.success && response.data != null) {
        setState(() => _allChats = response.data!);
      }
    } catch (_) {}
  }

  // ── Emoji picker toggle ────────────────────────────────────────────────────
  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _messageFocusNode.requestFocus();
    } else {
      _messageFocusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    final controller = _messageController;
    final text = controller.text;
    final selection = controller.selection;

    final newText = selection.isValid
        ? text.replaceRange(selection.start, selection.end, emoji.emoji)
        : text + emoji.emoji;

    final newOffset = selection.isValid ? selection.start + emoji.emoji.length : newText.length;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  // ── Reply helpers ──────────────────────────────────────────────────────────
  void _startReply(Message message) {
    HapticFeedback.lightImpact();
    setState(() => _replyingTo = message);
    _replyBarAnim.forward();
    Future.delayed(const Duration(milliseconds: 80), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    _replyBarAnim.reverse().then((_) {
      if (mounted) setState(() => _replyingTo = null);
    });
  }

  // ── Edit helpers ───────────────────────────────────────────────────────────
  void _startEdit(Message message) {
    HapticFeedback.lightImpact();
    // Cancel reply mode if active
    if (_replyingTo != null) _cancelReply();
    setState(() => _editingMessage = message);
    _editBarAnim.forward();
    // Pre-fill the text field with current content
    _messageController.text = message.content;
    _messageController.selection = TextSelection.collapsed(offset: message.content.length);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _messageFocusNode.requestFocus();
    });
  }

  void _cancelEdit() {
    _editBarAnim.reverse().then((_) {
      if (mounted) setState(() => _editingMessage = null);
    });
    _messageController.clear();
  }

  Future<void> _submitEdit() async {
    final newContent = _messageController.text.trim();
    if (newContent.isEmpty || _editingMessage == null) return;

    // Nothing changed — just cancel
    if (newContent == _editingMessage!.content) {
      _cancelEdit();
      return;
    }

    final message = _editingMessage!;
    setState(() => _isEditing = true);

    // Optimistically update the bubble immediately — this is what the user sees.
    // Even if the API returns only a success string (not a full message object),
    // this optimistic version is the correct final state.
    final optimisticUpdated = message.copyWith(content: newContent, isEdited: true, updatedAt: DateTime.now());
    setState(() {
      final idx = _messages.indexWhere((m) => m.uid == message.uid);
      if (idx != -1) _messages[idx] = optimisticUpdated;
    });

    _cancelEdit();
    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);

    try {
      // Returns null when the API responds with a success string instead of
      // a full message object — in that case we keep the optimistic version.
      final response = await widget.apiService.editMessage(
        chatUid: widget.chat.uid,
        messageUid: message.uid,
        content: newContent,
      );
      if (mounted && response.success && response.data != null) {
        // API returned a full message object — use it as the source of truth
        setState(() {
          final idx = _messages.indexWhere((m) => m.uid == message.uid);
          if (idx != -1) _messages[idx] = response.data!;
        });
      }
      // If updated == null the optimistic bubble is already correct — no action needed
    } catch (e) {
      // Roll back to original message on hard failure
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.uid == message.uid);
          if (idx != -1) _messages[idx] = message;
        });
        _showErrorSnackbar('Failed to edit message. Please try again.');
        debugPrint('[Edit] Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isEditing = false);
    }
  }

  // ── Attach button ─────────────────────────────────────────────────────────
  void _onAttachPressed() {
    if (_isPicking || _isUploading) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildAttachSheet(),
    );
  }

  // ── Attach sheet — full grid of all supported types ────────────────────────
  Widget _buildAttachSheet() {
    final items = [
      _AttachItem(
        icon: Icons.image_rounded,
        label: 'Photo',
        sublabel: 'jpg · png · webp · heic',
        color: const Color(0xFF7B9FD4),
        onTap: () {
          Navigator.pop(context);
          _pickImages();
        },
      ),
      _AttachItem(
        icon: Icons.camera_alt_rounded,
        label: 'Camera',
        sublabel: 'take a photo',
        color: Colors.green.shade600,
        onTap: () {
          Navigator.pop(context);
          _onCameraPressed();
        },
      ),
      _AttachItem(
        icon: Icons.videocam_rounded,
        label: 'Video',
        sublabel: 'mp4 · mov',
        color: Colors.pink.shade500,
        onTap: () {
          Navigator.pop(context);
          _pickVideo();
        },
      ),
      _AttachItem(
        icon: Icons.mic_rounded,
        label: 'Audio',
        sublabel: 'mp3 · recorded',
        color: Colors.purple.shade400,
        onTap: () {
          Navigator.pop(context);
          _pickAudio();
        },
      ),
      _AttachItem(
        icon: Icons.picture_as_pdf_rounded,
        label: 'PDF',
        sublabel: '.pdf',
        color: Colors.red.shade600,
        onTap: () {
          Navigator.pop(context);
          _pickByExtensions(['pdf']);
        },
      ),
      _AttachItem(
        icon: Icons.description_rounded,
        label: 'Word',
        sublabel: 'doc · docx',
        color: const Color(0xFF1565C0),
        onTap: () {
          Navigator.pop(context);
          _pickByExtensions(['doc', 'docx']);
        },
      ),
      _AttachItem(
        icon: Icons.table_chart_rounded,
        label: 'Excel',
        sublabel: 'xls · xlsx',
        color: const Color(0xFF2E7D32),
        onTap: () {
          Navigator.pop(context);
          _pickByExtensions(['xls', 'xlsx']);
        },
      ),
      _AttachItem(
        icon: Icons.slideshow_rounded,
        label: 'PowerPoint',
        sublabel: 'ppt · pptx',
        color: const Color(0xFFE65100),
        onTap: () {
          Navigator.pop(context);
          _pickByExtensions(['ppt', 'pptx']);
        },
      ),
      _AttachItem(
        icon: Icons.text_snippet_rounded,
        label: 'Text',
        sublabel: '.txt',
        color: const Color(0xFF546E7A),
        onTap: () {
          Navigator.pop(context);
          _pickByExtensions(['txt']);
        },
      ),
      _AttachItem(
        icon: Icons.folder_zip_rounded,
        label: 'Archive',
        sublabel: '.zip',
        color: const Color(0xFF6A1B9A),
        onTap: () {
          Navigator.pop(context);
          _pickByExtensions(['zip']);
        },
      ),
      _AttachItem(
        icon: Icons.attach_file_rounded,
        label: 'Any File',
        sublabel: 'all types',
        color: Colors.grey.shade600,
        onTap: () {
          Navigator.pop(context);
          _pickAnyFile();
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            // 4-column grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: items.map((item) => _buildAttachGridItem(item)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachGridItem(_AttachItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          Text(
            item.sublabel,
            style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onCameraPressed() {
    if (_isPicking || _isUploading) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                'Camera',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ── Photo ──────────────────────────────────────────
                    _buildCameraOption(
                      icon: Icons.photo_camera_rounded,
                      label: 'Photo',
                      color: Colors.green.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    // ── Video ──────────────────────────────────────────
                    _buildCameraOption(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: Colors.pink.shade500,
                      onTap: () {
                        Navigator.pop(context);
                        _recordVideo();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Record video from camera ───────────────────────────────────────────────
  Future<void> _recordVideo() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );
      if (picked == null) return;
      final file = await _resolvePickedFile(
        PlatformFile(path: picked.path, name: pathLib.basename(picked.path), size: 0),
      );
      if (file == null) {
        _showErrorSnackbar('Could not read video file.');
        return;
      }
      await _uploadAndSendFile(file, 'file');
    } on PlatformException catch (e) {
      debugPrint('[Camera] video PlatformException: $e');
      _showErrorSnackbar('Could not record video');
    } catch (e) {
      debugPrint('[Camera] video error: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ── Gallery image picker ────────────────────────────────────────────────────
  // Uses image_picker for JPEG/PNG/WEBP (with quality compression)
  // Falls back to FilePicker for HEIC and other raw formats
  Future<void> _pickImages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      // Pick single image — goes to caption sheet before sending
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null) return;
      if (mounted) _showImageCaptionSheet(File(picked.path));
    } on PlatformException catch (e) {
      debugPrint('[Picker] image gallery PlatformException: $e');
      // Fallback: use FilePicker which supports HEIC/WEBP/RAW
      await _pickImageByFilePicker();
    } catch (e) {
      debugPrint('[Picker] image gallery error: $e');
      await _pickImageByFilePicker();
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // FilePicker fallback for HEIC / WEBP / unsupported formats
  Future<void> _pickImageByFilePicker() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'gif', 'bmp'],
        withData: false,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = await _resolvePickedFile(result.files.single);
      if (file == null) {
        if (mounted) _showErrorSnackbar('Could not read image file.');
        return;
      }
      if (mounted) _showImageCaptionSheet(file);
    } catch (e) {
      debugPrint('[Picker] FilePicker image fallback error: $e');
      if (mounted) _showErrorSnackbar('Could not open gallery');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
      if (picked == null) return;
      if (mounted) _showImageCaptionSheet(File(picked.path));
    } on PlatformException catch (e) {
      debugPrint('[Picker] PlatformException (_pickImage): $e');
      if (mounted) _showErrorSnackbar('Could not open camera');
    } catch (e) {
      debugPrint('[Picker] Unexpected error (_pickImage): $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _showImageCaptionSheet(File imageFile) {
    _captionController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageCaptionSheet(
        imageFile: imageFile,
        captionController: _captionController,
        onSend: (caption) {
          Navigator.pop(context);
          _uploadAndSendFile(imageFile, 'image', caption: caption.trim());
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // ── Video picker (mp4 / mov) ───────────────────────────────────────────────
  Future<void> _pickVideo() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (picked == null) return;
      await _uploadAndSendFile(File(picked.path), 'file');
    } on PlatformException catch (e) {
      debugPrint('[Picker] video: $e');
      _showErrorSnackbar('Could not open video picker');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ── Document picker — by allowed extensions ────────────────────────────────
  Future<void> _pickByExtensions(List<String> extensions) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        withData: false,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final pf = result.files.single;
      final file = await _resolvePickedFile(pf);
      if (file == null) {
        _showErrorSnackbar('Could not read file. Try again.');
        return;
      }

      debugPrint('[Picker] resolved path: ${file.path}');
      await _uploadAndSendFile(file, 'file');
    } on PlatformException catch (e) {
      debugPrint('[Picker] custom ext $extensions: $e');
      _showErrorSnackbar('Could not open file picker');
    } catch (e) {
      debugPrint('[Picker] _pickByExtensions error: $e');
      _showErrorSnackbar('Failed to pick file: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ── Any file picker (fallback) ─────────────────────────────────────────────
  Future<void> _pickAnyFile() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;

      final pf = result.files.single;
      final file = await _resolvePickedFile(pf);
      if (file == null) {
        _showErrorSnackbar('Could not read file. Try again.');
        return;
      }

      debugPrint('[Picker] any file resolved: ${file.path}');
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      if (mimeType.startsWith('image/')) {
        if (mounted) _showImageCaptionSheet(file);
      } else {
        await _uploadAndSendFile(file, 'file');
      }
    } on PlatformException catch (e) {
      debugPrint('[Picker] any file: $e');
      _showErrorSnackbar('Could not open file picker');
    } catch (e) {
      debugPrint('[Picker] _pickAnyFile error: $e');
      _showErrorSnackbar('Failed to pick file: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ── Audio file picker ──────────────────────────────────────────────────────
  Future<void> _pickAudio() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: false, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;

      final pf = result.files.single;
      final file = await _resolvePickedFile(pf);
      if (file == null) {
        _showErrorSnackbar('Could not read audio file.');
        return;
      }

      debugPrint('[Picker] audio resolved: ${file.path}');
      await _uploadAndSendFile(file, 'audio');
    } on PlatformException catch (e) {
      debugPrint('[Picker] PlatformException (_pickAudio): $e');
    } catch (e) {
      debugPrint('[Picker] Unexpected error (_pickAudio): $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // ── Legacy document picker ─────────────────────────────────────────────────
  Future<void> _pickDocument() async => _pickAnyFile();

  // ── Resolve PlatformFile → real File (handles Android content URIs) ────────
  //
  // On Android, FilePicker may return a content:// URI in `path`.
  // We copy the bytes (via pf.bytes if available, or read the path directly)
  // to a temp file with the correct name so File() works everywhere.
  Future<File?> _resolvePickedFile(PlatformFile pf) async {
    try {
      final name = pf.name;
      final dir = await getTemporaryDirectory();
      final dest = File('${dir.path}/$name');

      // If FilePicker already gave us bytes (withData: true case or small file)
      if (pf.bytes != null && pf.bytes!.isNotEmpty) {
        await dest.writeAsBytes(pf.bytes!, flush: true);
        debugPrint('[Picker] wrote from bytes: ${dest.path}');
        return dest;
      }

      // Otherwise use the path directly
      final srcPath = pf.path;
      if (srcPath == null) {
        debugPrint('[Picker] pf.path is null and no bytes');
        return null;
      }

      final src = File(srcPath);
      if (!await src.exists()) {
        debugPrint('[Picker] source file does not exist: $srcPath');
        return null;
      }

      // Copy to temp so we always have a real filesystem path
      await src.copy(dest.path);
      debugPrint('[Picker] copied to temp: ${dest.path}');
      return dest;
    } catch (e) {
      debugPrint('[Picker] _resolvePickedFile error: $e');
      return null;
    }
  }

  // ── WhatsApp-style inline voice recording ────────────────────────────────
  //
  //  Tap  → start recording, button becomes animated mic
  //  Slide left  → cancel (threshold -80px)
  //  Slide up    → lock (hands-free; threshold -60px)
  //  Release     → stop + send (when not locked/cancelled)
  //  While locked: tap send button to send, tap ✕ to cancel
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _voiceRecordStart() async {
    if (_isUploading || _isPicking || _isVoiceRecording) return;

    final ok = await _audioRecorder.hasPermission();
    if (!ok) {
      _showErrorSnackbar('Microphone permission denied');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );
    } catch (e) {
      debugPrint('[Voice] start error: $e');
      _showErrorSnackbar('Could not start recording');
      return;
    }

    _voiceFilePath = path;
    if (!mounted) return;

    setState(() {
      _isVoiceRecording = true;
      _voiceLocked = false;
      _voiceCancelled = false;
      _voiceElapsed = Duration.zero;
      _micDragDx = 0.0;
      _micDragDy = 0.0;
    });

    HapticFeedback.mediumImpact();

    _voiceTimer?.cancel();
    _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isVoiceRecording) {
        setState(() => _voiceElapsed += const Duration(seconds: 1));
      }
    });

    _voiceAmpTimer?.cancel();
    _voiceAmpTimer = Timer.periodic(const Duration(milliseconds: 120), (_) async {
      if (!mounted || !_isVoiceRecording) return;
      double h;
      try {
        final amp = await _audioRecorder.getAmplitude();
        final db = amp.current.clamp(-60.0, 0.0);
        final ratio = (db + 60.0) / 60.0;
        h = 2.0 + ratio * 30.0 + _voiceRng.nextDouble() * 4;
      } catch (_) {
        h = 2.0 + _voiceRng.nextDouble() * 10;
      }
      if (mounted && _isVoiceRecording) {
        setState(() {
          _voiceBars.removeAt(0);
          _voiceBars.add(h.clamp(2.0, 32.0));
        });
      }
    });
  }

  Future<void> _voiceRecordStop({bool send = true}) async {
    // Capture elapsed BEFORE any state reset
    final elapsedSecs = _voiceElapsed.inSeconds;

    _voiceTimer?.cancel();
    _voiceAmpTimer?.cancel();
    _voiceTimer = null;
    _voiceAmpTimer = null;

    if (!_isVoiceRecording) return;

    String? stoppedPath;
    try {
      stoppedPath = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('[Voice] stop error: $e');
    }

    // Use the path saved at start if stop() did not return one
    final path = stoppedPath ?? _voiceFilePath;

    if (!mounted) return;
    setState(() {
      _isVoiceRecording = false;
      _voiceLocked = false;
      _voiceCancelled = false;
      _micDragDx = 0.0;
      _micDragDy = 0.0;
    });

    if (send && path != null) {
      final file = File(path);
      final exists = await file.exists();
      debugPrint('[Voice] path=$path exists=$exists elapsed=${elapsedSecs}s');
      if (exists && elapsedSecs >= 1) {
        await _uploadAndSendFile(file, 'audio');
      } else {
        if (exists) await file.delete();
        if (mounted && elapsedSecs < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Hold mic longer to record'),
              backgroundColor: const Color(0xFF1A1A2E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  void _voiceOnDragUpdate(LongPressMoveUpdateDetails details) {
    if (!_isVoiceRecording || _voiceLocked) return;
    // localOffsetFromOrigin = total offset from where the long press started
    final dx = details.localOffsetFromOrigin.dx;
    final dy = details.localOffsetFromOrigin.dy;
    setState(() {
      _micDragDx = dx.clamp(-120.0, 4.0);
      _micDragDy = dy.clamp(-80.0, 4.0);
    });

    // Slide up → lock (hands-free)
    if (_micDragDy <= -60.0 && !_voiceLocked) {
      HapticFeedback.mediumImpact();
      setState(() {
        _voiceLocked = true;
        _micDragDx = 0.0;
        _micDragDy = 0.0;
      });
    }
    // Slide left → cancel
    if (_micDragDx <= -80.0 && !_voiceLocked) {
      HapticFeedback.mediumImpact();
      setState(() => _voiceCancelled = true);
      _voiceRecordStop(send: false);
    }
  }

  void _voiceOnDragEnd(LongPressEndDetails _) {
    if (!_isVoiceRecording || _voiceLocked || _voiceCancelled) return;
    _voiceRecordStop(send: true);
  }

  Future<void> _uploadAndSendFile(File file, String hintType, {String caption = ''}) async {
    final replyToUid = _replyingTo?.uid;

    final fileName = pathLib.basename(file.path);
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final resolvedType = _resolveMessageTypeLocal(mimeType);

    const supported = {'image', 'file', 'audio'}; // backend only supports these 3
    if (!supported.contains(resolvedType)) {
      debugPrint(
        '[Upload] Unsupported file type blocked — '
        'fileName: $fileName | MIME: $mimeType | resolvedType: $resolvedType',
      );
      _showUnsupportedSnackbar();
      return;
    }

    if (_replyingTo != null) _cancelReply();

    final localSizeBytes = await file.length();
    final localSizeLabel = _formatFileSize(localSizeBytes);
    final optimisticUid = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      uid: optimisticUid,
      chatId: int.tryParse(widget.chat.uid) ?? 0,
      sender: widget.currentUser,
      messageType: resolvedType,
      content: caption.isNotEmpty ? caption : fileName,
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      readBy: [],
      fileName: fileName,
      file: localSizeLabel,
      replyTo: replyToUid,
    );

    setState(() {
      _messages.insert(0, optimistic);
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadingFileName = fileName;
    });
    _scrollToBottom();

    try {
      final result = await _fileUploadService.uploadFile(
        file,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      final response = await widget.apiService.sendFileMessage(
        chatUid: widget.chat.uid,
        upload: result,
        replyTo: replyToUid,
        caption: caption.isNotEmpty ? caption : null,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final actual = response.data!;
          setState(() {
            final idx = _messages.indexWhere((m) => m.uid == optimisticUid);
            if (idx != -1) _messages[idx] = actual;
            _isUploading = false;
            _uploadProgress = 0.0;
            _uploadingFileName = null;
          });
          _webSocketService.broadcastLocalMessage(actual);
        } else {
          throw Exception(response.message);
        }
      }
    } catch (e, stack) {
      debugPrint('[Upload] ✗ Error uploading "$fileName": $e');
      debugPrint('[Upload] Stack: $stack');

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.uid == optimisticUid);
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadingFileName = null;
        });
        _showErrorSnackbar('Failed to send file. Please try again.');
      }
    }
  }

  String _resolveMessageTypeLocal(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('audio/')) return 'audio';
    // video/* → 'file' (backend rejects 'video' as message_type)
    return 'file';
  }

  void _showUnsupportedSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.orange.shade700, shape: BoxShape.circle),
              child: const Icon(Icons.block_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'This file is not supported',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 20, color: Colors.red.shade300),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Upload progress overlay ────────────────────────────────────────────────
  Widget _buildUploadProgressOverlay() {
    if (!_isUploading) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              strokeWidth: 2.5,
              color: const Color(0xFF7B9FD4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Uploading ${_uploadingFileName ?? "file"}…',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFF7B9FD4),
                  borderRadius: BorderRadius.circular(2),
                  minHeight: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Delete message ─────────────────────────────────────────────────────────
  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 24, bottom: 12),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.delete_outline_rounded, size: 28, color: Colors.red.shade600),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Delete Message',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'This message will be deleted for everyone. Are you sure you want to continue?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (message.content.isNotEmpty && !message.isImage && !message.isFile && !message.isAudio)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.reply_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            'Message preview',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: Color(0xFF1A1A2E), height: 1.4),
                      ),
                    ],
                  ),
                ),
              if (message.isImage && message.mediaUrl != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.image_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            'Photo message',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message.mediaUrl!,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 32)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (message.isFile)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B9FD4).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF7B9FD4), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.fileName ?? 'File',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                            ),
                            if (message.fileSizeLabel != null)
                              Text(message.fileSizeLabel!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _webSocketService.deleteMessage(widget.chat.uid, message.uid);
      setState(() {
        final index = _messages.indexWhere((m) => m.uid == message.uid);
        if (index != -1) {
          _messages[index] = message.copyWith(
            isDeleted: true,
            content: '',
            messageType: 'text',
            deletedAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      _showErrorSnackbar('Failed to delete: $e');
    }
  }

  // ── Load messages ──────────────────────────────────────────────────────────
  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoadingMessages = true;
        _error = null;
        _currentPage = 1;
        _hasNextPage = true;
      });
      final response = await widget.apiService.fetchMessages(widget.chat.uid, page: _currentPage, pageSize: _pageSize);
      if (mounted) {
        if (response.success && response.data != null) {
          final messages = response.data!;
          setState(() {
            _messages
              ..clear()
              ..addAll(messages)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _isLoadingMessages = false;
            if (messages.length < _pageSize) _hasNextPage = false;
          });
          _scrollToBottom();
        } else {
          setState(() {
            _error = response.message;
            _isLoadingMessages = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await widget.apiService.fetchMessages(widget.chat.uid, page: nextPage, pageSize: _pageSize);
      if (!mounted) return;
      if (response.success && response.data != null) {
        final older = response.data!;
        setState(() {
          _currentPage = nextPage;
          if (older.isEmpty || older.length < _pageSize) _hasNextPage = false;
          final existing = _messages.map((m) => m.uid).toSet();
          _messages.addAll(older.where((m) => !existing.contains(m.uid)));
          _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final response = await widget.apiService.fetchMessages(widget.chat.uid);
        if (!mounted || !response.success || response.data == null) return;
        final msgs = response.data!;
        final existing = _messages.map((m) => m.uid).toSet();
        final newMsgs = msgs.where((m) => !existing.contains(m.uid)).toList();
        if (newMsgs.isNotEmpty) {
          setState(() {
            _messages.addAll(newMsgs);
            _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });
          _scrollToBottom();
        }
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── Message Options Bottom Sheet ───────────────────────────────────────────
  void _showMessageOptions(BuildContext context, Message message) {
    if (message.isDeleted) return;
    final isMe = message.sender.id == widget.currentUser.id;
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['👍', '❤️', '😂', '😮', '😢', '🙏']
                        .map(
                          (emoji) => GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _webSocketService
                                  .sendMessage(emoji, chatUid: widget.chat.uid, replyTo: message.uid)
                                  .then((actual) {
                                    if (mounted) {
                                      setState(() => _messages.insert(0, actual));
                                      _webSocketService.broadcastLocalMessage(actual);
                                      _scrollToBottom();
                                    }
                                  })
                                  .catchError((_) {});
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                              child: Center(child: Text(emoji, style: TextStyle(fontSize: 20))),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Divider(height: 1, color: AppColors.borderColor),
                _messageOption(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  onTap: () {
                    Navigator.pop(context);
                    _startReply(message);
                  },
                ),
                // ── FORWARD (fully wired) ─────────────────────────────
                _messageOption(
                  icon: Icons.forward_rounded,
                  label: 'Forward',
                  onTap: () async {
                    Navigator.pop(context); // close options sheet

                    final result = await showForwardSheet(
                      context: context,
                      message: message,
                      allChats: _allChats,
                      apiService: widget.apiService,
                    );

                    if (!mounted) return;
                    if (result == null) return; // user dismissed

                    if (result.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Text('Message forwarded', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1A1A2E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      _showErrorSnackbar('Forward failed: ${result.error ?? "Unknown error"}');
                    }
                  },
                ),
                // ─────────────────────────────────────────────────────
                if (message.isText)
                  _messageOption(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: message.content));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
                    },
                  ),
                _messageOption(icon: Icons.info_outline_rounded, label: 'Info', onTap: () => Navigator.pop(context)),
                if (isMe) ...[
                  if (message.isText)
                    _messageOption(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: () {
                        Navigator.pop(context);
                        _startEdit(message);
                      },
                    ),
                  _messageOption(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: Colors.red.shade600,
                    onTap: () async {
                      Navigator.pop(context);
                      await _deleteMessage(message);
                    },
                  ),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageOption({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: c, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  // ── Send text ──────────────────────────────────────────────────────────────
  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final replyToUid = _replyingTo?.uid;
    final replyToContent = _replyingTo?.content;
    final replyToSender = _replyingTo?.sender.fullName;

    if (_replyingTo != null) _cancelReply();

    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);

    final optimistic = Message(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: int.tryParse(widget.chat.uid) ?? 0,
      sender: widget.currentUser,
      messageType: 'text',
      content: content,
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      readBy: [],
      replyTo: replyToUid,
      replyToContent: replyToContent,
      replyToInfo: replyToUid != null && replyToContent != null
          ? ReplyToInfo(uid: replyToUid, content: replyToContent, senderName: replyToSender ?? '')
          : null,
    );

    setState(() => _messages.insert(0, optimistic));
    _messageController.clear();
    _scrollToBottom();

    try {
      final actual = await _webSocketService.sendMessage(content, chatUid: widget.chat.uid, replyTo: replyToUid);
      setState(() {
        final idx = _messages.indexWhere((m) => m.uid == optimistic.uid);
        if (idx != -1) _messages[idx] = actual;
      });
      _webSocketService.broadcastLocalMessage(actual);
    } catch (e) {
      setState(() => _messages.removeWhere((m) => m.uid == optimistic.uid));
      _showErrorSnackbar('Failed to send: $e');
    }
  }

  bool _isOptimistic(Message m) => int.tryParse(m.uid) != null || m.uid.startsWith('upload_');

  // ── Time helpers ───────────────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m ${local.hour >= 12 ? "PM" : "AM"}';
  }

  String _dateSeparatorLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[local.weekday - 1];
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year.toString().substring(2)}';
  }

  bool _needsSeparator(Message older, Message newer) {
    final a = older.createdAt.toLocal();
    final b = newer.createdAt.toLocal();
    return !(a.year == b.year && a.month == b.month && a.day == b.day);
  }

  Color _senderNameColor(int senderId) {
    const colors = [
      Color(0xFF5B8CC4),
      Color(0xFFE57373),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFF9575CD),
      Color(0xFF4DB6AC),
      Color(0xFFF06292),
    ];
    return colors[senderId % colors.length];
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBarAvatar() {
    final chat = widget.chat;
    final other = chat.otherParticipant;
    final isOnline =
        chat.chatType == ChatType.individual && other != null && _webSocketService.userOnlineStatus[other.id] == true;

    Widget child;
    Color bgColor;
    ImageProvider? bgImage;

    if (chat.chatType == ChatType.individual) {
      bgColor = const Color(0xFF7B9FD4);
      bgImage = other?.profilePic != null ? NetworkImage(other!.profilePic!) : null;
      child = Text(
        chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
        style: TextStyle(color: Colors.white, fontSize: 15),
      );
    } else if (chat.chatType == ChatType.batch) {
      bgColor = Colors.orange.shade100;
      bgImage = null;
      child = const Icon(Icons.school, color: Colors.orange, size: 22);
    } else {
      bgColor = Colors.purple.shade100;
      bgImage = chat.groupIcon != null ? NetworkImage(chat.groupIcon!) : null;
      child = const Icon(Icons.group, color: Colors.purple, size: 22);
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: bgColor,
          backgroundImage: bgImage,
          child: bgImage == null ? child : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBarSubtitle() {
    final chat = widget.chat;
    if (chat.chatType == ChatType.individual) {
      final other = chat.otherParticipant;
      final isOnline = other != null && _webSocketService.userOnlineStatus[other.id] == true;
      return Row(
        children: [
          if (isOnline)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
            ),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(fontSize: 12, color: isOnline ? const Color(0xFF4CAF50) : Colors.grey.shade500),
          ),
        ],
      );
    } else if (chat.chatType == ChatType.batch) {
      return Row(
        children: [
          Icon(Icons.school_outlined, size: 12, color: Colors.orange.shade600),
          const SizedBox(width: 4),
          Text('Batch Chat', style: TextStyle(fontSize: 12, color: Colors.orange.shade600)),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.group_outlined, size: 12, color: Colors.purple.shade400),
          const SizedBox(width: 4),
          Text('Group Chat', style: TextStyle(fontSize: 12, color: Colors.purple.shade400)),
        ],
      );
    }
  }

  Widget _buildTicks(Message message) {
    if (_isOptimistic(message)) {
      if (message.uid.startsWith('upload_')) {
        return Icon(Icons.cloud_upload_outlined, size: 12, color: Colors.grey.shade400);
      }
      return Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400);
    }
    final isRead = message.readBy.isNotEmpty && message.readBy.any((id) => id != widget.currentUser.id);
    final color = isRead ? const Color(0xFF5B9BD5) : Colors.grey.shade400;
    return SizedBox(
      width: 20,
      height: 13,
      child: Stack(
        children: [
          Positioned(left: 0, child: Icon(Icons.check, size: 13, color: color)),
          Positioned(left: 5, child: Icon(Icons.check, size: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE1F0FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.isDark ? const Color(0xFF7EB3D4) : const Color(0xFF4A7FA5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedBubble(Message message, bool showAvatar) {
    final isMe = message.sender.id == widget.currentUser.id;
    final isGroupOrBatch = widget.chat.chatType == ChatType.group || widget.chat.chatType == ChatType.batch;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            SizedBox(
              width: 38,
              child: showAvatar
                  ? Stack(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundImage: message.sender.profilePic != null
                              ? NetworkImage(message.sender.profilePic!)
                              : null,
                          backgroundColor: Colors.grey.shade300,
                          child: message.sender.profilePic == null
                              ? Text(
                                  message.sender.fullName.isNotEmpty ? message.sender.fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 14),
                                )
                              : null,
                        ),
                        if (_webSocketService.userOnlineStatus[message.sender.id] == true)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: AppColors.statsGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.cardBackground, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe && (isGroupOrBatch || showAvatar))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.sender.fullName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isGroupOrBatch ? _senderNameColor(message.sender.id) : AppColors.primary,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Text(
                        'This message was deleted',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: (isGroupOrBatch && showAvatar)
                  ? CircleAvatar(
                      radius: 19,
                      backgroundImage: widget.currentUser.profilePic != null
                          ? NetworkImage(widget.currentUser.profilePic!)
                          : null,
                      backgroundColor: AppColors.primary,
                      child: widget.currentUser.profilePic == null
                          ? Text(
                              widget.currentUser.fullName.isNotEmpty
                                  ? widget.currentUser.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                            )
                          : null,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInBubbleReply(Message message) {
    final isMe = message.sender.id == widget.currentUser.id;

    final String quotedContent;
    final String? quotedSender;

    if (message.replyToInfo != null) {
      quotedContent = message.replyToInfo!.content;
      quotedSender = message.replyToInfo!.senderName;
    } else {
      final original = _messages.cast<Message?>().firstWhere((m) => m?.uid == message.replyTo, orElse: () => null);
      quotedContent = original?.content ?? message.replyToContent ?? '…';
      quotedSender = original?.sender.fullName;
    }

    return GestureDetector(
      onTap: () => _scrollToMessage(message.replyTo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isMe ? (AppColors.isDark ? const Color(0xFF1A3A5C) : const Color(0xFFC5D8EF)) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: isMe ? const Color(0xFF4A7FA5) : const Color(0xFF7B9FD4), width: 3.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quotedSender != null && quotedSender.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  quotedSender,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isMe ? const Color(0xFF4A7FA5) : const Color(0xFF7B9FD4),
                  ),
                ),
              ),
            Text(
              quotedContent,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToMessage(String? uid) {
    if (uid == null) return;
    final mains = _mainMessages;
    final idx = mains.indexWhere((m) => m.uid == uid);
    if (idx == -1) return;
    final estimated = idx * 82.0;
    _scrollController.animateTo(
      estimated.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
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
                  return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                },
                errorBuilder: (_, __, ___) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    const Text('Failed to load image', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(Message message) {
    if (message.uid.startsWith('upload_') && message.mediaUrl == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  strokeWidth: 2.5,
                  color: const Color(0xFF7B9FD4),
                ),
              ),
              const SizedBox(height: 8),
              Text('Uploading…', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    final url = message.mediaUrl;
    if (url == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
        child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
      );
    }

    final hasCaption = message.content.isNotEmpty && message.content != (message.fileName ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showFullScreenImage(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    final progress = loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null;
                    return Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2.5,
                                color: const Color(0xFF7B9FD4),
                              ),
                            ),
                            if (progress != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 32),
                        const SizedBox(height: 6),
                        Text('Image unavailable', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(bottom: 8, right: 8, child: _buildDownloadButton(url, message.fileName ?? 'image.jpg')),
          ],
        ),
        if (hasCaption)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
            child: Text(message.content, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
          ),
      ],
    );
  }

  Widget _buildDownloadButton(String url, String fileName) {
    final isThisDownloading = _isDownloading && _downloadingUrl == url;
    return GestureDetector(
      onTap: isThisDownloading ? null : () => _downloadFile(url, fileName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isThisDownloading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.download_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              isThisDownloading ? 'Saving…' : 'Download',
              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
    setState(() {
      _isDownloading = true;
      _downloadingUrl = url;
    });

    try {
      debugPrint('[Download] ▶ GET $url');
      debugPrint('[Download] fileName: $fileName');

      // ── 1. Download bytes ────────────────────────────────────────────────
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 120));

      debugPrint('[Download] status: ${response.statusCode}');
      debugPrint('[Download] bytes : ${response.bodyBytes.length}');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
      final bytes = response.bodyBytes;
      if (bytes.isEmpty) throw Exception('Empty response body');

      // ── 2. Resolve save directory ────────────────────────────────────────
      // Android → scoped external storage (no WRITE_EXTERNAL permission needed)
      // iOS     → application documents directory (accessible via Files app)
      Directory? saveDir;
      if (Platform.isAndroid) {
        saveDir = await getExternalStorageDirectory();
      }
      saveDir ??= await getApplicationDocumentsDirectory();
      if (!await saveDir.exists()) await saveDir.create(recursive: true);

      // Sanitise filename
      final safeName = fileName.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();
      final finalName = safeName.isNotEmpty ? safeName : 'download';
      final savePath = '${saveDir.path}/$finalName';

      debugPrint('[Download] savePath: $savePath');

      // ── 3. Write to disk ─────────────────────────────────────────────────
      await File(savePath).writeAsBytes(bytes, flush: true);
      debugPrint('[Download] ✓ saved');

      if (!mounted) return;

      // ── 4. Auto-open with native app via open_filex ──────────────────────
      //   PDF    → system PDF viewer
      //   mp4/mov→ native video player
      //   mp3/m4a→ music player
      //   docx   → Word / Docs / WPS
      //   xlsx   → Excel / Sheets
      //   jpg/png→ Photos / Gallery
      //   zip    → Files / ZArchiver
      final openResult = await OpenFilex.open(savePath);
      debugPrint('[Download] OpenFilex result: ${openResult.type} — ${openResult.message}');

      // ── 5. Snackbar — show path + Open button as fallback ────────────────
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                openResult.type == ResultType.done ? Icons.check_circle_outline : Icons.download_done_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      finalName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      openResult.type == ResultType.done ? 'Opened successfully' : savePath,
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Show Open button as fallback if auto-open failed
              if (openResult.type != ResultType.done)
                TextButton(
                  onPressed: () async {
                    final result = await OpenFilex.open(savePath);
                    if (result.type != ResultType.done) {
                      debugPrint('[Download] retry open failed: ${result.message}');
                    }
                  },
                  child: const Text(
                    'Open',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, stack) {
      debugPrint('[Download] ✗ Error: $e');
      debugPrint('[Download] Stack: $stack');
      if (mounted) _showErrorSnackbar('Download failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadingUrl = null;
        });
      }
    }
  }

  // ── File type helpers ──────────────────────────────────────────────────────
  static const Map<String, _FileTypeStyle> _fileStyles = {
    'pdf': _FileTypeStyle(color: Color(0xFFE53935), icon: Icons.picture_as_pdf_outlined, label: 'PDF'),
    'doc': _FileTypeStyle(color: Color(0xFF1565C0), icon: Icons.description_outlined, label: 'DOC'),
    'docx': _FileTypeStyle(color: Color(0xFF1565C0), icon: Icons.description_outlined, label: 'DOCX'),
    'xls': _FileTypeStyle(color: Color(0xFF2E7D32), icon: Icons.table_chart_outlined, label: 'XLS'),
    'xlsx': _FileTypeStyle(color: Color(0xFF2E7D32), icon: Icons.table_chart_outlined, label: 'XLSX'),
    'ppt': _FileTypeStyle(color: Color(0xFFE65100), icon: Icons.slideshow_outlined, label: 'PPT'),
    'pptx': _FileTypeStyle(color: Color(0xFFE65100), icon: Icons.slideshow_outlined, label: 'PPTX'),
    'txt': _FileTypeStyle(color: Color(0xFF546E7A), icon: Icons.text_snippet_outlined, label: 'TXT'),
    'csv': _FileTypeStyle(color: Color(0xFF00695C), icon: Icons.grid_on_outlined, label: 'CSV'),
    'zip': _FileTypeStyle(color: Color(0xFF6A1B9A), icon: Icons.folder_zip_outlined, label: 'ZIP'),
    'rar': _FileTypeStyle(color: Color(0xFF6A1B9A), icon: Icons.folder_zip_outlined, label: 'RAR'),
    // Audio formats
    'mp3': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.audio_file_outlined, label: 'MP3'),
    'wav': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.audio_file_outlined, label: 'WAV'),
    'm4a': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.audio_file_outlined, label: 'M4A'),
    'aac': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.audio_file_outlined, label: 'AAC'),
    'ogg': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.audio_file_outlined, label: 'OGG'),
    // Video formats
    'mp4': _FileTypeStyle(color: Color(0xFFE91E63), icon: Icons.video_file_outlined, label: 'MP4'),
    'mov': _FileTypeStyle(color: Color(0xFFE91E63), icon: Icons.video_file_outlined, label: 'MOV'),
    'webm': _FileTypeStyle(color: Color(0xFFE91E63), icon: Icons.video_file_outlined, label: 'WEBM'),
    'mkv': _FileTypeStyle(color: Color(0xFFE91E63), icon: Icons.video_file_outlined, label: 'MKV'),
    'avi': _FileTypeStyle(color: Color(0xFFE91E63), icon: Icons.video_file_outlined, label: 'AVI'),
    // Image formats (shown in file bubble if not rendered inline)
    'jpg': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.image_outlined, label: 'JPG'),
    'jpeg': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.image_outlined, label: 'JPEG'),
    'png': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.image_outlined, label: 'PNG'),
    'webp': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.image_outlined, label: 'WEBP'),
    'heic': _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.image_outlined, label: 'HEIC'),
  };

  _FileTypeStyle _styleForFile(String? fileName) {
    if (fileName == null)
      return const _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.insert_drive_file_outlined, label: 'FILE');
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    return _fileStyles[ext] ??
        const _FileTypeStyle(color: Color(0xFF7B9FD4), icon: Icons.insert_drive_file_outlined, label: 'FILE');
  }

  Widget _buildFileContent(Message message, bool isMe) {
    final isUploading = message.uid.startsWith('upload_') && message.mediaUrl == null;
    final style = _styleForFile(message.fileName);
    final fileUrl = message.mediaUrl;

    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? (AppColors.isDark
                  ? const Color(0xFF1A3A5C).withValues(alpha: 0.7)
                  : const Color(0xFFC5D8EF).withValues(alpha: 0.5))
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── File type icon ───────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isUploading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      strokeWidth: 2.5,
                      color: style.color,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(style.icon, color: style.color, size: 18),
                      const SizedBox(height: 1),
                      Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          color: style.color,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 10),
          // ── File info ────────────────────────────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.fileName ?? 'File',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                if (isUploading)
                  Text(
                    'Uploading ${(_uploadProgress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, color: style.color, fontWeight: FontWeight.w500),
                  )
                else
                  Row(
                    children: [
                      if (message.fileSizeLabel != null) ...[
                        Text(message.fileSizeLabel!, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text(' · ', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                      // ── Download button ──────────────────────────────────
                      if (fileUrl != null)
                        GestureDetector(
                          onTap: (_isDownloading && _downloadingUrl == fileUrl)
                              ? null
                              : () => _downloadFile(fileUrl, message.fileName ?? 'file'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              (_isDownloading && _downloadingUrl == fileUrl)
                                  ? SizedBox(
                                      width: 11,
                                      height: 11,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: style.color),
                                    )
                                  : Icon(Icons.download_outlined, size: 13, color: style.color),
                              const SizedBox(width: 3),
                              Text(
                                (_isDownloading && _downloadingUrl == fileUrl) ? 'Saving…' : 'Download',
                                style: TextStyle(fontSize: 11, color: style.color, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      else
                        Text('Unavailable', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioContent(Message message, bool isMe) {
    final isUploadingOptimistic = message.uid.startsWith('upload_') && message.mediaUrl == null;

    // If still uploading and no URL yet, show the player in uploading state
    if (isUploadingOptimistic) {
      return AudioMessagePlayer(
        url: '',
        fileName: message.fileName ?? 'Voice message',
        isMe: isMe,
        isUploading: true,
        uploadProgress: _uploadProgress,
      );
    }

    final url = message.mediaUrl;
    if (url == null || url.isEmpty) {
      // Fallback for missing URL
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? (AppColors.isDark
                    ? const Color(0xFF1A3A5C).withValues(alpha: 0.5)
                    : const Color(0xFFC5D8EF).withValues(alpha: 0.5))
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_off_rounded, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text('Audio unavailable', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return AudioMessagePlayer(
      key: ValueKey(message.uid),
      url: url,
      fileName: message.fileName ?? 'Voice message',
      isMe: isMe,
    );
  }

  Widget _buildMessageContent(Message message, bool isMe) {
    if (message.isImage) {
      return _buildImageContent(message);
    } else if (message.isAudio) {
      return _buildAudioContent(message, isMe);
    } else if (message.messageType == 'video') {
      return _buildVideoContent(message, isMe);
    } else if (message.isFile) {
      return _buildFileContent(message, isMe);
    } else {
      return _buildHyperlinkText(message.content, isMe);
    }
  }

  Widget _buildHyperlinkText(String text, bool isMe) {
    final urlRegex = RegExp(r'((https?:\/\/)|(www\.))[^\s]+', caseSensitive: false);

    final matches = urlRegex.allMatches(text);
    if (matches.isEmpty) {
      return RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.45),
          children: _parseBoldText(text),
        ),
      );
    }

    final List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the match (with bold parsing)
      if (match.start > lastMatchEnd) {
        spans.addAll(_parseBoldText(text.substring(lastMatchEnd, match.start)));
      }

      final url = match.group(0)!;
      final displayUrl = url;
      final launchUrlStr = url.startsWith('http') ? url : 'https://$url';

      spans.add(
        TextSpan(
          text: displayUrl,
          style: TextStyle(color: AppColors.primary, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              try {
                final uri = Uri.parse(launchUrlStr);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                LoggerUtils.error('Could not launch URL: $e');
              }
            },
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add remaining text (with bold parsing)
    if (lastMatchEnd < text.length) {
      spans.addAll(_parseBoldText(text.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.45),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseBoldText(String text) {
    final List<InlineSpan> spans = [];
    // Match text between * markers, e.g. *bold*
    final boldRegex = RegExp(r'\*(.*?)\*');
    int lastMatchEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      // Add plain text before the star marker
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      // Add the bold text (without the stars)
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add any remaining plain text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  // ── Video bubble — play icon + tap to open ─────────────────────────────────
  Widget _buildVideoContent(Message message, bool isMe) {
    final isUploading = message.uid.startsWith('upload_') && message.mediaUrl == null;
    final url = message.mediaUrl;

    return GestureDetector(
      onTap: url != null
          ? () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
        height: 140,
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black54,
                child: Center(child: Icon(Icons.movie_outlined, color: Colors.white.withValues(alpha: 0.3), size: 48)),
              ),
            ),
            if (isUploading)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isMe ? const Color(0xFF4A7FA5) : const Color(0xFF7B9FD4),
                  size: 32,
                ),
              ),
            // File name at bottom
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Text(
                message.fileName ?? 'Video',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Swipe to reply ─────────────────────────────────────────────────────────
  Widget _buildSwipeToReply(Message message, Widget child) {
    if (message.isDeleted) return child;
    const maxSwipe = 60.0;
    const threshold = 44.0;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final delta = details.delta.dx;
        final current = _swipeDx[message.uid] ?? 0.0;
        final next = (current + delta).clamp(-maxSwipe, maxSwipe);
        setState(() => _swipeDx[message.uid] = next);
        if (_swipeTriggered[message.uid] != true && next.abs() >= threshold) {
          _swipeTriggered[message.uid] = true;
          _startReply(message);
        }
      },
      onHorizontalDragEnd: (_) {
        final start = _swipeDx[message.uid] ?? 0.0;
        final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
        _swipeReturnAnims[message.uid]?.dispose();
        _swipeReturnAnims[message.uid] = ctrl;

        final anim = Tween<double>(
          begin: start,
          end: 0.0,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack));
        ctrl.addListener(() {
          if (mounted) setState(() => _swipeDx[message.uid] = anim.value);
        });
        ctrl.forward();
        _swipeTriggered[message.uid] = false;
      },
      child: Transform.translate(
        offset: Offset(_swipeDx[message.uid] ?? 0.0, 0),
        child: Stack(clipBehavior: Clip.none, children: [child, _buildSwipeReplyIcon(message)]),
      ),
    );
  }

  Widget _buildSwipeReplyIcon(Message message) {
    final dx = (_swipeDx[message.uid] ?? 0.0).abs();
    final opacity = (dx / 60.0).clamp(0.0, 1.0);
    final isMe = message.sender.id == widget.currentUser.id;
    if (opacity == 0) return const SizedBox.shrink();

    return Positioned(
      left: isMe ? null : -36,
      right: isMe ? -36 : null,
      top: 0,
      bottom: 0,
      child: Opacity(
        opacity: opacity,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: const Color(0xFF7B9FD4).withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.reply_rounded, size: 17, color: Color(0xFF7B9FD4)),
          ),
        ),
      ),
    );
  }

  // ── Single bubble ──────────────────────────────────────────────────────────
  Widget _buildBubble(Message message, bool showAvatar) {
    if (message.isDeleted) return _buildDeletedBubble(message, showAvatar);

    final isMe = message.sender.id == widget.currentUser.id;
    final isGroupOrBatch = widget.chat.chatType == ChatType.group || widget.chat.chatType == ChatType.batch;

    final bubble = GestureDetector(
      onLongPress: () => _showMessageOptions(context, message),
      child: Padding(
        padding: EdgeInsets.only(top: 2, bottom: message.isImage ? 4 : 2, left: 12, right: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              SizedBox(
                width: 38,
                child: showAvatar
                    ? Stack(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundImage: message.sender.profilePic != null
                                ? NetworkImage(message.sender.profilePic!)
                                : null,
                            backgroundColor: Colors.grey.shade300,
                            child: message.sender.profilePic == null
                                ? Text(
                                    message.sender.fullName.isNotEmpty ? message.sender.fullName[0].toUpperCase() : '?',
                                    style: TextStyle(fontSize: 14),
                                  )
                                : null,
                          ),
                          if (_webSocketService.userOnlineStatus[message.sender.id] == true)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: AppColors.statsGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.cardBackground, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 80,
                  maxWidth: MediaQuery.of(context).size.width * (message.isImage ? 0.68 : 0.72),
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    message.isImage ? 6 : 12,
                    message.isImage ? 6 : 10,
                    message.isImage ? 6 : 12,
                    8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (AppColors.isDark ? const Color(0xFF2D4A6A) : const Color(0xFFDDE7F5))
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe && (isGroupOrBatch || showAvatar))
                        Padding(
                          padding: EdgeInsets.only(bottom: 4, left: message.isImage ? 6 : 0),
                          child: Text(
                            message.sender.fullName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isGroupOrBatch ? _senderNameColor(message.sender.id) : AppColors.primary,
                            ),
                          ),
                        ),
                      if (message.hasReply)
                        Padding(
                          padding: EdgeInsets.only(left: message.isImage ? 6 : 0, right: message.isImage ? 6 : 0),
                          child: _buildInBubbleReply(message),
                        ),
                      _buildMessageContent(message, isMe),
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.only(left: message.isImage ? 6 : 0, right: message.isImage ? 6 : 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (message.isEdited)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  'edited',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                            if (isMe) ...[const SizedBox(width: 4), _buildTicks(message)],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: (isGroupOrBatch && showAvatar)
                    ? CircleAvatar(
                        radius: 19,
                        backgroundImage: widget.currentUser.profilePic != null
                            ? NetworkImage(widget.currentUser.profilePic!)
                            : null,
                        backgroundColor: AppColors.primary,
                        child: widget.currentUser.profilePic == null
                            ? Text(
                                widget.currentUser.fullName.isNotEmpty
                                    ? widget.currentUser.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(fontSize: 13, color: Colors.white),
                              )
                            : null,
                      )
                    : null,
              ),
            ],
          ],
        ),
      ),
    );

    return _buildSwipeToReply(message, bubble);
  }

  // ── Message area ───────────────────────────────────────────────────────────
  Widget _buildMessageArea() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return NoConnectionScreen(
        title: 'Could Not Load Messages',
        message: 'Something went wrong while loading this chat.\nCheck your connection and try again.',
        buttonLabel: 'Retry',
        onRetry: _loadMessages,
      );
    }
    if (_messages.isEmpty) {
      return EmptyStateScreen(
        title: 'No Messages Yet',
        message: 'Be the first to say something!\nSend a message to start the conversation.',
        icon: Icons.chat_bubble_outline_rounded,
      );
    }

    final mains = _mainMessages;
    final List<Widget> items = [];

    for (int i = 0; i < mains.length; i++) {
      final message = mains[i];
      final showAvatar = i == 0 || mains[i - 1].sender.id != message.sender.id;
      items.add(_buildBubble(message, showAvatar));

      final isLast = i == mains.length - 1;
      if (!isLast && _needsSeparator(mains[i + 1], message)) {
        // Separator sits above the newer group visually (reverse list),
        // so label should reflect the newer group's date (message = mains[i]).
        items.add(_buildDateSeparator(_dateSeparatorLabel(message.createdAt)));
      }
      if (isLast) {
        // Oldest message — separator at the very top uses its own date.
        items.add(_buildDateSeparator(_dateSeparatorLabel(message.createdAt)));
      }
    }

    if (_hasNextPage) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  // ── Reply bar (above input) ────────────────────────────────────────────────
  Widget _buildReplyBar() {
    if (_replyingTo == null) return const SizedBox.shrink();
    final msg = _replyingTo!;
    final isOwn = msg.sender.id == widget.currentUser.id;

    return SizeTransition(
      sizeFactor: _replyBarFade,
      axisAlignment: -1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFF7B9FD4), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            if (msg.isImage && msg.mediaUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  msg.mediaUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 40,
                    height: 40,
                    color: AppColors.surface,
                    child: Icon(Icons.image, size: 18, color: AppColors.textHint),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOwn ? 'You' : msg.sender.fullName,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7B9FD4)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.isImage
                        ? '📷 Photo'
                        : msg.isAudio
                        ? '🎤 Voice message'
                        : msg.isFile
                        ? '📎 ${msg.fileName ?? "File"}'
                        : msg.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _cancelReply,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit bar (above input) ────────────────────────────────────────────────
  Widget _buildEditBar() {
    if (_editingMessage == null) return const SizedBox.shrink();
    final msg = _editingMessage!;

    return SizeTransition(
      sizeFactor: _editBarFade,
      axisAlignment: -1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(top: BorderSide(color: AppColors.borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      const Text(
                        'Edit message',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _cancelEdit,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Emoji Picker Panel ─────────────────────────────────────────────────────
  Widget _buildEmojiPicker() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _showEmojiPicker ? 280 : 0,
      child: _showEmojiPicker
          ? EmojiPicker(
              onEmojiSelected: _onEmojiSelected,
              onBackspacePressed: () {
                final controller = _messageController;
                final text = controller.text;
                final selection = controller.selection;
                if (text.isEmpty) return;
                final newText = selection.isValid && selection.start > 0
                    ? text.replaceRange(selection.start - 1, selection.start, '')
                    : text.characters.skipLast(1).toString();
                final offset = selection.isValid && selection.start > 0 ? selection.start - 1 : newText.length;
                controller.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(offset: offset),
                );
              },
              config: Config(
                height: 280,
                checkPlatformCompatibility: false,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  gridPadding: EdgeInsets.zero,
                  recentsLimit: 28,
                  backgroundColor: AppColors.cardBackground,
                  buttonMode: ButtonMode.MATERIAL,
                  loadingIndicator: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B9FD4), strokeWidth: 2),
                  ),
                ),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.RECENT,
                  backgroundColor: AppColors.cardBackground,
                  indicatorColor: const Color(0xFF7B9FD4),
                  iconColor: AppColors.isDark ? Colors.grey.shade400 : Colors.grey,
                  iconColorSelected: const Color(0xFF7B9FD4),
                  categoryIcons: const CategoryIcons(),
                  tabIndicatorAnimDuration: kTabScrollDuration,
                  dividerColor: Colors.transparent,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  enabled: true,
                  showBackspaceButton: true,
                  backgroundColor: AppColors.cardBackground,
                  buttonColor: const Color(0xFF7B9FD4),
                  buttonIconColor: Colors.white,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: AppColors.cardBackground,
                  buttonIconColor: const Color(0xFF7B9FD4),
                  hintText: 'Search emoji',
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────
  // ── Input bar ──────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    final bool hasText = _messageController.text.trim().isNotEmpty;
    final bool showSendBtn = hasText || _editingMessage != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEditBar(),
        _buildReplyBar(),

        // ════════════════════════════════════════════════════════════════════
        // RECORDING STATE — full-width bar with waveform + delete + send
        // ════════════════════════════════════════════════════════════════════
        if (_isVoiceRecording)
          _buildVoiceRecordingBar()
        else
          // ═══════════════════════════════════════════════════════════════════
          // NORMAL INPUT ROW
          // ═══════════════════════════════════════════════════════════════════
          Container(
            color: AppColors.cardBackground,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Text field pill ────────────────────────────────────────
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: (_isUploading || _isPicking) ? null : _toggleEmojiPicker,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  _showEmojiPicker ? Icons.keyboard_rounded : Icons.emoji_emotions_outlined,
                                  key: ValueKey(_showEmojiPicker),
                                  color: (_isUploading || _isPicking)
                                      ? AppColors.textSecondary.withValues(alpha: 0.3)
                                      : _showEmojiPicker
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _messageFocusNode,
                              minLines: 1,
                              maxLines: 4,
                              style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: _editingMessage != null
                                    ? 'Edit message…'
                                    : _replyingTo != null
                                    ? 'Reply…'
                                    : 'Type here..',
                                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _editingMessage != null ? _submitEdit() : _sendMessage(),
                              onTap: () {
                                if (_showEmojiPicker) {
                                  setState(() => _showEmojiPicker = false);
                                }
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_editingMessage == null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: (_isUploading || _isPicking) ? null : _onAttachPressed,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Icon(
                                  Icons.attach_file_rounded,
                                  color: (_isUploading || _isPicking)
                                      ? AppColors.textSecondary.withValues(alpha: 0.3)
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: (_isUploading || _isPicking) ? null : _onCameraPressed,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: (_isUploading || _isPicking)
                                      ? AppColors.textSecondary.withValues(alpha: 0.3)
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── Send button OR Mic button ──────────────────────────────
                  if (showSendBtn)
                    GestureDetector(
                      onTap: (_isUploading || _isEditing)
                          ? null
                          : _editingMessage != null
                          ? _submitEdit
                          : _sendMessage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (_isUploading || _isEditing)
                              ? AppColors.textSecondary.withValues(alpha: 0.3)
                              : _editingMessage != null
                              ? AppColors.statsGreen
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: (_isUploading || _isEditing)
                            ? Padding(
                                padding: const EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                  value: _isUploading && _uploadProgress > 0 ? _uploadProgress : null,
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                child: _editingMessage != null
                                    ? const Icon(
                                        Icons.check_rounded,
                                        key: ValueKey('check'),
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        key: ValueKey('send'),
                                        color: Colors.white,
                                        size: 22,
                                      ),
                              ),
                      ),
                    )
                  else
                    // ── Mic button: tap to start recording ────────────────────
                    GestureDetector(
                      onTap: () => _voiceRecordStart(),
                      onLongPressStart: (_) => _voiceRecordStart(),
                      onLongPressEnd: _voiceOnDragEnd,
                      onLongPressMoveUpdate: _voiceOnDragUpdate,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: Color(0xFF7B9FD4), shape: BoxShape.circle),
                        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                ],
              ),
            ),
          ),
        _buildEmojiPicker(),
      ],
    );
  }

  // ── Voice recording bar ────────────────────────────────────────────────────
  // Shown INSTEAD of the normal input row while _isVoiceRecording == true.
  // Layout: [🗑 Delete]  [● 00:00  ▓▓▓▓▓▓▓▓▓▓▓▓]  [▶ Send]
  Widget _buildVoiceRecordingBar() {
    String fmtVoice(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Delete / Cancel button ───────────────────────────────────
            GestureDetector(
              onTap: () => _voiceRecordStop(send: false),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade200, width: 1.5),
                ),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade500, size: 22),
              ),
            ),

            const SizedBox(width: 10),

            // ── Waveform + timer pill ────────────────────────────────────
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.isDark ? const Color(0xFF1E3A5C) : const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    // Blinking dot
                    AnimatedBuilder(
                      animation: _voiceBarAnim,
                      builder: (_, __) => Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500.withOpacity(0.4 + _voiceBarAnim.value * 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Timer
                    Text(
                      fmtVoice(_voiceElapsed),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Waveform bars
                    Expanded(
                      child: ClipRect(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: _voiceBars.map((h) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              width: 2.5,
                              height: h,
                              margin: const EdgeInsets.symmetric(horizontal: 0.8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Send button ──────────────────────────────────────────────
            GestureDetector(
              onTap: () => _voiceRecordStop(send: true),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B9FD4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B9FD4).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.send_rounded, color: AppColors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      // We set this to false to prevent the background image from shrinking
      // when the keyboard appears. We handle the padding manually below.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0.5,
        shadowColor: AppColors.shadowLight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            _buildAppBarAvatar(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                _buildAppBarSubtitle(),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background image stays full-screen even when keyboard is up
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/chatbg.png"), fit: BoxFit.cover),
              ),
            ),
          ),
          // Content column pivots up based on keyboard height
          Padding(
            padding: EdgeInsets.only(bottom: _showEmojiPicker ? 250 : keyboardHeight),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() => _showEmojiPicker = false);
                      }
                    },
                    child: _buildMessageArea(),
                  ),
                ),
                if (_isUploading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: _buildUploadProgressOverlay(),
                  ),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image caption bottom sheet ────────────────────────────────────────────────
class _ImageCaptionSheet extends StatefulWidget {
  final File imageFile;
  final TextEditingController captionController;
  final void Function(String caption) onSend;
  final VoidCallback onCancel;

  const _ImageCaptionSheet({
    required this.imageFile,
    required this.captionController,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<_ImageCaptionSheet> createState() => _ImageCaptionSheetState();
}

class _ImageCaptionSheetState extends State<_ImageCaptionSheet> {
  @override
  void initState() {
    super.initState();
    widget.captionController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Image shrinks as keyboard rises so text field stays visible
    final imageMaxHeight = keyboardHeight > 0 ? (screenHeight * 0.25).clamp(80.0, 200.0) : screenHeight * 0.42;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2)),
            ),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600, size: 22),
                    onPressed: widget.onCancel,
                  ),
                  const Expanded(
                    child: Text(
                      'Send Image',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Image preview — shrinks when keyboard opens ───────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              constraints: BoxConstraints(maxHeight: imageMaxHeight),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(widget.imageFile, fit: BoxFit.contain, width: double.infinity),
              ),
            ),

            // ── Caption input + send ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: TextField(
                        controller: widget.captionController,
                        autofocus: false,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Add a caption…',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => widget.onSend(widget.captionController.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: Color(0xFF7B9FD4), shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attach sheet item data ────────────────────────────────────────────────────
class _AttachItem {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _AttachItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });
}

// ── File type style data ───────────────────────────────────────────────────────
class _FileTypeStyle {
  final Color color;
  final IconData icon;
  final String label;
  const _FileTypeStyle({required this.color, required this.icon, required this.label});
}
