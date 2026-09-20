import 'package:equatable/equatable.dart';

/// Type of a Telegram chat/group.
enum ChatType { basicGroup, supergroup, channel, forum }

/// Sent status of a message.
enum SentStatus { pending, sent, failed, floodWait, retrying }

/// Result of an authentication operation.
sealed class AuthResult extends Equatable {
  const AuthResult();

  @override
  List<Object?> get props => [];
}

class AuthSuccess extends AuthResult {
  final String phoneCodeHash;
  final String? type;
  const AuthSuccess(this.phoneCodeHash, {this.type});

  @override
  List<Object?> get props => [phoneCodeHash, type];
}

class AuthPasswordRequired extends AuthResult {
  final String hint;
  const AuthPasswordRequired(this.hint);

  @override
  List<Object?> get props => [hint];
}

class AuthError extends AuthResult {
  final String message;
  final int? errorCode;
  const AuthError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Result of a sign-in operation.
sealed class SignInResult extends Equatable {
  const SignInResult();

  @override
  List<Object?> get props => [];
}

class SignInSuccess extends SignInResult {
  final int userId;
  final String firstName;
  const SignInSuccess(this.userId, this.firstName);

  @override
  List<Object?> get props => [userId, firstName];
}

class SignInPasswordRequired extends SignInResult {
  final String hint;
  const SignInPasswordRequired(this.hint);

  @override
  List<Object?> get props => [hint];
}

class SignInError extends SignInResult {
  final String message;
  const SignInError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Telegram group/channel model.
class TelegramGroup extends Equatable {
  final int id;
  final String title;
  final String? username;
  final int memberCount;
  final bool isFavorite;
  final bool isEnabled;
  final DateTime? nextSendTime;
  final int order;
  final ChatType type;
  final int accessHash;

  const TelegramGroup({
    required this.id,
    required this.title,
    this.username,
    this.memberCount = 0,
    this.isFavorite = false,
    this.isEnabled = true,
    this.nextSendTime,
    this.order = 0,
    this.type = ChatType.channel,
    this.accessHash = 0,
  });

  TelegramGroup copyWith({
    int? id,
    String? title,
    String? username,
    int? memberCount,
    bool? isFavorite,
    bool? isEnabled,
    DateTime? nextSendTime,
    int? order,
    ChatType? type,
    int? accessHash,
  }) {
    return TelegramGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      memberCount: memberCount ?? this.memberCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isEnabled: isEnabled ?? this.isEnabled,
      nextSendTime: nextSendTime ?? this.nextSendTime,
      order: order ?? this.order,
      type: type ?? this.type,
      accessHash: accessHash ?? this.accessHash,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'username': username,
        'memberCount': memberCount,
        'isFavorite': isFavorite,
        'isEnabled': isEnabled,
        'nextSendTime': nextSendTime?.toIso8601String(),
        'order': order,
        'type': type.index,
        'accessHash': accessHash,
      };

  factory TelegramGroup.fromJson(Map<String, dynamic> json) {
    try {
      return TelegramGroup(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        username: json['username'] as String?,
        memberCount: json['memberCount'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isEnabled: json['isEnabled'] as bool? ?? true,
        nextSendTime: json['nextSendTime'] != null
            ? DateTime.parse(json['nextSendTime'] as String)
            : null,
        order: json['order'] as int? ?? 0,
        type: ChatType.values[
            (json['type'] as int?) ?? ChatType.channel.index],
        accessHash: json['accessHash'] as int? ?? 0,
      );
    } catch (_) {
      return const TelegramGroup(id: 0, title: 'Invalid group');
    }
  }

  @override
  List<Object?> get props =>
      [id, title, username, memberCount, isFavorite, isEnabled, nextSendTime, order];
}

/// Ad template model.
class AdTemplate extends Equatable {
  final String id;
  final String name;
  final String text;
  final String? photoUrl;
  final String? documentUrl;
  final String? videoUrl;
  final String? title;
  final bool isSmart;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdTemplate({
    required this.id,
    required this.name,
    required this.text,
    this.photoUrl,
    this.documentUrl,
    this.videoUrl,
    this.title,
    this.isSmart = true,
    required this.createdAt,
    required this.updatedAt,
  });

  AdTemplate copyWith({
    String? id,
    String? name,
    String? text,
    String? photoUrl,
    String? documentUrl,
    String? videoUrl,
    String? title,
    bool? isSmart,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      text: text ?? this.text,
      photoUrl: photoUrl ?? this.photoUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      isSmart: isSmart ?? this.isSmart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'text': text,
        'photoUrl': photoUrl,
        'documentUrl': documentUrl,
        'videoUrl': videoUrl,
        'title': title,
        'isSmart': isSmart,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AdTemplate.fromJson(Map<String, dynamic> json) {
    try {
      return AdTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        text: json['text'] as String,
        photoUrl: json['photoUrl'] as String?,
        documentUrl: json['documentUrl'] as String?,
        videoUrl: json['videoUrl'] as String?,
        title: json['title'] as String?,
        isSmart: json['isSmart'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
    } catch (_) {
      return AdTemplate(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'Invalid template',
        text: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  List<Object?> get props => [id, name, text, isSmart];
}

/// A log entry for sent messages tracking.
class SendLog extends Equatable {
  final String id;
  final int chatId;
  final String chatName;
  final String templateId;
  final String? messageText;
  final DateTime sentTime;
  final SentStatus status;
  final String? errorMessage;
  final int? floodWaitSeconds;

  const SendLog({
    required this.id,
    required this.chatId,
    required this.chatName,
    required this.templateId,
    this.messageText,
    required this.sentTime,
    required this.status,
    this.errorMessage,
    this.floodWaitSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'chatName': chatName,
        'templateId': templateId,
        'messageText': messageText,
        'sentTime': sentTime.toIso8601String(),
        'status': status.index,
        'errorMessage': errorMessage,
        'floodWaitSeconds': floodWaitSeconds,
      };

  factory SendLog.fromJson(Map<String, dynamic> json) {
    try {
      return SendLog(
        id: json['id'] as String,
        chatId: json['chatId'] as int,
        chatName: json['chatName'] as String,
        templateId: json['templateId'] as String,
        messageText: json['messageText'] as String?,
        sentTime: DateTime.parse(json['sentTime'] as String),
        status: SentStatus.values[json['status'] as int],
        errorMessage: json['errorMessage'] as String?,
        floodWaitSeconds: json['floodWaitSeconds'] as int?,
      );
    } catch (_) {
      return SendLog(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        chatId: 0,
        chatName: 'Invalid log',
        templateId: '',
        sentTime: DateTime.now(),
        status: SentStatus.failed,
        errorMessage: 'Corrupted log entry',
      );
    }
  }

  @override
  List<Object?> get props => [id, chatId, sentTime, status];
}

/// Statistics summary for a given period.
class StatsSummary extends Equatable {
  final int totalSent;
  final int totalErrors;
  final int floodWaitCount;
  final int successfulSends;

  const StatsSummary({
    this.totalSent = 0,
    this.totalErrors = 0,
    this.floodWaitCount = 0,
    this.successfulSends = 0,
  });

  double get successRate =>
      totalSent > 0 ? (successfulSends / totalSent) * 100 : 0;

  @override
  List<Object?> get props => [totalSent, totalErrors, floodWaitCount, successfulSends];
}
