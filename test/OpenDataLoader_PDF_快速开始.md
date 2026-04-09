# OpenDataLoader PDF 快速开始

## 一句话说明
OpenDataLoader PDF 是一个强大的PDF解析工具，支持Fast和Hybrid两种模式，能提取文字、表格、图片等内容到多种格式。

## 🚀 极速入门

### 1. 安装准备

```bash
# 1. 激活conda环境
conda activate opendataloader

# 2. 安装基础包
pip install opendataloader-pdf

# 3. 系统依赖
sudo apt-get install openjdk-11-jdk

# 4. 代理设置（可选，国内用户）
export https_proxy=http://127.0.0.1:7890
```

### 2. Fast模式（5分钟上手）

```bash
# 最简单的命令
opendataloader-pdf 你的文件.pdf -o 输出目录 -f markdown

# 真实示例
opendataloader-pdf pdfs/crop/Aether_Manual_crop.pdf \
  -o my_output \
  -f markdown
```

### 3. Hybrid模式（高级功能）

```bash
# 第一步：启动服务器（新终端）
opendataloader-pdf-hybrid --port 5002 &
# 等待5秒让服务器启动

# 第二步：处理PDF（原终端）
opendataloader-pdf pdfs/crop/Aether_Manual_crop.pdf \
  -o hybrid_output \
  -f markdown \
  --hybrid docling-fast \
  --hybrid-url http://localhost:5002
```

## 📁 输入输出

### 输入文件
- 单个PDF文件（支持加密）
- 路径可以是绝对路径或相对路径
- 示例：`pdfs/crop/Aether_Manual_crop.pdf`

### 输出目录
```
hybrid_output/
├── document.md          # Markdown格式（推荐）
├── document.txt         # 纯文本
├── document.json        # 结构化JSON
├── images/              # 提取的图片
└── metadata.json        # 文档信息
```

## 🎯 常用命令

### 1. 基本提取
```bash
opendataloader-pdf input.pdf -o output -f markdown
```

### 2. 指定页码
```bash
opendataloader-pdf input.pdf -o output --pages "1-10,15-20"
```

### 3. 多种格式输出
```bash
opendataloader-pdf input.pdf -o output -f "markdown,json,text"
```

### 4. Hybrid模式（带中文OCR）
```bash
# 启动服务器
opendataloader-pdf-hybrid --port 5002 --ocr-lang "ch_sim,en" &

# 提取PDF
opendataloader-pdf input.pdf -o output --hybrid docling-fast
```

## 🔧 配置说明

### 环境变量
```bash
# 代理（国内用户）
export https_proxy=http://127.0.0.1:7890

# 模型缓存
export TRANSFORMERS_CACHE=/path/to/cache
export HUGGINGFACE_HUB_CACHE=/path/to/cache

# 性能优化
export NUMEXPR_MAX_THREADS=8
```

### 参数速查
| 参数 | 简写 | 说明 |
|------|------|------|
| `--output-dir` | `-o` | 输出目录 |
| `--formats` | `-f` | 输出格式 |
| `--hybrid` | 无 | 启用Hybrid模式 |
| `--pages` | 无 | 指定页码范围 |
| `--quiet` | `-q` | 静默模式 |

## 🐛 常见问题

### Q1: 安装失败怎么办？
```bash
# 1. 降级numpy
pip install "numpy<2" --force-reinstall

# 2. 检查Java
java -version  # 应该是OpenJDK 11+

# 3. 重新安装
pip uninstall opendataloader-pdf -y
pip install opendataloader-pdf
```

### Q2: 下载模型太慢？
```bash
# 设置代理
export https_proxy=http://127.0.0.1:7890

# 使用镜像
export HF_ENDPOINT=https://hf-mirror.com
```

### Q3: 内存不足？
```bash
# 1. 分批处理
opendataloader-pdf large.pdf --pages "1-50" -o part1
opendataloader-pdf large.pdf --pages "51-100" -o part2

# 2. 增加系统内存
sudo sysctl vm.overcommit_memory=1
```

### Q4: Hybrid服务器启动失败？
```bash
# 检查端口占用
lsof -i:5002

# 使用不同端口
opendataloader-pdf-hybrid --port 5003
```

## ⚡ 性能技巧

### 1. 批量处理
```bash
# 创建批处理脚本
for file in pdfs/*.pdf; do
  filename=$(basename "$file" .pdf)
  opendataloader-pdf "$file" -o "output/$filename" -f markdown -q &
done
wait
```

### 2. 优化输出
```bash
# 只导出需要的内容
opendataloader-pdf document.pdf \
  -o optimized_output \
  -f markdown \
  --pages "1-20" \
  --detect-strikethrough
```

### 3. 监控性能
```bash
# 查看处理时间
time opendataloader-pdf large.pdf -o output -q
```

## 📞 获取帮助

### 查看帮助
```bash
# 查看所有参数
opendataloader-pdf --help

# 查看hybrid帮助
opendataloader-pdf-hybrid --help
```

### 调试模式
```bash
# 显示详细日志
opendataloader-pdf document.pdf -o debug_output --verbose

# 服务器调试日志
opendataloader-pdf-hybrid --port 5002 --log-level debug
```

## 🎉 成功标志

如果看到以下输出，说明成功：

```bash
# Fast模式成功
Processing complete! Output saved to: my_output/document.md

# Hybrid模式成功
2026-04-08 17:28:31,081 - INFO - Starting Docling Fast Server on http://0.0.0.0:5002
Processing with hybrid backend... Done!
```

## 📚 了解更多

- 详细文档：查看项目目录下的 `OpenDataLoader_PDF_使用指南.md`
- 官方文档：https://github.com/opendataloader-project/opendataloader-pdf
- Git子模块：项目已包含opendataloader-pdf作为子模块

---
*开始使用吧！从 `opendataloader-pdf --help` 探索更多功能*