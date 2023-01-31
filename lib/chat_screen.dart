import 'dart:async';
import 'package:chat_gpt/threedots.dart';
import 'package:dio/dio.dart';
import 'package:chat_gpt/chatmessage.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  ChatGPT? chatGPT;
  StreamSubscription? _subscription;
  bool isTyping = false;
  @override
  void initState() {
    chatGPT = ChatGPT.instance;
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((timeStamp) {
      sendMessage(isInitial: true);
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Widget buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration.collapsed(hintText: "Send a Message"),
            // onSubmitted: (value) => sendMessage(),
          ),
        ),
        IconButton(
          onPressed: () => sendMessage(),
          icon: Icon(Icons.send),
        )
      ],
    ).px16();
  }

  void sendMessage({isInitial = false}) {
    ChatMessage message = (isInitial)
        ? ChatMessage(
            text: "controller.text",
            sender: "user",
            isVisible: false,
          )
        : ChatMessage(text: controller.text.trim(), sender: "user");
    setState(() {
      _messages.insert(0, message);
      if (!isInitial) {
        isTyping = true;
      }
    });
    controller.clear();

    final request = CompleteReq(
        prompt: message.text, model: kTranslateModelV3, max_tokens: 200);

    _subscription = chatGPT!
        .builder("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",
            orgId: "",
            baseOption: HttpSetup(receiveTimeout: 60000, connectTimeout: 60000))
        .onCompleteStream(request: request)
        .handleError((error) {
      ChatMessage botMessage = ChatMessage(
        text: "${error}",
        sender: "bot",
      );
      setState(() {
        _messages.insert(0, botMessage);
        if (!isInitial) {
          isTyping = false;
        }
      });
    }).timeout(
      Duration(seconds: 60),
      onTimeout: (sink) {
        ChatMessage botMessage = ChatMessage(
          text: "${sink.toString()}",
          sender: "bot",
        );
        setState(() {
          _messages.insert(0, botMessage);
          if (!isInitial) {
            isTyping = false;
          }
        });
      },
    ).listen((response) {
      Vx.log(response!.choices[0].text);
      ChatMessage botMessage = ChatMessage(
        text: response.choices[0].text,
        sender: "bot",
      );
      setState(() {
        _messages.insert(0, botMessage);
        if (!isInitial) {
          isTyping = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ChatGPT"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
                child: ListView.builder(
              reverse: true,
              padding: Vx.m8,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            )),
            if (isTyping) ThreeDots(),
            Divider(
              height: 1.0,
            ),
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
              ),
              child: buildTextComposer(),
            ),
          ],
        ),
      ),
    );
  }
}
