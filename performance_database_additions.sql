-- Performance Database Additions
-- Add this to your existing Supabase database to support performance tracking

-- ============================================================================
-- AI MESSAGES TRACKING TABLE 
-- ============================================================================

-- Track all AI messages per topic to count total questions asked
CREATE TABLE IF NOT EXISTS ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    topic_title TEXT NOT NULL,
    ai_response TEXT NOT NULL,
    user_answer TEXT DEFAULT '',
    execution_id TEXT NOT NULL,
    has_correctness_feedback BOOLEAN DEFAULT FALSE,
    is_correct BOOLEAN NULL, -- NULL if no feedback, TRUE/FALSE if feedback exists
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on ai_messages
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PERFORMANCE AGGREGATION VIEW
-- ============================================================================

-- Create a view to aggregate performance statistics per user per topic
CREATE OR REPLACE VIEW topic_performance_stats AS
SELECT 
    user_id,
    topic_title,
    COUNT(*) as questions_asked,
    COUNT(*) FILTER (WHERE is_correct = TRUE) as correct_answers,
    COUNT(*) FILTER (WHERE is_correct = FALSE) as wrong_answers,
    COUNT(*) FILTER (WHERE has_correctness_feedback = TRUE) as answered_questions,
    CASE 
        WHEN COUNT(*) FILTER (WHERE has_correctness_feedback = TRUE) > 0 
        THEN ROUND((COUNT(*) FILTER (WHERE is_correct = TRUE)::NUMERIC / COUNT(*) FILTER (WHERE has_correctness_feedback = TRUE)) * 100, 1)
        ELSE 0 
    END as accuracy_percentage,
    MAX(created_at) as last_activity
FROM ai_messages 
GROUP BY user_id, topic_title;

-- ============================================================================
-- FUNCTIONS FOR PERFORMANCE OPERATIONS
-- ============================================================================

-- Function to record AI message with performance tracking
CREATE OR REPLACE FUNCTION record_ai_message(
    p_topic_title TEXT,
    p_ai_response TEXT,
    p_execution_id TEXT,
    p_user_answer TEXT DEFAULT ''
)
RETURNS JSON
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_has_correctness BOOLEAN;
    v_is_correct BOOLEAN;
    v_message_id UUID;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;
    
    -- Check if AI response contains correctness feedback
    v_has_correctness := (
        UPPER(p_ai_response) LIKE '%[CORRECT]%' OR 
        UPPER(p_ai_response) LIKE '%[WRONG]%'
    );
    
    -- Determine correctness if feedback exists
    IF v_has_correctness THEN
        v_is_correct := UPPER(p_ai_response) LIKE '%[CORRECT]%';
    ELSE
        v_is_correct := NULL;
    END IF;
    
    -- Insert AI message record
    INSERT INTO ai_messages (
        user_id,
        topic_title,
        ai_response,
        user_answer,
        execution_id,
        has_correctness_feedback,
        is_correct
    ) VALUES (
        v_user_id,
        p_topic_title,
        p_ai_response,
        p_user_answer,
        p_execution_id,
        v_has_correctness,
        v_is_correct
    ) RETURNING id INTO v_message_id;
    
    -- Also insert into question_results if there's correctness feedback (for backward compatibility)
    IF v_has_correctness THEN
        INSERT INTO question_results (
            id,
            user_id,
            topic_title,
            question_text,
            user_answer,
            is_correct,
            timestamp,
            execution_id
        ) VALUES (
            gen_random_uuid()::TEXT,
            v_user_id,
            p_topic_title,
            'AI Question from chat',
            p_user_answer,
            v_is_correct,
            NOW(),
            p_execution_id
        ) ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message_id', v_message_id,
        'has_correctness', v_has_correctness,
        'is_correct', v_is_correct
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Function to get performance statistics for a user and topic
CREATE OR REPLACE FUNCTION get_topic_performance(
    p_topic_title TEXT
)
RETURNS JSON
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_stats RECORD;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;
    
    -- Get performance statistics
    SELECT * INTO v_stats
    FROM topic_performance_stats
    WHERE user_id = v_user_id AND topic_title = p_topic_title;
    
    IF v_stats IS NULL THEN
        RETURN json_build_object(
            'success', true,
            'questions_asked', 0,
            'correct_answers', 0,
            'wrong_answers', 0,
            'accuracy_percentage', 0
        );
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'questions_asked', v_stats.questions_asked,
        'correct_answers', v_stats.correct_answers,
        'wrong_answers', v_stats.wrong_answers,
        'answered_questions', v_stats.answered_questions,
        'accuracy_percentage', v_stats.accuracy_percentage,
        'last_activity', v_stats.last_activity
    );
END;
$$;

-- Function to get all performance statistics for a user
CREATE OR REPLACE FUNCTION get_all_topic_performance()
RETURNS JSON
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_results JSON;
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'User not authenticated');
    END IF;
    
    -- Get all performance statistics for the user
    SELECT json_agg(
        json_build_object(
            'topic_title', topic_title,
            'questions_asked', questions_asked,
            'correct_answers', correct_answers,
            'wrong_answers', wrong_answers,
            'answered_questions', answered_questions,
            'accuracy_percentage', accuracy_percentage,
            'last_activity', last_activity
        )
    ) INTO v_results
    FROM topic_performance_stats
    WHERE user_id = v_user_id;
    
    RETURN json_build_object(
        'success', true,
        'data', COALESCE(v_results, '[]'::JSON)
    );
END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- AI Messages Policies
CREATE POLICY "Users can view own AI messages" ON ai_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own AI messages" ON ai_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Teachers can view AI messages from their students (for shared chats)
CREATE POLICY "Teachers can view student AI messages" ON ai_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shared_chats sc
            JOIN user_profiles up ON sc.teacher_id = up.id
            WHERE sc.student_id = ai_messages.user_id
            AND up.id = auth.uid()
            AND up.role = 'teacher'
        )
    );

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_ai_messages_user_topic ON ai_messages(user_id, topic_title);
CREATE INDEX IF NOT EXISTS idx_ai_messages_user_created ON ai_messages(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_messages_correctness ON ai_messages(user_id, topic_title, has_correctness_feedback);
CREATE INDEX IF NOT EXISTS idx_ai_messages_execution ON ai_messages(execution_id);

-- ============================================================================
-- REALTIME SUBSCRIPTIONS
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE ai_messages;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

SELECT 'Performance tracking database additions created successfully!' as status;