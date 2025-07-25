-- Emcie App Complete Database Schema
-- Run this SQL in your Supabase SQL Editor
-- Includes: Core tables, Class System, Functions, Triggers, RLS Policies, Indexes

-- Enable RLS (Row Level Security)
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- 1. User Profiles Table with Role Support
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student',  -- 'student', 'teacher', 'admin'
    grade TEXT,  -- "8", "9", "10", "11", "12" (NULL for teachers)
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

-- Enable RLS on user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

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

-- Enable RLS on chat_sessions
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;

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

-- Enable RLS on question_results
ALTER TABLE question_results ENABLE ROW LEVEL SECURITY;

-- 4. Student Creation Requests Table
CREATE TABLE student_creation_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    student_email TEXT NOT NULL,
    student_full_name TEXT NOT NULL,
    student_grade TEXT NOT NULL,
    temporary_password TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'completed', 'failed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT valid_status CHECK (status IN ('pending', 'completed', 'failed')),
    CONSTRAINT valid_grade CHECK (student_grade IN ('8', '9', '10', '11', '12'))
);

-- Enable RLS on student_creation_requests
ALTER TABLE student_creation_requests ENABLE ROW LEVEL SECURITY;

-- 5. Upsertion Records Table (for vector embeddings)
CREATE TABLE upsertion_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    topic_title TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, topic_title, content_hash)
);

-- Enable RLS on upsertion_records
ALTER TABLE upsertion_records ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CLASS SYSTEM TABLES
-- ============================================================================

-- 6. Classes Table (Class System)
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    subject TEXT NOT NULL,
    grade_level TEXT NOT NULL,
    class_code TEXT UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_subject CHECK (subject IN (
        'Mathematics', 'Physical Sciences', 'Life Sciences', 'Geography',
        'History', 'English', 'Afrikaans', 'Business Studies',
        'Economics', 'Accounting', 'Information Technology', 'Other'
    )),
    CONSTRAINT valid_grade_level CHECK (grade_level IN ('8', '9', '10', '11', '12', 'Mixed'))
);

-- Enable RLS on classes
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- 7. Class Enrollments Table
CREATE TABLE class_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
    student_id UUID REFERENCES auth.users(id) NOT NULL,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Prevent duplicate enrollments
    UNIQUE(class_id, student_id)
);

-- Enable RLS on class_enrollments
ALTER TABLE class_enrollments ENABLE ROW LEVEL SECURITY;

-- 8. Shared Chats Table
CREATE TABLE shared_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES auth.users(id) NOT NULL,
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    class_id UUID REFERENCES classes(id),
    chat_data JSONB NOT NULL,
    shared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure valid roles
    CONSTRAINT valid_student_role CHECK (
        EXISTS (SELECT 1 FROM user_profiles WHERE id = student_id AND role = 'student')
    ),
    CONSTRAINT valid_teacher_role CHECK (
        EXISTS (SELECT 1 FROM user_profiles WHERE id = teacher_id AND role = 'teacher')
    )
);

-- Enable RLS on shared_chats
ALTER TABLE shared_chats ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to check if user is a teacher
CREATE OR REPLACE FUNCTION is_user_teacher(user_uuid UUID)
RETURNS BOOLEAN
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = user_uuid AND role = 'teacher'
    );
END;
$$;

-- Function to check if user is a student
CREATE OR REPLACE FUNCTION is_user_student(user_uuid UUID)
RETURNS BOOLEAN
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_profiles 
        WHERE id = user_uuid AND role = 'student'
    );
END;
$$;

-- Function to generate unique class codes
CREATE OR REPLACE FUNCTION generate_class_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a 6-character alphanumeric code
        new_code := upper(substr(md5(random()::text), 1, 6));
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM classes WHERE class_code = new_code) INTO code_exists;
        
        -- If code doesn't exist, return it
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$;

-- Function to set class code before insert
CREATE OR REPLACE FUNCTION set_class_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.class_code IS NULL OR NEW.class_code = '' THEN
        NEW.class_code := generate_class_code();
    END IF;
    RETURN NEW;
END;
$$;

-- Function for students to join class by code
CREATE OR REPLACE FUNCTION join_class_by_code(p_class_code TEXT)
RETURNS JSON
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_class_id UUID;
    v_student_id UUID;
    v_enrollment_id UUID;
