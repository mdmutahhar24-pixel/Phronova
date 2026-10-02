local terminal = {}

local messages = {}

os.execute("chcp 65001 >nul")

local colors = {
    gold   = "\27[38;2;207;181;60m",
    ivory  = "\27[38;2;255;255;240m",
    green  = "\27[38;2;57;255;20m",
    amber  = "\27[38;2;250;119;9m",
    red    = "\27[38;2;255;80;80m",
    blue   = "\27[38;2;100;180;255m",
    gray   = "\27[38;2;145;145;145m",
    dark   = "\27[38;2;65;65;65m",
    white  = "\27[38;2;245;245;245m",
    reset  = "\27[0m"
}

local mesColors = {
    normal  = colors.ivory,
    success = colors.green,
    warning = colors.amber,
    error   = colors.red
}

local function repeatChar(char, amount)
    return string.rep(char, amount)
end

local function printLine(char, amount, color)
    print(
        (color or colors.dark) ..
        repeatChar(char, amount) ..
        colors.reset
    )
end

function terminal:clear()
    os.execute("cls")
end

function terminal:header(mode)
    local emblem = "◈"

    terminal:clear()

    print()

    print(
        colors.gold ..
        "    " .. emblem .. " PHRONOVA" ..
        colors.reset
    )

    print(
        colors.gray ..
        "    The Lua framework for building Dekstop and Web Applications" ..
        colors.reset
    )

    printLine("─", 64)

    if mode == "startup" then
        print(
            colors.white ..
            "    CREATE PROJECT" ..
            colors.reset
        )
    elseif mode == "run" then
        print(
            colors.white ..
            "    DEVELOPMENT SERVER" ..
            colors.reset
        )
    end

    print()
end

function terminal:message(message, typeOfMes)
    table.insert(messages, {
        content = message,
        mesType = typeOfMes
    })

    local color = mesColors[typeOfMes] or colors.ivory
    local symbol = "·"

    if typeOfMes == "success" then
        symbol = "✓"
    elseif typeOfMes == "warning" then
        symbol = "!"
    elseif typeOfMes == "error" then
        symbol = "×"
    end

    print(
        color ..
        "    " ..
        symbol ..
        " " ..
        message ..
        colors.reset
    )
end

function terminal:info(message)
    print(
        colors.blue ..
        "    · " ..
        message ..
        colors.reset
    )
end

function terminal:section(title)
    print()

    print(
        colors.gold ..
        "    " ..
        title ..
        colors.reset
    )

    printLine("─", 48)

    print()
end

function terminal:prompt(message)
    io.write(
        colors.gold ..
        "    > " ..
        colors.ivory ..
        message ..
        colors.reset ..
        " "
    )

    return io.read("*l")
end

function terminal:select(options, title)
    local selected = 1
    title = title or "SELECT AN OPTION"

    local function draw()
        terminal:clear()

        print()

        print(
            colors.gold ..
            "    ◈ PHRONOVA" ..
            colors.reset
        )

        printLine("─", 64)

        print(
            colors.white ..
            "    " .. title ..
            colors.reset
        )

        print()

        for i, option in ipairs(options) do
            local number = tostring(i)

            if i == selected then
                print(
                    colors.gold ..
                    "      ┌─ " ..
                    colors.ivory ..
                    number ..
                    ". " ..
                    option ..
                    colors.gold ..
                    " ─┐" ..
                    colors.reset
                )
            else
                print(
                    colors.gray ..
                    "        " ..
                    number ..
                    ". " ..
                    option ..
                    colors.reset
                )
            end
        end

        print()

        print(
            colors.dark ..
            "    ↑ ↓  Navigate    Enter  Select" ..
            colors.reset
        )

        print()
    end

    while true do
        draw()

        local key = io.popen(
            'powershell -NoProfile -Command "$key = [Console]::ReadKey($true); [int]$key.Key"'
        )

        if key == nil then
            return nil
        end

        local keyCode = tonumber(key:read("*a"))
        key:close()

        if keyCode == 38 then
            selected = selected - 1

            if selected < 1 then
                selected = #options
            end

        elseif keyCode == 40 then
            selected = selected + 1

            if selected > #options then
                selected = 1
            end

        elseif keyCode == 13 then
            terminal:clear()

            return selected, options[selected]
        end
    end
end

function terminal:success(message)
    terminal:message(message, "success")
end

function terminal:warning(message)
    terminal:message(message, "warning")
end

function terminal:error(message)
    terminal:message(message, "error")
end

function terminal:done()
    print()

    printLine("─", 64)

    print(
        colors.green ..
        "    ✓ Project created successfully." ..
        colors.reset
    )

    print()
end

return terminal