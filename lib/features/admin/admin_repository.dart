import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Talks to the license-manager Supabase edge function.
/// Same API as nusa-online/src/lib/license-manager.ts

const _edgeUrl = 'https://sakeuhcbcnueplzlkltm.supabase.co/functions/v1/license-manager';
const _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNha2V1aGNiY251ZXBsemxrbHRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM2ODIzMDEsImV4cCI6MjA5OTI1ODMwMX0.WvjZJ8Sd3o5T8a4vMApyvoCoS01Qv493mo1PxyWO06M';
const _adminKeyStore = 'nusa_admin_key';
const _secure = FlutterSecureStorage();

// ── Models ────────────────────────────────────────────────────────────

class LicenseRecord {
  final String id, key, serial, product, status, createdAt;
  final String? ownerEmail, googleUserId, expiresAt;
  final int activationCount;

  LicenseRecord({
    required this.id, required this.key, required this.serial,
    required this.product, required this.status, required this.createdAt,
    this.ownerEmail, this.googleUserId, this.expiresAt,
    required this.activationCount,
  });

  factory LicenseRecord.fromJson(Map<String, dynamic> j) => LicenseRecord(
    id: j['id'] as String, key: j['key'] as String,
    serial: j['serial'] as String,
    product: j['product'] as String? ?? 'nusa-kasir',
    status: j['status'] as String,
    createdAt: j['created_at'] as String,
    ownerEmail: j['owner_email'] as String?,
    googleUserId: j['google_user_id'] as String?,
    expiresAt: j['expires_at'] as String?,
    activationCount: (j['activation_count'] as num?)?.toInt() ?? 0,
  );
}

class ActivationRecord {
  final String id, licenseId, deviceId, createdAt;
  final String? googleUserId;
  ActivationRecord({required this.id, required this.licenseId, required this.deviceId, required this.createdAt, this.googleUserId});
  factory ActivationRecord.fromJson(Map<String, dynamic> j) => ActivationRecord(
    id: j['id'] as String, licenseId: j['license_id'] as String,
    deviceId: j['device_id'] as String, createdAt: j['created_at'] as String,
    googleUserId: j['google_user_id'] as String?,
  );
}

class LicenseDetail extends LicenseRecord {
  final List<ActivationRecord> activations;
  LicenseDetail({
    required super.id, required super.key, required super.serial,
    required super.product, required super.status, required super.createdAt,
    super.ownerEmail, super.googleUserId, super.expiresAt,
    required super.activationCount, required this.activations,
  });
  factory LicenseDetail.fromJson(Map<String, dynamic> j) {
    final acts = (j['activations'] as List<dynamic>?)
        ?.map((a) => ActivationRecord.fromJson(a as Map<String, dynamic>)).toList() ?? [];
    return LicenseDetail(
      id: j['id'] as String, key: j['key'] as String,
      serial: j['serial'] as String, product: j['product'] as String? ?? 'nusa-kasir',
      status: j['status'] as String, createdAt: j['created_at'] as String,
      ownerEmail: j['owner_email'] as String?, googleUserId: j['google_user_id'] as String?,
      expiresAt: j['expires_at'] as String?,
      activationCount: (j['activation_count'] as num?)?.toInt() ?? (j['device_count'] as num?)?.toInt() ?? acts.length,
      activations: acts,
    );
  }
}

class LicenseStats {
  final int total, generated, trial, active, cancelled, expired, suspended, totalActivations;
  LicenseStats({required this.total, required this.generated, required this.trial, required this.active, required this.cancelled, required this.expired, required this.suspended, required this.totalActivations});
  factory LicenseStats.fromJson(Map<String, dynamic> j) => LicenseStats(
    total: (j['total'] as num?)?.toInt() ?? 0,
    generated: (j['Generated'] as num?)?.toInt() ?? 0,
    trial: (j['Trial'] as num?)?.toInt() ?? 0,
    active: (j['Active'] as num?)?.toInt() ?? 0,
    cancelled: (j['Cancelled'] as num?)?.toInt() ?? 0,
    expired: (j['Expired'] as num?)?.toInt() ?? 0,
    suspended: (j['Suspended'] as num?)?.toInt() ?? 0,
    totalActivations: (j['total_activations'] as num?)?.toInt() ?? 0,
  );
}

