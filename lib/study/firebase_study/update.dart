import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../word/word_data_for_edit.dart';

Future<void> updateTopic(
    String topicId, String newTopicName, String newDescription) async {
  try {
    await FirebaseFirestore.instance.collection('topics').doc(topicId).update({
      'name': newTopicName,
      'text': newDescription,
    });
    print('Topic updated successfully');
  } catch (e) {
    print('Error updating topic: $e');
  }
}

Future<void> updateFolder(
    String folderId, String newFolderName, String newDescription) async {
  try {
    await FirebaseFirestore.instance
        .collection('folders')
        .doc(folderId)
        .update({
      'name': newFolderName,
      'text': newDescription,
    });
    print('Folder updated successfully');
  } catch (e) {
    print('Error updating folder: $e');
  }
}

Future<void> updateWords(String topicId, List<WordData> wordsData) async {
  try {
    for (var wordData in wordsData) {
      String wordId = wordData.id; // Access id directly
      await FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('words')
          .doc(wordId)
          .set({
        'word': wordData.word,
        'definition': wordData.definition,
        'status': wordData.status,
        'isFavorited': wordData.isFavorited,
      });
    }
    print('Words updated successfully');
  } catch (e) {
    print('Error updating words: $e');
  }
}


Future<void> updateWordStatus(
    String topicId, String wordId, String newStatus) async {
  try {
    await FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('words')
        .doc(wordId)
        .update({'status': newStatus});
    print('Word status updated successfully');
  } catch (e) {
    print('Error updating word status: $e');
  }
}

Future<void> updateWordIsFavorited(
    String topicId, String wordId, bool newIsFavorited) async {
  try {
    await FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('words')
        .doc(wordId)
        .update({'isFavorited': newIsFavorited});
    print('Word status updated successfully');
  } catch (e) {
    print('Error updating word status: $e');
  }
}