BEGIN
    -- Get current user ID
    v_student_id := auth.uid();
    
    -- Verify user is a student
    IF NOT is_user_student(v_student_id) THEN
        RETURN json_build_object('success', false, 'error', 'Only students can join classes');
    END IF;
    
    -- Find the class by code
    SELECT id INTO v_class_id
    FROM classes
    WHERE class_code = p_class_code AND is_active = true;
    
    IF v_class_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Invalid class code');
    END IF;
    
    -- Check if already enrolled
    IF EXISTS (SELECT 1 FROM class_enrollments WHERE class_id = v_class_id AND student_id = v_student_id) THEN
        RETURN json_build_object('success', false, 'error', 'Already enrolled in this class');
    END IF;
    
    -- Create enrollment
    INSERT INTO class_enrollments (class_id, student_id)
    VALUES (v_class_id, v_student_id)
    RETURNING id INTO v_enrollment_id;
    
    RETURN json_build_object(
        'success', true,
        'enrollment_id', v_enrollment_id,
        'class_id', v_class_id
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Trigger function to validate student creation requests
CREATE OR REPLACE FUNCTION validate_student_creation_teacher()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verify the teacher_id is actually a teacher
    IF NOT is_user_teacher(NEW.teacher_id) THEN
        RAISE EXCEPTION 'Only teachers can create student accounts';
    END IF;
    
    RETURN NEW;
END;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to auto-generate class codes
CREATE TRIGGER trigger_set_class_code
    BEFORE INSERT ON classes
    FOR EACH ROW
    EXECUTE FUNCTION set_class_code();

-- Trigger to validate student creation requests
CREATE TRIGGER trigger_validate_student_creation_teacher
    BEFORE INSERT ON student_creation_requests
    FOR EACH ROW
    EXECUTE FUNCTION validate_student_creation_teacher();

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- User Profiles Policies
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Chat Sessions Policies
CREATE POLICY "Users can manage own chat sessions" ON chat_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Question Results Policies
CREATE POLICY "Users can manage own question results" ON question_results
    FOR ALL USING (auth.uid() = user_id);

-- Student Creation Requests Policies
CREATE POLICY "Teachers can manage their student creation requests" ON student_creation_requests
    FOR ALL USING (auth.uid() = teacher_id);

-- Upsertion Records Policies
CREATE POLICY "Users can manage own upsertion records" ON upsertion_records
    FOR ALL USING (auth.uid() = user_id);

-- Classes Policies
CREATE POLICY "Teachers can manage their own classes" ON classes
    FOR ALL USING (auth.uid() = teacher_id);

CREATE POLICY "Students can view classes they are enrolled in" ON classes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM class_enrollments ce
            WHERE ce.class_id = classes.id
            AND ce.student_id = auth.uid()
            AND ce.is_active = true
        )
    );

-- Class Enrollments Policies
CREATE POLICY "Teachers can manage enrollments for their classes" ON class_enrollments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM classes c
            WHERE c.id = class_enrollments.class_id
            AND c.teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can view their own enrollments" ON class_enrollments
    FOR SELECT USING (auth.uid() = student_id);

-- Shared Chats Policies
CREATE POLICY "Students can manage their shared chats" ON shared_chats
    FOR ALL USING (auth.uid() = student_id);

CREATE POLICY "Teachers can view shared chats from their students" ON shared_chats
    FOR SELECT USING (auth.uid() = teacher_id);

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_chat_sessions_user_active ON chat_sessions(user_id, last_active_at DESC);
CREATE INDEX idx_question_results_user_topic ON question_results(user_id, topic_title);
CREATE INDEX idx_question_results_timestamp ON question_results(user_id, timestamp DESC);
CREATE INDEX idx_student_creation_requests_teacher ON student_creation_requests(teacher_id, status);
CREATE INDEX idx_classes_teacher ON classes(teacher_id, is_active);
CREATE INDEX idx_classes_code ON classes(class_code);
CREATE INDEX idx_classes_subject_grade ON classes(subject, grade_level);
CREATE INDEX idx_class_enrollments_class ON class_enrollments(class_id, is_active);
CREATE INDEX idx_class_enrollments_student ON class_enrollments(student_id, is_active);
CREATE INDEX idx_shared_chats_student ON shared_chats(student_id);
CREATE INDEX idx_shared_chats_teacher ON shared_chats(teacher_id);
CREATE INDEX idx_shared_chats_class ON shared_chats(class_id);

-- ============================================================================
-- ENABLE REALTIME SUBSCRIPTIONS
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE question_results;
ALTER PUBLICATION supabase_realtime ADD TABLE student_creation_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE classes;
ALTER PUBLICATION supabase_realtime ADD TABLE class_enrollments;
ALTER PUBLICATION supabase_realtime ADD TABLE shared_chats;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT 'Emcie complete database schema with class system created successfully!' as status;