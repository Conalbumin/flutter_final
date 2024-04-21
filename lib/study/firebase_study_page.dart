import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> addTopic(
    String topicName, String text, int numberOfWords, bool isPrivate) async {
  try {
    String userUid =
        FirebaseAuth.instance.currentUser!.uid; // Get current user's UID
    await FirebaseFirestore.instance.collection('topics').add({
      'name': topicName,
      'text': text,
      'numberOfWords': numberOfWords,
      'isPrivate': isPrivate,
      'createdBy': userUid, // Store user UID along with the topic
    });
  } catch (e) {
    print('Error adding topic: $e');
  }
}

Future<void> addFolder(String folderName, String text) async {
  try {
    String userUid =
        FirebaseAuth.instance.currentUser!.uid; // Get current user's UID
    await FirebaseFirestore.instance.collection('folders').add({
      'name': folderName,
      'text': text,
      'createdBy': userUid,
    });
  } catch (e) {
    print('Error adding folder: $e');
  }
}

Future<void> addWord(
    String topicId, List<Map<String, String>> wordsData) async {
  try {
    int totalWordsAdded = wordsData.length;

    for (var wordData in wordsData) {
      String status = wordData['status'] ?? 'unLearned';
      bool isFavorited = false;

      await FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('words')
          .add({
        'word': wordData['word'],
        'definition': wordData['definition'],
        'status': status,
        'isFavorited': isFavorited
      });
    }

    // Increment the numberOfWords field in the topic document by the total number of words added
    await FirebaseFirestore.instance.collection('topics').doc(topicId).update({
      'numberOfWords': FieldValue.increment(totalWordsAdded),
    });

    print('Words added successfully');
  } catch (e) {
    print('Error adding words: $e');
  }
}

Future<void> addTopicWithWords(String topicName, String text, bool isPrivate,
    List<Map<String, String>> wordsData) async {
  try {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference topicRef =
        await FirebaseFirestore.instance.collection('topics').add({
      'name': topicName,
      'text': text,
      'numberOfWords': wordsData.length,
      'isPrivate': isPrivate,
      'createdBy': userUid
    });

    String topicId = topicRef.id;

    for (var wordData in wordsData) {
      String status = wordData['status'] ?? 'unLearned';
      bool isFavorited = false;

      await FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('words')
          .add({
        'word': wordData['word'],
        'definition': wordData['definition'],
        'status': status,
        'isFavorited': isFavorited
      });
    }

    print('Topic with words added successfully');
  } catch (e) {
    print('Error adding topic with words: $e');
  }
}

Future<void> addTopicToFolder(String topicId, String folderId) async {
  try {
    // Fetch topic details
    DocumentSnapshot topicSnapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .get();
    Map<String, dynamic> topicData =
        topicSnapshot.data() as Map<String, dynamic>;

    // Fetch topic words
    QuerySnapshot wordsSnapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('words')
        .get();

    // Create a batch to perform multiple operations atomically
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Add topic details to the folder
    DocumentReference topicRef = FirebaseFirestore.instance
        .collection('folders')
        .doc(folderId)
        .collection('topics')
        .doc(topicId);
    batch.set(topicRef, {
      // 'topicId': topicId,
      'name': topicData['name'],
      'text': topicData['text'],
      'numberOfWords': topicData['numberOfWords'],
      'isPrivate': topicData['isPrivate'],
      'createdBy': topicData['createdBy']
    });

    // Add topic words to the folder
    wordsSnapshot.docs.forEach((wordDoc) {
      batch.set(topicRef.collection('words').doc(wordDoc.id), wordDoc.data());
    });

    // Commit the batch
    await batch.commit();

    print('Topic and related data added to folder successfully');
  } catch (e) {
    print('Error adding topic to folder: $e');
  }
}

Stream<QuerySnapshot> getTopics() {
  String userUid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('topics')
      .where('isPrivate', isEqualTo: false)
      .where('createdBy', isEqualTo: userUid)
      .snapshots();
}

Stream<QuerySnapshot> getTopicsInFolder(String folderId) {
  String userUid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('folders')
      .doc(folderId)
      .collection('topics')
      .where('isPrivate', isEqualTo: false)
      .where('createdBy', isEqualTo: userUid)
      .snapshots();
}

