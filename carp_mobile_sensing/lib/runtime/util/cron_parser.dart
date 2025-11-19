/* 
 * Copyright (c) 2020, rbubke.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

part of '../../runtime.dart';

abstract class HasNext<E> {
  /// Find next suitable date
  E next();
}

abstract class HasPrevious<E> {
  /// Find previous suitable date
  E previous();
}

mixin CronIterator<E> on HasPrevious<E>, HasNext<E> {
  E current();
}

abstract class Cron {
  factory Cron() {
    tz.initializeTimeZones();
    return _Cron();
  }

  /// Takes a [cronString], a [locationName] and an optional [startTime].
  /// It returns an iterator [HasNext] which delivers [TZDateTime] events. If no [startTime]
  /// is provided [TZDateTime.now(getLocation(locationName)] is used.
  /// The [locationName] string has to be in the format listed at http://www.iana.org/time-zones.
  CronIterator<tz.TZDateTime> parse(
    String cronString,
    String locationName, [
    tz.TZDateTime? startTime,
  ]);
}

const String _regex0to59 = "([1-5]?[0-9])";
const String _regex0to23 = "([1]?[0-9]|[2][0-3])";
const String _regex1to31 = "([1-9]|[12][0-9]|[3][01])";
const String _regex1to12 = "([1-9]|[1][012])";
const String _regex0to7 = "([0-7])";
const String _minutesRegex =
    "((($_regex0to59[,])+$_regex0to59)|$_regex0to59([-]$_regex0to59)?|[*]([/]$_regex0to59)?)";
const String _hoursRegex =
    "((($_regex0to23[,])+$_regex0to23)|$_regex0to23([-]($_regex0to23))?|[*]([/]$_regex0to23)?)";
const String _daysRegex =
    "((($_regex1to31[,])+$_regex1to31)|$_regex1to31([-]$_regex1to31)?|[*]([/]$_regex1to31)?)";
const String _monthRegex =
    "((($_regex1to12[,])+$_regex1to12)|$_regex1to12([-]$_regex1to12)?|[*]([/]$_regex1to12)?)";
const String _weekdaysRegex =
    "((($_regex0to7[,])+$_regex0to7)|$_regex0to7([-]$_regex0to7)?|[*]([/]$_regex0to7)?)";
final RegExp _cronRegex = RegExp(
  "^$_minutesRegex\\s+$_hoursRegex\\s+$_daysRegex\\s+$_monthRegex\\s+$_weekdaysRegex\$",
);

class _Cron implements Cron {
  @override
  CronIterator<tz.TZDateTime> parse(
    String cronString,
    String locationName, [
    tz.TZDateTime? startTime,
  ]) {
    assert(cronString.isNotEmpty);
    assert(_cronRegex.hasMatch(cronString));
    var location = tz.getLocation(locationName);
    startTime ??= tz.TZDateTime.now(location);
    startTime = tz.TZDateTime.from(startTime, location);
    return _CronIterator(_parse(cronString), startTime);
  }

  _Schedule _parse(String cronString) {
    List<List<int>?> p = cronString
        .split(RegExp('\\s+'))
        .map(_parseConstraint)
        .toList();
    _Schedule schedule = _Schedule(
      minutes: p[0],
      hours: p[1],
      days: p[2],
      months: p[3],
      weekdays: p[4],
    );
    return schedule;
  }
}

class _Schedule {
  final List<int>? minutes;
  final List<int>? hours;
  final List<int>? days;
  final List<int>? months;
  final List<int>? weekdays;

  _Schedule._(this.minutes, this.hours, this.days, this.months, this.weekdays);

  factory _Schedule({
    dynamic minutes,
    dynamic hours,
    dynamic days,
    dynamic months,
    dynamic weekdays,
  }) {
    List<int>? parsedMinutes = _parseConstraint(
      minutes,
    )?.where((x) => x >= 0 && x <= 59).toList();
    List<int>? parsedHours = _parseConstraint(
      hours,
    )?.where((x) => x >= 0 && x <= 23).toList();
    List<int>? parsedDays = _parseConstraint(
      days,
    )?.where((x) => x >= 1 && x <= 31).toList();
    List<int>? parsedMonths = _parseConstraint(
      months,
    )?.where((x) => x >= 1 && x <= 12).toList();
    List<int>? parsedWeekdays = _parseConstraint(weekdays)
        ?.where((x) => x >= 0 && x <= 7)
        .map((x) => x == 0 ? 7 : x)
        .toSet()
        .toList();
    return _Schedule._(
      parsedMinutes,
      parsedHours,
      parsedDays,
      parsedMonths,
      parsedWeekdays,
    );
  }
}

List<int>? _parseConstraint(dynamic constraint) {
  if (constraint == null) return null;
  if (constraint is int) return [constraint];
  if (constraint is List<int>) return constraint;
  if (constraint is String) {
    if (constraint == '*') return null;
    final parts = constraint.split(',');
    if (parts.length > 1) {
      final items = parts
          .map(_parseConstraint)
          .expand((list) => list!)
          .toSet()
          .toList();
      items.sort();
      return items;
    }

    int? singleValue = int.tryParse(constraint);
    if (singleValue != null) return [singleValue];

    if (constraint.startsWith('*/')) {
      int period = int.tryParse(constraint.substring(2)) ?? -1;
      if (period > 0) {
        return List.generate(120 ~/ period, (i) => i * period);
      }
    }

    if (constraint.contains('-')) {
      List<String> ranges = constraint.split('-');
      if (ranges.length == 2) {
        int lower = int.tryParse(ranges.first) ?? -1;
        int higher = int.tryParse(ranges.last) ?? -1;
        if (lower <= higher) {
          return List.generate(higher - lower + 1, (i) => i + lower);
        }
      }
    }
  }
  throw 'Unable to parse: $constraint';
}

