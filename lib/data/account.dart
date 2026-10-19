import 'dart:convert';
import '../core/otpauth_uri.dart';
import '../core/totp.dart';

/// An enrolled account. Immutable value object — persistence and code
/// generation live elsewhere so this stays trivially testable.
class Account {
  const Account({
    required this.id,
    required this.issuer,
    required this.account,
    required this.secretBase32,
    this.digits = 6,
    this.period = 30,
    this.algorithm = OtpAlgorithm.sha1,
  });

  final String id;
  final String issuer;
  final String account;
  final String secretBase32;
  final int digits;
  final int period;
  final OtpAlgorithm algorithm;

  /// Display initial for the avatar chip (Google Authenticator shows the
  /// issuer's first letter).
  String get initial {
    final label = issuer.isNotEmpty ? issuer : account;
    return label.isEmpty ? '?' : label.substring(0, 1).toUpperCase();
  }

  /// Builds an account with a freshly generated id. Shared by QR and manual
  /// enrollment so the id scheme lives in one place.
  factory Account.create({
    required String issuer,
    required String account,
    required String secretBase32,
    int digits = 6,
    int period = 30,
    OtpAlgorithm algorithm = OtpAlgorithm.sha1,
  }) =>
      Account(
        id: '$issuer:$account:${DateTime.now().microsecondsSinceEpoch}',
        issuer: issuer,
        account: account,
        secretBase32: secretBase32,
        digits: digits,
        period: period,
        algorithm: algorithm,
      );

  Account copyWith({String? issuer, String? account}) => Account(
        id: id,
        issuer: issuer ?? this.issuer,
        account: account ?? this.account,
        secretBase32: secretBase32,
        digits: digits,
        period: period,
        algorithm: algorithm,
      );

  factory Account.fromOtpauth(OtpauthData data) => Account.create(
        issuer: data.issuer,
        account: data.account,
        secretBase32: data.secretBase32,
        digits: data.digits,
        period: data.period,
        algorithm: data.algorithm,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'issuer': issuer,
        'account': account,
        'secret': secretBase32,
        'digits': digits,
        'period': period,
        'algorithm': algorithm.name,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        issuer: json['issuer'] as String? ?? '',
        account: json['account'] as String? ?? '',
        secretBase32: json['secret'] as String,
        digits: json['digits'] as int? ?? 6,
        period: json['period'] as int? ?? 30,
        algorithm: OtpAlgorithm.values.firstWhere(
          (a) => a.name == json['algorithm'],
          orElse: () => OtpAlgorithm.sha1,
        ),
      );
}

String encodeAccounts(List<Account> accounts) =>
    jsonEncode(accounts.map((a) => a.toJson()).toList());

List<Account> decodeAccounts(String raw) =>
    (jsonDecode(raw) as List<dynamic>)
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
