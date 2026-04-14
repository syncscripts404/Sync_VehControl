
local Framework = nil
local PlayerData = {}

local function DetectFramework()
    local qbSuccess, qbObject = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if qbSuccess and qbObject then
        return 'qbcore', qbObject
    end
    local esxSuccess, esxObject = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)
    if esxSuccess and esxObject then
        return 'esx', esxObject
    end
    if GetResourceState('es_extended') == 'started' then
        return 'esx', nil
    end
    if GetResourceState('qb-core') == 'started' then
        return 'qbcore', nil
    end

    return nil, nil
end

local function InitializeFramework()
    local fwName, fwObj = DetectFramework()
    Framework = fwName

    if Framework == 'qbcore' then
        local QBCore = fwObj or exports['qb-core']:GetCoreObject()

        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            PlayerData = QBCore.Functions.GetPlayerData() or {}
        end)

        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            PlayerData = {}
        end)

        RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
            PlayerData = val or {}
        end)

        CreateThread(function()
            Wait(0)
            if QBCore and QBCore.Functions then
                PlayerData = QBCore.Functions.GetPlayerData() or {}
            end
        end)

    elseif Framework == 'esx' then
        local ESX = fwObj

        if not ESX then
            TriggerEvent('esx:getSharedObject', function(obj)
                ESX = obj
            end)
        end

        RegisterNetEvent('esx:playerLoaded', function(xPlayer)
            PlayerData = xPlayer or {}
        end)

        RegisterNetEvent('esx:onPlayerLogout', function()
            PlayerData = {}
        end)

        CreateThread(function()
            Wait(0)
            if ESX and ESX.GetPlayerData then
                PlayerData = ESX.GetPlayerData() or {}
            end
        end)
    end
end

CreateThread(function()
    Wait(0)
    InitializeFramework()
end)

local uiOpen = false
local indicatorLeft = false
local indicatorRight = false
local hazards = false
local windowDown = { false, false, false, false }
---@type table
local uiConfig = (Config and Config.UI) or {}

---@param hex string
---@return string|nil
local function hexToRgbString(hex)
    if type(hex) ~= 'string' then return nil end

    hex = hex:gsub('#', '')
    if #hex == 8 then
        hex = hex:sub(3)
    end

    if #hex ~= 6 then return nil end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    if not r or not g or not b then return nil end
    return string.format('%d, %d, %d', r, g, b)
end

---@param cfg any
local function normalizeUiConfig(cfg)
    cfg = cfg or {}

    local accent = cfg.MainColor or cfg.Accent or '#C9FF34'
    local accentRgb = cfg.AccentRgb or hexToRgbString(accent) or '201, 255, 52'

    return {
        accent = accent,
        accentRgb = accentRgb,
        backdrop = cfg.Backdrop or 'rgba(0, 0, 0, 0.28)',
        width = cfg.Width or 380,
        rightOffset = cfg.RightOffset or 70,
        maxHeightVh = cfg.MaxHeightVh or 46,
        tiltX = cfg.TiltX or 10,
        tiltY = cfg.TiltY or -10,
        animInMs = cfg.AnimInMs or 200,
        animOutMs = cfg.AnimOutMs or 180,
        slidePx = cfg.SlidePx or 26,
    }
end

---@return number|nil
local function getVehicle()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return nil end
    if not IsPedInAnyVehicle(ped, false) then return nil end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or not DoesEntityExist(veh) then return nil end
    return veh
end

---@param visible boolean
local function sendVisible(visible)
    SendNUIMessage({ type = 'vehcontrol:visible', visible = visible })
end

local function sendUiConfig()
    SendNUIMessage({ type = 'vehcontrol:config', config = normalizeUiConfig(uiConfig) })
end

---@param veh number
---@param boneName string
---@return boolean
local function hasBone(veh, boneName)
    local idx = GetEntityBoneIndexByName(veh, boneName)
    return idx ~= nil and idx ~= -1
end

local lastStatusKey = nil
local lastCapsKey = nil
local lastCapsVeh = nil
local lastCapsAt = 0

---@param b boolean
---@return string
local function b01(b)
    return b and '1' or '0'
end

---@param arr table
---@return string
local function arr01(arr)
    local out = {}
    for i = 1, #arr do
        out[i] = b01(arr[i])
    end
    return table.concat(out)
end

