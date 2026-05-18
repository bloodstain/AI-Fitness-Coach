export const user = {
  name: '林晨',
  goal: '减脂中',
  avatar: 'LC',
  age: 28,
  heightCm: 175,
  weightKg: 72.4,
  targetWeightKg: 68,
  bodyFatPercent: 21.8,
  bmi: 23.1,
  targetDate: '8月30日',
  weeklyTrainingDays: 4,
  experience: '有基础'
}

export const nutrition = {
  targetCalories: 1800,
  intakeCalories: 1260,
  remainingCalories: 540,
  burnedCalories: 420,
  protein: 82,
  proteinTarget: 120,
  carbs: 138,
  fat: 42
}

export const todayPlan = [
  { icon: 'meal', title: '早餐', subtitle: '已完成', status: 'done', value: '' },
  { icon: 'meal', title: '午餐', subtitle: '待确认', status: 'pending', value: '' },
  { icon: 'workout', title: '18:30 力量训练', subtitle: '下次训练', status: 'next', value: '' },
  { icon: 'water', title: '2200ml 饮水目标', subtitle: '已喝 1200ml', status: 'progress', value: '1200/2200ml' }
]

export const recognizedFoods = [
  { name: '鸡胸肉', amount: 150, unit: 'g', calories: 248, color: '#d89662' },
  { name: '米饭', amount: 120, unit: 'g', calories: 139, color: '#f2f2eb' },
  { name: '西兰花', amount: 100, unit: 'g', calories: 34, color: '#37a845' },
  { name: '鸡蛋', amount: 1, unit: '个', calories: 70, color: '#f4b43f' }
]

export const meals = [
  { type: '早餐', name: '燕麦牛奶', calories: 320, protein: 18, status: '已记录' },
  { type: '午餐', name: '鸡胸肉饭', calories: 491, protein: 46, status: '已记录' },
  { type: '晚餐', name: '拍照记录晚餐', calories: 0, protein: 0, status: '待记录' },
  { type: '加餐', name: '无', calories: 0, protein: 0, status: '可添加' }
]

export const dinnerOptions = [
  { name: '鸡胸肉沙拉', calories: 430, protein: 42, carbs: 22, fat: 12 },
  { name: '虾仁豆腐饭', calories: 510, protein: 39, carbs: 55, fat: 14 },
  { name: '牛肉蔬菜汤', calories: 460, protein: 36, carbs: 28, fat: 18 }
]

export const weekPlan = [
  { day: '周一', title: '上肢力量', meta: '45 分钟 · 重点胸背肩', icon: 'muscle' },
  { day: '周二', title: '有氧', meta: '45 分钟 · 中等强度有氧', icon: 'run' },
  { day: '周四', title: '下肢力量', meta: '45 分钟 · 重点腿臀', icon: 'leg' },
  { day: '周六', title: '全身循环', meta: '45 分钟 · 全身综合训练', icon: 'cycle' }
]

export const workoutExercises = [
  { name: '哑铃卧推', sets: '4组 x 10次', weight: '20kg', done: true },
  { name: '坐姿划船', sets: '4组 x 12次', weight: '35kg', done: true },
  { name: '肩推', sets: '3组 x 10次', weight: '15kg', done: false, active: true },
  { name: '平板支撑', sets: '3组 x 45秒', weight: '', done: false }
]

export const exerciseLibrary = [
  { name: '深蹲', bodyPart: '腿部', level: '中级', mistake: '膝盖内扣', color: '#24a65a' },
  { name: '卧推', bodyPart: '胸部', level: '中级', mistake: '肩胛不稳定', color: '#2f80ed' },
  { name: '硬拉', bodyPart: '背腿', level: '高级', mistake: '弓背发力', color: '#f59e0b' },
  { name: '平板支撑', bodyPart: '核心', level: '新手', mistake: '塌腰', color: '#7c3aed' }
]

export const profileMenus = ['身体数据', '我的目标', '设备同步', '会员中心', '通知设置', '隐私与数据']
