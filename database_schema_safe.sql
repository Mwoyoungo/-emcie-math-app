-- Emcie App Database Schema (Safe Version)
-- Run this SQL in your Supabase SQL Editor

-- 1. User Profiles Table with Role Support
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

-- 2. Chat Sessions Table
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

-- 3. Question Results Table
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

-- 4. Teacher-Student Relationships Table
CREATE TABLE teacher_student_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    student_id UUID REFERENCES auth.users(id) NOT NULL,
    relationship_type TEXT NOT NULL DEFAULT 'assigned',  -- 'assigned', 'requested', 'approved'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),  -- Who created the relationship
    
    -- Ensure unique relationships
    UNIQUE(teacher_id, student_id)
);

-- 5. Teacher Classes Table (Future Enhancement)
CREATE TABLE teacher_classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    class_name TEXT NOT NULL,
    grade_level TEXT NOT NULL,
    subject TEXT NOT NULL DEFAULT 'Mathematics',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(teacher_id, class_name)
);

-- 6. Class Enrollments Table
CREATE TABLE class_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES teacher_classes(id) NOT NULL,
    student_id UUID REFERENCES auth.users(id) NOT NULL,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(class_id, student_id)
);

-- Row Level Security Policies

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_student_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_enrollments ENABLE ROW LEVEL SECURITY;

-- Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Students can only access their own chat sessions
CREATE POLICY "Students can view own sessions" ON chat_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Students can only see their own performance data
CREATE POLICY "Students can view own performance" ON question_results
    FOR ALL USING (auth.uid() = user_id);

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

-- Performance Indexes for better query performance
CREATE INDEX idx_chat_sessions_user_active ON chat_sessions(user_id, last_active_at DESC);
CREATE INDEX idx_question_results_user_topic ON question_results(user_id, topic_title);
CREATE INDEX idx_question_results_timestamp ON question_results(user_id, timestamp DESC);
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_teacher_relationships_teacher ON teacher_student_relationships(teacher_id);
CREATE INDEX idx_teacher_relationships_student ON teacher_student_relationships(student_id);

-- Enable realtime subscriptions (this is safe to run)
ALTER PUBLICATION supabase_realtime ADD TABLE chat_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE question_results;
ALTER PUBLICATION supabase_realtime ADD TABLE teacher_student_relationships;

-- Success message
SELECT 'Emcie database schema created successfully! 🎉' as status;