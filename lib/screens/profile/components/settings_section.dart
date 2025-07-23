import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSettingsGroup(
          "Account Settings",
          [
            _buildSettingsItem(
              icon: Icons.person_outline,
              title: "Edit Profile",
              subtitle: "Update your personal information",
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.school_outlined,
              title: "Grade Level",
              subtitle: "Grade 11",
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.email_outlined,
              title: "Email",
              subtitle: "sarah.johnson@student.edu",
              onTap: () {},
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildSettingsGroup(
          "Learning Preferences",
          [
            _buildSettingsItem(
              icon: Icons.notifications_outlined,
              title: "Study Reminders",
              subtitle: "Daily at 4:00 PM",
              onTap: () {},
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: const Color(0xFF7553F6),
              ),
            ),
            _buildSettingsItem(
              icon: Icons.dark_mode_outlined,
              title: "Dark Mode",
              subtitle: "Use dark theme",
              onTap: () {},
              trailing: Switch(
                value: false,
                onChanged: (value) {},
                activeColor: const Color(0xFF7553F6),
              ),
            ),
            _buildSettingsItem(
              icon: Icons.language_outlined,
              title: "Language",
              subtitle: "English",
              onTap: () {},
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildSettingsGroup(
          "Support",
          [
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: "Help & Support",
              subtitle: "Get help with using Emcie",
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.feedback_outlined,
              title: "Send Feedback",
              subtitle: "Help us improve Emcie",
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: "About Emcie",
              subtitle: "Version 1.0.0",
              onTap: () {},
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildSettingsGroup(
          "Account",
          [
            _buildSettingsItem(
              icon: Icons.logout,
              title: "Sign Out",
              subtitle: "Sign out of your account",
              onTap: () {
                _showSignOutDialog(context);
              },
              textColor: const Color(0xFFFF6B6B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: "Poppins",
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (textColor ?? const Color(0xFF7553F6)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: textColor ?? const Color(0xFF7553F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? 
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Sign Out",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text("Are you sure you want to sign out of your account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Add sign out logic here
              },
              child: const Text(
                "Sign Out",
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
          ],
        );
      },
    );
  }
}