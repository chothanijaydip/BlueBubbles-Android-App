import 'package:bluebubbles/blocs/chat_bloc.dart';
import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/helpers/ui_helpers.dart';
import 'package:bluebubbles/layouts/conversation_list/conversation_list.dart';
import 'package:bluebubbles/layouts/conversation_list/conversation_tile.dart';
import 'package:bluebubbles/layouts/conversation_view/conversation_view.dart';
import 'package:bluebubbles/layouts/search/search_view.dart';
import 'package:bluebubbles/layouts/widgets/theme_switcher/theme_switcher.dart';
import 'package:bluebubbles/managers/event_dispatcher.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/repository/models/chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SamsungConversationList extends StatefulWidget {
  SamsungConversationList({Key? key, required this.parent}) : super(key: key);

  final ConversationListState parent;

  @override
  _SamsungConversationListState createState() => _SamsungConversationListState();
}

class _SamsungConversationListState extends State<SamsungConversationList> {
  List<Chat> selected = [];

  bool hasPinnedChat() {
    for (var i = 0; i < ChatBloc().chats.archivedHelper(widget.parent.widget.showArchivedChats).length; i++) {
      if (ChatBloc().chats.archivedHelper(widget.parent.widget.showArchivedChats)[i].isPinned!) {
        widget.parent.hasPinnedChats = true;
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  bool hasNormalChats() {
    int counter = 0;
    for (var i = 0; i < ChatBloc().chats.archivedHelper(widget.parent.widget.showArchivedChats).length; i++) {
      if (ChatBloc().chats.archivedHelper(widget.parent.widget.showArchivedChats)[i].isPinned!) {
        counter++;
      } else {}
    }
    if (counter == ChatBloc().chats.archivedHelper(widget.parent.widget.showArchivedChats).length) {
      return false;
    } else {
      return true;
    }
  }

  Widget slideLeftBackground(Chat chat) {
    return Container(
      color: SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.pin
          ? Colors.yellow[800]
          : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.alerts
              ? Colors.purple
              : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.delete
                  ? Colors.red
                  : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.mark_read
                      ? Colors.blue
                      : Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? Icons.star_outline : Icons.star)
                  : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.alerts
                      ? (chat.isMuted! ? Icons.notifications_active : Icons.notifications_off)
                      : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.delete
                          ? Icons.delete_forever
                          : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? Icons.mark_chat_read : Icons.mark_chat_unread)
                              : (chat.isArchived! ? Icons.unarchive : Icons.archive),
              color: Colors.white,
            ),
            Text(
              SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? " Unpin" : " Pin")
                  : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.alerts
                      ? (chat.isMuted! ? ' Show Alerts' : ' Hide Alerts')
                      : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.delete
                          ? " Delete"
                          : SettingsManager().settings.materialLeftAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? ' Mark Read' : ' Mark Unread')
                              : (chat.isArchived! ? ' UnArchive' : ' Archive'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }

  Widget slideRightBackground(Chat chat) {
    return Container(
      color: SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.pin
          ? Colors.yellow[800]
          : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.alerts
              ? Colors.purple
              : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.delete
                  ? Colors.red
                  : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.mark_read
                      ? Colors.blue
                      : Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Icon(
              SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? Icons.star_outline : Icons.star)
                  : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.alerts
                      ? (chat.isMuted! ? Icons.notifications_active : Icons.notifications_off)
                      : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.delete
                          ? Icons.delete_forever
                          : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? Icons.mark_chat_read : Icons.mark_chat_unread)
                              : (chat.isArchived! ? Icons.unarchive : Icons.archive),
              color: Colors.white,
            ),
            Text(
              SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.pin
                  ? (chat.isPinned! ? " Unpin" : " Pin")
                  : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.alerts
                      ? (chat.isMuted! ? ' Show Alerts' : ' Hide Alerts')
                      : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.delete
                          ? " Delete"
                          : SettingsManager().settings.materialRightAction.value == MaterialSwipeAction.mark_read
                              ? (chat.hasUnreadMessage! ? ' Mark Read' : ' Mark Unread')
                              : (chat.isArchived! ? ' UnArchive' : ' Archive'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showArchived = widget.parent.widget.showArchivedChats;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: context.theme.backgroundColor, // navigation bar color
        systemNavigationBarIconBrightness:
            context.theme.backgroundColor.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent, // status bar color
      ),
      child: Obx(
        () => WillPopScope(
          onWillPop: () async {
            if (selected.isNotEmpty) {
              selected = [];
              setState(() {});
              return false;
            }
            return true;
          },
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: selected.isEmpty
                    ? AppBar(
                        shadowColor: Colors.transparent,
                        iconTheme: IconThemeData(color: context.theme.primaryColor),
                        brightness: ThemeData.estimateBrightnessForColor(context.theme.backgroundColor),
                        bottom: PreferredSize(
                          child: Container(
                            color: context.theme.dividerColor,
                            height: 0,
                          ),
                          preferredSize: Size.fromHeight(0.5),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ...widget.parent.getHeaderTextWidgets(size: 20),
                            ...widget.parent.getConnectionIndicatorWidgets(),
                            widget.parent.getSyncIndicatorWidget(),
                          ],
                        ),
                        actions: [
                          (!showArchived)
                              ? GestureDetector(
                                  onTap: () async {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) => SearchView(),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.search,
                                      color: context.textTheme.bodyText1!.color,
                                    ),
                                  ),
                                )
                              : Container(),
                          (SettingsManager().settings.moveChatCreatorToHeader.value && !showArchived
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      ThemeSwitcher.buildPageRoute(
                                        builder: (BuildContext context) {
                                          return ConversationView(
                                            isCreator: true,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.create,
                                      color: context.textTheme.bodyText1!.color,
                                    ),
                                  ),
                                )
                              : Container()),
                          Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 15.5),
                              child: Container(
                                width: 40,
                                child: widget.parent.buildSettingsButton(),
                              ),
                            ),
                          ),
                        ],
                        backgroundColor: context.theme.backgroundColor,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (selected.length <= 1)
                                  GestureDetector(
                                    onTap: () {
                                      selected.forEach((element) async {
                                        await element.toggleMute(!element.isMuted!);
                                      });

                                      selected = [];
                                      if (this.mounted) setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.notifications_off,
                                        color: context.textTheme.bodyText1!.color,
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () {
                                    selected.forEach((element) {
                                      if (element.isArchived!) {
                                        ChatBloc().unArchiveChat(element);
                                      } else {
                                        ChatBloc().archiveChat(element);
                                      }
                                    });
                                    selected = [];
                                    if (this.mounted) setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      showArchived ? Icons.unarchive : Icons.archive,
                                      color: context.textTheme.bodyText1!.color,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    selected.forEach((element) async {
                                      await element.togglePin(!element.isPinned!);
                                    });

                                    selected = [];
                                    if (this.mounted) setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.star,
                                      color: context.textTheme.bodyText1!.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            backgroundColor: context.theme.backgroundColor,
            body: Obx(() {
              if (!ChatBloc().hasChats.value) {
                return Center(
                  child: Container(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Loading chats...",
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                        ),
                        buildProgressIndicator(context, width: 15, height: 15),
                      ],
                    ),
                  ),
                );
              }
              if (ChatBloc().chats.archivedHelper(showArchived).isEmpty) {
                return Center(
                  child: Container(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Text(
                      "You have no archived chats :(",
                      style: context.textTheme.subtitle1,
                    ),
                  ),
                );
              }

              bool hasPinned = hasPinnedChat();
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (hasPinned)
                      Container(
                        height: 20.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.transparent,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    if (hasPinned)
                      Container(
                        padding: EdgeInsets.all(6.0),
                        decoration: new BoxDecoration(
                          color: context.theme.accentColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Obx(() {
                              if (SettingsManager().settings.swipableConversationTiles.value) {
                                return Dismissible(
                                  background: Obx(
                                      () => slideRightBackground(ChatBloc().chats.archivedHelper(showArchived)[index])),
                                  secondaryBackground: Obx(
                                      () => slideLeftBackground(ChatBloc().chats.archivedHelper(showArchived)[index])),
                                  // Each Dismissible must contain a Key. Keys allow Flutter to
                                  // uniquely identify widgets.
                                  key: UniqueKey(),
                                  // Provide a function that tells the app
                                  // what to do after an item has been swiped away.
                                  onDismissed: (direction) async {
                                    if (direction == DismissDirection.endToStart) {
                                      if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.pin) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .togglePin(!ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!);
                                        EventDispatcher().emit("refresh", null);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.alerts) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .toggleMute(!ChatBloc().chats.archivedHelper(showArchived)[index].isMuted!);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.delete) {
                                        ChatBloc().deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        Chat.deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                      } else if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.mark_read) {
                                        ChatBloc().toggleChatUnread(
                                            ChatBloc().chats.archivedHelper(showArchived)[index],
                                            !ChatBloc().chats.archivedHelper(showArchived)[index].hasUnreadMessage!);
                                      } else {
                                        if (ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!) {
                                          ChatBloc()
                                              .unArchiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        } else {
                                          ChatBloc().archiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        }
                                      }
                                    } else {
                                      if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.pin) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .togglePin(!ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!);
                                        EventDispatcher().emit("refresh", null);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.alerts) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .toggleMute(!ChatBloc().chats.archivedHelper(showArchived)[index].isMuted!);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.delete) {
                                        ChatBloc().deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        Chat.deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                      } else if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.mark_read) {
                                        ChatBloc().toggleChatUnread(
                                            ChatBloc().chats.archivedHelper(showArchived)[index],
                                            !ChatBloc().chats.archivedHelper(showArchived)[index].hasUnreadMessage!);
                                      } else {
                                        if (ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!) {
                                          ChatBloc()
                                              .unArchiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        } else {
                                          ChatBloc().archiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        }
                                      }
                                    }
                                  },
                                  child: (!showArchived &&
                                          ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                      ? Container()
                                      : (showArchived &&
                                              !ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                          ? Container()
                                          : ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!
                                              ? ConversationTile(
                                                  key: UniqueKey(),
                                                  chat: ChatBloc().chats.archivedHelper(showArchived)[index],
                                                  inSelectMode: selected.isNotEmpty,
                                                  selected: selected,
                                                  onSelect: (bool selected) {
                                                    if (selected) {
                                                      this
                                                          .selected
                                                          .add(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                                    } else {
                                                      this.selected.removeWhere((element) =>
                                                          element.guid ==
                                                          ChatBloc().chats.archivedHelper(showArchived)[index].guid);
                                                    }

                                                    if (this.mounted) setState(() {});
                                                  },
                                                )
                                              : Container(),
                                );
                              } else {
                                if (!showArchived && ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                  return Container();
                                if (showArchived && !ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                  return Container();
                                if (ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!) {
                                  return ConversationTile(
                                    key: UniqueKey(),
                                    chat: ChatBloc().chats.archivedHelper(showArchived)[index],
                                    inSelectMode: selected.isNotEmpty,
                                    selected: selected,
                                    onSelect: (bool selected) {
                                      if (selected) {
                                        this.selected.add(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        if (this.mounted) setState(() {});
                                      } else {
                                        this.selected.removeWhere((element) =>
                                            element.guid == ChatBloc().chats.archivedHelper(showArchived)[index].guid);
                                        if (this.mounted) setState(() {});
                                      }
                                    },
                                  );
                                }
                                return Container();
                              }
                            });
                          },
                          itemCount: ChatBloc().chats.archivedHelper(showArchived).length,
                        ),
                      ),
                    if (hasNormalChats())
                      Container(
                        height: 20.0,
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.transparent,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(20))),
                      ),
                    if (hasNormalChats())
                      Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: new BoxDecoration(
                            color: context.theme.accentColor,
                            borderRadius: new BorderRadius.only(
                              topLeft: const Radius.circular(20.0),
                              topRight: const Radius.circular(20.0),
                              bottomLeft: const Radius.circular(20.0),
                              bottomRight: const Radius.circular(20.0),
                            )),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Obx(() {
                              if (SettingsManager().settings.swipableConversationTiles.value) {
                                return Dismissible(
                                  background: Obx(
                                      () => slideRightBackground(ChatBloc().chats.archivedHelper(showArchived)[index])),
                                  secondaryBackground: Obx(
                                      () => slideLeftBackground(ChatBloc().chats.archivedHelper(showArchived)[index])),
                                  // Each Dismissible must contain a Key. Keys allow Flutter to
                                  // uniquely identify widgets.
                                  key: UniqueKey(),
                                  // Provide a function that tells the app
                                  // what to do after an item has been swiped away.
                                  onDismissed: (direction) async {
                                    if (direction == DismissDirection.endToStart) {
                                      if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.pin) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .togglePin(!ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!);
                                        EventDispatcher().emit("refresh", null);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.alerts) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .toggleMute(!ChatBloc().chats.archivedHelper(showArchived)[index].isMuted!);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.delete) {
                                        ChatBloc().deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        Chat.deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                      } else if (SettingsManager().settings.materialLeftAction.value ==
                                          MaterialSwipeAction.mark_read) {
                                        ChatBloc().toggleChatUnread(
                                            ChatBloc().chats.archivedHelper(showArchived)[index],
                                            !ChatBloc().chats.archivedHelper(showArchived)[index].hasUnreadMessage!);
                                      } else {
                                        if (ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!) {
                                          ChatBloc()
                                              .unArchiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        } else {
                                          ChatBloc().archiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        }
                                      }
                                    } else {
                                      if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.pin) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .togglePin(!ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!);
                                        EventDispatcher().emit("refresh", null);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.alerts) {
                                        await ChatBloc()
                                            .chats
                                            .archivedHelper(showArchived)[index]
                                            .toggleMute(!ChatBloc().chats.archivedHelper(showArchived)[index].isMuted!);
                                        if (this.mounted) setState(() {});
                                      } else if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.delete) {
                                        ChatBloc().deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        Chat.deleteChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                      } else if (SettingsManager().settings.materialRightAction.value ==
                                          MaterialSwipeAction.mark_read) {
                                        ChatBloc().toggleChatUnread(
                                            ChatBloc().chats.archivedHelper(showArchived)[index],
                                            !ChatBloc().chats.archivedHelper(showArchived)[index].hasUnreadMessage!);
                                      } else {
                                        if (ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!) {
                                          ChatBloc()
                                              .unArchiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        } else {
                                          ChatBloc().archiveChat(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                        }
                                      }
                                    }
                                  },
                                  child: (!showArchived &&
                                          ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                      ? Container()
                                      : (showArchived &&
                                              !ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                          ? Container()
                                          : (!ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!)
                                              ? ConversationTile(
                                                  key: UniqueKey(),
                                                  chat: ChatBloc().chats.archivedHelper(showArchived)[index],
                                                  inSelectMode: selected.isNotEmpty,
                                                  selected: selected,
                                                  onSelect: (bool selected) {
                                                    if (selected) {
                                                      this
                                                          .selected
                                                          .add(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                                    } else {
                                                      this.selected.removeWhere((element) =>
                                                          element.guid ==
                                                          ChatBloc().chats.archivedHelper(showArchived)[index].guid);
                                                    }

                                                    if (this.mounted) setState(() {});
                                                  },
                                                )
                                              : Container(),
                                );
                              } else {
                                if (!showArchived && ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                  return Container();
                                if (showArchived && !ChatBloc().chats.archivedHelper(showArchived)[index].isArchived!)
                                  return Container();
                                if (!ChatBloc().chats.archivedHelper(showArchived)[index].isPinned!) {
                                  return ConversationTile(
                                    key: UniqueKey(),
                                    chat: ChatBloc().chats.archivedHelper(showArchived)[index],
                                    inSelectMode: selected.isNotEmpty,
                                    selected: selected,
                                    onSelect: (bool selected) {
                                      if (selected) {
                                        this.selected.add(ChatBloc().chats.archivedHelper(showArchived)[index]);
                                      } else {
                                        this.selected.removeWhere((element) =>
                                            element.guid == ChatBloc().chats.archivedHelper(showArchived)[index].guid);
                                      }

                                      if (this.mounted) setState(() {});
                                    },
                                  );
                                }
                                return Container();
                              }
                            });
                          },
                          itemCount: ChatBloc().chats.archivedHelper(showArchived).length,
                        ),
                      )
                  ],
                ),
              );
            }),
            floatingActionButton: selected.isEmpty && !SettingsManager().settings.moveChatCreatorToHeader.value
                ? widget.parent.buildFloatingActionButton()
                : null,
          ),
        ),
      ),
    );
  }
}
