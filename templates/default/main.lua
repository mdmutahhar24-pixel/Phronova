local core = require('phronova.core')

local function Main(page)
    core.setMetadata({
        title = 'Phronova'
    })

    return core.Element('div', {
        page
    })
end

return Main
