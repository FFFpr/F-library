# Idempotent Windows counterpart of install-skill-tools.sh.
# Cloud Agents use the .sh script; run this locally on Windows.
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$Req = Join-Path $Root ".cursor\scripts\requirements-skill-tools.txt"
$Venv = Join-Path $Root ".venv"
$PythonBin = Join-Path $Venv "Scripts\python.exe"

function Log([string]$Message) {
    Write-Host "[install-skill-tools] $Message"
}

$python3 = Get-Command python -ErrorAction SilentlyContinue
if (-not $python3) {
    throw "python is required on PATH"
}

Log "base interpreter: $($python3.Source)"
if (-not (Test-Path -LiteralPath $PythonBin)) {
    Log "creating venv at $Venv"
    & $python3.Source -m venv $Venv
} else {
    Log "reusing venv at $Venv"
}

& $PythonBin -m pip install -U pip
if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed" }
& $PythonBin -m pip install -r $Req
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

Log "verifying skill imports"
& $PythonBin -c @"
import ebooklib
import pymupdf
from rapidocr_onnxruntime import RapidOCR
print('pymupdf', pymupdf.version)
print('ebooklib ok')
ocr = RapidOCR()
print('RapidOCR ready', type(ocr).__name__)
"@
if ($LASTEXITCODE -ne 0) { throw "import verify failed" }

Log "done; use $PythonBin"
