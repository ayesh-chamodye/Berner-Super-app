import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageDiagnostic {
  /// Test if profile-pictures bucket exists and is accessible
  static Future<Map<String, dynamic>> testBucketAccess() async {
    try {
      print('🔍 StorageDiagnostic: Testing bucket access...');

      final client = SupabaseService.client;

      // Test 1: List all buckets
      print('🔍 Test 1: Listing all buckets...');
      final buckets = await client.storage.listBuckets();
      print('✅ Found ${buckets.length} buckets');

      bool profilePicturesBucketExists = false;
      for (final bucket in buckets) {
        print('   - ${bucket.id} (public: ${bucket.public})');
        if (bucket.id == 'profile-pictures') {
          profilePicturesBucketExists = true;
        }
      }

      if (!profilePicturesBucketExists) {
        print('❌ ERROR: "profile-pictures" bucket NOT FOUND!');
        print('⚠️  You need to create it in Supabase Dashboard');
        return {
          'success': false,
          'error': 'Bucket "profile-pictures" does not exist',
          'buckets': buckets.map((b) => b.id).toList(),
        };
      }

      print('✅ "profile-pictures" bucket found!');

      // Test 2: Try to list files in bucket
      print('🔍 Test 2: Listing files in profile-pictures bucket...');
      try {
        final files = await client.storage.from('profile-pictures').list(
          path: 'profile_pictures',
        );
        print('✅ Found ${files.length} files in bucket');
        for (final file in files) {
          print('   - ${file.name}');
        }
      } catch (listError) {
        print('⚠️  Could not list files: $listError');
      }

      // Test 3: Check bucket permissions
      print('🔍 Test 3: Checking bucket configuration...');
      final profileBucket = buckets.firstWhere((b) => b.id == 'profile-pictures');
      print('   - Public: ${profileBucket.public}');
      print('   - File size limit: ${profileBucket.fileSizeLimit ?? "None"}');

      if (!profileBucket.public) {
        print('⚠️  WARNING: Bucket is not public!');
        print('   You may have issues accessing uploaded images');
      }

      return {
        'success': true,
        'bucket_exists': true,
        'is_public': profileBucket.public,
        'file_count': 0,
      };

    } catch (e, stackTrace) {
      print('❌ StorageDiagnostic: Error testing bucket access');
      print('   Error: $e');
      print('   Stack: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test upload functionality
  static Future<bool> testUpload() async {
    try {
      print('🔍 StorageDiagnostic: Testing upload...');

      final client = SupabaseService.client;

      // Create a tiny test image (1x1 pixel PNG)
      final testImageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);

      final testFilePath = 'profile_pictures/test_upload.png';

      print('🔍 Uploading test image to: $testFilePath');

      await client.storage.from('profile-pictures').uploadBinary(
        testFilePath,
        testImageBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/png',
        ),
      );

      print('✅ Upload successful!');

      // Get public URL
      final publicUrl = client.storage.from('profile-pictures').getPublicUrl(testFilePath);
      print('✅ Public URL: $publicUrl');

      // Try to delete test file
      try {
        await client.storage.from('profile-pictures').remove([testFilePath]);
        print('✅ Test file deleted');
      } catch (deleteError) {
        print('⚠️  Could not delete test file: $deleteError');
      }

      return true;

    } catch (e, stackTrace) {
      print('❌ StorageDiagnostic: Upload test failed');
      print('   Error: $e');
      print('   Stack: $stackTrace');

      if (e.toString().contains('bucket')) {
        print('');
        print('🔴 BUCKET NOT FOUND ERROR!');
        print('📝 Follow these steps:');
        print('   1. Go to https://app.supabase.com');
        print('   2. Select your project');
        print('   3. Click Storage in sidebar');
        print('   4. Click "New Bucket"');
        print('   5. Name: profile-pictures');
        print('   6. Check "Public bucket"');
        print('   7. Click Create');
        print('');
      }

      return false;
    }
  }
}
