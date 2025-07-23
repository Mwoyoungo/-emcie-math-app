class SupabaseConfig {
  // TODO: Replace these with your actual Supabase project credentials
  // You can find these at: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api
  
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
  
  // Example:
  // static const String supabaseUrl = 'https://xyzabc123.supabase.co';
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  // Database Tables
  static const String userProfilesTable = 'user_profiles';
  static const String chatSessionsTable = 'chat_sessions';
  static const String questionResultsTable = 'question_results';
  static const String teacherStudentRelationshipsTable = 'teacher_student_relationships';
  static const String teacherClassesTable = 'teacher_classes';
}

/* 
SETUP INSTRUCTIONS:

1. Create a Supabase project at https://supabase.com
2. Go to Project Settings > API
3. Copy your Project URL and anon key
4. Copy this file to supabase_config.dart and replace the placeholder values
5. Run the SQL schema provided below to create tables

DATABASE SCHEMA:

-- Enable RLS (Row Level Security)
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- User Profiles Table with Role Support
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student',  -- 'student', 'teacher', 'admin'
    grade TEXT,  -- "10", "11", "12" (NULL for teachers)
    school_name TEXT,  -- Optional for teachers/students
    subject_specialization TEXT,  -- For teachers: "Mathematics", "Physics", etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_role CHECK (role IN ('student', 'teacher', 'admin')),
    CONSTRAINT student_needs_grade CHECK (
        (role = 'student' AND grade IS NOT NULL) OR 
        (role != 'student')
    )
);

-- Chat Sessions Table  
CREATE TABLE chat_sessions (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    topic_title TEXT NOT NULL,
    grade TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_active_at TIMESTAMP WITH TIME ZONE NOT NULL,
    messages JSONB DEFAULT '[]'::JSONB,
    metadata JSONB DEFAULT '{}'::JSONB
);

-- Question Results Table
CREATE TABLE question_results (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    topic_title TEXT NOT NULL,
    question_text TEXT NOT NULL,
    user_answer TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    execution_id TEXT NOT NULL
);

-- Row Level Security Policies
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own sessions" ON chat_sessions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own performance" ON question_results
    FOR ALL USING (auth.uid() = user_id);

-- Teacher-Student Relationships Table
CREATE TABLE teacher_student_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    student_id UUID REFERENCES auth.users(id) NOT NULL,
    relationship_type TEXT NOT NULL DEFAULT 'assigned',  -- 'assigned', 'requested', 'approved'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),  -- Who created the relationship
    
    -- Ensure unique relationships
    UNIQUE(teacher_id, student_id),
    
    -- Ensure roles are correct
    CONSTRAINT valid_teacher CHECK (
        EXISTS (SELECT 1 FROM user_profiles WHERE id = teacher_id AND role = 'teacher')
    ),
    CONSTRAINT valid_student CHECK (
        EXISTS (SELECT 1 FROM user_profiles WHERE id = student_id AND role = 'student')
    )
);

-- Teacher Classes Table (Future Enhancement)
CREATE TABLE teacher_classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    class_name TEXT NOT NULL,
    grade_level TEXT NOT NULL,
    subject TEXT NOT NULL DEFAULT 'Mathematics',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(teacher_id, class_name)
);

CREATE TABLE class_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES teacher_classes(id) NOT NULL,
    student_id UUID REFERENCES auth.users(id) NOT NULL,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(class_id, student_id)
);

-- Updated Row Level Security Policies for Role-based Access
-- Teachers can view performance of their assigned students
CREATE POLICY "Teachers can view assigned students performance" ON question_results
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM teacher_student_relationships tsr 
            WHERE tsr.teacher_id = auth.uid() 
            AND tsr.student_id = question_results.user_id
            AND tsr.relationship_type = 'approved'
        )
    );

-- Teachers can view sessions of their assigned students  
CREATE POLICY "Teachers can view assigned students sessions" ON chat_sessions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM teacher_student_relationships tsr 
            WHERE tsr.teacher_id = auth.uid() 
            AND tsr.student_id = chat_sessions.user_id
            AND tsr.relationship_type = 'approved'
        )
    );

-- Teacher-Student relationship management
CREATE POLICY "Users can view their relationships" ON teacher_student_relationships
    FOR SELECT USING (auth.uid() = teacher_id OR auth.uid() = student_id);

CREATE POLICY "Teachers can create relationships" ON teacher_student_relationships
    FOR INSERT WITH CHECK (
        auth.uid() = teacher_id AND 
        EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'teacher')
    );

-- Class management (future)
CREATE POLICY "Teachers can manage their classes" ON teacher_classes
    FOR ALL USING (auth.uid() = teacher_id);

CREATE POLICY "Teachers can manage class enrollments" ON class_enrollments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM teacher_classes tc 
            WHERE tc.id = class_enrollments.class_id 
            AND tc.teacher_id = auth.uid()
        )
    );

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE chat_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE question_results;
ALTER PUBLICATION supabase_realtime ADD TABLE teacher_student_relationships;
*/