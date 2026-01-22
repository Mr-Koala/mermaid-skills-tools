#!/bin/bash
# 直接生成 Mermaid 流程图脚本 / Direct Mermaid diagram generation script
# 从 Mermaid 代码或 .mmd 文件生成 PNG/SVG 图像
# Generates diagrams from Mermaid code or .mmd files to PNG/SVG
#
# 用法 / Usage: ./generate-diagram.sh "<input>" "<output_file>" [format]
#
# 示例 / Examples:
#   ./generate-diagram.sh "graph TD; A-->B;" "output.png"
#   ./generate-diagram.sh "diagram.mmd" "output.svg" "svg"
#   MERMAID_FORMAT=svg ./generate-diagram.sh "graph TD; A-->B;" "output"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/puppeteer-config.json"

# 解析参数 / Parse arguments
if [ $# -lt 2 ]; then
    echo "用法 / Usage: $0 <input> <output_file> [format]"
    echo ""
    echo "参数 / Arguments:"
    echo "  input        Mermaid 代码字符串或 .mmd 文件路径"
    echo "               Mermaid code string or .mmd file path"
    echo "  output_file  输出文件路径（根据扩展名或 format 参数确定格式）"
    echo "               Output file path (format determined by extension or format arg)"
    echo "  format       可选 / Optional: 'png' 或 'and' svg'（覆盖扩展名 / overrides extension）"
    echo ""
    echo "环境变量 / Environment Variables:"
    echo "  MERMAID_FORMAT    输出格式 / Output format: png (默认 / default) 或 svg"
    echo "  MERMAID_WIDTH     宽度 / Width in pixels (默认 / default: 1200)"
    echo "  MERMAID_HEIGHT    高度 / Height in pixels (默认 / default: 800)"
    echo "  MERMAID_SCALE     PNG 缩放因子 / PNG scale factor (默认 / default: 2)"
    echo "  MERMAID_THEME     主题 / Theme: default, forest, dark, neutral, night (默认 / default: default)"
    echo ""
    echo "示例 / Examples:"
    echo "  # 从 Mermaid 代码生成 PNG / From Mermaid code to PNG"
    echo '  $0 "graph TD; A-->B;" output.png'
    echo ""
    echo "  # 从 .mmd 文件生成 SVG / From .mmd file to SVG"
    echo "  $0 diagram.mmd output.svg"
    echo ""
    echo "  # 显式指定格式 / Explicit format override"
    echo '  $0 "graph TD; A-->B;" output.png svg'
    echo ""
    echo "  # 使用环境变量 / Using environment variables"
    echo '  MERMAID_FORMAT=svg $0 "graph TD; A-->B;" output'
    exit 1
fi

INPUT="$1"
OUTPUT="$2"
FORMAT="${3:-${MERMAID_FORMAT:-png}}"

# 检测 Chrome 路径 / Detect Chrome path
if [ -f "/usr/bin/google-chrome-stable" ]; then
    CHROME_PATH="/usr/bin/google-chrome-stable"  # Linux
elif [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"  # macOS
else
    CHROME_PATH="google-chrome-stable"  # 尝试 PATH
fi

# 默认尺寸 / Default dimensions
DEFAULT_WIDTH="${MERMAID_WIDTH:-1200}"
DEFAULT_HEIGHT="${MERMAID_HEIGHT:-800}"
SCALE_FACTOR="${MERMAID_SCALE:-2}"
THEME="${MERMAID_THEME:-default}"

echo "=== Mermaid 流程图生成器 / Diagram Generator ==="

# 验证 Chrome / Validate Chrome
if [ ! -f "$CHROME_PATH" ]; then
    echo "错误 / ERROR: Google Chrome 未找到 / not found at $CHROME_PATH"
    exit 1
fi

# 验证配置 / Validate config
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误 / ERROR: Puppeteer 配置未找到 / config not found: $CONFIG_FILE"
    exit 1
fi

# 检查 mmdc 是否安装 / Check if mmdc is installed
if ! command -v mmdc &> /dev/null; then
    echo "错误 / ERROR: @mermaid-js/mermaid-cli 未安装 / not installed"
    echo "安装 / Install with: npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

# 添加主题配置 / Add theme configuration to mermaid code
apply_theme() {
    local content="$1"
    local theme="$2"

    # 如果内容已包含 init 指令，不添加主题
    if echo "$content" | grep -q "%%{init:"; then
        echo "$content"
        return
    fi

    # 添加主题配置
    echo "%%{init: {'theme':'$theme'}}%%"
    echo "$content"
}

# 判断输入是文件还是 Mermaid 代码 / Determine if input is file or code
INPUT_FILE=""
if [ -f "$INPUT" ]; then
    # 读取文件内容并应用主题 / Read file and apply theme
    ORIGINAL_CONTENT=$(cat "$INPUT")
    THEMED_CONTENT=$(apply_theme "$ORIGINAL_CONTENT" "$THEME")

    # 创建临时文件 / Create temp file
    INPUT_FILE=$(mktemp /tmp/mermaid-temp-XXXXXX.mmd)
    echo "$THEMED_CONTENT" > "$INPUT_FILE"
    echo "输入文件 / Input file: $INPUT"
    echo "应用主题 / Applied theme: $THEME"
    trap "rm -f $INPUT_FILE" EXIT
else
    # 为 Mermaid 代码创建临时文件并应用主题 / Create temp file with theme
    THEMED_CONTENT=$(apply_theme "$INPUT" "$THEME")
    INPUT_FILE=$(mktemp /tmp/mermaid-temp-XXXXXX.mmd)
    echo "$THEMED_CONTENT" > "$INPUT_FILE"
    echo "输入代码 / Input code: ${INPUT:0:50}..."
    echo "应用主题 / Applied theme: $THEME"
    trap "rm -f $INPUT_FILE" EXIT
fi

# 根据输出扩展名确定输出格式 / Determine output format from extension
if [ "$FORMAT" = "png" ] || [[ "$OUTPUT" == *.png ]]; then
    FORMAT="png"
    FINAL_OUTPUT="${OUTPUT%.png}.png"
elif [ "$FORMAT" = "svg" ] || [[ "$OUTPUT" == *.svg ]]; then
    FORMAT="svg"
    FINAL_OUTPUT="${OUTPUT%.svg}.svg"
else
    # 默认使用 PNG / Default to PNG
    FORMAT="png"
    FINAL_OUTPUT="${OUTPUT}.png"
fi

echo "输出格式 / Output format: $FORMAT"
echo "输出文件 / Output file: $FINAL_OUTPUT"
echo "尺寸 / Dimensions: ${DEFAULT_WIDTH}x${DEFAULT_HEIGHT}"
if [ "$FORMAT" = "png" ]; then
    echo "缩放因子 / Scale factor: ${SCALE_FACTOR}x"
fi
echo

# 智能尺寸调整 / Smart sizing based on content
WIDTH="$DEFAULT_WIDTH"
HEIGHT="$DEFAULT_HEIGHT"

# 读取输入内容进行智能调整 / Read input for smart sizing
CONTENT=$(cat "$INPUT_FILE" 2>/dev/null || echo "$INPUT")

if [[ "$CONTENT" =~ timeline|gantt ]]; then
    WIDTH=$((DEFAULT_WIDTH * 2))
    HEIGHT=$((DEFAULT_HEIGHT / 2))
    echo "检测到时间轴/Gantt图 / Detected timeline/gantt chart, 使用宽幅格式 / using wide format"
elif [[ "$CONTENT" =~ architecture|system ]]; then
    WIDTH=$((DEFAULT_WIDTH * 2))
    HEIGHT=$((DEFAULT_HEIGHT * 2))
    echo "检测到架构/系统图 / Detected architecture/system diagram, 使用大幅格式 / using large format"
elif [[ "$CONTENT" =~ caching ]]; then
    WIDTH=$((DEFAULT_WIDTH * 2))
    HEIGHT=$((DEFAULT_HEIGHT * 2))
    echo "检测到缓存图 / Detected caching diagram, 使用大幅格式 / using large format"
elif [[ "$CONTENT" =~ monitoring|workflow|sequence|api ]]; then
    WIDTH=$((DEFAULT_WIDTH * 2))
    HEIGHT="$DEFAULT_HEIGHT"
    echo "检测到工作流/序列图 / Detected workflow/sequence diagram, 使用宽幅格式 / using wide format"
fi

# 生成图表 / Generate diagram
echo "生成中 / Generating..."
if [ "$FORMAT" = "svg" ]; then
    # SVG 生成（无缩放因子）/ SVG generation (no scale factor)
    PUPPETEER_EXECUTABLE_PATH="$CHROME_PATH" mmdc \
        -i "$INPUT_FILE" \
        -o "$FINAL_OUTPUT" \
        --puppeteerConfigFile "$CONFIG_FILE" \
        -w "$WIDTH" \
        -H "$HEIGHT"
else
    # PNG 生成带缩放因子 / PNG generation with scale factor
    PUPPETEER_EXECUTABLE_PATH="$CHROME_PATH" mmdc \
        -i "$INPUT_FILE" \
        -o "$FINAL_OUTPUT" \
        --puppeteerConfigFile "$CONFIG_FILE" \
        -w "$WIDTH" \
        -H "$HEIGHT" \
        -s "$SCALE_FACTOR"
fi

if [ $? -eq 0 ]; then
    echo "✅ 生成成功 / Generated successfully"

    # 验证输出 / Validate output
    if test -s "$FINAL_OUTPUT"; then
        size=$(stat -c%s "$FINAL_OUTPUT" 2>/dev/null || stat -f%z "$FINAL_OUTPUT")
        if [ "$FORMAT" = "svg" ]; then
            echo "✅ 验证通过 / Validated SVG (${size} bytes)"
        else
            dimensions=$(identify -format "%wx%h" "$FINAL_OUTPUT" 2>/dev/null || echo "unknown")
            echo "✅ 验证通过 / Validated PNG (${size} bytes, ${dimensions})"
        fi
    else
        echo "⚠️  警告 / Warning: 输出文件为空 / Output file is empty"
    fi
else
    echo "❌ 生成失败 / Generation failed"
    exit 1
fi

echo
echo "=== 完成 / Complete ==="
echo "输出 / Output: $FINAL_OUTPUT"
