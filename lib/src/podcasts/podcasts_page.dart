import 'package:flutter/material.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:provider/provider.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

import '../../app.dart';
import '../../common.dart';
import '../../constants.dart';
import '../../data.dart';
import '../../player.dart';
import '../../podcasts.dart';
import '../l10n/l10n.dart';
import '../library/library_model.dart';

class PodcastsPage extends StatefulWidget {
  const PodcastsPage({
    super.key,
    required this.isOnline,
    this.countryCode,
  });

  final bool isOnline;
  final String? countryCode;

  @override
  State<PodcastsPage> createState() => _PodcastsPageState();
}

class _PodcastsPageState extends State<PodcastsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<PodcastModel>().init(
            countryCode: widget.countryCode,
            updateMessage: context.l10n.newEpisodeAvailable,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.read<PodcastModel>();
    final searchActive = context.select((PodcastModel m) => m.searchActive);
    final setSearchActive = model.setSearchActive;
    final startPlaylist = context.read<PlayerModel>().startPlaylist;
    final theme = Theme.of(context);
    final libraryModel = context.read<LibraryModel>();
    final podcastSubscribed = libraryModel.podcastSubscribed;
    final removePodcast = libraryModel.removePodcast;
    final addPodcast = libraryModel.addPodcast;
    final setLimit = model.setLimit;
    final setSelectedFeedUrl = model.setSelectedFeedUrl;
    final selectedFeedUrl =
        context.select((PodcastModel m) => m.selectedFeedUrl);
    final limit = context.select((PodcastModel m) => m.limit);

    final search = model.search;
    final setSearchQuery = model.setSearchQuery;
    final textStyle =
        theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);
    final buttonStyle = TextButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    );

    final searchQuery = context.select((PodcastModel m) => m.searchQuery);

    final country = context.select((PodcastModel m) => m.country);
    final sortedCountries =
        context.select((PodcastModel m) => m.sortedCountries);
    context.select((PodcastModel m) => m.country);

    final setCountry = model.setCountry;
    final podcastGenre = context.select((PodcastModel m) => m.podcastGenre);
    final sortedGenres = context.select((PodcastModel m) => m.sortedGenres);
    final setPodcastGenre = model.setPodcastGenre;
    final searchResult = context.select((PodcastModel m) => m.searchResult);
    final searchResultCount =
        context.select((PodcastModel m) => m.searchResult?.resultCount);

    final showWindowControls =
        context.select((AppModel a) => a.showWindowControls);

    void onTapText(String text) {
      setSearchQuery(text);
      search(searchQuery: text);
    }

    Widget grid;
    if (searchResult == null) {
      grid = GridView(
        gridDelegate: imageGridDelegate,
        padding: gridPadding,
        children: List.generate(limit, (index) => Audio())
            .map((e) => const AudioCard())
            .toList(),
      );
    } else if (searchResult.items.isEmpty == true) {
      grid = NoSearchResultPage(message: Text(context.l10n.noPodcastFound));
    } else {
      grid = GridView.builder(
        padding: gridPadding,
        itemCount: searchResultCount,
        gridDelegate: imageGridDelegate,
        itemBuilder: (context, index) {
          final podcastItem = searchResult.items.elementAt(index);

          final artworkUrl600 = podcastItem.artworkUrl600;
          final image = SafeNetworkImage(
            url: artworkUrl600,
            fit: BoxFit.cover,
            height: kSmallCardHeight,
            width: kSmallCardHeight,
          );

          return AudioCard(
            bottom: AudioCardBottom(text: podcastItem.collectionName ?? ''),
            image: image,
            onPlay: () {
              if (podcastItem.feedUrl == null) return;
              findEpisodes(
                feedUrl: podcastItem.feedUrl!,
                itemImageUrl: artworkUrl600,
                genre: podcastItem.primaryGenreName,
              ).then((feed) {
                if (feed.isNotEmpty) {
                  _playOrConfirm(
                    amount: feed.length,
                    play: () => startPlaylist(feed, podcastItem.feedUrl!),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.podcastFeedIsEmpty)),
                  );
                }
              });
            },
            onTap: () async => await pushPodcastPage(
              context: context,
              podcastItem: podcastItem,
              podcastSubscribed: podcastSubscribed,
              onTapText: ({required audioType, required text}) =>
                  onTapText(text),
              removePodcast: removePodcast,
              addPodcast: addPodcast,
              setFeedUrl: setSelectedFeedUrl,
              oldFeedUrl: selectedFeedUrl,
              itemImageUrl: artworkUrl600,
              genre: podcastItem.primaryGenreName,
              countryCode: widget.countryCode,
            ),
          );
        },
      );
    }

    final controlPanel = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          LimitPopup(
            value: limit,
            onSelected: (value) {
              setLimit(value);
              search(searchQuery: searchQuery);
            },
          ),
          CountryPopup(
            onSelected: (value) {
              setCountry(value);
              search(searchQuery: searchQuery);
            },
            value: country,
            countries: sortedCountries,
          ),
          YaruPopupMenuButton<PodcastGenre>(
            style: buttonStyle,
            icon: const DropDownArrow(),
            onSelected: (value) {
              setPodcastGenre(value);
              search(searchQuery: searchQuery);
            },
            initialValue: podcastGenre,
            child: Text(
              podcastGenre.localize(context.l10n),
              style: textStyle,
            ),
            itemBuilder: (context) {
              return [
                for (final genre in sortedGenres)
                  PopupMenuItem(
                    value: genre,
                    child: Text(genre.localize(context.l10n)),
                  ),
              ];
            },
          ),
        ],
      ),
    );

    if (!widget.isOnline) {
      return const OfflinePage();
    } else {
      return YaruDetailPage(
        appBar: HeaderBar(
          leading: (Navigator.canPop(context))
              ? const NavBackButton()
              : const SizedBox.shrink(),
          titleSpacing: 0,
          style: showWindowControls
              ? YaruTitleBarStyle.normal
              : YaruTitleBarStyle.undecorated,
          actions: [
            Padding(
              padding: appBarActionSpacing,
              child: SearchButton(
                active: searchActive,
                onPressed: () => setSearchActive(!searchActive),
              ),
            ),
          ],
          title: searchActive
              ? SearchingBar(
                  key: ValueKey(searchQuery),
                  text: searchQuery,
                  onClear: () {
                    setSearchActive(false);
                    setSearchQuery('');
                    search();
                  },
                  onSubmitted: (value) {
                    setSearchQuery(value);

                    if (value?.isEmpty == true) {
                      search();
                    } else {
                      search(searchQuery: value);
                    }
                  },
                )
              : Text(context.l10n.podcasts),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            controlPanel,
            const SizedBox(
              height: 15,
            ),
            Expanded(child: grid),
          ],
        ),
      );
    }
  }

  void _playOrConfirm({required int amount, required Function play}) {
    if (amount < kAudioQueueThreshHold) {
      play();
    } else {
      showDialog<bool>(
        context: context,
        builder: (context) {
          return ConfirmationDialog(
            message: Text(
              context.l10n.queueConfirmMessage(
                amount.toString(),
              ),
            ),
          );
        },
      ).then((value) {
        if (value == true) {
          play();
        }
      });
    }
  }
}