class _CronIterator implements CronIterator<tz.TZDateTime> {
  final _Schedule _schedule;
  tz.TZDateTime _currentDate;
  bool _nextCalled = false;
  bool _previousCalled = false;

  _CronIterator(this._schedule, this._currentDate) {
    _currentDate = tz.TZDateTime.fromMillisecondsSinceEpoch(
      _currentDate.location,
      _currentDate.millisecondsSinceEpoch ~/ 60000 * 60000,
    );
  }

  @override
  tz.TZDateTime next() {
    _nextCalled = true;
    _currentDate = _currentDate.add(const Duration(minutes: 1));
    while (true) {
      if (_schedule.months?.contains(_currentDate.month) == false) {
        _currentDate = tz.TZDateTime(
          _currentDate.location,
          _currentDate.year,
          _currentDate.month + 1,
          1,
        );
        continue;
      }
      if (_schedule.weekdays?.contains(_currentDate.weekday) == false) {
        _currentDate = tz.TZDateTime(
          _currentDate.location,
          _currentDate.year,
          _currentDate.month,
          _currentDate.day + 1,
        );
        continue;
      }
      if (_schedule.days?.contains(_currentDate.day) == false) {
        _currentDate = tz.TZDateTime(
          _currentDate.location,
          _currentDate.year,
          _currentDate.month,
          _currentDate.day + 1,
        );
        continue;
      }
      if (_schedule.hours?.contains(_currentDate.hour) == false) {
        _currentDate = _currentDate.add(const Duration(hours: 1));
        _currentDate = _currentDate.subtract(
          Duration(minutes: _currentDate.minute),
        );
        continue;
      }
      if (_schedule.minutes?.contains(_currentDate.minute) == false) {
        _currentDate = _currentDate.add(const Duration(minutes: 1));
        continue;
      }
      return _currentDate;
    }
  }

  @override
  tz.TZDateTime previous() {
    _previousCalled = true;
    _currentDate = _currentDate.subtract(const Duration(minutes: 1));
    while (true) {
      if (_schedule.minutes?.contains(_currentDate.minute) == false) {
        _currentDate = _currentDate.subtract(const Duration(minutes: 1));
        continue;
      }
      if (_schedule.hours?.contains(_currentDate.hour) == false) {
        _currentDate = _currentDate.subtract(const Duration(hours: 1));
        continue;
      }
      if (_schedule.days?.contains(_currentDate.day) == false) {
        _currentDate = _currentDate.subtract(const Duration(days: 1));
        continue;
      }
      if (_schedule.weekdays?.contains(_currentDate.weekday) == false) {
        _currentDate = tz.TZDateTime(
          _currentDate.location,
          _currentDate.year,
          _currentDate.month,
          _currentDate.day - 1,
          _currentDate.hour,
          _currentDate.minute,
        );
        continue;
      }
      if (_schedule.months?.contains(_currentDate.month) == false) {
        _currentDate = tz.TZDateTime(
          _currentDate.location,
          _currentDate.year,
          _currentDate.month - 1,
          _currentDate.day,
          _currentDate.hour,
          _currentDate.minute,
        );
        continue;
      }
      return _currentDate;
    }
  }

  @override
  tz.TZDateTime current() {
    assert(_nextCalled || _previousCalled);
    return _currentDate;
  }
}
