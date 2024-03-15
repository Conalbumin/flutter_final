import 'package:flutter/material.dart';
import 'firebase_study_page.dart';
import 'package:quizlet_final_flutter/study/topic_tab.dart';

import 'folder_tab.dart'; // Import your Firebase functions here

class StudyPage extends StatefulWidget {
  const StudyPage({Key? key}) : super(key: key);

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: null,
        body: Column(
          children: [
            const Divider(
              indent: 25.0,
              endIndent: 25.0,
              height: 0.8,
            ),
            Container(
              color: Colors.blue,
              child: const TabBar(
                unselectedLabelColor: Colors.blueGrey,
                labelColor: Colors.white,
                tabs: [
                  Tab(
                    icon: Icon(Icons.chat_bubble),
                    text: "Topic",
                  ),
                  Tab(
                    icon: Icon(Icons.folder),
                    text: "Folder",
                  )
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  TopicTab(),
                  FolderTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
