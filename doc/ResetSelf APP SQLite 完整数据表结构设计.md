ResetSelf APP SQLite 完整数据表结构设计（可直接落地开发）

**设计原则**：贴合一日身份重构理论、高内聚低冗余、支持年度迭代、支持事务回滚、适配所有业务引擎、兼容长期数据沉淀。

**数据库基础信息**：DB Name：resetself_v1.db | 支持版本迁移、离线存储、全量事务。

---

## 数据表总览（6张核心表，无冗余）

1. **user_profile** 用户核心身份总表（唯一主数据）
    
2. **restructure_record** 24h重构问卷全量记录表
    
3. **limiting_belief** 限制性信念/内在敌人库
    
4. **daily_checkin** 每日身份校验日志表
    
5. **inertia_sample** 惯性样本库（偏差/内耗/SOS自动归档）
    
6. **yearly_archive** 年度迭代归档表（系统升级快照）
    

---

## 1. user_profile｜用户核心身份主表（唯一单条数据）

存储用户最终定稿身份、当前极简行动、系统状态，全局唯一。

```sql
CREATE TABLE IF NOT EXISTS user_profile (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  identity_text TEXT NOT NULL DEFAULT '',      -- 新身份叙事（5条以内完整文本）
  today_min_action TEXT NOT NULL DEFAULT '',   -- 当日唯一极简行动
  status TEXT NOT NULL DEFAULT 'uninit',      -- uninit/init/finished（是否完成首次重构）
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 仅保留一条用户配置
CREATE UNIQUE INDEX idx_user_single ON user_profile(id);
```

## 2. restructure_record｜24h重构问卷记录表

存储每一次完整24h重构的全套底稿，支持多次重构覆盖与回溯。

```sql
CREATE TABLE IF NOT EXISTS restructure_record (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  anti_vision TEXT,           -- 反愿景（现状恶果）
  fear_content TEXT,          -- 底层恐惧挖掘
  belief_draft TEXT,          -- 限制性信念初稿
  identity_draft TEXT,        -- 身份叙事初稿
  min_action_draft TEXT,      -- 极简行动初稿
  is_latest INTEGER DEFAULT 0,-- 是否当前生效版本 1/0
  create_year INTEGER,        -- 重构年份（用于年度归档）
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 3. limiting_belief｜限制性信念库（内在敌人）

沉淀用户核心潜意识阻碍，支持多条、支持生效/失效、年度淘汰。

```sql
CREATE TABLE IF NOT EXISTS limiting_belief (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,      -- 限制性信念原文
  trigger_scene TEXT,         -- 触发场景（用户补充/系统自动采集）
  status TEXT DEFAULT 'active',-- active/inactive（是否已破除）
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 4. daily_checkin｜每日身份校验日志表

存储每日三态校验数据，为周复盘、趋势统计提供数据源。

```sql
CREATE TABLE IF NOT EXISTS daily_checkin (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  check_date TEXT NOT NULL,   -- 校验日期 YYYY-MM-DD
  match_status TEXT NOT NULL, -- match/partial/error 三态
  system_comment TEXT,        -- 系统中性归因文案
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(check_date)          -- 每日仅一条记录
);
```

## 5. inertia_sample｜惯性样本库（核心业务数据表）

自动收录：每日偏离、SOS急救、内耗、拖延、恐惧触发记录。

```sql
CREATE TABLE IF NOT EXISTS inertia_sample (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_type TEXT NOT NULL,  -- checkin / sos / manual
  status_tag TEXT,            -- 匹配/部分偏离/完全偏离
  content TEXT,               -- 用户描述/系统采集内容
  belief_ref_id INTEGER,      -- 关联限制性信念ID（可空）
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (belief_ref_id) REFERENCES limiting_belief(id)
);
```

## 6. yearly_archive｜年度迭代归档表

每年系统升级快照，保存全年身份、信念、样本数据，用于年度对比报告。

```sql
CREATE TABLE IF NOT EXISTS yearly_archive (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  archive_year INTEGER NOT NULL, -- 归档年份
  identity_snapshot TEXT,     -- 当年身份快照
  belief_snapshot TEXT,       -- 当年核心信念快照
  sample_count INTEGER DEFAULT 0, -- 全年惯性样本总数
  checkin_stability TEXT,     -- 年度稳定度评级
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(archive_year)
);
```

---

## 核心索引设计（查询性能优化）

```sql
-- 惯性样本按时间检索（周复盘、历史记录）
CREATE INDEX idx_inertia_time ON inertia_sample(created_at);
-- 每日校验按日期检索
CREATE INDEX idx_checkin_date ON daily_checkin(check_date);
-- 信念状态筛选
CREATE INDEX idx_belief_status ON limiting_belief(status);
-- 年度归档年份检索
CREATE INDEX idx_archive_year ON yearly_archive(archive_year);
```

---

## 数据库业务规则（强制约束，对齐理论）

- **事务强制开启**：所有新增/修改/删除业务数据，必须包裹事务，失败自动回滚，杜绝数据残缺。
    
- **无数据删除逻辑**：用户所有自省数据只新增、归档、标记失效，不物理删除（保护成长轨迹）。
    
- **每日校验唯一约束**：同一天只能提交一次校验，防止重复数据。
    
- **最新重构版本唯一**：is_latest 全局仅一条为1，其余为0，保证首页渲染正确身份。
    
- **偏差数据永久留存**：所有inertia_sample样本永久保存，作为长期迭代数据源。
    

---

## 适配P0/P1阶段能力说明

✅ 完全支撑：数据持久化、首页身份渲染、每日校验、样本库收录、重构记录保存

✅ 预留支撑：周智能复盘SQL统计、年度对比报告、数据导出、白皮书生成

✅ 完全适配：防挫败机制、零删除、零清零、永久接续成长逻辑