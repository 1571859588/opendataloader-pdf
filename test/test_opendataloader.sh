#!/bin/bash
# OpenDataLoader PDF 测试脚本
# 用法: ./test_opendataloader.sh [fast|hybrid|full]

set -e  # 遇到错误立即退出

# 配置
INPUT_PDF="./pdfs/crop/Aether_Manual_crop.pdf"
FAST_OUTPUT="./test_output_fast"
HYBRID_OUTPUT="./test_output_hybrid"
FULL_OUTPUT="./test_output_full"
PORT=5007

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "检查前置条件..."
    
    # 检查PDF文件
    if [ ! -f "$INPUT_PDF" ]; then
        print_error "PDF文件不存在: $INPUT_PDF"
        exit 1
    fi
    
    # 检查Java
    if ! command -v java &> /dev/null; then
        print_error "Java未安装，请运行: sudo apt-get install openjdk-11-jdk"
        exit 1
    fi
    
    # 检查opendataloader命令
    if ! command -v opendataloader-pdf &> /dev/null; then
        print_error "opendataloader-pdf未安装，请运行: pip install opendataloader-pdf"
        exit 1
    fi
    
    print_success "所有前置条件检查通过"
}

test_fast_mode() {
    print_info "测试Fast模式..."
    
    # 清理旧输出
    rm -rf "$FAST_OUTPUT"
    
    # 运行Fast模式
    opendataloader-pdf "$INPUT_PDF" \
        -o "$FAST_OUTPUT" \
        -f markdown \
        -q
    
    if [ $? -eq 0 ] && [ -f "$FAST_OUTPUT/document.md" ]; then
        print_success "Fast模式测试成功！"
        print_info "输出文件: $FAST_OUTPUT/document.md"
        
        # 显示前10行
        echo -e "\n=== 输出预览（前10行）==="
        head -10 "$FAST_OUTPUT/document.md"
        echo "============================"
    else
        print_error "Fast模式测试失败"
        exit 1
    fi
}

start_hybrid_server() {
    print_info "启动Hybrid服务器 (端口: $PORT)..."
    
    # 停止可能正在运行的服务器
    pkill -f "opendataloader-pdf-hybrid" 2>/dev/null || true
    
    # 启动新服务器
    opendataloader-pdf-hybrid \
        --port $PORT \
        --log-level info \
        --enrich-formula \
        --ocr-lang "ch_sim,en" &
    
    SERVER_PID=$!
    print_info "服务器PID: $SERVER_PID"
    
    # 等待服务器启动
    sleep 12
    
    # 测试服务器连接
    if curl -s "http://localhost:$PORT/ping" > /dev/null; then
        print_success "Hybrid服务器启动成功"
    else
        print_error "Hybrid服务器启动失败"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
}

test_hybrid_mode() {
    print_info "测试Hybrid模式..."
    
    # 清理旧输出
    rm -rf "$HYBRID_OUTPUT"
    
    # 运行Hybrid模式
    opendataloader-pdf "$INPUT_PDF" \
        -o "$HYBRID_OUTPUT" \
        -f markdown \
        --hybrid docling-fast \
        --hybrid-url "http://localhost:$PORT" \
        --hybrid-mode auto \
        --hybrid-fallback
    
    if [ $? -eq 0 ] && [ -f "$HYBRID_OUTPUT/document.md" ]; then
        print_success "Hybrid模式测试成功！"
        print_info "输出文件: $HYBRID_OUTPUT/document.md"
        
        # 比较文件大小
        if [ -f "$FAST_OUTPUT/document.md" ]; then
            fast_size=$(stat -f%z "$FAST_OUTPUT/document.md" 2>/dev/null || stat -c%s "$FAST_OUTPUT/document.md")
            hybrid_size=$(stat -f%z "$HYBRID_OUTPUT/document.md" 2>/dev/null || stat -c%s "$HYBRID_OUTPUT/document.md")
            print_info "Fast输出大小: $fast_size 字节"
            print_info "Hybrid输出大小: $hybrid_size 字节"
        fi
    else
        print_error "Hybrid模式测试失败"
        exit 1
    fi
}

