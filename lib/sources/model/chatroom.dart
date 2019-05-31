part of firechat_kit;

enum FirechatChatroomType { group, oneToOne }

class FirechatChatroomKeys {
  static final String kTitle = "title";
  static final String kChatroomTypeIndex = "chatroomTypeIndex";
  static final String kPeopleRef = "peopleRef";
  static final String kComposingPeopleRef = "composingPeopleRef";
  static final String kFocusingPeopleRef = "focusingPeopleRef";
  static final String kLastMessageDate = "lastMessageDate";
  static final String kLastMessageRef = "lastMessageRef";
  static final String kLastMessagesRead = "lastMessagesRead";
  static final String kReadByPrefix = "readBy_";
  static final String kDetails = "details";
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

  /// The [DocumentReference] of the last message sent.
  DocumentReference lastMessageRef;

  /// The [Map] for the [DocumentReference] of the last [FirechatMessage] read
  /// by each of the [FirechatUser], identified by the [DocumentReference]
  /// of their related document in Firestore.
  ///
  /// Keys : users references
  /// Values : messages references
  Map<DocumentReference, DocumentReference> lastMessagesRead;

  /// [Map] for custom details than can de added to the [FirechatChatroom].
  ///
  /// These optional data are not handled by Firechat and is provided so you can
  /// link custom data to the chatroom directly in Firestore.
  Map<String, dynamic> details;

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
      this.lastMessageRef,
      this.details,
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
    this.lastMessageRef = map[FirechatChatroomKeys.kLastMessageRef];
    this.isLocal = false;
    this.details = map[FirechatChatroomKeys.kDetails];

    Map<String, DocumentReference> readByMap = {};
    map.forEach((String key, dynamic content) {
      if (key.startsWith(FirechatChatroomKeys.kReadByPrefix)) {
        readByMap[key] = content;
      }
    });
    lastMessagesRead = {};
    readByMap.forEach((String key, DocumentReference messageRef) {
      DocumentReference userRef = Firestore.instance.document(
          "users/" + key.replaceFirst(FirechatChatroomKeys.kReadByPrefix, ""));
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
      FirechatChatroomKeys.kLastMessageRef: this.lastMessageRef,
      FirechatChatroomKeys.kDetails: this.details
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
