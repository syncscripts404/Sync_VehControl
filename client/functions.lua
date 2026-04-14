local Framework = nil

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

local _, _ = DetectFramework()
Functions = {}