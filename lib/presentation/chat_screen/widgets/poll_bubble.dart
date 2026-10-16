import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/repository/chat_list_screen/models/poll.dart';

class PollBubble extends StatefulWidget {
  final Poll poll;
  final String messageUid;
  final String chatUid;
  final bool isMe;
  final bool canShowVoters;
  final Future<void> Function(List<String> optionUids)? onVote;
  final Future<void> Function()? onClose;

  const PollBubble({
    super.key,
    required this.poll,
    required this.messageUid,
    required this.chatUid,
    this.isMe = false,
    this.canShowVoters = false,
    this.onVote,
    this.onClose,
  });

  @override
  State<PollBubble> createState() => _PollBubbleState();
}

class _PollBubbleState extends State<PollBubble> {
  late Set<String> _selectedOptionUids;
  bool _isSubmitting = false;
  String? _submittingOptionUid;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _selectedOptionUids = Set<String>.from(widget.poll.myOptionUids);
  }

  @override
  void didUpdateWidget(covariant PollBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.poll.uid != oldWidget.poll.uid ||
        widget.poll.totalVotes != oldWidget.poll.totalVotes ||
        widget.poll.isClosed != oldWidget.poll.isClosed ||
        widget.poll.votedByMe != oldWidget.poll.votedByMe ||
        widget.poll.myOptionUids != oldWidget.poll.myOptionUids) {
      if (!_isSubmitting) {
        _selectedOptionUids = Set<String>.from(widget.poll.myOptionUids);
      }
    }
  }

  Future<void> _onOptionTap(String optionUid) async {
    if (widget.poll.isClosed || !widget.poll.canVote || _isSubmitting) return;

    HapticFeedback.selectionClick();

    List<String> newSelection;
    if (widget.poll.allowMultiple) {
      final current = Set<String>.from(_selectedOptionUids);
      if (current.contains(optionUid)) {
        if (current.length <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least one option must be selected.'),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        current.remove(optionUid);
      } else {
        current.add(optionUid);
      }
      newSelection = current.toList();
    } else {
      if (_selectedOptionUids.contains(optionUid) && widget.poll.votedByMe) {
        return;
      }
      newSelection = [optionUid];
    }

    setState(() {
      _selectedOptionUids = newSelection.toSet();
      _isSubmitting = true;
      _submittingOptionUid = optionUid;
    });

    try {
      if (widget.onVote != null) {
        await widget.onVote!(newSelection);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedOptionUids = Set<String>.from(widget.poll.myOptionUids);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submittingOptionUid = null;
        });
      }
    }
  }

  Future<void> _handleClose() async {
    if (_isClosing || widget.poll.isClosed || !widget.poll.canClose) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Poll?'),
        content: const Text(
          'Closing this poll will prevent further votes from all participants. Results will remain visible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close Poll', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isClosing = true);
    try {
      if (widget.onClose != null) {
        await widget.onClose!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close poll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }

  void _showVotersSheet(String optionText, List<PollVoter> voters) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Voters for "$optionText"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...voters.map((voter) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: (voter.profilePic != null &&
                                  voter.profilePic!.isNotEmpty)
                              ? NetworkImage(voter.profilePic!)
                              : null,
                          child: (voter.profilePic == null ||
                                  voter.profilePic!.isEmpty)
                              ? Text(
                                  voter.fullName.isNotEmpty
                                      ? voter.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          voter.fullName.isNotEmpty
                              ? voter.fullName
                              : 'Anonymous',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final isClosed = poll.isClosed;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Question & Subtitle ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.question,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          poll.allowMultiple
                              ? 'Select one or more'
                              : 'Select one',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isClosed) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Closed',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (poll.canClose && !isClosed)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onSelected: (val) {
                    if (val == 'close') _handleClose();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.lock_clock, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Close poll', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Options List (WhatsApp style) ──
          ...poll.options.map((option) => _buildOptionRow(option)),

          // ── Footer: Total vote count ──
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              poll.totalVotes == 1 ? '1 vote' : '${poll.totalVotes} votes',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(PollOption option) {
    final poll = widget.poll;
    final isVoted = _selectedOptionUids.contains(option.uid) || option.votedByMe;
    final isThisSubmitting = _isSubmitting && _submittingOptionUid == option.uid;
    final canVote = poll.canVote && !poll.isClosed;
    final percent = option.percent.clamp(0, 100);
    final hasVoters = widget.canShowVoters &&
        option.voters != null &&
        option.voters!.isNotEmpty;

    // Teal accent color matching WhatsApp poll style
    const accentColor = Color(0xFF00A884);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: canVote ? () => _onOptionTap(option.uid) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circle with tick mark / hollow border
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isVoted ? accentColor : Colors.transparent,
                      border: Border.all(
                        color: isVoted
                            ? accentColor
                            : (AppColors.isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                        width: 1.8,
                      ),
                    ),
                    child: Center(
                      child: isThisSubmitting
                          ? SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: isVoted ? Colors.white : accentColor,
                              ),
                            )
                          : (isVoted
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Option text
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: isVoted ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Voter avatars (if plain group chat and present)
                  if (hasVoters) ...[
                    GestureDetector(
                      onTap: () => _showVotersSheet(option.text, option.voters!),
                      child: _buildVoterAvatarStack(option.voters!),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Vote count
                  Text(
                    '${option.voteCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // Horizontal Progress bar line (indented to align with text)
              Padding(
                padding: const EdgeInsets.only(left: 34.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 4.5,
                    width: double.infinity,
                    color: AppColors.isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: percent / 100.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoterAvatarStack(List<PollVoter> voters) {
    final displayVoters = voters.take(3).toList();
    final stackWidth = (displayVoters.length == 1)
        ? 20.0
        : (displayVoters.length == 2 ? 34.0 : 46.0);

    return SizedBox(
      height: 20,
      width: stackWidth,
      child: Stack(
        children: List.generate(displayVoters.length, (i) {
          final voter = displayVoters[i];
          return Positioned(
            left: i * 13.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cardBackground,
                  width: 1.5,
                ),
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: ClipOval(
                child: (voter.profilePic != null && voter.profilePic!.isNotEmpty)
                    ? Image.network(
                        voter.profilePic!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(voter),
                      )
                    : _buildAvatarFallback(voter),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAvatarFallback(PollVoter voter) {
    final initial = voter.fullName.isNotEmpty
        ? voter.fullName.trim()[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
