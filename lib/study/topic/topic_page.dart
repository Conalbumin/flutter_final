import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quizlet_final_flutter/constant/toast.dart';
import 'package:quizlet_final_flutter/study/ranking/rank.dart';
import 'package:quizlet_final_flutter/study/study_mode/quiz_page.dart';
import 'package:quizlet_final_flutter/study/study_mode/typing_page.dart';
import 'package:quizlet_final_flutter/study/topic/topic_page_widget.dart';
import 'package:quizlet_final_flutter/study/word/word.dart';
import '../../constant/text_style.dart';
import '../csv.dart';
import '../firebase_study/add.dart';
import '../firebase_study/delete.dart';
import '../firebase_study/fetch.dart';
import '../firebase_study/related_func.dart';
import '../folder/add_topic_to_folder.dart';
import '../study_mode/flashcard_page.dart';
import '../study_mode/quiz.dart';
import '../study_mode/flashcard.dart';
import '../study_mode/type.dart';
import '../word/add_word_in_topic.dart';
import '../word/word_with_icon.dart';
import 'edit_topic_page.dart';
import 'package:card_swiper/card_swiper.dart';

class TopicPage extends StatefulWidget {
  final String topicId;
  final String topicName;
  final int numberOfWords;
  final String text;
  final bool isPrivate;
  final String userId;
  final DateTime timeCreated;
  final DateTime lastAccess;
  final Function() refreshCallback;
  final int accessPeople;

