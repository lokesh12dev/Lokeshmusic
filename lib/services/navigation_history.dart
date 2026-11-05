/*
 *     Copyright (C) 2026 Lokesh
 *
 *     Lokeshmusic is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Lokeshmusic is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Lokeshmusic, including how to contribute,
 *     please visit: https://github.com/lokesh/Lokeshmusic
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// Spotify-style back / forward navigation for the desktop shell.
///
/// go_router preserves the state of independent branches but exposes no
/// history, so we wallpaper over that by recording every location the
/// route information provider reports and replaying it with [GoRouter.go]
/// on back / forward taps.
class NavigationHistory extends ChangeNotifier {
  NavigationHistory._();

  static final NavigationHistory instance = NavigationHistory._();

  static const int _maxEntries = 100;

  GoRouter? _router;
  bool _attached = false;

  final List<String> _locations = <String>[];
  int _index = -1;

  /// True while a back- / forward-triggered [GoRouter.go] is in flight, so
  /// the resulting notification is not recorded as a new entry.
  bool _jumping = false;

  bool get canBack => _index > 0;
  bool get canForward => _index >= 0 && _index < _locations.length - 1;

  /// Starts recording. Idempotent per router instance.
  void attach(GoRouter router) {
    if (_attached) return;

    _router = router;
    _attached = true;
    router.routeInformationProvider.addListener(_onRouterChanged);
    _recordCurrentLocation();
  }

  void back() => _move(-1);

  void forward() => _move(1);

  void _move(int delta) {
    final router = _router;
    final target = _index + delta;
    if (router == null || target < 0 || target >= _locations.length) return;

    _index = target;
    _jumping = true;
    notifyListeners();
    router.go(_locations[_index]);

    // The jump normally produces a provider notification that clears the
    // flag; if go() ends up silent (same location reported), this frame
    // callback stops the flag from swallowing the next real navigation.
    SchedulerBinding.instance.addPostFrameCallback((_) => _jumping = false);
  }

  void _onRouterChanged() {
    if (_jumping) {
      _jumping = false;
      return;
    }
    _recordCurrentLocation();
  }

  void _recordCurrentLocation() {
    final router = _router;
    if (router == null) return;

    final path = router.routeInformationProvider.value.uri.path;
    if (path.isEmpty) return;
    if (_index >= 0 && _locations[_index] == path) return;

    if (_index < _locations.length - 1) {
      _locations.removeRange(_index + 1, _locations.length);
    }
    _locations.add(path);
    if (_locations.length > _maxEntries) {
      _locations.removeAt(0);
    }
    _index = _locations.length - 1;
    notifyListeners();
  }
}
