part of firechat_kit;

enum FirechatMessageAssetType { image, gif, video, audio }

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
    this.authorRef = map["authorRef"];
    this.content = map["content"];
    this.chatroomRef = map["chatroomRef"];
    this.assetUrl = map["assetUrl"];
    if (map["assetType"] != null)
      this.assetType = FirechatMessageAssetType.values[map["assetType"]];
    if (map["dateTimestamp"] != null)
      this.date = DateTime.fromMillisecondsSinceEpoch(map["dateTimestamp"]);
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "authorRef": this.authorRef,
      "dateTimestamp":
          (this.date != null) ? this.date.millisecondsSinceEpoch : null,
      "chatroomRef": this.chatroomRef,
      "content": this.content,
      "assetUrl": this.assetUrl,
      "assetType": (this.assetType != null)
          ? FirechatMessageAssetType.values.indexOf(assetType)
          : null
    };
    return map;
  }
}
