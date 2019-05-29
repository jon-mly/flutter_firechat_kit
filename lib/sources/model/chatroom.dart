part of firechat_kit;

enum FirechatChatroomType { group, oneToOne }

class FirechatChatroomKeys {
  static final String kTitle = "title";
  static final String kChatroomTypeIndex = "chatroomTypeIndex";
  static final String kPeopleRef = "peopleRef";
  static final String kComposingPeopleRef = "composingPeopleRef";
  static final String kFocusingPeopleRef = "focusingPeopleRef";
  static final String kLastMessageDate = "lastMessageDate";
  static final String kLastMessagesRead = "lastMessagesRead";
  static final String kReadByPrefix = "readBy_";
}

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

  /// The [Map] for the [DocumentReference] of the last [FirechatMessage] read
  /// by each of the [FirechatUser], identified by the [DocumentReference]
  /// of their related document in Firestore.
  Map<DocumentReference, DocumentReference> lastMessagesRead;

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
      this.lastMessageDate,
      this.lastMessagesRead});

  FirechatChatroom.fromMap(
      Map<String, dynamic> map, DocumentReference selfReference) {
    this.selfReference = selfReference;
    this.title = map[FirechatChatroomKeys.kTitle];
    if (map[FirechatChatroomKeys.kChatroomTypeIndex] != null)
      this.chatroomType = FirechatChatroomType
          .values[map[FirechatChatroomKeys.kChatroomTypeIndex]];
    this.peopleRef =
        map[FirechatChatroomKeys.kPeopleRef]?.cast<DocumentReference>() ?? null;
    this.composingPeopleRef = map[FirechatChatroomKeys.kComposingPeopleRef]
            ?.cast<DocumentReference>() ??
        null;
    this.focusingPeopleRef = map[FirechatChatroomKeys.kFocusingPeopleRef]
            ?.cast<DocumentReference>() ??
        null;
    this.lastMessageDate = DateTime.fromMillisecondsSinceEpoch(
        map[FirechatChatroomKeys.kLastMessageDate]);
    this.isLocal = false;

//    Map<String, DocumentReference> lastMessagesPerUser =
//        Map<String, DocumentReference>.from(
//            map[FirechatChatroomKeys.kLastMessagesRead] ?? {});
//    if (lastMessagesPerUser != null) {
//      this.lastMessagesRead = lastMessagesPerUser
//          .map((String userDocRefStr, DocumentReference messageRef) {
//        return MapEntry(Firestore.instance.document(userDocRefStr), messageRef);
//      });

    Map<String, DocumentReference> readByMap = {};
    map.forEach((String key, dynamic content) {
      if (key.startsWith(FirechatChatroomKeys.kReadByPrefix)) {
        readByMap[key] = content;
      }
    });
    lastMessagesRead = {};
    readByMap.forEach((String key, DocumentReference messageRef) {
      DocumentReference userRef = Firestore.instance.document(
          "/users/" + key.replaceFirst(FirechatChatroomKeys.kReadByPrefix, ""));
      lastMessagesRead[userRef] = messageRef;
    });
  }

  Map<String, dynamic> toMap() {
    int chatroomTypeIndex = (this.chatroomType != null)
        ? FirechatChatroomType.values.indexOf(this.chatroomType)
        : null;
    Map<String, dynamic> map = {
      FirechatChatroomKeys.kTitle: this.title,
      FirechatChatroomKeys.kChatroomTypeIndex: chatroomTypeIndex,
      FirechatChatroomKeys.kPeopleRef: this.peopleRef,
      FirechatChatroomKeys.kComposingPeopleRef: this.composingPeopleRef,
      FirechatChatroomKeys.kFocusingPeopleRef: this.focusingPeopleRef,
      FirechatChatroomKeys.kLastMessageDate:
          this.lastMessageDate.millisecondsSinceEpoch,
//      FirechatChatroomKeys.kLastMessagesRead: this.lastMessagesRead.map(
//          (DocumentReference userRef, DocumentReference messageRef) =>
//              MapEntry(userRef.path, messageRef))
    };

    Map<String, DocumentReference> readByMap = lastMessagesRead
        .map((DocumentReference userRef, DocumentReference messageRef) {
      return entryReadBy(userRef: userRef, messageRef: messageRef)
          .entries
          .first;
    });
    map.addAll(readByMap);

    return map;
  }

  Map<String, DocumentReference> entryReadBy(
      {@required DocumentReference userRef, @required messageRef}) {
    return {_readByTag(userRef): messageRef};
  }

  String _readByTag(DocumentReference userRef) {
    return FirechatChatroomKeys.kReadByPrefix + userRef.documentID;
  }
}
