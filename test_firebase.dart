import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🔥 Firebase Connection Test Starting...\n');
  
  try {
    // Initialize Firebase
    print('📱 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!\n');
    
    // Get Firestore instance
    final firestore = FirebaseFirestore.instance;
    print('📊 Getting Firestore instance...');
    print('✅ Firestore instance created!\n');
    
    // Test connection by reading a collection
    print('🔍 Testing Firestore connection...');
    print('   Project ID: countx-f6b37');
    
    // Try to read counters collection
    final countersSnapshot = await firestore
        .collection('counters')
        .limit(1)
        .get()
        .timeout(Duration(seconds: 10));
    
    print('✅ Successfully connected to Firestore!');
    print('📦 Counters collection exists');
    print('📄 Documents found: ${countersSnapshot.docs.length}');
    
    if (countersSnapshot.docs.isNotEmpty) {
      print('📋 Sample data: ${countersSnapshot.docs.first.data()}');
    }
    
    // Try to read entries collection
    final entriesSnapshot = await firestore
        .collection('counter_entries')
        .limit(1)
        .get()
        .timeout(Duration(seconds: 10));
    
    print('📦 Counter entries collection exists');
    print('📄 Documents found: ${entriesSnapshot.docs.length}');
    
    print('\n🎉 DATABASE CONNECTION SUCCESSFUL! 🎉');
    print('Your Firebase Firestore is properly connected.\n');
    
  } catch (e, stackTrace) {
    print('\n❌ ERROR: Firebase connection failed!');
    print('Error details: $e');
    print('\nStack trace:');
    print(stackTrace);
    print('\n⚠️ Possible issues:');
    print('   1. Check your internet connection');
    print('   2. Verify Firebase project configuration');
    print('   3. Check Firestore security rules');
    print('   4. Ensure Firebase project exists at: https://console.firebase.google.com');
  }
}
