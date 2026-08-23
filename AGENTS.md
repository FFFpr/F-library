# F-library

Book and video notes live under `docs/`. Skills live under `.cursor/skills/`.

## Cursor Cloud specific instructions

The environment Build runs `bash .cursor/scripts/install-skill-tools.sh` (see `.cursor/environment.json`). That creates `.venv` and installs `pymupdf`, `rapidocr-onnxruntime`, and `ebooklib`.

- Prefer `.venv/bin/python` for OCR / PDF / EPUB. Do not `pip install` these ad-hoc unless an import fails; then rerun the install script.
- Write notes to repo-relative `docs/book/` and `docs/video/`. Do not write to `~/.cursor/docs`.
- `ocr-scanned-pdf` still forbids adding scripts inside that skill directory; the install script is the shared toolchain.
