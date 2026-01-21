local menuOpen = false
local mapOpen = false
local settingsOpen = false
local disableThreadRunning = false
local lastMenuToggle = 0
local MENU_TOGGLE_COOLDOWN = 500

local function CanToggleMenu()
    local now = GetGameTimer()
    if now - lastMenuToggle < MENU_TOGGLE_COOLDOWN then
        return false
    end
    lastMenuToggle = now
    return true
end

local function SafeDisableControls()
    if disableThreadRunning then return end
    disableThreadRunning = true

    CreateThread(function()
        while menuOpen do
            for _, control in ipairs(Config.DisableControls or {}) do
                DisableControlAction(0, control, true)
            end
            Wait(0)
        end
        disableThreadRunning = false
    end)
end

function OpenPauseMenu()
    if menuOpen or mapOpen or settingsOpen or not CanToggleMenu() then return end
    
    -- Check nur beim Öffnen, nicht permanent
    if IsNuiFocused() or IsEntityDead(PlayerPedId()) then return end
    
    menuOpen = true
    
    TriggerScreenblurFadeIn(500)
    
    SendNUIMessage({
        action = "open",
        config = Config
    })
    
    SetNuiFocus(true, true)
    SafeDisableControls()
end

function ClosePauseMenu()
    if not menuOpen or not CanToggleMenu() then return end
    
    menuOpen = false
    
    TriggerScreenblurFadeOut(500)
    
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

RegisterNUICallback('close', function(_, cb)
    ClosePauseMenu()
    cb('ok')
end)

RegisterNUICallback('resume', function(_, cb)
    ClosePauseMenu()
    cb('ok')
end)

RegisterNUICallback('quit', function(_, cb)
    ClosePauseMenu()
    TriggerServerEvent('blossom_pause:disconnect')
    cb('ok')
end)

RegisterNUICallback('map', function(_, cb)
    if not menuOpen then
        cb('ok')
        return
    end
    
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    
    Wait(100)
    
    mapOpen = true
    
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_MP_PAUSE"), false, -1)
    
    CreateThread(function()
        local checkCount = 0
        
        while mapOpen and checkCount < 100 do
            Wait(50)
            checkCount = checkCount + 1
            
            if not IsPauseMenuActive() then
                mapOpen = false
                TriggerScreenblurFadeOut(500)
                break
            end
        end
        
        if checkCount >= 100 then
            mapOpen = false
            TriggerScreenblurFadeOut(500)
        end
    end)
    
    cb('ok')
end)

RegisterNUICallback('settings', function(_, cb)
    if not menuOpen then
        cb('ok')
        return
    end
    
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    
    Wait(100)
    
    settingsOpen = true
    
    ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_LANDING_MENU"), false, -1)
    
    CreateThread(function()
        local checkCount = 0
        
        while settingsOpen and checkCount < 200 do
            Wait(50)
            checkCount = checkCount + 1
            
            if not IsPauseMenuActive() then
                settingsOpen = false
                TriggerScreenblurFadeOut(500)
                break
            end
        end
        
        if checkCount >= 200 then
            settingsOpen = false
            TriggerScreenblurFadeOut(500)
        end
    end)
    
    cb('ok')
end)

RegisterNUICallback('openLink', function(data, cb)
    if data and data.url and data.url ~= '' then
        SendNUIMessage({
            action = "openExternal",
            url = data.url
        })
    end
    cb('ok')
end)

RegisterCommand('pausemenu', function()
    if menuOpen then
        ClosePauseMenu()
    else
        OpenPauseMenu()
    end
end, false)

CreateThread(function()
    while true do
        Wait(5)
        
        if not menuOpen and not mapOpen and not settingsOpen then
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 199, true)
            
            if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 199) then
                if IsPauseMenuActive() then
                    SetFrontendActive(false)
                end
                OpenPauseMenu()
            end
        end
    end
end)
