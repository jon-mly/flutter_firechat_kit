import 'package:flutter/material.dart';

import 'package:firechat_kit/firechat_kit.dart';

import 'conversation_page.dart';

class ChatroomsListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ChatroomsListPageState();
  }
}

class _ChatroomsListPageState extends State<ChatroomsListPage> {
  FirechatChatrooms _chatrooms;

  @override
  void initState() {
    super.initState();
    _chatrooms = FirechatKit.instance.prepareChatrooms();
  }

  //
  // ########## NAVIGATION
  //

  void _navigateBackToLoginPage() {
    Navigator.of(context).pop();
  }

  void _navigateToConversationPage() {
    FirechatConversation conversation = FirechatKit.instance.conversation;
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConversationPage(conversation)));
  }

  //
  // ########## ACTIONS
  //

  Future<void> _logout() async {
    FirechatKit.instance.logout();
    _navigateBackToLoginPage();
  }

  Future<void> _getConversationWithUser({@required String id}) async {
    await FirechatKit.instance.getConversationWithUser(id: id).then((_) {
      _navigateToConversationPage();
    }).catchError((e) {
      print(e);
    });
  }

  Future<void> _getSelectedConversation(
      {@required FirechatChatroom chatroom}) async {
    FirechatKit.instance.getConversationFor(chatroom: chatroom);
    _navigateToConversationPage();
  }

  void _editName(String newName) {
    FirechatKit.instance.currentUser.set(displayName: newName);
  }

  //
  // ############ ACTION DIALOG
  //

  Future<void> _presentSearchPeopleTextField() async {
    TextEditingController _dialogController = TextEditingController();
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.all(16.0),
            content: TextField(
              autofocus: true,
              autocorrect: false,
              controller: _dialogController,
              decoration: InputDecoration(
                  hintText: "Enter the ID of the user you want to talk to"),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.cancel, color: Colors.teal),
                onPressed: () => Navigator.of(context).pop(),
              ),
              IconButton(
                icon: Icon(Icons.open_in_new, color: Colors.teal),
                onPressed: () {
                  Navigator.of(context).pop();
                  _getConversationWithUser(id: _dialogController.text);
                },
              )
            ],
          );
        });
  }

  Future<void> _presentNameEditTextField() async {
    TextEditingController _dialogController = TextEditingController(
        text: FirechatKit.instance.currentUser.user.displayName ?? "");
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.all(16.0),
            content: TextField(
              autofocus: true,
              autocorrect: false,
              controller: _dialogController,
              decoration: InputDecoration(hintText: "Enter your display name"),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.cancel, color: Colors.teal),
                onPressed: () => Navigator.of(context).pop(),
              ),
              IconButton(
                icon: Icon(Icons.open_in_new, color: Colors.teal),
                onPressed: () {
                  Navigator.of(context).pop();
                  _editName(_dialogController.text);
                },
              )
            ],
          );
        });
  }

  //
  // ########## BUILDING
  //

  Widget _chatroomsList() {
    return StreamBuilder(
      stream: _chatrooms.onChatroomsUpdate,
      builder: (BuildContext context,
          AsyncSnapshot<List<FirechatChatroom>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(),
          );
        if (snapshot.data == null || snapshot.data.isEmpty)
          return Center(child: Text("No chatrooms"));

        List<FirechatChatroom> chatrooms = snapshot.data;

        return ListView.separated(
          itemCount: chatrooms.length,
          itemBuilder: (BuildContext context, int index) {
            FirechatChatroom chatroom = chatrooms[index];

            List<FirechatUser> contacts =
                _chatrooms.otherPeopleIn(chatroom: chatroom);
            FirechatMessage lastMessage =
                _chatrooms.lastMessageFor(chatroom: chatroom);
            bool isUpToDate =
                !_chatrooms.currentUserHasUnreadMessagesIn(chatroom: chatroom);
            FirechatUser sender = _chatrooms.senderOf(message: lastMessage);

            String title = (chatroom.title != null && chatroom.title.isNotEmpty)
                ? chatroom.title
                : "${contacts.map((contact) => contact.displayName ?? contact.userId)}";

            String subtitle;
            if (_chatrooms.currentUserSent(message: lastMessage)) {
              subtitle = "Me : ${lastMessage.content ?? ""}";
            } else {
              subtitle =
                  "${sender.displayName ?? sender.userId} : ${lastMessage.content ?? ""}";
            }

            return ListTile(
              title: Text(
                title,
                style: TextStyle(
                    fontWeight:
                        (isUpToDate) ? FontWeight.normal : FontWeight.bold),
              ),
              onTap: () => _getSelectedConversation(chatroom: chatroom),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                    fontWeight:
                        (isUpToDate) ? FontWeight.normal : FontWeight.bold),
              ),
            );
          },
          separatorBuilder: (_, int index) => Divider(
                color: Colors.black12,
              ),
        );
      },
    );
  }

  Widget _buildPage() {
    return StreamBuilder(
      stream: _chatrooms.onContactsUpdate,
      builder: (BuildContext context, _) {
        return _chatroomsList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirechatUser>(
        stream: FirechatKit.instance.currentUser.onUserUpdate,
        builder: (context, snapshot) {
          FirechatUser self = snapshot.data;
          return Scaffold(
            appBar: AppBar(
              title: Text(self?.displayName ?? self?.userId ?? ""),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.teal,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.edit),
                  color: Colors.white,
                  onPressed: _presentNameEditTextField,
                ),
                IconButton(
                  icon: Icon(Icons.exit_to_app),
                  color: Colors.white,
                  onPressed: _logout,
                )
              ],
            ),
            body: _buildPage(),
            floatingActionButton: FloatingActionButton(
              child: Icon(
                Icons.add,
              ),
              onPressed: _presentSearchPeopleTextField,
            ),
          );
        });
  }
}
