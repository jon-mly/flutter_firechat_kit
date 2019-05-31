library firechat_kit;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

part 'sources/firechat_kit.dart';
part 'sources/firechat_configuration.dart';
part 'sources/blocs/current_user.dart';
part 'sources/blocs/chatrooms.dart';
part 'sources/blocs/conversation.dart';
part 'sources/auth/auth_interface.dart';
part 'sources/firestore/firestore_user.dart';
part 'sources/firestore/firestore_message.dart';
part 'sources/firestore/firestore_chatroom.dart';
part 'sources/model/message.dart';
part 'sources/model/chatroom.dart';
part 'sources/model/user.dart';
part 'sources/errors/firechat_errors.dart';
