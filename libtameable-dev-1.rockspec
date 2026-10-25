-- Development dependencies only: the test tools, pinned. LibTameable itself is not a rock.
-- `luarocks install --only-deps libtameable-dev-1.rockspec` installs them, locally
-- (tests/setup-lua.ps1) and in CI alike.
rockspec_format = "3.0"
package = "libtameable"
version = "dev-1"
source = { url = "git+https://github.com/Langmans/LibTameable-1.0.git" }
description = { summary = "LibTameable's test tooling", license = "GPL-3.0-or-later" }
dependencies = {
    "lua ~> 5.1",
    "busted == 2.2.0",
    "luacov == 0.17.0",
    "luacov-reporter-lcov == 0.2",
}
build = { type = "builtin", modules = {} }
