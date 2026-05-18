<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import * as echarts from 'echarts/core'
import { BarChart, LineChart, PieChart } from 'echarts/charts'
import { GridComponent, MarkPointComponent } from 'echarts/components'
import { CanvasRenderer, SVGRenderer } from 'echarts/renderers'
import { mutateApi, requestApi, uploadImageApi } from '../services/api'

echarts.use([LineChart, BarChart, PieChart, GridComponent, MarkPointComponent, CanvasRenderer, SVGRenderer])

type Screen =
  | 'home'
  | 'dietCamera'
  | 'diet'
  | 'dietAdvice'
  | 'training'
  | 'todayWorkout'
  | 'exerciseLibrary'
  | 'activity'
  | 'aiChat'
  | 'aiReview'
  | 'profile'
  | 'onboarding'

const props = defineProps<{
  screen: Screen
}>()

const heartChartRef = ref<HTMLElement | null>(null)
const loadChartRef = ref<HTMLElement | null>(null)
const reviewScoreRef = ref<HTMLElement | null>(null)
const reviewWeightRef = ref<HTMLElement | null>(null)
const reviewTrainRef = ref<HTMLElement | null>(null)
const reviewDietRef = ref<HTMLElement | null>(null)
let heartChart: echarts.ECharts | null = null
let loadChart: echarts.ECharts | null = null
let reviewScoreChart: echarts.ECharts | null = null
let reviewWeightChart: echarts.ECharts | null = null
let reviewTrainChart: echarts.ECharts | null = null
let reviewDietChart: echarts.ECharts | null = null
let chartRetryTimer: ReturnType<typeof setTimeout> | null = null
const appData = ref<any>(null)
const recognitionFoods = ref<any[] | null>(null)
const recognitionConfidence = ref(0.86)
const recognitionPreviewImage = ref('')
const isRecognizing = ref(false)
const replaceWorkoutExerciseId = ref('')
const selectedGoal = ref('')
const selectedFrequency = ref(4)
const selectedLocation = ref('')
const selectedDuration = ref(45)
const selectedEquipment = ref<string[]>([])
const selectedPlanExercises = ref<any[]>([])
const selectedLimitations = ref<string[]>([])
const isGeneratingPlan = ref(false)
const showPlanHistory = ref(false)
const planHistory = ref<any[]>([])
const selectedHistoryPlanId = ref('')
const showBodyMetrics = ref(false)
const isSavingBodyMetrics = ref(false)
const bodyMetricForm = ref({
  weight_kg: '',
  body_fat_percent: '',
  bmi: '',
  waist_cm: '',
  hip_cm: '',
  note: ''
})
const isSavingGoalProfile = ref(false)
const goalProfileForm = ref({
  gender: 'male',
  age: '28',
  height_cm: '175',
  weight_kg: '72.4',
  target_weight_kg: '68',
  goal: '减脂',
  target_date: '2026-08-30',
  weekly_training_days: '4',
  training_experience: '有基础',
  diet_preferences: [] as string[],
  health_limitations_text: ''
})

const heartRateSamples = [
  86, 88, 92, 99, 105, 112, 118, 121, 119, 127, 123, 134, 138, 136, 141, 137,
  146, 155, 132, 139, 147, 152, 160, 168, 151, 142, 128, 122, 119, 108, 112
]

const heartRateTimes = heartRateSamples.map((_, index) => `${index * 5}`)
const trainingLoadSamples = [560, 680, 720, 600, 360, 300, 300]
const reviewWeightSamples = [72.8, 72.6, 72.55, 72.35, 72.4, 72.05, 71.88, 71.64]
const reviewTrainSamples = [56, 68, 76, 94, 58, 72]
const reviewDietSamples = [54, 66, 60, 78, 76, 61]

function resolveChartElement(target: unknown): HTMLElement | null {
  const maybeElement = target as HTMLElement
  if (maybeElement?.nodeType === 1) return maybeElement

  const maybeComponent = target as { $el?: HTMLElement }
  if (maybeComponent?.$el?.nodeType === 1) return maybeComponent.$el

  return null
}

function chartReady(element: HTMLElement) {
  const rect = element.getBoundingClientRect()
  return rect.width > 40 && rect.height > 40
}

function initActivityCharts(retryCount = 0) {
  if (props.screen !== 'activity') return
  const heartEl = resolveChartElement(heartChartRef.value) || document.querySelector<HTMLElement>('.heart-chart.echarts-chart')
  const loadEl = resolveChartElement(loadChartRef.value) || document.querySelector<HTMLElement>('.load-chart.echarts-chart')
  if (!heartEl || !loadEl) return

  if (!chartReady(heartEl) || !chartReady(loadEl)) {
    if (retryCount < 20) {
      chartRetryTimer = setTimeout(() => initActivityCharts(retryCount + 1), 80)
    }
    return
  }

  heartChart?.dispose()
  loadChart?.dispose()

  heartChart = echarts.init(heartEl, undefined, { renderer: 'svg' })
  heartChart.setOption({
    grid: { left: 32, right: 12, top: 12, bottom: 20 },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: heartRateTimes,
      axisTick: { show: false },
      axisLine: { lineStyle: { color: '#e2e6ea' } },
      axisLabel: {
        color: '#69717b',
        fontSize: 11,
        interval: 5,
        formatter: (value: string) => `${value}分钟`
      }
    },
    yAxis: {
      type: 'value',
      min: 60,
      max: 180,
      interval: 40,
      axisTick: { show: false },
      axisLine: { show: false },
      axisLabel: { color: '#69717b', fontSize: 11 },
      splitLine: { lineStyle: { color: '#edf0f2', type: 'dashed' } }
    },
    series: [{
      type: 'line',
      smooth: true,
      symbol: 'circle',
      showSymbol: true,
      symbolSize: 6,
      data: heartRateSamples,
      lineStyle: { width: 2, color: '#ff3b3b' },
      itemStyle: { color: '#ff3b3b' },
      areaStyle: { color: 'rgba(255,59,59,.10)' },
      markPoint: {
        symbol: 'roundRect',
        symbolSize: [34, 22],
        label: { formatter: '168', color: '#fff', fontSize: 11, fontWeight: 700 },
        itemStyle: { color: '#f24848' },
        data: [{ coord: ['115', 168] }]
      }
    }]
  })

  loadChart = echarts.init(loadEl, undefined, { renderer: 'svg' })
  loadChart.setOption({
    grid: { left: 32, right: 10, top: 20, bottom: 20 },
    xAxis: {
      type: 'category',
      data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
      axisTick: { show: false },
      axisLine: { lineStyle: { color: '#e2e6ea' } },
      axisLabel: { color: '#69717b', fontSize: 11 }
    },
    yAxis: {
      type: 'value',
      min: 0,
      max: 900,
      interval: 300,
      axisTick: { show: false },
      axisLine: { show: false },
      axisLabel: { color: '#69717b', fontSize: 11 },
      splitLine: { lineStyle: { color: '#edf0f2', type: 'dashed' } }
    },
    series: [{
      type: 'bar',
      barWidth: 26,
      data: trainingLoadSamples.map((value, index) => ({
        value,
        itemStyle: { color: index < 4 ? '#2f8bf2' : '#e1e3e6' }
      })),
      label: {
        show: true,
        position: 'top',
        formatter: ({ value }: { value: number }) => value >= 500 ? String(value) : '',
        color: '#69717b',
        fontSize: 11
      },
      itemStyle: { borderRadius: [4, 4, 0, 0] }
    }]
  })

  heartChart.resize()
  loadChart.resize()
}

function initReviewCharts(retryCount = 0) {
  if (props.screen !== 'aiReview') return
  const scoreEl = resolveChartElement(reviewScoreRef.value) || document.querySelector<HTMLElement>('.review-score-chart')
  const weightEl = resolveChartElement(reviewWeightRef.value) || document.querySelector<HTMLElement>('.review-weight-chart')
  const trainEl = resolveChartElement(reviewTrainRef.value) || document.querySelector<HTMLElement>('.review-train-chart')
  const dietEl = resolveChartElement(reviewDietRef.value) || document.querySelector<HTMLElement>('.review-diet-chart')
  const elements = [scoreEl, weightEl, trainEl, dietEl]
  if (elements.some(element => !element)) return
  if (elements.some(element => element && !chartReady(element))) {
    if (retryCount < 20) {
      chartRetryTimer = setTimeout(() => initReviewCharts(retryCount + 1), 80)
    }
    return
  }

  reviewScoreChart?.dispose()
  reviewWeightChart?.dispose()
  reviewTrainChart?.dispose()
  reviewDietChart?.dispose()

  reviewScoreChart = echarts.init(scoreEl, undefined, { renderer: 'svg' })
  reviewScoreChart.setOption({
    series: [{
      type: 'pie',
      radius: ['83%', '91%'],
      center: ['50%', '50%'],
      startAngle: 218,
      clockwise: true,
      silent: true,
      label: { show: false },
      data: [
        { value: 82, itemStyle: { color: '#08a64f' } },
        { value: 18, itemStyle: { color: '#dcefe4' } },
        { value: 22, itemStyle: { color: 'transparent' } }
      ]
    }]
  })

  reviewWeightChart = echarts.init(weightEl, undefined, { renderer: 'svg' })
  reviewWeightChart.setOption({
    grid: { left: 6, right: 8, top: 10, bottom: 22 },
    xAxis: {
      type: 'category',
      data: ['5/10', '', '', '', '', '', '', '5/16'],
      boundaryGap: false,
      axisTick: { show: false },
      axisLine: { lineStyle: { color: '#dfe5e8' } },
      axisLabel: { color: '#59616b', fontSize: 10, interval: 0 }
    },
    yAxis: { type: 'value', min: 71.4, max: 73, show: false },
    series: [{
      type: 'line',
      smooth: true,
      symbol: 'circle',
      symbolSize: 6,
      data: reviewWeightSamples,
      lineStyle: { width: 2, color: '#159f4f' },
      itemStyle: { color: '#159f4f' },
      areaStyle: { color: 'rgba(20, 166, 79, .16)' }
    }]
  })

  const barOption = (data: number[], color: string) => ({
    grid: { left: 30, right: 10, top: 14, bottom: 22 },
    xAxis: {
      type: 'category',
      data: ['5/10', '', '', '', '', '5/16'],
      axisTick: { show: false },
      axisLine: { lineStyle: { color: '#dfe5e8' } },
      axisLabel: { color: '#59616b', fontSize: 10, interval: 0 }
    },
    yAxis: {
      type: 'value',
      min: 0,
      max: 100,
      interval: 50,
      axisTick: { show: false },
      axisLine: { show: false },
      axisLabel: { color: '#59616b', fontSize: 10, formatter: '{value}%' },
      splitLine: { lineStyle: { color: '#cfd6dc', type: 'dashed' } }
    },
    series: [{
      type: 'bar',
      barWidth: 8,
      barCategoryGap: '46%',
      data,
      itemStyle: { color, borderRadius: [3, 3, 0, 0] }
    }]
  })

  reviewTrainChart = echarts.init(trainEl, undefined, { renderer: 'svg' })
  reviewTrainChart.setOption(barOption(reviewTrainSamples, '#2578f0'))
  reviewDietChart = echarts.init(dietEl, undefined, { renderer: 'svg' })
  reviewDietChart.setOption(barOption(reviewDietSamples, '#ff820f'))

  reviewScoreChart.resize()
  reviewWeightChart.resize()
  reviewTrainChart.resize()
  reviewDietChart.resize()
}

function initCharts() {
  initActivityCharts()
  initReviewCharts()
}

function scheduleCharts() {
  nextTick(() => {
    chartRetryTimer = setTimeout(() => initCharts(), 120)
    if (typeof requestAnimationFrame !== 'undefined') {
      requestAnimationFrame(() => initCharts())
    }
  })
}

async function loadAppData() {
  try {
    appData.value = await requestApi<any>('/api/app-data')
    syncTrainingConfig()
    syncBodyMetricForm()
    syncGoalProfileForm()
  } catch (error) {
    console.warn('Failed to load app data', error)
  }
}

function syncTrainingConfig() {
  const training = appData.value?.training
  const cachedPlanExercises = uni.getStorageSync('selectedPlanExercises') || []
  selectedGoal.value = training?.goal || user.value.goal || '减脂'
  selectedFrequency.value = Number(training?.weekly_frequency || user.value.weekly_training_days || 4)
  selectedLocation.value = training?.location || '健身房'
  selectedDuration.value = Number(training?.duration_minutes || 45)
  selectedEquipment.value = [...(training?.equipment || ['哑铃', '杠铃'])]
  selectedPlanExercises.value = [...(cachedPlanExercises.length ? cachedPlanExercises : training?.preferred_exercises || [])]
  selectedLimitations.value = [...(training?.limitations || ['膝盖无伤', '腰背正常'])]
}

onMounted(async () => {
  await loadAppData()
  scheduleCharts()
  if (typeof window !== 'undefined') {
    window.addEventListener('resize', initCharts)
  }
})

onBeforeUnmount(() => {
  if (typeof window !== 'undefined') {
    window.removeEventListener('resize', initCharts)
  }
  if (chartRetryTimer) {
    clearTimeout(chartRetryTimer)
  }
  heartChart?.dispose()
  loadChart?.dispose()
  reviewScoreChart?.dispose()
  reviewWeightChart?.dispose()
  reviewTrainChart?.dispose()
  reviewDietChart?.dispose()
})

const tabs = [
  { key: 'home', label: '首页', icon: '⌂', url: '/pages/home/index' },
  { key: 'diet', label: '饮食', icon: '◌', url: '/pages/diet/index' },
  { key: 'training', label: '训练', icon: '▥', url: '/pages/training/index' },
  { key: 'ai', label: 'AI私教', icon: '✦', url: '/pages/ai-chat/index' },
  { key: 'profile', label: '我的', icon: '◒', url: '/pages/profile/index' }
]

const screenTab: Record<Screen, string> = {
  home: 'home',
  dietCamera: 'diet',
  diet: 'diet',
  dietAdvice: 'diet',
  training: 'training',
  todayWorkout: 'training',
  exerciseLibrary: 'training',
  activity: 'training',
  aiChat: 'ai',
  aiReview: 'ai',
  profile: 'profile',
  onboarding: ''
}

const fallbackUser = {
  name: '林晨',
  goal: '减脂',
  avatar: 'LC',
  age: 28,
  height_cm: 175,
  weight_kg: 72.4,
  target_weight_kg: 68,
  body_fat_percent: 21.8,
  bmi: 23.1,
  target_date_label: '8月30日',
  weekly_training_days: 4,
  training_experience: '有基础',
  membership_status: 'Pro 试用中'
}

const fallbackNutrition = {
  target_calories: 1800,
  intake_calories: 1260,
  remaining_calories: 540,
  burned_calories: 420,
  protein_g: 82,
  protein_target_g: 120,
  carbs_g: 138,
  carbs_target_g: 200,
  fat_g: 42,
  fat_target_g: 60,
  protein_gap_g: 38
}

const fallbackHomePlan = [
  { icon_key: 'meal', title: '早餐', subtitle: '已完成', status: 'done', value_text: '' },
  { icon_key: 'meal', title: '午餐', subtitle: '待确认', status: 'pending', value_text: '' },
  { icon_key: 'workout', title: '18:30 力量训练', subtitle: '下次训练', status: 'next', value_text: '' },
  { icon_key: 'water', title: '2200ml 饮水目标', subtitle: '已喝 1200ml', status: 'progress', value_text: '1200/2200ml' }
]

const fallbackFoods = [
  { name: '鸡胸肉', amount: 150, unit: 'g', calories: 248, thumb_key: 'chicken' },
  { name: '米饭', amount: 120, unit: 'g', calories: 139, thumb_key: 'rice' },
  { name: '西兰花', amount: 100, unit: 'g', calories: 34, thumb_key: 'broccoli' },
  { name: '鸡蛋', amount: 1, unit: '个', calories: 70, thumb_key: 'egg' }
]

const fallbackMeals = [
  { meal_type: 'breakfast', title: '早餐', subtitle: '燕麦牛奶', suggested_range: '建议 450-550 kcal', calories: 320, protein_g: 18, image_key: 'oatmeal' },
  { meal_type: 'lunch', title: '午餐', subtitle: '鸡胸肉饭', suggested_range: '建议 600-700 kcal', calories: 491, protein_g: 46, image_key: 'chicken' },
  { meal_type: 'dinner', title: '晚餐', subtitle: '拍照记录晚餐', suggested_range: '建议 450-550 kcal', calories: 0, protein_g: 0, image_key: 'dish' },
  { meal_type: 'snack', title: '加餐', subtitle: '记录加餐', suggested_range: '建议 150-250 kcal', calories: 449, protein_g: 0, image_key: 'snack' }
]

const fallbackActivity = {
  weekly_workouts_done: 3,
  weekly_workouts_target: 4,
  workout_minutes: 156,
  calories_burned: 1280,
  steps: 7420,
  avg_heart_rate: 128,
  max_heart_rate: 168,
  training_load_total: 2560,
  synced_device: 'Apple Health',
  synced_status: '已同步',
  synced_ago: '5分钟前',
  week: [
    { weekday_label: '周一', day_label: '6/2', done: true, active: false },
    { weekday_label: '周二', day_label: '6/3', done: true, active: false },
    { weekday_label: '周三', day_label: '6/4', done: true, active: false },
    { weekday_label: '周四', day_label: '6/5', done: false, active: true },
    { weekday_label: '周五', day_label: '6/6', done: false, active: false },
    { weekday_label: '周六', day_label: '6/7', done: false, active: false },
    { weekday_label: '周日', day_label: '6/8', done: false, active: false }
  ],
  strength: [
    { name: '卧推', value_text: '42.5 kg', delta_text: '+2.5 kg', image_key: 'bench' },
    { name: '深蹲', value_text: '60 kg', delta_text: '+5 kg', image_key: 'squat' }
  ]
}

const user = computed(() => appData.value?.user ?? fallbackUser)
const nutrition = computed(() => appData.value?.diet?.nutrition ?? fallbackNutrition)
const recognizedFoods = computed(() => appData.value?.diet?.recognizedFoods ?? fallbackFoods)
const cameraFoods = computed(() => recognitionFoods.value ?? recognizedFoods.value)
const meals = computed(() => appData.value?.diet?.meals ?? fallbackMeals)
const activity = computed(() => appData.value?.activity ?? fallbackActivity)
const aiChat = computed(() => appData.value?.aiChat ?? {})
const aiReview = computed(() => appData.value?.aiReview ?? {})
const homePlan = computed(() => appData.value?.homePlan ?? fallbackHomePlan)
const bodyMetrics = computed(() => appData.value?.bodyMetrics ?? { latest: null, history: [] })
const proteinPercent = computed(() => `${Math.min(100, Math.round((nutrition.value.protein_g / nutrition.value.protein_target_g) * 100))}%`)
const caloriePercent = computed(() => `${Math.min(100, Math.round((nutrition.value.intake_calories / nutrition.value.target_calories) * 100))}%`)
const targetLoss = computed(() => Math.max(0, Number(user.value.weight_kg) - Number(user.value.target_weight_kg)).toFixed(1))
const recognizedTotalCalories = computed(() => cameraFoods.value.reduce((total: number, item: any) => total + Number(item.calories), 0))
const recognitionConfidencePercent = computed(() => `${Math.round(recognitionConfidence.value * 100)}%`)
const goalOptions = [
  { label: '减脂', icon: 'icon-fire' },
  { label: '增肌', icon: 'icon-muscle' },
  { label: '塑形', icon: 'icon-shape' },
  { label: '体能', icon: 'icon-stamina' }
]
const locationOptions = [
  { label: '健身房', icon: 'icon-dumbbell' },
  { label: '居家', icon: 'icon-home' },
  { label: '户外', icon: 'icon-tree' }
]
const equipmentOptions = [
  { label: '哑铃', icon: 'icon-dumbbell' },
  { label: '杠铃', icon: 'icon-dumbbell' },
  { label: '跑步机', icon: 'icon-runner' }
]
const limitationOptions = ['膝盖无伤', '腰背正常']
const onboardingGoalOptions = [
  { label: '减脂', icon: 'on-fire' },
  { label: '增肌', icon: 'on-muscle' },
  { label: '塑形', icon: 'on-shape' },
  { label: '健康维持', icon: 'on-health' }
]
const trainingExperienceOptions = [
  { label: '新手', icon: 'on-user' },
  { label: '有基础', icon: 'on-dumbbell' },
  { label: '进阶', icon: 'on-star' }
]
const dietPreferenceOptions = ['高蛋白', '少油', '不吃辣']

const quickActions = [
  { key: 'meal', label: '拍饮食', icon: 'camera', url: '/pages/diet-camera/index' },
  { key: 'weight', label: '记体重', icon: 'scale', url: '/pages/profile/index' },
  { key: 'workout', label: '开始训练', icon: 'dumbbell', url: '/pages/today-workout/index' },
  { key: 'water', label: '喝水', icon: 'water', url: '/pages/ai-review/index' }
]

const mealItems = computed(() => recognizedFoods.value.map((item: any) => [item.name, `${item.amount}${item.unit}`, `${item.calories} kcal`]))
const dinnerOptions = computed(() => (appData.value?.diet?.dinnerOptions ?? [
  { option_label: '方案A', name: '鸡胸肉沙拉', calories: 430, protein_g: 42, carbs_g: 22, fat_g: 12 },
  { option_label: '方案B', name: '虾仁豆腐饭', calories: 510, protein_g: 39, carbs_g: 55, fat_g: 14 },
  { option_label: '方案C', name: '牛肉蔬菜汤', calories: 460, protein_g: 36, carbs_g: 28, fat_g: 18 }
]).map((item: any) => [
  item.option_label,
  item.name,
  `${item.calories} kcal`,
  `蛋白 ${item.protein_g}g`,
  `碳水 ${item.carbs_g}g`,
  `脂肪 ${item.fat_g}g`
]))
const weekPlan = computed(() => (appData.value?.training?.weekPlan ?? [
  { weekday_label: '周一', title: '上肢力量', duration_minutes: 45, focus: '重点胸背肌', icon_key: 'muscle' },
  { weekday_label: '周二', title: '有氧', duration_minutes: 45, focus: '中等强度有氧', icon_key: 'run' },
  { weekday_label: '周四', title: '下肢力量', duration_minutes: 45, focus: '重点腿臀', icon_key: 'leg' },
  { weekday_label: '周六', title: '全身循环', duration_minutes: 45, focus: '全身综合训练', icon_key: 'cycle' }
]).map((item: any) => [
  item.weekday_label,
  item.title,
  `${item.duration_minutes} 分钟 · ${item.focus}`,
  item.icon_key
]))
const historyPlanTitle = computed(() => {
  const plan = appData.value?.training
  if (!plan) return '本周计划预览'
  return `${plan.goal || '训练'} · ${plan.weekly_frequency || 4}练 · ${plan.duration_minutes || 45}分钟`
})
const workouts = computed(() => (appData.value?.todayWorkout?.exercises ?? [
  { name: '哑铃卧推', sets: 4, reps: '10次', weight: '20kg', status: 'done', thumb_key: 'bench' },
  { name: '坐姿划船', sets: 4, reps: '12次', weight: '35kg', status: 'active', thumb_key: 'row' },
  { name: '肩推', sets: 3, reps: '10次', weight: '15kg', status: 'todo', thumb_key: 'press' },
  { name: '平板支撑', sets: 3, reps: '45秒', weight: '自重', status: 'todo', thumb_key: 'plank' }
]).map((item: any) => [
  item.name,
  `${item.sets}组 x ${item.reps}`,
  item.weight,
  item.status,
  item.thumb_key,
  item.id
]))
const library = computed(() => appData.value?.exerciseLibrary ?? [
  { name: '深蹲', body_part: '腿部', level: '中级', common_mistake: '膝盖内扣', target_muscle: '股四头肌', alternative: '箱式深蹲', image_key: 'squat' },
  { name: '卧推', body_part: '胸部', level: '中级', common_mistake: '肩胛不稳定', target_muscle: '胸大肌', alternative: '哑铃卧推', image_key: 'bench' },
  { name: '硬拉', body_part: '背腿', level: '高级', common_mistake: '弓背发力', target_muscle: '腘绳肌', alternative: '壶铃硬拉', image_key: 'deadlift' },
  { name: '平板支撑', body_part: '核心', level: '新手', common_mistake: '塌腰', target_muscle: '腹横肌', alternative: '死虫', image_key: 'plank' }
])
const profileMenus = computed(() => appData.value?.profileMenus ?? [
  { icon_key: 'body', title: '身体数据', note: '' },
  { icon_key: 'target', title: '我的目标', note: '' },
  { icon_key: 'watch', title: '设备同步', note: '体脂秤 未连接' },
  { icon_key: 'vip', title: '会员中心', note: '' },
  { icon_key: 'bell', title: '通知设置', note: '' },
  { icon_key: 'lock', title: '隐私与数据', note: '' }
])

function go(url: string) {
  uni.reLaunch({ url })
}

function openQuickAction(url: string) {
  uni.navigateTo({ url })
}

function goDietCamera() {
  uni.navigateTo({ url: '/pages/diet-camera/index' })
}

function goDietRecord() {
  uni.reLaunch({ url: '/pages/diet/index' })
}

function chooseFoodImage() {
  if (isRecognizing.value) return
  uni.chooseImage({
    count: 1,
    sizeType: ['compressed'],
    sourceType: ['camera', 'album'],
    success: async (chooseResult) => {
      const filePath = chooseResult.tempFilePaths[0]
      recognitionPreviewImage.value = filePath
      isRecognizing.value = true
      try {
        const result = await uploadImageApi<any>('/api/diet/recognize', filePath)
        recognitionFoods.value = result.items || []
        recognitionConfidence.value = Number(result.confidence || 0.86)
      } catch (error) {
        uni.showToast({ title: '识别失败', icon: 'none' })
        console.warn('Food recognition failed', error)
      } finally {
        isRecognizing.value = false
      }
    }
  })
}

function goDietAdvice() {
  uni.navigateTo({ url: '/pages/diet-advice/index' })
}

function goTodayWorkout() {
  uni.navigateTo({ url: '/pages/today-workout/index' })
}

function changeFrequency(delta: number) {
  selectedFrequency.value = Math.max(3, Math.min(6, selectedFrequency.value + delta))
}

function changeDuration(delta: number) {
  selectedDuration.value = Math.max(30, Math.min(60, selectedDuration.value + delta))
}

function toggleEquipment(label: string) {
  selectedEquipment.value = selectedEquipment.value.includes(label)
    ? selectedEquipment.value.filter(item => item !== label)
    : [...selectedEquipment.value, label]
}

