import 'dart:math';
import 'dart:ui';

import 'package:bluebubbles/blocs/chat_bloc.dart';
import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/helpers/device_helpers.dart';
import 'package:bluebubbles/helpers/ui_helpers.dart';
import 'package:bluebubbles/layouts/conversation_list/conversation_list.dart';
import 'package:bluebubbles/layouts/conversation_list/conversation_tile.dart';
import 'package:bluebubbles/layouts/conversation_list/pinned_conversation_tile.dart';
import 'package:bluebubbles/layouts/conversation_view/conversation_view.dart';
import 'package:bluebubbles/layouts/search/search_view.dart';
import 'package:bluebubbles/layouts/widgets/vertical_split_view.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/managers/theme_manager.dart';
import 'package:bluebubbles/repository/models/chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CupertinoConversationList extends StatelessWidget {
  const CupertinoConversationList({Key? key, required this.parent}) : super(key: key);

  final ConversationListState parent;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: context.theme.backgroundColor, // navigation bar color
        systemNavigationBarIconBrightness:
            context.theme.backgroundColor.computeLuminance() > 0.5 ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent, // status bar color
      ),
      child: buildForDevice(context),
    );
  }

  Widget buildChatList(BuildContext context, bool showAltLayout) {
    bool showArchived = parent.widget.showArchivedChats;
    Brightness brightness = ThemeData.estimateBrightnessForColor(context.theme.backgroundColor);
    return Obx(() => Scaffold(
          appBar: PreferredSize(
            preferredSize: Size(
              (showAltLayout) ? context.width * 0.33 : context.width,
              SettingsManager().settings.reducedForehead.value ? 10 : 40,
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: StreamBuilder<Color?>(
                  stream: parent.headerColorStream.stream,
                  builder: (context, snapshot) {
                    return AnimatedCrossFade(
                      crossFadeState:
                          parent.theme == Colors.transparent ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      duration: Duration(milliseconds: 250),
                      secondChild: AppBar(
                        iconTheme: IconThemeData(color: context.theme.primaryColor),
                        elevation: 0,
                        backgroundColor: parent.theme,
                        centerTitle: true,
                        brightness: brightness,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text(
                              showArchived ? "Archive" : "Messages",
                              style: context.textTheme.bodyText1,
                            ),
                          ],
                        ),
                      ),
                      firstChild: AppBar(
                        leading: new Container(),
                        elevation: 0,
                        brightness: brightness,
                        backgroundColor: context.theme.backgroundColor,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          backgroundColor: context.theme.backgroundColor,
          extendBodyBehindAppBar: true,
          body: CustomScrollView(
            controller: parent.scrollController,
            physics: ThemeManager().scrollPhysics,
            slivers: <Widget>[
              SliverAppBar(
                leading: ((SettingsManager().settings.skin.value == Skins.iOS && showArchived) ||
                        (SettingsManager().settings.skin.value == Skins.Material ||
                                SettingsManager().settings.skin.value == Skins.Samsung) &&
                            !showArchived)
                    ? IconButton(
                        icon: Icon(
                            (SettingsManager().settings.skin.value == Skins.iOS && showArchived)
                                ? Icons.arrow_back_ios
                                : Icons.arrow_back,
                            color: context.theme.primaryColor),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    : new Container(),
                stretch: true,
                expandedHeight: (!showArchived) ? 80 : 50,
                backgroundColor: Colors.transparent,
                pinned: false,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: <StretchMode>[StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                  ),
                  centerTitle: true,
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(height: 20),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(width: (!showArchived) ? 20 : 50),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ...parent.getHeaderTextWidgets(),
                                ...parent.getConnectionIndicatorWidgets(),
                                parent.getSyncIndicatorWidget(),
                              ],
                            ),
                            Spacer(
                              flex: 25,
                            ),
                            if (!showArchived)
                              ClipOval(
                                child: Material(
                                  color: context.theme.accentColor, // button color
                                  child: InkWell(
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Icon(Icons.search, color: context.theme.primaryColor, size: 12)),
                                    onTap: () async {
                                      Navigator.of(context).push(
                                        CupertinoPageRoute(
                                          builder: (context) => SearchView(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (!showArchived) Container(width: 10.0),
                            if (SettingsManager().settings.moveChatCreatorToHeader.value && !showArchived)
                              ClipOval(
                                child: Material(
                                  color: context.theme.accentColor, // button color
                                  child: InkWell(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Icon(Icons.create, color: context.theme.primaryColor, size: 12),
                                    ),
                                    onTap: this.parent.openNewChatCreator,
                                  ),
                                ),
                              ),
                            if (SettingsManager().settings.moveChatCreatorToHeader.value) Container(width: 10.0),
                            parent.buildSettingsButton(),
                            Spacer(
                              flex: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // SliverToBoxAdapter(
              //   child: Container(
              //     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              //     child: GestureDetector(
              //       onTap: () {
              //         Navigator.of(context).push(
              //           MaterialPageRoute(
              //             builder: (context) => SearchView(),
              //           ),
              //         );
              //       },
              //       child: AbsorbPointer(
              //         child: SearchTextBox(),
              //       ),
              //     ),
              //   ),
              // ),
              Obx(() {
                if (ChatBloc().chats.archivedHelper(showArchived).bigPinHelper(true).isEmpty) {
                  return SliverToBoxAdapter(child: Container());
                }
                ChatBloc().chats.archivedHelper(showArchived).sort(Chat.sort);

                int rowCount = context.mediaQuery.orientation == Orientation.portrait
                    ? SettingsManager().settings.pinRowsPortrait.value
                    : SettingsManager().settings.pinRowsLandscape.value;
                int colCount = SettingsManager().settings.pinColumnsPortrait.value;
                if (context.mediaQuery.orientation != Orientation.portrait) {
                  colCount = (colCount / context.mediaQuerySize.height * context.mediaQuerySize.width).floor();
                }
                int pinCount = ChatBloc().chats.archivedHelper(showArchived).bigPinHelper(true).length;
                int usedRowCount = min((pinCount / colCount).ceil(), rowCount);
                int maxOnPage = rowCount * colCount;
                PageController _controller = PageController();
                int _pageCount = (pinCount / maxOnPage).ceil();
                int _filledPageCount = (pinCount / maxOnPage).floor();

                return SliverPadding(
                  padding: EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: (context.mediaQuerySize.width + 30) / colCount * usedRowCount,
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          PageView.builder(
                            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            scrollDirection: Axis.horizontal,
                            controller: _controller,
                            itemBuilder: (context, index) {
                              return Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: _pageCount > 1 ? WrapAlignment.start : WrapAlignment.center,
                                children: List.generate(
                                  index < _filledPageCount
                                      ? maxOnPage
                                      : ChatBloc().chats.archivedHelper(showArchived).bigPinHelper(true).length %
                                          maxOnPage,
                                  (_index) {
                                    return PinnedConversationTile(
                                      key: Key(ChatBloc()
                                          .chats
                                          .archivedHelper(showArchived)
                                          .bigPinHelper(true)[index * maxOnPage + _index]
                                          .guid
                                          .toString()),
                                      chat: ChatBloc()
                                          .chats
                                          .archivedHelper(showArchived)
                                          .bigPinHelper(true)[index * maxOnPage + _index],
                                    );
                                  },
                                ),
                              );
                            },
                            itemCount: _pageCount,
                          ),
                          if (_pageCount > 1)
                            SmoothPageIndicator(
                              controller: _controller,
                              count: _pageCount,
                              effect: ScaleEffect(
                                dotHeight: 5.0,
                                dotWidth: 5.0,
                                spacing: 5.0,
                                radius: 5.0,
                                scale: 1.5,
                                activeDotColor: context.theme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Obx(() {
                ChatBloc().chats.archivedHelper(showArchived).sort(Chat.sort);
                if (!ChatBloc().hasChats.value) {
                  return SliverToBoxAdapter(
                    child: Center(
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
                    ),
                  );
                }
                if (!ChatBloc().hasChats.value) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.only(top: 50.0),
                        child: Text(
                          showArchived ? "You have no archived chats :(" : "You have no chats :(",
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ConversationTile(
                        key: Key(
                            ChatBloc().chats.archivedHelper(showArchived).bigPinHelper(false)[index].guid.toString()),
                        chat: ChatBloc().chats.archivedHelper(showArchived).bigPinHelper(false)[index],
                      );
                    },
                    childCount: ChatBloc().chats.archivedHelper(showArchived).bigPinHelper(false).length,
                  ),
                );
              }),
            ],
          ),
          floatingActionButton:
              !SettingsManager().settings.moveChatCreatorToHeader.value ? parent.buildFloatingActionButton() : null,
        ));
  }

  Widget buildForLandscape(BuildContext context, Widget chatList) {
    return VerticalSplitView(
        dividerWidth: 10.0,
        initialRatio: 0.4,
        minRatio: 0.33,
        maxRatio: 0.5,
        allowResize: true,
        left: chatList,
        right: ConversationView(
          chat: null,
          isCreator: true,
        ));
  }

  Widget buildForDevice(BuildContext context) {
    return OrientationBuilder(builder: (BuildContext context, Orientation orientation) {
      DeviceType deviceType = getDeviceType();
      bool showAltLayout = deviceType == DeviceType.Tablet || orientation == Orientation.portrait;
      Widget chatList = buildChatList(context, showAltLayout);
      if (showAltLayout) {
        return buildForLandscape(context, chatList);
      }

      return chatList;
    });
  }
}
