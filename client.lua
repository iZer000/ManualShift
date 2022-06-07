local manualon = true
local ready = false
local prepareshift = false

local vehicle = nil
local maxgears = 1
local selectedgear = 0
local highrpm = 0
local cruise = false


-------------------------------------------------------------------
local setGear = GetHashKey('SET_VEHICLE_CURRENT_GEAR') & 0xFFFFFFFF
function SetVehicleCurrentGear(_veh, _gear)
	Citizen.InvokeNative(setGear, _veh, _gear)
end

local nextGear = GetHashKey('SET_VEHICLE_NEXT_GEAR') & 0xFFFFFFFF
function SetVehicleNextGear(_veh, _gear)
	Citizen.InvokeNative(nextGear, _veh, _gear)
end

function ForceVehicleGear(_vehicle, _gear)
    SetVehicleNextGear(_vehicle, _gear)
	SetVehicleCurrentGear(_vehicle, _gear)
	SetVehicleNextGear(_vehicle, _gear)
end


-------------------------------------------------------------------

Citizen.CreateThread(function()
    GetInfo()

while true do

    if manualon then
        if vehicle ~= nil then
            if ready then
                ManualBrake()
                if selectedgear >= 0 then ForceVehicleGear(vehicle, selectedgear) end
            end
        end
    else
        Citizen.Wait(200)
    end

    Citizen.Wait(0)
end
end)


function GetInfo()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(300)
        local ped, newveh, class
        while manualon do
            Citizen.Wait(100)

            ped = PlayerPedId()
            newveh = GetVehiclePedIsIn(ped,false)
            class = GetVehicleClass(newveh)

            if newveh == vehicle then
            elseif newveh == 0 and vehicle ~= nil then
            vehicle = nil
            maxgears = 1
            selectedgear = 0
            ready = false
            cruise = false
            else
                if GetPedInVehicleSeat(newveh,-1) == ped then
                    if class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16 and class ~= 21 then
                        vehicle = newveh
                            maxgears = GetVehicleHighGear(newveh)
                            hbrake = GetVehicleHandlingFloat(newveh, "CHandlingData", "fHandBrakeForce")
                            if selectedgear == nil or selectedgear > maxgears then selectedgear = 0 end
                        Citizen.Wait(100)
                        ready = true
                    end
                end
            end
        end
        while not manualon do
            Citizen.Wait(300)
            ped = PlayerPedId()
            newveh = GetVehiclePedIsIn(ped,false)
            class = GetVehicleClass(newveh)

            if newveh == vehicle then
            elseif newveh == 0 and vehicle ~= nil then
                vehicle, maxgears, selectedgear, ready, cruise = nil, 1, 0, false, false
            else
                if GetPedInVehicleSeat(newveh,-1) == ped and class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16 and class ~= 21 then
                    vehicle = newveh
                end
            end
        end
    end
    end)
end


function ManualBrake()
    if manualon and ready and vehicle ~= nil then

        if selectedgear == -1 then
            SetVehicleHandbrake(vehicle, false)
            SetVehicleControlsInverted(vehicle, true)

            if GetEntitySpeedVector(vehicle, true).y >= 0.0 then
                DisableControlAction(2, 72, true)
                SetVehicleCurrentRpm(vehicle, 0.2)
            end


        elseif selectedgear == 0 then
            SetVehicleHandbrake(vehicle, true)
            SetVehicleControlsInverted(vehicle, false)
            DisableControlAction(2, 72, true)
            if IsControlPressed(0, 76) == false then
                SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
            else
                SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
            end

        else
            SetVehicleHandbrake(vehicle, false)
            SetVehicleControlsInverted(vehicle, false)
            if GetEntitySpeedVector(vehicle, true).y < 0.0 then
                 DisableControlAction(0, 72, true)
            end
        end

    end
end


Citizen.CreateThread(function() -- Anti-Hochschalt-Technik-Gedöns  -  TODO: Verbessern (WENN RPM um einiges niedriger is (oba ned 0) wia ausm PreFrame => reset auf PreFrame)
    while true do
        Citizen.Wait(0)
        if manualon and ready and vehicle ~= nil then
            highrpm = GetVehicleCurrentRpm(vehicle)
            if highrpm >= 0.90 then
                if selectedgear == 1 then
                    if GetVehicleCurrentRpm(vehicle) < 0.3 then
                        ControlRpmD(0)
                        exports['mandaiAlert']:Alert("DEBUG", "ResetRPM Trigger", 900, "info")
                    end
                    ControlRpmA(0.99)
                    ControlRpmB(0.99)
                    ControlRpmC(0.99)
                    ControlRpmD(0.99)
                else
                    ControlRpmA(highrpm)
                    ControlRpmB(highrpm)
                    ControlRpmC(highrpm)
                    if highrpm > 0.98 then highrpm = highrpm + 0.02 end
                    ControlRpmD(highrpm)
                end
            end
        else
            Citizen.Wait(300)
        end
    end
end)

