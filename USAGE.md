在一个终端激活opendataloader环境：
```bash
conda activate opendataloader
opendataloader-pdf-hybrid --port 5002
```

然后在另一个终端去运行：
```bash
# Batch all files in one call — each invocation spawns a JVM process, so repeated calls are slow
opendataloader-pdf --hybrid docling-fast pdfs/DDR5.pdf output/opendataloader/DDR5
```