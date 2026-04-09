# OpenDataLoader PDF 使用指南

本文档详细说明如何在项目中配置和使用OpenDataLoader PDF解析工具。

## 目录
1. [环境要求](#环境要求)
2. [快速开始](#快速开始)
3. [安装配置](#安装配置)
4. [使用模式](#使用模式)
5. [参数详解](#参数详解)
6. [输入输出说明](#输入输出说明)
7. [常见问题](#常见问题)
8. [性能调优](#性能调优)

## 环境要求

### 基础环境
- **操作系统**: Linux/Windows/macOS
- **Python**: 3.9+
- **Java**: OpenJDK 11+

### 硬件要求
- **内存**: 至少4GB（处理大型PDF需要8GB+）
- **存储**: 1GB可用空间（用于模型缓存）
- **GPU**: 可选，但不必须。有GPU可提升速度和某些模型性能

### 网络要求
- 可以访问GitHub和Hugging Face（用于下载模型）
- 如需加速，可配置代理（详见[代理设置](#代理设置)）

## 快速开始

### 1. 环境准备

```bash
# 克隆项目（已经作为子模块包含）
git submodule update --init --recursive

# 或手动克隆
git clone https://github.com/opendataloader-project/opendataloader-pdf.git packages/data_platform/external_tools/opendataloader-pdf
```

### 2. 安装依赖

```bash
# 创建conda环境（推荐）
conda create -n opendataloader python=3.11
conda activate opendataloader

# 安装基础包
pip install opendataloader-pdf

# 安装hybrid模式（可选，包含更多功能）
pip install "opendataloader-pdf[hybrid]"

# 降级numpy解决兼容性问题
pip install "numpy<2" --force-reinstall
```

### 3. 系统依赖

```bash
# Linux系统
sudo apt-get update
sudo apt-get install openjdk-11-jdk
```

## 安装配置

### 代理设置（国内用户）

如果下载速度慢，可以设置代理：

```bash
# 临时设置（当前会话有效）
export https_proxy=http://127.0.0.1:7890 
export http_proxy=http://127.0.0.1:7890
export ALL_PROXY=http://127.0.0.1:7890

# 永久设置（添加到~/.bashrc或~/.zshrc）
echo 'export https_proxy=http://127.0.0.1:7890' >> ~/.bashrc
echo 'export http_proxy=http://127.0.0.1:7890' >> ~/.bashrc
source ~/.bashrc
```

## 使用模式

OpenDataLoader PDF支持三种主要模式：

### 1. Fast模式（默认）
- 使用Java Tesseract OCR
- 无需启动额外服务
- 适合普通文档

```bash
# 基本用法
opendataloader-pdf 输入文件.pdf -o 输出目录 -f markdown

# 示例
opendataloader-pdf pdfs/crop/Aether_Manual_crop.pdf \
  -o output_fast \
  -f markdown \
  -q  # 静默模式
```

### 2. Hybrid模式（推荐）
- 结合Python Docling后端
- 支持高级功能（公式识别、图片描述）
- 需要启动服务器

```bash
# 第一步：启动服务器
export https_proxy=http://127.0.0.1:7890  # 如果需要
opendataloader-pdf-hybrid --port 5002 &

# 第二步：处理PDF
opendataloader-pdf pdfs/crop/Aether_Manual_crop.pdf \
  -o output_hybrid \
  -f markdown \
  --hybrid docling-fast \
  --hybrid-url http://localhost:5002 \
  --hybrid-mode auto
```

### 3. Full Hybrid模式
- 跳过智能triage
- 所有页面都使用hybrid处理
- 更彻底但速度稍慢

```bash
# 完整命令示例
opendataloader-pdf-hybrid \
  --port 5007 \
  --host 0.0.0.0 \
  --enrich-formula \
  --enrich-picture-description \
  --ocr-lang "ch_sim,en" &

# 等待服务器启动
sleep 5

# 处理PDF
opendataloader-pdf pdfs/crop/Aether_Manual_crop.pdf \
  -o output_full \
  -f markdown \
  --hybrid docling-fast \
  --hybrid-url http://localhost:5007 \
  --hybrid-mode full \
  --hybrid-fallback \
  --detect-strikethrough
```

## 参数详解

### 基础参数
| 参数 | 说明 | 示例 |
|------|------|------|
| `-o, --output-dir` | 输出目录 | `-o ./results` |
| `-f, --formats` | 输出格式 | `-f markdown,text` |
| `--pages` | 指定页码范围 | `--pages 1-5,10` |
| `-q, --quiet` | 静默模式 | `-q` |

### Hybrid模式参数
| 参数 | 说明 | 示例 |
|------|------|------|
| `--hybrid` | Hybrid后端类型 | `--hybrid docling-fast` |
| `--hybrid-url` | 服务器URL | `--hybrid-url http://localhost:5002` |
| `--hybrid-mode` | 处理模式 | `--hybrid-mode auto/full` |
| `--hybrid-fallback` | 失败时回退 | `--hybrid-fallback` |

### 服务器参数
| 参数 | 说明 | 示例 |
|------|------|------|
| `--port` | 服务器端口 | `--port 5002` |
| `--enrich-formula` | 启用公式识别 |  |
| `--enrich-picture-description` | 启用图片描述 |  |
| `--ocr-lang` | OCR语言 | `--ocr-lang ch_sim,en` |

## 输入输出说明

### 输入文件
- **格式**: PDF文件（支持加密PDF）
- **大小**: 理论上无限制，但大文件处理需要更多内存
- **语言**: 支持多语言，中文推荐使用`--ocr-lang ch_sim,en`

### 输出文件
默认情况下，工具会在输出目录创建以下文件：

```
输出目录/
├── document.md          # Markdown格式的文档内容
├── document.txt         # 纯文本格式
├── document.json        # JSON结构化数据
├── images/              # 提取的图片
│   ├── image_1.png
│   └── ...
└── metadata.json        # 文档元数据
```

### 输出格式

#### 1. Markdown格式（推荐）
- 保留文档结构
- 支持表格、图片链接
- 可读性最好

#### 2. JSON格式
- 结构化数据
- 包含详细的文档信息
- 适合程序处理

#### 3. 纯文本格式
- 简单的文本内容
- 去除所有格式
- 最小化输出

## 常见问题

### 1. 权限问题
```bash
# 如果遇到权限错误
chmod +x $(which opendataloader-pdf)
```

### 2. 模型下载慢
```bash
# 设置环境变量加速
export HF_ENDPOINT=https://hf-mirror.com
export HF_HUB_ENABLE_HF_TRANSFER=1
```

### 3. 内存不足
```bash
# 限制处理页数
opendataloader-pdf large.pdf --pages 1-10 -o output

# 增加系统内存
sudo sysctl vm.overcommit_memory=1
```

### 4. Hybrid服务器启动失败
```bash
# 检查端口占用
lsof -i:5002

# 使用不同端口
opendataloader-pdf-hybrid --port 5003
```

## 性能调优

### 1. 并行处理
```bash
# 设置线程数（服务器端）
export NUMEXPR_MAX_THREADS=8

# 批量处理多个文件
for pdf in pdfs/*.pdf; do
  opendataloader-pdf "$pdf" -o "output/$(basename $pdf .pdf)" &
done
wait
```

### 2. 缓存配置
```bash
# 设置模型缓存目录
export TRANSFORMERS_CACHE=/path/to/cache
export HUGGINGFACE_HUB_CACHE=/path/to/cache
```

### 3. 输出优化
```bash
# 只提取特定内容
opendataloader-pdf document.pdf \
  -o output \
  -f markdown \
  --pages 1-20 \
  --include-header-footer
```

### 4. 性能监控
```bash
# 查看处理进度
opendataloader-pdf document.pdf -o output --verbose

# 内存使用监控
/usr/bin/time -v opendataloader-pdf document.pdf -o output
```

## 进阶用法

### 1. 集成到Python代码

```python
import subprocess
import json

def extract_pdf_to_markdown(pdf_path, output_dir):
    """使用opendataloader-pdf提取PDF到Markdown"""
    cmd = [
        'opendataloader-pdf',
        pdf_path,
        '-o', output_dir,
        '-f', 'markdown',
        '--hybrid', 'docling-fast',
        '--hybrid-url', 'http://localhost:5002'
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        with open(f'{output_dir}/document.md', 'r', encoding='utf-8') as f:
            return f.read()
    else:
        raise Exception(f'提取失败: {result.stderr}')
```

### 2. Docker容器使用

```bash
# 构建镜像
docker build -t opendataloader-pdf .

# 运行容器
docker run -it --rm \
  -v $(pwd)/pdfs:/pdfs \
  -v $(pwd)/output:/output \
  opendataloader-pdf \
  opendataloader-pdf /pdfs/document.pdf -o /output -f markdown
```

### 3. 批处理脚本

```bash
#!/bin/bash
# batch_process.sh

INPUT_DIR="pdfs"
OUTPUT_DIR="output"
PORT=5002

# 启动服务器
opendataloader-pdf-hybrid --port $PORT &
SERVER_PID=$!
sleep 10

# 处理所有PDF
for pdf in "$INPUT_DIR"/*.pdf; do
    if [ -f "$pdf" ]; then
        filename=$(basename "$pdf" .pdf)
        echo "处理: $filename.pdf"
        
        opendataloader-pdf "$pdf" \
            -o "$OUTPUT_DIR/$filename" \
            -f markdown \
            --hybrid docling-fast \
            --hybrid-url "http://localhost:$PORT" \
            --quiet
    fi
done

# 停止服务器
kill $SERVER_PID
```

## 故障排除

### 查看详细日志
```bash
opendataloader-pdf document.pdf -o output --verbose 2>&1 | tee process.log

# Hybrid服务器日志
opendataloader-pdf-hybrid --port 5002 --log-level debug 2>&1 | tee server.log
```

### 检查依赖
```bash
# 检查Java
java -version

# 检查Python包
pip list | grep -E "opendataloader|docling"

# 检查模型文件
ls -la ~/.cache/huggingface/hub/
```

## 最佳实践

1. **预处理PDF**: 对于扫描件，先用其他工具优化质量
2. **分页处理**: 大文件分段处理，避免内存不足
3. **结果验证**: 处理完成后检查输出质量
4. **定期更新**: 保持opendataloader-pdf版本最新
5. **备份配置**: 保存成功的工作配置供复用

## 更多资源

- [官方文档](https://github.com/opendataloader-project/opendataloader-pdf)
- [GitHub Issues](https://github.com/opendataloader-project/opendataloader-pdf/issues)
- [Discord社区](https://discord.gg/opendataloader)

---
*文档更新日期: 2026-04-08*
*版本: OpenDataLoader PDF 2.2.1*