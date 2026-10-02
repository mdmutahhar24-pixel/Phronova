local core = {}
local events = {}
local nextEventId = 1
local nextReactiveId = 1

function core.RegisterEvent(callback)
    local id = nextEventId
    nextEventId = nextEventId + 1

    events[id] = callback

    return id
end

function core.DispatchEvent(id)
    local callback = events[id]

    if callback then
        callback()
    end
end

function core.Text(word)
    if type(word) == "table" and word.__reactive then
        return {
            type = "reactive_text",
            reactive = word,
            content = tostring(word:Get())
        }
    end

    if word ~= nil then
        return {
            type = "text",
            content = tostring(word)
        }
    end
end

function core.Element(element, children, props)
    if children == nil then
        children = {}
    elseif type(children) ~= "table" or children.type then
        children = { children }
    end

    props = props or {}

    for key, value in pairs(props) do
        if key:sub(1, 2) == "on" and type(value) == "function" then
            props[key] = core.RegisterEvent(value)
        end
    end

    return {
        type = "element",
        element = element,
        properties = props,
        children = children
    }
end

local function escapeHTML(value)
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
        :gsub("'", "&#39;")
end

function core.toHTML(element)
    if element.type == "text" then
        return escapeHTML(element.content)
    end
        if element.type == "reactive_text" then
        local id = element.reactive.__reactiveId

        element.reactive:Subscribe(function(newValue)
            element.content = tostring(newValue)
        end)

        return '<span data-phronova-reactive="' ..
            id ..
            '">' ..
            escapeHTML(element.content) ..
            '</span>'
    end

    local html = "<" .. element.element

    for key, value in pairs(element.properties or {}) do
        if key:sub(1, 2) == "on" and type(value) == "number" then
            local eventName = key:sub(3):lower()

            html = html ..
                ' data-phronova-event-' ..
                eventName ..
                '="' .. value .. '"'
        else
            html = html ..
                " " .. key .. '="' .. escapeHTML(value) .. '"'
        end
    end

    html = html .. ">"

    for _, child in ipairs(element.children or {}) do
        html = html .. core.toHTML(child)
    end

    return html .. "</" .. element.element .. ">"
end

local metadata = {}

function core.setMetadata(metadataVal)
    metadata = metadataVal or {}
end

function core.getMetadata()
    return metadata
end


function core.Reactive(initialVal)
    local value = initialVal

    local reactiveItems = {}
    local reactiveId = nextReactiveId
    nextReactiveId = nextReactiveId + 1

    reactiveItems.__reactiveId = reactiveId

    function reactiveItems:Get()
        return value
    end

    local subscribers = {}

    function reactiveItems:Set(newVal)
        value = newVal

        os.execute(
            'powershell -NoProfile -Command ' ..
            '"Invoke-WebRequest -UseBasicParsing ' ..
            '-Uri http://127.0.0.1:1125/__phronova_reactive_update/' ..
            tostring(reactiveItems.__reactiveId) ..
            '/' ..
            tostring(newVal) ..
            ' -Method GET | Out-Null"'
        )

        for key, content in pairs(subscribers) do
            if content.Active then
                content.Index(newVal)
            end
        end
    end

    function reactiveItems:Subscribe(callback)
        local param = {Index = callback, Active = true}
        table.insert(subscribers, param)
        return param
    end

    function reactiveItems:Deactivate(subscriber)
        for i = 1, #subscribers do
            if subscribers[i] == subscriber then
                subscriber.Active = false
            end
        end
    end

    function reactiveItems:Reactivate(subscriber)
        for i = 1, #subscribers do
            if subscribers[i] == subscriber and subscribers[i].Active == false then
                subscribers[i].Index(reactiveItems:Get())
                subscriber.Active = true
            end
        end
    end

    reactiveItems.__reactive = true

    return reactiveItems
end
return core