test_full_hybrid_mode() {
    print_info "测试Full Hybrid模式..."
    
    # 清理旧输出
    rm -rf "$FULL_OUTPUT"
    
    # 运行Full Hybrid模式
    opendataloader-pdf "$INPUT_PDF" \
        -o "$FULL_OUTPUT" \
        -f markdown,json \
        --hybrid docling-fast \
        --hybrid-url "http://localhost:$PORT" \
        --hybrid-mode full \
        --hybrid-fallback \
        --detect-strikethrough \
        --include-header-footer
    
    if [ $? -eq 0 ] && [ -f "$FULL_OUTPUT/document.md" ]; then
        print_success "Full Hybrid模式测试成功！"
        print_info "输出文件:"
        ls -la "$FULL_OUTPUT/"
    else
        print_error "Full Hybrid模式测试失败"
        exit 1
    fi
}

cleanup() {
    print_info "清理..."
    
    # 停止服务器
    if [ ! -z "$SERVER_PID" ]; then
        print_info "停止Hybrid服务器 (PID: $SERVER_PID)"
        kill $SERVER_PID 2>/dev/null || true
    fi
    
    print_success "清理完成"
}

main() {
    MODE="${1:-all}"
    
    echo "========================================="
    echo "  OpenDataLoader PDF 测试脚本"
    echo "  输入文件: $INPUT_PDF"
    echo "  测试模式: $MODE"
    echo "========================================="
    
    # 检查前置条件
    check_prerequisites
    
    # 根据模式执行测试
    case "$MODE" in
        "fast")
            test_fast_mode
            ;;
        "hybrid")
            start_hybrid_server
            test_hybrid_mode
            cleanup
            ;;
        "full")
            start_hybrid_server
            test_full_hybrid_mode
            cleanup
            ;;
        "all")
            test_fast_mode
            start_hybrid_server
            test_hybrid_mode
            test_full_hybrid_mode
            cleanup
            ;;
        *)
            print_error "未知模式: $MODE"
            print_info "可用模式: fast, hybrid, full, all"
            exit 1
            ;;
    esac
    
    echo ""
    print_success "所有测试完成！"
    echo ""
    print_info "查看详细文档:"
    echo "  - OpenDataLoader_PDF_使用指南.md (详细说明)"
    echo "  - OpenDataLoader_PDF_快速开始.md (快速上手)"
    echo ""
    print_info "输出文件位置:"
    [ -d "$FAST_OUTPUT" ] && echo "  - Fast模式: $FAST_OUTPUT/document.md"
    [ -d "$HYBRID_OUTPUT" ] && echo "  - Hybrid模式: $HYBRID_OUTPUT/document.md"
    [ -d "$FULL_OUTPUT" ] && echo "  - Full Hybrid模式: $FULL_OUTPUT/document.md"
}

# 捕获Ctrl+C
trap 'print_warning "用户中断"; cleanup; exit 1' INT

# 运行主函数
main "$@"

# 脚本使用说明
cat << EOF

=========================================
脚本使用说明:
=========================================

1. 运行所有测试:
   ./test_opendataloader.sh all

2. 只测试Fast模式:
   ./test_opendataloader.sh fast

3. 只测试Hybrid模式:
   ./test_opendataloader.sh hybrid

4. 测试Full Hybrid模式:
   ./test_opendataloader.sh full

5. 在后台运行服务器:
   opendataloader-pdf-hybrid --port 5002 --enrich-formula &

6. 手动测试命令:
   opendataloader-pdf ./pdfs/crop/Aether_Manual_crop.pdf -o test_output -f markdown

注意事项:
- 确保已安装opendataloader-pdf和Java 11
- 大PDF文件处理需要较长时间和内存
- 使用Ctrl+C中断测试
- 查看生成的markdown文件验证输出质量

=========================================
EOF