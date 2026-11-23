import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

/// Relations offered when linking someone; the server accepts only these.
const familyLinkRelations = ['Spouse', 'Child', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other'];

/// The user's own 4-digit family code and how long it still works.
class FamilyCodeInfo {
  final String code;
  final int validitySeconds;

  /// Seconds the code still worked when the server sent it. Counting down from
  /// this (not from a time of day) keeps a wrong phone clock from mattering.
  final int secondsLeft;

  const FamilyCodeInfo({required this.code, required this.secondsLeft, this.validitySeconds = 600});

  factory FamilyCodeInfo.fromJson(Map<String, dynamic> json) => FamilyCodeInfo(
        code: (json['code'] ?? '').toString(),
        secondsLeft: int.tryParse('${json['secondsLeft'] ?? 0}') ?? 0,
        validitySeconds: int.tryParse('${json['validitySeconds'] ?? 600}') ?? 600,
      );
}

/// What a phone number lookup may show: found or not, and a masked name.
class FamilyLookupResult {
  final bool found;
  final String maskedName;
  final bool alreadyLinked;
  final bool requestSent;
  final bool requestReceived;

  const FamilyLookupResult({
    required this.found,
    this.maskedName = '',
    this.alreadyLinked = false,
    this.requestSent = false,
    this.requestReceived = false,
  });

  factory FamilyLookupResult.fromJson(Map<String, dynamic> json) => FamilyLookupResult(
        found: json['found'] == true,
        maskedName: (json['maskedName'] ?? '').toString(),
        alreadyLinked: json['alreadyLinked'] == true,
        requestSent: json['requestSent'] == true,
        requestReceived: json['requestReceived'] == true,
      );
}

/// A person with their own Yira account who is linked to this family.
class FamilyLinkedMember {
  final String userId;
  final int linkId;
  final String name;
  final String firstName;
  final String lastName;
  final String relation;
  final String? gender;
  final String? dob;
  final String? phoneNumber;
  final String? imagePath;

  const FamilyLinkedMember({
    required this.userId,
    required this.linkId,
    required this.name,
    this.firstName = '',
    this.lastName = '',
    this.relation = 'Family',
    this.gender,
    this.dob,
    this.phoneNumber,
    this.imagePath,
  });

  factory FamilyLinkedMember.fromJson(Map<String, dynamic> json) => FamilyLinkedMember(
        userId: (json['userId'] ?? json['id'] ?? '').toString(),
        linkId: int.tryParse('${json['linkId']}') ?? 0,
        name: (json['name'] ?? '').toString(),
        firstName: (json['firstName'] ?? '').toString(),
        lastName: (json['lastName'] ?? '').toString(),
        relation: (json['relation'] ?? 'Family').toString(),
        gender: json['gender']?.toString(),
        dob: json['dob']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        imagePath: json['imagePath']?.toString(),
      );
}

/// Dependents and linked accounts, with the family-size limit.
class FamilyMembersInfo {
  final List<FamilyLinkedMember> linked;
  final int limit;
  final int used;
  final int remaining;

  const FamilyMembersInfo({this.linked = const [], this.limit = 6, this.used = 0, this.remaining = 6});

  factory FamilyMembersInfo.fromJson(Map<String, dynamic> json) {
    final members = json['members'] is List ? json['members'] as List : const [];
    return FamilyMembersInfo(
      linked: [
        for (final m in members.whereType<Map>())
          if ((m['type'] ?? '').toString().toUpperCase() == 'LINKED') FamilyLinkedMember.fromJson(Map<String, dynamic>.from(m)),
      ],
      limit: int.tryParse('${json['limit'] ?? 6}') ?? 6,
      used: int.tryParse('${json['used'] ?? 0}') ?? 0,
      remaining: int.tryParse('${json['remaining'] ?? 0}') ?? 0,
    );
  }
}

/// A link request: [incoming] when someone asked to add this user.
class FamilyLinkRequest {
  final int id;
  final bool incoming;

  /// The sender's name (incoming) or the masked name of the person asked (outgoing).
  final String name;
  final String phoneHint;

  /// Incoming: how the sender describes this user. Outgoing: how this user described them.
  final String relation;

  /// Incoming only: how the sender will appear in this user's family.
  final String suggestedRelation;
  final DateTime? expiresAt;

  const FamilyLinkRequest({
    required this.id,
    required this.incoming,
    required this.name,
    this.phoneHint = '',
    this.relation = '',
    this.suggestedRelation = '',
    this.expiresAt,
  });

  factory FamilyLinkRequest.fromJson(Map<String, dynamic> json, {required bool incoming}) => FamilyLinkRequest(
        id: int.tryParse('${json['id']}') ?? 0,
        incoming: incoming,
        name: (incoming ? json['name'] : json['maskedName'] ?? json['name'] ?? '').toString(),
        phoneHint: (json['phoneHint'] ?? '').toString(),
        relation: (json['relation'] ?? '').toString(),
        suggestedRelation: (json['suggestedRelation'] ?? '').toString(),
        expiresAt: json['expiresAt'] == null ? null : DateTime.tryParse(json['expiresAt'].toString())?.toLocal(),
      );
}

class FamilyLinkRequests {
  final List<FamilyLinkRequest> incoming;
  final List<FamilyLinkRequest> outgoing;

  const FamilyLinkRequests({this.incoming = const [], this.outgoing = const []});

  bool get isEmpty => incoming.isEmpty && outgoing.isEmpty;
}

/// The result of linking or sending a request.
class FamilyLinkOutcome {
  /// True when the person is now in the family; false when a request was sent.
  final bool linked;
  final String message;
  final FamilyLinkedMember? member;

  const FamilyLinkOutcome({required this.linked, required this.message, this.member});
}

/// A family-link failure the user can act on, with the server's code.
class FamilyLinkException implements Exception {
  final String code;
  final String message;

  const FamilyLinkException(this.code, this.message);

  @override
  String toString() => message;
}

const _friendlyByCode = {
  'INVALID_PHONE': 'Enter a 10-digit mobile number.',
  'NOT_FOUND': 'No Yira account uses this number.',
  'CANNOT_LINK_SELF': "That's your own number. Enter the number of the person you want to link.",
  'WRONG_CODE': "That code doesn't match. Check the 4 digits in their app and try again.",
  'CODE_EXPIRED': 'This code has expired. Ask them to open My Family and share the new code.',
  'INVALID_CODE': 'Enter the 4-digit family code shown in their app.',
  'INVALID_RELATION': 'Choose how they are related to you.',
  'ALREADY_LINKED': 'They are already in your family.',
  'FAMILY_LIMIT_REACHED': 'Your family is full. Remove someone first to link a new person.',
  'TARGET_FAMILY_FULL': "Their family is full, so they can't be linked right now.",
  'TOO_MANY_CODE_TRIES': 'Too many wrong codes. Please wait a few minutes, or send a request instead.',
  'TARGET_CODE_LOCKED': 'Too many wrong codes were tried for this number. Please wait, or send a request instead.',
  'TOO_MANY_LOOKUPS': "You've looked up a lot of numbers. Please try again in a few minutes.",
  'REQUEST_ALREADY_SENT': "You've already sent them a request.",
  'REQUEST_EXPIRED': 'This request has expired.',
  'REQUEST_CLOSED': 'This request has already been answered.',
  'SWITCH_TO_OWN_PROFILE': 'Switch back to your own profile to manage family links.',
  'SIGN_IN_REQUIRED': 'Please sign in again to manage your family.',
};

/// Turns any failure into one sentence for the user.
FamilyLinkException familyLinkError(Object error, [String fallback = 'Something went wrong. Please try again.']) {
  if (error is FamilyLinkException) return error;
  if (error is DioException) {
    final body = error.response?.data;
    String code = '';
    String? message;
    if (body is Map) {
      final data = body['data'];
      if (data is Map && data['code'] != null) code = data['code'].toString();
      final m = body['message'];
      if (m is String && m.trim().isNotEmpty) message = m.trim();
    }
    if (message != null) return FamilyLinkException(code, message);
    if (_friendlyByCode.containsKey(code)) return FamilyLinkException(code, _friendlyByCode[code]!);
    if (error.response?.statusCode == 404) {
      return const FamilyLinkException('NOT_AVAILABLE', 'This needs the latest Yira server. Please try again later.');
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const FamilyLinkException('OFFLINE', 'No internet connection. Check your connection and try again.');
    }
  }
  return FamilyLinkException('UNKNOWN', fallback);
}

/// The 10-digit number in [raw] (spaces, +91 and a leading 0 are allowed), or null.
String? normalizeFamilyPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) digits = digits.substring(2);
  if (digits.length == 11 && digits.startsWith('0')) digits = digits.substring(1);
  return RegExp(r'^\d{10}$').hasMatch(digits) ? digits : null;
}

