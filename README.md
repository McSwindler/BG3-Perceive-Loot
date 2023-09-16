# BG3-Mod-Template
A template Repo for bootstrapping a new mod in VSCode. Uses Powershell scripts to streamline the build process. Requires [LSLib](https://github.com/Norbyte/lslib/releases)

## Inital Usage
1. Hit the "Use this template" button to create a new repository using this template.
1. Clone your new repo into your workspace
1. Open in Visual Studio Code
1. Run the task 'Rename Mod'
1. Edit `.vscode/settings.json` to point to LSLib's divine.exe (`bg3.lslib.path`)

## Available Tasks
### Create Pak
This task will compile and package your mod into the `Build` directory. It will also increment the build number version in the `meta.lsx` file.

The `Source` directory is considered the root of the pak, anything inside of this directory will be packaged.

Currently, this step will only convert your Localization files. Other file types like `.lsx` will need to be compiled manually for now.

### Convert Localization Files
This task will convert your Localization `.xml` files into `.loca` files. Currently this task is executed automatically when you run `Create Pak`.

### Uprev Build Version
This task will increment the current build number of the version in `meta.lsx`. Currently this task is executed automatically when you run `Create Pak`.

### Uprev Version
This task will increment a given category of the version number in `meta.lsx`. Possibly options are: build, revision, minor, major

### Rename Mod
This task will rename the mod in `meta.lsx` as well as set the Author and Folder name. Will also move/rename applicable files (Localization and Mods directory). Should be run as the first step when using this template. All files and folders will need to be closed in VSCode before being able to complete this task.


## Adding Script Extender
I did not include script extender configuration in this template as not every mod needs it. Instead, I recommend following [LaughingLeader's Guide](https://github.com/LaughingLeader/BG3ModdingTools/wiki/Script-Extender-Lua-Setup#script-extender-setup)

## Special Thanks

* Norbyte for [LSLib](https://github.com/Norbyte/lslib/releases)
* LaughingLeader for their [vscode snippets](https://github.com/LaughingLeader/BG3ModdingTools)