--[[This is components.lua. Here is an example of what it can be used for:
    local core = require('phronova.core')

    local components = {}

    function components:Button(props)
        return core.Element('button', core.Text("Button"), props)
    end

    return components
    
    Then in app.lua or any page:
    local core = require('phronova.core')
    local components = require('components')

    local function App()
        return components:Button({class='MyStyleClass'})
    end

    return App
]]

local core = require('phronova.core')

local components = {}

return components