function toggleLimitation(label: string) {
  selectedLimitations.value = selectedLimitations.value.includes(label)
    ? selectedLimitations.value.filter(item => item !== label)
    : [...selectedLimitations.value, label]
}

async function generatePlan() {
  if (isGeneratingPlan.value) return
  isGeneratingPlan.value = true
  try {
    const plan = await mutateApi<any>('/api/training/plan/generate', 'POST', {
      goal: selectedGoal.value,
      weekly_frequency: selectedFrequency.value,
      location: selectedLocation.value,
      duration_minutes: selectedDuration.value,
      equipment: selectedEquipment.value,
      preferred_exercises: selectedPlanExercises.value,
      limitations: selectedLimitations.value
    })
    appData.value = {
      ...appData.value,
      training: plan
    }
    selectedPlanExercises.value = [...(plan.preferred_exercises || [])]
    uni.removeStorageSync('selectedPlanExercises')
    uni.showToast({ title: '计划已生成', icon: 'success' })
  } catch (error) {
    uni.showToast({ title: '生成失败', icon: 'none' })
    console.warn('Generate plan failed', error)
  } finally {
    isGeneratingPlan.value = false
  }
}

async function togglePlanHistory() {
  showPlanHistory.value = !showPlanHistory.value
  if (!showPlanHistory.value) return
  try {
    planHistory.value = await requestApi<any[]>('/api/training/plans')
  } catch (error) {
    uni.showToast({ title: '历史加载失败', icon: 'none' })
    console.warn('Load plan history failed', error)
  }
}

async function openHistoryPlan(planId: string) {
  try {
    const plan = await requestApi<any>(`/api/training/plans/${planId}`)
    selectedHistoryPlanId.value = planId
    appData.value = {
      ...appData.value,
      training: plan
    }
    syncTrainingConfig()
    showPlanHistory.value = false
  } catch (error) {
    uni.showToast({ title: '计划加载失败', icon: 'none' })
    console.warn('Open plan history failed', error)
  }
}

function goExerciseLibrary(workoutExerciseId = '', from: 'training' | 'todayWorkout' = 'training') {
  const activeExerciseId = from === 'todayWorkout'
    ? workoutExerciseId || appData.value?.todayWorkout?.exercises?.find((item: any) => item.status === 'active')?.id || ''
    : ''
  if (activeExerciseId) {
    replaceWorkoutExerciseId.value = activeExerciseId
    uni.setStorageSync('replaceWorkoutExerciseId', activeExerciseId)
  }
  const params = activeExerciseId ? `?from=${from}&replaceId=${activeExerciseId}` : `?from=${from}`
  uni.navigateTo({ url: `/pages/exercise-library/index${params}` })
}

async function selectLibraryExercise(exercise: any) {
  const hashQuery = typeof window !== 'undefined' ? window.location.hash.split('?')[1] || '' : ''
  const fromPage = hashQuery ? new URLSearchParams(hashQuery).get('from') || '' : ''
  const replaceIdFromUrl = hashQuery ? new URLSearchParams(hashQuery).get('replaceId') || '' : ''
  const workoutExerciseId = replaceWorkoutExerciseId.value || uni.getStorageSync('replaceWorkoutExerciseId') || replaceIdFromUrl
  if (fromPage !== 'todayWorkout' || !workoutExerciseId) {
    if (exercise?.name && !selectedPlanExercises.value.some(item => item.name === exercise.name)) {
      selectedPlanExercises.value = [
        ...selectedPlanExercises.value,
        {
          id: exercise.id,
          name: exercise.name,
          body_part: exercise.body_part,
          level: exercise.level,
          image_key: exercise.image_key
        }
      ]
      uni.setStorageSync('selectedPlanExercises', selectedPlanExercises.value)
    }
    uni.reLaunch({ url: '/pages/training/index' })
    return
  }

  try {
    if (!exercise?.id) {
      await loadAppData()
      exercise = appData.value?.exerciseLibrary?.find((item: any) => item.name === exercise?.name)
    }
    if (!exercise?.id) {
      uni.showToast({ title: '动作数据未加载', icon: 'none' })
      return
    }
    await mutateApi(`/api/training/today/exercises/${workoutExerciseId}/replace`, 'PATCH', {
      exercise_id: exercise.id
    })
    uni.removeStorageSync('replaceWorkoutExerciseId')
    replaceWorkoutExerciseId.value = ''
    uni.reLaunch({ url: `/pages/today-workout/index?refresh=${Date.now()}` })
  } catch (error) {
    uni.showToast({ title: '替换失败', icon: 'none' })
    console.warn('Replace exercise failed', error)
  }
}

function leaveExerciseLibrary() {
  const hashQuery = typeof window !== 'undefined' ? window.location.hash.split('?')[1] || '' : ''
  const fromPage = hashQuery ? new URLSearchParams(hashQuery).get('from') || '' : ''
  goBack(fromPage === 'todayWorkout' ? '/pages/today-workout/index' : '/pages/training/index')
}

function removePlanExercise(name: string) {
  selectedPlanExercises.value = selectedPlanExercises.value.filter(item => item.name !== name)
  uni.setStorageSync('selectedPlanExercises', selectedPlanExercises.value)
}

function goActivity() {
  uni.navigateTo({ url: '/pages/activity/index' })
}

function goAiReview() {
  uni.navigateTo({ url: '/pages/ai-review/index' })
}

function goOnboarding() {
  uni.navigateTo({ url: '/pages/onboarding/index' })
}

function formatMetricDate(value: string) {
  if (!value) return '暂无记录'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '刚刚'
  const month = date.getMonth() + 1
  const day = date.getDate()
  const hour = String(date.getHours()).padStart(2, '0')
  const minute = String(date.getMinutes()).padStart(2, '0')
  return `${month}月${day}日 ${hour}:${minute}`
}

function syncBodyMetricForm() {
  const latest = bodyMetrics.value.latest || user.value || {}
  bodyMetricForm.value = {
    weight_kg: latest.weight_kg ? String(latest.weight_kg) : '',
    body_fat_percent: latest.body_fat_percent ? String(latest.body_fat_percent) : '',
    bmi: latest.bmi ? String(latest.bmi) : '',
    waist_cm: latest.waist_cm ? String(latest.waist_cm) : '',
    hip_cm: latest.hip_cm ? String(latest.hip_cm) : '',
    note: latest.note || ''
  }
}

function openBodyMetrics() {
  showBodyMetrics.value = !showBodyMetrics.value
  if (showBodyMetrics.value) syncBodyMetricForm()
}

function handleProfileMenu(item: any) {
  if (item.icon_key === 'body') {
    openBodyMetrics()
    return
  }
  if (item.icon_key === 'target') {
    goOnboarding()
  }
}

function toNumber(value: string) {
  const number = Number(value)
  return Number.isFinite(number) ? number : null
}

function syncGoalProfileForm() {
  const current = user.value || {}
  goalProfileForm.value = {
    gender: current.gender || 'male',
    age: current.age ? String(current.age) : '28',
    height_cm: current.height_cm ? String(current.height_cm) : '175',
    weight_kg: current.weight_kg ? String(current.weight_kg) : '72.4',
    target_weight_kg: current.target_weight_kg ? String(current.target_weight_kg) : '68',
    goal: current.goal || '减脂',
    target_date: current.target_date ? String(current.target_date).slice(0, 10) : '2026-08-30',
    weekly_training_days: current.weekly_training_days ? String(current.weekly_training_days) : '4',
    training_experience: current.training_experience || '有基础',
    diet_preferences: [...(current.diet_preferences || ['高蛋白', '少油', '不吃辣'])],
    health_limitations_text: (current.health_limitations || ['膝盖无伤', '腰背正常']).join('、')
  }
}

function toggleDietPreference(label: string) {
  const selected = goalProfileForm.value.diet_preferences
  goalProfileForm.value.diet_preferences = selected.includes(label)
    ? selected.filter(item => item !== label)
    : [...selected, label]
}

function parseLimitations(text: string) {
  return text
    .split(/[、,\n，]/)
    .map(item => item.trim())
    .filter(Boolean)
}

async function saveGoalProfile() {
  if (isSavingGoalProfile.value) return
  const payload = {
    gender: goalProfileForm.value.gender,
    age: toNumber(goalProfileForm.value.age),
    height_cm: toNumber(goalProfileForm.value.height_cm),
    weight_kg: toNumber(goalProfileForm.value.weight_kg),
    target_weight_kg: toNumber(goalProfileForm.value.target_weight_kg),
    goal: goalProfileForm.value.goal,
    target_date: goalProfileForm.value.target_date,
    weekly_training_days: toNumber(goalProfileForm.value.weekly_training_days),
    training_experience: goalProfileForm.value.training_experience,
    diet_preferences: goalProfileForm.value.diet_preferences,
    health_limitations: parseLimitations(goalProfileForm.value.health_limitations_text)
  }
  if (!payload.age || !payload.height_cm || !payload.weight_kg || !payload.target_weight_kg) {
    uni.showToast({ title: '请完整填写基础信息', icon: 'none' })
    return
  }
  isSavingGoalProfile.value = true
  try {
    const updatedUser = await mutateApi<any>('/api/users/me/profile', 'PATCH', payload)
    appData.value = {
      ...appData.value,
      user: updatedUser,
      activity: {
        ...(appData.value?.activity || activity.value),
        weekly_workouts_target: updatedUser.weekly_training_days
      },
      aiChat: {
        ...(appData.value?.aiChat || {}),
        context: {
          ...(appData.value?.aiChat?.context || {}),
          goal_label: `${updatedUser.goal}目标`,
          workouts_label: `本周 ${updatedUser.weekly_training_days} 练`
        }
      }
    }
    const plan = await mutateApi<any>('/api/training/plan/generate', 'POST', {
      goal: updatedUser.goal,
      weekly_frequency: updatedUser.weekly_training_days,
      location: selectedLocation.value || '健身房',
      duration_minutes: selectedDuration.value || 45,
      equipment: selectedEquipment.value.length ? selectedEquipment.value : ['哑铃', '杠铃'],
      preferred_exercises: selectedPlanExercises.value,
      limitations: payload.health_limitations
    })
    appData.value = {
      ...appData.value,
      training: plan
    }
    syncTrainingConfig()
    syncGoalProfileForm()
    uni.showToast({ title: '目标已保存', icon: 'success' })
    setTimeout(() => uni.reLaunch({ url: '/pages/training/index' }), 500)
  } catch (error) {
    uni.showToast({ title: '保存失败', icon: 'none' })
    console.warn('Save goal profile failed', error)
  } finally {
    isSavingGoalProfile.value = false
  }
}

async function saveBodyMetrics() {
  if (isSavingBodyMetrics.value) return
  const payload = {
    weight_kg: toNumber(bodyMetricForm.value.weight_kg),
    body_fat_percent: toNumber(bodyMetricForm.value.body_fat_percent),
    bmi: toNumber(bodyMetricForm.value.bmi),
    waist_cm: toNumber(bodyMetricForm.value.waist_cm),
    hip_cm: toNumber(bodyMetricForm.value.hip_cm),
    note: bodyMetricForm.value.note.trim()
  }
  if (!payload.weight_kg || !payload.body_fat_percent || !payload.bmi) {
    uni.showToast({ title: '请填写体重、体脂和 BMI', icon: 'none' })
    return
  }
  isSavingBodyMetrics.value = true
  try {
    const saved = await mutateApi<any>('/api/users/me/body-metrics', 'POST', payload)
    const history = [saved, ...(bodyMetrics.value.history || []).filter((item: any) => item.id !== saved.id)].slice(0, 10)
    appData.value = {
      ...appData.value,
      user: {
        ...(appData.value?.user || user.value),
        weight_kg: saved.weight_kg,
        body_fat_percent: saved.body_fat_percent,
        bmi: saved.bmi
      },
      bodyMetrics: {
        latest: saved,
        history
      }
    }
    syncBodyMetricForm()
    showBodyMetrics.value = false
    uni.showToast({ title: '身体数据已保存', icon: 'success' })
  } catch (error) {
    uni.showToast({ title: '保存失败', icon: 'none' })
    console.warn('Save body metrics failed', error)
  } finally {
    isSavingBodyMetrics.value = false
  }
}

function goBack(fallback = '/pages/home/index') {
  const pages = getCurrentPages()
  if (pages.length > 1) {
    uni.navigateBack()
  } else {
    uni.reLaunch({ url: fallback })
  }
}
</script>

