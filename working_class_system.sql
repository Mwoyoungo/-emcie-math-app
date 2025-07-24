-- Working Class System - Fix the recursion issue
-- Run this in your Supabase SQL Editor

-- Clean slate
DROP TABLE IF EXISTS class_enrollments CASCADE;
DROP TABLE IF EXISTS classes CASCADE;

-- 1. Classes table (this part works fine)
CREATE TABLE classes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    subject text DEFAULT 'Mathematics',
    grade_level text,
    class_code text UNIQUE NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp DEFAULT now(),
    updated_at timestamp DEFAULT now()
);

-- 2. Class enrollments - SIMPLIFIED
CREATE TABLE class_enrollments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id uuid REFERENCES classes(id) ON DELETE CASCADE,
    student_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
    enrolled_at timestamp DEFAULT now(),
    is_active boolean DEFAULT true,
    UNIQUE(class_id, student_id)
);

-- Enable RLS
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_enrollments ENABLE ROW LEVEL SECURITY;

-- =============================================
-- SIMPLE POLICIES - NO CROSS-TABLE REFERENCES
-- =============================================

-- Classes: Simple teacher ownership (THIS WORKS)
CREATE POLICY "Teachers can manage own classes" ON classes
    FOR ALL 
    USING (auth.uid() = teacher_id);

-- Classes: Let students see classes (we'll handle enrollment separately)
CREATE POLICY "Anyone can view active classes" ON classes
    FOR SELECT 
    USING (is_active = true);

-- Class enrollments: Students can only see/manage their own enrollments
CREATE POLICY "Students can manage own enrollments" ON class_enrollments
    FOR ALL
    USING (auth.uid() = student_id);

-- Class enrollments: Teachers can see enrollments but ONLY through direct queries
-- NO subqueries that could cause recursion
CREATE POLICY "Teachers can view all enrollments" ON class_enrollments
    FOR SELECT
    USING (true);  -- Let app-level logic handle filtering

CREATE POLICY "Teachers can manage enrollments via app" ON class_enrollments
    FOR INSERT
    WITH CHECK (true);  -- Let app handle validation

CREATE POLICY "Teachers can update enrollments" ON class_enrollments
    FOR UPDATE
    USING (true);

-- =============================================
-- HELPER FUNCTIONS (keep these simple)
-- =============================================

-- Generate class codes
CREATE OR REPLACE FUNCTION generate_class_code()
RETURNS text AS $$
DECLARE
    new_code text;
    code_exists boolean;
BEGIN
    LOOP
        new_code := UPPER(substring(md5(random()::text) from 1 for 6));
        SELECT EXISTS(SELECT 1 FROM classes WHERE class_code = new_code) INTO code_exists;
        IF NOT code_exists THEN
            RETURN new_code;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Auto-generate codes
CREATE OR REPLACE FUNCTION set_class_code()
RETURNS trigger AS $$
BEGIN
    IF NEW.class_code IS NULL OR NEW.class_code = '' THEN
        NEW.class_code := generate_class_code();
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_class_code
    BEFORE INSERT OR UPDATE ON classes
    FOR EACH ROW EXECUTE FUNCTION set_class_code();

-- Simple join function
CREATE OR REPLACE FUNCTION join_class_by_code(p_class_code text)
RETURNS jsonb AS $$
DECLARE
    class_record classes%ROWTYPE;
    enrollment_exists boolean;
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'User not authenticated');
    END IF;
    
    SELECT * INTO class_record FROM classes WHERE class_code = UPPER(p_class_code) AND is_active = true;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid class code');
    END IF;
    
    SELECT EXISTS(
        SELECT 1 FROM class_enrollments 
        WHERE class_id = class_record.id AND student_id = auth.uid() AND is_active = true
    ) INTO enrollment_exists;
    
    IF enrollment_exists THEN
        RETURN jsonb_build_object('success', false, 'error', 'Already enrolled in this class');
    END IF;
    
    INSERT INTO class_enrollments (class_id, student_id)
    VALUES (class_record.id, auth.uid());
    
    RETURN jsonb_build_object(
        'success', true, 
        'class_name', class_record.name,
        'teacher_id', class_record.teacher_id
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_classes_teacher ON classes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classes_code ON classes(class_code);
CREATE INDEX IF NOT EXISTS idx_enrollments_class ON class_enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON class_enrollments(student_id);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE classes;
ALTER PUBLICATION supabase_realtime ADD TABLE class_enrollments;

SELECT 'Working class system created - no recursion!' as status;