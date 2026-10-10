import 'dart:async';

import 'package:parkpin/core/constants/db_tables.dart';
import 'package:parkpin/models/app_notification.dart';
import 'package:parkpin/models/app_user.dart';
import 'package:parkpin/models/bay.dart';
import 'package:parkpin/models/booking.dart';
import 'package:parkpin/models/parking_facility.dart';
import 'package:parkpin/models/payment.dart';
import 'package:parkpin/models/pricing_rule.dart';
import 'package:parkpin/services/auth_service.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// All Supabase calls for the operator screens (O01–O10).
/// Row Level Security makes sure an operator only ever touches their own
/// car park, so every query below is also filtered by [facilityId].
class OperatorService {
  OperatorService._();
  static final OperatorService instance = OperatorService._();

  SupabaseClient get _db => SupabaseService.client;

  AppUser? _profile;
  ParkingFacility? _facility;

  AppUser? get profile => _profile;
  ParkingFacility? get facility => _facility;
  String? get email => AuthService.instance.currentEmail;

  String get facilityId {
    final id = _profile?.facilityId;
    if (id == null) throw const AppException('No car park is linked to this operator account.');
    return id;
  }

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const AppException('Your session has ended. Please log in again.');
    return id;
  }

  // ───────────────────────── O01 Login / session ─────────────────────────

  /// Signs in and checks that the account really is an operator.
  Future<AppUser> signIn(String email, String password) async {
    final user = await AuthService.instance.signIn(email, password);
    await _acceptOperator(user);
    return user;
  }

  /// Reuses a saved session if the phone is already signed in as an operator.
  Future<bool> restoreSession() async {
    try {
      final user = await AuthService.instance.currentProfile();
      if (user == null || !user.isOperator || user.facilityId == null) return false;
      _profile = user;
      await getFacility(refresh: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _acceptOperator(AppUser user) async {
    if (!user.isOperator) {
      await AuthService.instance.signOut();
      throw const AppException('This account is not a car-park operator account.');
    }
    if (user.facilityId == null) {
      await AuthService.instance.signOut();
      throw const AppException('No car park is linked to this operator account yet.');
    }
    _profile = user;
    await getFacility(refresh: true);
  }

  /// Makes sure profile + facility are loaded (e.g. after a hot restart).
  Future<void> ensureLoaded() async {
    if (_profile == null) {
      final ok = await restoreSession();
      if (!ok) throw const AppException('Your session has ended. Please log in again.');
    }
    if (_facility == null) await getFacility(refresh: true);
  }

  /// O01 – "Forgot password?": Supabase emails a reset link.
  Future<void> sendPasswordReset(String email) async {
    await _db.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    _profile = null;
    _facility = null;
  }

  // ───────────────────────── Facility + profile (O06, O10) ─────────────────────────

  Future<ParkingFacility> getFacility({bool refresh = false}) async {
    if (!refresh && _facility != null) return _facility!;
    final row = await _db.from(DbTables.parkingFacilities).select().eq('id', facilityId).single();
    _facility = ParkingFacility.fromMap(row);
    return _facility!;
  }

  Future<void> updateFacility({String? name, String? address, double? ratePerHour, double? reservationFee}) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (address != null) 'address': address.trim(),
      'rate_per_hour': ?ratePerHour,
      'reservation_fee': ?reservationFee,
    };
    if (data.isEmpty) return;
    await _db.from(DbTables.parkingFacilities).update(data).eq('id', facilityId);
    await getFacility(refresh: true);
  }

  Future<void> updateProfile({required String fullName, String? phone}) async {
    // Built directly (not copyWith) so a null phone clears the saved number.
    final p = _profile!;
    final updated = AppUser(
      id: p.id,
      fullName: fullName.trim(),
      phone: phone?.trim(),
      role: p.role,
      facilityId: p.facilityId,
      createdAt: p.createdAt,
    );
    await _db.from(DbTables.profiles).update(updated.toMap()).eq('id', _uid);
    _profile = updated;
  }

  // ───────────────────────── Bays (O02, O03) ─────────────────────────

  /// Live bay list – Supabase Realtime pushes every change (FR1).
  Stream<List<Bay>> watchBays() => _db
      .from(DbTables.bays)
      .stream(primaryKey: ['id'])
      .eq('facility_id', facilityId)
      .map((rows) => rows.map(Bay.fromMap).toList()..sort(Bay.compare));

  Future<List<Bay>> getBays() async {
    final rows = await _db.from(DbTables.bays).select().eq('facility_id', facilityId);
    return rows.map(Bay.fromMap).toList()..sort(Bay.compare);
  }

  /// Publishes availability: {bayId: 'available' | 'occupied'}.
  Future<void> setBayStatuses(Map<String, String> changes) async {
    await Future.wait(changes.entries.map(
      (e) => _db.from(DbTables.bays).update({'status': e.value}).eq('id', e.key),
    ));
  }

  Future<void> addBay({required String label, String? level, String type = 'standard'}) async {
    await _db.from(DbTables.bays).insert({
      'facility_id': facilityId,
      'label': label.trim().toUpperCase(),
      'level': (level == null || level.trim().isEmpty) ? null : level.trim().toUpperCase(),
      'type': type,
      'status': Bay.available,
    });
    await _syncTotalBays();
  }

  Future<void> updateBay(String bayId, {required String label, String? level, required String type}) async {
    await _db.from(DbTables.bays).update({
      'label': label.trim().toUpperCase(),
      'level': (level == null || level.trim().isEmpty) ? null : level.trim().toUpperCase(),
      'type': type,
    }).eq('id', bayId);
  }

  Future<void> deleteBay(Bay bay) async {
    if (bay.status == Bay.reserved) {
      throw const AppException('This bay is held for a booking. Reassign the booking first.');
    }
    await _db.from(DbTables.bays).delete().eq('id', bay.id);
    await _syncTotalBays();
  }

  Future<void> _syncTotalBays() async {
    final bays = await getBays();
    await _db.from(DbTables.parkingFacilities).update({'total_bays': bays.length}).eq('id', facilityId);
  }

  Future<List<Bay>> getFreeBays() async {
    final rows = await _db
        .from(DbTables.bays)
        .select()
        .eq('facility_id', facilityId)
        .eq('status', Bay.available);
    return rows.map(Bay.fromMap).toList()..sort(Bay.compare);
  }

  // ───────────────────────── Bookings (O02, O04, O05, O08) ─────────────────────────

  static const String _bookingSelect = '*, profiles(full_name), bays(label, level)';

  /// Bookings from the last 30 days onward, oldest first.
  Future<List<Booking>> getBookings() async {
    final since = DateTime.now().subtract(const Duration(days: 30)).toUtc().toIso8601String();
    final rows = await _db
        .from(DbTables.bookings)
        .select(_bookingSelect)
        .eq('facility_id', facilityId)
        .gte('start_time', since)
        .order('start_time');
    return rows.map(Booking.fromMap).toList();
  }

  /// Emits whenever any booking at this car park changes (used to refresh lists).
  Stream<void> watchBookingChanges() => _db
      .from(DbTables.bookings)
      .stream(primaryKey: ['id'])
      .eq('facility_id', facilityId)
      .map((_) {});

  Future<Booking> getBooking(String id) async {
    final row = await _db.from(DbTables.bookings).select(_bookingSelect).eq('id', id).single();
    return Booking.fromMap(row);
  }

  /// O08 – look up the code typed in or read from the driver's QR.
  Future<Booking?> findByCode(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return null;
    final row = await _db
        .from(DbTables.bookings)
        .select(_bookingSelect)
        .eq('facility_id', facilityId)
        .eq('booking_code', clean)
        .maybeSingle();
    return row == null ? null : Booking.fromMap(row);
  }

  Future<void> setBookingStatus(String bookingId, String status) async {
    await _db.from(DbTables.bookings).update({'status': status}).eq('id', bookingId);
  }

  /// Gives a booking a bay. A database trigger frees the old bay and marks the
  /// new one reserved/occupied; a unique index stops double-booking.
  Future<void> assignBay(String bookingId, String bayId) async {
    await _db.from(DbTables.bookings).update({'bay_id': bayId}).eq('id', bookingId);
  }

  /// O05 – keep the booking and make sure it holds a bay. Returns the bay used.
  Future<String> confirmAndHold(Booking b) async {
    var label = b.bayDisplay;
    if (!b.hasBay) {
      final free = await getFreeBays();
      if (free.isEmpty) throw const AppException('No free bays right now. Free a bay first.');
      await assignBay(b.id, free.first.id);
      label = free.first.display;
    }
    await notify(b.driverId, 'Your bay is held',
        'Bay $label is held for you at ${_facility?.name ?? 'the car park'}.',
        type: 'booking');
    return label;
  }

  /// O04 – give every pending booking without a bay a free bay.
  /// Returns how many bookings were updated.
  Future<int> holdPendingBays(List<Booking> bookings) async {
    final waiting = bookings.where((b) => b.status == Booking.reserved && !b.hasBay).toList();
    if (waiting.isEmpty) return 0;
    final free = await getFreeBays();
    var count = 0;
    for (final b in waiting) {
      if (count >= free.length) break;
      final bay = free[count];
      await assignBay(b.id, bay.id);
      await notify(b.driverId, 'Your bay is held', 'Bay ${bay.display} is held for you.', type: 'booking');
      count++;
    }
    return count;
  }

  /// O08 – admit a driver at the gate (assigns a bay if needed, marks active).
  Future<String> admit(Booking b) async {
    if (b.status != Booking.reserved) throw const AppException('Only pending bookings can be admitted.');
    var bayId = b.bayId;
    var label = b.bayDisplay;
    if (bayId == null) {
      final free = await getFreeBays();
      if (free.isEmpty) throw const AppException('Car park is full – no free bay to assign.');
      bayId = free.first.id;
      label = free.first.display;
    }
    await _db.from(DbTables.bookings).update({'bay_id': bayId, 'status': Booking.active}).eq('id', b.id);
    await notify(b.driverId, 'Checked in', 'Welcome! Please park in bay $label.', type: 'booking');
    await notify(_uid, 'Gate scan complete', 'Bay $label admitted · ${b.bookingCode}', type: 'system');
    return label;
  }

  /// O05/O08 – driver leaves; the trigger frees the bay.
  Future<void> checkOut(Booking b) async {
    await setBookingStatus(b.id, Booking.completed);
    await notify(b.driverId, 'Thanks for parking', 'Your booking ${b.bookingCode} is complete.', type: 'booking');
  }

  Future<void> markNoShow(Booking b) async {
    await setBookingStatus(b.id, Booking.expired);
    await notify(b.driverId, 'Booking expired',
        'You did not arrive, so booking ${b.bookingCode} was released.',
        type: 'booking');
  }

  /// O05 – driver's phone number so staff can call about a late arrival.
  Future<String?> getDriverPhone(String driverId) async {
    final row = await _db.from(DbTables.profiles).select('phone').eq('id', driverId).maybeSingle();
    final phone = (row?['phone'] as String?)?.trim();
    return (phone == null || phone.isEmpty) ? null : phone;
  }

  /// O05 – how much has been paid for one booking (booking + extensions).
  Future<double> getBookingPaidTotal(String bookingId) async {
    final rows = await _db
        .from(DbTables.payments)
        .select('total, status')
        .eq('booking_id', bookingId)
        .eq('status', 'paid');
    return rows.fold<double>(0, (sum, r) => sum + ((r['total'] as num?)?.toDouble() ?? 0));
  }

  // ───────────────────────── Payments (O02, O07) ─────────────────────────

  Future<List<Payment>> getPayments({required DateTime since}) async {
    final rows = await _db
        .from(DbTables.payments)
        .select()
        .eq('facility_id', facilityId)
        .gte('created_at', since.toUtc().toIso8601String())
        .order('created_at', ascending: false);
    return rows.map(Payment.fromMap).toList();
  }

  // ───────────────────────── Off-peak pricing (O06) ─────────────────────────

  Future<PricingRule?> getOffPeakRule() async {
    final row = await _db
        .from(DbTables.pricingRules)
        .select()
        .eq('facility_id', facilityId)
        .eq('is_off_peak', true)
        .limit(1)
        .maybeSingle();
    return row == null ? null : PricingRule.fromMap(row);
  }

  /// Off-peak rate after a percentage discount, rounded to 2 decimals.
  static double offPeakRate(double standardRate, int discountPercent) =>
      (standardRate * (100 - discountPercent)).round() / 100;

  /// Discount (%) that turns [standardRate] into [offPeak].
  static int discountFrom(double standardRate, double offPeak) {
    if (standardRate <= 0) return 0;
    return ((1 - offPeak / standardRate) * 100).round().clamp(0, 100);
  }

  Future<void> saveOffPeak({
    required double standardRate,
    required double reservationFee,
    required int startHour,
    required int endHour,
    required int discountPercent,
    required bool promote,
    List<int> days = const [1, 2, 3, 4, 5], // 0 = Sunday … 6 = Saturday
  }) async {
    await updateFacility(ratePerHour: standardRate, reservationFee: reservationFee);
    final data = {
      'facility_id': facilityId,
      'label': 'Off-peak',
      'rate_per_hour': offPeakRate(standardRate, discountPercent),
      'start_hour': startHour,
      'end_hour': endHour,
      'days': days,
      'is_off_peak': true,
      'is_active': promote,
    };
    final existing = await getOffPeakRule();
    if (existing == null) {
      await _db.from(DbTables.pricingRules).insert(data);
    } else {
      await _db.from(DbTables.pricingRules).update(data).eq('id', existing.id);
    }
  }

  // ───────────────────────── Notifications (O09) ─────────────────────────

  Stream<List<AppNotification>> watchNotifications() => _db
      .from(DbTables.notifications)
      .stream(primaryKey: ['id'])
      .eq('user_id', _uid)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(AppNotification.fromMap).toList());

  // Supabase queries only run when awaited, so these use async/await.
  Future<void> markRead(String id) async {
    await _db.from(DbTables.notifications).update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    await _db.from(DbTables.notifications).update({'is_read': true}).eq('user_id', _uid).eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await _db.from(DbTables.notifications).delete().eq('id', id);
  }

  /// O05 – operator writes a message to the driver of a booking.
  Future<void> messageDriver(Booking b, String message) async {
    await _db.from(DbTables.notifications).insert({
      'user_id': b.driverId,
      'title': 'Message from ${_facility?.name ?? 'the car park'}',
      'message': message.trim(),
      'type': 'booking',
    });
  }

  /// Sends a notification (to a driver, or to the operator themself).
  /// A failed notification never blocks the main action.
  Future<void> notify(String userId, String title, String message, {String type = 'system'}) async {
    try {
      await _db.from(DbTables.notifications).insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
      });
    } catch (_) {}
  }
}
