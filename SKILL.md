---
name: mermaid-tools
description: This skill should be used when the user asks to "extract Mermaid diagrams", "convert Mermaid to PNG", "generate Mermaid images", "create flowchart", "draw diagram", "设置主题", "change theme", "生成流程图", "转换图表", or mentions working with Mermaid code blocks in markdown files. Bundled scripts extract diagrams from markdown and generate high-quality PNG/SVG images with smart sizing and theme support.
version: 2.1.0
---

# Mermaid Tools / Mermaid 图表工具

从 Markdown 文件提取 Mermaid 图表并生成高质量 PNG/SVG 图像。支持直接从 Mermaid 代码生成图表。

Extract Mermaid diagrams from markdown files and generate high-quality PNG/SVG images. Supports direct diagram generation from Mermaid code.

## 核心功能 / Core Features

### 1. 提取并生成图表 / Extract and Generate

从 Markdown 文件提取所有 Mermaid 图表并生成图像：

```bash
cd scripts
./extract-and-generate.sh "<markdown_file>" "<output_directory>"
```

**功能 / Features:**
- 自动提取所有 ````mermaid` 代码块
- 按顺序编号（01, 02, 03...）
- 生成 `.mmd` 文件和图像文件
- 智能尺寸调整
- 自动验证输出

### 2. 直接生成图表 / Direct Generation

从 Mermaid 代码或 `.mmd` 文件直接生成图像：

```bash
cd scripts

# 从 Mermaid 代码生成 PNG
./generate-diagram.sh "graph TD; A-->B;" "output.png"

# 从 .mmd 文件生成 SVG
./generate-diagram.sh "diagram.mmd" "output.svg"

# 使用环境变量指定格式
MERMAID_FORMAT=svg ./generate-diagram.sh "graph TD; A-->B;" "output"
```

**支持的输入格式 / Supported Input:**
- Mermaid 代码字符串
- `.mmd` 文件路径

**支持的输出格式 / Supported Output:**
- PNG（默认，支持缩放）
- SVG（矢量图）

### 3. 智能尺寸调整 / Smart Sizing

脚本根据图表类型自动调整尺寸：

| 图表类型 | 尺寸 |
|---------|------|
| Timeline/Gantt | 2400×400（宽且短）|
| Architecture/System/Caching | 2400×1600（大且详细）|
| Monitoring/Workflow/Sequence/API | 2400×800（宽流程图）|
| 默认 / Default | 1200×800 |

### 4. 自定义参数 / Customization

通过环境变量覆盖默认参数：

```bash
cd scripts

# 自定义尺寸和缩放
MERMAID_WIDTH=1600 MERMAID_HEIGHT=1200 MERMAID_SCALE=3 \
  ./generate-diagram.sh "graph TD; A-->B;" "output.png"

# SVG 格式
MERMAID_FORMAT=svg ./generate-diagram.sh "graph TD; A-->B;" "output"

# 使用深色主题
MERMAID_THEME=dark ./generate-diagram.sh "graph TD; A-->B;" "output.png"
```

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| `MERMAID_FORMAT` | png | 输出格式：png 或 svg |
| `MERMAID_WIDTH` | 1200 | 基础宽度（像素）|
| `MERMAID_HEIGHT` | 800 | 基础高度（像素）|
| `MERMAID_SCALE` | 2 | PNG 缩放因子 |
| `MERMAID_THEME` | default | 图表主题 |

### 5. 主题支持 / Theme Support

支持多种 Mermaid 内置主题，通过 `MERMAID_THEME` 环境变量设置：

| 主题 | 说明 |
|------|------|
| `default` | 默认主题，白色背景 |
| `forest` | 森林主题，绿色系 |
| `dark` | 深色主题，适合暗色背景 |
| `neutral` | 中性主题，灰色系 |
| `night` | 夜间主题，深蓝色系 |

**使用示例 / Usage Examples:**

```bash
cd scripts

# 深色主题生成单张图表
MERMAID_THEME=dark ./generate-diagram.sh "graph TD; A-->B;" "output.png"

# 森林主题批量提取
MERMAID_THEME=forest ./extract-and-generate.sh "document.md" "diagrams"

# 中性主题生成 SVG
MERMAID_THEME=neutral MERMAID_FORMAT=svg \
  ./generate-diagram.sh "graph LR;" "output"
```

**主题效果预览 / Theme Preview:**

```bash
# 生成同一图表的不同主题版本
for theme in default forest dark neutral night; do
  MERMAID_THEME=$theme ./generate-diagram.sh \
    "graph TD; A[开始] --> B[处理] --> C[结束]" \
    "example-$theme.png"
