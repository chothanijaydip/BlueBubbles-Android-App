import 'dart:async';
import 'dart:ui';

import 'package:bluebubbles/blocs/chat_bloc.dart';
import 'package:bluebubbles/blocs/setup_bloc.dart';
import 'package:bluebubbles/helpers/ui_helpers.dart';
import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/layouts/conversation_list/list_styles/cupertino_conversation_list.dart';
import 'package:bluebubbles/layouts/conversation_list/list_styles/material_conversation_list.dart';
import 'package:bluebubbles/layouts/conversation_list/list_styles/samsung_conversation_list.dart';
import 'package:bluebubbles/layouts/conversation_view/conversation_view.dart';
import 'package:bluebubbles/layouts/settings/settings_panel.dart';
import 'package:bluebubbles/layouts/widgets/theme_switcher/theme_switcher.dart';
import 'package:bluebubbles/managers/event_dispatcher.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/socket_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ConversationList extends StatefulWidget {
  ConversationList({Key? key, required this.showArchivedChats}) : super(key: key);

  final bool showArchivedChats;

  @override
  ConversationListState createState() => ConversationListState();
}

class ConversationListState extends State<ConversationList> {
  Color? currentHeaderColor;
  bool hasPinnedChats = false;

  // ignore: close_sinks
  StreamController<Color?> headerColorStream = StreamController<Color?>.broadcast();

  late ScrollController scrollController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (this.mounted) {
      theme = Colors.transparent;
    }

    SystemChannels.textInput.invokeMethod('TextInput.hide').catchError((e) {
      debugPrint("Error caught while hiding keyboard: ${e.toString()}");
    });
  }

  @override
  void dispose() {
    super.dispose();

    // Remove the scroll listener from the state
    scrollController.removeListener(scrollListener);
  }

  @override
  void initState() {
    super.initState();
    ChatBloc().refreshChats();
    scrollController = ScrollController()..addListener(scrollListener);

    // Listen for any incoming events
    EventDispatcher().stream.listen((Map<String, dynamic> event) {
      if (!event.containsKey("type")) return;

      if (event["type"] == 'refresh' && this.mounted) {
        setState(() {});
      }
    });
  }

  Color? get theme => currentHeaderColor;

  set theme(Color? color) {
    if (currentHeaderColor == color) return;
    currentHeaderColor = color;
    if (!headerColorStream.isClosed) headerColorStream.sink.add(currentHeaderColor);
  }

  void scrollListener() {
    !_isAppBarExpanded ? theme = Colors.transparent : theme = context.theme.accentColor.withOpacity(0.5);
  }

  bool get _isAppBarExpanded {
    return scrollController.hasClients && scrollController.offset > (125 - kToolbarHeight);
  }

  List<Widget> getHeaderTextWidgets({double? size}) {
    TextStyle? style = context.textTheme.headline1;
    if (size != null) style = style!.copyWith(fontSize: size);

    return [Text(widget.showArchivedChats ? "Archive" : "Messages", style: style), Container(width: 10)];
  }

  Widget getSyncIndicatorWidget() {
    return Obx(() {
      if (!SettingsManager().settings.showSyncIndicator.value) return SizedBox.shrink();
      if (!SetupBloc().isSyncing.value) return Container();
      return buildProgressIndicator(context, width: 10, height: 10);
    });
  }

  void openNewChatCreator() async {
    bool shouldShowSnackbar = (await SettingsManager().getMacOSVersion())! >= 11;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (BuildContext context) {
          return ConversationView(
            isCreator: true,
            showSnackbar: shouldShowSnackbar,
          );
        },
      ),
    );
  }

  void sortChats() {
    ChatBloc().chats.sort((a, b) {
      if (!a.isPinned! && b.isPinned!) return 1;
      if (a.isPinned! && !b.isPinned!) return -1;
      if (a.latestMessageDate == null && b.latestMessageDate == null) return 0;
      if (a.latestMessageDate == null) return 1;
      if (b.latestMessageDate == null) return -1;
      return -a.latestMessageDate!.compareTo(b.latestMessageDate!);
    });
  }

  Widget buildSettingsButton() => !widget.showArchivedChats
      ? PopupMenuButton(
          color: context.theme.accentColor,
          onSelected: (dynamic value) {
            if (value == 0) {
              ChatBloc().markAllAsRead();
            } else if (value == 1) {
              Navigator.of(context).push(
                ThemeSwitcher.buildPageRoute(
                  builder: (context) => ConversationList(
                    showArchivedChats: true,
                  ),
                ),
              );
            } else if (value == 2) {
              Navigator.of(context).push(
                ThemeSwitcher.buildPageRoute(
                  builder: (BuildContext context) {
                    return SettingsPanel();
                  },
                ),
              );
            }
          },
          itemBuilder: (context) {
            return <PopupMenuItem>[
              PopupMenuItem(
                value: 0,
                child: Text(
                  'Mark all as read',
                  style: context.textTheme.bodyText1,
                ),
              ),
              PopupMenuItem(
                value: 1,
                child: Text(
                  'Archived',
                  style: context.textTheme.bodyText1,
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Text(
                  'Settings',
                  style: context.textTheme.bodyText1,
                ),
              ),
            ];
          },
          child: ThemeSwitcher(
            iOSSkin: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: context.theme.accentColor,
              ),
              child: Icon(
                Icons.more_horiz,
                color: context.theme.primaryColor,
                size: 15,
              ),
            ),
            materialSkin: Icon(
              Icons.more_vert,
              color: context.textTheme.bodyText1!.color,
              size: 25,
            ),
            samsungSkin: Icon(
              Icons.more_vert,
              color: context.textTheme.bodyText1!.color,
              size: 25,
            ),
          ),
        )
      : Container();

  FloatingActionButton buildFloatingActionButton() {
    return FloatingActionButton(
        backgroundColor: context.theme.primaryColor,
        child: Icon(Icons.message, color: Colors.white, size: 25),
        onPressed: openNewChatCreator);
  }

  List<Widget> getConnectionIndicatorWidgets() {
    if (!SettingsManager().settings.showConnectionIndicator.value) return [];

    return [Obx(() => getIndicatorIcon(SocketManager().state.value, size: 12)), Container(width: 10.0)];
  }

  @override
  Widget build(BuildContext context) {
    return ThemeSwitcher(
      iOSSkin: CupertinoConversationList(parent: this),
      materialSkin: MaterialConversationList(parent: this),
      samsungSkin: SamsungConversationList(parent: this),
    );
  }
}
