// File konfigurasi manual untuk Yosef Examination System
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYyKlu_nnHR7hdP_92SGpg4Dj_XgA2qJ8',
    appId: '1:671244452078:web:cc6f429ef644f2490733ff',
    messagingSenderId: '671244452078',
    projectId: 'yosef-exam-system',
    authDomain: 'yosef-exam-system.firebaseapp.com',
    storageBucket: 'yosef-exam-system.firebasestorage.app',
  );
}
