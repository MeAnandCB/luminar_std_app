import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

class _QA {
  final String question;
  final String answer;
  final String? tip;
  const _QA(this.question, this.answer, {this.tip});
}

class _Category {
  final String label;
  final IconData icon;
  final Color colorA;
  final Color colorB;
  final List<_QA> items;
  const _Category(this.label, this.icon, this.colorA, this.colorB, this.items);
}

const _kCategories = [
  _Category(
    'HR',
    Icons.people_alt_rounded,
    Color(0xFF6C63FF),
    Color(0xFF9D73FF),
    [
      _QA(
        'Tell me about yourself.',
        'Start with your name, educational background, key skills, and a brief summary of your career goals. Keep it under 2 minutes and relate it to the role you are applying for.',
        tip: 'Use the Present–Past–Future formula: current role → how you got here → where you are headed.',
      ),
      _QA(
        'Why do you want to work here?',
        'Research the company beforehand. Mention specific things you admire — the culture, the product, or the growth opportunities — and explain how they align with your own goals.',
        tip: 'Show you did your homework. Generic answers are a red flag.',
      ),
      _QA(
        'What are your strengths?',
        'Pick 2–3 strengths relevant to the job. Back each one with a concrete example. For example: "I am detail-oriented — in my last project I caught a critical bug before release."',
        tip: 'Strengths without evidence sound like boasting. Always prove them.',
      ),
      _QA(
        'What is your greatest weakness?',
        'Choose a real weakness that is not critical to the role, then explain what you are actively doing to improve it. Avoid clichés like "I work too hard."',
        tip: 'Interviewers want self-awareness and growth mindset, not perfection.',
      ),
      _QA(
        'Where do you see yourself in 5 years?',
        'Show ambition aligned with the company. Mention a senior role or specialisation you aspire to, and how this position is a step toward that goal.',
      ),
      _QA(
        'Why should we hire you?',
        'Summarise your most relevant skills and experience, and explain the unique value you bring that other candidates may not. Connect it directly to the job description.',
        tip: 'This is your 60-second sales pitch. Prepare and practise it.',
      ),
      _QA(
        'Tell me about a time you failed.',
        'Use the STAR method (Situation, Task, Action, Result). Be honest, focus on what you learned, and explain how you applied that lesson afterward.',
        tip: 'The failure itself matters less than how you recovered from it.',
      ),
      _QA(
        'What motivates you?',
        'Be genuine — mention learning new things, solving problems, or making a measurable impact. Avoid saying "money" as your only motivator.',
      ),
      _QA(
        'How do you handle work pressure and stress?',
        'Describe specific coping strategies: task prioritisation, breaking work into chunks, taking short breaks, or communicating early when timelines are at risk.',
      ),
      _QA(
        'Do you have any questions for us?',
        'Always say yes! Ask about team culture, onboarding, growth paths, or what success looks like in this role. It shows genuine interest.',
        tip: 'Never ask about salary or leave policy in the first round.',
      ),
    ],
  ),
  _Category(
    'Behavioral',
    Icons.psychology_rounded,
    Color(0xFF10B981),
    Color(0xFF34D399),
    [
      _QA(
        'Describe a time you worked in a team and faced conflict.',
        'Use the STAR method. Describe a specific disagreement, how you listened to the other person\'s viewpoint, how you sought a compromise or escalated appropriately, and what the outcome was.',
        tip: 'Show empathy and communication skills, not just that you "won."',
      ),
      _QA(
        'Tell me about a time you took initiative.',
        'Think of a situation where you identified a problem or opportunity that was not your direct responsibility and took steps to address it. Describe the impact it had.',
      ),
      _QA(
        'How do you prioritise tasks when everything is urgent?',
        'Explain a framework you use — for example, the Eisenhower Matrix (urgent vs important) or simply listing tasks, estimating time, and tackling the highest-impact items first. Mention communicating with stakeholders when deadlines clash.',
        tip: 'Say "I communicate proactively" — this shows maturity.',
      ),
      _QA(
        'Tell me about a time you made a mistake at work.',
        'Be honest, take responsibility, explain what happened, what you did to fix it immediately, and most importantly what you changed to ensure it did not happen again.',
      ),
      _QA(
        'Describe a time you had to learn something quickly.',
        'Choose an example where you were given little time to ramp up. Explain your learning strategy — documentation, tutorials, asking colleagues — and how you applied the knowledge.',
      ),
      _QA(
        'Tell me about a challenging project and how you managed it.',
        'Describe the scope of the project, the biggest challenge (tight deadline, unclear requirements, technical difficulty), your specific actions, and the measurable result.',
      ),
      _QA(
        'Give an example of when you showed leadership.',
        'Leadership does not require a title. Mention a time you took ownership of a task, guided teammates, made a decision under pressure, or kept the group focused.',
      ),
      _QA(
        'How do you handle criticism or negative feedback?',
        'Explain that you listen without becoming defensive, ask clarifying questions to understand the concern, thank the person for the feedback, and act on it. Give an example if possible.',
        tip: 'This tests emotional intelligence. Stay calm and professional in your delivery.',
      ),
    ],
  ),
  _Category(
    'Situational',
    Icons.lightbulb_rounded,
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
    [
      _QA(
        'What would you do if you disagreed with your manager\'s decision?',
        'Express that you would first try to understand the reasoning behind the decision by asking questions. If you still disagreed, you would share your concerns respectfully and privately, provide data or alternative solutions, and ultimately respect the final call.',
        tip: 'Never say you would just go along silently or escalate immediately.',
      ),
      _QA(
        'How would you handle a situation where a deadline is at risk?',
        'Identify the risk early, assess what can be descoped or accelerated, communicate to stakeholders immediately with options (not just problems), and work extra hours if truly necessary — while making it transparent.',
      ),
      _QA(
        'What would you do if a colleague was not pulling their weight?',
        'First have a private, non-confrontational conversation to understand if they are struggling. Offer help. If the problem continues and affects the team, raise it with the manager — focusing on impact, not blame.',
      ),
      _QA(
        'If you were given a task you had never done before, how would you approach it?',
        'Break it into smaller parts, research similar problems, consult documentation or colleagues, create a prototype or plan early, and ask for feedback before investing too much time in the wrong direction.',
      ),
      _QA(
        'How would you deal with a difficult client or stakeholder?',
        'Listen actively to understand their frustration, acknowledge their concerns without becoming defensive, set clear expectations, and follow up consistently. Escalate only when the situation affects the project\'s viability.',
      ),
      _QA(
        'You are asked to do something unethical at work. What do you do?',
        'Refuse politely but clearly, citing company policy or professional ethics. Document the request in writing. Escalate to HR or a compliance channel if necessary. Your integrity is non-negotiable.',
        tip: 'Firms want people who will protect the organisation — show backbone.',
      ),
    ],
  ),
  _Category(
    'Common',
    Icons.forum_rounded,
    Color(0xFFEC4899),
    Color(0xFFF472B6),
    [
      _QA(
        'What is your expected salary?',
        'Research market rates for the role in your location. Give a range based on your research and experience. You can also say "I am open to a competitive offer based on the overall package."',
        tip: 'Know your worth — use sites like Glassdoor or LinkedIn Salary.',
      ),
      _QA(
        'Are you willing to relocate?',
        'Be honest. If you are open to it, say so enthusiastically. If you have limitations, mention them calmly while explaining you are willing to discuss arrangements.',
      ),
      _QA(
        'How soon can you join?',
        'Give your actual notice period. If you can join sooner, mention it. Avoid overpromising — it damages trust before you even start.',
      ),
      _QA(
        'What do you know about our company?',
        'Demonstrate genuine research: the company\'s product or service, mission, recent news, and why it excites you. This shows initiative and interest.',
        tip: 'Spend 20 minutes on their website and LinkedIn before the interview.',
      ),
      _QA(
        'How would your previous colleagues describe you?',
        'Describe positive traits you have actually demonstrated — reliable, collaborative, a fast learner — and ideally back them with a quick example or quote from feedback you have received.',
      ),
      _QA(
        'What are your hobbies and interests outside work?',
        'Be genuine. If relevant, show how a hobby has built transferable skills (e.g., competitive gaming → strategic thinking; blogging → communication). Avoid listing only passive activities.',
      ),
      _QA(
        'Are you applying to other companies?',
        'It is fine to say yes — it shows you are in demand. Mention that this role is particularly exciting to you and why. Avoid naming competitors if possible.',
      ),
    ],
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kCategories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: TabBarView(
          controller: _tabController,
          children: _kCategories
              .map((cat) => _CategoryTab(category: cat))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Interview Prep',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        'Practice Q&A • Flashcards • Tips',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          color: AppColors.cardBackground,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            indicatorColor: const Color(0xFF6C63FF),
            indicatorWeight: 2.5,
            dividerColor: AppColors.borderColor,
            tabs: _kCategories
                .map((c) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.icon, size: 14),
                          const SizedBox(width: 5),
                          Text(c.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Category Tab ─────────────────────────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.category});
  final _Category category;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats + Practice CTA
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [category.colorA.withValues(alpha: 0.12), category.colorB.withValues(alpha: 0.06)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: category.colorA.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [category.colorA, category.colorB]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${category.items.length} Questions',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: category.colorA),
                    ),
                    Text(
                      'Tap a card to see the answer',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _PracticeButton(category: category),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Q&A list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: category.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _QACard(
              qa: category.items[i],
              index: i,
              colorA: category.colorA,
              colorB: category.colorB,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Practice button ──────────────────────────────────────────────────────────

class _PracticeButton extends StatelessWidget {
  const _PracticeButton({required this.category});
  final _Category category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FlashcardPracticeScreen(category: category),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [category.colorA, category.colorB]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: category.colorA.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Practice', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Q&A Card (expandable) ────────────────────────────────────────────────────

class _QACard extends StatefulWidget {
  const _QACard({required this.qa, required this.index, required this.colorA, required this.colorB});
  final _QA qa;
  final int index;
  final Color colorA;
  final Color colorB;

  @override
  State<_QACard> createState() => _QACardState();
}

class _QACardState extends State<_QACard> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded ? widget.colorA.withValues(alpha: 0.4) : AppColors.borderColor,
        ),
        boxShadow: _expanded
            ? [BoxShadow(color: widget.colorA.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [widget.colorA, widget.colorB]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.qa.question,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: widget.colorA, size: 22),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 12),
                  Divider(color: widget.colorA.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 12),
                  Text(
                    widget.qa.answer,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.55),
                  ),
                  if (widget.qa.tip != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.colorA.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.colorA.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates_rounded, size: 14, color: widget.colorA),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.qa.tip!,
                              style: TextStyle(fontSize: 11.5, color: widget.colorA, height: 1.45, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Flashcard Practice Screen ────────────────────────────────────────────────

class _FlashcardPracticeScreen extends StatefulWidget {
  const _FlashcardPracticeScreen({required this.category});
  final _Category category;

  @override
  State<_FlashcardPracticeScreen> createState() => _FlashcardPracticeScreenState();
}

class _FlashcardPracticeScreenState extends State<_FlashcardPracticeScreen>
    with SingleTickerProviderStateMixin {
  late List<_QA> _deck;
  int _current = 0;
  bool _revealed = false;
  int _gotIt = 0;
  int _tryAgain = 0;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _deck = List.from(widget.category.items)..shuffle();
    _flipCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  bool get _done => _current >= _deck.length;

  void _reveal() {
    if (_revealed) return;
    setState(() => _showBack = false);
    _flipCtrl.forward().then((_) {
      setState(() {
        _revealed = true;
        _showBack = true;
      });
      _flipCtrl.value = 0;
    });
  }

  void _next(bool correct) {
    setState(() {
      if (correct) _gotIt++; else _tryAgain++;
      _current++;
      _revealed = false;
      _showBack = false;
    });
  }

  void _restart() {
    setState(() {
      _deck.shuffle();
      _current = 0;
      _revealed = false;
      _showBack = false;
      _gotIt = 0;
      _tryAgain = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color ca = widget.category.colorA;
    final Color cb = widget.category.colorB;
    final total = _deck.length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Practice Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(widget.category.label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          if (!_done)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_current + 1} / $total',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ca),
                ),
              ),
            ),
        ],
      ),
      body: _done ? _buildResult(ca, cb) : _buildCard(ca, cb, total),
    );
  }

  Widget _buildCard(Color ca, Color cb, int total) {
    final qa = _deck[_current];
    final progress = (_current) / total;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(ca),
          minHeight: 3,
        ),
        // Score row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _ScorePill(label: 'Got it', count: _gotIt, color: const Color(0xFF10B981)),
              const Spacer(),
              _ScorePill(label: 'Try again', count: _tryAgain, color: Colors.redAccent),
            ],
          ),
        ),
        // Card
        Expanded(
          child: GestureDetector(
            onTap: _reveal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, __) {
                  final angle = _flipAnim.value * math.pi;
                  final isFlipping = _flipCtrl.isAnimating;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(angle),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _showBack
                              ? [AppColors.cardBackground, AppColors.cardBackground]
                              : [ca, cb],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _showBack ? ca.withValues(alpha: 0.3) : Colors.transparent,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ca.withValues(alpha: _showBack ? 0.08 : 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: isFlipping
                          ? const SizedBox()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: _showBack
                                        ? ca.withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _showBack ? Icons.lightbulb_rounded : Icons.help_outline_rounded,
                                    color: _showBack ? ca : Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _showBack ? 'Answer' : 'Question',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: _showBack ? ca.withValues(alpha: 0.6) : Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _showBack ? qa.answer : qa.question,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _showBack ? AppColors.textPrimary : Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                                if (_showBack && qa.tip != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: ca.withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.tips_and_updates_rounded, size: 13, color: ca),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            qa.tip!,
                                            style: TextStyle(fontSize: 11, color: ca, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (!_showBack) ...[
                                  const SizedBox(height: 28),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Tap to reveal answer',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Action buttons
        if (_revealed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Try Again',
                    icon: Icons.refresh_rounded,
                    color: Colors.redAccent,
                    onTap: () => _next(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Got It!',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => _next(true),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildResult(Color ca, Color cb) {
    final total = _deck.length;
    final score = ((_gotIt / total) * 100).round();
    final emoji = score >= 80 ? '🎉' : score >= 50 ? '👍' : '💪';
    final msg = score >= 80
        ? 'Excellent! You\'re interview ready!'
        : score >= 50
            ? 'Good progress! Keep practising.'
            : 'Keep going — practice makes perfect!';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [ca, cb]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: ca.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          Text('$score%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: ca)),
          const SizedBox(height: 6),
          Text(msg, style: TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _ResultTile(label: 'Got It', count: _gotIt, color: const Color(0xFF10B981))),
              const SizedBox(width: 12),
              Expanded(child: _ResultTile(label: 'Try Again', count: _tryAgain, color: Colors.redAccent)),
              const SizedBox(width: 12),
              Expanded(child: _ResultTile(label: 'Total', count: total, color: ca)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Practice Again', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ca,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Back to Questions', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
