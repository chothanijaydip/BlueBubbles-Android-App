import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bluebubble_messages/helpers/attachment_downloader.dart';
import 'package:bluebubble_messages/blocs/setup_bloc.dart';
import 'package:bluebubble_messages/helpers/utils.dart';
import 'package:bluebubble_messages/repository/database.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'managers/method_channel_interface.dart';
import 'repository/models/attachment.dart';
import 'repository/models/message.dart';
import 'settings.dart';
import './blocs/chat_bloc.dart';
import './repository/models/chat.dart';
import './repository/models/handle.dart';

class SocketManager {
  factory SocketManager() {
    return _manager;
  }

  static final SocketManager _manager = SocketManager._internal();

  SocketManager._internal();

  Directory appDocDir;

  List<Chat> chatsWithNotifications = <Chat>[];

  void removeChatNotification(Chat chat) {
    for (int i = 0; i < chatsWithNotifications.length; i++) {
      debugPrint(i.toString());
      if (chatsWithNotifications[i].guid == chat.guid) {
        chatsWithNotifications.removeAt(i);
        break;
      }
    }
    notify();
  }

  List<String> processedGUIDS = [];
  //settings
  Settings settings;

  SetupBloc setup = new SetupBloc();
  StreamController<bool> finishedSetup = StreamController<bool>();

  SharedPreferences sharedPreferences;
  //Socket io
  // SocketIOManager manager;
  SocketIO socket;

  //setstate for these widgets
  Map<String, Function> subscribers = new Map();

  Map<String, AttachmentDownloader> attachmentDownloaders = Map();
  void addAttachmentDownloader(String guid, AttachmentDownloader downloader) {
    attachmentDownloaders[guid] = downloader;
  }

  void finishDownloader(String guid) {
    attachmentDownloaders.remove(guid);
  }

  Map<String, Function> disconnectSubscribers = new Map();

  String token;

  void subscribe(String guid, Function cb) {
    _manager.subscribers[guid] = cb;
  }

  void unsubscribe(String guid) {
    _manager.subscribers.remove(guid);
  }

  void disconnectCallback(Function cb, String guid) {
    _manager.disconnectSubscribers[guid] = cb;
  }

  void unSubscribeDisconnectCallback(String guid) {
    _manager.disconnectSubscribers.remove(guid);
  }

  void notify() {
    for (Function cb in _manager.subscribers.values) {
      cb();
    }
  }

  void getSavedSettings() async {
    appDocDir = await getApplicationDocumentsDirectory();
    _manager.sharedPreferences = await SharedPreferences.getInstance();
    var result = _manager.sharedPreferences.getString('Settings');
    if (result != null) {
      Map resultMap = jsonDecode(result);
      _manager.settings = Settings.fromJson(resultMap);
    }
    finishedSetup.sink.add(_manager.settings.finishedSetup);
    _manager.startSocketIO();
    _manager.authFCM();
  }

  void saveSettings(Settings settings,
      [bool connectToSocket = false, Function connectCb]) async {
    if (_manager.sharedPreferences == null) {
      _manager.sharedPreferences = await SharedPreferences.getInstance();
    }
    _manager.sharedPreferences.setString('Settings', jsonEncode(settings));
    await _manager.authFCM();
    if (connectToSocket) {
      _manager.startSocketIO(connectCb);
    }
  }

  void socketStatusUpdate(data, [Function connectCB]) {
    switch (data) {
      case "connect":
        debugPrint("CONNECTED");
        authFCM();
        // syncChats();
        if (connectCB != null) {
          connectCB();
        }
        _manager.disconnectSubscribers.forEach((key, value) {
          value();
          _manager.disconnectSubscribers.remove(key);
        });
        return;
      case "disconnect":
        _manager.disconnectSubscribers.values.forEach((f) {
          f();
        });
        debugPrint("disconnected");
        return;
      case "reconnect":
        debugPrint("RECONNECTED");
        return;
      default:
        return;
    }
  }

  Future<void> deleteDB() async {
    Database db = await DBProvider.db.database;

    // Remove base tables
    await Handle.flush();
    await Chat.flush();
    await Attachment.flush();
    await Message.flush();

    // Remove join tables
    await db.execute("DELETE FROM chat_handle_join");
    await db.execute("DELETE FROM chat_message_join");
    await db.execute("DELETE FROM attachment_message_join");

    // Recreate tables
    DBProvider.db.buildDatabase(db);
  }

