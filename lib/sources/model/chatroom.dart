part of firechat_kit;

enum FirechatChatroomType { group, oneToOne }

class FirechatChatroom {
  /// The title of the [FirechatChatroom].
  String title;

  /// The type of the [FirechatChatroom].
  FirechatChatroomType chatroomType;

  /// The list of [User] references for the participants.
  List<DocumentReference> peopleRef;

//  /// The references list of the [FirechatMessage] sent in the room.
//  List<DocumentReference> messagesRef;

  /// The [DocumentReference] of this instance.
  DocumentReference selfReference;

  /// Indicates if the [FirechatChatroom] is not yet exported to the database.
  /// Is false by default.
  ///
  /// This is used mainly when a user gets to a database but the first
  /// message is not sent yet.
  bool isLocal;

  FirechatChatroom(
      {this.selfReference,
      this.chatroomType,
      this.title,
//      this.messagesRef,
      this.peopleRef,
      this.isLocal: false});

  FirechatChatroom.fromMap(
      Map<String, dynamic> map, DocumentReference selfReference) {
    this.selfReference = selfReference;
    this.title = map["title"];
    if (map["chatroomTypeIndex"] != null)
      this.chatroomType = FirechatChatroomType.values[map["chatroomTypeIndex"]];
    this.peopleRef = map["peopleRef"]?.cast<DocumentReference>() ?? null;
//    this.messagesRef = map["messagesRef"]?.cast<DocumentReference>() ?? null;
//     Messages are ordered from the older to the newer.
//    this.messagesRef = messagesRef.reversed.toList();
    this.isLocal = false;
  }

  Map<String, dynamic> toMap() {
    int chatroomTypeIndex = (this.chatroomType != null)
        ? FirechatChatroomType.values.indexOf(this.chatroomType)
        : null;
    Map<String, dynamic> map = {
      "title": this.title,
      "chatroomTypeIndex": chatroomTypeIndex,
      "peopleRef": this.peopleRef,
//      "messagesRef": this.messagesRef
    };
    return map;
  }
}
