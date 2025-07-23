# Emcie Database Schema Design

## Overview
This document outlines the proposed database schema for the Emcie math learning app using Supabase. The schema is designed to support user authentication, chat sessions with AI tutors, performance tracking, and progress analytics.

## Tables Design

### 1. `user_profiles` Table
**Purpose**: Store extended user information beyond Supabase auth with role-based access

```sql
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
```

**Workflow Integration**:
- Links to Supabase built-in `auth.users` table
- `role` determines app functionality and permissions
- Students: access chat sessions and performance tracking
- Teachers: access student progress dashboards (future feature)
- `grade` required for students, optional for teachers
- `subject_specialization` for teacher expertise areas
- Created during signup process with role selection

**Relationships**:
- One-to-many with `chat_sessions` (students only)
- One-to-many with `question_results` (students only)
- One-to-many with `teacher_student_relationships` (both roles)

---

### 2. `chat_sessions` Table
**Purpose**: Persist conversation threads between user and AI tutor

```sql
CREATE TABLE chat_sessions (
    id TEXT PRIMARY KEY,  -- chatId from ChatSessionService
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    topic_title TEXT NOT NULL,  -- "Algebra", "Functions", etc.
    grade TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_active_at TIMESTAMP WITH TIME ZONE NOT NULL,
    messages JSONB DEFAULT '[]'::JSONB,  -- Array of ChatMessage objects
    metadata JSONB DEFAULT '{}'::JSONB   -- Session metadata (progress, etc.)
);
```

**Workflow Integration**:
- `id` matches the `chatId` generated in `ChatSessionService`
- `topic_title` corresponds to CAPS math topics (Functions, Algebra, etc.)
- `messages` stores complete conversation history as JSON
- Enables session resumption: user can continue conversations across app restarts
- `last_active_at` used for "Continue Learning" section on home page
- `metadata` stores assessment progress, last execution ID, etc.

**JSON Structure for `messages`**:
```json
[
  {
    "text": "Question 1: Simplify 2x + 3x",
    "isUser": false,
    "timestamp": "2024-01-15T10:30:00Z",
    "hasLatex": true,
    "chatMessageId": "msg_123",
    "executionId": "exec_456"
  },
  {
    "text": "5x",
    "isUser": true,
    "timestamp": "2024-01-15T10:31:00Z"
  }
]
```

**Home Page Integration**:
- Green dot indicator when `last_active_at` is recent
- "CONTINUE" vs "START LEARNING" based on session existence
- Continue Learning section shows sessions ordered by `last_active_at`

---

### 3. `question_results` Table
**Purpose**: Track individual question responses for performance analytics

```sql
CREATE TABLE question_results (
    id TEXT PRIMARY KEY,  -- execution_id + timestamp
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    topic_title TEXT NOT NULL,
    question_text TEXT NOT NULL,  -- The AI's question
    user_answer TEXT NOT NULL,    -- Student's response
    is_correct BOOLEAN NOT NULL,  -- Parsed from AI response [CORRECT]/[WRONG]
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    execution_id TEXT NOT NULL    -- Links to FlowiseAI execution
);
```

**Workflow Integration**:
- Created when `PerformanceService.recordQuestionResult()` is called
- `is_correct` determined by parsing AI responses for "[CORRECT]" or "[WRONG]"
- `execution_id` links to FlowiseAI's tracking system
- Powers the performance statistics in progress screen
- Enables topic-specific progress bars on home page

**Performance Analytics**:
- **Accuracy Calculation**: `COUNT(is_correct=true) / COUNT(*) * 100`
- **Topic Progress**: Individual topic performance tracking
- **Overall Stats**: Cross-topic performance aggregation
- **Badge System**: Gold (90%+), Silver (75%+), Bronze (60%+)

**Progress Screen Integration**:
```
Topics Studied: COUNT(DISTINCT topic_title)
Correct Answers: COUNT(is_correct=true)
Total Questions: COUNT(*)
Accuracy: (correct/total) * 100%
```

---

### 4. `teacher_student_relationships` Table
**Purpose**: Connect teachers with students for progress monitoring

```sql
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
```

**Future Teacher Dashboard Integration**:
- Teachers can view assigned students' progress
- Students can share their performance with teachers
- Support for classroom management features
- Relationship approval workflow for privacy

