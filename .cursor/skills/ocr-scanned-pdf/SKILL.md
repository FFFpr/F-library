---
name: ocr-scanned-pdf
description: OCR scanned or image-only PDFs via local pymupdf + RapidOCR (the same Shell steps used on 美的历程). Use when the user has a scan PDF, image PDF, no text layer, photographed pages, Chinese OCR, English OCR, 扫描件, or asks to extract text without reading a large PDF binary.
---

# OCR Scanned PDF

把扫描件抽成文本。照下面这套**已经跑通过**的步骤在 Shell 里做即可：不要往本 skill 加 `scripts/`，也不要把大体量 PDF 用 Read 打开（约 50 MB 上限）。

本 skill 只抽文字。写读书笔记走 `book-summarizer`。

**中文 OCR / 英文 OCR 由用户指定。** 没说就先问，禁止自行开扫全书。

## Interpreter

优先用仓库 `.venv`（Cloud Agent Build 会装好）：

- Linux / Cloud: `.venv/bin/python`
- Windows: `.venv\Scripts\python.exe`

若 `import pymupdf` 或 `from rapidocr_onnxruntime import RapidOCR` 失败，先跑安装脚本，不要在任务里临时 `pip install`：

```bash
bash .cursor/scripts/install-skill-tools.sh
```

Windows 本地：`powershell -File .cursor/scripts/install-skill-tools.ps1`

## What already worked

《美的历程》：58 MB / 225 页，无文字层，每页一张整图。本机 `pymupdf` + `rapidocr-onnxruntime`，默认中文识别。先抽查几页，再全书循环，已有 `page_NNN.txt` 则跳过。识别在本机，不耗对话 token。

## Language

| 用户指定 | 做法 |
|----------|------|
| 中文 OCR | `RapidOCR()` 默认中文模型（可夹杂数字和少量英文） |
| 英文 OCR | 有英文 rec `.onnx` 再传给 RapidOCR；没有则先说明，再问是否仍用默认模型 |

中英混排、汉字为主 → 中文。整页英文 → 英文。

## Steps

```
Task Progress:
- [ ] 1. Confirm PDF exists. Do not Read() the binary if large
- [ ] 2. Resolve zh vs en
- [ ] 3. Probe text layer
- [ ] 4. OCR a few sample pages; stop if garbage
- [ ] 5. Same loop for all pages; concatenate full.txt
- [ ] 6. Delete one-off temp files after use
```

**探测文字层**（几乎无字 + 有图 → 扫描件；有字则直接 `gettext` / `get_text`，不要 OCR）：

```python
import pymupdf
doc = pymupdf.open(r"PDF")
print(doc.page_count, doc.metadata)
for i in [0, 1, 7]:
    p = doc[i]
    print(i+1, len(p.get_text().strip()), len(p.get_images()))
```

**抽查 / 全书 OCR**（灰度、1.2 倍渲染；有嵌入图可先 `extract_image`）：

```python
from pathlib import Path
import pymupdf
from rapidocr_onnxruntime import RapidOCR

pdf, out = Path(r"PDF"), Path(r"OUT")
out.mkdir(parents=True, exist_ok=True)
ocr, doc = RapidOCR(), pymupdf.open(pdf)
for i in range(doc.page_count):          # 抽查时改成几个页码
    dest = out / f"page_{i+1:03d}.txt"
    if dest.exists() and dest.stat().st_size > 0:
        continue
    page = doc[i]
    imgs = page.get_images()
    if imgs:
        img = doc.extract_image(imgs[0][0])["image"]
    else:
        pix = page.get_pixmap(matrix=pymupdf.Matrix(1.2, 1.2), colorspace=pymupdf.csGRAY)
        img = pix.tobytes("png")
    result, _ = ocr(img)
    dest.write_text("\n".join(item[1] for item in result) if result else "", encoding="utf-8")
```

页数多时可把这段写成**任务目录下的一次性临时文件**，跑完立刻删。不要放进本 skill。

最后把 `page_*.txt` 拼成 `full.txt`。抽查失败：说明原因后停止。不换源、不靠记忆补全文、不改原 PDF。

## Do not

- 不要在本 skill 目录新增脚本
- 不要把每一页图交给视觉模型当主路径
- 不要对 >40 MB 的 PDF 使用 Read
