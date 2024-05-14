import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizlet_final_flutter/constant/text_style.dart';
import '../firebase_study/related_func.dart';
import 'topic.dart';

class TopicTab extends StatefulWidget {
  const TopicTab({Key? key});

  @override
  State<TopicTab> createState() => _TopicTabState();
}

class _TopicTabState extends State<TopicTab> {
  String _sortBy = 'timeCreated';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sort by:', style: normalTextBlack),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Center(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.blue,
                        value: _sortBy,
                        onChanged: (String? newValue) {
                          setState(() {
                            _sortBy = newValue!;
                          });
                        },
                        items: <String>['timeCreated', 'lastAccess']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                value == 'timeCreated'
                                    ? 'Creation time'
                                    : 'Last access',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        )),
        Expanded(
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (userSnapshot.hasError) {
                return Text('Error: ${userSnapshot.error}');
              }
              if (userSnapshot.data == null) {
                return const Center(
                  child: Text('No user signed in.'),
                );
              }
              String currentUserId = userSnapshot.data!.uid;
              // Lấy danh sách topic mà sub-collection 'access' chứa user id
              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('topics').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  // Đối với mỗi document trong 'topics'
                  List<Future<DocumentSnapshot>> futureAccessSnapshots =
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    // Trả về future của document trong 'access'
                    return FirebaseFirestore.instance
                        .collection('topics')
                        .doc(document.id)
                        .collection('access')
                        .doc(currentUserId) // Lấy theo user hiện tại
                        .get();
                  }).toList();
                  // Sử dụng Future.wait để đợi tất cả các tương lai hoàn thành và trả về danh sách
                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: Future.wait(futureAccessSnapshots),
                    builder: (context, accessSnapshotList) {
                      if (accessSnapshotList.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (accessSnapshotList.hasError) {
                        return Text('Error: ${accessSnapshotList.error}');
                      }
                      // Duyệt qua danh sách document của 'topics'
                      List<DocumentSnapshot> topics = snapshot.data!.docs;
                      List<DocumentSnapshot> sortedTopics = [];
                      for (int i = 0; i < topics.length; i++) {
                        // Nếu document 'access' tồn tại
                        if (accessSnapshotList.data![i].exists) {
                          sortedTopics.add(topics[i]);
                        }
                      }
                      // Sắp xếp các topic theo yêu cầu
                      sortedTopics = sortTopicsByTime(sortedTopics, _sortBy);
                      if (sortedTopics.isEmpty) {
                        return const Center(
                          child: Text('No topics created by the user.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: sortedTopics.length,
                        itemBuilder: (BuildContext context, int index) {
                          DocumentSnapshot document = sortedTopics[index];
                          String topicId = document.id;
                          String topicName = document['name'];
                          String text = document['text'];
                          int numberOfWords = document['numberOfWords'];
                          bool isPrivate = document['isPrivate'];
                          String userId = document['createdBy'];
                          DateTime timeCreated =
                              (document['timeCreated'] as Timestamp).toDate();
                          DateTime lastAccess =
                              (document['lastAccess'] as Timestamp).toDate();
                          int accessPeople = document['accessPeople'];

                          return TopicItem(
                            topicId: topicId,
                            topicName: topicName,
                            text: text,
                            numberOfWords: numberOfWords,
                            isPrivate: isPrivate,
                            userId: userId,
                            timeCreated: timeCreated,
                            lastAccess: lastAccess,
                            accessPeople: accessPeople,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