---

### 5. `teacher_classes` Table (Future Enhancement)
**Purpose**: Group students into classes for teachers

```sql
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
```

---

## Data Flow & Integration

### 1. User Registration Flow
```
SignInForm (with role selection) → UserService → SupabaseService.signUp() → user_profiles table

Student Registration:
- Role: 'student'
- Grade: Required (10, 11, 12)
- School: Optional
- Access: Chat sessions, performance tracking

Teacher Registration:
- Role: 'teacher' 
- Grade: Not applicable
- Subject Specialization: Required
- School: Optional
- Access: Student progress dashboard (future)
```

### 2. Chat Session Flow
```
ChatScreen → ChatSessionService → SupabaseService.saveChatSession() → chat_sessions table
```

### 3. Performance Tracking Flow
```
AI Response → PerformanceService → SupabaseService.saveQuestionResult() → question_results table
```

### 4. Home Page Data Flow
```
HomePage → SupabaseService.getUserChatSessions() → chat_sessions table
         → SupabaseService.getTopicPerformance() → question_results table
```

---

## Row Level Security (RLS)

**Security Principle**: Role-based access with privacy protection

```sql
-- Users can see their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

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
```

---

## Real-time Features

### 1. Session Updates
- Real-time sync when messages are added to sessions
- Multiple devices can show updated conversation state

### 2. Performance Updates
- Live performance statistics updates
- Real-time progress bar updates on home page

---

## Indexes for Performance

```sql
-- Chat sessions by user and activity
CREATE INDEX idx_chat_sessions_user_active ON chat_sessions(user_id, last_active_at DESC);

-- Performance by user and topic
CREATE INDEX idx_question_results_user_topic ON question_results(user_id, topic_title);

-- Performance by timestamp for recent activity
CREATE INDEX idx_question_results_timestamp ON question_results(user_id, timestamp DESC);
```

---

## Migration Considerations

### Existing In-Memory Data
- Current `ChatSessionService` uses in-memory storage
- Migration strategy: On first Supabase connection, save existing sessions
- Gradual transition: Keep in-memory as backup until cloud sync is stable

### Offline Support
- Continue using in-memory storage when offline
- Sync to Supabase when connection is restored
- Conflict resolution for concurrent edits

---

## Potential Issues & Solutions

### 1. Large Message Arrays
**Problem**: `messages` JSONB can grow large for long conversations
**Solution**: 
- Implement message pagination
- Archive old messages to separate table
- Compress older message content

### 2. Performance Analytics Queries
**Problem**: Aggregating performance across all topics can be expensive
**Solution**:
- Materialized views for performance summaries
- Periodic recalculation of stats
- Caching frequently accessed metrics

### 3. Real-time Scaling
**Problem**: Many concurrent users with real-time subscriptions
**Solution**:
- Implement connection pooling
- Use Supabase Edge Functions for heavy computations
- Rate limiting on real-time updates

---

## Future Enhancements

### 1. Learning Path Tracking
```sql
CREATE TABLE learning_paths (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    topic_title TEXT,
    difficulty_level INTEGER,
    completed_at TIMESTAMP WITH TIME ZONE
);
```

### 2. AI Tutor Feedback
```sql
CREATE TABLE tutor_feedback (
    id UUID PRIMARY KEY,
    question_result_id TEXT REFERENCES question_results(id),
    feedback_text TEXT,
    improvement_suggestions JSONB
);
```

### 3. Parent/Teacher Dashboard
```sql
CREATE TABLE user_relationships (
    id UUID PRIMARY KEY,
    student_id UUID REFERENCES auth.users(id),
    guardian_id UUID REFERENCES auth.users(id),
    relationship_type TEXT -- 'parent', 'teacher'
);
```

---

## Questions for Review

1. **Message Storage**: Should we store messages as JSONB or normalize into separate messages table?
2. **Performance Data**: Is question-level tracking sufficient, or do we need sub-question steps?
3. **Session Limits**: Should we limit the number of concurrent sessions per user?
4. **Data Retention**: How long should we keep old chat sessions and performance data?
5. **Authentication**: Do we need additional user roles (student, teacher, admin)?
