import 'package:flutter/material.dart';
import 'package:myreklam/models/social_video.dart';
import 'package:myreklam/widgets/social_video_preview.dart';
import 'package:myreklam/models/reel_model.dart';
import 'package:myreklam/screens/create_reel_screen.dart';
import 'package:myreklam/services/reel_service.dart';
import 'package:myreklam/services/share_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';
import 'package:video_player/video_player.dart';

class ReelsScreen extends StatefulWidget {
  final String? initialReelId;
  const ReelsScreen({super.key, this.initialReelId});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final _service = ReelService();
  List<ReelModel> _reels = const [];
  bool _loading = true;
  String? _error;
  int _active = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = <ReelModel>[];
      for (var page = 1; page <= 5; page++) {
        final batch = await _service.getReels(page: page);
        all.addAll(batch.where((next) => !all.any((old) => old.id == next.id)));
        if (batch.isEmpty ||
            (widget.initialReelId != null &&
                all.any((r) => r.id == widget.initialReelId)))
          break;
      }
      final initial = widget.initialReelId == null
          ? 0
          : all.indexWhere((r) => r.id == widget.initialReelId);
      _active = initial < 0 ? 0 : initial;
      _pageController = PageController(initialPage: _active);
      if (!mounted) return;
      setState(() {
        _reels = all;
        _loading = false;
        _error = null;
      });
      if (!UserSession().isGuest && all.isNotEmpty) {
        await _refreshReaction(_active);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les Réels.';
      });
    }
  }

  Future<void> _refreshReaction(int index) async {
    try {
      await _service.refreshReaction(_reels[index]);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleLike(ReelModel reel) async {
    if (UserSession().isGuest) return;
    final previous = reel.isLiked;
    setState(() {
      reel.isLiked = !previous;
      reel.likesCount += previous ? -1 : 1;
    });
    try {
      await _service.toggleLike(reel);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted)
        setState(() {
          reel.isLiked = previous;
          reel.likesCount += previous ? 1 : -1;
        });
    }
  }

  void _openComments(ReelModel reel) {
    if (UserSession().isGuest) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReelCommentsSheet(
        reel: reel,
        service: _service,
        onAdded: () => setState(() => reel.commentsCount++),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050806),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Réels'),
        actions: [
          if (!UserSession().isGuest)
            IconButton(
              tooltip: 'Créer un Reel',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateReelScreen()),
              ),
              icon: const Icon(Icons.add_box_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, retry: _load)
          : _reels.isEmpty
          ? _EmptyState(
              onCreate: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateReelScreen()),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              onPageChanged: (index) {
                setState(() => _active = index);
                if (!UserSession().isGuest) _refreshReaction(index);
              },
              itemBuilder: (_, index) {
                final reel = _reels[index];
                return _ReelPage(
                  key: ValueKey(reel.id),
                  reel: reel,
                  active: index == _active,
                  onLike: () => _toggleLike(reel),
                  onComments: () => _openComments(reel),
                  onShare: () => ShareService.shareEntity(
                    'reels',
                    reel.id,
                    title: reel.caption,
                    mediaUrl: reel.videoUrl,
                  ),
                );
              },
            ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  final ReelModel reel;
  final bool active;
  final VoidCallback onLike;
  final VoidCallback onComments;
  final VoidCallback onShare;
  const _ReelPage({
    super.key,
    required this.reel,
    required this.active,
    required this.onLike,
    required this.onComments,
    required this.onShare,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  late final VideoPlayerController _video;
  bool _ready = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
    if (SocialVideo.parse(widget.reel.videoUrl) == null) _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _video.initialize();
      await _video.setLooping(true);
      if (widget.active) await _video.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || oldWidget.active == widget.active) return;
    widget.active ? _video.play() : _video.pause();
  }

  @override
  void dispose() {
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: SocialVideo.parse(reel.videoUrl) != null
              ? Center(child: SocialVideoPreview(text: reel.videoUrl))
              : _ready
              ? GestureDetector(
                  onTap: () => setState(
                    () =>
                        _video.value.isPlaying ? _video.pause() : _video.play(),
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _video.value.size.width,
                      height: _video.value.size.height,
                      child: VideoPlayer(_video),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 105,
          child: Column(
            children: [
              _Action(
                icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
                color: reel.isLiked ? Colors.redAccent : Colors.white,
                label: '${reel.likesCount}',
                onTap: widget.onLike,
              ),
              _Action(
                icon: Icons.mode_comment_outlined,
                label: '${reel.commentsCount}',
                onTap: widget.onComments,
              ),
              _Action(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: widget.onShare,
              ),
              if (SocialVideo.parse(reel.videoUrl) == null)
                _Action(
                  icon: _muted ? Icons.volume_off : Icons.volume_up,
                  label: '',
                  onTap: () async {
                    _muted = !_muted;
                    await _video.setVolume(_muted ? 0 : 1);
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 80,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ReklamAvatar(
                    avatarUrl: reel.authorAvatar,
                    displayName: reel.authorName,
                    radius: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      reel.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                reel.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _Action({
    required this.icon,
    this.color = Colors.white,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: InkResponse(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
        ],
      ),
    ),
  );
}

class _ReelCommentsSheet extends StatefulWidget {
  final ReelModel reel;
  final ReelService service;
  final VoidCallback onAdded;
  const _ReelCommentsSheet({
    required this.reel,
    required this.service,
    required this.onAdded,
  });
  @override
  State<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<_ReelCommentsSheet> {
  final _input = TextEditingController();
  List<Map<String, dynamic>>? _comments;
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await widget.service.comments(widget.reel.id);
      if (mounted) setState(() => _comments = result);
    } catch (_) {
      if (mounted) setState(() => _comments = const []);
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final created = await widget.service.addComment(widget.reel.id, body);
      _input.clear();
      widget.onAdded();
      if (mounted) setState(() => _comments = [created, ...?_comments]);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Commentaires',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          Expanded(
            child: _comments == null
                ? const Center(child: CircularProgressIndicator())
                : _comments!.isEmpty
                ? const Center(child: Text('Aucun commentaire'))
                : ListView.builder(
                    itemCount: _comments!.length,
                    itemBuilder: (_, index) {
                      final comment = _comments![index];
                      final user = Map<String, dynamic>.from(
                        comment['user'] as Map? ?? const {},
                      );
                      final profile = Map<String, dynamic>.from(
                        (user['particulier_profile'] ?? user['pro_profile'])
                                as Map? ??
                            const {},
                      );
                      final name =
                          (profile['pseudo'] ??
                                  profile['company_name'] ??
                                  user['email'] ??
                                  'Membre')
                              .toString();
                      return ListTile(
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text((comment['body'] ?? '').toString()),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire…',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ErrorState({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: Colors.white)),
        TextButton(onPressed: retry, child: const Text('Réessayer')),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Aucun Reel pour le moment.',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onCreate,
          child: const Text('Créer le premier Reel'),
        ),
      ],
    ),
  );
}