Future<List<DocumentSnapshot>> fetchWords(String topicId) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('words')
        .get();
    return querySnapshot.docs;
  } catch (e) {
    print('Error fetching words: $e');
    rethrow;
  }
}

Future<List<DocumentSnapshot>> fetchTopics(String folderId) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('folders')
        .doc(folderId)
        .collection('topics')
        .get();
    return querySnapshot.docs;
  } catch (e) {
    print('Error fetching topics: $e');
    rethrow;
  }
}

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

Future<void> setPrivateTopic(String topicId, bool isPrivate) async {
  try {
    await FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .update({'isPrivate': isPrivate});
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

Future<void> updateWords(
    String topicId, List<Map<String, String>> wordsData) async {
  try {
    for (var wordData in wordsData) {
      String wordId = wordData['id'] ?? '';
      await FirebaseFirestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('words')
          .doc(wordId)
          .set({
        'word': wordData['word'],
        'definition': wordData['definition'],
        'status': wordData['status'],
        'isFavorited': wordData['isFavorited']
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

void deleteFolder(BuildContext context, String folderId) {
  try {
    // Delete all topics within the folder and their associated words
    FirebaseFirestore.instance
        .collection('folders')
        .doc(folderId)
        .collection('topics')
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((topicDoc) {
        // Delete all words associated with the topic
        FirebaseFirestore.instance
            .collection('topics')
            .doc(topicDoc.id)
            .collection('words')
            .get()
            .then((wordsSnapshot) {
          wordsSnapshot.docs.forEach((wordDoc) {
            wordDoc.reference.delete();
          });
        }).catchError((error) {
          print('Error fetching words for deletion: $error');
        });

        // Delete the topic document
        topicDoc.reference.delete();
      });

      // Delete the topics collection within the folder
      FirebaseFirestore.instance
          .collection('folders')
          .doc(folderId)
          .collection('topics')
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      }).catchError((error) {
        print('Error deleting topics collection: $error');
      });

      // Delete the folder itself
      FirebaseFirestore.instance
          .collection('folders')
          .doc(folderId)
          .delete()
          .then((_) {
        print('Folder and related topics deleted successfully');
        Navigator.of(context).pop();
      }).catchError((error) {
        print('Error deleting folder: $error');
      });
    }).catchError((error) {
      print('Error fetching topics for deletion: $error');
    });
  } catch (e) {
    print('Error: $e');
  }
}

void deleteTopic(BuildContext context, String topicId) {
  try {
    // Create a batch to perform multiple delete operations atomically
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Delete the topic document
    DocumentReference topicRef =
        FirebaseFirestore.instance.collection('topics').doc(topicId);
    batch.delete(topicRef);

    // Delete all words associated with the topic
    FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('words')
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((wordDoc) {
        batch.delete(wordDoc.reference);
      });

      // Commit the batch
      batch.commit().then((_) {
        print('Topic and associated words deleted successfully');
        Navigator.of(context).pop();
      }).catchError((error) {
        print('Error committing batch delete: $error');
      });
      Navigator.of(context).pop();
    }).catchError((error) {
      print('Error fetching words for deletion: $error');
    });
  } catch (e) {
    print('Error: $e');
  }
}

void deleteTopicInFolder(
    BuildContext context, String topicId, String folderId) {
  try {
    // Fetch the reference of the topic in the folder's collection
    DocumentReference topicRef = FirebaseFirestore.instance
        .collection('folders')
        .doc(folderId)
        .collection('topics')
        .doc(topicId);

    // Delete the reference of the topic from the folder
    topicRef.delete().then((_) {
      print('Topic removed from folder successfully');
    }).catchError((error) {
      print('Error removing topic from folder: $error');
    });
  } catch (e) {
    print('Error: $e');
  }
}

void deleteWord(BuildContext context, String topicId, String wordId) {
  try {
    FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('words')
        .doc(wordId)
        .delete()
        .then((_) {
      // Update the number of words in the topic document
      FirebaseFirestore.instance.collection('topics').doc(topicId).update({
        'numberOfWords': FieldValue.increment(-1),
      }).then((_) {
        print('Number of words updated successfully');
        Navigator.of(context).pop();
      }).catchError((error) {
        print('Error updating number of words: $error');
      });
    }).catchError((error) {
      print('Error deleting word: $error');
    });
  } catch (e) {
    print('Error: $e');
  }
}