<template>
  <view class="screen-page">
    <view class="phone">
      <template v-if="screen === 'home'">
        <view class="home-top">
          <text class="brand">AI Fitness Coach</text>
          <view class="notify-button" aria-label="通知">
            <view class="bell-icon"><i></i></view>
            <em></em>
          </view>
        </view>
        <view class="home-head">
          <view class="greeting"><view class="avatar photo"></view><text>早上好，{{ user.name }}</text></view>
          <view class="goal-pill"><i></i><text>{{ user.goal }}中</text><em>›</em></view>
        </view>
        <view class="card calorie-card">
          <view class="card-title"><text>今日热量 ⓘ</text><text>详情 ›</text></view>
          <view class="calorie-grid">
            <view class="ring"><view><text>已摄入</text><text class="big">{{ nutrition.intake_calories }}</text><text class="kcal">kcal</text></view></view>
            <view class="metric-list">
              <view><i class="dot green"></i><text>剩余热量</text><strong>{{ nutrition.remaining_calories }}</strong><small>kcal</small></view>
              <view><i class="dot orange"></i><text>已消耗</text><strong>{{ nutrition.burned_calories }}</strong><small>kcal</small></view>
            </view>
            <view class="chart-wrap">
              <view class="y-axis"><text>1500</text><text>1000</text><text>500</text><text>0</text></view>
              <view class="mini-chart">
                <text v-for="h in [20,42,58,86,38,22,64,108,80,122,54]" :key="h" :style="{ height: `${h}rpx` }"></text>
              </view>
              <view class="x-axis"><text>0</text><text>6</text><text>12</text><text>18</text><text>24</text></view>
            </view>
          </view>
        </view>
        <view class="card protein-row"><text>⌘ 蛋白质</text><view class="bar"><i :style="{ width: proteinPercent }"></i></view><text>{{ nutrition.protein_g }}/{{ nutrition.protein_target_g }}g ›</text></view>
        <view class="card quick-actions">
          <view v-for="action in quickActions" :key="action.key" class="quick-action" @click="openQuickAction(action.url)">
            <view class="quick-icon" :class="`quick-icon-${action.icon}`">
              <i></i>
            </view>
            <text>{{ action.label }}</text>
          </view>
        </view>
        <view class="section-title"><text>今日计划</text><text>查看全部 ›</text></view>
        <view class="card plan-list">
          <view v-for="item in homePlan" :key="item.title" :class="{ 'water-plan': item.icon_key === 'water' }">
            <i :class="{ amber: item.status === 'pending', blue: item.icon_key === 'water' }">{{ item.icon_key === 'workout' ? '▥' : item.icon_key === 'water' ? '♢' : '☘' }}</i>
            <text><b>{{ item.title }}</b><small>{{ item.subtitle }}</small></text>
            <em :class="{ warn: item.status === 'pending' }">{{ item.value_text || (item.status === 'done' ? '✓' : item.status === 'pending' ? '◷' : '›') }}</em>
          </view>
        </view>
        <view class="ai-card"><i>✦</i><view><b>AI 今日建议</b><text>晚餐选择高蛋白低油脂，训练前补充少量碳水。</text></view><em>›</em></view>
      </template>

      <template v-else-if="screen === 'dietCamera'">
        <view class="camera-head">
          <view class="camera-back" @click="goBack('/pages/diet/index')"></view>
          <text>拍照识别</text>
          <view class="camera-help">?</view>
        </view>
        <view class="camera-preview" @click="chooseFoodImage">
          <image v-if="recognitionPreviewImage" class="camera-upload-image" :src="recognitionPreviewImage" mode="aspectFill" />
          <view class="scan-corner lt"></view>
          <view class="scan-corner rt"></view>
          <view class="scan-corner lb"></view>
          <view class="scan-corner rb"></view>
          <view class="food-plate">
            <i class="food-chicken"></i>
            <i class="food-rice"></i>
            <i class="food-broccoli"></i>
            <i class="food-egg"></i>
          </view>
          <view class="scan-status"><i></i><text>{{ isRecognizing ? 'AI 正在识别' : '点击拍照识别' }}</text></view>
        </view>
        <view class="recognition-sheet">
          <view class="sheet-grip"></view>
          <view class="recognition-head">
            <b>识别结果</b>
            <text>置信度 {{ recognitionConfidencePercent }}</text>
            <em>＋ 添加食物</em>
          </view>
          <view class="recognition-list">
            <view v-for="item in cameraFoods" :key="item.name">
              <i class="thumb" :class="item.thumb_key"></i><b>{{ item.name }}</b><input :value="item.amount" disabled /><text>{{ item.unit }}</text><em>{{ item.calories }} kcal</em><small></small>
            </view>
          </view>
          <view class="camera-total"><i></i><view><text>预计总热量</text><b>{{ recognizedTotalCalories }} <small>kcal</small></b></view></view>
          <view class="camera-actions">
            <button @click="goDietRecord"><i class="action-check"></i><text>确认记录</text></button>
            <button><i class="action-edit"></i><text>手动修改</text></button>
          </view>
          <view class="camera-minor">
            <button @click="chooseFoodImage"><i class="action-camera"></i><text>重拍</text></button>
            <button><i class="action-add"></i><text>添加食物</text></button>
          </view>
        </view>
      </template>

      <template v-else-if="screen === 'dietCameraLegacy'">
        <view class="top-title">拍照识别</view>
        <view class="food-preview">
          <view class="scan-corners"></view>
          <text>AI 正在识别</text>
          <view class="plate"><i></i><i></i><i></i><i></i></view>
        </view>
        <view class="sheet">
          <view class="sheet-head"><text>识别结果</text><text>置信度 86%</text></view>
          <view v-for="item in mealItems" :key="item[0]" class="food-row"><text>{{ item[0] }}</text><small>{{ item[1] }}</small><b>{{ item[2] }}</b><em>编辑</em></view>
          <view class="total-box"><text>预计总热量</text><b>491 kcal</b></view>
          <view class="dual-buttons"><button>确认记录</button><button>手动修改</button></view>
          <view class="minor-actions"><text>重拍</text><text>添加食物</text></view>
        </view>
      </template>

      <template v-else-if="screen === 'diet'">
        <view class="diet-head">
          <text>饮食</text>
          <view class="diet-ai" @click="goDietAdvice"><i></i><text>AI 营养师</text></view>
        </view>
        <view class="date-switch">
          <view class="date-arrow">‹</view>
          <view class="date-pill"><i></i><text>今天 5月16日</text><em></em></view>
          <view class="date-arrow">›</view>
        </view>
        <view class="card diet-summary">
          <view class="calorie-main">
            <view><b>{{ nutrition.intake_calories }}</b><text>/ {{ nutrition.target_calories }} kcal</text></view>
            <view class="summary-bar"><i :style="{ width: caloriePercent }"></i></view>
            <p>还可以吃 <strong>{{ nutrition.remaining_calories }}</strong> kcal</p>
          </view>
          <view class="macro-donut"><view></view></view>
          <view class="macro-legend">
            <p><i></i><b>26%</b><text>蛋白质</text></p>
            <p><i></i><b>44%</b><text>碳水</text></p>
            <p><i></i><b>30%</b><text>脂肪</text></p>
          </view>
          <view class="macro-stats">
            <view><b>蛋白质 {{ nutrition.protein_g }}g</b><i><em :style="{ width: proteinPercent }"></em></i><text>目标 {{ nutrition.protein_target_g }}g</text></view>
            <view><b>碳水 {{ nutrition.carbs_g }}g</b><i><em style="width:69%"></em></i><text>目标 {{ nutrition.carbs_target_g }}g</text></view>
            <view><b>脂肪 {{ nutrition.fat_g }}g</b><i><em style="width:70%"></em></i><text>目标 {{ nutrition.fat_target_g }}g</text></view>
          </view>
          <view class="protein-warning" @click="goDietAdvice"><i></i><text>蛋白质还差 {{ nutrition.protein_gap_g }}g</text></view>
        </view>
        <template v-for="meal in meals" :key="meal.meal_type">
          <view v-if="meal.meal_type !== 'dinner' && meal.meal_type !== 'snack'" class="meal-card">
            <view class="meal-card-head"><view><b>{{ meal.title }}</b><text>{{ meal.suggested_range }}</text></view><em>{{ meal.calories }} <small>kcal</small></em><i>›</i></view>
            <view class="meal-food"><view class="food-thumb" :class="meal.image_key"></view><view><b>{{ meal.subtitle }}</b><text>1份 <small v-if="meal.protein_g >= 40">高蛋白</small></text></view></view>
          </view>
        </template>
        <view class="meal-card dinner-empty">
          <view class="meal-card-head"><view><b>{{ meals[2]?.title || '晚餐' }}</b><text>{{ meals[2]?.suggested_range || '建议 450-550 kcal' }}</text></view><em>— <small>kcal</small></em></view>
          <view class="empty-dinner">
            <view class="dish-icon"><i></i></view>
            <view><b>还没有记录晚餐</b><text>拍照记录晚餐，AI 帮你分析营养</text><button @click="goDietCamera">拍照记录晚餐</button></view>
          </view>
        </view>
        <view class="meal-card snack-card">
          <view class="meal-card-head"><view><b>{{ meals[3]?.title || '加餐' }}</b><text>{{ meals[3]?.suggested_range || '建议 150-250 kcal' }}</text></view><em>{{ meals[3]?.calories || 0 }} <small>kcal</small></em><i>›</i></view>
          <view class="snack-row"><view class="snack-icon"></view><view><b>记录加餐</b><text>如水果、坚果、酸奶等</text></view><view class="add-record" @click="goDietCamera">＋ 记录</view></view>
        </view>
        <view class="float-camera"><i></i></view>
      </template>

      <template v-else-if="screen === 'dietLegacy'">
        <view class="title-row"><text>饮食</text><small>今天 5月16日</small></view>
        <view class="card nutrition-card">
          <view><text>今日摄入</text><b>1260 / 1800</b><small>kcal</small></view>
          <view class="donut">68%</view>
          <view class="macro-lines"><p><text>蛋白质 82g</text><i><em style="width:68%"></em></i></p><p><text>碳水 138g</text><i><em style="width:62%"></em></i></p><p><text>脂肪 42g</text><i><em style="width:52%"></em></i></p></view>
          <view class="warning">蛋白质还差 38g</view>
        </view>
        <view class="meal-section"><b>早餐</b><view class="meal-line"><text>燕麦牛奶</text><em>320 kcal</em></view></view>
        <view class="meal-section"><b>午餐</b><view class="meal-line"><text>鸡胸肉饭</text><em>491 kcal</em></view></view>
        <view class="meal-section empty"><b>晚餐</b><view class="meal-line"><text>拍照记录晚餐</text><em>＋</em></view></view>
        <view class="meal-section"><b>加餐</b><view class="meal-line"><text>无</text><em>可添加</em></view></view>
        <button class="float-camera">▢</button>
      </template>

      <template v-else-if="screen === 'dietAdvice'">
        <view class="advice-head">
          <view class="advice-back" @click="goBack('/pages/diet/index')"><uni-icons type="left" size="34" color="#11151b" /></view>
          <text>AI 饮食建议</text>
          <view class="advice-chat"><uni-icons type="chat" size="30" color="#0b9f50" /></view>
        </view>
        <view class="advice-summary">
          <view><i class="iconfont-circle"><uni-icons type="fire-filled" size="34" color="#fff" /></i><text>今日摄入</text><b>{{ nutrition.intake_calories }} <small>kcal</small></b></view>
          <view><i class="iconfont-circle"><uni-icons type="tune-filled" size="34" color="#fff" /></i><text>剩余</text><b>{{ nutrition.remaining_calories }} <small>kcal</small></b></view>
          <view><i class="iconfont-circle"><uni-icons type="hand-up-filled" size="34" color="#fff" /></i><text>蛋白质差</text><b>{{ nutrition.protein_gap_g }} <small>g</small></b></view>
        </view>
        <view class="advice-card">
          <view class="advice-title"><uni-icons type="star-filled" size="34" color="#0b9f50" /><b>晚餐建议</b></view>
          <view v-for="(option, index) in dinnerOptions" :key="option[0]" class="dinner-option">
            <view class="dinner-img" :class="index === 0 ? 'salad' : index === 1 ? 'shrimp' : 'beef'"></view>
            <view class="dinner-info"><text>{{ option[0] }}</text><b>{{ option[1] }}</b><p><small>{{ option[3] }}</small><small>{{ option[4] }}</small><small>{{ option[5] }}</small></p></view>
            <em>{{ option[2].replace(' kcal', '') }} <small>kcal</small></em><uni-icons type="right" size="28" color="#7d858e" />
          </view>
          <view class="recommend-reason">
            <i class="iconfont-circle"><uni-icons type="info-filled" size="32" color="#fff" /></i>
            <view><b>为什么这样推荐</b><text>根据你的今日摄入和营养目标，推荐高蛋白、适量碳水、低脂肪的晚餐，有助于补充蛋白质，控制总热量，促进肌肉恢复与体脂管理。</text></view>
          </view>
          <view class="ask-title">你可能想问</view>
          <view class="advice-questions">
            <view><uni-icons type="wallet-filled" size="28" color="#0b9f50" /><text>今天吃超了怎么办</text></view>
            <view><uni-icons type="shop-filled" size="28" color="#0b9f50" /><text>还可以吃什么</text></view>
            <view><uni-icons type="hand-up-filled" size="28" color="#0b9f50" /><text>提高蛋白质</text></view>
          </view>
          <button class="meal-plan-button">✦ 生成一日食谱</button>
        </view>
      </template>

      <template v-else-if="screen === 'training'">
        <view class="training-head">
          <text>AI 健身计划</text>
          <view class="history-link" @click="togglePlanHistory"><i></i><text>{{ showPlanHistory ? '收起历史' : '计划历史' }}</text></view>
        </view>
        <view v-if="showPlanHistory" class="training-card plan-history-card">
          <view v-if="!planHistory.length" class="plan-history-empty">暂无历史计划</view>
          <view v-for="plan in planHistory" :key="plan.id" class="plan-history-row" :class="{ active: selectedHistoryPlanId === plan.id }" @click="openHistoryPlan(plan.id)">
            <view>
              <b>{{ plan.goal }} · {{ plan.weekly_frequency }}练</b>
              <text>{{ plan.location }} · {{ plan.duration_minutes }}分钟</text>
            </view>
            <small>{{ (plan.preferred_exercises || []).map((item: any) => item.name).join('、') || '未选动作' }}</small>
            <em>›</em>
          </view>
        </view>
        <view class="training-card training-config">
          <view class="config-row goal-row">
            <b>我的目标</b>
            <view class="goal-options">
              <view v-for="option in goalOptions" :key="option.label" :class="{ active: selectedGoal === option.label }" @click="selectedGoal = option.label"><i :class="option.icon"></i><text>{{ option.label }}</text></view>
            </view>
          </view>
          <view class="config-row number-row">
            <b>每周训练频率</b>
            <view class="stepper"><button @click="changeFrequency(-1)">−</button><strong>{{ selectedFrequency }}</strong><text>练</text><button @click="changeFrequency(1)">＋</button></view>
            <small>推荐 3-6 练</small>
          </view>
          <view class="config-row place-row">
            <b>训练地点</b>
            <view class="place-options">
              <view v-for="option in locationOptions" :key="option.label" :class="{ active: selectedLocation === option.label }" @click="selectedLocation = option.label"><i :class="option.icon"></i><text>{{ option.label }}</text></view>
            </view>
          </view>
          <view class="config-row number-row">
            <b>每次训练时长</b>
            <view class="stepper"><button @click="changeDuration(-5)">−</button><strong>{{ selectedDuration }}</strong><text>分钟</text><button @click="changeDuration(5)">＋</button></view>
            <small>推荐 30-60 分钟</small>
          </view>
        </view>
        <view class="training-card chip-section">
          <b>可用器械 <small>（可多选）</small></b>
          <view class="training-chips">
            <view v-for="item in equipmentOptions" :key="item.label" :class="{ selected: selectedEquipment.includes(item.label) }" @click="toggleEquipment(item.label)"><i :class="item.icon"></i><text>{{ item.label }}</text></view>
          </view>
        </view>
        <view class="training-card library-link" @click="goExerciseLibrary('', 'training')">
          <view><uni-icons type="list" size="30" color="#0da052" /><text>动作库</text></view>
          <uni-icons type="right" size="26" color="#7a828b" />
        </view>
        <view v-if="selectedPlanExercises.length" class="training-card selected-exercise-card">
          <b>已选动作</b>
          <view class="selected-exercise-list">
            <view v-for="item in selectedPlanExercises" :key="item.name">
              <text>{{ item.name }}</text>
              <small>{{ item.body_part }} · {{ item.level }}</small>
              <em @click="removePlanExercise(item.name)">×</em>
            </view>
          </view>
        </view>
        <view class="training-card library-link" @click="goActivity">
          <view><uni-icons type="bars" size="30" color="#0da052" /><text>运动数据</text></view>
          <uni-icons type="right" size="26" color="#7a828b" />
        </view>
        <view class="training-card chip-section limits">
          <b>身体限制 <small>（可多选）</small></b>
          <view class="limit-chips">
            <view v-for="item in limitationOptions" :key="item" :class="{ selected: selectedLimitations.includes(item) }" @click="toggleLimitation(item)"><i></i><text>{{ item }}</text></view>
          </view>
          <text class="limit-help">如有其他问题可咨询 AI 私教 ›</text>
        </view>
        <view class="training-card plan-preview">
          <view class="preview-head"><b>{{ historyPlanTitle }}</b><text>根据你的目标和设置生成</text></view>
          <view class="preview-list">
            <view v-for="day in weekPlan" :key="day[0]" @click="goTodayWorkout"><i :class="`plan-${day[3] || 'muscle'}`"></i><b>{{ day[0] }}</b><strong>{{ day[1] }}</strong><text>{{ day[2] }}</text><em>›</em></view>
          </view>
          <p><i></i><text>周三、周五、周日为休息或拉伸活动日，可根据恢复状态调整</text></p>
        </view>
        <button class="generate-plan" @click="generatePlan">✦ {{ isGeneratingPlan ? '生成中' : '生成计划' }}</button>
      </template>

      <template v-else-if="screen === 'todayWorkout'">
        <view class="today-head">
          <view class="today-back" @click="goBack('/pages/training/index')"></view>
          <view><b>今日训练</b><text>{{ appData?.todayWorkout?.title || '上肢力量' }} · {{ appData?.todayWorkout?.duration_minutes || 45 }}分钟</text></view>
          <view class="training-helper"><i></i><text>训练助手</text></view>
        </view>
        <view class="today-progress-card">
          <view class="complete-ring"><view><p><b>{{ appData?.todayWorkout?.completed_exercises || 3 }}</b><em>/{{ appData?.todayWorkout?.total_exercises || 7 }}</em></p><text>动作完成</text></view></view>
          <view class="progress-divider"></view>
          <view class="timer-box"><i></i><b>{{ appData?.todayWorkout?.timer || '18:24' }}</b><text>训练时长</text></view>
        </view>
        <view class="exercise-list">
          <template v-for="(item, index) in workouts" :key="item[0]">
          <view v-if="item[3] === 'active'" class="exercise-row active">
            <view class="exercise-top">
              <view class="exercise-index">{{ index + 1 }}</view>
              <view class="exercise-thumb" :class="item[4]"></view>
              <view><b>{{ item[0] }}</b><text>{{ item[1] }}　{{ item[2] }}</text></view>
              <small>进行中</small>
              <em>⌃</em>
            </view>
            <view class="rest-card"><i></i><text>休息</text><b>00:45</b><button>跳过休息</button></view>
            <view class="workout-actions"><button>✓ 完成一组</button><button @click="goExerciseLibrary(item[5], 'todayWorkout')">↔ 替换动作</button></view>
          </view>
          <view v-else class="exercise-row" :class="{ done: item[3] === 'done' }">
            <view class="exercise-index" :class="{ muted: item[3] !== 'done' }">{{ item[3] === 'done' ? '✓' : index + 1 }}</view>
            <view class="exercise-thumb" :class="item[4]"></view>
            <view><b>{{ item[0] }}</b><text>{{ item[1] }}　{{ item[2] }}</text></view>
            <em>›</em>
          </view>
          </template>
        </view>
        <button class="end-workout" @click="goActivity">结束训练</button>
      </template>

      <template v-else-if="screen === 'exerciseLibrary'">
        <view class="library-head">
          <view class="library-back" @click="leaveExerciseLibrary"></view>
          <text>动作库</text>
          <view class="filter-icon"></view>
        </view>
        <view class="library-search"><uni-icons type="search" size="30" color="#5f6872" /><text>搜索动作</text></view>
        <scroll-view class="library-cats" scroll-x="true" show-scrollbar="false">
          <view class="cat-track"><text class="active">胸</text><text>背</text><text>腿</text><text>肩</text><text>手臂</text><text>核心</text><text>有氧</text></view>
        </scroll-view>
        <view class="library-feature" @click="selectLibraryExercise(library[0])">
          <image class="library-img squat" src="/static/exercises/squat.png" mode="aspectFill" />
          <view class="feature-main">
            <view class="feature-title"><view><b>{{ library[0]?.name || '深蹲' }}</b><text>{{ library[0]?.body_part || '腿部' }} · {{ library[0]?.level || '中级' }}</text><em>常用</em></view><uni-icons type="up" size="28" color="#1b222a" /></view>
            <view class="feature-info">
              <p><i class="lib-bone"></i><b>目标肌群</b><text>{{ library[0]?.target_muscle || '股四头肌' }}</text></p>
              <p><i class="lib-warn"></i><b>常见错误</b><text>{{ library[0]?.common_mistake || '膝盖内扣' }}</text></p>
              <p><i class="lib-switch"></i><b>替代动作</b><text>{{ library[0]?.alternative || '箱式深蹲' }}</text></p>
            </view>
          </view>
        </view>
        <view v-for="item in library.slice(1)" :key="item.name" class="library-row" @click="selectLibraryExercise(item)">
          <image class="library-img" :class="item.image_key" :src="`/static/exercises/${item.image_key === 'bench' ? 'bench-press' : item.image_key}.png`" mode="aspectFill" />
          <view><b>{{ item.name }}</b><text>{{ item.body_part }} · {{ item.level }}</text></view>
          <uni-icons type="flag" size="30" color="#252b32" />
          <uni-icons type="right" size="30" color="#252b32" />
        </view>
      </template>

      <template v-else-if="screen === 'activity'">
        <view class="activity-head">
          <text>运动数据</text>
          <view class="activity-calendar"><uni-icons type="calendar" size="34" color="#11151b" /></view>
        </view>
        <view class="activity-week">
          <view v-for="item in activity.week || []" :key="item.day_label" :class="{ active: item.active }"><text>{{ item.weekday_label }}</text><b>{{ item.day_label }}</b><p><i :class="{ done: item.done }">{{ item.done ? '✓' : '' }}</i></p></view>
        </view>
        <view class="activity-stats">
          <view><i class="stat-train"><uni-icons type="tune-filled" size="32" color="#22b14c" /></i><text>本周训练</text><b><em>{{ activity.weekly_workouts_done || 3 }}</em> / {{ activity.weekly_workouts_target || 4 }}次</b></view>
          <view><i class="stat-time"><uni-icons type="spinner-cycle" size="32" color="#2f8bf2" /></i><text>运动时长</text><b>{{ activity.workout_minutes || 156 }} <small>分钟</small></b></view>
          <view><i class="stat-fire"><uni-icons type="fire-filled" size="32" color="#ff8a22" /></i><text>消耗</text><b>{{ activity.calories_burned || 1280 }} <small>kcal</small></b></view>
          <view><i class="stat-step"><uni-icons type="navigate-filled" size="32" color="#37a852" /></i><text>步数</text><b>{{ activity.steps || 7420 }} <small>步</small></b></view>
        </view>
        <view class="activity-card heart-card">
          <view class="activity-card-head"><b><i></i>心率 <small>(bpm)</small></b><text>平均 <em>{{ activity.avg_heart_rate || 128 }}</em>　最大 <em>{{ activity.max_heart_rate || 168 }}</em></text></view>
          <view ref="heartChartRef" class="heart-chart echarts-chart"></view>
        </view>
        <view class="activity-card load-card">
          <view class="activity-card-head"><b><i></i>训练负荷 <small>(训练量)</small></b><text>本周总负荷 <em>{{ activity.training_load_total || 2560 }}</em></text></view>
          <view ref="loadChartRef" class="load-chart echarts-chart"></view>
        </view>
        <view class="activity-bottom-grid">
          <view class="strength-card">
            <view class="activity-card-head"><b><i></i>力量进展</b><uni-icons type="right" size="28" color="#7d858e" /></view>
            <p v-for="item in activity.strength || []" :key="item.name"><image :src="`/static/exercises/${item.image_key === 'bench' ? 'bench-press' : item.image_key}.png`" mode="aspectFill" /><view><b>{{ item.value_text }}</b><text>{{ item.name }}</text></view><em>{{ item.delta_text }} ↗</em></p>
          </view>
          <view class="device-card">
            <view class="device-head">
              <view class="health-icon"><uni-icons type="heart-filled" size="38" color="#f2414b" /></view>
              <b>设备同步</b>
            </view>
            <view class="device-body">
              <text>{{ activity.synced_device || 'Apple Health' }}</text>
              <p><i>✓</i> {{ activity.synced_status || '已同步' }}</p>
              <small>{{ activity.synced_ago || '5分钟前' }}</small>
            </view>
            <uni-icons class="device-arrow" type="right" size="28" color="#7d858e" />
          </view>
        </view>
      </template>

      <template v-else-if="screen === 'aiChat'">
        <view class="coach-head">
          <view class="coach-back" @click="goBack('/pages/home/index')"></view>
          <text>AI 私教</text>
          <view class="coach-more"><i></i></view>
        </view>
        <view class="coach-context">
          <view><i class="coach-target"></i><text>{{ aiChat.context?.goal_label || '减脂目标' }}</text></view>
          <view><i class="coach-fire"></i><text>{{ aiChat.context?.calories_label || '今日 1260kcal' }}</text></view>
          <view><i class="coach-dumbbell"></i><text>{{ aiChat.context?.workouts_label || '本周 3 练' }}</text></view>
        </view>
        <view class="coach-chat">
          <view class="coach-user-row">
            <view class="coach-user-bubble">
              <b>{{ aiChat.messages?.[0]?.content || '今天午餐吃多了，晚餐怎么补救？' }}</b>
              <text>{{ aiChat.messages?.[0]?.created_time || '15:30' }} <i></i></text>
            </view>
            <view class="coach-user-avatar"></view>
          </view>
          <view class="coach-ai-row">
            <view class="coach-bot-avatar"><i></i></view>
            <view>
              <view class="coach-ai-bubble">
                <text>{{ aiChat.messages?.[1]?.content || '别担心，晚餐可以这样调整来帮助你控制热量，稳住目标：' }}</text>
                <p v-for="item in aiChat.messages?.[1]?.bullets || []" :key="item"><i></i><text>{{ item }}</text></p>
              </view>
              <view class="coach-ai-time">{{ aiChat.messages?.[1]?.created_time || '15:30' }}</view>
            </view>
          </view>
        </view>
        <view class="coach-suggestions">
          <view v-for="item in aiChat.suggestions || []" :key="item.text"><i :class="`coach-${item.icon_key}`"></i><text>{{ item.text }}</text></view>
        </view>
        <view class="coach-review-entry" @click="goAiReview">
          <view><i></i><text>AI 复盘</text></view>
          <b>查看今日饮食、训练和饮水报告</b>
          <uni-icons type="right" size="28" color="#0c9f50" />
        </view>
        <view class="coach-input">
          <view class="voice-icon"><i></i></view>
          <text>问问你的 AI 私教</text>
          <view class="send-icon"></view>
        </view>
      </template>

      <template v-else-if="screen === 'aiReview'">
        <view class="review-page-head">
          <view class="review-back" @click="goBack('/pages/ai-chat/index')"></view>
          <text>AI 复盘</text>
          <view class="review-calendar"><uni-icons type="calendar" size="36" color="#11151b" /></view>
        </view>
        <view class="review-tabs">
          <view class="active">今日复盘</view>
          <view>周度复盘</view>
        </view>
        <view class="review-date-row">
          <view><uni-icons type="calendar" size="28" color="#6b7280" /><text>5月16日</text><b>星期五</b><uni-icons type="down" size="22" color="#6b7280" /></view>
          <button><uni-icons type="redo" size="26" color="#0c9f50" />分享报告</button>
        </view>
        <view class="review-summary-card">
          <view class="review-score-wrap">
            <view ref="reviewScoreRef" class="review-score-chart"></view>
            <view class="review-score-text"><text>今日表现</text><b>{{ aiReview.score || 82 }}</b><em>分</em><small>{{ aiReview.score_label || '良好' }}</small></view>
          </view>
          <view class="review-goals">
            <view class="review-goal-row">
              <i class="review-icon diet"><text class="iconfont review-iconfont review-icon-diet"></text></i>
              <view><b>饮食达标</b><p><em style="width:78%"></em></p></view>
              <strong>{{ aiReview.diet_percent || 78 }}%</strong><uni-icons type="right" size="30" color="#6b7280" />
            </view>
            <view class="review-goal-row">
              <i class="review-icon train"><text class="iconfont review-iconfont review-icon-train"></text></i>
              <view><b>训练完成</b><p><em style="width:100%"></em></p></view>
              <strong>{{ aiReview.training_label || '已完成' }}</strong><uni-icons type="right" size="30" color="#6b7280" />
            </view>
            <view class="review-goal-row">
              <i class="review-icon water"><text class="iconfont review-iconfont review-icon-water"></text></i>
              <view><b>饮水</b><p class="blue"><em style="width:86%"></em></p></view>
              <strong><span>{{ aiReview.water_current_ml || 1900 }}</span>/{{ aiReview.water_target_ml || 2200 }}ml</strong><uni-icons type="right" size="30" color="#6b7280" />
            </view>
          </view>
        </view>
        <view class="review-tip-card good">
          <i><text class="iconfont review-tip-icon review-tip-good"></text></i>
          <view><b>今天做得好的地方</b><text>{{ aiReview.good_tip || '蛋白质摄入接近目标，力量训练按计划完成。' }}</text></view>
          <uni-icons type="right" size="32" color="#1f2933" />
        </view>
        <view class="review-tip-card adjust">
          <i><text class="iconfont review-tip-icon review-tip-adjust"></text></i>
          <view><b>明天调整</b><text>{{ aiReview.adjust_tip || '午餐油脂偏高，晚餐保持清淡并补足蔬菜。' }}</text></view>
          <uni-icons type="right" size="32" color="#1f2933" />
        </view>
        <view class="review-trend-head"><b>本周趋势</b><text>5月10日 - 5月16日</text></view>
        <view class="review-trend-grid">
          <view class="review-trend-card weight">
            <view class="trend-title"><i><text class="iconfont trend-icon trend-icon-weight"></text></i><text>体重</text></view>
            <b>{{ aiReview.weight_delta_kg || -0.4 }} <small>kg</small></b>
            <p>较上周 <em>↓</em></p>
            <view ref="reviewWeightRef" class="review-mini-chart review-weight-chart"></view>
          </view>
          <view class="review-trend-card train">
            <view class="trend-title"><i><text class="iconfont trend-icon trend-icon-train"></text></i><text>训练完成率</text></view>
            <b>{{ aiReview.training_completion_percent || 75 }}%</b>
            <p>较上周 <em>↑ 10%</em></p>
            <view ref="reviewTrainRef" class="review-mini-chart review-train-chart"></view>
          </view>
          <view class="review-trend-card diet">
            <view class="trend-title"><i><text class="iconfont trend-icon trend-icon-diet"></text></i><text>饮食达标率</text></view>
            <b>{{ aiReview.diet_completion_percent || 68 }}%</b>
            <p>较上周 <em>↑ 6%</em></p>
            <view ref="reviewDietRef" class="review-mini-chart review-diet-chart"></view>
          </view>
        </view>
        <button class="review-plan-button"><uni-icons type="calendar" size="36" color="#fff" />调整下周计划</button>
        <view class="review-foot-note"><uni-icons type="download" size="24" color="#9aa1aa" /><text>AI 基于你的数据生成，持续记录让建议更准确</text></view>
      </template>
      <template v-else-if="screen === 'profile'">
        <view class="profile-top">
          <text>我的</text>
          <view class="profile-bell"><i></i></view>
        </view>
        <view class="profile-user">
          <view class="profile-avatar"></view>
          <view class="profile-info">
            <view><b>{{ user.name }}</b><em><i></i>{{ user.membership_status }}</em></view>
            <text>AI 会根据你的数据提供个性化建议</text>
          </view>
          <view class="profile-arrow">›</view>
        </view>
        <view class="profile-card body-overview">
          <view class="profile-card-head"><b>身体概览</b><text>更新于 今天 08:30 ›</text></view>
          <view class="profile-metrics">
            <view><i class="profile-icon weight"></i><text>体重</text><b>{{ user.weight_kg }}<small>kg</small></b></view>
            <view><i class="profile-icon fat"></i><text>体脂</text><b>{{ user.body_fat_percent }}<small>%</small></b></view>
            <view><i class="profile-icon bmi"></i><text>BMI</text><b>{{ user.bmi }}</b></view>
          </view>
        </view>
        <view v-if="showBodyMetrics" class="profile-card body-metrics-panel">
          <view class="profile-card-head"><b>身体数据</b><text>记录会保存到数据库</text></view>
          <view class="body-form-grid">
            <view>
              <text>体重 kg</text>
              <input v-model="bodyMetricForm.weight_kg" type="digit" placeholder="72.4" />
            </view>
            <view>
              <text>体脂 %</text>
              <input v-model="bodyMetricForm.body_fat_percent" type="digit" placeholder="21.8" />
            </view>
            <view>
              <text>BMI</text>
              <input v-model="bodyMetricForm.bmi" type="digit" placeholder="23.1" />
            </view>
            <view>
              <text>腰围 cm</text>
              <input v-model="bodyMetricForm.waist_cm" type="digit" placeholder="82" />
            </view>
            <view>
              <text>臀围 cm</text>
              <input v-model="bodyMetricForm.hip_cm" type="digit" placeholder="96" />
            </view>
          </view>
          <textarea v-model="bodyMetricForm.note" class="body-note" placeholder="备注，比如早晨空腹测量" maxlength="80"></textarea>
          <button class="body-save-button" :disabled="isSavingBodyMetrics" @click="saveBodyMetrics">
            {{ isSavingBodyMetrics ? '保存中...' : '保存身体数据' }}
          </button>
          <view v-if="bodyMetrics.history?.length" class="body-history">
            <view class="body-history-title">最近记录</view>
            <view v-for="item in bodyMetrics.history" :key="item.id" class="body-history-row">
              <text>{{ formatMetricDate(item.measured_at) }}</text>
              <b>{{ item.weight_kg }}kg</b>
              <b>{{ item.body_fat_percent }}%</b>
              <b>BMI {{ item.bmi }}</b>
            </view>
          </view>
        </view>
        <view class="profile-card goal-progress" @click="goOnboarding">
          <view class="profile-card-head"><b><i class="goal-mark"></i>目标进度</b><text>查看详情 ›</text></view>
          <view class="goal-metrics">
            <view>
              <i class="profile-icon target-weight"></i>
              <text>目标体重</text>
              <b>{{ user.target_weight_kg }}<small>kg</small></b>
              <p><em style="width:72%"></em></p>
              <small>已减 {{ targetLoss }} kg</small>
            </view>
            <view>
              <i class="profile-icon calendar"></i>
              <text>目标日期</text>
              <b>{{ user.target_date_label }}</b>
              <small>还有 106 天</small>
            </view>
            <view>
              <i class="profile-icon train"></i>
              <text>每周训练</text>
              <b>{{ user.weekly_training_days }}<small>次</small></b>
              <small>本周已完成 {{ activity.weekly_workouts_done || 3 }} 次</small>
            </view>
          </view>
        </view>
        <view class="profile-menu">
          <view v-for="item in profileMenus" :key="item.title" @click="handleProfileMenu(item)"><i :class="`menu-${item.icon_key}`"></i><text>{{ item.title }}</text><small v-if="item.note">{{ item.note }}</small><em>›</em></view>
        </view>
      </template>

      <template v-else-if="screen === 'onboarding'">
        <view class="onboard-page-head">
          <view class="onboard-back" @click="goBack('/pages/profile/index')"></view>
          <text>设置你的目标</text>
          <b><em>2</em>/4</b>
        </view>
        <view class="onboard-steps">
          <view class="done">✓</view><i class="done"></i>
          <view class="active">2</view><i></i>
          <view>3</view><i></i>
          <view>4</view>
        </view>

        <view class="onboard-section-title">基础信息</view>
        <view class="onboard-info-card">
          <view class="gender-row">
            <text>性别</text>
            <view class="gender-actions">
              <button :class="{ active: goalProfileForm.gender === 'male' }" @click="goalProfileForm.gender = 'male'"><i class="on-icon on-male"></i>男</button>
              <button :class="{ active: goalProfileForm.gender === 'female' }" @click="goalProfileForm.gender = 'female'"><i class="on-icon on-female"></i>女</button>
            </view>
          </view>
          <view><text>年龄</text><input v-model="goalProfileForm.age" type="number" /><small>岁</small></view>
          <view><text>身高</text><input v-model="goalProfileForm.height_cm" type="number" /><small>cm</small></view>
          <view><text>当前体重</text><input v-model="goalProfileForm.weight_kg" type="digit" /><small>kg</small></view>
          <view><text>目标体重</text><input v-model="goalProfileForm.target_weight_kg" type="digit" /><small>kg</small></view>
          <view><text>目标日期</text><input v-model="goalProfileForm.target_date" type="text" placeholder="2026-08-30" /><small></small></view>
        </view>

        <view class="onboard-section-title">你的目标</view>
        <view class="onboard-goal-grid">
          <button v-for="option in onboardingGoalOptions" :key="option.label" :class="{ active: goalProfileForm.goal === option.label }" @click="goalProfileForm.goal = option.label"><i class="on-icon" :class="option.icon"></i>{{ option.label }}</button>
        </view>

        <view class="onboard-section-title">训练经验</view>
        <view class="onboard-level-grid">
          <button v-for="option in trainingExperienceOptions" :key="option.label" :class="{ active: goalProfileForm.training_experience === option.label }" @click="goalProfileForm.training_experience = option.label"><i class="on-icon" :class="option.icon"></i>{{ option.label }}</button>
        </view>

        <view class="onboard-section-title">每周训练</view>
        <view class="onboard-info-card compact">
          <view><text>训练频率</text><input v-model="goalProfileForm.weekly_training_days" type="number" /><small>次/周</small></view>
        </view>

        <view class="onboard-section-title">饮食偏好 <small>(可多选)</small></view>
        <view class="onboard-preferences">
          <button v-for="item in dietPreferenceOptions" :key="item" :class="{ active: goalProfileForm.diet_preferences.includes(item) }" @click="toggleDietPreference(item)"><i>✓</i>{{ item }}</button>
        </view>

        <view class="onboard-section-title">伤病或限制 <small>(选填)</small></view>
        <textarea v-model="goalProfileForm.health_limitations_text" class="onboard-textarea-input" placeholder="如：膝盖不适、腰椎间盘突出等" maxlength="100"></textarea>

        <button class="onboard-next" :disabled="isSavingGoalProfile" @click="saveGoalProfile">{{ isSavingGoalProfile ? '生成中...' : '下一步：生成计划' }}</button>
      </template>

      <template v-else>
        <view class="onboarding-head"><text>2/4</text><b>设置你的目标</b></view>
        <view class="card form-card">
          <view class="field"><text>性别</text><b>男</b></view>
          <view class="field"><text>年龄</text><b>28</b></view>
          <view class="field"><text>身高</text><b>175cm</b></view>
          <view class="field"><text>当前体重</text><b>72.4kg</b></view>
          <view class="field"><text>目标体重</text><b>68kg</b></view>
        </view>
        <view class="form-row block"><b>目标</b><p><text class="selected">减脂</text><text>增肌</text><text>塑形</text><text>健康维持</text></p></view>
        <view class="form-row block"><b>训练经验</b><p><text>新手</text><text class="selected">有基础</text><text>进阶</text></p></view>
        <view class="form-row block"><b>饮食偏好</b><p><text>高蛋白</text><text>少油</text><text>不吃辣</text></p></view>
        <view class="limit-box">伤病或限制</view>
        <button class="sticky-primary">下一步：生成计划</button>
      </template>

      <view v-if="screenTab[screen]" class="tabbar">
        <button v-for="tab in tabs" :key="tab.key" :class="{ active: screenTab[screen] === tab.key }" @click="go(tab.url)">
          <view class="tab-icon"><text>{{ tab.icon }}</text></view>
          <small>{{ tab.label }}</small>
        </button>
      </view>
    </view>
  </view>
