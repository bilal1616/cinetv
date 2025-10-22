// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../data/models/video_source.dart';

class TrailerPlayerPage extends StatefulWidget {
  const TrailerPlayerPage({super.key, required this.args});
  final TrailerArgs args;

  @override
  State<TrailerPlayerPage> createState() => _TrailerPlayerPageState();
}

class _TrailerPlayerPageState extends State<TrailerPlayerPage> {
  YoutubePlayerController? _yt;
  late final TrailerSource _src = widget.args.source;

  // Showcase yönetimi
  final _showcaseKey = GlobalKey<ShowCaseWidgetState>();
  final _gestureTipKey = GlobalKey();
  bool _showcaseStartedOnceInThisOpen = false;
  late BuildContext _showcaseContext; // ✔ Doğru context tutulur

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (_src.provider == TrailerProvider.youtube) {
      _yt = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          playsInline: true,
          strictRelatedVideos: true,
          enableJavaScript: true,
        ),
      )..loadVideoById(videoId: _src.videoId);

      _yt!.setFullScreenListener((isFullScreen) {
        if (isFullScreen) {
          SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          SystemChrome.setPreferredOrientations(const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartShowcase());
  }

  void _maybeStartShowcase() {
    if (!mounted || _showcaseStartedOnceInThisOpen) return;

    final mq = MediaQuery.maybeOf(context);
    final isPortrait =
        mq == null ? true : mq.orientation == Orientation.portrait;
    if (!isPortrait) return;

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _showcaseKey.currentState?.startShowCase([_gestureTipKey]);
      _showcaseStartedOnceInThisOpen = true;
    });
  }

  @override
  void dispose() {
    _yt?.close();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.args.title;

    return ShowCaseWidget(
      key: _showcaseKey,
      blurValue: 0,
      builder: (ctx) {
        _showcaseContext = ctx; // ✔ Context burada alınır

        if (_src.provider == TrailerProvider.youtube && _yt != null) {
          final isLandscape =
              MediaQuery.of(ctx).orientation == Orientation.landscape;

          return Scaffold(
            appBar: isLandscape ? null : AppBar(title: Text(title)),
            body: SafeArea(
              top: !isLandscape,
              bottom: !isLandscape,
              child: Center(
                child: AspectRatio(
                  aspectRatio:
                      isLandscape
                          ? MediaQuery.of(ctx).size.width /
                              MediaQuery.of(ctx).size.height
                          : 16 / 9,
                  child: Showcase.withWidget(
                    key: _gestureTipKey,
                    disableBarrierInteraction: true,
                    targetPadding: const EdgeInsets.all(0),
                    container: _TipBubble(
                      title:
                          'VİDEO OYNATICI İPUCU\n'
                          '(SADECE ANDROİD CİHAZLAR İÇİN)',
                      text:
                          '👉🏼 Video Oynatıcıyı Yukarı doğru kaydırma hareketi ile Dikey Tam Ekran moduna getirebilirsiniz.\n'
                          '👉🏼 Dikey Tam Ekran modunda ekranı Aşağı doğru kaydırma hareketi ile eski konumuna (Normal Ekran Modu) getirebilirsiniz.\n'
                          '👉🏼 Video Oynatıcı\'da bulunan ekran büyütme butonu ekranınızı Dikey Tam Ekran moduna çevirir.\n'
                          '👉🏼 Telefonunuzun Otomatik Döndür seçeneğiyle Yatay Tam Ekran Modunda izleme yapabilirsiniz',
                      onClose:
                          () => ShowCaseWidget.of(_showcaseContext).dismiss(),
                    ),
                    child: YoutubePlayer(controller: _yt!),
                  ),
                ),
              ),
            ),
          );
        }

        return _WebEmbedPage(
          title: title,
          provider: _src.provider,
          id: _src.videoId,
          gestureTipKey: _gestureTipKey,
          showcaseContext: _showcaseContext,
        );
      },
    );
  }
}

class _WebEmbedPage extends StatefulWidget {
  const _WebEmbedPage({
    required this.title,
    required this.provider,
    required this.id,
    required this.gestureTipKey,
    required this.showcaseContext,
  });

  final String title;
  final TrailerProvider provider;
  final String id;
  final GlobalKey gestureTipKey;
  final BuildContext showcaseContext;

  @override
  State<_WebEmbedPage> createState() => _WebEmbedPageState();
}

class _WebEmbedPageState extends State<_WebEmbedPage> {
  late final WebViewController _controller;

  String get _url => switch (widget.provider) {
    TrailerProvider.vimeo => 'https://player.vimeo.com/video/${widget.id}',
    TrailerProvider.dailymotion =>
      'https://www.dailymotion.com/embed/video/${widget.id}',
    _ => '',
  };

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape ? null : AppBar(title: Text(widget.title)),
      body: SafeArea(
        top: !isLandscape,
        bottom: !isLandscape,
        child: Center(
          child: AspectRatio(
            aspectRatio:
                isLandscape
                    ? MediaQuery.of(context).size.width /
                        MediaQuery.of(context).size.height
                    : 16 / 9,
            child: Showcase.withWidget(
              key: widget.gestureTipKey,
              disableBarrierInteraction: true,
              targetPadding: const EdgeInsets.all(0),
              container: _TipBubble(
                title:
                    'VİDEO OYNATICI İPUCU\n'
                    '(SADECE ANDROİD CİHAZLAR İÇİN)',
                text:
                    '👉🏼 Video Oynatıcıyı Yukarı doğru kaydırma hareketi ile Dikey Tam Ekran moduna getirebilirsiniz.\n'
                    '👉🏼 Dikey Tam Ekran modunda ekranı Aşağı doğru kaydırma hareketi ile eski konumuna (Normal Ekran Modu) getirebilirsiniz.\n'
                    '👉🏼 Video Oynatıcı\'da bulunan ekran büyütme butonu ekranınızı Dikey Tam Ekran moduna çevirir.\n'
                    '👉🏼 Telefonunuzun Otomatik Döndür seçeneğiyle Yatay Tam Ekran Modunda izleme yapabilirsiniz',
                onClose:
                    () => ShowCaseWidget.of(widget.showcaseContext).dismiss(),
              ),
              child: WebViewWidget(controller: _controller),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({required this.title, required this.text, this.onClose});

  final String title;
  final String text;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: .95),
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Başlık + Kapat tuşu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Sol başlık
                Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                /// Sağ X ikonu
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    splashRadius: 20,
                    onPressed: onClose,
                    tooltip: 'Kapat',
                  ),
              ],
            ),

            const SizedBox(height: 6),

            /// Açıklama
            Text(
              text,
              textAlign: TextAlign.left,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
