import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:serene_user_app/app_modules/home_screen_module/view/home_screen.dart';
//import 'package:medico_project/screens/patient_screen/list_nearbyhos_doc/list_nearbyhos_doc_view.dart';
// 'package:medico_project/screens/patient_screen/home_screen/home_screen.dart';
//import 'package:medico_project/screens/patient_screen/list_nearbyclinc_doc/list_nearbyclinc_doc.dart';

// The main chat screen widget.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, 
  required this.userId
  });
 final int userId; // Example user ID, replace with actual user ID if needed.

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// The State class for the main chat screen.
class _ChatScreenState extends State<ChatScreen> {
  // A list of mock messages to display. We now use a simple data structure.
  final List<Map<String, dynamic>> _messages = [
    {
      'text': "Hello there! I'm a Serene AI. How can I assist you today?",
      'isUser': false,
    },
    //   {
    //     'text': "I'm looking for a modern UI design for a chatbot in Flutter.",
    //     'isUser': true,
    //   },
    //   {
    //     'text':
    //         "That's a great request! The code provided focuses on clean, elegant design with a user-friendly experience.",
    //     'isUser': false,
    //   },
    //   {'text': "Awesome! I'm excited to see it.", 'isUser': true},
  ];
  List<String> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isAskingQuestions = false;
  final TextEditingController _textController = TextEditingController();
  int? userId;
  @override
  void initState() {
    super.initState();
    //_loadQuestions();
    userId = widget.userId;
    print('ChatScreen userId: $userId');
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _fetchQuestions();
      setState(() {
        _questions = questions;
        _currentQuestionIndex = 0;
        _isAskingQuestions = true;
      });
      if (_questions.isNotEmpty) {
        _addBotMessage(_questions[_currentQuestionIndex]);
      }
    } catch (e) {
      _addBotMessage("Sorry, couldn't load questions.");
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.insert(0, {'text': text, 'isUser': false});
    });
  }

  // API endpoint URLs
  final String chatUrl =
      'https://417sptdw-8002.inc1.devtunnels.ms/userapp/chat/';
  final String questionsUrl =
      'https://417sptdw-8002.inc1.devtunnels.ms/userapp/questions/';

  // POST user message
  Future<void> _postUserMessage(String text) async {
    final response = await http.post(
      Uri.parse(chatUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": userId, // put the actual user id you want to send
        "message": text,
      }),
    );
   // print('POST /chat status: ${response.statusCode}');
   // print('POST /chat body: ${response.body}');

    // Fix the condition to properly check status code
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  // GET list of bot questions
  Future<List<String>> _fetchQuestions() async {
    final response = await http.get(Uri.parse(questionsUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> questions = data['questions'];
      return questions.cast<String>();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  // Handle input + backend communication
  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.insert(0, {'text': text, 'isUser': true});
    });

    String lowerText = text.trim();

    if (!_isAskingQuestions) {
      if (lowerText == 'hello' ||
          lowerText == 'hi' ||
          lowerText == 'hey' ||
          lowerText == 'hlo' ||
          lowerText == 'hii' ||
          lowerText == 'Hello' ||
          lowerText == 'Hi' ||
          lowerText == 'Hey' ||
          lowerText == 'Hlo' ||
          lowerText == 'Hii' ||
          lowerText == 'HEllO' ||
          lowerText == 'HI' ||
          lowerText == 'HEY' ||
          lowerText == 'Hllo' ||
          lowerText == 'HII' ||
          lowerText == 'HLO') {
        //  _addBotMessage("Loading questions, please wait...");
        await _loadQuestions();
      } else {
        _addBotMessage("Please say 'hello' or 'hi' to start.");
      }
      return;
    }

    try {
      await _postUserMessage(text);
    } catch (e) {
      _addBotMessage("Error sending message to server.");
      return;
    }

    _currentQuestionIndex++;
    if (_currentQuestionIndex < _questions.length) {
      _addBotMessage(_questions[_currentQuestionIndex]);
    } else {
      _addBotMessage(
        "Thank you for your answers! A Serene will get in touch soon.",
      );
      _isAskingQuestions = false;
      await _showResultFlow();
    }
  }

  Future<void> _showSeverityDialog(String severity, String disease) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Severity Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Severity: $severity'),
            const SizedBox(height: 8),
            Text('Disease: $disease'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Just pop!
            },
          ),
        ],
      );
    },
  );
}


  Future<Map<String, dynamic>> _fetchPredictionResult() async {
    final url =
        'https://417sptdw-8002.inc1.devtunnels.ms/userapp/get_prediction_result/$userId/';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
     // print("Prediction API Response: $data");
      return data;
    } else {
      throw Exception('Failed to fetch prediction result');
    }
  }

  Future<void> _showRemedyDialog(String remedyText) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remedy'),
          content: SingleChildScrollView(
            child: Text(
              remedyText.isNotEmpty
                  ? remedyText
                  : 'No remedy provided by system.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return HomeScreen(
                       // userId: userId!
                        );
                    },
                  ),
                );
                //   await Future.delayed(const Duration(milliseconds: 200));
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPredictionDialog(String predictionText) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Prediction Result'),
          content: SingleChildScrollView(
            child: Text(
              predictionText.isNotEmpty
                  ? predictionText
                  : 'No prediction details provided.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Next'),
              onPressed: () {
                Navigator.of(context).pop(); // Close this dialog
              },
            ),
          ],
        );
      },
    );
  }

 Future<void> _showResultFlow() async {
  try {
    final prediction = await _fetchPredictionResult();
    final String severity = (prediction['severity_level'] ?? 'Not determined').toString().trim();
    final String disease = (prediction['predicted_disease'] ?? 'No disease detected').toString().trim();
    final String remedy = (prediction['remedy_text'] ?? 'No remedy provided.').toString().trim();

    await _showSeverityDialog(severity, disease); // Wait for user OK

    if (severity.toLowerCase() == "low") {
      String predictionDetails = disease; // or more if needed
      await _showPredictionDialog(predictionDetails);
      await _showRemedyDialog(remedy);
    }
    else if (severity.toLowerCase() == "medium") {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //       builder: (context) => FindDoctorScreen(userId: userId!)),
        // );
      }
    }
    else if (severity.toLowerCase() == "high") {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //       builder: (context) => FindHosDoctorScreen(userId: userId!)),
        // );
      }
    }

  } catch (e) {
    debugPrint('Error fetching prediction result: $e');
    _addBotMessage("Sorry, could not determine severity level.");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Serene AI",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: <Widget>[
          // Expanded widget for the message list.
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true, // This makes the list grow from the bottom.
              itemCount: _messages.length,
              // We now build a ChatMessage widget for each message data entry.
              itemBuilder: (_, int index) => ChatMessage(
                text: _messages[index]['text'] as String,
                isUser: _messages[index]['isUser'] as bool,
              ),
            ),
          ),
          const Divider(height: 1.0),
          // Widget for the input field.
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the text input area.
  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Row(
          children: <Widget>[
            // The text input field.
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: "Send a message...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                  border: InputBorder.none,
                ),
              ),
            ),
            // The send button.
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}

// A widget to represent a single chat message.
// This is now a StatefulWidget to manage its own animation.
class ChatMessage extends StatefulWidget {
  const ChatMessage({required this.text, required this.isUser, super.key});

  final String text;
  final bool isUser;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Each message has its own animation controller.
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    // Start the animation when the message is created.
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
      axisAlignment: 0.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: widget.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: <Widget>[
            // Display the avatar for the chatbot.
            if (!widget.isUser) ...[
              const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.psychology_alt_outlined, color: Colors.white),
              ),
              const SizedBox(width: 8.0),
            ],
            // The message bubble.
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: widget.isUser ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20.0),
                  topRight: const Radius.circular(20.0),
                  bottomLeft: widget.isUser
                      ? const Radius.circular(20.0)
                      : Radius.zero,
                  bottomRight: widget.isUser
                      ? Radius.zero
                      : const Radius.circular(20.0),
                ),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.isUser ? Colors.blue[900] : Colors.black,
                  fontSize: 16.0,
                ),
              ),
            ),
            // Display the avatar for the user.
            if (widget.isUser) ...[
              const SizedBox(width: 8.0),
              const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}  