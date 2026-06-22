if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[CloudHub] 1. Gra załadowana pomyślnie.")

if getgenv().DUPE == true then 
    warn("[CloudHub] Skrypt już działa w tle!")
    return 
end
getgenv().DUPE = true

-- SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local client = Players.LocalPlayer
local camera = workspace.CurrentCamera

print("[CloudHub] 2. Szukam Player_Data dla: " .. client.Name)

local playerDataFolder = ReplicatedStorage:WaitForChild("Player_Data", 5)
local playerData = playerDataFolder and playerDataFolder:WaitForChild(client.Name, 5)

if not playerData then
    warn("[CloudHub] BŁĄD CRITICAL: Brak danych gracza!")
    return
end

local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local toServer = remotes and remotes:WaitForChild("To_Server", 5)
local Handle_Initiate_S = toServer and toServer:WaitForChild("Handle_Initiate_S", 5)

if not Handle_Initiate_S then
    warn("[CloudHub] BŁĄD CRITICAL: Brak Remote Eventu!")
    return
end

-- ANTI-AFK
client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
end)

-- Kolejkowanie skryptu (PODMIEŃ LINK NA SWÓJ RAW!)
pcall(function()
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/dobretekonto123-sudo/batman12-0/refs/heads/main/dupe.lua"))()')
end)

local shrinkProp = playerData:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage")
Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 0)

-- Funkcja do bezpiecznego Rejoina (obsługuje też Private Servery)
local function Rejoin()
    print("[CloudHub] Inicjalizacja teleportu...")
    if #Players:GetPlayers() <= 1 then
        -- Jeśli jesteś sam na serwerze (np. priv)
        TeleportService:Teleport(game.PlaceId, client)
    else
        -- Jeśli to serwer publiczny / wieloosobowy
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
    end
end

-- GŁÓWNA LOGIKA DUPLIKACJI
local function startDupeProcess()
    local wen = client.Backpack:WaitForChild("Wen", 3)
    
    -- Faza 1: Zbieranie
    if not wen then
        print("[CloudHub] Brak Wen. Odpalam Fazę 1...")
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

    -- Faza 2: Drop i Rejoin
    print("[CloudHub] Wen wykryte. Odpalam Fazę 2...")
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
    print("[CloudHub] Przedmiot usunięty. Czekam na zwolnienie danych (Max 3s)...")

    -- ROZWIĄZANIE PROBLEMU: Pętla z timeoutem 3 sekundy
    local dataWait = tick()
    while playerData and playerData.Parent and (tick() - dataWait) < 3 do 
        task.wait() 
    end

    print("[CloudHub] Czas oczekiwania minął. Robię ostateczny Rejoin...")
    Rejoin()
end

task.spawn(startDupeProcess)
