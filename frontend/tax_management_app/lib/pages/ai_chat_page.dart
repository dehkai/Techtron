import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../api/gpt.dart';
// import 'package:health_one/dashboard/diagnose/widget/identifySickness.dart';
import 'package:uuid/uuid.dart';

// This file contains a widget to ilustrate the chat and vision diagnose button that will lead to IdentifySicknessPage()
// In this page, user are allowed to communicate with GPT 4o regarding their health concern

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];

  // User will have a unique id 8000. It will become the sender
  final _user = const types.User(id: '8000');

  // GPT system will have a unique id 8001. It will become the responder
  final gpt = const types.User(id: '8001');

  @override
  void initState() {
    super.initState();
  }

  // Function to add message into '_message' List
  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handlePreviewDataFetched(types.TextMessage message, types.PreviewData previewData) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(previewData: previewData);

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  // Function to handle when user press the send button
  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(author: _user, createdAt: DateTime.now().millisecondsSinceEpoch, id: const Uuid().v4(), text: message.text);

    _addMessage(textMessage);

    List chatHistory = List.generate(_messages.length, (index) {
      String role;
      if (_messages[index].author.id == "8000") {
        role = "user";
      } else {
        role = "assistant";
      }

      return {'role': role, 'content': _messages[_messages.length - (index + 1)].toJson()["text"]};
    });
    dynamic response = await chatGPT4Model(chatHistory);

    final gptMessage = types.TextMessage(
      author: gpt,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: response["choices"][0]["message"]["content"],
    );

    _addMessage(gptMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3930),
        elevation: 0,
        title: const Text('AI Chat', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color.fromARGB(122, 29, 28, 33), width: 1)),
                color: Color(0xffF2F1F3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // const Expanded(
                  //   flex: 1,
                  //   child: Text(
                  //     "Need any help on your financial?",
                  //     style: TextStyle(fontSize: 16, color: Color(0xff001B2E), fontWeight: FontWeight.w700),
                  //     overflow: TextOverflow.clip,
                  //   ),
                  // ),
                  // Expanded(
                  //   flex: 1,
                  //   child: InkWell(
                  //     onTap: () {
                  //       Navigator.of(context).push(MaterialPageRoute(builder: (context) => IdentifySicknessPage()));
                  //     },
                  //     child: Container(
                  //       decoration: BoxDecoration(
                  //         color: Color(0xffFFC49B),
                  //         borderRadius: BorderRadius.circular(20),
                  //         boxShadow: [BoxShadow(color: Color(0xff1d1c21).withOpacity(1), offset: Offset(3, 3), blurRadius: 0, spreadRadius: 1)],
                  //       ),
                  //       child: const Padding(
                  //         padding: EdgeInsets.all(20.0),
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Row(children: [Icon(Icons.remove_red_eye, color: Color(0xff1d1c21)), SizedBox(width: 5), Text("by AI Doctor")]),
                  //             const Text('Vision Diagnose', style: TextStyle(fontSize: 20, color: Color(0xff1d1c21), fontWeight: FontWeight.w500)),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            Expanded(
              child: Chat(
                theme: const DefaultChatTheme(backgroundColor: Color(0xffF2F1F3), primaryColor: Color(0xffFFC670), secondaryColor: Color(0xffFFFBF5)),
                messages: _messages,
                onPreviewDataFetched: _handlePreviewDataFetched,
                onSendPressed: _handleSendPressed,
                showUserAvatars: true,
                showUserNames: true,
                user: _user,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
