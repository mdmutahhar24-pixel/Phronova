local core = require("phronova.core")

local pages = {}

--------------------------------------------------
-- Paths
--------------------------------------------------

local scriptPath =
    debug.getinfo(1, "S").source:sub(2)

local phronovaDirectory =
    scriptPath:match("^(.*)[\\/]")

local core = require("phronova.core")

local pages = {}

local installDirectory

function pages.setInstallDirectory(directory)
    installDirectory =
        directory:gsub("[\\/]+$", "")
end
--------------------------------------------------
-- Utilities
--------------------------------------------------

local function normalize(path)
    return path
        :gsub("/", "\\")
        :gsub("\\+$", "")
end

local function readFiles(directory)
    local files = {}

    local command =
        'dir /s /b /a-d "' ..
        directory ..
        '\\*.lua"'

    local pipe = io.popen(command)

    if not pipe then
        return files
    end

    for file in pipe:lines() do
        files[#files + 1] =
            normalize(file)
    end

    pipe:close()

    return files
end

local function readFile(path)
    local file =
        io.open(path, "r")

    if not file then
        return nil
    end

    local contents =
        file:read("*a")

    file:close()

    return contents
end

local function writeFile(path, contents)
    local file =
        io.open(path, "w")

    if not file then
        return false
    end

    file:write(contents)
    file:close()

    return true
end

local function copyFile(source, destination)
    local contents =
        readFile(source)

    if not contents then
        return false
    end

    return writeFile(
        destination,
        contents
    )
end

local function ensureDirectory(path)
    os.execute(
        'mkdir "' .. path .. '" 2>nul'
    )
end

local function preparePublic(
    projectPath,
    generatedDirectory
)
    local publicDirectory =
        projectPath .. "\\public"

    print(
        "Public directory: " ..
        publicDirectory
    )

    local command =
        'xcopy "' ..
        publicDirectory ..
        '\\*" "' ..
        generatedDirectory ..
        '\\" /E /I /Y'

    print(
        "Copy command: " ..
        command
    )

    local success =
        os.execute(command)

    print(
        "Copy result: " ..
        tostring(success)
    )
end

--------------------------------------------------
-- Configuration
--------------------------------------------------

local function loadConfig(projectPath)
    local configPath =
        projectPath ..
        "\\phronova.config.lua"

    local chunk, err =
        loadfile(configPath)

    if not chunk then
        return {
            css = "custom"
        }
    end

    local success, config =
        pcall(chunk)

    if not success then
        error(
            "Could not load phronova.config.lua:\n" ..
            tostring(config)
        )
    end

    if type(config) ~= "table" then
        error(
            "phronova.config.lua must return a table"
        )
    end

    return config
end

--------------------------------------------------
-- Routing
--------------------------------------------------

local function routeFromFile(
    file,
    pagesDirectory
)
    local relative =
        file:sub(#pagesDirectory + 2)

    relative =
        relative:gsub("\\", "/")

    relative =
        relative:gsub("%.lua$", "")

    if relative:match("/index$") then
        relative =
            relative:gsub("/index$", "")

    elseif relative == "index" then
        relative = ""
    end

    return "/" .. relative
end

local function outputFromRoute(
    generatedDirectory,
    route
)
    if route == "/" then
        return generatedDirectory ..
            "\\index.html"
    end

    local relative =
        route:sub(2)

    return generatedDirectory ..
        "\\" ..
        relative ..
        "\\index.html"
end

--------------------------------------------------
-- Relative asset paths
--------------------------------------------------

local function assetPath(route, target, asset)

    -- Website uses HTTP root paths.
    if target == "website" then
        return "/" .. asset
    end

    -- Desktop uses paths relative to the generated HTML file.
    local depth = 0

    if route ~= "/" then
        for _ in route:gmatch("/") do
            depth = depth + 1
        end
    end

    return string.rep("../", depth) .. asset
end

--------------------------------------------------
-- Bootstrap
--------------------------------------------------

local function prepareBootstrap(
    projectPath,
    generatedDirectory,
    config
)
    if config.css ~= "bootstrap" then
        return
    end

    local assetsDirectory =
        generatedDirectory ..
        "\\assets"

    ensureDirectory(assetsDirectory)

    local bootstrapSource =
        installDirectory ..
        "\\css\\bootstrap\\bootstrap.min.css"

    local bootstrapDestination =
        assetsDirectory ..
        "\\bootstrap.min.css"

    if not copyFile(
        bootstrapSource,
        bootstrapDestination
    ) then

        error(
            "Bootstrap stylesheet not found:\n" ..
            bootstrapSource
        )
    end
end

local function prepareTailwind(
    projectPath,
    generatedDirectory,
    config
)
    if config.css ~= "tailwind" then
        return
    end

    local assetsDirectory =
        generatedDirectory .. "\\assets"

    ensureDirectory(assetsDirectory)

    local tailwindExecutable =
        installDirectory ..
        "\\css\\tailwind\\tailwindcss.exe"

    local input =
        generatedDirectory ..
        "\\tailwind.input.css"

    local output =
        assetsDirectory ..
        "\\tailwind.css"

    local inputFile =
        io.open(input, "w")

    if not inputFile then
        error("Could not create Tailwind input file")
    end

    inputFile:write(
        '@import "tailwindcss";\n' ..
        '@source "../src";\n' ..
        '@source "../main.lua";\n'
    )

    inputFile:close()

    local command =
        '"' .. tailwindExecutable .. '"' ..
        ' -i "' .. input .. '"' ..
        ' -o "' .. output .. '"' ..
        ' --minify'


    local success =
        os.execute(
            'cmd.exe /c ""' ..
            tailwindExecutable ..
            '" -i "' ..
            input ..
            '" -o "' ..
            output ..
            '" --minify"'
        )

    if not success then
        error("Tailwind CSS generation failed")
    end
end


local function prepareFavicon(
    projectPath,
    generatedDirectory,
    config
)
    if not config.favicon then
        return
    end

    local assetsDirectory =
        generatedDirectory .. "\\assets"

    ensureDirectory(assetsDirectory)

    local faviconSource =
        projectPath .. "\\" .. config.favicon

    local faviconDestination =
        assetsDirectory .. "\\favicon.ico"

    if not copyFile(
        faviconSource,
        faviconDestination
    ) then
        error(
            "Favicon not found:\n" ..
            faviconSource
        )
    end
end

local function prepareRuntime(generatedDirectory)
    local runtimeSource =
        phronovaDirectory ..
        "\\..\\runtime\\phronova.js"

    local runtimeDestination =
        generatedDirectory ..
        "\\phronova.js"

    if not copyFile(
        runtimeSource,
        runtimeDestination
    ) then
        error(
            "Phronova runtime not found:\n" ..
            runtimeSource
        )
    end
end
--------------------------------------------------
-- Page loading
--------------------------------------------------

local function loadPage(path)
    local chunk, err =
        loadfile(path)

    if not chunk then
        error(
            "Could not load page: " ..
            path ..
            "\n" ..
            err
        )
    end

    local result =
        chunk()

    -- Pages may return an element
    -- or a component function.
    if type(result) == "function" then
        result = result()
    end

    if type(result) ~= "table" then
        error(
            "Page must return an element " ..
            "or a component function: " ..
            path
        )
    end

    return result
end

--------------------------------------------------
-- HTML
--------------------------------------------------

local function renderDocument(
    page,
    layout,
    route,
    target,
    config
)
    local content =
        layout(page)

    local metadata =
        core.getMetadata() or {}

    local title =
        metadata.title or "Phronova"

    local description =
        metadata.description or ""

    --------------------------------------------------
    -- CSS
    --------------------------------------------------

    local stylesheets = ""

    if config.css == "bootstrap" then

        stylesheets =
            '    <link rel="stylesheet" href="' ..
            assetPath(
                route,
                target,
                "assets/bootstrap.min.css"
            ) ..
            '">\n'

        stylesheets =
            stylesheets ..
            '    <link rel="stylesheet" href="' ..
            assetPath(
                route,
                target,
                "src/style.css"
            ) ..
            '">\n'

    elseif config.css == "tailwind" then

        stylesheets =
            '    <link rel="stylesheet" href="' ..
            assetPath(
                route,
                target,
                "assets/tailwind.css"
            ) ..
            '">\n'

        stylesheets =
            stylesheets ..
            '    <link rel="stylesheet" href="' ..
            assetPath(
                route,
                target,
                "src/style.css"
            ) ..
            '">\n'

    else

        stylesheets =
            '    <link rel="stylesheet" href="' ..
            assetPath(
                route,
                target,
                "src/style.css"
            ) ..
            '">\n'

    end

    local favicon = ""

    if config.favicon then
        favicon = '<link rel="icon" href="' .. assetPath(route, target, "assets/favicon.ico") .. '">\n'
    end
    --------------------------------------------------
    -- Live reload
    --------------------------------------------------

    local reloadScript = [[
        <script src="/phronova.js"></script>
    ]]

    if target == "website" then
        reloadScript = [[
        <script src="/phronova.js"></script>
        <script>
            const phronovaReload =
                new EventSource("/__phronova_reload");

            phronovaReload.onmessage =
                function(event) {
                    if (event.data === "reload") {
                        location.reload();
                    }
                };
        </script>
    ]]
    end

    --------------------------------------------------
    -- Document
    --------------------------------------------------

    return [[<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="]] ..
        description ..
        [[">
]] ..
        stylesheets ..
        favicon..
        [[    <title>]] ..
        title ..
        [[</title>
</head>

<body>
    ]] ..
        core.toHTML(content) ..
        [[

]] ..
        reloadScript ..
        [[
</body>
</html>]]
end

--------------------------------------------------
-- Build
--------------------------------------------------

function pages.build(
    projectPath,
    layout,
    target
)
    projectPath =
        normalize(projectPath)

    target =
        target or "website"

    --------------------------------------------------
    -- Directories
    --------------------------------------------------

    local srcDirectory =
        projectPath .. "\\src"

    local pagesDirectory =
        srcDirectory .. "\\pages"

    local generatedDirectory =
        projectPath .. "\\generated"

    --------------------------------------------------
    -- Configuration
    --------------------------------------------------

    local config =
        loadConfig(projectPath)

    --------------------------------------------------
    -- Generated directory
    --------------------------------------------------

    ensureDirectory(
        generatedDirectory
    )

    preparePublic(projectPath, generatedDirectory)

    prepareRuntime(generatedDirectory)

    --------------------------------------------------
    -- Bootstrap assets
    --------------------------------------------------

    prepareBootstrap(
        projectPath,
        generatedDirectory,
        config
    )

    prepareTailwind(projectPath, generatedDirectory, config)

    prepareFavicon(projectPath, generatedDirectory, config)

    --------------------------------------------------
    -- Homepage
    --------------------------------------------------

    local appPath =
        srcDirectory .. "\\app.lua"

    local app =
        loadPage(appPath)

    local html =
        renderDocument(
            app,
            layout,
            "/",
            target,
            config
        )

    assert(
        writeFile(
            generatedDirectory ..
            "\\index.html",
            html
        ),
        "Could not write the homepage"
    )

    --------------------------------------------------
    -- Other pages
    --------------------------------------------------

    local pageFiles =
        readFiles(pagesDirectory)

    for _, file in ipairs(pageFiles) do

        local route =
            routeFromFile(
                file,
                pagesDirectory
            )

        local page =
            loadPage(file)

        local outputPath =
            outputFromRoute(
                generatedDirectory,
                route
            )

        local directory =
            outputPath:match(
                "^(.*)\\[^\\]+$"
            )

        ensureDirectory(directory)

        local document =
            renderDocument(
                page,
                layout,
                route,
                target,
                config
            )

        assert(
            writeFile(
                outputPath,
                document
            ),
            "Could not write route " ..
            route
        )

        print(
            "Generated " .. route
        )
    end

    print(
        "Page generation complete!"
    )
end



return pages