---@param veh number|nil
local function sendCaps(veh)
    veh = veh or getVehicle()
    if not veh then
        local caps = {
            headlights = false,
            highbeams = false,
            hazards = false,
            indicatorLeft = false,
            indicatorRight = false,
            doors = { false, false, false, false, false, false },
            windows = { false, false, false, false },
            tires = { false, false, false, false, false, false },
        }

        local key = table.concat({
            b01(caps.headlights),
            b01(caps.highbeams),
            b01(caps.hazards),
            b01(caps.indicatorLeft),
            b01(caps.indicatorRight),
            arr01(caps.doors),
            arr01(caps.windows),
            arr01(caps.tires),
        }, '|')

        if key ~= lastCapsKey then
            lastCapsKey = key
            lastCapsVeh = nil
            lastCapsAt = GetGameTimer()
            SendNUIMessage({ type = 'vehcontrol:caps', caps = caps })
        end
        return
    end

    local now = GetGameTimer()
    if lastCapsVeh == veh and (now - lastCapsAt) < 1000 then
        return
    end

    local doors = {
        hasBone(veh, 'door_dside_f'),
        hasBone(veh, 'door_pside_f'),
        hasBone(veh, 'door_dside_r'),
        hasBone(veh, 'door_pside_r'),
        hasBone(veh, 'bonnet'),
        hasBone(veh, 'boot'),
    }

    local windows = {
        hasBone(veh, 'window_lf'),
        hasBone(veh, 'window_rf'),
        hasBone(veh, 'window_lr'),
        hasBone(veh, 'window_rr'),
    }

    local caps = {
        headlights = true,
        highbeams = true,
        hazards = true,
        indicatorLeft = true,
        indicatorRight = true,
        doors = doors,
        windows = windows,
        tires = { true, true, true, true, true, true },
    }

    local key = table.concat({
        b01(caps.headlights),
        b01(caps.highbeams),
        b01(caps.hazards),
        b01(caps.indicatorLeft),
        b01(caps.indicatorRight),
        arr01(caps.doors),
        arr01(caps.windows),
        arr01(caps.tires),
    }, '|')

    if key ~= lastCapsKey or lastCapsVeh ~= veh then
        lastCapsKey = key
        lastCapsVeh = veh
        lastCapsAt = now
        SendNUIMessage({ type = 'vehcontrol:caps', caps = caps })
    end
end

local function sendStatus()
    local veh = getVehicle()
    if not veh then
        sendCaps(nil)

        local status = {
            headlights = false,
            highbeams = false,
            indicatorLeft = false,
            indicatorRight = false,
            hazards = false,
            doors = { false, false, false, false, false, false },
            windows = windowDown,
            tires = { true, true, true, true, true, true },
        }

        local key = table.concat({
            b01(status.headlights),
            b01(status.highbeams),
            b01(status.indicatorLeft),
            b01(status.indicatorRight),
            b01(status.hazards),
            arr01(status.doors),
            arr01(status.windows),
            arr01(status.tires),
        }, '|')

        if key ~= lastStatusKey then
            lastStatusKey = key
            SendNUIMessage({ type = 'vehcontrol:status', status = status })
        end
        return
    end

    local a, b, c = GetVehicleLightsState(veh)
    local lightsOn = c == nil and a or b
    local highbeamsOn = c == nil and b or c

    local doors = {}
    for i = 0, 5 do
        doors[i + 1] = (GetVehicleDoorAngleRatio(veh, i) or 0.0) > 0.1
    end

    local tires = {}
    for i = 0, 5 do
        tires[i + 1] = not IsVehicleTyreBurst(veh, i, false)
    end

    local status = {
        headlights = lightsOn == 1,
        highbeams = highbeamsOn == 1,
        indicatorLeft = indicatorLeft,
        indicatorRight = indicatorRight,
        hazards = hazards,
        doors = doors,
        windows = windowDown,
        tires = tires,
    }

    local key = table.concat({
        b01(status.headlights),
        b01(status.highbeams),
        b01(status.indicatorLeft),
        b01(status.indicatorRight),
        b01(status.hazards),
        arr01(status.doors),
        arr01(status.windows),
        arr01(status.tires),
    }, '|')

    if key ~= lastStatusKey then
        lastStatusKey = key
        SendNUIMessage({ type = 'vehcontrol:status', status = status })
    end

    sendCaps(veh)
end

local function setIndicators()
    local veh = getVehicle()
    if not veh then return end

    if hazards then
        SetVehicleIndicatorLights(veh, 1, true)
        SetVehicleIndicatorLights(veh, 0, true)
        return
    end

    SetVehicleIndicatorLights(veh, 1, indicatorLeft)
    SetVehicleIndicatorLights(veh, 0, indicatorRight)
end

local inspectCam = nil
local inspectCamActive = false

local camPos = nil
local camLook = nil
local camPosTarget = nil
local camLookTarget = nil

