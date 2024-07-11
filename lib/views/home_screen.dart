import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> chatmessageList = [];
  ChatUser currentUser = ChatUser(id: '0', firstName: 'User');
  ChatUser geminiUser = ChatUser(
      id: '1', firstName: 'Gemini', profileImage: 'assets/images/gemini.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gemini Chat"),
        centerTitle: true,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
        inputOptions: InputOptions(trailing: [
          IconButton(
              onPressed: _sendMediaMessage, icon: Icon(Icons.image_rounded))
        ]),
        currentUser: currentUser,
        onSend: _sendmessage,
        messages: chatmessageList);
  }

  void _sendmessage(ChatMessage chatMessage) {
    setState(() {
      chatmessageList = [chatMessage, ...chatmessageList];
    });

    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }

      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastmessage = chatmessageList.firstOrNull;

        if (lastmessage != null && lastmessage.user == geminiUser) {
          lastmessage == chatmessageList.removeAt(0);
          String response = event.content?.parts
                  ?.fold("", (pre, cur) => "$pre ${cur.text}") ??
              "";
          lastmessage.text += response;

          setState(() {
            chatmessageList = [lastmessage, ...chatmessageList];
          });
        } else {
          String response = event.content?.parts
                  ?.fold("", (pre, cur) => "$pre ${cur.text}") ??
              "";

          ChatMessage message = ChatMessage(
              user: geminiUser, createdAt: DateTime.now(), text: response);
          setState(() {
            chatmessageList = [message, ...chatmessageList];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: 'Decribe this picture.',
          medias: [
            ChatMedia(url: file.path, fileName: '', type: MediaType.image)
          ]);
      _sendmessage(chatMessage);
    }
  }
}
