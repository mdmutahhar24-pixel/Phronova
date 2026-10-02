# Phronova
A Framework for Lua Web and Desktop Applications

## What is Phronova?
Phronova is a Lua frontend framework that can be used to build either web or desktop applications or both! *Note: Phronova currently doesn't provide a installer for the desktop version.

## IMPORTANT NOTE:
Currently, Phronova only runs on Windows

## Installation Steps:
1. Go to installer/install.bat
2. Run it
3. Press the Windows Key
4. Search Environment Variables
5. Add `%LOCALAPPDATA%\Phronova\bin` to the `Path` variable
6. use the `phronova` command

## Running and Creating a Project using Phronova
Commands and Explanation:
- `phronova create (projectName) --tailwind/--bootstrap` (projectName): name of your project. `--tailwind`/`--bootstrap`: For either tailwind or bootstrap (leave blank for frameworkless)
- `phronova run (projectName) --website/--desktop` (projectName): name of your project. `--website`/`--desktop`: for either testing website or desktop versions of your application.

## Known bugs/Not implemented feaures:
- favicon not working
- Desktop installer


## Features:
Phronova currently includes the following:
- CLI
- Tailwind CSS
- Bootstrap CSS
- Frameworkless CSS (just a css file. This will be included no matter what CSS framework you chose. This is just an option in case you don't want bootstrap or tailwind)
- Web Server
- Desktop Server
- User Interactivity
- And More!

One important thing to address: Phronova already contains guides for how to use features. When you explore phronova for a bit, you will figure out everything.

## Additional Features Tutorial:
- For pages, it is similar to Next.JS's navigations (a folder creates a page)
- For Interactivity use `core.Reactive(exampleVal)` to set a initial value. Set that to a variable (val in this example). and then do val:Get() to get the value, val:Set(newVal) to set a new value to val.
- Don't modify anything in generated. When you run, anything in generated will be overwritten, so don't waste the effort.