---@param a vector3
---@param b vector3
---@param t number
---@return vector3
local function vLerp(a, b, t)
    return vec3(
        a.x + (b.x - a.x) * t,
        a.y + (b.y - a.y) * t,
        a.z + (b.z - a.z) * t
    )
end

local function destroyInspectCam()
    if inspectCam ~= nil then
        RenderScriptCams(false, true, 200, true, false)
        DestroyCam(inspectCam, false)
        inspectCam = nil
    end
    inspectCamActive = false
    camPos = nil
    camLook = nil
    camPosTarget = nil
    camLookTarget = nil
end

local function ensureInspectCam()
    if inspectCam ~= nil then
        return
    end

    inspectCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamFov(inspectCam, 60.0)
    SetCamActive(inspectCam, true)
    RenderScriptCams(true, true, 200, true, false)
    inspectCamActive = true
end

---@param veh number
---@param boneName string
---@return vector3|nil
local function getBoneWorld(veh, boneName)
    local idx = GetEntityBoneIndexByName(veh, boneName)
    if idx == nil or idx == -1 then return nil end
    return GetWorldPositionOfEntityBone(veh, idx)
end

---@param lookAt vector3
---@param camPos vector3
local function setInspectCam(lookAt, camPos)
    ensureInspectCam()
    camPosTarget = camPos
    camLookTarget = lookAt
end

---@param target string
---@param index number|nil
local function focusInspectTarget(target, index)
    local veh = getVehicle()
    if not veh then return end

    local lookAt = nil
    local camPos = nil

    if target == 'hazards' then
        lookAt = getBoneWorld(veh, 'boot') or GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.2, 0.6)
        camPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -5.2, 1.25)
    elseif target == 'indicatorLeft' then
        lookAt = getBoneWorld(veh, 'taillight_l') or getBoneWorld(veh, 'headlight_l') or GetOffsetFromEntityInWorldCoords(veh, -0.7, -2.0, 0.6)
        camPos = GetOffsetFromEntityInWorldCoords(veh, -2.3, -4.9, 1.25)
    elseif target == 'indicatorRight' then
        lookAt = getBoneWorld(veh, 'taillight_r') or getBoneWorld(veh, 'headlight_r') or GetOffsetFromEntityInWorldCoords(veh, 0.7, -2.0, 0.6)
        camPos = GetOffsetFromEntityInWorldCoords(veh, 2.3, -4.9, 1.25)
    elseif target == 'door' then
        local doorBones = { 'door_dside_f', 'door_pside_f', 'door_dside_r', 'door_pside_r', 'bonnet', 'boot' }
        local bone = (index and doorBones[index + 1]) or nil
        if bone then
            lookAt = getBoneWorld(veh, bone)
        end
        if not lookAt then
            lookAt = GetEntityCoords(veh)
        end

        if index == 0 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, -2.2, 1.6, 1.1)
        elseif index == 1 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, 2.2, 1.6, 1.1)
        elseif index == 2 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, -2.2, -0.8, 1.1)
        elseif index == 3 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, 2.2, -0.8, 1.1)
        elseif index == 4 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, 4.0, 1.2)
        elseif index == 5 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -5.2, 1.25)
        else
            camPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -4.8, 1.25)
        end
    elseif target == 'window' then
        local windowBones = { 'window_lf', 'window_rf', 'window_lr', 'window_rr' }
        local bone = (index and windowBones[index + 1]) or nil
        if bone then
            lookAt = getBoneWorld(veh, bone)
        end
        if not lookAt then
            lookAt = GetEntityCoords(veh)
        end

        if index == 0 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, -2.0, 1.4, 1.4)
        elseif index == 1 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, 2.0, 1.4, 1.4)
        elseif index == 2 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, -2.0, -0.9, 1.4)
        elseif index == 3 then
            camPos = GetOffsetFromEntityInWorldCoords(veh, 2.0, -0.9, 1.4)
        else
            camPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, -4.8, 1.5)
        end
    end

    if lookAt and camPos then
        setInspectCam(lookAt, camPos)
    end
end

local function setUIOpen(state)
    uiOpen = state
    SetNuiFocus(state, state)
    if state then
        sendUiConfig()
    end
    sendVisible(state)
    if state then
        sendStatus()
        ensureInspectCam()
        local veh = getVehicle()
        if veh then
            camPos = GetGameplayCamCoord()
            camLook = GetEntityCoords(veh)
            camPosTarget = camPos
            camLookTarget = camLook
        end
        focusInspectTarget('hazards', nil)
    else
        destroyInspectCam()
    end
end

