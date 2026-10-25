-- busted output: the usual terminal report, and with `--Xoutput <file>` also a JUnit report in
-- that file, which CI hands to GitHub so failed tests show up on the run and the pull request.
return function(options)
    local terminalOptions = {}
    for key, value in pairs(options) do
        terminalOptions[key] = value
    end
    -- The terminal handler reads its own flags from the arguments; the file name is not one.
    terminalOptions.arguments = {}
    local terminal = require("busted.outputHandlers.utfTerminal")(terminalOptions)
    if type(options.arguments) == "table" and options.arguments[1] then
        require("busted.outputHandlers.junit")(options)
    end
    return terminal
end
