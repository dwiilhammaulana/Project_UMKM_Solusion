import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() {
  test('Debug Supabase db and triggers', () async {
    // Load env variables manually
    final lines = File('.env').readAsLinesSync();
    final env = <String, String>{};
    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length >= 2) {
        env[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }
    final supabaseUrl = env['SUPABASE_URL']!;
    final supabaseAnonKey = env['SUPABASE_ANON_KEY']!;

    print('Connecting to Supabase: $supabaseUrl');

    final client = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    final email = 'test${DateTime.now().millisecondsSinceEpoch}@gmail.com';
    final password = 'password123';
    print('Signing up temporary user: $email');

    try {
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': 'Test User',
          'nik': '1234567890123456',
          'phone': '08123456789',
          'role': 'admin',
        },
      );
      final user = authResponse.user;
      if (user == null) {
        print('Sign up failed: User is null');
        return;
      }
      print('Signed up successfully. User ID: ${user.id}');
      print('User Metadata: ${user.userMetadata}');

      // Wait a bit for the trigger to run
      await Future.delayed(const Duration(seconds: 2));

      // Fetch the created profile
      final profile = await client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        print('Profile not found in public.profiles table!');
      } else {
        print('Created Profile:');
        print('id: ${profile['id']}');
        print('email: ${profile['email']}');
        print('full_name: ${profile['full_name']}');
        print('nik: ${profile['nik']}');
        print('phone: ${profile['phone']}');
        print('role: ${profile['role']}');
        print('store_owner: ${profile['store_owner_user_id']}');
      }

      // Try updating nik and phone of the profile
      print('Attempting to update profile directly...');
      await client.from('profiles').update({
        'nik': '9876543210987654',
        'phone': '08987654321',
      }).eq('id', user.id);

      final updatedProfile = await client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();
      print('Updated Profile directly:');
      print('nik: ${updatedProfile['nik']}');
      print('phone: ${updatedProfile['phone']}');
    } catch (e, stack) {
      print('Error during test: $e');
      print(stack);
    }
  });
}