Future<void> pushPodcastPage({
  required BuildContext context,
  required Item podcastItem,
  required bool Function(String? feedUrl) podcastSubscribed,
  required void Function({
    required String text,
    required AudioType audioType,
  }) onTapText,
  required void Function(String feedUrl) removePodcast,
  required void Function(String feedUrl, Set<Audio> audios) addPodcast,
  required void Function(String? feedUrl) setFeedUrl,
  required String? oldFeedUrl,
  String? itemImageUrl,
  String? genre,
  String? countryCode,
}) async {
  if (podcastItem.feedUrl == null) return;

  setFeedUrl(podcastItem.feedUrl);

  await findEpisodes(
    feedUrl: podcastItem.feedUrl!,
    itemImageUrl: itemImageUrl,
    genre: genre,
  ).then((podcast) async {
    if (oldFeedUrl == podcastItem.feedUrl || podcast.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final subscribed = podcastSubscribed(podcastItem.feedUrl);
          final id = podcastItem.feedUrl;

          return PodcastPage(
            subscribed: subscribed,
            imageUrl: podcastItem.artworkUrl600,
            addPodcast: addPodcast,
            removePodcast: removePodcast,
            onTextTap: onTapText,
            audios: podcast,
            pageId: id!,
            title: podcast.firstOrNull?.album ??
                podcast.firstOrNull?.title ??
                podcastItem.feedUrl!,
          );
        },
      ),
    ).then((_) => setFeedUrl(null));
  });
}

class PodcastsPageIcon extends StatelessWidget {
  const PodcastsPageIcon({
    super.key,
    required this.isPlaying,
    required this.selected,
    required this.checkingForUpdates,
  });

  final bool isPlaying, selected, checkingForUpdates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (checkingForUpdates) {
      return const SideBarProgress();
    }

    if (isPlaying) {
      return Icon(
        Iconz().play,
        color: theme.colorScheme.primary,
      );
    }

    return selected ? Icon(Iconz().podcastFilled) : Icon(Iconz().podcast);
  }
}
