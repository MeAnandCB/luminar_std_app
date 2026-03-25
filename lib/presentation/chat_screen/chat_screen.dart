import 'dart:io';
import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
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
import 'package:path/path.dart' as pathLib;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

    _fileUploadService = FileUploadService(
      baseUrl: widget.apiService.baseUrl,
      token: widget.apiService.token,
    );

    _replyBarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _replyBarFade = CurvedAnimation(
      parent: _replyBarAnim,
      curve: Curves.easeOut,
    );

    _editBarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _editBarFade = CurvedAnimation(parent: _editBarAnim, curve: Curves.easeOut);

    _voiceBarAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    });

    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });

    _webSocketService =
        widget.webSocketService ??
        WebSocketService(
          url: widget.websocketUrl,
          currentUser: widget.currentUser,
          apiService: widget.apiService,
        );

    _webSocketService.onConnected = () =>
        _webSocketService.updateUserStatus(true);

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

    if (widget.chat.chatType == ChatType.individual &&
        widget.chat.otherParticipant != null) {
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
      final chats = await widget.apiService.fetchChats();
      if (mounted) setState(() => _allChats = chats);
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

    final newOffset = selection.isValid
        ? selection.start + emoji.emoji.length
        : newText.length;

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
    _messageController.selection = TextSelection.collapsed(
      offset: message.content.length,
    );
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
    final optimisticUpdated = message.copyWith(
      content: newContent,
      isEdited: true,
      updatedAt: DateTime.now(),
    );
    setState(() {
      final idx = _messages.indexWhere((m) => m.uid == message.uid);
      if (idx != -1) _messages[idx] = optimisticUpdated;
    });

    _cancelEdit();
    if (_showEmojiPicker) setState(() => _showEmojiPicker = false);

    try {
      // Returns null when the API responds with a success string instead of
      // a full message object — in that case we keep the optimistic version.
      final updated = await widget.apiService.editMessage(
        chatUid: widget.chat.uid,
        messageUid: message.uid,
        content: newContent,
      );
      if (mounted && updated != null) {
        // API returned a full message object — use it as the source of truth
        setState(() {
          final idx = _messages.indexWhere((m) => m.uid == message.uid);
          if (idx != -1) _messages[idx] = updated;
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

  // ── Attach button — file picker ────────────────────────────────────────────
  void _onAttachPressed() {
    if (_isPicking || _isUploading) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildAttachSheet(),
    );
  }

  Widget _buildAttachSheet() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attachOption(
                    icon: Icons.image_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF7B9FD4),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _attachOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.green.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _attachOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: Colors.orange.shade600,
                    onTap: () {
                      Navigator.pop(context);
                      _pickDocument();
                    },
                  ),
                  _attachOption(
                    icon: Icons.audio_file_rounded,
                    label: 'Audio',
                    color: Colors.purple.shade400,
                    onTap: () {
                      Navigator.pop(context);
                      _pickAudio();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _onCameraPressed() => _pickImage(ImageSource.camera);

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return;
      _showImageCaptionSheet(File(picked.path));
    } on PlatformException catch (e) {
      debugPrint('[Picker] PlatformException (_pickImage): $e');
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

  Future<void> _pickDocument() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;
      await _uploadAndSendFile(File(filePath), 'file');
    } on PlatformException catch (e) {
      debugPrint('[Picker] PlatformException (_pickDocument): $e');
    } catch (e) {
      debugPrint('[Picker] Unexpected error (_pickDocument): $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
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
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
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
    _voiceAmpTimer = Timer.periodic(const Duration(milliseconds: 120), (
      _,
    ) async {
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  // ── Audio file picker (for attach sheet) ──────────────────────────────────
  Future<void> _pickAudio() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: false,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;
      await _uploadAndSendFile(File(filePath), 'audio');
    } on PlatformException catch (e) {
      debugPrint('[Picker] PlatformException (_pickAudio): $e');
    } catch (e) {
      debugPrint('[Picker] Unexpected error (_pickAudio): $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _uploadAndSendFile(
    File file,
    String hintType, {
    String caption = '',
  }) async {
    final replyToUid = _replyingTo?.uid;

    final fileName = pathLib.basename(file.path);
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final resolvedType = _resolveMessageTypeLocal(mimeType);

    const supported = {'image', 'file', 'audio'};
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

      final actual = await widget.apiService.sendFileMessage(
        chatUid: widget.chat.uid,
        upload: result,
        replyTo: replyToUid,
        caption: caption.isNotEmpty ? caption : null,
      );

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.uid == optimisticUid);
          if (idx != -1) _messages[idx] = actual;
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadingFileName = null;
        });
        _webSocketService.broadcastLocalMessage(actual);
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
    if (mimeType.startsWith('video/')) return 'video';
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
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'This file is not supported',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
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
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: Colors.red.shade300,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A2E),
                  ),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
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
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
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
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 28,
                        color: Colors.red.shade600,
                      ),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (message.content.isNotEmpty &&
                  !message.isImage &&
                  !message.isFile &&
                  !message.isAudio)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                          Icon(
                            Icons.reply_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Message preview',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A2E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              if (message.isImage && message.mediaUrl != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                          Icon(
                            Icons.image_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Photo message',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
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
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (message.isFile)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
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
                          color: const Color(0xFF7B9FD4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_outlined,
                          color: Color(0xFF7B9FD4),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.fileName ?? 'File',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            if (message.fileSizeLabel != null)
                              Text(
                                message.fileSizeLabel!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
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
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
      final messages = await widget.apiService.fetchMessages(
        widget.chat.uid,
        page: _currentPage,
        pageSize: _pageSize,
      );
      setState(() {
        _messages
          ..clear()
          ..addAll(messages)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoadingMessages = false;
        if (messages.length < _pageSize) _hasNextPage = false;
      });
      _scrollToBottom();
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
      final older = await widget.apiService.fetchMessages(
        widget.chat.uid,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _currentPage = nextPage;
        if (older.isEmpty || older.length < _pageSize) _hasNextPage = false;
        final existing = _messages.map((m) => m.uid).toSet();
        _messages.addAll(older.where((m) => !existing.contains(m.uid)));
        _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final msgs = await widget.apiService.fetchMessages(widget.chat.uid);
        if (!mounted) return;
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
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                                  .sendMessage(
                                    emoji,
                                    chatUid: widget.chat.uid,
                                    replyTo: message.uid,
                                  )
                                  .then((actual) {
                                    if (mounted) {
                                      setState(
                                        () => _messages.insert(0, actual),
                                      );
                                      _webSocketService.broadcastLocalMessage(
                                        actual,
                                      );
                                      _scrollToBottom();
                                    }
                                  })
                                  .catchError((_) {});
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade100),
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
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Message forwarded',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1A1A2E),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      _showErrorSnackbar(
                        'Forward failed: ${result.error ?? "Unknown error"}',
                      );
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                _messageOption(
                  icon: Icons.info_outline_rounded,
                  label: 'Info',
                  onTap: () => Navigator.pop(context),
                ),
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

  Widget _messageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF1A1A2E);
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
              style: TextStyle(
                fontSize: 14,
                color: c,
                fontWeight: FontWeight.w400,
              ),
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
          ? ReplyToInfo(
              uid: replyToUid,
              content: replyToContent,
              senderName: replyToSender ?? '',
            )
          : null,
    );

    setState(() => _messages.insert(0, optimistic));
    _messageController.clear();
    _scrollToBottom();

    try {
      final actual = await _webSocketService.sendMessage(
        content,
        chatUid: widget.chat.uid,
        replyTo: replyToUid,
      );
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

  bool _isOptimistic(Message m) =>
      int.tryParse(m.uid) != null || m.uid.startsWith('upload_');

  // ── Time helpers ───────────────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
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
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
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
        chat.chatType == ChatType.individual &&
        other != null &&
        _webSocketService.userOnlineStatus[other.id] == true;

    Widget child;
    Color bgColor;
    ImageProvider? bgImage;

    if (chat.chatType == ChatType.individual) {
      bgColor = const Color(0xFF7B9FD4);
      bgImage = other?.profilePic != null
          ? NetworkImage(other!.profilePic!)
          : null;
      child = Text(
        chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 15),
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
      final isOnline =
          other != null && _webSocketService.userOnlineStatus[other.id] == true;
      return Row(
        children: [
          if (isOnline)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? const Color(0xFF4CAF50) : Colors.grey.shade500,
            ),
          ),
        ],
      );
    } else if (chat.chatType == ChatType.batch) {
      return Row(
        children: [
          Icon(Icons.school_outlined, size: 12, color: Colors.orange.shade600),
          const SizedBox(width: 4),
          Text(
            'Batch Chat',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.group_outlined, size: 12, color: Colors.purple.shade400),
          const SizedBox(width: 4),
          Text(
            'Group Chat',
            style: TextStyle(fontSize: 12, color: Colors.purple.shade400),
          ),
        ],
      );
    }
  }

  Widget _buildTicks(Message message) {
    if (_isOptimistic(message)) {
      if (message.uid.startsWith('upload_')) {
        return Icon(
          Icons.cloud_upload_outlined,
          size: 12,
          color: Colors.grey.shade400,
        );
      }
      return Icon(
        Icons.access_time_rounded,
        size: 12,
        color: Colors.grey.shade400,
      );
    }
    final isRead =
        message.readBy.isNotEmpty &&
        message.readBy.any((id) => id != widget.currentUser.id);
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
            color: const Color(0xFFE1F0FA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4A7FA5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedBubble(Message message) {
    final isMe = message.sender.id == widget.currentUser.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) const SizedBox(width: 46),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'This message was deleted',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 46),
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
      final original = _messages.cast<Message?>().firstWhere(
        (m) => m?.uid == message.replyTo,
        orElse: () => null,
      );
      quotedContent = original?.content ?? message.replyToContent ?? '…';
      quotedSender = original?.sender.fullName;
    }

    return GestureDetector(
      onTap: () => _scrollToMessage(message.replyTo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFC5D8EF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMe ? const Color(0xFF4A7FA5) : const Color(0xFF7B9FD4),
              width: 3.5,
            ),
          ),
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
                    color: isMe
                        ? const Color(0xFF4A7FA5)
                        : const Color(0xFF7B9FD4),
                  ),
                ),
              ),
            Text(
              quotedContent,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
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
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
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
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
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
              Text(
                'Uploading…',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final url = message.mediaUrl;
    if (url == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    }

    final hasCaption =
        message.content.isNotEmpty &&
        message.content != (message.fileName ?? '');

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
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
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
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Image unavailable',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildDownloadButton(url, message.fileName ?? 'image.jpg'),
            ),
          ],
        ),
        if (hasCaption)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A2E),
                height: 1.4,
              ),
            ),
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
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isThisDownloading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.download_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              isThisDownloading ? 'Saving…' : 'Download',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
      // ── 1. Fetch the bytes ───────────────────────────────────────────────
      debugPrint('[Download] GET $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final bytes = response.bodyBytes;
      debugPrint('[Download] received ${bytes.length} bytes');

      // ── 2. Determine save path ───────────────────────────────────────────
      //   Android 10+  → getExternalStorageDirectory() returns scoped storage
      //                  e.g. /storage/emulated/0/Android/data/<pkg>/files
      //   iOS           → getApplicationDocumentsDirectory()
      //   Fallback      → getTemporaryDirectory()
      Directory? dir;
      if (Platform.isAndroid) {
        dir =
            await getExternalStorageDirectory(); // scoped, no permission needed
      }
      dir ??= await getApplicationDocumentsDirectory();

      if (!await dir.exists()) await dir.create(recursive: true);

      // Sanitise fileName — strip any path separators
      final safeName = fileName.replaceAll(RegExp(r'[/\\]'), '_');
      final savePath = '${dir.path}/$safeName';

      // ── 3. Write file ────────────────────────────────────────────────────
      final file = File(savePath);
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('[Download] saved → $savePath');

      // ── 4. Success snackbar ──────────────────────────────────────────────
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Image saved successfully',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final uri = Uri.file(savePath);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[Download] Error: $e');
      debugPrint('[Download] Stack: $stack');
      if (mounted) {
        _showErrorSnackbar('Download failed: ${e.toString()}');
      }
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
    'pdf': _FileTypeStyle(
      color: Color(0xFFE53935),
      icon: Icons.picture_as_pdf_outlined,
      label: 'PDF',
    ),
    'doc': _FileTypeStyle(
      color: Color(0xFF1565C0),
      icon: Icons.description_outlined,
      label: 'DOC',
    ),
    'docx': _FileTypeStyle(
      color: Color(0xFF1565C0),
      icon: Icons.description_outlined,
      label: 'DOCX',
    ),
    'xls': _FileTypeStyle(
      color: Color(0xFF2E7D32),
      icon: Icons.table_chart_outlined,
      label: 'XLS',
    ),
    'xlsx': _FileTypeStyle(
      color: Color(0xFF2E7D32),
      icon: Icons.table_chart_outlined,
      label: 'XLSX',
    ),
    'ppt': _FileTypeStyle(
      color: Color(0xFFE65100),
      icon: Icons.slideshow_outlined,
      label: 'PPT',
    ),
    'pptx': _FileTypeStyle(
      color: Color(0xFFE65100),
      icon: Icons.slideshow_outlined,
      label: 'PPTX',
    ),
    'txt': _FileTypeStyle(
      color: Color(0xFF546E7A),
      icon: Icons.text_snippet_outlined,
      label: 'TXT',
    ),
    'csv': _FileTypeStyle(
      color: Color(0xFF00695C),
      icon: Icons.grid_on_outlined,
      label: 'CSV',
    ),
    'zip': _FileTypeStyle(
      color: Color(0xFF6A1B9A),
      icon: Icons.folder_zip_outlined,
      label: 'ZIP',
    ),
    'rar': _FileTypeStyle(
      color: Color(0xFF6A1B9A),
      icon: Icons.folder_zip_outlined,
      label: 'RAR',
    ),
    'mp3': _FileTypeStyle(
      color: Color(0xFF7B9FD4),
      icon: Icons.audio_file_outlined,
      label: 'MP3',
    ),
    'mp4': _FileTypeStyle(
      color: Color(0xFF7B9FD4),
      icon: Icons.video_file_outlined,
      label: 'MP4',
    ),
  };

  _FileTypeStyle _styleForFile(String? fileName) {
    if (fileName == null)
      return const _FileTypeStyle(
        color: Color(0xFF7B9FD4),
        icon: Icons.insert_drive_file_outlined,
        label: 'FILE',
      );
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    return _fileStyles[ext] ??
        const _FileTypeStyle(
          color: Color(0xFF7B9FD4),
          icon: Icons.insert_drive_file_outlined,
          label: 'FILE',
        );
  }

  Widget _buildFileContent(Message message, bool isMe) {
    final isUploading =
        message.uid.startsWith('upload_') && message.mediaUrl == null;
    final style = _styleForFile(message.fileName);
    final fileUrl = message.mediaUrl;

    return GestureDetector(
      onTap: isUploading || fileUrl == null
          ? null
          : () async {
              final uri = Uri.parse(fileUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                _showErrorSnackbar('Could not open file');
              }
            },
      child: Container(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFC5D8EF).withOpacity(0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.12),
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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (isUploading)
                    Row(
                      children: [
                        Text(
                          'Uploading ${(_uploadProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: style.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        if (message.fileSizeLabel != null) ...[
                          Text(
                            message.fileSizeLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                        Icon(
                          Icons.download_outlined,
                          size: 12,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Tap to open',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioContent(Message message, bool isMe) {
    final isUploadingOptimistic =
        message.uid.startsWith('upload_') && message.mediaUrl == null;

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
              ? const Color(0xFFC5D8EF).withOpacity(0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_off_rounded, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              'Audio unavailable',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
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
    } else if (message.isFile) {
      return _buildFileContent(message, isMe);
    } else if (message.isAudio) {
      return _buildAudioContent(message, isMe);
    } else {
      return Text(
        message.content,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1A1A2E),
          height: 1.45,
        ),
      );
    }
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
        final ctrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        );
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [child, _buildSwipeReplyIcon(message)],
        ),
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
            decoration: BoxDecoration(
              color: const Color(0xFF7B9FD4).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.reply_rounded,
              size: 17,
              color: Color(0xFF7B9FD4),
            ),
          ),
        ),
      ),
    );
  }

  // ── Single bubble ──────────────────────────────────────────────────────────
  Widget _buildBubble(Message message, bool showAvatar) {
    if (message.isDeleted) return _buildDeletedBubble(message);

    final isMe = message.sender.id == widget.currentUser.id;
    final isGroupOrBatch =
        widget.chat.chatType == ChatType.group ||
        widget.chat.chatType == ChatType.batch;

    final bubble = GestureDetector(
      onLongPress: () => _showMessageOptions(context, message),
      child: Padding(
        padding: EdgeInsets.only(
          top: 2,
          bottom: message.isImage ? 4 : 2,
          left: 12,
          right: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
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
                                    message.sender.fullName.isNotEmpty
                                        ? message.sender.fullName[0]
                                              .toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 14),
                                  )
                                : null,
                          ),
                          if (_webSocketService.userOnlineStatus[message
                                  .sender
                                  .id] ==
                              true)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
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
                  maxWidth:
                      MediaQuery.of(context).size.width *
                      (message.isImage ? 0.68 : 0.72),
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    message.isImage ? 6 : 12,
                    message.isImage ? 6 : 10,
                    message.isImage ? 6 : 12,
                    8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFDDE7F5) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe && (isGroupOrBatch || showAvatar))
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 4,
                            left: message.isImage ? 6 : 0,
                          ),
                          child: Text(
                            message.sender.fullName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isGroupOrBatch
                                  ? _senderNameColor(message.sender.id)
                                  : const Color(0xFF5B8CC4),
                            ),
                          ),
                        ),
                      if (message.hasReply)
                        Padding(
                          padding: EdgeInsets.only(
                            left: message.isImage ? 6 : 0,
                            right: message.isImage ? 6 : 0,
                          ),
                          child: _buildInBubbleReply(message),
                        ),
                      _buildMessageContent(message, isMe),
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.only(
                          left: message.isImage ? 6 : 0,
                          right: message.isImage ? 6 : 0,
                        ),
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
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildTicks(message),
                            ],
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
                child: showAvatar
                    ? CircleAvatar(
                        radius: 19,
                        backgroundImage: widget.currentUser.profilePic != null
                            ? NetworkImage(widget.currentUser.profilePic!)
                            : null,
                        backgroundColor: const Color(0xFF7B9FD4),
                        child: widget.currentUser.profilePic == null
                            ? Text(
                                widget.currentUser.fullName.isNotEmpty
                                    ? widget.currentUser.fullName[0]
                                          .toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Say hello! 👋',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        ),
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
        items.add(_buildDateSeparator(_dateSeparatorLabel(message.createdAt)));
      }
      if (isLast) {
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
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9EDF0), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF7B9FD4),
                borderRadius: BorderRadius.circular(2),
              ),
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
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image,
                      size: 18,
                      color: Colors.grey,
                    ),
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B9FD4),
                    ),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
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
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE9EDF0), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Edit message',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
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
                    ? text.replaceRange(
                        selection.start - 1,
                        selection.start,
                        '',
                      )
                    : text.characters.skipLast(1).toString();
                final offset = selection.isValid && selection.start > 0
                    ? selection.start - 1
                    : newText.length;
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
                  backgroundColor: Colors.white,
                  buttonMode: ButtonMode.MATERIAL,
                  loadingIndicator: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7B9FD4),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                categoryViewConfig: CategoryViewConfig(
                  initCategory: Category.RECENT,
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFF7B9FD4),
                  iconColor: Colors.grey,
                  iconColorSelected: const Color(0xFF7B9FD4),
                  categoryIcons: const CategoryIcons(),
                  tabIndicatorAnimDuration: kTabScrollDuration,
                  dividerColor: Colors.transparent,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  enabled: true,
                  showBackspaceButton: true,
                  backgroundColor: Colors.white,
                  buttonColor: const Color(0xFF7B9FD4),
                  buttonIconColor: Colors.white,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Colors.white,
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
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Text field pill ────────────────────────────────────────
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6FB),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: (_isUploading || _isPicking)
                                ? null
                                : _toggleEmojiPicker,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  _showEmojiPicker
                                      ? Icons.keyboard_rounded
                                      : Icons.emoji_emotions_outlined,
                                  key: ValueKey(_showEmojiPicker),
                                  color: (_isUploading || _isPicking)
                                      ? Colors.grey.shade300
                                      : _showEmojiPicker
                                      ? const Color(0xFF7B9FD4)
                                      : Colors.grey.shade500,
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
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                              decoration: InputDecoration(
                                hintText: _editingMessage != null
                                    ? 'Edit message…'
                                    : _replyingTo != null
                                    ? 'Reply…'
                                    : 'Type here..',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _editingMessage != null
                                  ? _submitEdit()
                                  : _sendMessage(),
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
                              onTap: (_isUploading || _isPicking)
                                  ? null
                                  : _onAttachPressed,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Icon(
                                  Icons.attach_file_rounded,
                                  color: (_isUploading || _isPicking)
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade500,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: (_isUploading || _isPicking)
                                  ? null
                                  : _onCameraPressed,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  color: (_isUploading || _isPicking)
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade500,
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
                              ? Colors.grey.shade300
                              : _editingMessage != null
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF7B9FD4),
                          shape: BoxShape.circle,
                        ),
                        child: (_isUploading || _isEditing)
                            ? Padding(
                                padding: const EdgeInsets.all(13),
                                child: CircularProgressIndicator(
                                  value: _isUploading && _uploadProgress > 0
                                      ? _uploadProgress
                                      : null,
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF7B9FD4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
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
      color: Colors.white,
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
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade500,
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Waveform + timer pill ────────────────────────────────────
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FB),
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
                          color: Colors.red.shade500.withOpacity(
                            0.4 + _voiceBarAnim.value * 0.6,
                          ),
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
                              margin: const EdgeInsets.symmetric(
                                horizontal: 0.8,
                              ),
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
                      color: const Color(0xFF7B9FD4).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      resizeToAvoidBottomInset: !_showEmojiPicker,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                _buildAppBarSubtitle(),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A2E)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
              },
              child: Stack(
                children: [
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/chatbg.png"),
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  _buildMessageArea(),
                ],
              ),
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 3,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: widget.onCancel,
                ),
                const Expanded(
                  child: Text(
                    'Send Image',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black),
                      ),
                      child: TextField(
                        controller: widget.captionController,
                        autofocus: true,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.red, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Add a caption…',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B9FD4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── File type style data ───────────────────────────────────────────────────────
class _FileTypeStyle {
  final Color color;
  final IconData icon;
  final String label;
  const _FileTypeStyle({
    required this.color,
    required this.icon,
    required this.label,
  });
}