local function notifyNotInVehicle()
    if lib and lib.notify then
        lib.notify({ type = 'error', description = 'You are not in a vehicle !' })
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('You are not in a vehicle !')
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterCommand('vehcontrol', function()
    if not uiOpen then
        local veh = getVehicle()
        if not veh then
            notifyNotInVehicle()
            return
        end
    end
    setUIOpen(not uiOpen)
end, false)

RegisterKeyMapping('vehcontrol', 'Vehicle Control UI', 'keyboard', 'F7')

RegisterNUICallback('close', function(_, cb)
    setUIOpen(false)
    cb({ ok = true })
end)

RegisterNUICallback('cameraFocus', function(data, cb)
    if uiOpen then
        focusInspectTarget(tostring(data and data.target or ''), tonumber(data and data.index))
    end
    cb({ ok = true })
end)

RegisterNUICallback('cameraClear', function(_, cb)
    if uiOpen then
        focusInspectTarget('hazards', nil)
    end
    cb({ ok = true })
end)

RegisterNUICallback('toggleHeadlights', function(_, cb)
    local veh = getVehicle()
    if veh then
        local a, b, c = GetVehicleLightsState(veh)
        local lightsOn = c == nil and a or b
        local highbeamsOn = c == nil and b or c

        local anyOn = (lightsOn == 1) or (highbeamsOn == 1)
        if anyOn then
            SetVehicleFullbeam(veh, false)
            SetVehicleLights(veh, 1)
        else
            SetVehicleLights(veh, 2)
        end
    end
    sendStatus()
    cb({ ok = true })
end)

RegisterNUICallback('toggleHighbeams', function(_, cb)
    local veh = getVehicle()
    if veh then
        local a, b, c = GetVehicleLightsState(veh)
        local lightsOn = c == nil and a or b
        local highbeamsOn = c == nil and b or c
        if highbeamsOn == 1 then
            SetVehicleFullbeam(veh, false)
            if lightsOn == 1 then
                SetVehicleLights(veh, 2)
            end
        else
            SetVehicleLights(veh, 2)
            SetVehicleFullbeam(veh, true)
        end
    end
    sendStatus()
    cb({ ok = true })
end)

RegisterNUICallback('toggleHazards', function(_, cb)
    hazards = not hazards
    if hazards then
        indicatorLeft = false
        indicatorRight = false
    end
    setIndicators()
    sendStatus()
    cb({ ok = true })
end)

RegisterNUICallback('toggleIndicatorLeft', function(_, cb)
    indicatorLeft = not indicatorLeft
    if indicatorLeft then
        hazards = false
        indicatorRight = false
    end
    setIndicators()
    sendStatus()
    cb({ ok = true })
end)

RegisterNUICallback('toggleIndicatorRight', function(_, cb)
    indicatorRight = not indicatorRight
    if indicatorRight then
        hazards = false
        indicatorLeft = false
    end
    setIndicators()
    sendStatus()
    cb({ ok = true })
end)

RegisterNUICallback('toggleDoor', function(data, cb)
    local veh = getVehicle()
    if veh then
        local idx = tonumber(data and data.index)
        if idx ~= nil and idx >= 0 and idx <= 5 then
            local ratio = GetVehicleDoorAngleRatio(veh, idx) or 0.0
            if ratio > 0.1 then
                SetVehicleDoorShut(veh, idx, false)
            else
                SetVehicleDoorOpen(veh, idx, false, false)
            end
        end
    end
    sendStatus()
    cb({ ok = true })
end)

RegisterNUICallback('toggleWindow', function(data, cb)
    local veh = getVehicle()
    if veh then
        local idx = tonumber(data and data.index)
        if idx ~= nil and idx >= 0 and idx <= 3 then
            windowDown[idx + 1] = not windowDown[idx + 1]
            if windowDown[idx + 1] then
                RollDownWindow(veh, idx)
            else
                RollUpWindow(veh, idx)
            end
        end
    end
    sendStatus()
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if uiOpen then
            sendStatus()
            Wait(250)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    Wait(0)
    sendVisible(false)
    sendUiConfig()
end)

CreateThread(function()
    while true do
        if inspectCamActive and uiOpen and inspectCam ~= nil and camPosTarget ~= nil and camLookTarget ~= nil then
            if camPos == nil then camPos = camPosTarget end
            if camLook == nil then camLook = camLookTarget end

            camPos = vLerp(camPos, camPosTarget, 0.04)
            camLook = vLerp(camLook, camLookTarget, 0.05)

            SetCamCoord(inspectCam, camPos.x, camPos.y, camPos.z)
            PointCamAtCoord(inspectCam, camLook.x, camLook.y, camLook.z)
            Wait(0)
        else
            Wait(200)
        end
    end
end)
