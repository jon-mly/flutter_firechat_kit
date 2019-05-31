import 'package:flutter/material.dart';

import 'package:firechat_kit/firechat_kit.dart';

import 'package:firechat_kit_example/main.dart';

class ConversationPage extends StatefulWidget {
  final FirechatConversation conversation;

  ConversationPage(this.conversation);

  @override
  State<StatefulWidget> createState() {
    return _ConversationPageState(conversation);
  }
}

class _ConversationPageState extends State<ConversationPage> with RouteAware {
  final FirechatConversation _conversation;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FocusNode _focusNode;
  bool _keyboardOpened = false;
  bool _isLoadingOlderMessages = false;

  _ConversationPageState(this._conversation);

  //
  // ########## STATE LIFECYCLE
  //

  @override
  void initState() {
    super.initState();
    // Focus node
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _keyboardOpened = _focusNode.hasFocus;
      });
    });
    // Text Editing Controller
    _controller.addListener(
        () => _conversation.userIsComposing(_controller.text.length > 0));
    // Scroll Controller
    _scrollController.addListener(_scrollViewDidScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Route observer
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollViewDidScroll);
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  //
  // ########## NAVIGATION EVENTS
  //

  @override
  void didPush() {
    super.didPush();
    // View is now on the top view.
    _conversation.userIsFocusing(true);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // View is now on the top view.
    _conversation.userIsFocusing(true);
  }

  @override
  void didPushNext() {
    super.didPushNext();
    // View is no more on top of the view
    _conversation.userIsFocusing(false);
  }

  @override
  void didPop() {
    super.didPop();
    // View is no more on top of the view
    _conversation.userIsFocusing(false);
  }

  //
  // ########## ACTIONS
  //

  void _sendMessage() {
    _conversation.sendMessage(_controller.text).catchError((e) => print(e));
    _controller.clear();
  }

  void _delete(FirechatMessage message) {
    _conversation.deleteMessage(message);
  }

  Future<void> _requestMoreMessages() async {
    setState(() {
      _isLoadingOlderMessages = true;
    });
    await _conversation.requestOlderMessages();
    setState(() {
      _isLoadingOlderMessages = false;
    });
  }

  void _editName(String newName) {
    _conversation.setChatroomName(name: newName);
  }

  //
  // ############ ACTION DIALOG
  //

  Future<void> _presentNameEditTextField(String initialName) async {
    TextEditingController _dialogController =
        TextEditingController(text: initialName ?? "");
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
                  hintText: "Enter the name of the conversation"),
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
  // ########## SCROLL CONTROLLER & PAGNIATION
  //

  void _scrollViewDidScroll() {
    // Load more messages when the scroll view reaches the top and there is no
    // loading process at the moment.
    if (_scrollController.position.extentAfter <= 0 &&
        !_isLoadingOlderMessages) {
      _requestMoreMessages();
    }
  }

  //
  // ########## BUILDING
  //

  Widget _messageBar() {
    return Container(
      height: 60.0,
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      color: Colors.teal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8.0),
                  hintText: "Enter a message",
                  hintStyle: TextStyle(color: Colors.white.withAlpha(160))),
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.redAccent,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 6.0),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: Colors.white,
            ),
            onPressed: _sendMessage,
          )
        ],
      ),
    );
  }

  Widget _messagesList() {
    return StreamBuilder(
      stream: _conversation.onMessagesUpdate,
      builder: (BuildContext context,
          AsyncSnapshot<List<FirechatMessage>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(
            child: CircularProgressIndicator(),
          );
        if (snapshot.data == null || snapshot.data.isEmpty)
          return Center(child: Text("No messages yet. Send one."));

        List<FirechatMessage> messages = snapshot.data;
        return ListView.separated(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          reverse: true,
          itemCount: messages.length + ((_isLoadingOlderMessages) ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (_isLoadingOlderMessages && index == messages.length)
              return ListTile(
                title: Center(
                  child: CircularProgressIndicator(),
                ),
              );

            FirechatMessage message = messages[index];
            FirechatUser sender = _conversation.senderOf(message: message);
            bool sentByCurrentUser =
                FirechatKit.instance.authorIsCurrentUserFor(message: message);
            bool seen = _conversation.messageIsReadByOthers(message);

            Widget tile = ListTile(
              title: Text(
                message.content,
                textAlign: sentByCurrentUser ? TextAlign.end : TextAlign.start,
              ),
              trailing: sentByCurrentUser
                  ? SizedBox(
                      child: seen
                          ? Container(
                              color: Colors.blue,
                            )
                          : Container(
                              color: Colors.grey,
                            ),
                      height: 20.0,
                      width: 20.0,
                    )
                  : null,
              subtitle: sentByCurrentUser
                  ? Text(
                      "Me",
                      textAlign: TextAlign.end,
                    )
                  : Text(
                      sender.displayName ?? sender.userId ?? "Someone",
                      textAlign: TextAlign.start,
                    ),
            );
            if (sentByCurrentUser)
              return Dismissible(
                key: GlobalKey(),
                child: tile,
                background: Container(
                  color: Colors.red,
                  child: Center(
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                ),
                onDismissed: (_) => _delete(message),
              );
            return tile;
          },
          separatorBuilder: (_, int index) => Divider(
                color: Colors.black12,
              ),
        );
      },
    );
  }

  Widget _messagesListAndTypingInfos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: _messagesList(),
        ),
        StreamBuilder(
          stream: _conversation.onFocusingUsersUpdate,
          builder:
              (BuildContext context, AsyncSnapshot<List<FirechatUser>> snap) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: (snap.hasData)
                  ? Text(
                      "${snap.data.map((FirechatUser user) => user.displayName ?? user.userId)}")
                  : Container(),
            );
          },
        ),
        StreamBuilder(
          stream: _conversation.onComposingUsersUpdate,
          builder:
              (BuildContext context, AsyncSnapshot<List<FirechatUser>> snap) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: (snap.hasData && snap.data.isNotEmpty)
                  ? Text(
                      "Typing : ${snap.data.map((FirechatUser user) => user.displayName ?? user.userId)}")
                  : Container(),
            );
          },
        )
      ],
    );
  }

  Widget _messageListInGestureWrapper() {
    if (_keyboardOpened)
      return GestureDetector(
        child: _messagesListAndTypingInfos(),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
      );
    return _messagesListAndTypingInfos();
  }

  Widget _buildPageWith({@required FirechatChatroom chatroom}) {
    return StreamBuilder(
      stream: _conversation.onContactsUpdate,
      builder: (BuildContext context, snapshot) {
        String conversationTitle;
        if (chatroom == null)
          conversationTitle = "";
        else {
          conversationTitle =
              (chatroom.title != null && chatroom.title.isNotEmpty)
                  ? chatroom.title
                  : "CONVERSATION";
        }

        return Scaffold(
            appBar: AppBar(
              title: Text(conversationTitle),
              backgroundColor: Colors.teal,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: Navigator.of(context).pop,
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.edit),
                  color: Colors.white,
                  onPressed: () => _presentNameEditTextField(chatroom.title),
                ),
              ],
            ),
            body: Column(
              children: <Widget>[
                Expanded(
                  child: _messageListInGestureWrapper(),
                ),
                _messageBar()
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirechatChatroom>(
        stream: _conversation.onChatroomUpdate,
        builder: (context, snapshot) {
          FirechatChatroom chatroom = snapshot.data;
          return _buildPageWith(chatroom: chatroom);
        });
  }
}
