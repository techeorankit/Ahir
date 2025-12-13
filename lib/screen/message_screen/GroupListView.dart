import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:shortzz/screen/message_screen/public_chat.dart';

import '../../common/manager/session_manager.dart';
import '../../common/service/utils/params.dart';
import '../../common/service/utils/web_service.dart';
import '../../common/widget/full_name_with_blue_tick.dart';
import '../../common/widget/no_data_widget.dart';
import '../../languages/languages_keys.dart';
import '../../utilities/const_res.dart';
import '../../utilities/text_style_custom.dart';
import '../../utilities/theme_res.dart';
import 'message_screen_controller.dart';

class GroupListView  extends StatefulWidget {


const GroupListView({
super.key,

});

@override
State<GroupListView> createState() => _CustomShimmerFillTextState();
}

class _CustomShimmerFillTextState extends State<GroupListView> {
  List<dynamic> groupData = []; // Updated type

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    propertyListSearch();

  }

  Future<List<dynamic>> propertyListSearch() async {
    // setState(() {
    //   propertyData.clear();
    // });
    try {
      var header = {Params.apikey: apiKey};
      header[Params.authToken] = SessionManager.instance.getAuthToken();
      // final userId = await UID;

      final response = await http.get(
        Uri.parse(WebService.post.groupDataFetch),
        headers: header,
      );
      print("groupData33 ${response.body.toString()}");
      if (response.statusCode == 200) {
        setState(() {
          groupData = jsonDecode(response.body);

        });

        print("groupData $groupData");
        return jsonDecode(response.body);
      } else {
        print("groupData11 $groupData");

        throw Exception("Server Error!");
      }
    } catch (e) {
      print("groupData22 $groupData");
      debugPrint("Error fetching data: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final MessageScreenController controller = Get.find();
    return NoDataView(
      showShow: groupData.isEmpty,
      title: LKey.chatListEmptyTitle.tr,
      description: LKey.chatListEmptyDescription.tr,
      child: ListView.builder(
        itemCount: groupData.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final chatConversation = groupData[index];
          return InkWell(
            onTap: () {
              Get.to(
                    () => PublicChatScreen(chatConversation['id'].toString(),chatConversation['name'].toString()),
              );
            },
            // onLongPress: () => controller.onLongPress(chatConversation),
            child: Container(
              color: bgLightGrey(context),
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [

                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        // FullNameWithBlueTick(
                        //   username: chatConversation['name'],
                        //   fontSize: 13,
                        //   iconSize: 18,
                        //   isVerify: 0,
                        // ),
                        Text(chatConversation['name'] ?? '',
                            style: TextStyleCustom.outFitLight300(
                                fontSize: 16, color: Colors.black),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)
                      ],
                    ),
                  ),

                  // Column(
                  //   spacing: 4,
                  //   mainAxisSize: MainAxisSize.min,
                  //   crossAxisAlignment: CrossAxisAlignment.end,
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //         DateTime.fromMillisecondsSinceEpoch(
                  //             int.parse(chatConversation.id ?? '0'))
                  //             .toString()
                  //             .timeAgo,
                  //         style: TextStyleCustom.outFitLight300(
                  //             fontSize: 13, color: textLightGrey(context))),
                  //     Visibility(
                  //       visible: (chatConversation.msgCount ?? 0) > 0,
                  //       replacement: const SizedBox(height: 23),
                  //       child: Container(
                  //         width: 23,
                  //         height: 23,
                  //         decoration: BoxDecoration(
                  //             color: themeAccentSolid(context),
                  //             shape: BoxShape.circle),
                  //         alignment: Alignment.center,
                  //         child: Text(
                  //           '${chatConversation.msgCount ?? 0}',
                  //           style: TextStyleCustom.outFitRegular400(
                  //               fontSize: 12, color: whitePure(context)),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // )
                ],
              ),
            ),
          );;
        },
      ),
    );
  }
}