function ControlRpmA(_highrpm)
    Citizen.CreateThread(function()
        while IsControlPressed(0, 71) and not prepareshift do
            Citizen.Wait(0)
            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
        end
    end)
end
function ControlRpmB(_highrpm)
    Citizen.CreateThread(function()
        while IsControlPressed(0, 71) and not prepareshift do
            SetVehicleCurrentRpm(vehicle, _highrpm)
            Citizen.Wait(0)
            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
        end
    end)
end
function ControlRpmC(_highrpm)
    Citizen.CreateThread(function()
        while IsControlPressed(0, 71) and not prepareshift do
            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
            Citizen.Wait(0)
            SetVehicleCurrentRpm(vehicle, _highrpm)
        end
    end)
end
function ControlRpmD(_highrpm)
    Citizen.CreateThread(function()
        while IsControlPressed(0, 71) and not prepareshift do
            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
            Citizen.Wait(0)

            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
            SetVehicleCurrentRpm(vehicle, _highrpm)
        end
    end)
end





local lastrpm
--[[
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if manualon and ready and vehicle ~= nil then
            lastrpm = GetVehicleCurrentRpm(vehicle)
            Citizen.Wait(120)
            while( (lastrpm - GetVehicleCurrentRpm(vehicle)) > 0.1 and not prepareshift ) do
                SetVehicleCurrentRpm(vehicle, lastrpm) 
                --exports['mandaiAlert']:Alert("DEBUG", "Reset trigerred", 60, "info")
                Citizen.Wait(0)
            end
        end
    end
end) ]]

-- Information Exports --
function i0GetCurrentGearString()
    if manualon then
        if selectedgear == -1 then return "R"
        elseif selectedgear == 0 then return "N" end
        return tostring(selectedgear)
    else
        local ySpeed = GetEntitySpeedVector(vehicle, true).y
        if ySpeed < -0.05 then return "R"
        elseif ySpeed > 0.05 then return GetVehicleCurrentGear(vehicle)
        else return "N" end
    end
end


function i0GetCurrentGearNum()
    if manualon then
        return selectedgear
    else
        local ySpeed = GetEntitySpeedVector(vehicle, true).y
        if ySpeed < -0.05 then return -1
        elseif ySpeed > 0.05 then return GetVehicleCurrentGear(vehicle)
        else return 0 end
    end
end

function i0GetHbkStatus()
    if IsControlPressed(0, 76) then return true end
    return false
end

function i0GetCruiseStatus()
    return cruise
end
-------------------------

-- Commands --
RegisterCommand("+shiftup", function()
    if ready and vehicle ~= nil then
        if selectedgear <= maxgears - 1 then
            prepareshift = true
            Citizen.Wait(30)
            selectedgear = selectedgear + 1
            Citizen.Wait(70)
            prepareshift = false
        end
    end
end)
RegisterKeyMapping("+shiftup", "-Hochschalten", "keyboard", "RSHIFT") 


RegisterCommand("+shiftdown", function()
    if ready and vehicle ~= nil then
        if selectedgear > -1 then
            prepareshift = true
            Citizen.Wait(100)
            selectedgear = selectedgear - 1
            Citizen.Wait(100)
            prepareshift = false
        end
    end
end)
RegisterKeyMapping("+shiftdown", "-Runterschalten", "keyboard", "RCONTROL")


RegisterCommand("cruisecontrol", function()
    if vehicle ~= nil and selectedgear > 0 then
        if cruise then
            cruise = false
            SetVehicleMaxSpeed(vehicle, 0.0)
        else
            cruise = true
            SetVehicleMaxSpeed(vehicle, GetEntitySpeed(vehicle))
        end
    end
end)
RegisterKeyMapping("+cruisecontrol", "-Cruisecontrol aktivieren", "keyboard", "LMENU")


RegisterCommand("manual", function() manualon = not manualon end)
--------------




-- Debug: TextHUD
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if manualon and vehicle ~= nil and ready then
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.3)
            SetTextColour(128, 128, 128, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("~r~Gang: ~w~" .. selectedgear .. " / " .. maxgears .. " ~r~KMH: ~w~" .. math.ceil(GetEntitySpeed(vehicle) * 3.6) .. " ~r~RPM: ~w~" .. GetVehicleCurrentRpm(vehicle) )
            DrawText(0.015, 0.78)
        else
            Citizen.Wait(800)
        end
    end
end)