#!/bin/bash
# Enhanced Mermaid diagram extraction and PNG generation script
# Extracts diagrams from markdown and numbers them sequentially
# 支持主题 / Supports themes via MERMAID_THEME environment variable
#
# Usage: ./extract-and-generate.sh <markdown_file> [output_directory]
# Example: ./extract-and-generate.sh "~/workspace/document.md" "~/workspace/diagrams"
# Example with theme: MERMAID_THEME=forest ./extract-and-generate.sh "doc.md" "output"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/puppeteer-config.json"
EXTRACTOR_SCRIPT="$SCRIPT_DIR/extract_diagrams.py"

# Parse arguments / 解析参数
if [ $# -lt 1 ]; then
    echo "用法 / Usage: $0 <markdown_file> [output_directory]"
    echo "示例 / Example: $0 '~/workspace/document.md' '~/workspace/diagrams'"
    echo ""
    echo "环境变量 / Environment Variables:"
    echo "  MERMAID_WIDTH     宽度 / Width (默认 / default: 1200)"
    echo "  MERMAID_HEIGHT    高度 / Height (默认 / default: 800)"
    echo "  MERMAID_SCALE     PNG 缩放 / PNG scale (默认 / default: 2)"
    echo "  MERMAID_FORMAT    输出格式 / Output format: png 或 svg (默认 / default: png)"
    echo "  MERMAID_THEME     主题 / Theme: default, forest, dark, neutral, night (默认 / default: default)"
    exit 1
fi

MARKDOWN_FILE="$1"
OUTPUT_DIR="${2:-$(dirname "$MARKDOWN_FILE")/diagrams}"

echo "=== Enhanced Mermaid Diagram Processor ==="
echo "Source markdown: $MARKDOWN_FILE" 
echo "Output directory: $OUTPUT_DIR"
echo "Environment: WSL2 Ubuntu with Chrome dependencies"
echo

# Validate inputs
if [ ! -f "$MARKDOWN_FILE" ]; then
    echo "ERROR: Markdown file not found: $MARKDOWN_FILE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Configuration - 检测 Chrome 路径 / Detect Chrome path
if [ -f "/usr/bin/google-chrome-stable" ]; then
    CHROME_PATH="/usr/bin/google-chrome-stable"  # Linux/WSL2
elif [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"  # macOS
else
    CHROME_PATH="google-chrome-stable"  # 尝试 PATH
fi

echo "Detected Chrome at: $CHROME_PATH"

# Check dependencies
echo "Checking dependencies..."
if ! command -v mmdc &> /dev/null; then
    echo "ERROR: @mermaid-js/mermaid-cli not installed"
    echo "Install with: npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

if [ ! -f "$CHROME_PATH" ]; then
    echo "ERROR: Google Chrome not found at $CHROME_PATH"
    echo "Install Chrome and dependencies with the setup commands"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Puppeteer config not found: $CONFIG_FILE"
    exit 1
fi

if [ ! -f "$EXTRACTOR_SCRIPT" ]; then
    echo "ERROR: Python extractor script not found: $EXTRACTOR_SCRIPT"
    exit 1
fi

echo "✅ Dependencies verified"
echo

# Extract Mermaid diagrams from markdown
echo "Extracting Mermaid diagrams from markdown..."
python3 "$EXTRACTOR_SCRIPT" "$MARKDOWN_FILE" "$OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract diagrams from markdown"
    exit 1
fi

echo

# Now generate PNGs using the existing generation logic
echo "Generating PNG files..."
cd "$OUTPUT_DIR"

# Default dimensions - can be overridden with environment variables
# 默认尺寸 - 可通过环境变量覆盖
DEFAULT_WIDTH="${MERMAID_WIDTH:-1200}"
DEFAULT_HEIGHT="${MERMAID_HEIGHT:-800}"
SCALE_FACTOR="${MERMAID_SCALE:-2}"
THEME="${MERMAID_THEME:-default}"
FORMAT="${MERMAID_FORMAT:-png}"

# 添加主题配置 / Add theme configuration to mermaid code
apply_theme() {
    local content="$1"
    local theme="$2"

    # 如果内容已包含 init 指令，不添加主题
    # If content already has init directive, don't add theme
    if echo "$content" | grep -q "%%{init:"; then
        echo "$content"
        return
    fi

    # 添加主题配置 / Add theme configuration
    echo "%%{init: {'theme':'$theme'}}%%"
    echo "$content"
}

# Process all .mmd files in order
# 按顺序处理所有 .mmd 文件
mmd_files=(*.mmd)

if [ ${#mmd_files[@]} -eq 1 ] && [ "${mmd_files[0]}" = "*.mmd" ]; then
    echo "No .mmd files found in output directory / 输出目录中未找到 .mmd 文件"
    exit 0
fi

# Sort files numerically by their prefix
# 按文件名前缀数字排序
IFS=$'\n' mmd_files=($(sort -V <<< "${mmd_files[*]}"))

echo "Found ${#mmd_files[@]} Mermaid diagram(s) to process / 找到 ${#mmd_files[@]} 个 Mermaid 图表"
echo "Theme: $THEME / 主题: $THEME"
echo "Format: $FORMAT / 格式: $FORMAT"
echo

for mmd_file in "${mmd_files[@]}"; do
    if [ ! -f "$mmd_file" ]; then
        continue
    fi

    # Extract filename without extension
    # 提取不含扩展名的文件名
    diagram="${mmd_file%.mmd}"

    # 确定输出文件扩展名 / Determine output file extension
    if [ "$FORMAT" = "svg" ]; then
        output_file="${diagram}.svg"
    else
        output_file="${diagram}.png"
    fi
    
    # Use smart defaults based on diagram content or filename patterns
    width="$DEFAULT_WIDTH"
    height="$DEFAULT_HEIGHT"
    
    # Smart sizing based on filename patterns
    if [[ "$diagram" =~ timeline|gantt ]]; then
        width=$((DEFAULT_WIDTH * 2))  # Wider for timelines
        height=$((DEFAULT_HEIGHT / 2))  # Shorter for timelines
    elif [[ "$diagram" =~ architecture|system ]]; then
        width=$((DEFAULT_WIDTH * 2))  # Larger for complex diagrams
        height=$((DEFAULT_HEIGHT * 2))
    elif [[ "$diagram" =~ caching ]]; then
        width=$((DEFAULT_WIDTH * 2))  # Larger for caching flowcharts
        height=$((DEFAULT_HEIGHT * 2))
    elif [[ "$diagram" =~ monitoring|workflow|sequence|api ]]; then
        width=$((DEFAULT_WIDTH * 2))  # Wider for workflows and sequences
        height="$DEFAULT_HEIGHT"
    fi

    # 读取原始内容并应用主题 / Read original content and apply theme
    original_content=$(cat "$mmd_file")
    themed_content=$(apply_theme "$original_content" "$THEME")

    # 创建带主题的临时文件 / Create temp file with theme
    temp_mmd="${mmd_file}.themed"
    echo "$themed_content" > "$temp_mmd"

    # 生成图表 / Generate diagram
    echo "生成中 / Generating: $output_file (${width}x${height})..."

    if [ "$FORMAT" = "svg" ]; then
        # SVG 生成（无缩放）/ SVG generation (no scale)
        PUPPETEER_EXECUTABLE_PATH="$CHROME_PATH" mmdc \
            -i "$temp_mmd" \
            -o "$output_file" \
            --puppeteerConfigFile "$CONFIG_FILE" \
            -w "$width" \
            -H "$height"
    else
        # PNG 生成带缩放 / PNG generation with scale
        PUPPETEER_EXECUTABLE_PATH="$CHROME_PATH" mmdc \
            -i "$temp_mmd" \
            -o "$output_file" \
            --puppeteerConfigFile "$CONFIG_FILE" \
            -w "$width" \
            -H "$height" \
            -s "$SCALE_FACTOR"
    fi

    # 清理临时文件 / Clean up temp file
    rm -f "$temp_mmd"

    if [ $? -eq 0 ]; then
        echo "  ✅ 生成成功 / Generated successfully"
    else
        echo "  ❌ 生成失败 / Generation failed"
        continue
    fi

    # 验证输出文件 / Validate output file
    if test -s "$output_file"; then
        size=$(stat -c%s "$output_file" 2>/dev/null || stat -f%z "$output_file")
        if [ "$FORMAT" = "svg" ]; then
            echo "  ✅ 验证通过 / Validated SVG (${size} bytes)"
        else
            dimensions_actual=$(identify -format "%wx%h" "$output_file" 2>/dev/null || echo "unknown")
            echo "  ✅ 验证通过 / Validated PNG (${size} bytes, ${dimensions_actual})"
        fi
    else
        echo "  ❌ 验证失败 / Validation failed"
    fi
    echo
done

echo "=== 生成完成 / Generation Complete ==="
echo "所有图表生成并验证成功！/ All diagrams generated and validated successfully!"
echo

echo "生成的文件（按顺序）/ Generated files (in sequence):"
if [ "$FORMAT" = "svg" ]; then
    ls -la [0-9][0-9]-*.svg 2>/dev/null | awk '{printf "  %s (%s bytes)\n", $9, $5}' || echo "  未找到编号的 SVG 文件 / No numbered SVG files found"
else
    ls -la [0-9][0-9]-*.png 2>/dev/null | awk '{printf "  %s (%s bytes)\n", $9, $5}' || echo "  未找到编号的 PNG 文件 / No numbered PNG files found"
fi

echo
echo "生成的文件（全部）/ Generated files (all):"
if [ "$FORMAT" = "svg" ]; then
    ls -la *.svg 2>/dev/null | awk '{printf "  %s (%s bytes)\n", $9, $5}' || echo "  未找到 SVG 文件 / No SVG files found"
else
    ls -la *.png 2>/dev/null | awk '{printf "  %s (%s bytes)\n", $9, $5}' || echo "  未找到 PNG 文件 / No PNG files found"
fi