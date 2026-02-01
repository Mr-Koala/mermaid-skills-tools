# Mermaid Tools

> 从 Markdown 文件提取 Mermaid 图表并生成高质量 PNG/SVG 图像

[![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)](https://github.com/daymade/claude-code-skills/tree/main/mermaid-tools)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 特性

- **批量提取** - 自动从 Markdown 文件提取所有 Mermaid 代码块
- **智能命名** - 根据上下文自动生成有意义的文件名
- **高质量输出** - 支持 PNG 和 SVG 格式，可自定义分辨率
- **主题支持** - 支持多种内置主题（default、forest、dark、neutral、night）
- **智能尺寸** - 根据图表类型自动调整画布大小

## 快速开始

### 安装依赖

```bash
# 安装 mermaid-cli
npm install -g @mermaid-js/mermaid-cli

# 安装 Chrome（Linux/WSL2）
sudo apt-get update
sudo apt-get install -y google-chrome-stable
```

### 批量提取并生成

从 Markdown 文件提取所有 Mermaid 图表：

```bash
cd ~/.claude/skills/mermaid-tools/scripts
./extract-and-generate.sh "document.md" "diagrams"
```

输出：`01-diagram-name.mmd` + `01-diagram-name.png/svg`

### 直接生成单个图表

```bash
cd ~/.claude/skills/mermaid-tools/scripts

# 从代码生成 PNG
./generate-diagram.sh "graph TD; A-->B;" "output.png"

# 从文件生成 SVG
./generate-diagram.sh "diagram.mmd" "output.svg"
```

## 主题定制

支持五种内置主题：

```bash
# 深色主题
MERMAID_THEME=dark ./generate-diagram.sh "graph TD; A-->B;" "output.png"

# 森林主题
MERMAID_THEME=forest ./extract-and-generate.sh "doc.md" "diagrams"

# 夜间主题生成 SVG
MERMAID_THEME=night MERMAID_FORMAT=svg ./generate-diagram.sh "graph LR;" "output"
```

| 主题 | 效果 |
|------|------|
| `default` | 白色背景，默认配色 |
| `forest` | 绿色系，清新风格 |
| `dark` | 深色背景，适合暗色界面 |
| `neutral` | 灰色系，中性简约 |
| `night` | 深蓝色系，夜间模式 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MERMAID_FORMAT` | png | 输出格式：png 或 svg |
| `MERMAID_WIDTH` | 1200 | 基础宽度（像素）|
| `MERMAID_HEIGHT` | 800 | 基础高度（像素）|
| `MERMAID_SCALE` | 2 | PNG 缩放因子（影响清晰度）|
| `MERMAID_THEME` | default | 图表主题 |

## 智能尺寸调整

脚本根据图表类型自动选择最佳尺寸：

| 图表类型 | 尺寸 | 适用场景 |
|---------|------|---------|
| Timeline/Gantt | 2400×400 | 时间轴、项目计划 |
| Architecture/System | 2400×1600 | 系统架构、详细设计 |
| Workflow/Sequence | 2400×800 | 流程图、时序图 |
| 默认 | 1200×800 | 通用图表 |

## 项目结构

```
mermaid-tools/
├── scripts/
│   ├── extract-and-generate.sh    # 批量提取和生成
│   ├── generate-diagram.sh         # 直接生成单个图表
│   ├── extract_diagrams.py         # Python 提取工具
│   └── puppeteer-config.json       # WSL2 Chrome 配置
├── references/
│   └── setup_and_troubleshooting.md  # 详细安装和故障排除
├── skill.md                        # 技能配置文件
├── CLAUDE.md                       # Claude Code 使用指南
└── README.md                       # 本文件
```

## 常见问题

### 权限被拒绝

```bash
chmod +x ~/.claude/skills/mermaid-tools/scripts/*.sh
```

### 输出质量低

提高缩放因子获得更清晰的 PNG：

```bash
MERMAID_SCALE=3 ./generate-diagram.sh "graph TD; A-->B;" "output.png"
```

### Chrome 错误（WSL2）

确保已安装 Chrome 依赖：

```bash
sudo apt-get install -y \
  libnss3 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libdrm2 \
  libxkbcommon0 \
  libxcomposite1 \
  libxdamage1 \
  libxfixes3 \
  libxrandr2 \
  libgbm1 \
  libasound2
```

### 找不到图表

1. 确认 Markdown 文件包含 ` ```mermaid ` 代码块
2. 检查文件路径是否正确
3. 验证代码块格式正确

## 支持的图表类型

- 流程图 (Flowchart)
- 序列图 (Sequence diagram)
- 类图 (Class diagram)
- 状态图 (State diagram)
- 实体关系图 (ER diagram)
- 用户旅程图 (User journey)
- 甘特图 (Gantt chart)
- 饼图 (Pie chart)
- Git 图 (Git graph)
- 时间轴 (Timeline)
- 思维导图 (Mindmap)

## 版本历史

### v2.1.0
- 新增主题支持功能
- 支持 PNG 和 SVG 格式切换
- 智能尺寸调整

### v2.0.0
- 初始版本，基础提取和生成功能

## 许可证

MIT License

## 相关资源

- [Mermaid 官方文档](https://mermaid.js.org/)
- [mermaid-cli GitHub](https://github.com/mermaid-js/mermaid-cli)
- [Claude Code Skills](https://claude-plugins.dev/skills/@daymade/claude-code-skills/mermaid-tools)
