-- Video Sessions and Assignments Schema
-- Complete system for video meetings and assignment management

-- Video Sessions Table
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
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Video Session Instances (Generated automatically for each recurring session)
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

-- Video Session Attendance
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

-- Assignments Table
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

-- Assignment Submissions
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

-- Indexes for performance
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

-- Enable Row Level Security
ALTER TABLE video_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_session_instances ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_session_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignment_submissions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Video Sessions
CREATE POLICY "Teachers can manage their video sessions" ON video_sessions
    FOR ALL
    USING (teacher_id = auth.uid());

CREATE POLICY "Students can view video sessions for their classes" ON video_sessions
    FOR SELECT
    USING (
        class_id IN (
            SELECT class_id FROM class_enrollments 
            WHERE student_id = auth.uid() AND is_active = TRUE
        )
    );

-- RLS Policies for Video Session Instances
CREATE POLICY "Teachers can manage their session instances" ON video_session_instances
    FOR ALL
    USING (
        video_session_id IN (
            SELECT id FROM video_sessions WHERE teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can view session instances for their classes" ON video_session_instances
    FOR SELECT
    USING (
        video_session_id IN (
            SELECT vs.id FROM video_sessions vs
            JOIN class_enrollments ce ON vs.class_id = ce.class_id
            WHERE ce.student_id = auth.uid() AND ce.is_active = TRUE
        )
    );

-- RLS Policies for Video Session Attendance
CREATE POLICY "Teachers can view attendance for their sessions" ON video_session_attendance
    FOR SELECT
    USING (
        session_instance_id IN (
            SELECT vsi.id FROM video_session_instances vsi
            JOIN video_sessions vs ON vsi.video_session_id = vs.id
            WHERE vs.teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can view and update their own attendance" ON video_session_attendance
    FOR ALL
    USING (student_id = auth.uid());

-- RLS Policies for Assignments
CREATE POLICY "Teachers can manage their assignments" ON assignments
    FOR ALL
    USING (teacher_id = auth.uid());

CREATE POLICY "Students can view assignments for their classes" ON assignments
    FOR SELECT
    USING (
        class_id IN (
            SELECT class_id FROM class_enrollments 
            WHERE student_id = auth.uid() AND is_active = TRUE
        )
    );

-- RLS Policies for Assignment Submissions
CREATE POLICY "Teachers can view submissions for their assignments" ON assignment_submissions
    FOR SELECT
    USING (
        assignment_id IN (
            SELECT id FROM assignments WHERE teacher_id = auth.uid()
        )
    );

CREATE POLICY "Teachers can grade submissions for their assignments" ON assignment_submissions
    FOR UPDATE
    USING (
        assignment_id IN (
            SELECT id FROM assignments WHERE teacher_id = auth.uid()
        )
    );

CREATE POLICY "Students can manage their own submissions" ON assignment_submissions
    FOR ALL
    USING (student_id = auth.uid());

-- Triggers for updating timestamps
CREATE OR REPLACE FUNCTION update_video_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_video_sessions_updated_at_trigger
    BEFORE UPDATE ON video_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_video_sessions_updated_at();

CREATE OR REPLACE FUNCTION update_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_assignments_updated_at_trigger
    BEFORE UPDATE ON assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_assignments_updated_at();

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

CREATE TRIGGER auto_generate_session_instances_trigger
    AFTER INSERT ON video_sessions
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_session_instances();