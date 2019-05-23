import 'package:flutter/material.dart';

import 'package:firechat_kit/firechat_kit.dart';

class ConversationPage extends StatefulWidget {
  final FirechatConversation conversation;

  ConversationPage(this.conversation);

  @override
  State<StatefulWidget> createState() {
    return _ConversationPageState(conversation);
  }
}

class _ConversationPageState extends State<ConversationPage> {
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
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _keyboardOpened = _focusNode.hasFocus;
      });
    });
    _scrollController.addListener(_scrollViewDidScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollViewDidScroll);
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  //
  // ########## ACTIONS
  //

  void _sendMessage() {
    _conversation
        .sendMessage(_controller.text)
        .then((_) => _controller.clear())
        .catchError((e) => print(e));
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
            bool sentByCurrentUser =
                FirechatKit.instance.authorIsCurrentUserFor(message: message);
            Widget tile = ListTile(
              title: Text(
                message.content,
                textAlign: sentByCurrentUser ? TextAlign.end : TextAlign.start,
              ),
              subtitle: sentByCurrentUser
                  ? Text(
                      "Me",
                      textAlign: TextAlign.end,
                    )
                  : Text(
                      "The other one",
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

  Widget _messageListInGestureWrapper() {
    if (_keyboardOpened)
      return GestureDetector(
        child: _messagesList(),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
      );
    return _messagesList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Conversation"),
          backgroundColor: Colors.teal,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: Navigator.of(context).pop,
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: _messageListInGestureWrapper(),
            ),
            _messageBar()
          ],
        ));
  }
}