  const TopicPage({
    Key? key,
    required this.topicId,
    required this.topicName,
    required this.numberOfWords,
    required this.text,
    required this.isPrivate,
    required this.userId,
    required this.refreshCallback,
    required this.timeCreated,
    required this.lastAccess,
    required this.accessPeople,
  }) : super(key: key);

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  late List<DocumentSnapshot> words;
  late int _numberOfWords;
  late String _topicName;
  late String _text;
  bool showAllWords = true;
  List<DocumentSnapshot> favoritedWords = [];
  String userUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _topicName = widget.topicName;
    _text = widget.text;
    _numberOfWords = widget.numberOfWords;
    fetchDataAndUpdateState();
  }

  Future<void> fetchDataAndUpdateState() async {
    List<DocumentSnapshot> fetchedWords = await fetchWords(widget.topicId);
    setState(() {
      words = fetchedWords;
      updateFavWordsList();
    });
  }

  void updateFavWordsList() {
    setState(() {
      favoritedWords =
          words.where((word) => word['isFavorited'] == true).toList();
    });
  }

  void handleWordAdded(String topicId) {
    fetchDataAndUpdateState();
  }

  void handleWordDeleted(String wordId) {
    setState(() {
      words.removeWhere((word) => word.id == wordId);
      favoritedWords.removeWhere((word) => word.id == wordId);
      _numberOfWords--;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_topicName, style: appBarStyle),
            Text('Number of Words: $_numberOfWords',
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
              if(userUid == widget.userId) {
                _showDeleteConfirmationDialog(context, widget.topicId);
              } else {
                showToast('You are not allowed to delete this topic');
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
              PopupMenuItem<String>(
                value: 'setPrivate',
                child: ListTile(
                  leading: Icon(Icons.private_connectivity),
                  title: Text(widget.isPrivate ? 'Set public' : 'Set private'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'exportCsv',
                child: ListTile(
                  leading: Icon(Icons.import_export),
                  title: Text('Export topic'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'importCsv',
                child: ListTile(
                  leading: Icon(Icons.import_contacts),
                  title: Text('Import topic'),
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
                    builder: (context) => AddWordInTopic(
                      topicId: widget.topicId,
                      handleWordAdded: (topicId) {
                        handleWordAdded(topicId);
                      },
                      updateNumberOfWords: (int numberOfWordAdded) {
                        setState(() {
                          _numberOfWords += numberOfWordAdded;
                        });
                      },
                    ),
                  ),
                );
              } else if (choice == 'setPrivate') {
                if (userUid == widget.userId) {
                  setPrivateTopic(context, widget.topicId, !widget.isPrivate);
                } else {
                  showToast('You are not allowed to modify this topic');
                }
              } else if (choice == 'exportCsv') {
                List<Map<String, dynamic>> wordData =
                    convertDocumentSnapshotsToMapList(words);
                exportTopicToCSV(wordData, widget.topicName, context);
              } else {
                setState(() {
                  pickAndProcessCsvFile(widget.topicId, handleWordAdded,
                      (int numberOfCsv) {
                    setState(() {
                      _numberOfWords += numberOfCsv;
                    });
                  });
                });
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
              height: 200,
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
                    if (words.isEmpty) {
                      return warning();
                    } else {
                      return Swiper(
                        scrollDirection: Axis.horizontal,
                        itemCount: words.length,
                        loop: false,
                        viewportFraction: 0.6,
                        itemBuilder: (context, index) {
                          String word = words[index]['word'];
                          String definition = words[index]['definition'];
                          String status = words[index]['status'];
                          bool isFavorited = words[index]['isFavorited'];
                          return WordItem(
                            definition: definition,
                            word: word,
                            wordId: words[index].id,
                            topicId: widget.topicId,
                            status: status,
                            isFavorited: isFavorited.toString() ?? '',
                            showDefinition: false,
                            countLearn: 0,
                          );
                        },
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text("Description: $_text", style: normalSubText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Spacer
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.stacked_bar_chart,
                        color: Colors.white,
                        size: 40,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RankingPage(
                              topicId: widget.topicId,
                              numberOfWords: widget.numberOfWords,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      DateTime currentTime = DateTime.now();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashCardPage(
                              topicId: widget.topicId,
                              numberOfWords: widget.numberOfWords,
                              showAllWords: showAllWords,
                              lastAccess: currentTime),
                        ),
                      );
                    },
                    child: const FlashCard(),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      DateTime currentTime = DateTime.now();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(
                            topicId: widget.topicId,
                            topicName: widget.topicName,
                            numberOfWords: widget.numberOfWords,
                            numberOfQuestions: words.length,
                            onSelectAnswer: (answers) {
                              // Handle selected answers here
                            },
                            showAllWords: showAllWords,
                            lastAccess: currentTime,
                          ),
                        ),
                      );
                    },
                    child: const Quiz(),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      DateTime currentTime = DateTime.now();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TypingPage(
                            topicId: widget.topicId,
                            topicName: widget.topicName,
                            numberOfWords: widget.numberOfWords,
                            numberOfQuestions: words.length,
                            showAllWords: showAllWords,
                            onType: (answers) {
                              // Handle typed answers here
                            },
                            lastAccess: currentTime,
                          ),
                        ),
                      );
                    },
                    child: const Type(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 350,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.indigo,
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: showAllWords
                              ? Colors.indigo.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showAllWords = true;
                              fetchDataAndUpdateState();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              'All',
                              textAlign: TextAlign.center,
                              style: all_FavInTopic,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: !showAllWords
                            ? Colors.indigo.withOpacity(0.3)
                            : Colors.transparent,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showAllWords = false;
                              fetchDataAndUpdateState();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              'Favorited',
                              textAlign: TextAlign.center,
                              style: all_FavInTopic,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  return showAllWords
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: words.length,
                          itemBuilder: (context, index) {
                            String word = words[index]['word'];
                            String definition = words[index]['definition'];
                            String status = words[index]['status'];
                            bool isFavorited = words[index]['isFavorited'];
                            return WordWithIcon(
                              definition: definition,
                              word: word,
                              wordId: words[index].id,
                              topicId: widget.topicId,
                              status: status,
                              isFavorited: isFavorited.toString() ?? '',
                              handleWordDeleted: (wordId) {
                                handleWordDeleted(wordId);
                              },
                              countLearn: 0,
                            );
                          },
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: favoritedWords.length,
                          itemBuilder: (context, index) {
                            String word = favoritedWords[index]['word'];
                            String definition =
                                favoritedWords[index]['definition'];
                            String status = favoritedWords[index]['status'];
                            bool isFavorited =
                                favoritedWords[index]['isFavorited'];
                            return WordWithIcon(
                              definition: definition,
                              word: word,
                              wordId: favoritedWords[index].id,
                              topicId: widget.topicId,
                              status: status,
                              isFavorited: isFavorited.toString() ?? '',
                              handleWordDeleted: (wordId) {
                                handleWordDeleted(wordId);
                              },
                              countLearn: 0,
                            );
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
    if (userUid == widget.userId) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditTopicPage(
            initialTopicName: _topicName,
            initialDescription: _text,
            topicId: widget.topicId,
          ),
        ),
      );

      if (result != null &&
          result['topicName'] != null &&
          result['description'] != null) {
        setState(() {
          _topicName = result['topicName'];
          _text = result['description'];
          fetchWords(widget.topicId);
        });
      }
    } else {
      showToast('You are not allowed to modify this topic');
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
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
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
