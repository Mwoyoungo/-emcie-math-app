import 'package:flutter/material.dart';
import 'components/profile_header.dart';
import 'components/settings_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Profile",
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              
              // Profile Header
              const ProfileHeader(),
              
              const SizedBox(height: 24),
              
              // Settings Sections
              const SettingsSection(),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}