-- Emcie App Complete Database Schema (Current Production State)
-- Run this SQL in your Supabase SQL Editor
-- Includes: Core tables, Class System, Video Sessions, Assignments, Functions, Triggers, RLS Policies, Storage Buckets

-- Enable RLS (Row Level Security)
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- 1. User Profiles Table with Role Support
CREATE TABLE IF NOT EXISTS user_profiles (
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
CREATE TABLE IF NOT EXISTS chat_sessions (
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
CREATE TABLE IF NOT EXISTS question_results (
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
CREATE TABLE IF NOT EXISTS student_creation_requests (
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
CREATE TABLE IF NOT EXISTS upsertion_records (
    uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL,
    namespace TEXT NOT NULL,
    updated_at DOUBLE PRECISION NOT NULL,
    group_id TEXT
);

-- Enable RLS on upsertion_records (currently disabled in production)
-- ALTER TABLE upsertion_records ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- CLASS SYSTEM TABLES
-- ============================================================================

-- 6. Classes Table (Class System)
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id),
    name TEXT NOT NULL,
    description TEXT,
    subject TEXT DEFAULT 'Mathematics',
    grade_level TEXT NOT NULL,
    class_code TEXT UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on classes
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- 7. Class Enrollments Table
CREATE TABLE IF NOT EXISTS class_enrollments (
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
CREATE TABLE IF NOT EXISTS shared_chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES auth.users(id) NOT NULL,
    teacher_id UUID REFERENCES auth.users(id) NOT NULL,
    class_id UUID REFERENCES classes(id),
    chat_data JSONB NOT NULL,
    shared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on shared_chats
ALTER TABLE shared_chats ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- VIDEO SESSIONS AND ASSIGNMENTS TABLES
-- ============================================================================

-- 9. Video Sessions Table
CREATE TABLE IF NOT EXISTS video_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES user_profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    start_time TIME NOT NULL,
    recurring_days INTEGER[] NOT NULL CHECK (array_length(recurring_days, 1) > 0), -- [1,2,3,4,5] for Mon-Fri
    agora_channel_name TEXT NOT NULL UNIQUE,
    agora_app_id TEXT,
    video_link TEXT, -- For external video links (Google Meet, Zoom, etc.)
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on video_sessions
ALTER TABLE video_sessions ENABLE ROW LEVEL SECURITY;

-- 10. Video Session Instances (Generated automatically for each recurring session)
CREATE TABLE IF NOT EXISTS video_session_instances (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    video_session_id UUID NOT NULL REFERENCES video_sessions(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled')),
    agora_token TEXT,
    total_students_enrolled INTEGER DEFAULT 0,
    total_students_attended INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(video_session_id, scheduled_date)
);

-- Enable RLS on video_session_instances
ALTER TABLE video_session_instances ENABLE ROW LEVEL SECURITY;

-- 11. Video Session Attendance
CREATE TABLE IF NOT EXISTS video_session_attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_instance_id UUID NOT NULL REFERENCES video_session_instances(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES user_profiles(id),
    joined_at TIMESTAMP WITH TIME ZONE,
    left_at TIMESTAMP WITH TIME ZONE,
    total_duration_minutes INTEGER DEFAULT 0,
    is_present BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(session_instance_id, student_id)
);

-- Enable RLS on video_session_attendance
ALTER TABLE video_session_attendance ENABLE ROW LEVEL SECURITY;

-- 12. Assignments Table
CREATE TABLE IF NOT EXISTS assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES user_profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    max_file_size_mb INTEGER DEFAULT 10,
    allowed_file_types TEXT[] DEFAULT ARRAY['pdf', 'png', 'jpg', 'jpeg'],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on assignments
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;

-- 13. Assignment Submissions
CREATE TABLE IF NOT EXISTS assignment_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES user_profiles(id),
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_type TEXT NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    grade NUMERIC(5,2), -- Optional grading 0-100
    teacher_feedback TEXT,
    graded_at TIMESTAMP WITH TIME ZONE,
    graded_by UUID REFERENCES user_profiles(id),
    UNIQUE(assignment_id, student_id) -- One submission per student per assignment
);

-- Enable RLS on assignment_submissions
ALTER TABLE assignment_submissions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Create storage bucket for assignment files
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'assignment-files',
    'assignment-files',
    true,
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/png', 'image/jpg', 'image/jpeg', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

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

-- Function to generate session instances for recurring sessions
CREATE OR REPLACE FUNCTION generate_session_instances(
    p_video_session_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_weeks_ahead INTEGER DEFAULT 4
)
RETURNS INTEGER AS $$
DECLARE
    session_record RECORD;
    loop_date DATE;
    end_date DATE;
    day_of_week INTEGER;
    session_date DATE;
    instances_created INTEGER := 0;
BEGIN
    -- Get the video session details
    SELECT * INTO session_record FROM video_sessions WHERE id = p_video_session_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    loop_date := p_start_date;
    end_date := loop_date + (p_weeks_ahead * 7);
    
    -- Loop through each day in the range
    WHILE loop_date <= end_date LOOP
        day_of_week := EXTRACT(DOW FROM loop_date); -- 0=Sunday, 1=Monday, etc.
        
        -- Convert to our format (1=Monday, 7=Sunday)
        IF day_of_week = 0 THEN
            day_of_week := 7;
        END IF;
        
        -- Check if this day is in the recurring days
        IF day_of_week = ANY(session_record.recurring_days) THEN
            session_date := loop_date;
            
            -- Insert session instance if it doesn't exist
            INSERT INTO video_session_instances (
                video_session_id,
                scheduled_date,
                scheduled_start_time,
                scheduled_end_time
            ) VALUES (
                p_video_session_id,
                session_date,
                session_date + session_record.start_time,
                session_date + session_record.start_time + (session_record.duration_minutes || ' minutes')::INTERVAL
            ) ON CONFLICT (video_session_id, scheduled_date) DO NOTHING;
            
            instances_created := instances_created + 1;
        END IF;
        
        loop_date := loop_date + 1;
    END LOOP;
    
    RETURN instances_created;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate instances when video session is created
CREATE OR REPLACE FUNCTION auto_generate_session_instances()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM generate_session_instances(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update functions for timestamps
CREATE OR REPLACE FUNCTION update_video_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_shared_chats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to auto-generate class codes
CREATE TRIGGER trigger_set_class_code
    BEFORE INSERT OR UPDATE ON classes
    FOR EACH ROW
    EXECUTE FUNCTION set_class_code();

-- Trigger to validate student creation requests
CREATE TRIGGER trigger_validate_student_creation_teacher
    BEFORE INSERT OR UPDATE ON student_creation_requests
    FOR EACH ROW
    EXECUTE FUNCTION validate_student_creation_teacher();

-- Trigger to auto-generate session instances
CREATE TRIGGER auto_generate_session_instances_trigger
    AFTER INSERT ON video_sessions
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_session_instances();

-- Triggers for updating timestamps
CREATE TRIGGER update_video_sessions_updated_at_trigger
    BEFORE UPDATE ON video_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_video_sessions_updated_at();

CREATE TRIGGER update_assignments_updated_at_trigger
    BEFORE UPDATE ON assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_assignments_updated_at();

CREATE TRIGGER update_shared_chats_updated_at_trigger
    BEFORE UPDATE ON shared_chats
    FOR EACH ROW
    EXECUTE FUNCTION update_shared_chats_updated_at();

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
CREATE POLICY "Students can view own sessions" ON chat_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Question Results Policies
CREATE POLICY "Students can view own performance" ON question_results
    FOR ALL USING (auth.uid() = user_id);

-- Student Creation Requests Policies
CREATE POLICY "Teachers can manage their student creation requests" ON student_creation_requests
    FOR ALL USING (auth.uid() = teacher_id);

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

-- Video Sessions Policies
CREATE POLICY "Teachers can manage their video sessions" ON video_sessions
    FOR ALL USING (teacher_id = auth.uid());

CREATE POLICY "Students can view video sessions for their classes" ON video_sessions
    FOR SELECT USING (
        class_id IN (
            SELECT class_id FROM class_enrollments 
            WHERE student_id = auth.uid() AND is_active = TRUE
        )
    );

-- Video Session Instances Policies
CREATE POLICY "Teachers can manage their session instances" ON video_session_instances
    FOR ALL USING (
        video_session_id IN (
            SELECT id FROM video_sessions WHERE teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can view session instances for their classes" ON video_session_instances
    FOR SELECT USING (
        video_session_id IN (
            SELECT vs.id FROM video_sessions vs
            JOIN class_enrollments ce ON vs.class_id = ce.class_id
            WHERE ce.student_id = auth.uid() AND ce.is_active = TRUE
        )
    );

-- Video Session Attendance Policies
CREATE POLICY "Teachers can view attendance for their sessions" ON video_session_attendance
    FOR SELECT USING (
        session_instance_id IN (
            SELECT vsi.id FROM video_session_instances vsi
            JOIN video_sessions vs ON vsi.video_session_id = vs.id
            WHERE vs.teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can view and update their own attendance" ON video_session_attendance
    FOR ALL USING (student_id = auth.uid());

-- Assignments Policies
CREATE POLICY "Teachers can manage their assignments" ON assignments
    FOR ALL USING (teacher_id = auth.uid());

CREATE POLICY "Students can view assignments for their classes" ON assignments
    FOR SELECT USING (
        class_id IN (
            SELECT class_id FROM class_enrollments 
            WHERE student_id = auth.uid() AND is_active = TRUE
        )
    );

-- Assignment Submissions Policies
CREATE POLICY "Teachers can view submissions for their assignments" ON assignment_submissions
    FOR SELECT USING (
        assignment_id IN (
            SELECT id FROM assignments WHERE teacher_id = auth.uid()
        )
    );

CREATE POLICY "Teachers can grade submissions for their assignments" ON assignment_submissions
    FOR UPDATE USING (
        assignment_id IN (
            SELECT id FROM assignments WHERE teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can manage their own submissions" ON assignment_submissions
    FOR ALL USING (student_id = auth.uid());

-- ============================================================================
-- STORAGE POLICIES
-- ============================================================================

-- Students can upload assignment files
CREATE POLICY "Students can upload assignment files" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'assignment-files' AND 
        auth.role() = 'authenticated'
    );

-- Students can view their own assignment files
CREATE POLICY "Students can view their own assignment files" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'assignment-files' AND 
        (auth.uid())::text = (storage.foldername(name))[2]
    );

-- Teachers can view assignment files for their classes
CREATE POLICY "Teachers can view assignment files for their classes" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'assignment-files' AND 
        EXISTS (
            SELECT 1 FROM assignments a 
            WHERE (a.id)::text = (storage.foldername(name))[1] 
            AND a.teacher_id = auth.uid()
        )
    );

-- Teachers can delete assignment files for their classes
CREATE POLICY "Teachers can delete assignment files for their classes" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'assignment-files' AND 
        EXISTS (
            SELECT 1 FROM assignments a 
            WHERE (a.id)::text = (storage.foldername(name))[1] 
            AND a.teacher_id = auth.uid()
        )
    );

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_active ON chat_sessions(user_id, last_active_at DESC);
CREATE INDEX IF NOT EXISTS idx_question_results_user_topic ON question_results(user_id, topic_title);
CREATE INDEX IF NOT EXISTS idx_question_results_timestamp ON question_results(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_student_creation_requests_teacher ON student_creation_requests(teacher_id, status);
CREATE INDEX IF NOT EXISTS idx_classes_teacher ON classes(teacher_id, is_active);
CREATE INDEX IF NOT EXISTS idx_classes_code ON classes(class_code);
CREATE INDEX IF NOT EXISTS idx_classes_subject_grade ON classes(subject, grade_level);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_class ON class_enrollments(class_id, is_active);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_student ON class_enrollments(student_id, is_active);
CREATE INDEX IF NOT EXISTS idx_shared_chats_student ON shared_chats(student_id);
CREATE INDEX IF NOT EXISTS idx_shared_chats_teacher ON shared_chats(teacher_id);
CREATE INDEX IF NOT EXISTS idx_shared_chats_class ON shared_chats(class_id);

-- Video Sessions Indexes
CREATE INDEX IF NOT EXISTS idx_video_sessions_class_id ON video_sessions (class_id);
CREATE INDEX IF NOT EXISTS idx_video_sessions_teacher_id ON video_sessions (teacher_id);
CREATE INDEX IF NOT EXISTS idx_video_sessions_active ON video_sessions (is_active);

CREATE INDEX IF NOT EXISTS idx_video_session_instances_session_id ON video_session_instances (video_session_id);
CREATE INDEX IF NOT EXISTS idx_video_session_instances_date ON video_session_instances (scheduled_date);
CREATE INDEX IF NOT EXISTS idx_video_session_instances_status ON video_session_instances (status);

CREATE INDEX IF NOT EXISTS idx_video_session_attendance_instance_id ON video_session_attendance (session_instance_id);
CREATE INDEX IF NOT EXISTS idx_video_session_attendance_student_id ON video_session_attendance (student_id);

CREATE INDEX IF NOT EXISTS idx_assignments_class_id ON assignments (class_id);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher_id ON assignments (teacher_id);
CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON assignments (due_date);

CREATE INDEX IF NOT EXISTS idx_assignment_submissions_assignment_id ON assignment_submissions (assignment_id);
CREATE INDEX IF NOT EXISTS idx_assignment_submissions_student_id ON assignment_submissions (student_id);
CREATE INDEX IF NOT EXISTS idx_assignment_submissions_submitted_at ON assignment_submissions (submitted_at);

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
ALTER PUBLICATION supabase_realtime ADD TABLE video_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE video_session_instances;
ALTER PUBLICATION supabase_realtime ADD TABLE video_session_attendance;
ALTER PUBLICATION supabase_realtime ADD TABLE assignments;
ALTER PUBLICATION supabase_realtime ADD TABLE assignment_submissions;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT 'Emcie complete database schema with all features created successfully!' as status;
