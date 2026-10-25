# Sets up LibTameable's development tools on Windows, all inside .lua\ in the repository (gitignored),
# so nothing outside the repository changes and no PATH edit is needed:
#
# - Lua 5.1.5, built by hererocks with Visual Studio's C compiler (the C build tools must be
#   installed; Python provides hererocks);
# - LuaRocks, the standalone Windows build, with its config in .lua\config-5.1.lua;
# - the pinned test rocks from libtameable-dev-1.rockspec (busted, luacov, ...), compiled with the
#   same compiler as Lua;
# - StyLua, the release binary.
#
# Safe to run again: each step is skipped when its result is already there. Afterwards, in a new
# PowerShell, `.lua\bin\activate.ps1` puts the tools on PATH for that session, or call
# `.lua\bin\lua.exe tests\check.lua` directly.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$lua = Join-Path $root ".lua"
$bin = Join-Path $lua "bin"
$LuaRocksVersion = "3.13.0"
$StyLuaVersion = "2.6.0"

# The 64-bit C compiler environment from the newest Visual Studio with the C++ tools.
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw "Visual Studio with the C++ build tools is needed to build Lua and the rocks." }
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"

if (-not (Test-Path (Join-Path $bin "lua.exe"))) {
    python -m pip install --user --quiet hererocks
    python -m hererocks $lua -l 5.1 --target vs
}

$luarocks = Join-Path $bin "luarocks.exe"
if (-not (Test-Path $luarocks)) {
    $tmp = New-Item -ItemType Directory -Path (Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid()))
    $zip = Join-Path $tmp "luarocks.zip"
    Invoke-WebRequest "https://luarocks.github.io/luarocks/releases/luarocks-$LuaRocksVersion-windows-64.zip" -OutFile $zip
    Expand-Archive $zip -DestinationPath $tmp
    Copy-Item (Join-Path $tmp "luarocks-$LuaRocksVersion-windows-64\luarocks.exe") $bin
    Remove-Item -Recurse -Force $tmp
}

# LuaRocks reads this file instead of the user's own config (LUAROCKS_CONFIG), so the rocks
# install into .lua\ and build against its headers.
$config = Join-Path $lua "config-5.1.lua"
$luaForward = $lua -replace "\\", "/"
Set-Content -Encoding ascii $config @"
lua_version = "5.1"
lua_interpreter = "lua.exe"
rocks_trees = { { name = "libtameable", root = "$luaForward" } }
variables = {
    LUA = "$luaForward/bin/lua.exe",
    LUA_DIR = "$luaForward",
    LUA_BINDIR = "$luaForward/bin",
    LUA_INCDIR = "$luaForward/include",
    LUA_LIBDIR = "$luaForward/lib",
}
"@
$env:LUAROCKS_CONFIG = $config
cmd /c "call `"$vcvars`" >nul && `"$luarocks`" install --only-deps `"$root\libtameable-dev-1.rockspec`""
if ($LASTEXITCODE -ne 0) { throw "luarocks install failed" }

if (-not (Test-Path (Join-Path $bin "stylua.exe"))) {
    $tmp = New-Item -ItemType Directory -Path (Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid()))
    $zip = Join-Path $tmp "stylua.zip"
    Invoke-WebRequest "https://github.com/JohnnyMorganz/StyLua/releases/download/v$StyLuaVersion/stylua-windows-x86_64.zip" -OutFile $zip
    Expand-Archive $zip -DestinationPath $bin
    Remove-Item -Recurse -Force $tmp
}

Write-Host "Done. Run: .lua\bin\lua.exe tests\check.lua"
