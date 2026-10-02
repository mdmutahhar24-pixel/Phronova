local scriptPath = debug.getinfo(1, "S").source:sub(2)

local core = require("phronova.core")
local fname = arg[4]
local installDir = arg[1]
local originalDir = arg[2]

local pageBuilder = require("phronova.pages")

pageBuilder.setInstallDirectory(arg[1])
local dev = require("phronova.dev")
local terminal = require("phronova.terminal")

os.execute("chcp 65001 >nul")

local function ensureDirectory(path)
    os.execute(
        'mkdir "' .. path .. '" 2>nul'
    )
end

local function startHiddenServer(
    serverPath,
    generatedPath,
    cssPath
)
    local command =
        'powershell -NoProfile -Command ' ..
        '"$p = Start-Process ' ..
        '-FilePath \"' .. serverPath .. '\" ' ..
        '-ArgumentList \"' .. generatedPath .. '\",\"' .. cssPath .. '\" ' ..
        '-WindowStyle Hidden ' ..
        '-PassThru; ' ..
        'Write-Output $p.Id"'

    local pipe =
        io.popen(command)

    if not pipe then
        error("Could not start Phronova web server")
    end

    local pid =
        pipe:read("*a")

    pipe:close()

    pid = tonumber(
        pid:match("%d+")
    )

    if not pid then
        error("Could not determine web server process ID")
    end

    return pid
end


local function stopServer(pid)
    if not pid then
        return
    end

    os.execute(
        'taskkill /PID ' ..
        tostring(pid) ..
        ' /T /F >nul 2>&1'
    )
end

local function copyDirectory(source, destination)
    local command =
        'xcopy "' ..
        source ..
        '" "' ..
        destination ..
        '" /E /I /Y /Q >nul'

    local success =
        os.execute(command)

    if not success then
        error(
            "Could not copy Phronova starter template"
        )
    end
end

local function createConfig(
    projectPath,
    cssFramework
)
    local configPath =
        projectPath ..
        "\\phronova.config.lua"

    local file =
        io.open(configPath, "w")

    if not file then
        error(
            "Could not create phronova.config.lua"
        )
    end

    file:write(
        "return {\n" ..
        '    css = "' ..
        cssFramework ..
        '",\n' ..
        '    favicon = "src/favicon.ico"\n' ..
        "}\n"
    )

    file:close()
end

if arg[3] == "create" then

    local projectName =
        arg[4]

    if not projectName then
        error(
            "Please provide a project name.\n" ..
            "Example: phronova create MyApp"
        )
    end

    local cssFramework =
        "custom"

    if arg[5] == "--tailwind" then
        cssFramework = "tailwind"

    elseif arg[5] == "--bootstrap" then
        cssFramework = "bootstrap"

    elseif arg[5] == "--custom" or not arg[5] then
        cssFramework = "custom"

    else
        error(
            "Unknown CSS option: " ..
            tostring(arg[5]) ..
            "\n\n" ..
            "Available options:\n" ..
            "  --custom\n" ..
            "  --tailwind\n" ..
            "  --bootstrap"
        )
    end

    local projectPath =
        originalDir ..
        "\\" ..
        projectName

    local templatePath =
        installDir ..
        "\\templates\\default"

    terminal:header(
        "CREATING PHRONOVA PROJECT"
    )

    print(
        "    · Project: [" ..
        projectName ..
        "]"
    )

    print(
        "    · CSS: [" ..
        cssFramework ..
        "]"
    )

    print(
        "    · Creating starter..."
    )

    ensureDirectory(projectPath)

    copyDirectory(
        templatePath,
        projectPath
    )

    createConfig(
        projectPath,
        cssFramework
    )

    terminal:done()

    print("")
    print(
        "    Project created successfully!"
    )
    print("")

    return
elseif arg[3] == "run" then

    local fullPath =
        originalDir .. "/" .. fname

    local sep =
        package.config:sub(1, 1)

    package.path =
        fullPath .. sep .. "?.lua;" ..
        fullPath .. sep .. "?" .. sep .. "init.lua;" ..
        installDir .. sep .. "?.lua;" ..
        installDir .. sep .. "?" .. sep .. "init.lua;" ..
        package.path


    package.loaded["main"] = nil

    local layout =
        require("main")


    if arg[5] == "--website" then

        terminal:header("run")

        terminal:info(
            "Project: [" .. fname .. "]"
        )

        terminal:info(
            "Building website..."
        )

        pageBuilder.build(
            fullPath,
            layout,
            "website"
        )

        terminal:success(
            "Pages generated"
        )


        local serverPath =
            installDir .. sep ..
            "runtime" .. sep ..
            "server" .. sep ..
            "server.exe"

        local generatedPath =
            fullPath .. sep ..
            "generated"

        local cssPath =
            fullPath .. sep ..
            "src" .. sep ..
            "style.css"

        local serverPid =
            startHiddenServer(
                serverPath,
                generatedPath,
                cssPath
            )

        terminal:success(
            "Web server started"
        )

        print()

        print(
            "    Web Server: " ..
            "http://127.0.0.1:1125/"
        )

        print()

        os.execute(
            'start "" "http://127.0.0.1:1125/"'
        )

        local cleanup = function()
            stopServer(serverPid)
        end
        
        local ok =
            pcall(function()

                dev.watch(fullPath, function()

                    package.loaded["main"] = nil
                    package.loaded["src.components"] = nil

                    local layout =
                        require("main")

                    pageBuilder.build(
                        fullPath,
                        layout,
                        "website"
                    )

                end)

            end)

        stopServer(serverPid)

    elseif arg[5] == "--desktop" then

        terminal:header("run")

        terminal:info(
            "Project: [" .. fname .. "]"
        )

        terminal:info(
            "Building desktop application..."
        )

        pageBuilder.build(
            fullPath,
            layout,
            "desktop"
        )

        local generatedPath =
            fullPath .. sep ..
            "generated"

        terminal:success(
            "Pages generated"
        )

        local serverPath =
            installDir .. sep ..
            "runtime" .. sep ..
            "server" .. sep ..
            "server.exe"

        local cssPath =
            fullPath .. sep ..
            "src" .. sep ..
            "style.css"

        local serverPid =
            startHiddenServer(
                serverPath,
                generatedPath,
                cssPath
            )

        local windowPath =
            installDir .. sep ..
            "runtime" .. sep ..
            "webview" .. sep ..
            "window.exe"

        terminal:info(
            "Starting WebView2..."
        )

        os.execute(
            'start "" "' ..
            windowPath ..
            '" "http://127.0.0.1:1125/"'
        )

        terminal:success(
            "Desktop application started"
        )


        dev.watch(fullPath, function()

            package.loaded["main"] = nil
            package.loaded["src.components"] = nil

            local layout =
                require("main")

            pageBuilder.build(
                fullPath,
                layout,
                "desktop"
            )

        end)

    else

        error(
            "Platform not provided"
        )

    end

else

    print(scriptPath)

end