</template>

<style scoped>
.screen-page { min-height: 100vh; display: flex; justify-content: center; background: #eaf0ec; }
.phone { position: relative; width: 100vw; max-width: 512px; min-height: 100vh; padding: 30rpx 34rpx 168rpx; background: #fbfcfa; overflow: hidden; color: #14171c; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif; }
.home-top { display: flex; align-items: center; justify-content: space-between; gap: 24rpx; }
.brand { display: block; flex: 1; min-width: 0; font-size: 40rpx; font-weight: 900; line-height: 1.15; }
.notify-button {
  position: relative;
  flex: 0 0 auto;
  width: 56rpx;
  height: 56rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
}
.notify-button em {
  position: absolute;
  right: 7rpx;
  top: 8rpx;
  width: 12rpx;
  height: 12rpx;
  border-radius: 50%;
  background: #f05a3d;
  border: 3rpx solid #fbfcfa;
}
.bell-icon {
  position: relative;
  width: 38rpx;
  height: 40rpx;
  color: #17191d;
}
.bell-icon::before,
.bell-icon::after,
.bell-icon i {
  content: "";
  position: absolute;
  box-sizing: border-box;
  display: block;
}
.bell-icon::before {
  left: 7rpx;
  top: 8rpx;
  width: 24rpx;
  height: 24rpx;
  border: 4rpx solid currentColor;
  border-bottom: 0;
  border-radius: 15rpx 15rpx 8rpx 8rpx;
}
.bell-icon::after {
  left: 4rpx;
  top: 29rpx;
  width: 30rpx;
  height: 4rpx;
  border-radius: 99rpx;
  background: currentColor;
}
.bell-icon i {
  left: 16rpx;
  top: 34rpx;
  width: 7rpx;
  height: 5rpx;
  border-radius: 50%;
  background: currentColor;
}
.bell-icon i::before {
  content: "";
  position: absolute;
  left: 1rpx;
  top: -31rpx;
  width: 6rpx;
  height: 6rpx;
  border-radius: 50%;
  background: currentColor;
}
.home-head { margin-top: 22rpx; display: flex; justify-content: space-between; align-items: flex-end; }
.greeting { display: flex; gap: 18rpx; align-items: center; font-size: 42rpx; font-weight: 900; }
.avatar { width: 76rpx; height: 76rpx; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: #cfdad4; }
.photo { background: radial-gradient(circle at 50% 28%, #2f3b48 0 15%, transparent 16%), linear-gradient(135deg, #d7e0da, #6e8b81); }
.goal-pill, .context-chips text, .question-chips text { border-radius: 999rpx; background: #e8f6ed; color: #13834a; font-size: 24rpx; font-weight: 800; padding: 14rpx 22rpx; }
.goal-pill { display: flex; align-items: center; gap: 8rpx; white-space: nowrap; }
.goal-pill i {
  position: relative;
  width: 22rpx;
  height: 22rpx;
  border: 3rpx solid currentColor;
  border-radius: 50%;
  box-sizing: border-box;
}
.goal-pill i::before,
.goal-pill i::after {
  content: "";
  position: absolute;
  box-sizing: border-box;
}
.goal-pill i::before {
  left: 5rpx;
  top: 5rpx;
  width: 6rpx;
  height: 6rpx;
  border-radius: 50%;
  background: currentColor;
}
.goal-pill i::after {
  right: -6rpx;
  top: -5rpx;
  width: 10rpx;
  height: 10rpx;
  border-top: 3rpx solid currentColor;
  border-right: 3rpx solid currentColor;
}
.goal-pill text { line-height: 1; }
.goal-pill em { font-style: normal; font-size: 28rpx; line-height: 1; }
.card { border-radius: 18rpx; background: #fff; border: 1rpx solid #e8ecef; box-shadow: 0 12rpx 34rpx rgba(28, 38, 48, .06); }
.calorie-card { margin-top: 24rpx; padding: 22rpx; }
.card-title, .title-row, .sheet-head, .section-title { display: flex; justify-content: space-between; align-items: center; font-weight: 900; }
.card-title text:last-child, .section-title text:last-child, .title-row small { color: #7a8089; font-size: 24rpx; font-weight: 500; }
.calorie-grid { margin-top: 18rpx; display: grid; grid-template-columns: 200rpx 136rpx 1fr; gap: 16rpx; align-items: center; }
.ring { width: 198rpx; height: 198rpx; border-radius: 50%; padding: 18rpx; background: conic-gradient(#14b860 252deg, #eef1f0 0); }
.ring view { height: 100%; border-radius: 50%; background: #fff; display: flex; flex-direction: column; align-items: center; justify-content: center; }
.ring text { font-size: 22rpx; color: #4c535c; }
.ring .big { font-size: 58rpx; color: #15181d; font-weight: 900; line-height: 1; }
.ring .kcal { margin-top: 3rpx; color: #f28a17; font-size: 22rpx; font-weight: 800; }
.metric-list { display: grid; gap: 18rpx; }
.metric-list view {
  min-height: 66rpx;
  display: grid;
  grid-template-columns: 34rpx 1fr;
  grid-template-rows: 28rpx 30rpx;
  align-items: center;
  column-gap: 8rpx;
}
.metric-list .dot { grid-row: 1 / 3; }
.metric-list text {
  display: block;
  min-width: 0;
  color: #6e7580;
  font-size: 20rpx;
  line-height: 1.1;
  white-space: nowrap;
}
.metric-list strong {
  align-self: end;
  color: #0fa857;
  font-size: 28rpx;
  line-height: 1;
}
.metric-list small {
  margin-left: 4rpx;
  color: #67707b;
  font-size: 18rpx;
  line-height: 1;
}
.dot { width: 34rpx; height: 34rpx; border-radius: 50%; display: block; background: #14b860; }
.orange, .amber { background: #f59e0b !important; }
.blue { background: #1d9bf0 !important; }
.chart-wrap {
  height: 176rpx;
  display: grid;
  grid-template-columns: 34rpx 1fr;
  grid-template-rows: 1fr 24rpx;
  column-gap: 8rpx;
  align-items: stretch;
}
.y-axis {
  height: 148rpx;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  color: #a0a6ae;
  font-size: 16rpx;
  line-height: 1;
  text-align: right;
}
.mini-chart {
  height: 148rpx;
  display: flex;
  align-items: flex-end;
  gap: 7rpx;
  border-left: 1rpx solid #edf0f2;
  border-bottom: 1rpx solid #e2e8e4;
  background:
    linear-gradient(#eef2ef 1rpx, transparent 1rpx) 0 0 / 100% 49rpx,
    #fff;
  padding: 0 0 0 8rpx;
}
.mini-chart text, .bar-chart i { width: 10rpx; border-radius: 10rpx 10rpx 0 0; background: #25be6c; }
.mini-chart text:nth-last-child(2), .bar-chart i:nth-child(5) { background: #f59e0b; }
.x-axis {
  grid-column: 2;
  display: flex;
  justify-content: space-between;
  padding-left: 8rpx;
  color: #9aa2aa;
  font-size: 16rpx;
  line-height: 24rpx;
}
.protein-row { margin-top: 14rpx; height: 76rpx; padding: 0 20rpx; display: grid; grid-template-columns: 145rpx 1fr 120rpx; align-items: center; gap: 16rpx; font-size: 25rpx; font-weight: 800; }
.bar { height: 10rpx; border-radius: 99rpx; background: #edf0ee; overflow: hidden; }
.bar i { display: block; height: 100%; border-radius: inherit; background: #16aa5d; }
.quick-actions { margin-top: 16rpx; display: grid; grid-template-columns: repeat(4, 1fr); height: 148rpx; padding: 10rpx 0; }
.quick-action { min-width: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12rpx; }
.quick-actions text { color: #181b20; font-size: 24rpx; font-weight: 800; line-height: 1; white-space: nowrap; }
.quick-icon {
  position: relative;
  width: 64rpx;
  height: 64rpx;
  border-radius: 20rpx;
  background: #e8f6ed;
  color: #0c9a51;
}
.quick-icon::before,
.quick-icon::after,
.quick-icon i {
  content: "";
  position: absolute;
  box-sizing: border-box;
  display: block;
}
.quick-icon-camera::before {
  left: 13rpx;
  top: 20rpx;
  width: 38rpx;
  height: 29rpx;
  border: 4rpx solid currentColor;
  border-radius: 8rpx;
}
.quick-icon-camera::after {
  left: 21rpx;
  top: 13rpx;
  width: 16rpx;
  height: 10rpx;
  border-radius: 4rpx 4rpx 0 0;
  background: currentColor;
}
.quick-icon-camera i {
  left: 26rpx;
  top: 27rpx;
  width: 12rpx;
  height: 12rpx;
  border: 3rpx solid currentColor;
  border-radius: 50%;
}
.quick-icon-scale::before {
  left: 12rpx;
  top: 13rpx;
  width: 40rpx;
  height: 38rpx;
  border: 4rpx solid currentColor;
  border-radius: 13rpx;
}
.quick-icon-scale::after {
  left: 26rpx;
  top: 22rpx;
  width: 12rpx;
  height: 12rpx;
  border-top: 4rpx solid currentColor;
  border-left: 4rpx solid currentColor;
  transform: rotate(45deg);
}
.quick-icon-dumbbell::before {
  left: 13rpx;
  top: 30rpx;
  width: 38rpx;
  height: 4rpx;
  border-radius: 99rpx;
  background: currentColor;
}
.quick-icon-dumbbell::after {
  left: 7rpx;
  top: 21rpx;
  width: 12rpx;
  height: 24rpx;
  border-radius: 5rpx;
  background: currentColor;
  box-shadow: 45rpx 0 0 currentColor;
}
.quick-icon-dumbbell i {
  left: 22rpx;
  top: 24rpx;
  width: 6rpx;
  height: 16rpx;
  border-radius: 3rpx;
  background: currentColor;
  box-shadow: 21rpx 0 0 currentColor;
}
.quick-icon-water::before {
  left: 19rpx;
  top: 10rpx;
  width: 27rpx;
  height: 40rpx;
  border: 4rpx solid currentColor;
  border-radius: 50% 50% 50% 50% / 62% 62% 38% 38%;
  transform: rotate(45deg);
}
.quick-icon-water::after {
  left: 24rpx;
  top: 34rpx;
  width: 17rpx;
  height: 4rpx;
  border-radius: 99rpx;
  background: currentColor;
  opacity: .35;
}
.section-title { margin: 28rpx 4rpx 14rpx; font-size: 30rpx; }
.plan-list { padding: 8rpx 20rpx; }
.plan-list view { height: 84rpx; display: grid; grid-template-columns: 56rpx 1fr auto; gap: 16rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.plan-list view:last-child { border-bottom: 0; }
.plan-list i { width: 50rpx; height: 50rpx; border-radius: 50%; background: #14b860; color: #fff; display: flex; align-items: center; justify-content: center; font-style: normal; font-size: 26rpx; }
.plan-list b, .plan-list small, .plan-list text { display: block; }
.plan-list b { font-size: 25rpx; }
.plan-list small { margin-top: 3rpx; color: #808791; font-size: 20rpx; }
.plan-list em { color: #0ca456; font-style: normal; font-size: 28rpx; font-weight: 900; line-height: 1; }
.plan-list .warn { color: #e69b13; }
.plan-list .water-plan small { color: #63a6d9; font-size: 19rpx; font-weight: 500; }
.plan-list .water-plan em { padding: 7rpx 12rpx; border-radius: 999rpx; background: #eef7ff; color: #2378b8; font-size: 20rpx; font-weight: 800; }
.ai-card { margin-top: 18rpx; padding: 22rpx; display: grid; grid-template-columns: 66rpx 1fr 24rpx; align-items: center; gap: 16rpx; border-radius: 18rpx; background: #edf9f0; border: 1rpx solid #d3ebda; }
.ai-card i { width: 58rpx; height: 58rpx; border-radius: 50%; background: #0e9f53; color: #fff; display: flex; align-items: center; justify-content: center; font-style: normal; }
.ai-card b, .ai-card text { display: block; }
.ai-card text { margin-top: 6rpx; font-size: 22rpx; color: #4c535c; }
.top-title { margin: 24rpx 0 20rpx; font-size: 38rpx; font-weight: 900; }
.food-preview { position: relative; height: 610rpx; border-radius: 20rpx; overflow: hidden; background: linear-gradient(145deg, #f6d8b0, #e9f6e9); display: flex; align-items: center; justify-content: center; }
.food-preview > text { position: absolute; top: 30rpx; left: 30rpx; padding: 10rpx 20rpx; border-radius: 99rpx; background: rgba(17, 24, 39, .72); color: #fff; font-size: 24rpx; }
.camera-head { height: 84rpx; display: grid; grid-template-columns: 64rpx 1fr 64rpx; align-items: center; }
.camera-head > text { text-align: center; color: #11151b; font-size: 38rpx; font-weight: 900; }
.camera-back { width: 44rpx; height: 44rpx; position: relative; }
.camera-back::before { content: ""; position: absolute; left: 13rpx; top: 8rpx; width: 23rpx; height: 23rpx; border-left: 5rpx solid #11151b; border-bottom: 5rpx solid #11151b; transform: rotate(45deg); }
.camera-help { justify-self: end; width: 44rpx; height: 44rpx; border: 4rpx solid #11151b; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #11151b; font-size: 28rpx; font-weight: 900; }
.camera-preview { position: relative; margin: 0 -34rpx; height: 520rpx; background: linear-gradient(180deg, #9f7651, #c6a17b); overflow: hidden; display: flex; align-items: center; justify-content: center; }
.camera-upload-image { position: absolute; inset: 0; width: 100%; height: 100%; z-index: 1; }
.camera-upload-image + .scan-corner ~ .food-plate { opacity: 0; }
.food-plate { width: 650rpx; height: 430rpx; border-radius: 50%; background: #e8e0d5; box-shadow: 0 18rpx 42rpx rgba(0,0,0,.22); position: relative; overflow: hidden; }
.food-plate i { position: absolute; display: block; }
.food-chicken { left: 86rpx; top: 86rpx; width: 220rpx; height: 120rpx; border-radius: 70rpx; background: repeating-linear-gradient(100deg, #d58a45 0 24rpx, #f6c08a 25rpx 42rpx); transform: rotate(-10deg); }
.food-rice { right: 110rpx; bottom: 62rpx; width: 245rpx; height: 160rpx; border-radius: 50%; background: radial-gradient(circle, #fff 0 34%, #f4f1e8 35%); }
.food-broccoli { right: 58rpx; top: 64rpx; width: 230rpx; height: 145rpx; border-radius: 50%; background: radial-gradient(circle at 30% 35%, #2a8b30 0 16%, transparent 17%), radial-gradient(circle at 60% 28%, #3fae3e 0 18%, transparent 19%), radial-gradient(circle at 48% 60%, #62bd43 0 20%, transparent 21%), #79c44c; }
.food-egg { left: 210rpx; bottom: 70rpx; width: 135rpx; height: 95rpx; border-radius: 50%; background: radial-gradient(circle, #f6a51b 0 29%, #fff 30%); }
.scan-corner { position: absolute; z-index: 2; width: 58rpx; height: 58rpx; border-color: #b6ffd0; }
.scan-corner.lt { left: 64rpx; top: 56rpx; border-left: 7rpx solid #b6ffd0; border-top: 7rpx solid #b6ffd0; border-radius: 16rpx 0 0 0; }
.scan-corner.rt { right: 64rpx; top: 56rpx; border-right: 7rpx solid #b6ffd0; border-top: 7rpx solid #b6ffd0; border-radius: 0 16rpx 0 0; }
.scan-corner.lb { left: 64rpx; bottom: 82rpx; border-left: 7rpx solid #b6ffd0; border-bottom: 7rpx solid #b6ffd0; border-radius: 0 0 0 16rpx; }
.scan-corner.rb { right: 64rpx; bottom: 82rpx; border-right: 7rpx solid #b6ffd0; border-bottom: 7rpx solid #b6ffd0; border-radius: 0 0 16rpx 0; }
.scan-status { position: absolute; left: 50%; bottom: 42rpx; transform: translateX(-50%); height: 52rpx; padding: 0 22rpx; display: flex; align-items: center; gap: 12rpx; border-radius: 12rpx; background: rgba(28, 30, 31, .78); color: #fff; font-size: 24rpx; }
.scan-status i { width: 24rpx; height: 24rpx; border: 4rpx solid #3edc82; border-right-color: transparent; border-radius: 50%; }
.recognition-sheet { margin: -10rpx -34rpx 0; position: relative; z-index: 3; padding: 22rpx 34rpx 160rpx; border-radius: 28rpx 28rpx 0 0; background: #fff; }
.sheet-grip { width: 68rpx; height: 8rpx; border-radius: 99rpx; background: #d8dce0; margin: 0 auto 20rpx; }
.recognition-head { display: grid; grid-template-columns: auto 1fr auto; gap: 18rpx; align-items: center; }
.recognition-head b { color: #11151b; font-size: 32rpx; font-weight: 900; }
.recognition-head text { justify-self: start; padding: 8rpx 18rpx; border-radius: 999rpx; background: #def5e8; color: #0b9f50; font-size: 23rpx; font-weight: 800; }
.recognition-head em { color: #0b9f50; font-style: normal; font-size: 25rpx; font-weight: 900; }
.recognition-list { margin-top: 20rpx; border: 1rpx solid #e5e9ed; border-radius: 16rpx; overflow: hidden; }
.recognition-list view { min-height: 82rpx; padding: 10rpx 18rpx; display: grid; grid-template-columns: 62rpx 1fr 138rpx 34rpx 116rpx 32rpx; gap: 14rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.recognition-list view:last-child { border-bottom: 0; }
.thumb { width: 54rpx; height: 54rpx; border-radius: 9rpx; }
.thumb.chicken { background: linear-gradient(135deg, #f1c18a, #c57b37); }
.thumb.rice { background: radial-gradient(circle, #fff 0 45%, #e9e3d6 46%); }
.thumb.broccoli { background: radial-gradient(circle, #2c8d31 0 35%, #61bd41 36%); }
.thumb.egg { background: radial-gradient(circle, #f5a51c 0 28%, #fff 29%); }
.recognition-list b { color: #11151b; font-size: 28rpx; font-weight: 900; }
.recognition-list input { height: 58rpx; border: 1rpx solid #dfe4e9; border-radius: 8rpx; text-align: center; font-size: 28rpx; color: #11151b; background: #fff; }
.recognition-list text { color: #333941; font-size: 24rpx; }
.recognition-list em { color: #ff6a00; font-style: normal; font-size: 24rpx; font-weight: 800; text-align: right; }
.recognition-list small { width: 28rpx; height: 28rpx; border: 3rpx solid #222831; border-radius: 5rpx; position: relative; }
.recognition-list small::after { content: ""; position: absolute; right: -4rpx; top: 2rpx; width: 14rpx; height: 4rpx; background: #222831; transform: rotate(-45deg); }
.camera-total { margin-top: 20rpx; height: 104rpx; padding: 0 28rpx; display: flex; align-items: center; gap: 24rpx; border-radius: 16rpx; background: #eef9f2; }
.camera-total i { width: 62rpx; height: 62rpx; border-radius: 50%; background: #0b9f50; position: relative; }
.camera-total i::before { content: ""; position: absolute; left: 23rpx; top: 14rpx; width: 18rpx; height: 34rpx; border-radius: 18rpx 18rpx 18rpx 3rpx; background: #fff; transform: rotate(35deg); }
.camera-total text { display: block; color: #333b43; font-size: 24rpx; }
.camera-total b { display: block; margin-top: 4rpx; color: #0b9f50; font-size: 42rpx; line-height: 1; }
.camera-total small { color: #333b43; font-size: 24rpx; font-weight: 500; }
.camera-actions { margin-top: 20rpx; display: flex; justify-content: space-between; gap: 0; }
.camera-actions button { width: 45%; height: 84rpx; border-radius: 12rpx; font-size: 30rpx; font-weight: 900; display: flex; align-items: center; justify-content: center; gap: 16rpx; }
.camera-actions button:first-child { background: #0b9f50; color: #fff; }
.camera-actions button:last-child { border: 2rpx solid #0b9f50; color: #0b9f50; background: #fff; }
.camera-minor { margin-top: 20rpx; display: flex; justify-content: space-between; gap: 0; }
.camera-minor button { width: 45%; height: 70rpx; border-radius: 12rpx; border: 1rpx solid #e0e5e9; color: #222831; font-size: 25rpx; font-weight: 800; background: #fff; display: flex; align-items: center; justify-content: center; gap: 14rpx; }
.camera-actions button i,
.camera-minor button i { position: relative; width: 34rpx; height: 34rpx; flex: 0 0 auto; color: currentColor; }
.camera-actions button i::before,
.camera-actions button i::after,
.camera-minor button i::before,
.camera-minor button i::after { content: ""; position: absolute; box-sizing: border-box; display: block; }
.action-check { border: 4rpx solid currentColor; border-radius: 50%; }
.action-check::after { left: 9rpx; top: 6rpx; width: 10rpx; height: 17rpx; border-right: 5rpx solid currentColor; border-bottom: 5rpx solid currentColor; transform: rotate(45deg); }
.action-edit::before { left: 6rpx; top: 20rpx; width: 22rpx; height: 4rpx; border-radius: 99rpx; background: currentColor; transform: rotate(-45deg); }
.action-edit::after { left: 18rpx; top: 7rpx; width: 9rpx; height: 20rpx; border: 4rpx solid currentColor; border-radius: 4rpx; transform: rotate(45deg); }
.action-camera::before { left: 3rpx; top: 11rpx; width: 28rpx; height: 21rpx; border: 4rpx solid currentColor; border-radius: 7rpx; }
.action-camera::after { left: 12rpx; top: 16rpx; width: 10rpx; height: 10rpx; border: 4rpx solid currentColor; border-radius: 50%; box-shadow: -2rpx -10rpx 0 -3rpx currentColor; }
.action-add { border: 4rpx solid currentColor; border-radius: 50%; }
.action-add::before { left: 8rpx; top: 13rpx; width: 14rpx; height: 4rpx; border-radius: 99rpx; background: currentColor; }
.action-add::after { left: 13rpx; top: 8rpx; width: 4rpx; height: 14rpx; border-radius: 99rpx; background: currentColor; }
.plate { width: 420rpx; height: 420rpx; border-radius: 50%; background: #fff; box-shadow: 0 14rpx 40rpx rgba(0,0,0,.12); position: relative; }
.plate i { position: absolute; border-radius: 50%; }
.plate i:nth-child(1) { width: 160rpx; height: 150rpx; left: 54rpx; top: 70rpx; background: #e7d4ad; }
.plate i:nth-child(2) { width: 150rpx; height: 150rpx; right: 58rpx; top: 78rpx; background: #d59359; }
.plate i:nth-child(3) { width: 140rpx; height: 125rpx; left: 82rpx; bottom: 70rpx; background: #28a752; }
.plate i:nth-child(4) { width: 110rpx; height: 110rpx; right: 92rpx; bottom: 72rpx; background: #efb347; }
.sheet { margin-top: -72rpx; position: relative; z-index: 2; padding: 26rpx; border-radius: 28rpx 28rpx 18rpx 18rpx; background: #fff; box-shadow: 0 -16rpx 48rpx rgba(18, 29, 43, .12); }
.food-row { min-height: 72rpx; display: grid; grid-template-columns: 1fr 86rpx 115rpx 70rpx; gap: 12rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; font-size: 25rpx; }
.food-row small { color: #7a828c; }
.food-row b, .food-row em { color: #f08a16; font-style: normal; }
.total-box, .context-card, .workout-status, .score-card { margin-top: 18rpx; padding: 20rpx; border-radius: 16rpx; background: #f2faf5; display: flex; justify-content: space-between; align-items: center; }
.total-box b { color: #0a9d50; font-size: 34rpx; }
.dual-buttons { margin-top: 20rpx; display: grid; grid-template-columns: 1fr 1fr; gap: 16rpx; }
.dual-buttons button, .primary, .sticky-primary { height: 84rpx; border-radius: 16rpx; background: #0e9f53; color: #fff; font-size: 29rpx; font-weight: 900; }
.dual-buttons button:nth-child(2) { background: #eef8f2; color: #0e9f53; }
.minor-actions { margin-top: 18rpx; display: flex; justify-content: center; gap: 48rpx; color: #6f7882; font-size: 24rpx; }
.title-row { margin: 22rpx 0; }
.title-row text { font-size: 38rpx; font-weight: 900; }
.nutrition-card { padding: 24rpx; position: relative; }
.nutrition-card > view:first-child b { display: block; margin-top: 8rpx; font-size: 46rpx; }
.donut { position: absolute; right: 26rpx; top: 26rpx; width: 128rpx; height: 128rpx; border-radius: 50%; background: conic-gradient(#11a75a 245deg, #edf0f2 0); display: flex; align-items: center; justify-content: center; color: #0f9f55; font-weight: 900; }
.macro-lines { margin-top: 24rpx; display: grid; gap: 16rpx; }
.macro-lines p { display: grid; grid-template-columns: 150rpx 1fr; gap: 14rpx; margin: 0; align-items: center; font-size: 23rpx; color: #5b636d; }
.macro-lines i { height: 10rpx; border-radius: 99rpx; background: #edf0f2; overflow: hidden; }
.macro-lines em { display: block; height: 100%; background: #13aa59; }
.warning { margin-top: 22rpx; padding: 12rpx 18rpx; border-radius: 12rpx; background: #fff6e8; color: #ef8a00; font-weight: 800; font-size: 23rpx; }
.meal-section { margin-top: 18rpx; padding: 20rpx 24rpx; border-radius: 18rpx; background: #fff; border: 1rpx solid #edf0f2; }
.meal-section b { color: #0a9d50; font-size: 24rpx; }
.meal-line { margin-top: 10rpx; display: flex; justify-content: space-between; font-weight: 900; }
.meal-line em { color: #f08a16; font-style: normal; }
.empty { border-style: dashed; }
.float-camera { position: absolute; right: 34rpx; bottom: 154rpx; width: 96rpx; height: 96rpx; border-radius: 50%; background: #0e9f53; color: #fff; font-size: 42rpx; box-shadow: 0 14rpx 34rpx rgba(14,159,83,.3); }
.diet-head { margin: 18rpx 0 28rpx; display: flex; align-items: center; justify-content: space-between; }
.diet-head > text { color: #05070a; font-size: 48rpx; font-weight: 900; line-height: 1; }
.diet-ai { display: flex; align-items: center; gap: 8rpx; color: #0b9f50; font-size: 24rpx; font-weight: 900; }
.diet-ai i { position: relative; width: 34rpx; height: 34rpx; border: 3rpx solid currentColor; border-radius: 50%; }
.diet-ai i::before,
.diet-ai i::after { content: ""; position: absolute; box-sizing: border-box; }
.diet-ai i::before { left: 8rpx; top: 8rpx; width: 6rpx; height: 6rpx; border-radius: 50%; background: currentColor; box-shadow: 10rpx 0 0 currentColor; }
.diet-ai i::after { left: 8rpx; bottom: 6rpx; width: 14rpx; height: 6rpx; border: 3rpx solid currentColor; border-top: 0; border-radius: 0 0 10rpx 10rpx; }
.date-switch { display: grid; grid-template-columns: 58rpx minmax(252rpx, 1fr) 58rpx; gap: 22rpx; align-items: center; width: 100%; max-width: 430rpx; margin-bottom: 22rpx; }
.date-arrow { height: 58rpx; border: 1rpx solid #dfe5e2; border-radius: 18rpx; display: flex; align-items: center; justify-content: center; color: #15181d; font-size: 42rpx; font-weight: 700; background: #fff; }
.date-pill { min-width: 0; height: 58rpx; padding: 0 18rpx; border: 1rpx solid #dfe5e2; border-radius: 18rpx; display: flex; align-items: center; justify-content: center; gap: 12rpx; background: #fff; color: #17191d; font-size: 26rpx; font-weight: 800; white-space: nowrap; }
.date-pill text { white-space: nowrap; line-height: 1; }
.date-pill i { position: relative; width: 27rpx; height: 26rpx; border: 3rpx solid #17191d; border-radius: 5rpx; }
.date-pill i::before { content: ""; position: absolute; left: 4rpx; right: 4rpx; top: 6rpx; border-top: 3rpx solid #17191d; }
.date-pill em { width: 0; height: 0; border-left: 7rpx solid transparent; border-right: 7rpx solid transparent; border-top: 8rpx solid #59616b; }
.diet-summary { padding: 30rpx; display: grid; grid-template-columns: 1fr 126rpx 112rpx; grid-template-rows: auto auto; gap: 24rpx 16rpx; align-items: center; }
.calorie-main b { color: #0fa857; font-size: 72rpx; font-weight: 800; line-height: .95; }
.calorie-main text { margin-left: 14rpx; color: #555b62; font-size: 33rpx; }
.summary-bar { margin-top: 22rpx; height: 17rpx; border-radius: 99rpx; background: #eef0f1; overflow: hidden; }
.summary-bar i { display: block; height: 100%; border-radius: inherit; background: #0fa857; }
.calorie-main p { margin: 18rpx 0 0; color: #59616b; font-size: 26rpx; }
.calorie-main strong { color: #0fa857; font-size: 29rpx; }
.macro-donut { display: flex; justify-content: flex-end; }
.macro-donut view { width: 118rpx; height: 118rpx; border-radius: 50%; background: conic-gradient(#12a95a 0 94deg, #ff8b22 94deg 252deg, #ffbf1d 252deg 360deg); position: relative; }
.macro-donut view::after { content: ""; position: absolute; inset: 27rpx; border-radius: 50%; background: #fff; }
.macro-legend { display: grid; gap: 17rpx; }
.macro-legend p { margin: 0; display: grid; grid-template-columns: 18rpx 1fr; grid-template-rows: auto auto; column-gap: 14rpx; row-gap: 3rpx; align-items: center; }
.macro-legend i { width: 14rpx; height: 14rpx; border-radius: 50%; background: #13a95a; }
.macro-legend p:nth-child(2) i { background: #ff8b22; }
.macro-legend p:nth-child(3) i { background: #ffbf1d; }
.macro-legend b { color: #20242a; font-size: 29rpx; font-weight: 900; line-height: 1; }
.macro-legend text { grid-column: 2; color: #8a929b; font-size: 20rpx; line-height: 1; }
.macro-stats { grid-column: 1 / -1; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 28rpx; }
.macro-stats view { min-width: 0; }
.macro-stats b { display: block; color: #17191d; font-size: 24rpx; white-space: nowrap; }
.macro-stats i { margin-top: 13rpx; display: block; height: 10rpx; border-radius: 99rpx; background: #eef0f1; overflow: hidden; }
.macro-stats em { display: block; height: 100%; border-radius: inherit; background: #0fa857; }
.macro-stats view:nth-child(2) em,
.macro-stats view:nth-child(3) em { background: #f5a400; }
.macro-stats text { display: block; margin-top: 10rpx; color: #7b828b; font-size: 22rpx; }
.protein-warning { justify-self: end; min-width: 230rpx; height: 68rpx; padding: 0 20rpx; display: flex; align-items: center; justify-content: center; gap: 12rpx; border-radius: 22rpx; background: #fff0e8; color: #ff6a18; font-size: 26rpx; font-weight: 900; }
.protein-warning i { position: relative; width: 36rpx; height: 36rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.protein-warning i::before { content: ""; position: absolute; left: 13rpx; top: 7rpx; width: 4rpx; height: 12rpx; border-radius: 99rpx; background: currentColor; }
.protein-warning i::after { content: ""; position: absolute; left: 13rpx; bottom: 6rpx; width: 4rpx; height: 4rpx; border-radius: 50%; background: currentColor; }
.meal-card { margin-top: 18rpx; border-radius: 18rpx; background: #fff; border: 1rpx solid #e5e8ec; box-shadow: 0 10rpx 26rpx rgba(20, 32, 45, .06); overflow: hidden; }
.meal-card-head { min-height: 88rpx; padding: 0 26rpx; display: grid; grid-template-columns: 1fr auto 24rpx; gap: 16rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.meal-card-head view { display: flex; align-items: baseline; gap: 24rpx; min-width: 0; }
.meal-card-head b { color: #090b0f; font-size: 30rpx; font-weight: 900; white-space: nowrap; }
.meal-card-head text { color: #696f78; font-size: 23rpx; white-space: nowrap; }
.meal-card-head em { color: #101216; font-size: 34rpx; font-weight: 900; font-style: normal; white-space: nowrap; }
.meal-card-head small { color: #59616a; font-size: 22rpx; font-weight: 500; }
.meal-card-head i { color: #8b929a; font-style: normal; font-size: 38rpx; line-height: 1; }
.meal-food { min-height: 106rpx; padding: 20rpx 26rpx; display: grid; grid-template-columns: 116rpx 1fr; gap: 24rpx; align-items: center; }
.food-thumb { width: 116rpx; height: 82rpx; border-radius: 14rpx; overflow: hidden; }
.food-thumb.oatmeal { background: radial-gradient(circle at 48% 50%, #f3e4c6 0 28%, transparent 29%), radial-gradient(circle at 35% 39%, #2f5d9e 0 7%, transparent 8%), radial-gradient(circle at 62% 38%, #2f5d9e 0 6%, transparent 7%), linear-gradient(135deg, #d6b38a, #fff6df); }
.food-thumb.chicken { background: radial-gradient(circle at 18% 28%, #3aa955 0 16%, transparent 17%), radial-gradient(circle at 78% 46%, #f05e2e 0 14%, transparent 15%), linear-gradient(135deg, #f7f0df 0 45%, #d79a60 46% 62%, #f9faf2 63%); }
.meal-food b,
.meal-food text { display: block; }
.meal-food b { color: #15181d; font-size: 29rpx; font-weight: 900; }
.meal-food text { margin-top: 14rpx; color: #6a727c; font-size: 24rpx; }
.meal-food small { margin-left: 14rpx; padding: 4rpx 10rpx; border-radius: 8rpx; background: #e7f7ed; color: #0b9f50; font-size: 21rpx; font-weight: 800; }
.dinner-empty .meal-card-head { border-bottom: 0; }
.empty-dinner { min-height: 170rpx; padding: 10rpx 36rpx 28rpx; display: grid; grid-template-columns: 112rpx 1fr; gap: 28rpx; align-items: center; }
.dish-icon { width: 112rpx; height: 112rpx; border-radius: 50%; background: #eaf8f0; display: flex; align-items: center; justify-content: center; color: #0e9f53; }
.dish-icon i { position: relative; width: 58rpx; height: 37rpx; border-bottom: 4rpx solid currentColor; }
.dish-icon i::before { content: ""; position: absolute; left: 8rpx; bottom: 5rpx; width: 42rpx; height: 32rpx; border: 4rpx solid currentColor; border-bottom: 0; border-radius: 42rpx 42rpx 0 0; }
.dish-icon i::after { content: ""; position: absolute; left: 27rpx; top: -6rpx; width: 6rpx; height: 7rpx; border-radius: 50%; background: currentColor; }
.empty-dinner b,
.empty-dinner text { display: block; }
.empty-dinner b { color: #16191d; font-size: 31rpx; font-weight: 900; }
.empty-dinner text { margin-top: 10rpx; color: #727982; font-size: 23rpx; }
.empty-dinner button { margin-top: 18rpx; width: 164rpx; height: 56rpx; border-radius: 10rpx; background: #0e9f53; color: #fff; font-size: 25rpx; font-weight: 900; }
.snack-card { margin-right: 0; }
.snack-row { min-height: 96rpx; padding: 18rpx 26rpx; display: grid; grid-template-columns: 60rpx 1fr auto; gap: 22rpx; align-items: center; }
.snack-icon { width: 60rpx; height: 60rpx; border-radius: 50%; background: radial-gradient(circle at 52% 42%, transparent 0 17%, #0e9f53 18% 22%, transparent 23%), #f0f3f2; position: relative; }
.snack-icon::before { content: ""; position: absolute; left: 23rpx; top: 16rpx; width: 16rpx; height: 21rpx; border: 3rpx solid #0e9f53; border-radius: 50% 50% 46% 46%; transform: rotate(20deg); }
.snack-row b,
.snack-row text { display: block; }
.snack-row b { color: #181b20; font-size: 25rpx; font-weight: 900; }
.snack-row text { margin-top: 8rpx; color: #737b84; font-size: 21rpx; }
.add-record { color: #0b9f50; font-size: 27rpx; font-weight: 900; white-space: nowrap; }
.float-camera { position: fixed; right: calc((100vw - min(100vw, 512px)) / 2 + 34rpx); bottom: 154rpx; z-index: 30; display: flex; align-items: center; justify-content: center; }
.float-camera i { position: relative; width: 47rpx; height: 36rpx; border: 6rpx solid #fff; border-radius: 9rpx; }
.float-camera i::before { content: ""; position: absolute; left: 11rpx; top: 7rpx; width: 13rpx; height: 13rpx; border: 5rpx solid #fff; border-radius: 50%; }
.float-camera i::after { content: ""; position: absolute; left: 8rpx; top: -14rpx; width: 17rpx; height: 9rpx; border-radius: 6rpx 6rpx 0 0; background: #fff; }
.context-card { display: grid; grid-template-columns: repeat(3,1fr); gap: 12rpx; background: #fff; border: 1rpx solid #e8ecef; }
.context-card view { text-align: center; border-right: 1rpx solid #edf0f2; }
.context-card view:last-child { border-right: 0; }
.context-card b { display: block; color: #0e9f53; font-size: 32rpx; }
.context-card text { color: #6f7780; font-size: 20rpx; }
.advice-main, .why, .form-card, .chart-card, .strength, .review-stats, .review, .goal-card { margin-top: 18rpx; padding: 24rpx; }
h3 { margin: 0 0 18rpx; font-size: 32rpx; }
.option { min-height: 122rpx; display: grid; grid-template-columns: 76rpx 1fr; gap: 16rpx; align-items: center; border-top: 1rpx solid #edf0f2; }
.option i, .exercise-card i { width: 68rpx; height: 68rpx; border-radius: 14rpx; background: linear-gradient(135deg, #e4bd85, #25a85d); }
.option b, .option text { display: block; }
.option text { margin-top: 4rpx; color: #f08a16; font-size: 23rpx; }
.option p { display: flex; gap: 8rpx; margin: 8rpx 0 0; }
.option small, .categories text, .form-row p text { padding: 8rpx 14rpx; border-radius: 10rpx; background: #f0f4f2; color: #59616b; font-size: 20rpx; }
.why b, .why text, .review b, .review text { display: block; }
.why text, .review text { margin-top: 10rpx; color: #58616b; font-size: 24rpx; line-height: 1.55; }
.question-chips, .context-chips, .categories { margin-top: 18rpx; display: flex; gap: 12rpx; flex-wrap: wrap; }
.primary { margin-top: 22rpx; width: 100%; }
.advice-head { margin-top: 18rpx; height: 72rpx; display: grid; grid-template-columns: 64rpx 1fr 64rpx; align-items: center; }
.advice-head > text { text-align: center; color: #11151b; font-size: 40rpx; font-weight: 900; }
.advice-back { width: 44rpx; height: 44rpx; display: flex; align-items: center; justify-content: flex-start; }
.advice-chat { justify-self: end; width: 44rpx; height: 44rpx; display: flex; align-items: center; justify-content: center; position: relative; color: #0b9f50; }
.advice-chat i { position: absolute; left: 4rpx; top: 8rpx; width: 32rpx; height: 24rpx; border: 4rpx solid currentColor; border-radius: 10rpx; }
.advice-chat i::before { content: ""; position: absolute; left: 7rpx; bottom: -9rpx; width: 9rpx; height: 9rpx; border-left: 4rpx solid currentColor; border-bottom: 4rpx solid currentColor; background: #fbfcfa; transform: rotate(-25deg); }
.advice-chat i::after { content: ""; position: absolute; right: -10rpx; top: -10rpx; width: 8rpx; height: 8rpx; border-radius: 50%; background: currentColor; box-shadow: 7rpx -5rpx 0 -2rpx currentColor; }
.advice-summary { margin-top: 28rpx; padding: 26rpx 28rpx; border-radius: 18rpx; border: 1rpx solid #e1e5e9; background: #fff; display: grid; grid-template-columns: repeat(3, 1fr); }
.advice-summary view { min-width: 0; display: grid; grid-template-columns: 70rpx 1fr; column-gap: 18rpx; align-items: center; border-right: 1rpx solid #e5e9ed; }
.advice-summary view:last-child { border-right: 0; }
.advice-summary i { grid-row: 1 / 3; width: 64rpx; height: 64rpx; border-radius: 50%; background: linear-gradient(135deg, #87cf72, #35ad55); position: relative; color: #fff; }
.advice-summary .iconfont-circle,
.recommend-reason .iconfont-circle { display: flex; align-items: center; justify-content: center; }
.advice-summary .iconfont-circle::before,
.advice-summary .iconfont-circle::after,
.recommend-reason .iconfont-circle::before,
.recommend-reason .iconfont-circle::after { display: none; }
.advice-summary text { color: #333941; font-size: 23rpx; }
.advice-summary b { margin-top: 6rpx; color: #11151b; font-size: 40rpx; font-weight: 900; line-height: 1; }
.advice-summary small { color: #5f6771; font-size: 22rpx; font-weight: 500; }
.advice-fire::before { content: ""; position: absolute; left: 23rpx; top: 14rpx; width: 18rpx; height: 34rpx; border-radius: 18rpx 18rpx 18rpx 3rpx; background: currentColor; transform: rotate(35deg); }
.advice-gauge::before { content: ""; position: absolute; left: 16rpx; top: 20rpx; width: 32rpx; height: 22rpx; border: 6rpx solid currentColor; border-bottom: 0; border-radius: 32rpx 32rpx 0 0; }
.advice-gauge::after { content: ""; position: absolute; left: 31rpx; top: 30rpx; width: 5rpx; height: 17rpx; border-radius: 99rpx; background: currentColor; transform: rotate(45deg); }
.advice-protein::before { content: ""; position: absolute; left: 20rpx; top: 16rpx; width: 24rpx; height: 27rpx; border: 6rpx solid currentColor; border-top: 0; border-radius: 0 0 18rpx 18rpx; transform: rotate(-18deg); }
.advice-card { margin-top: 20rpx; padding: 28rpx; border-radius: 18rpx; border: 1rpx solid #e1e5e9; background: #fff; box-shadow: 0 8rpx 22rpx rgba(20, 32, 45, .04); }
.advice-title { display: flex; align-items: center; gap: 16rpx; margin-bottom: 22rpx; }
.advice-title i { width: 34rpx; height: 34rpx; position: relative; color: #0b9f50; }
.advice-title i::before { content: ""; position: absolute; left: 9rpx; top: 9rpx; width: 15rpx; height: 15rpx; background: currentColor; transform: rotate(45deg); }
.advice-title i::after { content: ""; position: absolute; right: 0; top: 0; width: 8rpx; height: 8rpx; border-radius: 50%; background: currentColor; }
.advice-title b { color: #11151b; font-size: 34rpx; font-weight: 900; }
.dinner-option { min-height: 154rpx; padding: 12rpx; display: grid; grid-template-columns: 170rpx 1fr 104rpx 24rpx; gap: 18rpx; align-items: center; border: 1rpx solid #e4e8ec; border-radius: 16rpx; margin-top: 14rpx; }
.dinner-img { width: 170rpx; height: 124rpx; border-radius: 14rpx; background: #eef4e9; }
.dinner-img.salad { background: radial-gradient(circle at 28% 40%, #d88949 0 18%, transparent 19%), radial-gradient(circle at 66% 58%, #ffd342 0 13%, transparent 14%), linear-gradient(135deg, #80c75c, #f4f8e8); }
.dinner-img.shrimp { background: radial-gradient(circle at 47% 38%, #f08d49 0 20%, transparent 21%), radial-gradient(circle at 64% 57%, #efd6a5 0 17%, transparent 18%), linear-gradient(135deg, #f6f1dc, #e2bd84); }
.dinner-img.beef { background: radial-gradient(circle at 40% 45%, #8d5434 0 18%, transparent 19%), radial-gradient(circle at 63% 54%, #ec8b3a 0 13%, transparent 14%), linear-gradient(135deg, #dff0d8, #b8dc9c); }
.dinner-info text { color: #0b9f50; font-size: 24rpx; font-weight: 900; }
.dinner-info b { display: block; margin-top: 10rpx; color: #11151b; font-size: 29rpx; font-weight: 900; }
.dinner-info p { margin: 18rpx 0 0; display: flex; gap: 12rpx; flex-wrap: wrap; }
.dinner-info small { padding: 7rpx 14rpx; border-radius: 10rpx; background: #eaf6ee; color: #244d33; font-size: 20rpx; }
.dinner-info small:nth-child(2) { background: #fff5d9; color: #735414; }
.dinner-info small:nth-child(3) { background: #fdece6; color: #7c3c2d; }
.dinner-option > em { color: #219653; font-size: 38rpx; font-style: normal; font-weight: 900; text-align: right; }
.dinner-option > em small { color: #59616b; font-size: 22rpx; font-weight: 500; }
.dinner-option > .uni-icons { justify-self: center; }
.recommend-reason { margin-top: 20rpx; padding: 24rpx; display: grid; grid-template-columns: 64rpx 1fr; gap: 20rpx; border-radius: 16rpx; background: #eef9f2; }
.recommend-reason > i { width: 54rpx; height: 54rpx; border-radius: 50%; background: #0b9f50; position: relative; }
.recommend-reason > i::before { content: ""; position: absolute; left: 21rpx; top: 12rpx; width: 12rpx; height: 22rpx; border-radius: 12rpx 12rpx 3rpx 3rpx; background: #fff; }
.recommend-reason b { color: #143621; font-size: 25rpx; font-weight: 900; }
.recommend-reason text { display: block; margin-top: 10rpx; color: #27323b; font-size: 23rpx; line-height: 1.55; }
.ask-title { margin-top: 26rpx; color: #11151b; font-size: 27rpx; font-weight: 900; }
.advice-questions { margin-top: 14rpx; display: grid; grid-template-columns: repeat(3, 1fr); gap: 18rpx; }
.advice-questions view { height: 66rpx; display: flex; align-items: center; justify-content: center; gap: 10rpx; border: 1rpx solid #e0e5e9; border-radius: 14rpx; color: #0b8f48; font-size: 22rpx; font-weight: 800; white-space: nowrap; }
.advice-questions i { width: 28rpx; height: 28rpx; position: relative; color: #0b9f50; }
.q-card::before { content: ""; position: absolute; inset: 4rpx; border-radius: 5rpx; background: currentColor; }
.q-bowl::before { content: ""; position: absolute; left: 4rpx; top: 12rpx; width: 20rpx; height: 12rpx; border: 4rpx solid currentColor; border-top: 0; border-radius: 0 0 18rpx 18rpx; }
.q-muscle::before { content: ""; position: absolute; left: 3rpx; top: 10rpx; width: 21rpx; height: 13rpx; border: 4rpx solid currentColor; border-top: 0; border-radius: 0 0 14rpx 14rpx; transform: rotate(-18deg); }
.meal-plan-button { margin-top: 30rpx; width: 100%; height: 86rpx; border-radius: 999rpx; background: #249f4f; color: #fff; font-size: 31rpx; font-weight: 900; }
.form-row { min-height: 92rpx; display: grid; grid-template-columns: 90rpx 1fr; gap: 18rpx; align-items: center; border-bottom: 1rpx solid #eef1f3; }
.form-row:last-child { border-bottom: 0; }
.form-row p { margin: 0; display: flex; gap: 10rpx; flex-wrap: wrap; }
.form-row p .selected, .categories .active { background: #e8f6ed; color: #0e9f53; border: 1rpx solid #0e9f53; }
.form-row p .wide { padding-left: 22rpx; padding-right: 22rpx; }
.week-card { padding: 12rpx 22rpx; }
.week-card view { height: 82rpx; display: grid; grid-template-columns: 74rpx 1fr; gap: 16rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.week-card view:last-child { border-bottom: 0; }
.week-card i { color: #0e9f53; font-style: normal; font-weight: 900; }
.week-card b, .week-card small { display: block; }
.week-card small { color: #7a828c; margin-top: 4rpx; }
.training-head { margin: 14rpx 0 26rpx; display: grid; grid-template-columns: 1fr auto; align-items: center; }
.training-head > text { text-align: center; color: #11151b; font-size: 46rpx; font-weight: 900; line-height: 1; }
.history-link { display: flex; align-items: center; gap: 8rpx; color: #1c222a; font-size: 24rpx; font-weight: 800; white-space: nowrap; }
.history-link i { position: relative; width: 30rpx; height: 30rpx; border: 4rpx solid currentColor; border-left-color: transparent; border-radius: 50%; }
.history-link i::before { content: ""; position: absolute; left: -3rpx; top: 3rpx; width: 11rpx; height: 11rpx; border-left: 4rpx solid currentColor; border-top: 4rpx solid currentColor; transform: rotate(-45deg); }
.history-link i::after { content: ""; position: absolute; left: 12rpx; top: 6rpx; width: 4rpx; height: 11rpx; border-radius: 99rpx; background: currentColor; transform-origin: bottom; transform: rotate(-45deg); }
.training-card { margin-top: 18rpx; border-radius: 18rpx; background: #fff; border: 1rpx solid #dfe4e9; box-shadow: 0 8rpx 22rpx rgba(20, 32, 45, .04); }
.plan-history-card { padding: 10rpx 18rpx; }
.plan-history-empty { height: 78rpx; display: flex; align-items: center; justify-content: center; color: #7a828b; font-size: 24rpx; }
.plan-history-row { min-height: 82rpx; display: grid; grid-template-columns: 1fr 180rpx 22rpx; gap: 14rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.plan-history-row:last-child { border-bottom: 0; }
.plan-history-row.active { color: #0b9f50; }
.plan-history-row b { display: block; color: #11151b; font-size: 25rpx; font-weight: 900; }
.plan-history-row text { display: block; margin-top: 8rpx; color: #69717b; font-size: 21rpx; }
.plan-history-row small { min-width: 0; color: #5f6872; font-size: 20rpx; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; text-align: right; }
.plan-history-row em { color: #8b929b; font-size: 34rpx; font-style: normal; }
.training-config { padding: 0 26rpx; }
.config-row { min-height: 106rpx; display: grid; grid-template-columns: 138rpx 1fr; gap: 14rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.config-row:last-child { border-bottom: 0; }
.config-row > b,
.chip-section > b,
.preview-head b { color: #151a22; font-size: 25rpx; font-weight: 900; white-space: nowrap; }
.goal-row { grid-template-columns: 138rpx 1fr; min-height: 116rpx; }
.goal-options { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8rpx; }
.goal-options view,
.place-options view,
.training-chips view { min-width: 0; height: 60rpx; display: flex; align-items: center; justify-content: center; gap: 7rpx; border: 1rpx solid #dfe4e9; border-radius: 14rpx; color: #1e242c; font-size: 23rpx; font-weight: 800; background: #fff; white-space: nowrap; }
.goal-options .active,
.place-options .active { border-color: #0da052; background: #0da052; color: #fff; box-shadow: 0 10rpx 20rpx rgba(13, 160, 82, .18); }
.number-row { grid-template-columns: 138rpx 1fr 142rpx; }
.number-row small { color: #737b85; font-size: 21rpx; text-align: right; white-space: nowrap; }
.stepper { display: grid; grid-template-columns: 58rpx 64rpx 48rpx 58rpx; gap: 14rpx; align-items: center; justify-content: center; }
.stepper button { width: 58rpx; height: 58rpx; border-radius: 50%; border: 1rpx solid #d7dde3; color: #151a22; font-size: 38rpx; font-weight: 700; background: #fff; display: flex; align-items: center; justify-content: center; line-height: 1; }
.stepper strong { color: #0da052; font-size: 45rpx; font-weight: 900; text-align: center; line-height: 1; }
.stepper text { color: #151a22; font-size: 25rpx; font-weight: 800; white-space: nowrap; }
.place-row { grid-template-columns: 138rpx 1fr; }
.place-options { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10rpx; }
.chip-section { min-height: 92rpx; padding: 18rpx 24rpx; display: grid; grid-template-columns: 168rpx 1fr; gap: 14rpx; align-items: center; }
.chip-section > b { line-height: 1.1; }
.chip-section b small { display: block; margin-top: 6rpx; color: #8a929b; font-size: 18rpx; font-weight: 500; line-height: 1; }
.training-chips { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12rpx; }
.training-chips view.selected { border-color: #0da052; background: #eef9f2; color: #0b9f50; }
.library-link { height: 76rpx; padding: 0 24rpx; display: flex; align-items: center; justify-content: space-between; }
.library-link view { display: flex; align-items: center; gap: 12rpx; color: #11151b; font-size: 25rpx; font-weight: 900; }
.selected-exercise-card { padding: 22rpx 24rpx; display: block; }
.selected-exercise-card > b { display: block; color: #11151b; font-size: 27rpx; font-weight: 900; margin-bottom: 16rpx; }
.selected-exercise-list { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12rpx; }
.selected-exercise-list view { min-width: 0; height: 68rpx; padding: 0 14rpx; display: grid; grid-template-columns: 1fr 28rpx; grid-template-rows: 1fr 1fr; align-items: center; border-radius: 14rpx; background: #eef9f2; border: 1rpx solid #bfe6cd; }
.selected-exercise-list text { min-width: 0; color: #0b7f43; font-size: 24rpx; font-weight: 900; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.selected-exercise-list small { min-width: 0; color: #4f6f5b; font-size: 19rpx; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.selected-exercise-list em { grid-column: 2; grid-row: 1 / 3; color: #5f6872; font-size: 34rpx; font-style: normal; text-align: right; }
.limits { grid-template-columns: 168rpx 1fr; gap: 10rpx 14rpx; }
.limit-chips { display: flex; gap: 10rpx; flex-wrap: nowrap; min-width: 0; }
.limit-chips view { height: 50rpx; padding: 0 12rpx; display: flex; align-items: center; gap: 7rpx; border-radius: 12rpx; background: #eaf6ef; color: #1f3329; font-size: 20rpx; font-weight: 800; white-space: nowrap; }
.limit-chips view:not(.selected) { background: #fff; color: #5f6872; border: 1rpx solid #dfe4e9; }
.limit-chips view:not(.selected) i { background: #c8d0d7; }
.limit-chips i { width: 26rpx; height: 26rpx; border-radius: 50%; background: #0da052; position: relative; }
.limit-chips i::after { content: ""; position: absolute; left: 7rpx; top: 5rpx; width: 9rpx; height: 13rpx; border-right: 4rpx solid #fff; border-bottom: 4rpx solid #fff; transform: rotate(45deg); }
.limit-help { grid-column: 2; color: #7a828b; font-size: 20rpx; text-align: left; white-space: normal; line-height: 1.35; }
.plan-preview { padding: 22rpx 26rpx 20rpx; }
.preview-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18rpx; }
.preview-head text { color: #7a828b; font-size: 23rpx; }
.preview-list { border: 1rpx solid #e5e9ed; border-radius: 14rpx; overflow: hidden; }
.preview-list view { min-height: 78rpx; padding: 0 18rpx; display: grid; grid-template-columns: 48rpx 72rpx 1fr 250rpx 22rpx; gap: 12rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.preview-list view:last-child { border-bottom: 0; }
.preview-list i { width: 38rpx; height: 38rpx; color: #0da052; position: relative; }
.preview-list b { color: #151a22; font-size: 25rpx; font-weight: 800; }
.preview-list strong { color: #151a22; font-size: 27rpx; font-weight: 900; }
.preview-list text { color: #69717b; font-size: 22rpx; text-align: right; white-space: nowrap; }
.preview-list em { color: #8b929b; font-style: normal; font-size: 36rpx; line-height: 1; }
.plan-preview p { margin: 20rpx 0 0; display: flex; align-items: center; gap: 12rpx; color: #707883; font-size: 21rpx; }
.plan-preview p i { width: 26rpx; height: 26rpx; border: 3rpx solid currentColor; border-radius: 50%; position: relative; flex: 0 0 auto; }
.plan-preview p i::before { content: ""; position: absolute; left: 10rpx; top: 9rpx; width: 4rpx; height: 9rpx; border-radius: 99rpx; background: currentColor; }
.plan-preview p i::after { content: ""; position: absolute; left: 10rpx; top: 5rpx; width: 4rpx; height: 4rpx; border-radius: 50%; background: currentColor; }
.generate-plan { margin-top: 28rpx; width: 100%; height: 90rpx; border-radius: 14rpx; background: #0da052; color: #fff; font-size: 31rpx; font-weight: 900; box-shadow: 0 14rpx 30rpx rgba(13, 160, 82, .18); }
.goal-options i,
.place-options i,
.training-chips i { position: relative; width: 24rpx; height: 24rpx; color: currentColor; flex: 0 0 auto; overflow: visible; }
.goal-options i::before,
.goal-options i::after,
.place-options i::before,
.place-options i::after,
.training-chips i::before,
.training-chips i::after,
.preview-list i::before,
.preview-list i::after { content: ""; position: absolute; box-sizing: border-box; display: block; }
.icon-fire::before { left: 8rpx; top: 2rpx; width: 12rpx; height: 19rpx; border-radius: 12rpx 12rpx 12rpx 3rpx; background: currentColor; transform: rotate(35deg); }
.icon-fire::after { left: 7rpx; top: 10rpx; width: 9rpx; height: 12rpx; border-radius: 10rpx 10rpx 10rpx 2rpx; background: rgba(255, 255, 255, .45); transform: rotate(35deg); }
.icon-muscle::before { left: 3rpx; top: 8rpx; width: 18rpx; height: 11rpx; border: 3rpx solid currentColor; border-top: 0; border-radius: 0 0 13rpx 13rpx; transform: rotate(-22deg); }
.icon-muscle::after { left: 12rpx; top: 4rpx; width: 9rpx; height: 10rpx; border: 3rpx solid currentColor; border-left: 0; border-radius: 0 9rpx 9rpx 0; transform: rotate(-22deg); }
.icon-shape::before { left: 5rpx; top: 3rpx; width: 14rpx; height: 19rpx; border-left: 3rpx solid currentColor; border-right: 3rpx solid currentColor; border-radius: 50%; }
.icon-shape::after { left: 8rpx; top: 9rpx; width: 8rpx; height: 6rpx; border-top: 3rpx solid currentColor; border-bottom: 3rpx solid currentColor; border-radius: 50%; }
.icon-stamina::before { left: 4rpx; top: 7rpx; width: 16rpx; height: 14rpx; border: 3rpx solid currentColor; border-radius: 50% 50% 46% 46%; }
.icon-stamina::after { left: 9rpx; top: 4rpx; width: 7rpx; height: 7rpx; border-radius: 50%; border: 3rpx solid currentColor; background: transparent; }
.icon-dumbbell::before { left: 2rpx; top: 10rpx; width: 20rpx; height: 4rpx; border-radius: 99rpx; background: currentColor; }
.icon-dumbbell::after { left: -1rpx; top: 6rpx; width: 7rpx; height: 12rpx; border-radius: 3rpx; background: currentColor; box-shadow: 20rpx 0 0 currentColor; }
.icon-home::before { left: 5rpx; top: 11rpx; width: 15rpx; height: 11rpx; border: 3rpx solid currentColor; border-top: 0; border-radius: 0 0 3rpx 3rpx; }
.icon-home::after { left: 5rpx; top: 5rpx; width: 14rpx; height: 14rpx; border-left: 3rpx solid currentColor; border-top: 3rpx solid currentColor; transform: rotate(45deg); }
.icon-tree::before { left: 6rpx; top: 4rpx; width: 13rpx; height: 14rpx; border: 3rpx solid currentColor; border-radius: 50% 50% 45% 45%; }
.icon-tree::after { left: 11rpx; top: 17rpx; width: 3rpx; height: 8rpx; background: currentColor; box-shadow: -6rpx 7rpx 0 -1rpx currentColor, 6rpx 7rpx 0 -1rpx currentColor; }
.icon-runner::before { left: 8rpx; top: 2rpx; width: 7rpx; height: 7rpx; border-radius: 50%; background: currentColor; }
.icon-runner::after { left: 5rpx; top: 11rpx; width: 15rpx; height: 11rpx; border-left: 4rpx solid currentColor; border-bottom: 4rpx solid currentColor; transform: skew(-22deg) rotate(-8deg); }
.plan-muscle::before { left: 7rpx; top: 14rpx; width: 22rpx; height: 13rpx; border: 4rpx solid currentColor; border-top: 0; border-radius: 0 0 16rpx 16rpx; transform: rotate(-18deg); }
.plan-muscle::after { left: 21rpx; top: 8rpx; width: 10rpx; height: 12rpx; border: 4rpx solid currentColor; border-left: 0; border-radius: 0 10rpx 10rpx 0; transform: rotate(-18deg); }
.plan-run::before { left: 14rpx; top: 3rpx; width: 8rpx; height: 8rpx; border-radius: 50%; background: currentColor; }
.plan-run::after { left: 7rpx; top: 15rpx; width: 23rpx; height: 16rpx; border-left: 5rpx solid currentColor; border-bottom: 5rpx solid currentColor; transform: skew(-24deg) rotate(-8deg); }
.plan-leg::before { left: 12rpx; top: 5rpx; width: 12rpx; height: 25rpx; border-left: 5rpx solid currentColor; border-bottom: 5rpx solid currentColor; border-radius: 0 0 0 9rpx; }
.plan-leg::after { left: 21rpx; top: 25rpx; width: 13rpx; height: 5rpx; border-radius: 99rpx; background: currentColor; }
.plan-cycle::before { left: 5rpx; top: 8rpx; width: 27rpx; height: 22rpx; border: 4rpx solid currentColor; border-left-color: transparent; border-radius: 50%; }
.plan-cycle::after { right: 1rpx; top: 3rpx; width: 10rpx; height: 10rpx; border-top: 4rpx solid currentColor; border-right: 4rpx solid currentColor; transform: rotate(22deg); }
.workout-status { display: grid; grid-template-columns: 1fr 1fr; gap: 12rpx; text-align: center; background: #fff; border: 1rpx solid #e8ecef; }
.workout-status b { display: block; font-size: 40rpx; color: #0e9f53; }
.workout-status text { color: #69727c; font-size: 22rpx; }
.workout-list { margin-top: 18rpx; display: grid; gap: 14rpx; }
.workout-row { min-height: 94rpx; padding: 18rpx; display: grid; grid-template-columns: 48rpx 1fr; gap: 16rpx; align-items: center; }
.workout-row i { width: 40rpx; height: 40rpx; border-radius: 50%; border: 2rpx solid #cbd5d1; display: flex; align-items: center; justify-content: center; font-style: normal; color: #0e9f53; }
.workout-row.done i { background: #0e9f53; border-color: #0e9f53; color: #fff; }
.workout-row.active { border-color: #0e9f53; background: #f5fbf7; }
.workout-row b, .workout-row text { display: block; }
.workout-row text { margin-top: 6rpx; color: #6c747e; font-size: 23rpx; }
.workout-row p { margin: 12rpx 0 0; display: flex; align-items: center; gap: 10rpx; flex-wrap: wrap; }
.workout-row small { color: #ef8a00; font-weight: 900; }
.workout-row button { height: 44rpx; padding: 0 14rpx; border-radius: 10rpx; background: #0e9f53; color: #fff; font-size: 20rpx; }
.sticky-primary { position: absolute; left: 34rpx; right: 34rpx; bottom: 30rpx; }
.today-head { margin: 16rpx 0 24rpx; display: grid; grid-template-columns: 72rpx 1fr 150rpx; align-items: center; }
.today-head > view:nth-child(2) { text-align: center; }
.today-head b { display: block; color: #11151b; font-size: 44rpx; font-weight: 900; line-height: 1.15; }
.today-head text { color: #606873; font-size: 26rpx; }
.today-back { width: 54rpx; height: 54rpx; position: relative; }
.today-back::before { content: ""; position: absolute; left: 14rpx; top: 11rpx; width: 28rpx; height: 28rpx; border-left: 5rpx solid #11151b; border-bottom: 5rpx solid #11151b; transform: rotate(45deg); }
.training-helper { display: flex; align-items: center; justify-content: flex-end; gap: 8rpx; color: #0b9f50; font-size: 23rpx; font-weight: 800; white-space: nowrap; }
.training-helper i { width: 30rpx; height: 30rpx; position: relative; color: #0b9f50; }
.training-helper i::before { content: ""; position: absolute; left: 8rpx; top: 8rpx; width: 14rpx; height: 14rpx; background: currentColor; transform: rotate(45deg); }
.training-helper i::after { content: ""; position: absolute; right: 0; top: 0; width: 8rpx; height: 8rpx; border-radius: 50%; background: currentColor; }
.today-progress-card { min-height: 218rpx; padding: 28rpx 36rpx; display: grid; grid-template-columns: 1fr 1rpx 1fr; gap: 38rpx; align-items: center; border-radius: 20rpx; border: 1rpx solid #e1e5e9; background: #fff; box-shadow: 0 8rpx 22rpx rgba(20, 32, 45, .04); }
.complete-ring { justify-self: center; width: 150rpx; height: 150rpx; border-radius: 50%; padding: 12rpx; background: conic-gradient(#11a95a 0 154deg, #eef0f1 154deg 305deg, #11a95a 305deg 360deg); }
.complete-ring view { height: 100%; border-radius: 50%; background: #fff; display: flex; flex-direction: column; align-items: center; justify-content: center; }
.complete-ring p { margin: 0; display: flex; align-items: baseline; justify-content: center; line-height: 1; }
.complete-ring b { color: #0fa857; font-size: 48rpx; line-height: 1; }
.complete-ring em { margin-left: 4rpx; color: #11151b; font-style: normal; font-size: 34rpx; font-weight: 900; line-height: 1; }
.complete-ring text { display: block; margin-top: 8rpx; color: #69717b; font-size: 22rpx; line-height: 1; white-space: nowrap; }
.progress-divider { width: 1rpx; height: 132rpx; background: #e0e4e8; }
.timer-box { text-align: center; }
.timer-box i { display: inline-block; width: 54rpx; height: 54rpx; border: 6rpx solid #ff5a13; border-radius: 50%; position: relative; vertical-align: middle; margin-right: 18rpx; }
.timer-box i::before { content: ""; position: absolute; left: 21rpx; top: 12rpx; width: 5rpx; height: 18rpx; border-radius: 99rpx; background: #ff5a13; }
.timer-box i::after { content: ""; position: absolute; left: 23rpx; top: 27rpx; width: 15rpx; height: 5rpx; border-radius: 99rpx; background: #ff5a13; }
.timer-box b { color: #ff5a13; font-size: 58rpx; font-weight: 900; vertical-align: middle; line-height: 1; }
.timer-box text { display: block; margin-top: 18rpx; color: #69717b; font-size: 25rpx; }
.exercise-list { margin-top: 18rpx; display: grid; gap: 14rpx; }
.exercise-row { min-height: 104rpx; padding: 18rpx 24rpx; display: grid; grid-template-columns: 62rpx 122rpx 1fr 26rpx; gap: 18rpx; align-items: center; border-radius: 18rpx; border: 1rpx solid #e5e9ed; background: #fff; box-shadow: 0 8rpx 18rpx rgba(20, 32, 45, .04); }
.exercise-index { width: 46rpx; height: 46rpx; border-radius: 10rpx; background: #0da052; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 29rpx; font-weight: 900; }
.exercise-index.muted { background: #eceeef; color: #333941; }
.exercise-thumb { width: 96rpx; height: 66rpx; border-left: 1rpx solid #dfe4e8; background: #f5f7f6; position: relative; }
.exercise-thumb::before { content: ""; position: absolute; left: 34rpx; top: 15rpx; width: 38rpx; height: 22rpx; border-radius: 18rpx; background: #2d333a; transform: rotate(-10deg); opacity: .88; }
.exercise-thumb::after { content: ""; position: absolute; left: 45rpx; top: 7rpx; width: 18rpx; height: 18rpx; border-radius: 50%; background: #2d333a; }
.exercise-thumb.row::before { top: 24rpx; transform: rotate(0); }
.exercise-thumb.press::before { top: 20rpx; height: 30rpx; transform: rotate(90deg); }
.exercise-thumb.plank::before { left: 28rpx; top: 30rpx; width: 60rpx; height: 10rpx; transform: rotate(0); }
.exercise-row b { color: #11151b; font-size: 30rpx; font-weight: 900; display: block; }
.exercise-row text { display: block; margin-top: 10rpx; color: #69717b; font-size: 25rpx; }
.exercise-row > em { color: #252b32; font-style: normal; font-size: 42rpx; line-height: 1; }
.exercise-row.active { display: block; padding: 24rpx; border: 2rpx solid #0da052; background: #f8fffb; }
.exercise-top { display: grid; grid-template-columns: 62rpx 122rpx 1fr 86rpx 26rpx; gap: 18rpx; align-items: center; }
.exercise-top small { height: 48rpx; padding: 0 18rpx; border-radius: 12rpx; background: #e6f5ec; color: #0b9f50; font-size: 23rpx; display: flex; align-items: center; justify-content: center; white-space: nowrap; }
.exercise-top em { color: #252b32; font-style: normal; font-size: 38rpx; }
.rest-card { margin: 26rpx 24rpx 18rpx; min-height: 78rpx; padding: 0 18rpx; display: grid; grid-template-columns: 38rpx 70rpx 1fr 150rpx; gap: 14rpx; align-items: center; border-radius: 14rpx; border: 1rpx solid #d8eee2; background: #f1faf5; }
.rest-card i { width: 34rpx; height: 28rpx; border-bottom: 5rpx solid #0b9f50; border-radius: 0 0 20rpx 20rpx; position: relative; }
.rest-card i::before { content: ""; position: absolute; left: 6rpx; top: -4rpx; width: 18rpx; height: 14rpx; border: 4rpx solid #0b9f50; border-bottom: 0; border-radius: 12rpx 12rpx 0 0; }
.rest-card text { margin: 0; color: #0b9f50; font-size: 27rpx; font-weight: 900; }
.rest-card b { color: #0b9f50; font-size: 42rpx; text-align: center; }
.rest-card button { width: 150rpx; height: 46rpx; border-radius: 10rpx; border: 1rpx solid #bee6ce; color: #0b9f50; background: #fff; font-size: 22rpx; font-weight: 800; display: flex; align-items: center; justify-content: center; line-height: 1; white-space: nowrap; }
.workout-actions { display: grid; grid-template-columns: 1fr 1fr; gap: 26rpx; margin: 0 38rpx; }
.workout-actions button { height: 72rpx; border-radius: 14rpx; font-size: 28rpx; font-weight: 900; }
.workout-actions button:first-child { background: #0da052; color: #fff; }
.workout-actions button:last-child { border: 1rpx solid #0da052; color: #0da052; background: #fff; }
.end-workout { margin-top: 20rpx; width: 100%; height: 86rpx; border-radius: 14rpx; background: #0da052; color: #fff; font-size: 32rpx; font-weight: 900; }
.search { height: 74rpx; padding: 0 24rpx; display: flex; align-items: center; border-radius: 14rpx; border: 1rpx solid #e2e7eb; color: #9097a1; background: #fff; }
.library-head { margin: 22rpx 0 28rpx; display: grid; grid-template-columns: 54rpx 1fr 54rpx; align-items: center; }
.library-head > text { color: #11151b; font-size: 58rpx; font-weight: 900; line-height: 1; }
.library-back { width: 54rpx; height: 54rpx; position: relative; }
.library-back::before { content: ""; position: absolute; left: 18rpx; top: 13rpx; width: 24rpx; height: 24rpx; border-left: 6rpx solid #11151b; border-bottom: 6rpx solid #11151b; border-radius: 3rpx; transform: rotate(45deg); }
.filter-icon { width: 46rpx; height: 46rpx; position: relative; }
.filter-icon::before { content: ""; position: absolute; left: 5rpx; top: 8rpx; width: 36rpx; height: 28rpx; border: 5rpx solid #11151b; border-bottom: 0; clip-path: polygon(0 0, 100% 0, 62% 52%, 62% 100%, 38% 100%, 38% 52%); }
.library-search { height: 82rpx; padding: 0 24rpx; display: flex; align-items: center; gap: 18rpx; border-radius: 16rpx; border: 1rpx solid #e0e5e9; background: #fff; color: #a0a6ae; font-size: 30rpx; }
.library-cats { margin: 24rpx 0; width: 100%; white-space: nowrap; scrollbar-width: none; }
.library-cats ::-webkit-scrollbar { display: none; width: 0; height: 0; }
.cat-track { display: inline-flex; gap: 18rpx; padding-right: 28rpx; }
.library-cats text { min-width: 86rpx; height: 62rpx; padding: 0 26rpx; border-radius: 999rpx; border: 1rpx solid #dfe4e9; display: inline-flex; align-items: center; justify-content: center; color: #11151b; font-size: 27rpx; font-weight: 800; background: #fff; white-space: nowrap; }
.library-cats .active { background: #0da052; border-color: #0da052; color: #fff; }
.library-feature { padding: 20rpx; border-radius: 18rpx; border: 1rpx solid #e2e6ea; background: #fff; box-shadow: 0 8rpx 22rpx rgba(20,32,45,.04); }
.library-img { width: 288rpx; height: 154rpx; border-radius: 14rpx; background: #1b222a; display: block; overflow: hidden; }
.library-img::before,
.library-img::after { display: none !important; content: none !important; }
.library-img.squat { background: linear-gradient(135deg, #161b20, #2b3239); }
.library-img.bench { background: linear-gradient(135deg, #11161b, #38424a); }
.library-img.deadlift { background: linear-gradient(135deg, #20262b, #4a555d); }
.library-img.plank { background: linear-gradient(135deg, #151b20, #303940); }
.library-feature > .library-img { float: left; margin-right: 26rpx; }
.feature-main { min-height: 338rpx; }
.feature-title { min-height: 154rpx; display: flex; justify-content: space-between; align-items: flex-start; }
.feature-title b { display: block; color: #11151b; font-size: 35rpx; font-weight: 900; }
.feature-title text { display: block; margin-top: 14rpx; color: #5f6872; font-size: 25rpx; }
.feature-title em { display: inline-flex; margin-top: 22rpx; height: 40rpx; padding: 0 16rpx; align-items: center; border-radius: 8rpx; background: #e6f7ed; color: #0b9f50; font-style: normal; font-size: 22rpx; font-weight: 800; }
.feature-info { clear: both; padding-top: 26rpx; }
.feature-info p { min-height: 66rpx; margin: 0; display: grid; grid-template-columns: 62rpx 180rpx 1fr; gap: 18rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.feature-info p:last-child { border-bottom: 0; }
.feature-info i { width: 46rpx; height: 46rpx; border-radius: 50%; background: #e7f7ed; position: relative; color: #0b9f50; }
.feature-info b { color: #11151b; font-size: 26rpx; font-weight: 900; }
.feature-info text { color: #59616b; font-size: 25rpx; }
.lib-bone::before { content: ""; position: absolute; left: 14rpx; top: 19rpx; width: 20rpx; height: 6rpx; border-radius: 99rpx; background: currentColor; transform: rotate(-45deg); }
.lib-warn::before { content: ""; position: absolute; left: 12rpx; top: 9rpx; width: 22rpx; height: 22rpx; border-left: 4rpx solid currentColor; border-bottom: 4rpx solid currentColor; transform: rotate(-45deg); }
.lib-switch::before { content: ""; position: absolute; left: 9rpx; top: 13rpx; width: 26rpx; height: 5rpx; border-radius: 99rpx; background: currentColor; box-shadow: 0 14rpx 0 currentColor; }
.library-row { min-height: 128rpx; margin-top: 18rpx; padding: 16rpx 20rpx; display: grid; grid-template-columns: 288rpx 1fr 44rpx 28rpx; gap: 22rpx; align-items: center; border-radius: 18rpx; border: 1rpx solid #e2e6ea; background: #fff; box-shadow: 0 8rpx 22rpx rgba(20,32,45,.04); }
.library-row .library-img { width: 288rpx; height: 96rpx; }
.library-row b { display: block; color: #11151b; font-size: 31rpx; font-weight: 900; }
.library-row text { display: block; margin-top: 14rpx; color: #5f6872; font-size: 24rpx; }
.exercise-card { margin-top: 16rpx; min-height: 122rpx; padding: 18rpx; display: grid; grid-template-columns: 78rpx 1fr 24rpx; gap: 16rpx; align-items: center; }
.exercise-card:nth-of-type(2n) i { background: linear-gradient(135deg, #2878d8, #56b98b); }
.exercise-card b, .exercise-card text, .exercise-card p { display: block; }
.exercise-card text { margin-top: 6rpx; color: #68717c; font-size: 23rpx; }
.exercise-card p { margin: 8rpx 0 0; color: #7d8590; font-size: 20rpx; }
.week-dots { display: grid; grid-template-columns: repeat(7,1fr); gap: 10rpx; margin: 18rpx 0; }
.week-dots text { height: 58rpx; border-radius: 50%; background: #fff; border: 1rpx solid #e5eaed; display: flex; align-items: center; justify-content: center; color: #0e9f53; font-weight: 800; }
.activity-head { margin: 22rpx 0 30rpx; display: flex; align-items: center; justify-content: space-between; }
.activity-head > text { color: #11151b; font-size: 48rpx; font-weight: 900; line-height: 1; }
.activity-calendar { width: 52rpx; height: 52rpx; display: flex; align-items: center; justify-content: center; }
.activity-week { display: grid; grid-template-columns: repeat(7, 1fr); margin-bottom: 22rpx; }
.activity-week view { min-height: 124rpx; display: grid; grid-template-rows: 28rpx 34rpx 44rpx; align-items: center; text-align: center; color: #565f69; }
.activity-week text,
.activity-week b { display: block; font-size: 24rpx; font-weight: 500; }
.activity-week b { font-size: 27rpx; }
.activity-week .active { color: #16a345; font-weight: 900; }
.activity-week p { height: 44rpx; margin: 0; display: flex; align-items: center; justify-content: center; }
.activity-week i { width: 16rpx; height: 16rpx; border-radius: 50%; background: #c9ced4; display: flex; align-items: center; justify-content: center; color: #fff; font-style: normal; }
.activity-week i.done { width: 34rpx; height: 34rpx; background: #36b63c; font-size: 22rpx; font-weight: 900; }
.activity-week .active i { width: 38rpx; height: 38rpx; border: 3rpx solid #34b449; background: #fff; position: relative; }
.activity-week .active i::after { content: ""; width: 16rpx; height: 16rpx; border-radius: 50%; background: #7fd663; }
.activity-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14rpx; }
.activity-stats view { min-height: 158rpx; padding: 20rpx; border-radius: 16rpx; border: 1rpx solid #e2e6ea; background: #fff; }
.activity-stats i { width: 48rpx; height: 48rpx; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 18rpx; }
.stat-train { background: #e7f7ed; }
.stat-time { background: #e8f2ff; }
.stat-fire { background: #fff0dd; }
.stat-step { background: #e8f6e6; }
.activity-stats text { display: block; color: #333941; font-size: 23rpx; }
.activity-stats b { display: block; margin-top: 20rpx; color: #11151b; font-size: 36rpx; font-weight: 900; line-height: 1; white-space: nowrap; }
.activity-stats em { color: #37b83e; font-style: normal; }
.activity-stats small { color: #5f6872; font-size: 21rpx; font-weight: 500; }
.activity-card { margin-top: 18rpx; padding: 24rpx; border-radius: 18rpx; border: 1rpx solid #e2e6ea; background: #fff; box-shadow: 0 8rpx 22rpx rgba(20,32,45,.04); }
.activity-card-head { display: flex; align-items: center; justify-content: space-between; gap: 18rpx; }
.activity-card-head b { display: flex; align-items: center; gap: 12rpx; color: #11151b; font-size: 28rpx; font-weight: 900; }
.activity-card-head b small { color: #59616b; font-size: 22rpx; font-weight: 500; }
.activity-card-head > text { color: #59616b; font-size: 22rpx; }
.activity-card-head em { color: #11151b; font-style: normal; font-weight: 900; }
.heart-card .activity-card-head b i { width: 40rpx; height: 40rpx; border-radius: 50%; background: radial-gradient(circle, #f2414b 0 45%, #ffe7e9 46%); }
.heart-chart { height: 128px; min-height: 128px; margin-top: 12rpx; }
.echarts-chart { width: 100%; display: block; position: relative; overflow: hidden; }
.echarts-chart > div,
.echarts-chart canvas,
.echarts-chart svg { display: block; }
.load-card .activity-card-head b i { width: 34rpx; height: 34rpx; background: linear-gradient(90deg, #2f8bf2 0 22%, transparent 23% 38%, #2f8bf2 39% 61%, transparent 62% 76%, #2f8bf2 77%); }
.load-chart { height: 132px; min-height: 132px; margin-top: 10rpx; }
.activity-bottom-grid { margin-top: 18rpx; display: grid; grid-template-columns: 1.16fr .84fr; gap: 16rpx; align-items: stretch; }
.strength-card,
.device-card {
  min-height: 214rpx;
  padding: 22rpx;
  border-radius: 20rpx;
  border: 1rpx solid #e1e7e4;
  background:
    linear-gradient(180deg, rgba(246, 251, 248, .86), rgba(255,255,255,.98)),
    #fff;
  box-shadow: 0 12rpx 30rpx rgba(23, 36, 48, .06);
  position: relative;
  overflow: hidden;
}
.strength-card::before,
.device-card::before {
  content: "";
  position: absolute;
  inset: 0 0 auto;
  height: 5rpx;
  background: linear-gradient(90deg, #27b85c, rgba(39,184,92,0));
}
.strength-card .activity-card-head b i {
  width: 40rpx;
  height: 40rpx;
  border-radius: 50%;
  background: linear-gradient(135deg, #35bf57, #109f4f);
  position: relative;
}
.strength-card .activity-card-head b i::before {
  content: "";
  position: absolute;
  left: 13rpx;
  top: 9rpx;
  width: 16rpx;
  height: 21rpx;
  border: 5rpx solid #fff;
  border-top: 0;
  border-radius: 0 0 15rpx 15rpx;
  transform: rotate(-18deg);
}
.strength-card p {
  margin: 18rpx 0 0;
  min-height: 72rpx;
  display: grid;
  grid-template-columns: 66rpx 1fr 112rpx;
  gap: 16rpx;
  align-items: center;
  padding: 10rpx 0;
  border-bottom: 1rpx solid #edf1ee;
}
.strength-card p:last-child { border-bottom: 0; }
.strength-card image { width: 62rpx; height: 54rpx; border-radius: 12rpx; box-shadow: 0 6rpx 14rpx rgba(17, 24, 39, .10); }
.strength-card p view { min-width: 0; }
.strength-card p b { display: block; color: #11151b; font-size: 34rpx; font-weight: 900; white-space: nowrap; line-height: 1; }
.strength-card p small { color: #69717b; font-size: 19rpx; font-weight: 500; }
.strength-card p text { display: block; margin-top: 8rpx; color: #79828c; font-size: 21rpx; font-weight: 700; }
.strength-card p em {
  justify-self: end;
  padding: 7rpx 10rpx;
  border-radius: 999rpx;
  background: #e9f8ef;
  color: #0cae52;
  font-style: normal;
  font-size: 20rpx;
  font-weight: 900;
  white-space: nowrap;
}
.device-card {
  display: flex;
  flex-direction: column;
}
.device-card::after {
  content: "";
  position: absolute;
  right: -28rpx;
  top: -34rpx;
  width: 112rpx;
  height: 112rpx;
  border-radius: 50%;
  background: rgba(242, 65, 75, .07);
}
.device-head { display: grid; grid-template-columns: 58rpx 1fr; gap: 14rpx; align-items: center; position: relative; z-index: 1; }
.health-icon {
  width: 56rpx;
  height: 56rpx;
  border-radius: 18rpx;
  background: linear-gradient(135deg, #fff4f5, #f1f3f6);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: inset 0 0 0 1rpx rgba(242, 65, 75, .06);
}
.device-head b { color: #11151b; font-size: 27rpx; font-weight: 900; }
.device-body { margin-top: 20rpx; padding: 18rpx; border-radius: 16rpx; background: rgba(255,255,255,.72); border: 1rpx solid #eef1f3; position: relative; z-index: 1; }
.device-body > text { color: #11151b; font-size: 24rpx; font-weight: 800; }
.device-card p { margin: 14rpx 0 0; color: #11151b; font-size: 23rpx; }
.device-card p i { display: inline-flex; width: 26rpx; height: 26rpx; margin-right: 8rpx; border-radius: 50%; background: #0fb456; color: #fff; align-items: center; justify-content: center; font-style: normal; font-size: 18rpx; }
.device-card small { display: block; margin-top: 12rpx; color: #8a929b; font-size: 22rpx; }
.device-arrow { position: absolute; right: 18rpx; bottom: 18rpx; z-index: 1; }
.metric-grid { display: grid; grid-template-columns: repeat(2,1fr); gap: 14rpx; }
.metric-grid view { min-height: 108rpx; padding: 18rpx; border-radius: 16rpx; background: #fff; border: 1rpx solid #e8ecef; }
.metric-grid b { display: block; font-size: 32rpx; }
.metric-grid text { display: block; margin-top: 8rpx; color: #6d7580; font-size: 22rpx; }
.chart-card b { display: block; }
.line-chart { height: 130rpx; margin-top: 18rpx; border-radius: 14rpx; background: linear-gradient(160deg, transparent 45%, rgba(16,169,88,.22) 46% 52%, transparent 53%), repeating-linear-gradient(0deg, #f7faf8, #f7faf8 28rpx, #edf1ef 29rpx); }
.bar-chart { height: 138rpx; margin-top: 18rpx; display: flex; align-items: flex-end; gap: 26rpx; }
.strength p, .review-stats p, .goal-card p { display: flex; justify-content: space-between; margin: 18rpx 0 0; color: #5f6872; }
.strength em, .review-stats em, .goal-card em { color: #0e9f53; font-style: normal; font-weight: 900; }
.sync { margin-top: 18rpx; padding: 18rpx 22rpx; border-radius: 14rpx; background: #eef6ff; color: #2369b4; font-weight: 800; font-size: 23rpx; }
.chat { margin-top: 22rpx; display: grid; gap: 18rpx; }
.user-msg { justify-self: end; max-width: 78%; padding: 18rpx 22rpx; border-radius: 18rpx 18rpx 4rpx 18rpx; background: #0e9f53; color: #fff; font-size: 25rpx; }
.ai-msg { max-width: 86%; padding: 20rpx; border-radius: 18rpx 18rpx 18rpx 4rpx; background: #fff; border: 1rpx solid #e8ecef; }
.ai-msg b, .ai-msg text { display: block; }
.ai-msg text { margin-top: 12rpx; color: #4d5660; font-size: 24rpx; }
.input-bar { position: absolute; left: 34rpx; right: 34rpx; bottom: 150rpx; height: 76rpx; border-radius: 18rpx; background: #fff; border: 1rpx solid #dfe6e9; display: flex; justify-content: space-between; align-items: center; padding: 0 20rpx; color: #9198a2; }
.coach-head { margin-top: 18rpx; height: 72rpx; display: grid; grid-template-columns: 64rpx 1fr 64rpx; align-items: center; }
.coach-head > text { text-align: center; color: #11151b; font-size: 48rpx; font-weight: 900; line-height: 1; }
.coach-back { width: 42rpx; height: 42rpx; position: relative; }
.coach-back::before { content: ""; position: absolute; left: 12rpx; top: 6rpx; width: 25rpx; height: 25rpx; border-left: 6rpx solid #11151b; border-bottom: 6rpx solid #11151b; transform: rotate(45deg); border-radius: 3rpx; }
.coach-more { justify-self: end; width: 46rpx; height: 46rpx; border: 4rpx solid #11151b; border-radius: 50%; position: relative; }
.coach-more i,
.coach-more::before,
.coach-more::after { content: ""; position: absolute; top: 18rpx; width: 5rpx; height: 5rpx; border-radius: 50%; background: #11151b; }
.coach-more i { left: 10rpx; }
.coach-more::before { left: 19rpx; }
.coach-more::after { left: 28rpx; }
.coach-context { margin-top: 28rpx; display: grid; grid-template-columns: repeat(3, 1fr); gap: 16rpx; }
.coach-context view { min-width: 0; height: 88rpx; padding: 0 16rpx; border-radius: 18rpx; border: 1rpx solid #e0e5e9; background: #fff; display: flex; align-items: center; justify-content: center; gap: 12rpx; color: #15191f; font-size: 25rpx; font-weight: 800; white-space: nowrap; }
.coach-context i,
.coach-suggestions i { position: relative; width: 34rpx; height: 34rpx; color: #0b9f50; flex: 0 0 auto; }
.coach-chat { margin-top: 38rpx; display: grid; gap: 30rpx; }
.coach-user-row { display: grid; grid-template-columns: 1fr 76rpx; gap: 18rpx; align-items: start; }
.coach-user-bubble { justify-self: end; max-width: 548rpx; min-height: 118rpx; padding: 28rpx 28rpx 18rpx; border-radius: 22rpx; border: 1rpx solid #e2e6ea; background: #fff; }
.coach-user-bubble b { display: block; color: #11151b; font-size: 31rpx; font-weight: 900; line-height: 1.35; }
.coach-user-bubble text { margin-top: 18rpx; display: flex; justify-content: flex-end; align-items: center; gap: 12rpx; color: #9aa1aa; font-size: 23rpx; }
.coach-user-bubble text i { width: 34rpx; height: 18rpx; position: relative; transform: none; }
.coach-user-bubble text i::before,
.coach-user-bubble text i::after {
  content: "";
  position: absolute;
  width: 15rpx;
  height: 8rpx;
  border-left: 4rpx solid #0ba45a;
  border-bottom: 4rpx solid #0ba45a;
  transform: rotate(-45deg);
}
.coach-user-bubble text i::before { left: 1rpx; top: 4rpx; }
.coach-user-bubble text i::after { left: 14rpx; top: 4rpx; }
.coach-user-avatar { width: 72rpx; height: 72rpx; border-radius: 50%; background: #d7f0e3; position: relative; }
.coach-user-avatar::before { content: ""; position: absolute; left: 26rpx; top: 17rpx; width: 20rpx; height: 20rpx; border-radius: 50%; background: #68b592; }
.coach-user-avatar::after { content: ""; position: absolute; left: 17rpx; bottom: 12rpx; width: 38rpx; height: 25rpx; border-radius: 38rpx 38rpx 12rpx 12rpx; background: #68b592; }
.coach-ai-row { display: grid; grid-template-columns: 82rpx 1fr; gap: 22rpx; align-items: start; }
.coach-bot-avatar { width: 74rpx; height: 74rpx; border-radius: 50%; background: #d8f2e1; display: flex; align-items: center; justify-content: center; }
.coach-bot-avatar i { position: relative; width: 46rpx; height: 31rpx; border-radius: 12rpx; background: #11151b; }
.coach-bot-avatar i::before { content: ""; position: absolute; left: 8rpx; top: 10rpx; width: 8rpx; height: 8rpx; border-radius: 50%; background: #27d47a; box-shadow: 22rpx 0 0 #27d47a; }
.coach-bot-avatar i::after { content: ""; position: absolute; left: 20rpx; top: -12rpx; width: 5rpx; height: 12rpx; background: #fff; border-radius: 99rpx; box-shadow: 0 -4rpx 0 #fff; }
.coach-ai-bubble { max-width: 590rpx; padding: 30rpx 34rpx; border-radius: 20rpx; background: #e7f8eb; color: #11151b; }
.coach-ai-bubble > text { display: block; font-size: 28rpx; font-weight: 800; line-height: 1.65; }
.coach-ai-bubble p { margin: 24rpx 0 0; display: grid; grid-template-columns: 18rpx 1fr; gap: 18rpx; align-items: start; color: #11151b; font-size: 27rpx; line-height: 1.65; }
.coach-ai-bubble p i { margin-top: 14rpx; width: 12rpx; height: 12rpx; border-radius: 50%; background: #18a75b; }
.coach-ai-bubble p b { color: #0b9f50; font-weight: 900; }
.coach-ai-time { margin: 12rpx 0 0 6rpx; color: #9aa1aa; font-size: 22rpx; }
.coach-suggestions { margin-top: 34rpx; display: grid; grid-template-columns: repeat(3, 1fr); gap: 18rpx; }
.coach-suggestions view { min-width: 0; height: 76rpx; border-radius: 16rpx; border: 1rpx solid #e0e5e9; background: #fff; display: flex; align-items: center; justify-content: center; gap: 12rpx; color: #1d232b; font-size: 24rpx; font-weight: 800; white-space: nowrap; }
.coach-input { position: absolute; left: 34rpx; right: 34rpx; bottom: 142rpx; height: 94rpx; padding: 0 14rpx; border-radius: 28rpx; border: 1rpx solid #dfe4e8; background: #fff; display: grid; grid-template-columns: 66rpx 1fr 66rpx; gap: 18rpx; align-items: center; }
.coach-input text { color: #a0a5ad; font-size: 31rpx; letter-spacing: 0; }
.voice-icon { width: 58rpx; height: 58rpx; border-radius: 50%; border: 3rpx solid #15191f; display: flex; align-items: center; justify-content: center; color: #0b9f50; }
.voice-icon i { position: relative; width: 27rpx; height: 27rpx; }
.voice-icon i::before { content: ""; position: absolute; left: 11rpx; top: 3rpx; width: 7rpx; height: 20rpx; border-radius: 99rpx; background: currentColor; box-shadow: -9rpx 5rpx 0 -2rpx currentColor, 9rpx 5rpx 0 -2rpx currentColor; }
.send-icon { width: 58rpx; height: 58rpx; border-radius: 50%; background: #0b9f50; position: relative; justify-self: end; }
.send-icon::before {
  content: "";
  position: absolute;
  left: 50%;
  top: 50%;
  width: 0;
  height: 0;
  border-left: 28rpx solid #fff;
  border-top: 15rpx solid transparent;
  border-bottom: 15rpx solid transparent;
  transform: translate(-45%, -50%) rotate(-35deg);
}
.send-icon::after {
  content: "";
  position: absolute;
  left: 50%;
  top: 50%;
  width: 17rpx;
  height: 4rpx;
  border-radius: 99rpx;
  background: #0b9f50;
  transform: translate(-34%, -34%) rotate(-35deg);
}
.coach-target::before { content: ""; position: absolute; inset: 5rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.coach-target::after { content: ""; position: absolute; left: 14rpx; top: 14rpx; width: 6rpx; height: 6rpx; border-radius: 50%; background: currentColor; box-shadow: 10rpx -12rpx 0 -1rpx currentColor; }
.coach-fire::before { content: ""; position: absolute; left: 10rpx; top: 3rpx; width: 16rpx; height: 27rpx; border-radius: 16rpx 16rpx 16rpx 3rpx; background: currentColor; transform: rotate(35deg); }
.coach-dumbbell::before { content: ""; position: absolute; left: 5rpx; top: 15rpx; width: 24rpx; height: 5rpx; border-radius: 99rpx; background: currentColor; }
.coach-dumbbell::after { content: ""; position: absolute; left: 1rpx; top: 9rpx; width: 8rpx; height: 18rpx; border-radius: 4rpx; background: currentColor; box-shadow: 25rpx 0 0 currentColor; }
.coach-weight::before { content: ""; position: absolute; left: 6rpx; top: 6rpx; width: 22rpx; height: 22rpx; border: 4rpx solid currentColor; border-radius: 6rpx; }
.coach-weight::after { content: ""; position: absolute; left: 14rpx; top: 13rpx; width: 8rpx; height: 8rpx; border-top: 4rpx solid currentColor; border-left: 4rpx solid currentColor; transform: rotate(45deg); }
.coach-run::before { content: ""; position: absolute; left: 12rpx; top: 3rpx; width: 9rpx; height: 9rpx; border-radius: 50%; background: currentColor; }
.coach-run::after { content: ""; position: absolute; left: 6rpx; top: 15rpx; width: 22rpx; height: 15rpx; border-left: 5rpx solid currentColor; border-bottom: 5rpx solid currentColor; transform: skew(-24deg) rotate(-8deg); }
.coach-review-entry { margin: 18rpx 0 14rpx; min-height: 82rpx; padding: 18rpx 20rpx; display: grid; grid-template-columns: 156rpx 1fr 28rpx; gap: 12rpx; align-items: center; border-radius: 18rpx; border: 1rpx solid #b9e6ca; background: #f2fbf5; }
.coach-review-entry view { display: flex; align-items: center; gap: 10rpx; color: #0c9f50; font-size: 26rpx; font-weight: 900; white-space: nowrap; }
.coach-review-entry i { width: 34rpx; height: 34rpx; border-radius: 50%; background: conic-gradient(#0c9f50 0 82%, #d6efdf 0); display: block; position: relative; }
.coach-review-entry i::after { content: ""; position: absolute; inset: 8rpx; border-radius: 50%; background: #f2fbf5; }
.coach-review-entry b { color: #4b5563; font-size: 22rpx; font-weight: 600; line-height: 1.25; }
.score-card { margin-top: 18rpx; background: #0e9f53; color: #fff; }
.score-card b { font-size: 48rpx; }
.review-stats p:first-child { margin-top: 0; }
.warn-bg { background: #fff8ec; border-color: #f3dfbd; }
.trends { margin-top: 18rpx; grid-template-columns: repeat(3,1fr); }
.review-page-head { height: 92rpx; display: grid; grid-template-columns: 72rpx 1fr 72rpx; align-items: center; margin: 12rpx 0 12rpx; }
.review-page-head > text { text-align: center; color: #05070a; font-size: 45rpx; font-weight: 900; letter-spacing: 0; }
.review-back { width: 54rpx; height: 54rpx; position: relative; }
.review-back::before { content: ""; position: absolute; left: 17rpx; top: 13rpx; width: 24rpx; height: 24rpx; border-left: 6rpx solid #05070a; border-bottom: 6rpx solid #05070a; transform: rotate(45deg); border-radius: 3rpx; }
.review-calendar { justify-self: end; width: 56rpx; height: 56rpx; display: flex; align-items: center; justify-content: center; }
.review-tabs { height: 82rpx; display: grid; grid-template-columns: 1fr 1fr; align-items: end; border-bottom: 1rpx solid #e1e5e9; margin-bottom: 24rpx; }
.review-tabs view { height: 70rpx; display: flex; align-items: center; justify-content: center; color: #20252d; font-size: 28rpx; position: relative; }
.review-tabs .active { color: #078c43; font-weight: 900; }
.review-tabs .active::after { content: ""; position: absolute; bottom: -1rpx; left: 50%; width: 46rpx; height: 6rpx; border-radius: 99rpx; background: #0aa04e; transform: translateX(-50%); }
.review-date-row { height: 58rpx; display: flex; align-items: center; justify-content: space-between; margin-bottom: 20rpx; }
.review-date-row > view { display: flex; align-items: center; gap: 12rpx; min-width: 0; color: #2f3540; }
.review-date-row text { font-size: 30rpx; white-space: nowrap; }
.review-date-row b { font-size: 29rpx; font-weight: 500; white-space: nowrap; }
.review-date-row button { margin: 0; padding: 0 18rpx; width: 168rpx; height: 54rpx; border-radius: 999rpx; border: 1rpx solid #8fd6ad; background: #fff; color: #0c9f50; display: flex; align-items: center; justify-content: center; gap: 8rpx; font-size: 25rpx; font-weight: 700; line-height: 1; }
.review-summary-card { min-height: 276rpx; padding: 22rpx; display: grid; grid-template-columns: 214rpx 1fr; gap: 16rpx; border: 1rpx solid #dfe4e7; border-radius: 24rpx; background: linear-gradient(90deg, rgba(242, 250, 245, .94), #fff 36%); box-shadow: 0 8rpx 22rpx rgba(23, 36, 48, .04); }
.review-score-wrap { position: relative; width: 196rpx; height: 196rpx; align-self: center; justify-self: center; }
.review-score-chart { width: 196rpx; height: 196rpx; }
.review-score-text { position: absolute; inset: 0; display: grid; grid-template-rows: auto auto auto; align-content: center; justify-items: center; text-align: center; color: #11151b; }
.review-score-text text { font-size: 21rpx; line-height: 1; }
.review-score-text b { color: #079c49; font-size: 62rpx; font-weight: 900; line-height: .92; margin-top: 10rpx; }
.review-score-text em { color: #0b8f46; font-size: 23rpx; font-style: normal; line-height: 1; transform: translate(54rpx, -30rpx); }
.review-score-text small { color: #0b8f46; font-size: 22rpx; font-weight: 800; line-height: 1; margin-top: -12rpx; }
.review-goals { display: flex; flex-direction: column; justify-content: center; gap: 24rpx; min-width: 0; }
.review-goal-row { display: grid; grid-template-columns: 56rpx 1fr auto 24rpx; gap: 12rpx; align-items: center; min-width: 0; }
.review-icon { width: 50rpx; height: 50rpx; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.review-icon.diet, .review-icon.train { background: #e6f7ec; }
.review-icon.water { background: #e8f1ff; }
.review-iconfont { width: 32rpx; height: 32rpx; display: block; position: relative; color: #0c9f50; }
.review-iconfont::before,
.review-iconfont::after { content: ""; position: absolute; box-sizing: border-box; display: block; }
.review-icon-diet::before { left: 4rpx; top: 2rpx; width: 4rpx; height: 27rpx; border-radius: 99rpx; background: currentColor; box-shadow: 7rpx 0 0 currentColor; }
.review-icon-diet::after { left: 18rpx; top: 2rpx; width: 9rpx; height: 27rpx; border-radius: 99rpx 99rpx 4rpx 4rpx; border: 4rpx solid currentColor; border-top: 0; border-right-width: 3rpx; }
.review-icon-train::before { left: 4rpx; top: 13rpx; width: 24rpx; height: 6rpx; border-radius: 99rpx; background: currentColor; }
.review-icon-train::after { left: 0; top: 7rpx; width: 8rpx; height: 18rpx; border-radius: 4rpx; background: currentColor; box-shadow: 24rpx 0 0 currentColor, 7rpx 3rpx 0 -2rpx currentColor, 17rpx 3rpx 0 -2rpx currentColor; }
.review-icon-water { color: #2878f0; }
.review-icon-water::before { left: 7rpx; top: 1rpx; width: 18rpx; height: 27rpx; border-radius: 55% 55% 58% 58%; background: currentColor; transform: rotate(45deg); }
.review-icon-water::after { left: 10rpx; top: 9rpx; width: 6rpx; height: 11rpx; border-radius: 99rpx; background: rgba(255, 255, 255, .42); transform: rotate(24deg); }
.review-goal-row b { display: block; color: #11151b; font-size: 29rpx; font-weight: 800; }
.review-goal-row p { margin: 14rpx 0 0; height: 12rpx; border-radius: 99rpx; background: #dfe4e7; overflow: hidden; }
.review-goal-row p em { display: block; height: 100%; border-radius: inherit; background: #0aa04e; }
.review-goal-row p.blue em { background: #2878f0; }
.review-goal-row strong { color: #079c49; font-size: 28rpx; font-weight: 800; white-space: nowrap; }
.review-goal-row strong span { color: #2878f0; }
.review-tip-card { min-height: 126rpx; margin-top: 22rpx; padding: 24rpx; display: grid; grid-template-columns: 78rpx 1fr 30rpx; gap: 18rpx; align-items: center; border-radius: 22rpx; background: #fff; }
.review-tip-card.good { border: 1rpx solid #a9e0bd; }
.review-tip-card.adjust { border: 1rpx solid #f3c78e; }
.review-tip-card > i { width: 66rpx; height: 66rpx; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.review-tip-card.good > i { background: linear-gradient(135deg, #1ab957, #059643); }
.review-tip-card.adjust > i { background: linear-gradient(135deg, #ff9b1f, #f17900); }
.review-tip-icon { width: 40rpx; height: 40rpx; display: block; position: relative; color: #fff; }
.review-tip-icon::before,
.review-tip-icon::after { content: ""; position: absolute; box-sizing: border-box; display: block; }
.review-tip-good::before { left: 6rpx; top: 17rpx; width: 9rpx; height: 18rpx; border-radius: 4rpx; background: currentColor; }
.review-tip-good::after { left: 16rpx; top: 5rpx; width: 18rpx; height: 28rpx; border-radius: 7rpx 8rpx 5rpx 5rpx; background: currentColor; box-shadow: 13rpx 10rpx 0 -8rpx currentColor; transform: skew(-7deg); }
.review-tip-adjust::before { left: 4rpx; bottom: 5rpx; width: 6rpx; height: 13rpx; border-radius: 3rpx 3rpx 0 0; background: currentColor; box-shadow: 12rpx -7rpx 0 0 currentColor, 24rpx -14rpx 0 0 currentColor; }
.review-tip-adjust::after { left: 6rpx; top: 5rpx; width: 26rpx; height: 18rpx; border-top: 5rpx solid currentColor; border-right: 5rpx solid currentColor; transform: rotate(-35deg); }
.review-tip-card b, .review-tip-card text { display: block; }
.review-tip-card b { color: #0d1117; font-size: 31rpx; font-weight: 900; }
.review-tip-card text { margin-top: 12rpx; color: #242a33; font-size: 25rpx; line-height: 1.35; }
.review-trend-head { margin: 28rpx 0 14rpx; display: flex; align-items: center; justify-content: space-between; }
.review-trend-head b { color: #0d1117; font-size: 32rpx; font-weight: 900; }
.review-trend-head text { color: #6b7280; font-size: 25rpx; }
.review-trend-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16rpx; }
.review-trend-card { min-height: 304rpx; padding: 20rpx 14rpx 12rpx; border: 1rpx solid #e1e5e9; border-radius: 18rpx; background: #fff; overflow: hidden; }
.trend-title { display: flex; align-items: center; gap: 12rpx; min-width: 0; }
.trend-title i { width: 42rpx; height: 42rpx; border-radius: 50%; display: flex; align-items: center; justify-content: center; flex: 0 0 auto; }
.review-trend-card.weight .trend-title i { background: #19a957; }
.review-trend-card.train .trend-title i { background: #2878f0; }
.review-trend-card.diet .trend-title i { background: #ff820f; }
.trend-icon { width: 26rpx; height: 26rpx; display: block; position: relative; color: #fff; }
.trend-icon::before,
.trend-icon::after { content: ""; position: absolute; box-sizing: border-box; display: block; }
.trend-icon-weight::before { left: 2rpx; top: 4rpx; width: 22rpx; height: 20rpx; border-radius: 6rpx; border: 4rpx solid currentColor; }
.trend-icon-weight::after { left: 9rpx; top: 9rpx; width: 8rpx; height: 8rpx; border-top: 4rpx solid currentColor; border-left: 4rpx solid currentColor; transform: rotate(45deg); }
.trend-icon-train::before { left: 2rpx; top: 11rpx; width: 22rpx; height: 5rpx; border-radius: 99rpx; background: currentColor; }
.trend-icon-train::after { left: -1rpx; top: 6rpx; width: 7rpx; height: 16rpx; border-radius: 3rpx; background: currentColor; box-shadow: 21rpx 0 0 currentColor, 7rpx 3rpx 0 -2rpx currentColor, 14rpx 3rpx 0 -2rpx currentColor; }
.trend-icon-diet::before { left: 3rpx; top: 2rpx; width: 4rpx; height: 22rpx; border-radius: 99rpx; background: currentColor; box-shadow: 6rpx 0 0 currentColor; }
.trend-icon-diet::after { left: 16rpx; top: 2rpx; width: 8rpx; height: 22rpx; border-radius: 99rpx 99rpx 4rpx 4rpx; border: 4rpx solid currentColor; border-top: 0; border-right-width: 3rpx; }
.trend-title text { color: #11151b; font-size: 23rpx; font-weight: 800; white-space: nowrap; }
.review-trend-card > b { display: block; margin-top: 12rpx; color: #0aa04e; font-size: 36rpx; font-weight: 900; line-height: 1; }
.review-trend-card.train > b { color: #2878f0; }
.review-trend-card.diet > b { color: #ff820f; }
.review-trend-card small { font-size: 22rpx; font-weight: 500; }
.review-trend-card p { margin: 10rpx 0 0; color: #5f6872; font-size: 20rpx; }
.review-trend-card em { color: #0aa04e; font-style: normal; font-weight: 900; }
.review-trend-card.diet em { color: #ff820f; }
.review-mini-chart { width: 100%; height: 136rpx; margin-top: 10rpx; }
.review-train-chart,
.review-diet-chart { width: 92%; margin-left: auto; margin-right: auto; }
.review-plan-button { margin: 22rpx 0 16rpx; padding: 0; width: 100%; height: 84rpx; border-radius: 20rpx; background: linear-gradient(180deg, #05a14a, #008d3e); color: #fff; display: flex; align-items: center; justify-content: center; gap: 18rpx; font-size: 32rpx; font-weight: 900; line-height: 1; }
.review-foot-note { display: flex; align-items: center; justify-content: center; gap: 10rpx; color: #8b929b; font-size: 23rpx; }
.profile-head { display: flex; gap: 18rpx; align-items: center; margin: 24rpx 0; }
.profile-head b, .profile-head text { display: block; }
.profile-head b { font-size: 34rpx; }
.profile-head text { margin-top: 6rpx; color: #0e9f53; font-weight: 800; font-size: 23rpx; }
.menu-list { margin-top: 18rpx; border-radius: 18rpx; overflow: hidden; background: #fff; border: 1rpx solid #e8ecef; }
.menu-list view { height: 80rpx; padding: 0 22rpx; display: flex; justify-content: space-between; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.menu-list view:last-child { border-bottom: 0; }
.profile-top { margin: 22rpx 0 30rpx; display: flex; align-items: center; justify-content: space-between; }
.profile-top > text { color: #11151b; font-size: 58rpx; font-weight: 900; line-height: 1; }
.profile-bell { width: 54rpx; height: 54rpx; position: relative; color: #11151b; }
.profile-bell i { position: absolute; left: 13rpx; top: 10rpx; width: 28rpx; height: 28rpx; border: 4rpx solid currentColor; border-bottom: 0; border-radius: 17rpx 17rpx 8rpx 8rpx; }
.profile-bell::before { content: ""; position: absolute; left: 10rpx; top: 38rpx; width: 34rpx; height: 4rpx; border-radius: 99rpx; background: currentColor; }
.profile-bell::after { content: ""; position: absolute; left: 23rpx; top: 44rpx; width: 9rpx; height: 7rpx; border-radius: 50%; background: currentColor; }
.profile-user { min-height: 142rpx; display: grid; grid-template-columns: 116rpx 1fr 34rpx; gap: 26rpx; align-items: center; margin-bottom: 26rpx; }
.profile-avatar { width: 116rpx; height: 116rpx; border-radius: 50%; background: radial-gradient(circle at 50% 38%, #c2c6cc 0 17%, transparent 18%), radial-gradient(ellipse at 50% 86%, #c2c6cc 0 40%, transparent 41%), linear-gradient(145deg, #f1f2f5, #dadde3); border: 1rpx solid #e1e4e8; }
.profile-info view { display: flex; align-items: center; gap: 16rpx; }
.profile-info b { color: #11151b; font-size: 38rpx; font-weight: 900; }
.profile-info em { height: 40rpx; padding: 0 14rpx; display: flex; align-items: center; gap: 8rpx; border: 1rpx solid #99d9ae; border-radius: 999rpx; background: #f0fbf3; color: #0b9f50; font-size: 23rpx; font-style: normal; font-weight: 800; }
.profile-info em i { width: 20rpx; height: 16rpx; background: #0b9f50; clip-path: polygon(0 100%, 100% 100%, 85% 30%, 63% 58%, 50% 0, 36% 58%, 14% 30%); }
.profile-info > text { display: block; margin-top: 14rpx; color: #747b85; font-size: 24rpx; }
.profile-arrow { color: #7f8790; font-size: 46rpx; line-height: 1; text-align: right; }
.profile-card { margin-top: 18rpx; padding: 24rpx 28rpx; border-radius: 18rpx; border: 1rpx solid #dfe4e9; background: #fff; box-shadow: 0 8rpx 22rpx rgba(20, 32, 45, .04); }
.profile-card-head { display: flex; align-items: center; justify-content: space-between; gap: 18rpx; }
.profile-card-head b { display: flex; align-items: center; gap: 12rpx; color: #11151b; font-size: 28rpx; font-weight: 900; }
.profile-card-head text { color: #747b85; font-size: 23rpx; white-space: nowrap; }
.profile-metrics,
.goal-metrics { margin-top: 28rpx; display: grid; grid-template-columns: 1fr 1.12fr 1fr; }
.profile-metrics view,
.goal-metrics view { min-width: 0; padding: 0 16rpx; border-right: 1rpx solid #e5e9ed; }
.profile-metrics view:last-child,
.goal-metrics view:last-child { border-right: 0; }
.profile-icon { position: relative; display: inline-block; width: 42rpx; height: 42rpx; border-radius: 50%; background: #e7f7ed; color: #0b9f50; vertical-align: middle; margin-right: 12rpx; }
.profile-metrics text,
.goal-metrics text { color: #5e6670; font-size: 24rpx; vertical-align: middle; }
.profile-metrics b,
.goal-metrics b { display: block; margin-top: 16rpx; color: #11151b; font-size: 44rpx; font-weight: 900; line-height: 1; }
.goal-metrics view:nth-child(2) b { font-size: 35rpx; white-space: nowrap; letter-spacing: 0; }
.goal-metrics view:nth-child(2) text,
.goal-metrics view:nth-child(2) > small { white-space: nowrap; }
.profile-metrics small,
.goal-metrics small { margin-left: 6rpx; color: #626a74; font-size: 24rpx; font-weight: 500; }
.goal-metrics > view > small { display: block; margin: 14rpx 0 0; color: #7a828b; font-size: 22rpx; }
.goal-metrics p { margin: 18rpx 0 0; height: 8rpx; border-radius: 99rpx; background: #e6eaee; overflow: hidden; }
.goal-metrics p em { display: block; height: 100%; border-radius: inherit; background: #35b756; }
.goal-mark { position: relative; width: 34rpx; height: 34rpx; border: 4rpx solid #0b9f50; border-radius: 50%; }
.goal-mark::before { content: ""; position: absolute; left: 10rpx; top: 10rpx; width: 6rpx; height: 6rpx; border-radius: 50%; background: #0b9f50; }
.goal-mark::after { content: ""; position: absolute; right: -8rpx; top: -7rpx; width: 13rpx; height: 13rpx; border-top: 4rpx solid #0b9f50; border-right: 4rpx solid #0b9f50; }
.profile-menu { margin-top: 20rpx; border-radius: 18rpx; border: 1rpx solid #dfe4e9; background: #fff; overflow: hidden; }
.profile-menu view { height: 82rpx; padding: 0 28rpx; display: grid; grid-template-columns: 42rpx 1fr auto 24rpx; gap: 22rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.profile-menu view:last-child { border-bottom: 0; }
.profile-menu i { position: relative; width: 34rpx; height: 34rpx; color: #11151b; }
.profile-menu text { color: #11151b; font-size: 27rpx; font-weight: 800; }
.profile-menu small { color: #747b85; font-size: 22rpx; white-space: nowrap; }
.profile-menu em { color: #7f8790; font-style: normal; font-size: 40rpx; line-height: 1; }
.body-form-grid { margin-top: 22rpx; display: grid; grid-template-columns: repeat(2, 1fr); gap: 16rpx; }
.body-form-grid view { min-width: 0; padding: 18rpx 18rpx 16rpx; border: 1rpx solid #e1e6eb; border-radius: 16rpx; background: #fbfcfd; }
.body-form-grid text { display: block; color: #68717c; font-size: 22rpx; font-weight: 700; }
.body-form-grid input { margin-top: 10rpx; height: 42rpx; color: #11151b; font-size: 30rpx; font-weight: 900; line-height: 42rpx; }
.body-note { box-sizing: border-box; margin-top: 16rpx; width: 100%; height: 104rpx; padding: 18rpx; border: 1rpx solid #e1e6eb; border-radius: 16rpx; background: #fbfcfd; color: #11151b; font-size: 25rpx; line-height: 1.45; }
.body-save-button { margin: 18rpx 0 0; padding: 0; width: 100%; height: 78rpx; border-radius: 16rpx; background: linear-gradient(180deg, #13aa56, #079845); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 29rpx; font-weight: 900; line-height: 1; }
.body-save-button[disabled] { opacity: .68; }
.body-history { margin-top: 22rpx; border-top: 1rpx solid #edf0f2; padding-top: 16rpx; }
.body-history-title { color: #11151b; font-size: 25rpx; font-weight: 900; }
.body-history-row { min-height: 58rpx; display: grid; grid-template-columns: 1.4fr .8fr .7fr .9fr; gap: 12rpx; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.body-history-row:last-child { border-bottom: 0; }
.body-history-row text { color: #6b7480; font-size: 22rpx; white-space: nowrap; }
.body-history-row b { color: #11151b; font-size: 23rpx; font-weight: 800; white-space: nowrap; }
.profile-icon::before,
.profile-icon::after,
.profile-menu i::before,
.profile-menu i::after { content: ""; position: absolute; box-sizing: border-box; }
.weight::before { left: 11rpx; top: 10rpx; width: 20rpx; height: 20rpx; border: 4rpx solid currentColor; border-radius: 5rpx; }
.weight::after { left: 17rpx; top: 15rpx; width: 8rpx; height: 8rpx; border-top: 3rpx solid currentColor; border-left: 3rpx solid currentColor; transform: rotate(45deg); }
.fat::before { left: 10rpx; top: 10rpx; width: 22rpx; height: 22rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.fat::after { left: 15rpx; top: 23rpx; width: 18rpx; height: 4rpx; border-radius: 99rpx; background: currentColor; transform: rotate(-45deg); }
.bmi::before { left: 15rpx; top: 8rpx; width: 12rpx; height: 12rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.bmi::after { left: 10rpx; top: 25rpx; width: 22rpx; height: 11rpx; border: 4rpx solid currentColor; border-top: 0; border-radius: 0 0 18rpx 18rpx; }
.target-weight::before { left: 10rpx; top: 13rpx; width: 22rpx; height: 20rpx; border: 4rpx solid currentColor; border-radius: 5rpx; }
.target-weight::after { left: 16rpx; top: 8rpx; width: 10rpx; height: 9rpx; border: 4rpx solid currentColor; border-bottom: 0; border-radius: 8rpx 8rpx 0 0; }
.calendar::before { left: 9rpx; top: 10rpx; width: 24rpx; height: 22rpx; border: 4rpx solid currentColor; border-radius: 5rpx; }
.calendar::after { left: 9rpx; top: 18rpx; width: 24rpx; height: 4rpx; background: currentColor; }
.train::before { left: 7rpx; top: 19rpx; width: 28rpx; height: 5rpx; border-radius: 99rpx; background: currentColor; }
.train::after { left: 3rpx; top: 13rpx; width: 8rpx; height: 17rpx; border-radius: 4rpx; background: currentColor; box-shadow: 28rpx 0 0 currentColor; }
.menu-body::before { left: 11rpx; top: 2rpx; width: 12rpx; height: 12rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.menu-body::after { left: 6rpx; top: 20rpx; width: 22rpx; height: 12rpx; border: 4rpx solid currentColor; border-top: 0; border-radius: 0 0 18rpx 18rpx; }
.menu-target::before { inset: 3rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.menu-target::after { left: 14rpx; top: 14rpx; width: 6rpx; height: 6rpx; border-radius: 50%; background: currentColor; }
.menu-watch::before { left: 8rpx; top: 7rpx; width: 18rpx; height: 24rpx; border: 4rpx solid currentColor; border-radius: 8rpx; }
.menu-watch::after { left: 12rpx; top: 0; width: 10rpx; height: 7rpx; border-radius: 4rpx; background: currentColor; box-shadow: 0 31rpx 0 currentColor; }
.menu-vip::before { left: 3rpx; top: 8rpx; width: 28rpx; height: 20rpx; border: 4rpx solid currentColor; transform: rotate(45deg); }
.menu-vip::after { left: 8rpx; top: 12rpx; width: 18rpx; height: 4rpx; background: currentColor; transform: rotate(45deg); }
.menu-bell::before { left: 8rpx; top: 5rpx; width: 18rpx; height: 22rpx; border: 4rpx solid currentColor; border-bottom: 0; border-radius: 14rpx 14rpx 6rpx 6rpx; }
.menu-bell::after { left: 5rpx; top: 27rpx; width: 24rpx; height: 4rpx; border-radius: 99rpx; background: currentColor; }
.menu-lock::before { left: 7rpx; top: 14rpx; width: 20rpx; height: 17rpx; border: 4rpx solid currentColor; border-radius: 5rpx; }
.menu-lock::after { left: 12rpx; top: 3rpx; width: 10rpx; height: 13rpx; border: 4rpx solid currentColor; border-bottom: 0; border-radius: 10rpx 10rpx 0 0; }
.onboard-page-head { height: 96rpx; display: grid; grid-template-columns: 80rpx 1fr 80rpx; align-items: center; margin: 18rpx 0 10rpx; }
.onboard-page-head > text { text-align: center; color: #090b0f; font-size: 45rpx; font-weight: 900; letter-spacing: 0; }
.onboard-page-head > b { justify-self: end; color: #7b828c; font-size: 32rpx; font-weight: 500; }
.onboard-page-head > b em { color: #0b9f50; font-size: 42rpx; font-style: normal; font-weight: 900; }
.onboard-back { width: 60rpx; height: 60rpx; position: relative; }
.onboard-back::before { content: ""; position: absolute; left: 18rpx; top: 14rpx; width: 26rpx; height: 26rpx; border-left: 6rpx solid #06080c; border-bottom: 6rpx solid #06080c; border-radius: 3rpx; transform: rotate(45deg); }
.onboard-steps { height: 74rpx; margin: 8rpx 0 42rpx; padding: 0 138rpx; display: grid; grid-template-columns: 40rpx 1fr 40rpx 1fr 40rpx 1fr 40rpx; align-items: center; gap: 18rpx; }
.onboard-steps view { width: 40rpx; height: 40rpx; border-radius: 50%; border: 2rpx solid #d0d5da; color: #7b828c; background: #fff; display: flex; align-items: center; justify-content: center; font-size: 24rpx; font-weight: 800; }
.onboard-steps view.done,
.onboard-steps view.active { border-color: #0b9f50; background: #0b9f50; color: #fff; }
.onboard-steps i { height: 4rpx; border-radius: 99rpx; background: #d0d5da; display: block; }
.onboard-steps i.done { background: #0b9f50; }
.onboard-section-title { margin: 26rpx 0 14rpx; color: #151a22; font-size: 28rpx; font-weight: 900; }
.onboard-section-title small { color: #8a929b; font-size: 24rpx; font-weight: 500; }
.onboard-info-card { padding: 0 24rpx; border: 1rpx solid #dfe4e9; border-radius: 18rpx; background: #fff; }
.onboard-info-card > view { min-height: 86rpx; display: grid; grid-template-columns: 180rpx 1fr 24rpx; align-items: center; border-bottom: 1rpx solid #e5e9ed; }
.onboard-info-card > view:last-child { border-bottom: 0; }
.onboard-info-card text { color: #12161d; font-size: 30rpx; font-weight: 500; }
.onboard-info-card b { justify-self: end; color: #0d1117; font-size: 30rpx; font-weight: 600; }
.onboard-info-card input { justify-self: end; width: 220rpx; height: 56rpx; color: #0d1117; text-align: right; font-size: 30rpx; font-weight: 700; }
.onboard-info-card small { color: #5f6872; font-size: 24rpx; font-weight: 500; }
.onboard-info-card em { justify-self: end; color: #7b828c; font-style: normal; font-size: 42rpx; line-height: 1; }
.onboard-info-card .gender-row { grid-template-columns: 180rpx 1fr; }
.onboard-info-card.compact { margin-top: 0; }
.gender-actions { justify-self: end; display: flex; gap: 24rpx; }
.gender-actions button { margin: 0; padding: 0; width: 142rpx; height: 66rpx; border: 1rpx solid #dce2e6; border-radius: 14rpx; background: #fff; color: #4b5563; display: flex; align-items: center; justify-content: center; gap: 14rpx; font-size: 30rpx; font-weight: 800; line-height: 1; }
.gender-actions button.active { border-color: #0b9f50; background: linear-gradient(180deg, #13aa56, #079845); color: #fff; }
.onboard-goal-grid { display: grid; grid-template-columns: 1.05fr 1fr 1fr 1.12fr; gap: 22rpx; }
.onboard-level-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 22rpx; }
.onboard-goal-grid button,
.onboard-level-grid button { margin: 0; padding: 0; height: 76rpx; border: 1rpx solid #dfe4e9; border-radius: 16rpx; background: #fff; color: #11151b; display: flex; align-items: center; justify-content: center; gap: 14rpx; font-size: 28rpx; font-weight: 800; line-height: 1; white-space: nowrap; }
.onboard-goal-grid button.active { border-color: #0b9f50; background: linear-gradient(180deg, #13aa56, #079845); color: #fff; }
.onboard-level-grid button.active { border-color: #82d2a5; background: #f3fbf6; color: #0b9f50; }
.onboard-preferences { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24rpx; }
.onboard-preferences button { margin: 0; padding: 0 24rpx; height: 54rpx; border: 1rpx solid #d9e9de; border-radius: 999rpx; background: #f3fbf6; color: #11151b; display: flex; align-items: center; justify-content: flex-start; gap: 18rpx; font-size: 25rpx; font-weight: 800; line-height: 1; }
.onboard-preferences button.active { border-color: #0b9f50; background: #e7f7ed; color: #0b9f50; }
.onboard-preferences i { width: 32rpx; height: 32rpx; border-radius: 50%; background: #14a857; color: #fff; display: flex; align-items: center; justify-content: center; font-style: normal; font-size: 22rpx; font-weight: 900; }
.onboard-textarea { height: 112rpx; padding: 24rpx 26rpx; border: 1rpx solid #dfe4e9; border-radius: 16rpx; background: #fff; display: flex; align-items: flex-start; justify-content: space-between; color: #a1a8b0; font-size: 25rpx; }
.onboard-textarea small { align-self: flex-end; color: #8c949e; font-size: 22rpx; }
.onboard-textarea-input { box-sizing: border-box; width: 100%; height: 112rpx; padding: 24rpx 26rpx; border: 1rpx solid #dfe4e9; border-radius: 16rpx; background: #fff; color: #11151b; font-size: 25rpx; line-height: 1.45; }
.onboard-next { margin: 34rpx 0 8rpx; padding: 0; width: 100%; height: 88rpx; border-radius: 18rpx; background: linear-gradient(180deg, #12aa56, #049343); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 32rpx; font-weight: 900; line-height: 1; }
.onboard-next[disabled] { opacity: .68; }
.on-icon { width: 32rpx; height: 32rpx; display: block; position: relative; color: currentColor; }
.on-icon::before,
.on-icon::after { content: ""; position: absolute; box-sizing: border-box; display: block; }
.on-male::before { left: 3rpx; bottom: 3rpx; width: 16rpx; height: 16rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.on-male::after { right: 2rpx; top: 2rpx; width: 14rpx; height: 14rpx; border-top: 4rpx solid currentColor; border-right: 4rpx solid currentColor; }
.on-female::before { left: 7rpx; top: 2rpx; width: 18rpx; height: 18rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.on-female::after { left: 14rpx; bottom: 1rpx; width: 4rpx; height: 13rpx; background: currentColor; box-shadow: -5rpx 6rpx 0 -1rpx currentColor, 5rpx 6rpx 0 -1rpx currentColor; }
.on-fire::before { left: 9rpx; top: 3rpx; width: 15rpx; height: 24rpx; border-radius: 16rpx 16rpx 16rpx 3rpx; background: currentColor; transform: rotate(35deg); }
.on-fire::after { left: 8rpx; top: 14rpx; width: 9rpx; height: 13rpx; border-radius: 10rpx 10rpx 10rpx 2rpx; background: rgba(255,255,255,.45); transform: rotate(35deg); }
.on-muscle::before { left: 4rpx; top: 11rpx; width: 20rpx; height: 13rpx; border: 4rpx solid currentColor; border-top: 0; border-radius: 0 0 14rpx 14rpx; transform: rotate(-22deg); }
.on-muscle::after { left: 16rpx; top: 6rpx; width: 10rpx; height: 12rpx; border: 4rpx solid currentColor; border-left: 0; border-radius: 0 9rpx 9rpx 0; transform: rotate(-22deg); }
.on-shape::before { left: 6rpx; top: 4rpx; width: 18rpx; height: 24rpx; border-left: 4rpx solid currentColor; border-right: 4rpx solid currentColor; border-radius: 50%; }
.on-shape::after { left: 10rpx; top: 13rpx; width: 10rpx; height: 7rpx; border-top: 4rpx solid currentColor; border-bottom: 4rpx solid currentColor; border-radius: 50%; }
.on-health::before { left: 3rpx; top: 7rpx; width: 26rpx; height: 20rpx; border: 4rpx solid currentColor; border-radius: 50% 50% 45% 45%; }
.on-health::after { left: 9rpx; top: 13rpx; width: 14rpx; height: 8rpx; border-left: 4rpx solid currentColor; border-bottom: 4rpx solid currentColor; transform: rotate(-45deg); }
.on-user::before { left: 11rpx; top: 3rpx; width: 10rpx; height: 10rpx; border: 4rpx solid currentColor; border-radius: 50%; }
.on-user::after { left: 5rpx; bottom: 3rpx; width: 22rpx; height: 14rpx; border: 4rpx solid currentColor; border-radius: 14rpx 14rpx 4rpx 4rpx; border-bottom: 0; }
.on-dumbbell::before { left: 3rpx; top: 14rpx; width: 26rpx; height: 5rpx; border-radius: 99rpx; background: currentColor; }
.on-dumbbell::after { left: 0; top: 8rpx; width: 8rpx; height: 18rpx; border-radius: 4rpx; background: currentColor; box-shadow: 24rpx 0 0 currentColor, 8rpx 4rpx 0 -2rpx currentColor, 16rpx 4rpx 0 -2rpx currentColor; }
.on-star::before { inset: 3rpx; background: currentColor; clip-path: polygon(50% 0, 61% 34%, 97% 34%, 68% 54%, 79% 90%, 50% 68%, 21% 90%, 32% 54%, 3% 34%, 39% 34%); }
.onboarding-head { margin: 26rpx 0 24rpx; }
.onboarding-head text { color: #0e9f53; font-weight: 900; }
.onboarding-head b { display: block; margin-top: 16rpx; font-size: 42rpx; }
.field { height: 74rpx; display: flex; justify-content: space-between; align-items: center; border-bottom: 1rpx solid #edf0f2; }
.field:last-child { border-bottom: 0; }
.field text { color: #6d7680; }
.block { margin-top: 22rpx; padding: 0; border: 0; display: block; }
.block b { display: block; margin-bottom: 14rpx; }
.limit-box { margin-top: 22rpx; height: 96rpx; padding: 22rpx; border-radius: 16rpx; border: 1rpx dashed #cfd8d3; color: #8a929b; background: #fff; }
.tabbar {
  position: absolute;
  left: 22rpx;
  right: 22rpx;
  bottom: 18rpx;
  height: 116rpx;
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  padding: 10rpx 10rpx 12rpx;
  border: 1rpx solid rgba(224, 230, 226, .9);
  border-radius: 30rpx;
  background: rgba(255, 255, 255, .96);
  box-shadow: 0 18rpx 42rpx rgba(26, 40, 34, .13);
  backdrop-filter: blur(18rpx);
}
.tabbar button {
  min-width: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 7rpx;
  border-radius: 24rpx;
  color: #8a929b;
  font-weight: 700;
}
.tab-icon {
  width: 48rpx;
  height: 44rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 16rpx;
  color: #7c858f;
  font-size: 30rpx;
  line-height: 1;
  transition: all .18s ease;
}
.tabbar small {
  font-size: 20rpx;
  line-height: 1;
  white-space: nowrap;
}
.tabbar .active {
  color: #0b8f4b;
  font-weight: 900;
}
.tabbar .active .tab-icon {
  width: 56rpx;
  background: #e7f7ed;
  color: #0e9f53;
  box-shadow: inset 0 0 0 1rpx rgba(14, 159, 83, .14);
}
</style>
