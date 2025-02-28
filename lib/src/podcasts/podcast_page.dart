import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import '../../data.dart';
import '../l10n/l10n.dart';
import '../library/library_model.dart';

class PodcastPage extends StatelessWidget {
  const PodcastPage({
    super.key,
    this.onTextTap,
    this.imageUrl,
    required this.pageId,
    this.audios,
    this.subscribed = true,
    required this.removePodcast,
    required this.addPodcast,
    required this.title,
  });

  static Widget createIcon({
    required BuildContext context,
    String? imageUrl,
    required bool isOnline,
  }) {
    if (!isOnline) {
      return Icon(Iconz().offline);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        width: iconSize(),
        height: iconSize(),
        child: SafeNetworkImage(
          url: imageUrl,
          fit: BoxFit.fitHeight,
          filterQuality: FilterQuality.medium,
          fallBackIcon: Icon(
            Iconz().rss,
          ),
          errorIcon: Icon(
            Iconz().rss,
          ),
        ),
      ),
    );
  }

  static Widget createTitle({
    required BuildContext context,
    required String title,
    required update,
  }) {
    return Badge(
      alignment: Alignment.bottomRight,
      isLabelVisible: update,
      label: Text(context.l10n.newEpisode),
      child: Text(title),
    );
  }

  final void Function(String feedUrl) removePodcast;
  final void Function(String feedUrl, Set<Audio> audios) addPodcast;
  final void Function({
    required String text,
    required AudioType audioType,
  })? onTextTap;
  final String? imageUrl;
  final String pageId;
  final String title;
  final Set<Audio>? audios;
  final bool subscribed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genre = audios?.firstWhereOrNull((e) => e.genre != null)?.genre;

    context.select((LibraryModel m) => m.lastPositions?.length);

    return AudioPage(
      showAudioTileHeader: false,
      onTextTap: onTextTap,
      audioPageType: AudioPageType.podcast,
      image: imageUrl == null
          ? null
          : SafeNetworkImage(
              fallBackIcon: Icon(
                Iconz().podcast,
                size: 80,
                color: Theme.of(context).hintColor,
              ),
              errorIcon: Icon(
                Iconz().podcast,
                size: 80,
                color: Theme.of(context).hintColor,
              ),
              url: imageUrl,
              fit: BoxFit.fitWidth,
              filterQuality: FilterQuality.medium,
            ),
      headerLabel: genre ?? context.l10n.podcast,
      headerTitle: title,
      headerSubtile: audios?.firstOrNull?.artist,
      headerDescription: audios?.firstOrNull?.albumArtist,
      audios: audios,
      pageId: pageId,
      title: Text(title),
      controlPanelTitle: Text(title),
      controlPanelButton: IconButton(
        icon: Icon(
          Iconz().rss,
          color: subscribed
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        onPressed: () {
          if (subscribed) {
            removePodcast(pageId);
          } else if (audios?.isNotEmpty == true) {
            addPodcast(pageId, audios!);
          }
        },
      ),
    );
  }
}
