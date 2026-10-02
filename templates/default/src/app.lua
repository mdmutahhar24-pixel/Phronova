local core = require("phronova.core")

local function Feature(title, description)
    return core.Element("div", {
        core.Element("h3", core.Text(title)),
        core.Element("p", core.Text(description))
    }, {
        class = "feature-card"
    })
end

local function App()

    return core.Element("main", {

        core.Element("section", {
            core.Element("img", nil, {
                src = "/images/logo.png",
                width = 300,
                class = "logo"
            }),

            core.Element("h1",
                core.Text("Build with Phronova")
            ),

            core.Element("p",
                core.Text(
                    "The Lua framework for building modern web and desktop applications."
                ),
                {
                    class = "subtitle"
                }
            ),

            core.Element("p",
                core.Text(
                    "Create pages, components, reactive interfaces, and complete applications using Lua."
                ),
                {
                    class = "description"
                }
            )
        }, {
            class = "hero montserrat-home"
        }),

        core.Element("section", {

            Feature(
                "⚡ Reactive",
                "Build interfaces that respond to changing data."
            ),

            Feature(
                "📄 File-Based Pages",
                "Organize your application with simple Lua files."
            ),

            Feature(
                "🎨 Flexible Styling",
                "Use custom CSS, Tailwind, or Bootstrap."
            ),

            Feature(
                "🖥️ Web + Desktop",
                "Build for the browser or run your application as a desktop app."
            )

        }, {
            class = "features"
        }),

        core.Element("section", {
            core.Element("h2",
                core.Text("Ready to build?")
            ),

            core.Element("p",
                core.Text(
                    "Create your pages, add your components, and let Phronova handle the rest."
                )
            )
        }, {
            class = "getting-started"
        })

    })
end

return App