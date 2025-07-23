class SupabaseConfig {
  // Environment variables for secure deployment
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jhgdyioswmeokpunktjb.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY', 
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpoZ2R5aW9zd21lb2twdW5rdGpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyNjQ0MzAsImV4cCI6MjA2ODg0MDQzMH0.0apN2_iAPEIjNs_YjeHBgixaP_9doxTGRchmgPRJPVE',
  );
  
  // Database Tables
  static const String userProfilesTable = 'user_profiles';
  static const String chatSessionsTable = 'chat_sessions';
  static const String questionResultsTable = 'question_results';
  static const String teacherStudentRelationshipsTable = 'teacher_student_relationships';
  static const String teacherClassesTable = 'teacher_classes';
}