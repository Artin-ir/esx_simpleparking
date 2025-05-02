ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local parkingLocations = Config.ParkingLocations  
local parkTime = Config.ParkTime  
local retrieveTime = Config.RetrieveTime  
local MarkerDistance = Config.MarkerDistance
local hasEnteredMarker = {}
local storedVehicle = nil

for i = 1, #parkingLocations do
    hasEnteredMarker[i] = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isInVehicle = IsPedInAnyVehicle(playerPed, false)
        local helpShown = false

        for i, pos in ipairs(parkingLocations) do
            local dist = #(playerCoords - pos)

            if dist <= MarkerDistance then
                DrawMarker(36, pos.x, pos.y, pos.z + 0.2, 0, 0, 0, 0, 0, 0, 1.4, 1.4, 1.0, 237, 27, 54, 100, false, true, 2, false, nil, nil, false)

                helpShown = true

                if dist <= 1.0 then
                    if not hasEnteredMarker[i] then
                        hasEnteredMarker[i] = true
                    end
                    if isInVehicle then
                        ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ To Park')
                    
                        if IsControlJustReleased(0, 38) then
                            local vehicle = GetVehiclePedIsIn(playerPed, false)
                            local plate = string.upper(string.gsub(GetVehicleNumberPlateText(vehicle), "^%s*(.-)%s*$", "%1"))

                            ESX.TriggerServerCallback('LP_Parking:checkVehicleOwnership', function(isOwner)
                                if isOwner then
                                    ESX.ShowNotification('Parking')

                            
                                    Citizen.Wait(parkTime)
                    
                                    local props = ESX.Game.GetVehicleProperties(vehicle)
                                    ESX.Game.DeleteVehicle(vehicle)
                                    ESX.ShowNotification("Vehicle parked successfully.")
                                    storedVehicle = props
                                    TriggerServerEvent('LP_Parking:saveVehicleData', plate)
                                else
                                    ESX.ShowNotification('This vehicle does not belong to you.')
                                end
                            end, plate)
                        end
                    else
                        if storedVehicle then
                            ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ To Retrieve Your Vehicle')

                            if IsControlJustReleased(0, 38) then
                                
                                ESX.ShowNotification('Retrieving Vehicle')
                                

                                Citizen.Wait(retrieveTime) 
                            

                                ESX.Game.SpawnVehicle(storedVehicle.model, pos, GetEntityHeading(playerPed), function(vehicle)
                                    ESX.Game.SetVehicleProperties(vehicle, storedVehicle)
                                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                    ESX.ShowNotification("Vehicle retrieved.")
                                    storedVehicle = nil
                                end)
                            end
                        else
                            ESX.ShowHelpNotification("No stored vehicle.")
                        end
                    end
                elseif dist > 1.0 and hasEnteredMarker[i] then
                    hasEnteredMarker[i] = false
                end
            elseif dist > MarkerDistance and hasEnteredMarker[i] then
                hasEnteredMarker[i] = false
            end
        end

        if not helpShown then
            ClearAllHelpMessages()
        end
    end
end)


RegisterNetEvent('LP_Parking:allowParking')
AddEventHandler('LP_Parking:allowParking', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local props = ESX.Game.GetVehicleProperties(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)

    ESX.Game.DeleteVehicle(vehicle)
    ESX.ShowNotification("Vehicle parked successfully.")
    storedVehicle = props
    TriggerServerEvent('LP_Parking:saveVehicleData', plate)
end)

RegisterNetEvent('LP_Parking:denyParking')
AddEventHandler('LP_Parking:denyParking', function()
    ESX.ShowNotification('This vehicle does not belong to you.')
end)
