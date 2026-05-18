
基于 `AI_Fitness_Coach_Product_Plan.md` 落地的 AI 饮食分析、拍照识别热量、AI 健身计划、打卡、运动数据和 AI 私教产品原型。
<img width="3840" height="2160" alt="merged" src="https://github.com/user-attachments/assets/772591c4-a41f-4343-a487-34f685844888" />

## 技术栈

- 前端：uni-app + Vue 3 + TypeScript + Vite
- 后端：FastAPI
- 数据库：PostgreSQL

## 前端启动

```powershell
npm install
npm run dev:h5
```

默认地址：

```text
http://127.0.0.1:5173
```

前端页面按 `ui` 目录中的高保真效果图，用 uni-app 真实页面结构绘制，不再使用 PNG 作为页面主体。

H5 构建：

```powershell
npm run build:h5
```

微信小程序构建：

```powershell
npm run build:mp-weixin
```

## 后端启动

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

接口文档：

```text
http://127.0.0.1:8000/docs
```

健康检查：

```text
http://127.0.0.1:8000/api/health
```

## PostgreSQL

数据库结构：

```text
database/schema.sql
```

示例数据：

```text
database/seed.sql
```

导入示例：

```powershell
psql -U fitness -d ai_fitness_coach -f database/schema.sql
psql -U fitness -d ai_fitness_coach -f database/seed.sql
```
