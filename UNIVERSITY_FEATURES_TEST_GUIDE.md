# University Features Testing Guide

## Setup Steps

### 1. Database Setup
Run the SQL script `university_database_additions.sql` in your Supabase SQL Editor:
```sql
-- This adds university_type column to user_profiles table
-- Creates university_topics table
-- Sets up proper constraints and RLS policies
```

### 2. Test Account Creation

#### High School Student (Existing Flow)
1. Open signup form
2. Select "Student" role
3. Select "High School" education level
4. Select grade (10, 11, or 12)
5. Complete signup
6. Should see regular math topics home page

#### University Student (New Flow) 
1. Open signup form
2. Select "Student" role  
3. Select "University" education level
4. No grade selection required
5. Complete signup
6. Should see literature topics home page

### 3. Test University Home Page

#### Expected Behavior for University Students:
- Shows "Literature Topics" header (not "Math Topics")
- Shows 3 topic cards:
  - **Small Things** (red) - book icon
  - **Poems** (teal) - create icon  
  - **Short Stories** (blue) - article icon
- Each card shows performance stats if available
- Tapping card auto-sends: "Please assess me on [topic]"

### 4. Test Chat Integration

#### University Student Chat Flow:
1. Tap any literature topic (e.g., "Poems")
2. Should auto-navigate to chat screen
3. Should auto-send message: "please assess me on poems"
4. AI responses should come from university API (`e868e133-0871-477a-b056-eed91a4d4b05`)
5. Performance tracking should work ([CORRECT]/[WRONG] detection)
6. Chat history should persist

#### High School Student Chat Flow (Should be unchanged):
1. Tap any math topic
2. Should auto-send assessment request
3. AI responses should come from math API (`e07906e0-cbb2-47a9-afc9-cebc4a830321`)

### 5. Test Performance Tracking

Both university and high school students should have:
- Questions asked counter
- Correct/wrong answer tracking  
- Progress bars and percentages
- Performance badges (Gold/Silver/Bronze)

### 6. Test Edge Cases

#### Login Flow:
- Existing users should login normally
- University students should see literature home page
- High school students should see math home page

#### Navigation:
- University students should only see university home page on "Home" tab
- Classes, Performance, Profile tabs should work normally

## Common Issues & Debugging

### 1. UUID Database Errors
- **Error**: `invalid input syntax for type uuid: "email@domain.com"`
- **Cause**: Using email instead of proper UUID for database operations
- **Fix**: Use `SupabaseService.instance.client.auth.currentUser?.id` for userId
- **Status**: ✅ Fixed

### 2. Icons Not Showing
- **Status**: ✅ Fixed - Now using Material icons (Icons.book, Icons.create, Icons.article)

### 3. API Not Responding
- Check network connectivity
- Verify API endpoints in `ai_service.dart`
- Check if university student flag is being passed correctly

### 3. Database Errors
- Ensure `university_database_additions.sql` was run successfully
- Check user_profiles table has `university_type` column
- Verify constraints are properly set

### 4. Home Page Not Switching
- Check entry_point.dart logic for university student detection
- Verify UserService is properly storing university_type

### 5. Performance Tracking Issues
- University topics use same performance system as math topics
- Check PerformanceService methods work with literature topic names

## Testing Checklist

- [ ] Database schema updated successfully
- [ ] High school signup flow works (unchanged)
- [ ] University signup flow works (new)
- [ ] University students see literature home page
- [ ] High school students see math home page (unchanged)  
- [ ] Literature topics show correct icons and colors
- [ ] Auto-message system works ("Please assess me on...")
- [ ] University API integration works
- [ ] Chat persistence works for university topics
- [ ] Performance tracking works for literature topics
- [ ] Login flow works for both user types
- [ ] All navigation tabs work properly

## API Endpoints

- **High School (Math)**: `e07906e0-cbb2-47a9-afc9-cebc4a830321`
- **University (Literature)**: `e868e133-0871-477a-b056-eed91a4d4b05`

Both use: `https://cloud.flowiseai.com/api/v1/prediction/[ID]`