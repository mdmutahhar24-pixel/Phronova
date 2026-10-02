local dev = {}
local core = require("phronova.core")

local function getSnapshot(projectPath)
    local script = [[
param([string]$ProjectPath)

$files = @()

$main = Join-Path $ProjectPath "main.lua"
if (Test-Path -LiteralPath $main) {
    $files += Get-Item -LiteralPath $main
}

$src = Join-Path $ProjectPath "src"
if (Test-Path -LiteralPath $src) {
    $files += Get-ChildItem -LiteralPath $src -Recurse -File
}

$files |
    Sort-Object FullName |
    ForEach-Object {
        "$($_.FullName)|$($_.Length)|$($_.LastWriteTimeUtc.Ticks)"
    }
]]

    local scriptPath = projectPath .. "\\.phronova-watch.ps1"

    local file = io.open(scriptPath, "w")
    if not file then
        error("Could not create the Phronova watcher script.")
    end

    file:write(script)
    file:close()

    local command =
        'powershell -NoProfile -ExecutionPolicy Bypass -File "' ..
        scriptPath .. '" -ProjectPath "' .. projectPath .. '"'

    local pipe = io.popen(command)
    if not pipe then
        error("Could not start PowerShell.")
    end

    local result = pipe:read("*a")
    pipe:close()

    return result
end

local function notifyReload()
    os.execute(
        'powershell -NoProfile -Command ' ..
        '"Invoke-WebRequest -UseBasicParsing ' ..
        '-Uri http://127.0.0.1:1125/__phronova_reload_trigger ' ..
        '-Method GET | Out-Null"'
    )
end

local function getEvents()
    local pipe = io.popen(
        'powershell -NoProfile -Command ' ..
        '"(Invoke-WebRequest -UseBasicParsing ' ..
        '-Uri http://127.0.0.1:1125/__phronova_events).Content"'
    )

    if not pipe then
        return
    end

    local result = pipe:read("*a")
    pipe:close()

    for eventId in result:gmatch("%d+") do
        core.DispatchEvent(tonumber(eventId))
    end
end

dev.running = true


function dev.watch(projectPath, rebuild)
    print("Watching main.lua and src/ for changes...")
    print("Press Ctrl+C to stop.")

    local previous = getSnapshot(projectPath)
    local lastFileCheck = os.clock()

    while dev.running do
        -- Handle browser events frequently
        getEvents()

        -- Check files only once per second
        if os.clock() - lastFileCheck >= 1 then
            lastFileCheck = os.clock()

            local current = getSnapshot(projectPath)

            if current ~= previous then
                previous = current

                print("\nChanges detected. Rebuilding...")

                local ok, err = pcall(rebuild)

                if ok then
                    print("Rebuild complete!")
                    notifyReload()
                else
                    print("Rebuild failed: " .. tostring(err))
                end
            end
        end
    end
end


return dev