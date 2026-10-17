--- Performs additional setup after installation
--- Documentation: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook
--- @param ctx {rootPath: string, runtimeVersion: string, sdkInfo: table} Context
function PLUGIN:PostInstall(ctx)
    local cmd = require("cmd")
    local file = require("file")

    local root = ctx.rootPath
    local os_name = RUNTIME.osType:lower()

    --- Quotes a string for use in a POSIX shell command
    local function quote(s)
        return "'" .. s:gsub("'", "'\\''") .. "'"
    end

    --- Writes bin/love, a wrapper that runs `target` (relative to the install root)
    local function write_wrapper(target)
        local bin = file.join_path(root, "bin", "love")
        cmd.exec("mkdir -p " .. quote(file.join_path(root, "bin")))
        local f = assert(io.open(bin, "w"))
        f:write('#!/bin/sh\nroot=$(cd "$(dirname "$0")/.." && pwd -P)\nexec "$root/' .. target .. '" "$@"\n')
        f:close()
        cmd.exec("chmod +x " .. quote(bin))
        return bin
    end

    local bin
    if os_name == "linux" then
        -- Extract the AppImage so running LÖVE doesn't require FUSE
        local appdir = file.join_path(root, "love.AppDir")
        if not file.exists(appdir) then
            local images = file.glob(file.join_path(root, "*.AppImage"))
            if #images == 0 then
                error("LÖVE AppImage not found in " .. root)
            end
            cmd.exec(quote(images[1]) .. " --appimage-extract > /dev/null", { cwd = root })
            file.move(file.join_path(root, "squashfs-root"), appdir)
            os.remove(images[1])
        end
        -- Before 11.4 the AppImage ships a love launcher script and a compiled AppRun that
        -- mangles PATH, so run the launcher directly
        if file.exists(file.join_path(appdir, "love")) then
            bin = write_wrapper("love.AppDir/love")
        else
            bin = write_wrapper("love.AppDir/AppRun")
        end
    elseif os_name == "darwin" then
        -- mise strips the archive's single top-level love.app directory, so put the bundle back together
        local app = file.join_path(root, "love.app")
        if not file.exists(app) then
            local contents = file.join_path(root, "Contents")
            if not file.exists(contents) then
                error("LÖVE app bundle not found in " .. root)
            end
            cmd.exec("mkdir " .. quote(app))
            file.move(contents, file.join_path(app, "Contents"))
        end
        bin = write_wrapper("love.app/Contents/MacOS/love")
    elseif os_name == "windows" then
        -- love.exe has no console output, lovec.exe is the console variant
        bin = file.join_path(root, "lovec.exe")
        if not file.exists(bin) then
            error("lovec.exe not found in " .. root)
        end
        bin = '"' .. bin .. '"'
    else
        error("Unsupported OS: " .. os_name)
    end

    -- Verify installation works
    if os_name ~= "windows" then
        bin = quote(bin)
    end
    cmd.exec(bin .. " --version")
end
