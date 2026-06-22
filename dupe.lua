repeat task.wait() until game:IsLoaded()

if getgenv().DUPE then return end
getgenv().DUPE = true

warn("---------------------------------")
warn("CloudHub Dupe - Auto Execute Version")
warn("---------------------------------")

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local client = Players.LocalPlayer
local camera = workspace.CurrentCamera

local playerData = ReplicatedStorage:WaitForChild("Player_Data"):WaitForChild(client.Name)
local Handle_Initiate_S = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("To_Server"):WaitForChild("Handle_Initiate_S")

-- ANTI-AFK (Zabezpieczenie przed wyrzuceniem z serwera za bezczynność)
client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
end)

-- AUTO-EXECUTE (Utrzymuje działanie skryptu po ponownym dołączeniu)
queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/dobretekonto123-sudo/batman12-0/refs/heads/main/dupe.lua))()')

-- INICJALIZACJA
local shrinkProp = playerData:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage")
Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 0)

-- GŁÓWNA LOGIKA DUPLIKACJI
local function startDupeProcess()
    local wen = client.Backpack:WaitForChild("Wen", 10)
    
    -- Faza 1: Zbieranie, jeśli nie ma przedmiotu
    if not wen then
        Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 69)

        while shrinkProp.Value ~= 69 do task.wait() end

        local inventoryItems = playerData:WaitForChild("Inventory"):WaitForChild("Items")
        
        while not inventoryItems:FindFirstChild("Wen") do
            local bag = workspace:FindFirstChild("Money bag")
            if bag then
                if bag.Position.Y < 0 then
                    bag:Destroy()
                    break
                end
                
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

        -- Rejoin (ponowne dołączenie) po zakończeniu Fazy 1
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
        return
    end

    -- Faza 2: Upuszczanie (Drop) i Rejoin, jeśli przedmiot już istnieje
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

    -- Czekanie na poprawne usunięcie danych gracza
    while playerData.Parent do task.wait() end

    -- Ostateczny Rejoin
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
end

-- URUCHOMIENIE PROCESU
task.spawn(startDupeProcess)
