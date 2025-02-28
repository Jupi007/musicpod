import 'dart:async';

import 'package:collection/collection.dart';
import 'package:podcast_search/podcast_search.dart';
import 'package:radio_browser_api/radio_browser_api.dart' hide Country;
import 'package:safe_change_notifier/safe_change_notifier.dart';

import '../../data.dart';
import '../../string_x.dart';
import 'radio_service.dart';

class RadioModel extends SafeChangeNotifier {
  final RadioService _radioService;

  RadioModel(this._radioService);

  StreamSubscription<bool>? _stationsSub;
  StreamSubscription<bool>? _statusCodeSub;
  StreamSubscription<bool>? _searchSub;
  StreamSubscription<bool>? _tagsSub;

  Country? _country;
  Country? get country => _country;
  void setCountry(Country? value) {
    if (value == _country) return;
    _country = value;
    notifyListeners();
  }

  List<Country> get sortedCountries {
    if (_country == null) return Country.values;
    final notSelected =
        Country.values.where((c) => c != _country).toList().sorted(
              (a, b) => a.name.compareTo(b.name),
            );
    final list = <Country>[_country!, ...notSelected];

    return list;
  }

  List<Tag>? get tags => _radioService.tags;
  Tag? _tag;
  Tag? get tag => _tag;
  void setTag(Tag? value) {
    if (value == _tag) return;
    _tag = value;
    notifyListeners();
  }

  Set<Audio>? get stations {
    if (_radioService.stations != null) {
      if (_radioService.stations!.isEmpty) {
        return <Audio>{};
      }

      return Set.from(
        _radioService.stations!.map(
          (e) => Audio(
            url: e.urlResolved,
            title: e.name,
            artist: e.bitrate == 0 ? ' ' : '${e.bitrate.toString()} kb/s',
            album: e.tags ?? '',
            audioType: AudioType.radio,
            imageUrl: e.favicon,
            website: e.homepage,
          ),
        ),
      );
    } else {
      return null;
    }
  }

  String? get statusCode => _radioService.statusCode;

  int _limit = 100;
  int get limit => _limit;
  void setLimit(int? value) {
    if (value == null || value == _limit) return;
    _limit = value;
    notifyListeners();
  }

  bool? _connected;
  bool? get connected => _connected;

  Future<void> init(String? countryCode, String? lastFav) async {
    _connected = await _radioService.init();

    _stationsSub =
        _radioService.stationsChanged.listen((_) => notifyListeners());

    _statusCodeSub =
        _radioService.statusCodeChanged.listen((_) => notifyListeners());

    _searchSub =
        _radioService.searchQueryChanged.listen((_) => notifyListeners());

    _tagsSub = _radioService.tagsChanged.listen((_) => notifyListeners());

    if (connected == true) {
      await _radioService.loadTags();

      if (_tag == null) {
        _tag = lastFav == null || tags == null || tags!.isEmpty
            ? null
            : tags!.firstWhere((t) => t.name.contains(lastFav));
        await loadStationsByTag();
      }

      if (stations == null) {
        final c = Country.values.firstWhereOrNull((c) => c.code == countryCode);
        _country = c;
        await loadStationsByCountry();
      }
    }

    notifyListeners();
  }

  Future<void> loadStationsByCountry() {
    return _radioService.loadStations(
      country: country?.name.camelToSentence(),
      limit: limit,
    );
  }

  Future<void> loadStationsByTag() async {
    await _radioService.loadStations(tag: tag, limit: limit);
  }

  Future<void> search({String? name, String? tag}) async {
    if (name != null) {
      if (name.trim().isEmpty) {
        setTag(null);
        await loadStationsByCountry();
      } else {
        await _radioService.loadStations(name: name, limit: limit);
      }
    } else if (tag != null) {
      await _radioService.loadStations(
        tag: Tag(name: tag, stationCount: 1),
        limit: limit,
      );
    } else {
      setTag(null);
      await loadStationsByCountry();
    }
  }

  String? get searchQuery => _radioService.searchQuery;
  void setSearchQuery(String? value) => _radioService.setSearchQuery(value);

  bool _searchActive = false;
  bool get searchActive => _searchActive;
  void setSearchActive(bool value) {
    if (value == _searchActive) return;
    _searchActive = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _stationsSub?.cancel();
    _searchSub?.cancel();
    _tagsSub?.cancel();
    _statusCodeSub?.cancel();
    super.dispose();
  }
}
