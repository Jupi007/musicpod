import 'package:flutter/material.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

import '../../data.dart';
import '../l10n/l10n.dart';
import '../library/playlist_dialog.dart';
import 'icons.dart';
import 'stream_provider_share_button.dart';

class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.audio,
    required this.audioSelected,
    required this.playlistId,
    required this.liked,
    required this.removeLikedAudio,
    required this.addLikedAudio,
    this.onRemoveFromPlaylist,
    required this.topFivePlaylistNames,
    required this.addAudioToPlaylist,
    required this.addPlaylist,
    this.insertIntoQueue,
  });

  final String playlistId;
  final Audio audio;
  final bool audioSelected;
  final bool liked;
  final void Function(Audio, [bool]) removeLikedAudio;
  final void Function(Audio, [bool]) addLikedAudio;
  final void Function(String, Audio)? onRemoveFromPlaylist;
  final List<String>? topFivePlaylistNames;
  final void Function(String, Audio) addAudioToPlaylist;
  final void Function(String, Set<Audio>) addPlaylist;
  final void Function()? insertIntoQueue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final heartButton = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => liked ? removeLikedAudio(audio) : addLikedAudio(audio),
      child: Iconz().getAnimatedHeartIcon(
        liked: liked,
        color: audioSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
    );

    return _Button(
      insertIntoQueue: insertIntoQueue,
      artist: audio.artist ?? '',
      title: audio.title ?? '',
      playlistId: playlistId,
      onRemoveFromPlaylist: onRemoveFromPlaylist == null
          ? null
          : (v) => onRemoveFromPlaylist!(v, audio),
      onCreateNewPlaylist: () {
        showDialog(
          context: context,
          builder: (context) {
            return PlaylistDialog(
              audios: {audio},
              onCreateNewPlaylist: addPlaylist,
            );
          },
        );
      },
      onAddToPlaylist: (playlistId) => addAudioToPlaylist(playlistId, audio),
      topFivePlaylistIds: topFivePlaylistNames,
      icon: heartButton,
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    this.onCreateNewPlaylist,
    this.onRemoveFromPlaylist,
    this.onAddToPlaylist,
    this.playlistId,
    this.topFivePlaylistIds,
    required this.icon,
    required this.artist,
    required this.title,
    this.insertIntoQueue,
  });

  final void Function()? insertIntoQueue;
  final void Function()? onCreateNewPlaylist;
  final void Function(String playlistId)? onRemoveFromPlaylist;
  final void Function(String playlistId)? onAddToPlaylist;
  final String? playlistId;
  final List<String>? topFivePlaylistIds;
  final Widget icon;
  final String artist;
  final String title;

  @override
  Widget build(BuildContext context) {
    return YaruPopupMenuButton(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.circular(kYaruButtonRadius),
        ),
      ),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            onTap: onCreateNewPlaylist,
            child: Text(context.l10n.createNewPlaylist),
          ),
          PopupMenuItem(
            onTap: insertIntoQueue,
            child: Text(context.l10n.insertIntoQueue),
          ),
          if (onRemoveFromPlaylist != null)
            PopupMenuItem(
              onTap: onRemoveFromPlaylist == null || playlistId == null
                  ? null
                  : () => onRemoveFromPlaylist!(playlistId!),
              child: Text('Remove from $playlistId'),
            ),
          if (topFivePlaylistIds != null)
            for (final playlist in topFivePlaylistIds!)
              PopupMenuItem(
                onTap: onAddToPlaylist == null
                    ? null
                    : () => onAddToPlaylist!(playlist),
                child: Text(
                  '${context.l10n.addTo} $playlist',
                ),
              ),
          PopupMenuItem(
            padding: EdgeInsets.zero,
            child: StreamProviderRow(text: '$artist - $title'),
          ),
        ];
      },
      child: icon,
    );
  }
}
