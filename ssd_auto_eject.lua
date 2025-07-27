--[[
  SSD Auto-Eject Script for Hammerspoon - Clean Version
  Uses io.popen() for reliable command output capture
--]]

-- CONFIGURATION
local ssdVolumeName = "Vamsi_2TB" -- IMPORTANT: Set this to your disk's volume name
local delaySeconds  = 30 * 60     -- 30 minutes
local mountDelay    = 5           -- Delay before remounting (seconds)

-- INTERNAL STATE
local ssdVolumePath = "/Volumes/" .. ssdVolumeName
local currentDiskID = nil
local ejectTimer    = nil

-- Validates if the current disk ID is still valid
function validateDiskID()
    if not currentDiskID then return false end
    local handle = io.popen("diskutil info " .. currentDiskID .. " 2>/dev/null")
    local result = handle:read("*a")
    local success = handle:close()
    return success and result and result ~= ""
end

-- Clean and reliable method to find disk ID using io.popen
function findAndSetDiskID()
    -- First check if the volume is actually mounted
    if not hs.fs.attributes(ssdVolumePath) then
        currentDiskID = nil
        return false
    end

    -- Use io.popen to get df output reliably
    local handle = io.popen("df '" .. ssdVolumePath .. "' 2>/dev/null")
    if not handle then
        currentDiskID = nil
        return false
    end

    local content = handle:read("*a")
    handle:close()

    if not content or content == "" then
        currentDiskID = nil
        return false
    end

    -- Parse the output to get device name (e.g., /dev/disk7s2)
    local devicePath = string.match(content, "(/dev/disk%d+s?%d*)")
    if not devicePath then
        currentDiskID = nil
        return false
    end

    -- Extract the parent disk identifier (e.g., disk7 from disk7s2)
    local parentDisk = string.match(devicePath, "/dev/(disk%d+)")
    if parentDisk then
        currentDiskID = parentDisk
        return true
    end

    currentDiskID = nil
    return false
end

-- Function to eject the SSD using its identifier.
function ejectSSD()
    if not currentDiskID then
        if not findAndSetDiskID() then
            hs.notify.new({
                title = "SSD Manager", 
                informativeText = "SSD not found for ejection (may already be ejected)."
            }):send()
            return
        end
    end

    if not validateDiskID() then
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "Cannot eject: Disk ID is no longer valid."
        }):send()
        currentDiskID = nil
        return
    end

    local handle = io.popen("diskutil eject /dev/" .. currentDiskID .. " 2>&1")
    local output = handle:read("*a")
    local success = handle:close()

    if success then
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "'" .. ssdVolumeName .. "' ejected after idle period."
        }):send()
    else
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "Failed to eject SSD: " .. (output or "Unknown error")
        }):send()
    end
end

-- Function to mount the SSD using its identifier.
function mountSSD()
    if not currentDiskID then
        if not findAndSetDiskID() then
            hs.notify.new({
                title = "SSD Manager", 
                informativeText = "Cannot remount: SSD not found."
            }):send()
            return
        end
    end

    -- Check if it's already mounted
    if hs.fs.attributes(ssdVolumePath) then
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "'" .. ssdVolumeName .. "' is already mounted."
        }):send()
        return
    end

    if not validateDiskID() then
        if not findAndSetDiskID() then
            hs.notify.new({
                title = "SSD Manager", 
                informativeText = "Cannot find SSD to remount."
            }):send()
            return
        end
    end

    local handle = io.popen("diskutil mountDisk /dev/" .. currentDiskID .. " 2>&1")
    local output = handle:read("*a")
    local success = handle:close()

    if success then
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "'" .. ssdVolumeName .. "' remounted successfully."
        }):send()
    else
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "Failed to mount SSD: " .. (output or "Unknown error")
        }):send()
    end
end

-- Test functions for manual testing in Hammerspoon console
function testEject()
    ejectSSD()
end

function testMount()
    mountSSD()
end

function testFindDisk()
    if findAndSetDiskID() then
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "Found disk: " .. currentDiskID
        }):send()
        print("Found disk:", currentDiskID)
    else
        hs.notify.new({
            title = "SSD Manager", 
            informativeText = "Disk not found or not mounted."
        }):send()
        print("Disk not found")
    end
end

-- Main watcher for system events
local watcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.screensDidLock or event == hs.caffeinate.watcher.systemWillSleep then
        if ejectTimer then
            ejectTimer:stop()
            ejectTimer = nil
        end

        if findAndSetDiskID() then
            ejectTimer = hs.timer.doAfter(delaySeconds, function()
                ejectSSD()
                ejectTimer = nil
            end)
            
            local eventName = (event == hs.caffeinate.watcher.screensDidLock) and "screen lock" or "system sleep"
            hs.notify.new({
                title = "SSD Manager", 
                informativeText = "SSD will be ejected in " .. (delaySeconds / 60) .. " minutes after " .. eventName .. "."
            }):send()
        end

    elseif event == hs.caffeinate.watcher.screensDidUnlock or event == hs.caffeinate.watcher.systemDidWake then
        if ejectTimer then
            ejectTimer:stop()
            ejectTimer = nil
            hs.notify.new({
                title = "SSD Manager", 
                informativeText = "SSD eject cancelled due to activity."
            }):send()
        end

        hs.timer.doAfter(mountDelay, function()
            mountSSD()
        end)
    end
end)

-- Initialize the script
local function initializeSSDManager()
    findAndSetDiskID()
    watcher:start()
    
    local statusMsg = currentDiskID and 
        ("Script loaded. Monitoring '" .. ssdVolumeName .. "' (ID: " .. currentDiskID .. ").") or
        ("Script loaded. SSD '" .. ssdVolumeName .. "' not currently mounted.")
    
    hs.notify.new({
        title = "SSD Manager", 
        informativeText = statusMsg
    }):send()
end

-- Start the SSD manager
initializeSSDManager()
