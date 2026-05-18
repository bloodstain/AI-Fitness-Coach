CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(32) UNIQUE,
  email VARCHAR(255) UNIQUE,
  display_name VARCHAR(80) NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  gender VARCHAR(20) NOT NULL,
  age INTEGER NOT NULL CHECK (age > 0),
  height_cm INTEGER NOT NULL CHECK (height_cm > 0),
  current_weight_kg NUMERIC(5, 2) NOT NULL,
  target_weight_kg NUMERIC(5, 2),
  body_fat_percent NUMERIC(5, 2),
  goal VARCHAR(40) NOT NULL,
  target_date DATE,
  weekly_training_days INTEGER NOT NULL DEFAULT 3,
  training_experience VARCHAR(40) NOT NULL DEFAULT 'newbie',
  diet_preferences JSONB NOT NULL DEFAULT '[]',
  health_limitations JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE food_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(120) NOT NULL,
  category VARCHAR(80) NOT NULL,
  unit VARCHAR(20) NOT NULL DEFAULT '100g',
  calories_per_100g NUMERIC(8, 2) NOT NULL,
  protein_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  fat_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  carbs_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  fiber_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  sodium_mg_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  source VARCHAR(80) NOT NULL DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE meal_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  meal_type VARCHAR(30) NOT NULL,
  eaten_at TIMESTAMPTZ NOT NULL,
  image_url TEXT,
  recognition_confidence NUMERIC(4, 3),
  total_calories NUMERIC(8, 2) NOT NULL DEFAULT 0,
  ai_suggestion TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE meal_record_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meal_record_id UUID NOT NULL REFERENCES meal_records(id) ON DELETE CASCADE,
  food_item_id UUID REFERENCES food_items(id),
  name VARCHAR(120) NOT NULL,
  amount NUMERIC(8, 2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  calories NUMERIC(8, 2) NOT NULL,
  protein_g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  fat_g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  carbs_g NUMERIC(8, 2) NOT NULL DEFAULT 0,
  confidence NUMERIC(4, 3),
  user_corrected BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE exercise_library (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(120) NOT NULL,
  body_part VARCHAR(60) NOT NULL,
  equipment VARCHAR(60) NOT NULL,
  level VARCHAR(40) NOT NULL,
  instructions TEXT NOT NULL,
  common_mistakes TEXT,
  contraindications TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workout_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal VARCHAR(40) NOT NULL,
  weekly_frequency INTEGER NOT NULL,
  location VARCHAR(40) NOT NULL,
  duration_minutes INTEGER NOT NULL,
  equipment JSONB NOT NULL DEFAULT '[]',
  limitations JSONB NOT NULL DEFAULT '[]',
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workout_plan_days (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  weekday INTEGER NOT NULL CHECK (weekday BETWEEN 1 AND 7),
  title VARCHAR(120) NOT NULL,
  focus VARCHAR(120) NOT NULL,
  duration_minutes INTEGER NOT NULL
);

CREATE TABLE workout_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_plan_day_id UUID REFERENCES workout_plan_days(id) ON DELETE CASCADE,
  exercise_id UUID REFERENCES exercise_library(id),
  name VARCHAR(120) NOT NULL,
  sets INTEGER NOT NULL,
  reps VARCHAR(40) NOT NULL,
  weight VARCHAR(40),
  rest_seconds INTEGER NOT NULL DEFAULT 60,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE workout_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workout_plan_day_id UUID REFERENCES workout_plan_days(id),
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration_minutes INTEGER,
  calories_burned NUMERIC(8, 2),
  completion_rate NUMERIC(4, 3),
  feedback_difficulty VARCHAR(40),
  notes TEXT
);

CREATE TABLE checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  checkin_type VARCHAR(40) NOT NULL,
  checkin_date DATE NOT NULL,
  status VARCHAR(30) NOT NULL,
  value_text VARCHAR(120),
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, checkin_type, checkin_date)
);

CREATE TABLE body_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  measured_at TIMESTAMPTZ NOT NULL,
  weight_kg NUMERIC(5, 2),
  body_fat_percent NUMERIC(5, 2),
  bmi NUMERIC(5, 2),
  waist_cm NUMERIC(5, 2),
  hip_cm NUMERIC(5, 2),
  photo_url TEXT
);

CREATE TABLE activity_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recorded_date DATE NOT NULL,
  steps INTEGER NOT NULL DEFAULT 0,
  workout_minutes INTEGER NOT NULL DEFAULT 0,
  calories_burned NUMERIC(8, 2) NOT NULL DEFAULT 0,
  avg_heart_rate INTEGER,
  source VARCHAR(80) NOT NULL DEFAULT 'manual',
  metadata JSONB NOT NULL DEFAULT '{}',
  UNIQUE (user_id, recorded_date, source)
);

CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  topic VARCHAR(80) NOT NULL DEFAULT 'coach',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ai_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  safety_level VARCHAR(30) NOT NULL DEFAULT 'normal',
  context_snapshot JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_code VARCHAR(60) NOT NULL,
  status VARCHAR(30) NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ,
  provider VARCHAR(60),
  provider_order_id VARCHAR(120)
);

CREATE INDEX idx_meal_records_user_date ON meal_records (user_id, eaten_at);
CREATE INDEX idx_workout_records_user_date ON workout_records (user_id, started_at);
CREATE INDEX idx_checkins_user_date ON checkins (user_id, checkin_date);
CREATE INDEX idx_activity_records_user_date ON activity_records (user_id, recorded_date);
CREATE INDEX idx_ai_messages_conversation ON ai_messages (conversation_id, created_at);
