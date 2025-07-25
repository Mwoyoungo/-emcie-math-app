-- Create shared_chats table for students to share AI conversations with teachers
CREATE TABLE IF NOT EXISTS shared_chats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES user_profiles(id),
    teacher_id UUID NOT NULL REFERENCES user_profiles(id),
    class_id UUID NOT NULL REFERENCES classes(id),
    topic_title TEXT NOT NULL,
    student_name TEXT NOT NULL,
    class_name TEXT NOT NULL,
    chat_data JSONB NOT NULL, -- Full ChatSession JSON
    message TEXT, -- Optional message from student
    is_read BOOLEAN DEFAULT FALSE,
    shared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_shared_chats_teacher_id ON shared_chats (teacher_id);
CREATE INDEX IF NOT EXISTS idx_shared_chats_student_id ON shared_chats (student_id);
CREATE INDEX IF NOT EXISTS idx_shared_chats_class_id ON shared_chats (class_id);
CREATE INDEX IF NOT EXISTS idx_shared_chats_shared_at ON shared_chats (shared_at DESC);
CREATE INDEX IF NOT EXISTS idx_shared_chats_is_read ON shared_chats (is_read);

-- Enable Row Level Security
ALTER TABLE shared_chats ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shared_chats
-- Teachers can see chats shared with them
CREATE POLICY "Teachers can view their shared chats" ON shared_chats
    FOR SELECT
    USING (teacher_id = auth.uid());

-- Students can insert (share) chats
CREATE POLICY "Students can share chats" ON shared_chats
    FOR INSERT
    WITH CHECK (student_id = auth.uid());

-- Teachers can update read status
CREATE POLICY "Teachers can update read status" ON shared_chats
    FOR UPDATE
    USING (teacher_id = auth.uid())
    WITH CHECK (teacher_id = auth.uid());

-- Teachers can delete shared chats
CREATE POLICY "Teachers can delete shared chats" ON shared_chats
    FOR DELETE
    USING (teacher_id = auth.uid());

-- Students can delete their own shared chats  
CREATE POLICY "Students can delete their shared chats" ON shared_chats
    FOR DELETE
    USING (student_id = auth.uid());

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_shared_chats_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_shared_chats_updated_at_trigger
    BEFORE UPDATE ON shared_chats
    FOR EACH ROW
    EXECUTE FUNCTION update_shared_chats_updated_at();