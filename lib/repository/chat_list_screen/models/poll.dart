class PollVoter {
  final int id;
  final String fullName;
  final String? profilePic;

  PollVoter({
    required this.id,
    required this.fullName,
    this.profilePic,
  });

  factory PollVoter.fromJson(Map<String, dynamic> json) => PollVoter(
        id: (json['id'] as num?)?.toInt() ?? 0,
        fullName: json['full_name']?.toString() ?? '',
        profilePic: json['profile_pic']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        if (profilePic != null) 'profile_pic': profilePic,
      };
}

class PollOption {
  final String uid;
  final String text;
  final int position;
  final int voteCount;
  final int percent;
  final bool votedByMe;
  final List<PollVoter>? voters;

  PollOption({
    required this.uid,
    required this.text,
    required this.position,
    required this.voteCount,
    required this.percent,
    required this.votedByMe,
    this.voters,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    List<PollVoter>? voters;
    if (json['voters'] is List) {
      voters = (json['voters'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => PollVoter.fromJson(v))
          .toList();
    }
    return PollOption(
      uid: json['uid']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      percent: (json['percent'] as num?)?.round() ?? 0,
      votedByMe: json['voted_by_me'] == true,
      voters: voters,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'text': text,
        'position': position,
        'vote_count': voteCount,
        'percent': percent,
        'voted_by_me': votedByMe,
        if (voters != null) 'voters': voters!.map((v) => v.toJson()).toList(),
      };

  PollOption copyWith({
    String? uid,
    String? text,
    int? position,
    int? voteCount,
    int? percent,
    bool? votedByMe,
    List<PollVoter>? voters,
  }) =>
      PollOption(
        uid: uid ?? this.uid,
        text: text ?? this.text,
        position: position ?? this.position,
        voteCount: voteCount ?? this.voteCount,
        percent: percent ?? this.percent,
        votedByMe: votedByMe ?? this.votedByMe,
        voters: voters ?? this.voters,
      );
}

class Poll {
  final String uid;
  final String question;
  final bool allowMultiple;
  final bool isClosed;
  final int totalVotes;
  final bool votedByMe;
  final List<String> myOptionUids;
  final bool canVote;
  final bool canClose;
  final List<PollOption> options;

  Poll({
    required this.uid,
    required this.question,
    required this.allowMultiple,
    required this.isClosed,
    required this.totalVotes,
    required this.votedByMe,
    required this.myOptionUids,
    required this.canVote,
    required this.canClose,
    required this.options,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? [];
    final options = rawOptions
        .whereType<Map<String, dynamic>>()
        .map((o) => PollOption.fromJson(o))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final rawMyOptionUids = json['my_option_uids'];
    final myOptionUids = rawMyOptionUids is List
        ? rawMyOptionUids.map((e) => e.toString()).toList()
        : <String>[];

    return Poll(
      uid: json['uid']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      allowMultiple: json['allow_multiple'] == true,
      isClosed: json['is_closed'] == true,
      totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      votedByMe: json['voted_by_me'] == true,
      myOptionUids: myOptionUids,
      canVote: json['can_vote'] == true,
      canClose: json['can_close'] == true,
      options: options,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'question': question,
        'allow_multiple': allowMultiple,
        'is_closed': isClosed,
        'total_votes': totalVotes,
        'voted_by_me': votedByMe,
        'my_option_uids': myOptionUids,
        'can_vote': canVote,
        'can_close': canClose,
        'options': options.map((o) => o.toJson()).toList(),
      };

  Poll copyWith({
    String? uid,
    String? question,
    bool? allowMultiple,
    bool? isClosed,
    int? totalVotes,
    bool? votedByMe,
    List<String>? myOptionUids,
    bool? canVote,
    bool? canClose,
    List<PollOption>? options,
  }) =>
      Poll(
        uid: uid ?? this.uid,
        question: question ?? this.question,
        allowMultiple: allowMultiple ?? this.allowMultiple,
        isClosed: isClosed ?? this.isClosed,
        totalVotes: totalVotes ?? this.totalVotes,
        votedByMe: votedByMe ?? this.votedByMe,
        myOptionUids: myOptionUids ?? this.myOptionUids,
        canVote: canVote ?? this.canVote,
        canClose: canClose ?? this.canClose,
        options: options ?? this.options,
      );
}