done
```

## 重要原则 / Important Principles

### 始终从 scripts 目录运行 / Always Run from scripts Directory

所有脚本依赖同目录下的其他文件，必须先切换到 `scripts/` 目录：

```bash
cd ~/.claude/skills/mermaid-tools/scripts
./[script-name].sh [arguments]
```

从其他目录运行会因找不到依赖而失败。

### 使用捆绑脚本 / Use Bundled Scripts

始终使用此技能 `scripts/` 目录中捆绑的脚本：

- `extract-and-generate.sh` - 提取并批量生成
- `generate-diagram.sh` - 直接生成单个图表
- `extract_diagrams.py` - Python 提取工具
- `puppeteer-config.json` - WSL2 Chrome 配置

## 依赖验证 / Dependency Verification

运行脚本前验证依赖：

```bash
# 检查 mermaid-cli
mmdc --version

# 检查 Chrome
google-chrome-stable --version

# 检查 Python 3
python3 --version
```

缺少依赖？查看 `references/setup_and_troubleshooting.md` 获取完整安装说明。

## 脚本说明 / Script Reference

### extract-and-generate.sh

从 Markdown 提取图表并批量生成图像。

**工作流程 / Workflow:**
1. 验证依赖（mermaid-cli、Chrome、Python）
2. 调用 Python 脚本提取 Mermaid 代码块
3. 为每个图表生成图像文件
4. 验证生成的文件

**输出文件 / Output Files:**
- `01-diagram-name.mmd` - 提取的 Mermaid 代码
- `01-diagram-name.png` - 高分辨率 PNG 图像

### generate-diagram.sh

直接从 Mermaid 代码或文件生成图像。

**参数 / Arguments:**
```
<input> <output_file> [format]
```

- `input` - Mermaid 代码字符串或 .mmd 文件
- `output_file` - 输出文件路径
- `format` - 可选：png 或 svg

**用法示例 / Usage Examples:**
```bash
# 代码转 PNG
./generate-diagram.sh "graph TD; A-->B;" "flowchart.png"

# 文件转 SVG
./generate-diagram.sh "diagram.mmd" "diagram.svg"

# 显式指定格式
./generate-diagram.sh "graph LR;" "output" "svg"

# 高分辨率 PNG
MERMAID_SCALE=3 ./generate-diagram.sh "graph TD; A-->B;" "output.png"
```

### extract_diagrams.py

Python 脚本，从 Markdown 文件提取 Mermaid 代码块。

**命名策略 / Naming Strategy:**
1. 特定描述（system architecture、authentication flow）
2. 章节标题（## 或 ###）
3. 默认编号（diagram-01、diagram-02）

### puppeteer-config.json

Chrome/Puppeteer 配置文件，包含 WSL2 环境启动参数。

## 常见问题 / Quick Fixes

### 权限被拒绝 / Permission Denied

```bash
chmod +x ~/.claude/skills/mermaid-tools/scripts/*.sh
```

### 输出质量低 / Low Quality Output

```bash
MERMAID_SCALE=3 ./generate-diagram.sh "graph TD; A-->B;" "output.png"
```

### Chrome 错误 / Chrome Errors

验证 WSL2 依赖已安装（见 references/ 文档）。

### 找不到图表 / No Diagrams Found

1. 验证 Markdown 文件包含 ````mermaid` 代码块
2. 检查文件路径正确
3. 确保代码块格式正确

## 附加资源 / Additional Resources

### 参考文档 / Reference Documentation

- **`references/setup_and_troubleshooting.md`** - 完整的依赖安装、环境变量和故障排除指南

### 脚本文件 / Script Files

- **`scripts/extract-and-generate.sh`** - 批量提取和生成
- **`scripts/generate-diagram.sh`** - 直接生成单个图表
- **`scripts/extract_diagrams.py`** - Python 提取工具
- **`scripts/puppeteer-config.json`** - WSL2 Chrome 配置

### 支持的图表类型 / Supported Diagram Types

- 流程图 / Flowchart (graph TD/LR)
- 序列图 / Sequence diagram
- 类图 / Class diagram
- 状态图 / State diagram
- 实体关系图 / ER diagram
- 用户旅程图 / User journey
- 甘特图 / Gantt chart
- 饼图 / Pie chart
- 甘特图 / Git graph
- 时间轴 / Timeline
- 思维导图 / Mindmap
