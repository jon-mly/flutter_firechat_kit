part of firechat_kit;

class FirechatError extends Error {
  String message;
  Object optionalContent;

  FirechatError(this.message, {this.optionalContent});

  static final FirechatError kLoggingInError = FirechatError(
      "An error has occured while trying to log in anonymously with Firebase Auth.");
  static final FirechatError kNotLoggedInError = FirechatError(
      "The user is not logged in. Please ensure that `login` has been called before.");
  static final FirechatError kFirestoreUserFetchError = FirechatError(
      "An error has occured while Firestore were trying to retrieve a FirechatUser document.");
  static final FirechatError kFirestoreUserUploadError = FirechatError(
      "An error has occured while Firestore were trying to upload a FirechatUser document.");
  static final FirechatError kFirestoreUserUpdateError = FirechatError(
      "An error has occured while Firestore were trying to update a FirechatUser document.");
  static final FirechatError kFirestoreChatroomQueryError = FirechatError(
      "An error has occured while Firestore were trying to filter and get Chatroom documents");
  static final FirechatError kFirestoreChatroomUploadError = FirechatError(
      "An error has occured while Firestore were trying to upload a Chatroom document.");
  static final FirechatError kCouldNotRetrieveUserDataError = FirechatError(
      "An error has occured while Firechat Kit tried to retrieve the FirechatUser instance.");
  static final FirechatError kChatroomQueryError = FirechatError(
      "An error has occured while Firechat Kit tried to search for a Chatroom instance in Firestore.");
  static final FirechatError kMessageToSendIsEmpty = FirechatError(
      "The content of the message given in parameter of FirechatConversation.sendMessage is empty.");
  static final FirechatError kMessageAssetTypeIsNull = FirechatError(
      "While a URL for an asset has been given in parameter of FirechatConversation.sendMessage, the asset type has not been given.");
  static final FirechatError kMessageSendingError = FirechatError(
      "An error has occured with Firestore while trying to send a message.");
  static final FirechatError kMessageDeletionError = FirechatError(
      "An error has occured with Firestore while trying to delete a message.");
  static final FirechatError kMessageNotFoundError = FirechatError(
      "The DocumentReference of the given Message does not lead to anything in Firestore.");
  static final FirechatError kNullUserId =
      FirechatError("The given user Id is null.");
  static final FirechatError kNullDocumentReferenceError = FirechatError(
      "The DocumentReference of the given Message does not lead to anything in Firestore.");
  static final FirechatError kNullChatroomError =
      FirechatError("The Chatroom given in parameter is null.");
  static final FirechatError kNoUserFoundFromId = FirechatError(
      "No FirechatUser has been found to be associated with the given Id.");

  String toString() {
    return "Message : \n$message, Optional content : \n${optionalContent.toString()}";
  }
}
