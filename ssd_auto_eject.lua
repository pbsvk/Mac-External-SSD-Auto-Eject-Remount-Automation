-- Mac External SSD Auto Eject & Remount Automation
-- Configurations
local ssdVolume = "/Volumes/Vamsi_2TB" -- Change this to your SSD volume path
local ssdDiskID = "disk6"              -- Change this to your SSD disk identifier
local lockTime = nil
local ejectTimer = nil
local delaySeconds = 30 * 60 -- 30 minutes

-- Function to unmount the SSD
function unmountSSD()
    hs.execute("diskutil unmountDisk /dev/" .. ssdDiskID)
    hs.notify.new({
        title = "SSD Manager",
        informativeText = "External SSD unmounted after 30 min idle."
    }):send()
end

-- Function to mount the SSD
function mountSSD()
    hs.execute("diskutil mountDisk /dev/" .. ssdDiskID)
    hs.notify.new({
        title = "SSD Manager",
        informativeText = "External SSD remounted."
    }):send()
end

-- Lock/unlock/watch
local watcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.screensDidLock then
        lockTime = os.time()
        ejectTimer = hs.timer.doAfter(delaySeconds, function()
            local now = os.time()
            if lockTime and (now - lockTime >= delaySeconds) then
                unmountSSD()
            end
        end)
    elseif event == hs.caffeinate.watcher.screensDidUnlock or
           event == hs.caffeinate.watcher.systemDidWake then
        if ejectTimer then
            ejectTimer:stop()
            ejectTimer = nil
        end
        hs.timer.doAfter(5, function() mountSSD() end)
    end
end)

watcher:start()

-- Manual test functions
function testUnmount()
    unmountSSD()
end

function testMount()
    mountSSD()
end
