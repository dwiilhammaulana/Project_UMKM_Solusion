import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _runSupabaseDebugTest = bool.fromEnvironment('RUN_SUPABASE_DEBUG_TEST');

void logMessage(Object? message) => stdout.writeln(message);

Map<String, String> loadEnvFile(String path) {
  final env = <String, String>{};

  for (final line in File(path).readAsLinesSync()) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
      continue;
    }

    final separatorIndex = trimmedLine.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    final key = trimmedLine.substring(0, separatorIndex).trim();
    final value = trimmedLine.substring(separatorIndex + 1).trim();
    env[key] = value;
  }

  return env;
}

void main() {
  test('Debug Supabase db and triggers', () async {
    final env = loadEnvFile('.env');
    final supabaseUrl = env['SUPABASE_URL']!;
    final supabaseAnonKey = env['SUPABASE_ANON_KEY']!;

    logMessage('Connecting to Supabase: $supabaseUrl');

    final client = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    final email = 'test${DateTime.now().millisecondsSinceEpoch}@gmail.com';
    final password = 'password123';
    logMessage('Signing up temporary user: $email');

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
        logMessage('Sign up failed: User is null');
        return;
      }
      logMessage('Signed up successfully. User ID: ${user.id}');
      logMessage('User Metadata: ${user.userMetadata}');

      // Wait a bit for the trigger to run
      await Future.delayed(const Duration(seconds: 2));

      // Fetch the created profile
      final profile = await client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        logMessage('Profile not found in public.profiles table!');
      } else {
        logMessage('Created Profile:');
        logMessage('id: ${profile['id']}');
        logMessage('email: ${profile['email']}');
        logMessage('full_name: ${profile['full_name']}');
        logMessage('nik: ${profile['nik']}');
        logMessage('phone: ${profile['phone']}');
        logMessage('role: ${profile['role']}');
        logMessage('store_owner: ${profile['store_owner_user_id']}');
      }

      // Try updating nik and phone of the profile
      logMessage('Attempting to update profile directly...');
      await client.from('profiles').update({
        'nik': '9876543210987654',
        'phone': '08987654321',
      }).eq('id', user.id);

      final updatedProfile = await client
          .from('profiles')
          .select('nik, phone')
          .eq('id', user.id)
          .single();
      logMessage('Updated Profile directly:');
      logMessage('nik: ${updatedProfile['nik']}');
      logMessage('phone: ${updatedProfile['phone']}');
    } catch (e, stack) {
      logMessage('Error during test: $e');
      logMessage(stack);
      rethrow;
    }
  }, skip: !_runSupabaseDebugTest);
}
