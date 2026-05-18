INSERT INTO users (id, display_name, phone)
VALUES ('00000000-0000-0000-0000-000000000001', '林晨', '13800000000')
ON CONFLICT DO NOTHING;

INSERT INTO user_profiles (
  user_id,
  gender,
  age,
  height_cm,
  current_weight_kg,
  target_weight_kg,
  body_fat_percent,
  goal,
  target_date,
  weekly_training_days,
  training_experience,
  diet_preferences,
  health_limitations
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'male',
  28,
  175,
  72.4,
  68,
  21.8,
  '减脂',
  '2026-08-30',
  4,
  '有基础',
  '["高蛋白", "少油", "不吃辣"]',
  '["膝盖无伤", "腰背正常"]'
);

INSERT INTO food_items (name, category, calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g)
VALUES
  ('鸡胸肉', '肉类', 165, 31, 3.6, 0),
  ('米饭', '主食', 116, 2.6, 0.3, 25.9),
  ('西兰花', '蔬菜', 34, 2.8, 0.4, 6.6),
  ('鸡蛋', '蛋类', 143, 12.6, 9.5, 1.1);

INSERT INTO exercise_library (name, body_part, equipment, level, instructions, common_mistakes)
VALUES
  ('深蹲', '腿部', '杠铃', '中级', '保持核心收紧，下蹲至大腿接近平行地面。', '膝盖内扣、弓背'),
  ('卧推', '胸部', '杠铃', '中级', '肩胛收紧，杠铃下放至胸部附近后推起。', '肩胛不稳定、手腕过度后折'),
  ('硬拉', '背腿', '杠铃', '高级', '髋主导发力，保持脊柱中立。', '弓背、杠铃远离身体'),
  ('平板支撑', '核心', '徒手', '新手', '肩、髋、踝保持一条直线。', '塌腰、耸肩');
