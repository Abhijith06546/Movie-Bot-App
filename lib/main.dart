import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MovieRecommenderApp());
}

class MovieRecommenderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Recommender',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> messages = [];
  String apiKey = 'Enter the API key here';
  Future<void> getMovieRecommendations(String keywords) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'user',
            'content': 'Based on the following keywords, suggest some movies:\n\nKeywords: $keywords\n\nMovies:'
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String recommendations = data['choices'][0]['message']['content'];
      setState(() {
        messages.add("Bot: $recommendations");
      });
    } else if (response.statusCode == 429) {  // Too many requests
      setState(() {
        messages.add("Bot: Rate limit exceeded. Please try again later.");
      });
    } else if (response.statusCode == 403) { // Forbidden, possibly due to quota
      setState(() {
        messages.add("Bot: Your API key is not valid or you have insufficient quota.");
      });
    } else {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      setState(() {
        messages.add("Bot: Sorry, I couldn't fetch recommendations.");
      });
    }
  }


  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      setState(() {
        messages.add("You: $text");
      });
      getMovieRecommendations(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movie Recommender'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: 'Enter keywords'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _handleSubmitted(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