class LicenseListResponse {
  final List<LicenseRecord> licenses;
  final int total, page, limit;
  LicenseListResponse({required this.licenses, required this.total, required this.page, required this.limit});
  factory LicenseListResponse.fromJson(Map<String, dynamic> j) => LicenseListResponse(
    licenses: (j['licenses'] as List<dynamic>).map((l) => LicenseRecord.fromJson(l as Map<String, dynamic>)).toList(),
    total: (j['total'] as num?)?.toInt() ?? 0,
    page: (j['page'] as num?)?.toInt() ?? 0,
    limit: (j['limit'] as num?)?.toInt() ?? 30,
  );
}

// ── Repository ─────────────────────────────────────────────────────────

class AdminRepository {
  static Future<String?> getStoredKey() => _secure.read(key: _adminKeyStore);
  static Future<void> saveKey(String key) => _secure.write(key: _adminKeyStore, value: key);
  static Future<void> clearKey() => _secure.delete(key: _adminKeyStore);

  static Future<Map<String, dynamic>> _call(String action, Map<String, dynamic> params) async {
    final adminKey = await getStoredKey();
    if (adminKey == null) throw Exception('Not authenticated');
    final uri = Uri.parse(_edgeUrl);
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('apikey', _anonKey);
      req.headers.set('Authorization', 'Bearer $_anonKey');
      req.headers.set('x-admin-key', adminKey);
      req.write(jsonEncode({...params, 'action': action}));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (res.statusCode >= 400) throw Exception(data['error'] as String? ?? 'HTTP ${res.statusCode}');
      return data;
    } finally {
      client.close();
    }
  }

  static Future<bool> verifyAdminKey(String key) async {
    final uri = Uri.parse(_edgeUrl);
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('apikey', _anonKey);
      req.headers.set('Authorization', 'Bearer $_anonKey');
      req.headers.set('x-admin-key', key);
      req.write(jsonEncode({'action': 'stats'}));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  static Future<LicenseStats> getStats() async {
    final data = await _call('stats', {});
    return LicenseStats.fromJson(data['stats'] as Map<String, dynamic>);
  }

  static Future<LicenseListResponse> listLicenses({int page = 0, int limit = 30, String? status, String? search}) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _call('list', params);
    return LicenseListResponse.fromJson(data);
  }

  static Future<LicenseDetail> getLicenseDetail(String licenseId) async {
    final data = await _call('detail', {'license_id': licenseId});
    return LicenseDetail.fromJson(data['license'] as Map<String, dynamic>);
  }

  static Future<({bool ok, int count, List<String> keys, bool isTrial, String? expiresAt, bool emailSent, String? emailError})> generateKeys({
    int count = 1, String? ownerEmail, String? buyerName, bool sendEmail = false, bool isTrial = false,
  }) async {
    final data = await _call('generate', {
      'count': count, 'owner_email': ownerEmail ?? '', 'buyer_name': buyerName ?? '',
      'send_email': sendEmail, 'is_trial': isTrial,
    });
    return (
      ok: data['ok'] == true,
      count: (data['count'] as num).toInt(),
      keys: (data['keys'] as List<dynamic>).cast<String>(),
      isTrial: data['is_trial'] == true,
      expiresAt: data['expires_at'] as String?,
      emailSent: data['email_sent'] == true,
      emailError: data['email_error'] as String?,
    );
  }

  static Future<Map<String, dynamic>> addKey({required String key, required String serial, String? ownerEmail}) async {
    return _call('add', {'key': key, 'serial': serial, 'owner_email': ownerEmail ?? ''});
  }

  static Future<Map<String, dynamic>> revokeLicense(String licenseId) async {
    return _call('revoke', {'license_id': licenseId});
  }

  static Future<Map<String, dynamic>> deleteLicense(String licenseId) async {
    return _call('delete', {'license_id': licenseId});
  }
}
