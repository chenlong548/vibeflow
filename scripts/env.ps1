# env.ps1 - load a custom LLM endpoint from .env into this toolchain.
# Usage:  . .\scripts\env.ps1
# Then cd to the project and run your agent (e.g. claude).
# .env is not in the repo; copy .env.example to .env first.
$ErrorActionPreference = "Stop"

$root    = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env not found at $envFile. Copy .env.example to .env and set LLM_BASE_URL / LLM_API_KEY / LLM_MODEL."
    exit 1
}

$map = @{}
Get-Content $envFile -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
        $map[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
    }
}

$base  = $map["LLM_BASE_URL"]
$key   = $map["LLM_API_KEY"]
$model = $map["LLM_MODEL"]

if (-not $base -or -not $key -or -not $model) {
    Write-Error "LLM_BASE_URL, LLM_API_KEY and LLM_MODEL are all required in .env."
    exit 1
}

# Map the custom endpoint to the Anthropic-compatible gateway vars this
# toolchain consumes. For OpenAI-compatible models, put an OpenAI->Anthropic
# gateway URL in LLM_BASE_URL.
$env:ANTHROPIC_BASE_URL             = $base
$env:ANTHROPIC_AUTH_TOKEN           = $key
$env:ANTHROPIC_MODEL                = $model
$env:ANTHROPIC_DEFAULT_OPUS_MODEL   = if ($map["LLM_OPUS_MODEL"])    { $map["LLM_OPUS_MODEL"]    } else { $model }
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = if ($map["LLM_SONNET_MODEL"])  { $map["LLM_SONNET_MODEL"]  } else { $model }
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL  = if ($map["LLM_HAIKU_MODEL"])   { $map["LLM_HAIKU_MODEL"]   } else { $model }
$env:CLAUDE_CODE_SUBAGENT_MODEL     = if ($map["LLM_SUBAGENT_MODEL"]) { $map["LLM_SUBAGENT_MODEL"] } else { $model }

if ($map["LLM_EFFORT"]) { $env:CLAUDE_CODE_EFFORT_LEVEL = $map["LLM_EFFORT"] }

Write-Host "LLM endpoint ready:" -ForegroundColor Green
Write-Host "  BASE_URL = $env:ANTHROPIC_BASE_URL"
Write-Host "  MODEL    = $env:ANTHROPIC_MODEL"
Write-Host "Next: cd to the project and run your agent." -ForegroundColor Cyan