  startSocketIO([Function connectCb]) async {
    if (connectCb == null && _manager.settings.finishedSetup == false) return;
    // If we already have a socket connection, kill it
    if (_manager.socket != null) {
      _manager.socket.destroy();
    }

    debugPrint(
        "Starting socket io with the server: ${_manager.settings.serverAddress}");

    try {
      // Create a new socket connection
      _manager.socket = SocketIOManager().createSocketIO(
          _manager.settings.serverAddress, "/",
          query: "guid=${_manager.settings.guidAuthKey}",
          socketStatusCallback: (data) => socketStatusUpdate(data, connectCb));
      _manager.socket.init();
      _manager.socket.connect();
      _manager.socket.unSubscribesAll();

      // Let us know when our device was added
      _manager.socket.subscribe("fcm-device-id-added", (data) {
        debugPrint("fcm device added: " + data.toString());
      });

      // Let us know when there is an error
      _manager.socket.subscribe("error", (data) {
        debugPrint("An error occurred: " + data.toString());
      });
      _manager.socket.subscribe("new-message", (_data) async {
        // debugPrint(data.toString());
        debugPrint("new-message");
        Map<String, dynamic> data = jsonDecode(_data);
        if (SocketManager().processedGUIDS.contains(data["guid"])) {
          return new Future.value("");
        } else {
          SocketManager().processedGUIDS.add(data["guid"]);
        }
        if (data["chats"].length == 0) return new Future.value("");
        Chat chat = await Chat.findOne({"guid": data["chats"][0]["guid"]});
        if (chat == null) return new Future.value("");
        String title = await chatTitle(chat);
        SocketManager().handleNewMessage(data, chat);
        if (data["isFromMe"]) {
          return new Future.value("");
        }

        // String message = data["text"].toString();

        // await _showNotificationWithDefaultSound(0, title, message);

        return new Future.value("");
      });

      _manager.socket.subscribe("updated-message", (_data) async {
        debugPrint("updated-message");
        // Map<String, dynamic> data = jsonDecode(_data);
        // debugPrint("updated message: " + data.toString());
      });
    } catch (e) {
      debugPrint("FAILED TO CONNECT");
    }
  }

  void closeSocket() {
    _manager.socket.destroy();
    _manager.socket = null;
  }

  Future<void> authFCM() async {
    try {
      final String result = await MethodChannelInterface()
          .invokeMethod('auth', _manager.settings.fcmAuthData);
      token = result;
      if (_manager.socket != null) {
        _manager.socket.sendMessage(
            "add-fcm-device",
            jsonEncode({"deviceId": token, "deviceName": "android-client"}),
            () {});
        debugPrint(token);
      }
    } on PlatformException catch (e) {
      token = "Failed to get token: " + e.toString();
      debugPrint(token);
    }
  }

  void handleNewMessage(Map<String, dynamic> data, Chat chat) {
    Message message = new Message.fromMap(data);
    if (message.isFromMe) {
      chat.save().then((_chat) {
        _chat.addMessage(message).then((value) {
          // if (value == null) {
          //   return;
          // }

          debugPrint("new message " + message.text);
          // Create the attachments
          List<dynamic> attachments = data['attachments'];

          attachments.forEach((attachmentItem) {
            Attachment file = Attachment.fromMap(attachmentItem);
            file.save(message);
          });
          notify();
        });
      });
    } else {
      chat.addMessage(message).then((value) {
        // if (value == null) return;
        // Create the attachments
        debugPrint("new message " + chat.guid);
        List<dynamic> attachments = data['attachments'];

        attachments.forEach((attachmentItem) {
          Attachment file = Attachment.fromMap(attachmentItem);
          file.save(message);
        });
        chatsWithNotifications.add(chat);
        notify();
      });
    }
  }

  void finishSetup() {
    finishedSetup.sink.add(true);
    notify();
  }

  void sendMessage(Chat chat, String text) {
    Map<String, dynamic> params = new Map();
    params["guid"] = chat.guid;
    params["message"] = text;
    String tempGuid = "Temp${randomString(5)}";
    Message sentMessage =
        Message(guid: tempGuid, text: text, dateCreated: DateTime.now());
    sentMessage.save();
    chat.save();
    chat.addMessage(sentMessage);
    notify();

    _manager.socket.sendMessage("send-message", jsonEncode(params), (data) {
      Map response = jsonDecode(data);
      debugPrint("message sent: " + response.toString());
    });
  }
}