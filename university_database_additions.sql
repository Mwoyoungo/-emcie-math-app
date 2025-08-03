-- University Support Database Schema Additions
-- Run this SQL in your Supabase SQL Editor

-- Add university field to user_profiles table
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS university_type TEXT DEFAULT 'high_school';

-- Add constraint for university_type
ALTER TABLE user_profiles 
ADD CONSTRAINT valid_university_type CHECK (university_type IN ('high_school', 'university'));

-- Update user profiles to allow university students
ALTER TABLE user_profiles 
DROP CONSTRAINT IF EXISTS student_needs_grade;

-- Add new constraint that allows university students to not have a grade
ALTER TABLE user_profiles
ADD CONSTRAINT student_needs_grade_or_university CHECK (
    (role = 'student' AND university_type = 'high_school' AND grade IS NOT NULL) OR 
    (role = 'student' AND university_type = 'university') OR
    (role != 'student')
);

-- Create university topics table
CREATE TABLE IF NOT EXISTS university_topics (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT '#7553F6',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default university topics
INSERT INTO university_topics (title, description, icon_name, color) VALUES
('Small Things', 'Explore literature through analysis of short stories, novellas, and character studies', 'book', '#FF6B6B'),
('Poems', 'Dive into poetry analysis, interpretation, and creative writing', 'edit', '#4ECDC4'),
('Short Stories', 'Master the art of short story writing and literary analysis', 'article', '#45B7D1')
ON CONFLICT (title) DO NOTHING;

-- Enable RLS on university_topics
ALTER TABLE university_topics ENABLE ROW LEVEL SECURITY;

-- RLS Policy for university_topics (allow read for all authenticated users)
CREATE POLICY "Allow read university_topics for authenticated users" ON university_topics
    FOR SELECT
    TO authenticated
    USING (true);