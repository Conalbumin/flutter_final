import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizlet_final_flutter/study/word/word.dart';
import '../firebase_study_page.dart';
import '../folder/add_topic_to_folder.dart';
import '../study_mode/quiz.dart';
import '../study_mode/flashcard.dart';
import '../study_mode/type.dart';
import '../word/add_word_in_topic.dart';
import 'edit_topic_page.dart';
import 'package:card_swiper/card_swiper.dart';

class TopicPage extends StatefulWidget {
  final String topicId;
  final String topicName;
  final int numberOfWords;
  final String text;
  final bool isPrivate;

  const TopicPage({
    Key? key,
    required this.topicId,
    required this.topicName,
    required this.numberOfWords,
    required this.text,
    required this.isPrivate,
  }) : super(key: key);

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  late List<DocumentSnapshot> words;
  late String _topicName;
  late String _text;

  @override
  void initState() {
    super.initState();
    _topicName = widget.topicName;
    _text = widget.text;
    fetchWords(widget.topicId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_topicName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 25)),
            Text('Number of Words: ${widget.numberOfWords}',
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 35,
            ),
            onPressed: () {
              _showDeleteConfirmationDialog(context, widget.topicId);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'addToFolder',
                child: ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('Add to Folder'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'addWordInTopic',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add new Word'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'setPrivate',
                child: ListTile(
                  leading: Icon(Icons.private_connectivity),
                  title: Text('Set private'),
                ),
              )
            ],
            onSelected: (String choice) {
              if (choice == 'edit') {
                editAction(context);
              } else if (choice == 'addToFolder') {
                _showFolderTab(context);
              } else if (choice == 'addWordInTopic') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddWordInTopic(topicId: widget.topicId),
                  ),
                );
              } else if (choice == 'setPrivate') {
                setPrivateTopic(widget.topicId, !widget.isPrivate); // Toggle isPrivate
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200, // Adjust the height as needed
              child: FutureBuilder(
                future: fetchWords(widget.topicId),
                builder:
                    (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    List<DocumentSnapshot> words = snapshot.data!;
                    return Swiper(
                      pagination: const SwiperPagination(
                        builder: DotSwiperPaginationBuilder(
                          color: Colors.white,
                          activeColor: Colors.indigo,
                          activeSize: 15,
                          size: 10,
                        ),
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: words.length,
                      itemBuilder: (context, index) {
                        String word = words[index]['word'];
                        String definition = words[index]['definition'];
                        return WordItem(
                          definition: definition,
                          word: word,
                          wordId: words[index].id,
                          topicId: widget.topicId,
                        ); // Pass context here
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                height: 60,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "Description: $_text",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle onTap for FlashCard
                      print('FlashCard tapped');
                      // Add navigation or other actions as needed
                    },
                    child: const FlashCard(),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      // Handle onTap for Quiz
                      print('Quiz tapped');
                      // Add navigation or other actions as needed
                    },
                    child: const Quiz(),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      // Handle onTap for Type
                      print('Type tapped');
                      // Add navigation or other actions as needed
                    },
                    child: const Type(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: fetchWords(widget.topicId),
              builder:
                  (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<DocumentSnapshot> words = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      String word = words[index]['word'];
                      String definition = words[index]['definition'];
                      return WordItem(
                        definition: definition,
                        word: word,
                        wordId: words[index].id,
                        topicId: widget.topicId,
                      ).card(context); // Pass context here
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderTab(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AddTopicToFolderPage(
          onSelectFolder: (folderId) {
            addTopicToFolder(widget.topicId, folderId);
          },
        );
      },
    );
  }

  void editAction(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTopicPage(
              initialTopicName: _topicName,
              initialDescription: _text,
              topicId: widget.topicId,
            ),
      ),
    );

    if (result != null && result['topicName'] != null && result['description'] != null) {
      setState(() {
        _topicName = result['topicName'];
        _text = result['description'];
        fetchWords(widget.topicId);
      });
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, String topicId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Topic'),
          content: const Text('Are you sure you want to remove this topic?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                print("topicId ${topicId}");
                deleteTopic(context, topicId);
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
