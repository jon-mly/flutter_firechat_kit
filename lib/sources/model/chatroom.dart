part of firechat_kit;

enum FirechatChatroomType { group, oneToOne }

class FirechatChatroom {
  /// The title of the [FirechatChatroom].
  String title;

  /// The type of the [FirechatChatroom].
  FirechatChatroomType chatroomType;

  /// The list of [FirechatUser] references for the participants.
  List<DocumentReference> peopleRef;

  /// The list of [FirechatUser] who are currently composing in this chatroom.
  List<DocumentReference> composingPeopleRef;

  /// The list of [FirechatUser] who are currently active in the the chatroom.
  List<DocumentReference> focusingPeopleRef;

  /// The [DocumentReference] of this instance.
  DocumentReference selfReference;

  /// The [DateTime] of the last message sent.
  DateTime lastMessageDate;

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
      this.peopleRef,
      this.composingPeopleRef,
      this.focusingPeopleRef,
      this.isLocal: false,
      this.lastMessageDate});

  FirechatChatroom.fromMap(
      Map<String, dynamic> map, DocumentReference selfReference) {
    this.selfReference = selfReference;
    this.title = map["title"];
    if (map["chatroomTypeIndex"] != null)
      this.chatroomType = FirechatChatroomType.values[map["chatroomTypeIndex"]];
    this.peopleRef = map["peopleRef"]?.cast<DocumentReference>() ?? null;
    this.composingPeopleRef =
        map["composingPeopleRef"]?.cast<DocumentReference>() ?? null;
    this.focusingPeopleRef =
        map["focusingPeopleRef"]?.cast<DocumentReference>() ?? null;
    this.lastMessageDate =
        DateTime.fromMillisecondsSinceEpoch(map["lastMessageDate"]);
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
      "composingPeopleRef": this.composingPeopleRef,
      "focusingPeopleRef": this.focusingPeopleRef,
      "lastMessageDate": this.lastMessageDate
    };
    return map;
  }
}
