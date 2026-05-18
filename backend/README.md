# AI Fitness Coach Backend

FastAPI 后端骨架，按产品规划中的业务模块拆分：

- 用户资料与目标
- 饮食记录与拍照识别结果
- AI 健身计划
- 打卡记录
- 运动数据
- AI 私教对话

## 启动

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

访问：

- `http://127.0.0.1:8000/api/health`
- `http://127.0.0.1:8000/docs`

## PostgreSQL

数据库结构在：

```text
database/schema.sql
```

本版本先提供 API 和 schema 骨架，接口返回 mock 数据，方便前端先完成产品流转。后续接入 PostgreSQL 时，把 `app/services/mock_data.py` 替换为 repository 查询即可。
