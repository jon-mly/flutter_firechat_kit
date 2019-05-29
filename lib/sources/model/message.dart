part of firechat_kit;

enum FirechatMessageAssetType { image, gif, video, audio }

class FirechatMessageKeys {
  static final String kAuthorRef = "authorRef";
  static final String kDate = "dateTimestamp";
  static final String kContent = "content";
  static final String kAssetUrl = "assetUrl";
  static final String kAssetType = "assetType";
  static final String kChatroomRef = "chatroomRef";
}

/// A message sent by a user.
class FirechatMessage {
  /// Firestore [DocumentReference] of the [FirechatUser] author of the message.
  DocumentReference authorRef;

  /// The date when the [FirechatMessage] has been sent.
  ///
  /// Is expected to be converted from millisecondes since Epoch, as stocked
  /// in the server.
  DateTime date;

  /// The text content of the message.
  String content;

  /// The download URL of the asset linked to this [FirechatMessage].
  String assetUrl;

  /// The type of the asset linked to this [FirechatMessage].
  FirechatMessageAssetType assetType;

  /// The server [DocumentReference] of the [FirechatChatroom] where the [FirechatMessage] has
  /// been sent.
  DocumentReference chatroomRef;

  /// The [DocumentReference] of this instance.
  DocumentReference selfReference;

  FirechatMessage(
      {this.authorRef,
      this.date,
      this.chatroomRef,
      this.content,
      this.selfReference,
      this.assetType,
      this.assetUrl});

  FirechatMessage.fromMap(
      Map<String, dynamic> map, DocumentReference selfReference) {
    this.selfReference = selfReference;
    this.authorRef = map[FirechatMessageKeys.kAuthorRef];
    this.content = map[FirechatMessageKeys.kContent];
    this.chatroomRef = map[FirechatMessageKeys.kChatroomRef];
    this.assetUrl = map[FirechatMessageKeys.kAssetUrl];
    if (map[FirechatMessageKeys.kAssetType] != null)
      this.assetType =
          FirechatMessageAssetType.values[map[FirechatMessageKeys.kAssetType]];
    if (map[FirechatMessageKeys.kDate] != null)
      this.date =
          DateTime.fromMillisecondsSinceEpoch(map[FirechatMessageKeys.kDate]);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      FirechatMessageKeys.kAuthorRef: this.authorRef,
      FirechatMessageKeys.kDate:
          (this.date != null) ? this.date.millisecondsSinceEpoch : null,
      FirechatMessageKeys.kChatroomRef: this.chatroomRef,
      FirechatMessageKeys.kContent: this.content,
      FirechatMessageKeys.kAssetUrl: this.assetUrl,
      FirechatMessageKeys.kAssetType: (this.assetType != null)
          ? FirechatMessageAssetType.values.indexOf(assetType)
          : null
    };
    return map;
  }
}
