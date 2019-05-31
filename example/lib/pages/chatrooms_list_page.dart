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
  @override
  void initState() {
    super.initState();
    FirechatKit.instance.prepareChatrooms();
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

  //
  // ########## BUILDING
  //

  Widget _chatroomsList() {
    return StreamBuilder(
      stream: FirechatKit.instance.chatrooms.onChatroomsUpdate,
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
            List<FirechatUser> contacts = FirechatKit.instance.chatrooms
                .otherPeopleIn(chatroom: chatroom);
            return ListTile(
              title: Text(
                  "${contacts.map((contact) => contact?.displayName ?? contact.userId)}"),
              onTap: () => _getSelectedConversation(chatroom: chatroom),
            );
          },
          separatorBuilder: (_, int index) => Divider(
                color: Colors.black12,
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FirechatKit Example"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            color: Colors.white,
            onPressed: _logout,
          )
        ],
      ),
      body: _chatroomsList(),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: _presentSearchPeopleTextField,
      ),
    );
  }
}