/// Null when [raw] is a usable mobile number, otherwise what to fix.
String? validateFamilyPhone(String raw) {
  if (raw.trim().isEmpty) return 'Enter their mobile number.';
  return normalizeFamilyPhone(raw) == null ? 'Enter a 10-digit mobile number.' : null;
}

/// Null when [raw] is four digits, otherwise what to fix.
String? validateFamilyCode(String raw) {
  final code = raw.trim();
  if (code.isEmpty) return 'Enter their 4-digit family code.';
  return RegExp(r'^\d{4}$').hasMatch(code) ? null : 'The family code has 4 digits.';
}

/// Calls for family codes, links and requests. Always acts for the signed-in
/// account holder (no profile header is sent).
class FamilyLinkApi {
  Dio get _dio => sl<ApiClient>().account(showSuccessSnack: false);

  Options get _options {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
    return Options(
      headers: {if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token'},
      // These screens show their own messages.
      extra: {'suppressErrorSnack': true},
    );
  }

  Map<String, dynamic> _data(Response res) {
    final body = res.data;
    final data = body is Map ? body['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<T> _call<T>(Future<T> Function() run, String fallback) async {
    try {
      return await run();
    } catch (e) {
      throw familyLinkError(e, fallback);
    }
  }

  Future<FamilyCodeInfo> getCode() => _call(
        () async => FamilyCodeInfo.fromJson(_data(await _dio.get(URLs.familyCodeUrl, options: _options))),
        'Could not load your family code.',
      );

  Future<FamilyCodeInfo> refreshCode() => _call(
        () async => FamilyCodeInfo.fromJson(_data(await _dio.post(URLs.familyCodeRefreshUrl, options: _options))),
        'Could not make a new code.',
      );

  Future<FamilyLookupResult> lookup(String phone) => _call(
        () async => FamilyLookupResult.fromJson(
          _data(await _dio.post(URLs.familyLookupUrl, data: {'phone': phone}, options: _options)),
        ),
        'Could not look up this number.',
      );

  Future<FamilyLinkOutcome> linkWithCode({required String phone, required String code, required String relation}) => _call(
        () async {
          final data = _data(await _dio.post(
            URLs.familyLinkWithCodeUrl,
            data: {'phone': phone, 'familyCode': code, 'relation': relation},
            options: _options,
          ));
          final member = data['member'] is Map ? FamilyLinkedMember.fromJson(Map<String, dynamic>.from(data['member'] as Map)) : null;
          final name = member?.name.trim() ?? '';
          return FamilyLinkOutcome(
            linked: true,
            member: member,
            message: name.isNotEmpty ? '$name is now in your family.' : 'They are now in your family.',
          );
        },
        'Could not link this person.',
      );

  Future<FamilyLinkOutcome> sendRequest({required String phone, required String relation}) => _call(
        () async {
          final data = _data(await _dio.post(
            URLs.familyRequestsUrl,
            data: {'phone': phone, 'relation': relation},
            options: _options,
          ));
          if ((data['status'] ?? '').toString().toUpperCase() == 'ACCEPTED') {
            final member = data['member'] is Map ? FamilyLinkedMember.fromJson(Map<String, dynamic>.from(data['member'] as Map)) : null;
            return FamilyLinkOutcome(linked: true, member: member, message: 'You are now linked.');
          }
          return const FamilyLinkOutcome(
            linked: false,
            message: 'Request sent. They can accept it in My Family within 7 days.',
          );
        },
        'Could not send the request.',
      );

  Future<FamilyLinkRequests> getRequests() => _call(
        () async {
          final data = _data(await _dio.get(URLs.familyRequestsUrl, options: _options));
          List<FamilyLinkRequest> parse(dynamic list, bool incoming) => list is List
              ? [for (final r in list.whereType<Map>()) FamilyLinkRequest.fromJson(Map<String, dynamic>.from(r), incoming: incoming)]
              : const [];
          return FamilyLinkRequests(incoming: parse(data['incoming'], true), outgoing: parse(data['outgoing'], false));
        },
        'Could not load family requests.',
      );

  Future<FamilyLinkedMember?> acceptRequest(int id, {String? relation}) => _call(
        () async {
          final data = _data(await _dio.post(
            '${URLs.familyRequestsUrl}/$id/accept',
            data: {'relation': ?relation},
            options: _options,
          ));
          return data['member'] is Map ? FamilyLinkedMember.fromJson(Map<String, dynamic>.from(data['member'] as Map)) : null;
        },
        'Could not accept the request.',
      );

  Future<void> declineRequest(int id) => _call(
        () async => _dio.post('${URLs.familyRequestsUrl}/$id/decline', options: _options),
        'Could not decline the request.',
      );

  Future<void> cancelRequest(int id) => _call(
        () async => _dio.post('${URLs.familyRequestsUrl}/$id/cancel', options: _options),
        'Could not cancel the request.',
      );

  Future<FamilyMembersInfo> getMembers() => _call(
        () async => FamilyMembersInfo.fromJson(_data(await _dio.get(URLs.familyMembersUrl, options: _options))),
        'Could not load your family.',
      );

  Future<void> removeLink(int linkId) => _call(
        () async => _dio.post('${URLs.familyLinksUrl}/$linkId/remove', options: _options),
        'Could not remove this person.',
      );
}
