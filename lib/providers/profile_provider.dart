import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/misc_models.dart';
import '../models/user_session.dart';
import '../services/user_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider();

  final UserService _service = UserService();

  CustomerProfile? profile;
  List<FamilyMember> familyMembers = [];
  List<SavedAddress> addresses = [];
  bool loading = false;
  bool saving = false;

  static const String _addressesKey = 'pi_saved_addresses';
  static const String _lastAddressKey = 'pi_last_booking_address';

  Future<void> load() async {
    loading = true;
    notifyListeners();
    profile = await _service.getProfile();
    if (profile != null) {
      familyMembers = await _service.familyMembers(profile!);
    }
    loading = false;
    notifyListeners();
    await loadAddresses();
  }

  Future<bool> save(CustomerProfile updated) async {
    saving = true;
    notifyListeners();
    final ok = await _service.updateProfile(updated);
    if (ok) {
      profile = updated;
      familyMembers = await _service.familyMembers(updated);
    }
    saving = false;
    notifyListeners();
    return ok;
  }

  Future<void> saveFamilyMembers(List<FamilyMember> members) async {
    if (profile == null) return;
    final updated = CustomerProfile(
      id: profile!.id,
      username: profile!.username,
      fullName: profile!.fullName,
      email: profile!.email,
      phonenumber: profile!.phonenumber,
      dateOfBirth: profile!.dateOfBirth,
      timeOfBirth: profile!.timeOfBirth,
      placeOfBirth: profile!.placeOfBirth,
      pujaLanguage: profile!.pujaLanguage,
      gotra: profile!.gotra,
      kulaDevata: profile!.kulaDevata,
      nakshatra: profile!.nakshatra,
      rashi: profile!.rashi,
      city: profile!.city,
      state: profile!.state,
      address: profile!.address,
      familyMembers: FamilyMember.encodeList(members),
      profilePhotoUrl: profile!.profilePhotoUrl,
      latitude: profile!.latitude,
      longitude: profile!.longitude,
      timezone: profile!.timezone,
    );
    final ok = await save(updated);
    if (ok) familyMembers = members;
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null || raw.isEmpty) {
      addresses = [];
    } else {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          addresses = decoded
              .whereType<Map>()
              .map((e) => SavedAddress.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {
        addresses = [];
      }
    }
    notifyListeners();
  }

  Future<void> upsertAddress(SavedAddress address) async {
    final idx = addresses.indexWhere((a) => a.id == address.id);
    if (idx >= 0) {
      addresses[idx] = address;
    } else {
      addresses.insert(0, address);
    }
    await _persistAddresses();
  }

  Future<void> removeAddress(String id) async {
    addresses = addresses.where((a) => a.id != id).toList();
    await _persistAddresses();
  }

  Future<void> _persistAddresses() async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _addressesKey,
      jsonEncode(addresses.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> rememberLastAddress(String raw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAddressKey, raw);
  }

  Future<String?> lastAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastAddressKey);
  }
}
