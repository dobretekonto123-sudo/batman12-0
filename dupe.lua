-- Sprawdzamy ładowanie gry w bezpieczniejszy sposób
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[CloudHub] 1. Gra załadowana pomyślnie.")

-- Zabezpieczenie przed podwójnym odpaleniem (z powiadomieniem)
if getgenv().DUPE == true then 
    warn("[CloudHub] Skrypt już działa w tle! Blokuję ponowne uruchomienie.")
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

print("[CloudHub] 2. Serwisy załadowane. Szukam Player_Data dla: " .. client.Name)

-- Dodajemy timeout (5 sekund), żeby skrypt nie wisiał w nieskończoność
local playerDataFolder = ReplicatedStorage:WaitForChild("Player_Data", 5)
if not playerDataFolder then
    warn("[CloudHub] BŁĄD CRITICAL: Nie znaleziono folderu Player_Data w ReplicatedStorage!")
    return
end

local playerData = playerDataFolder:WaitForChild(client.Name, 5)
if not playerData then
    warn("[CloudHub] BŁĄD CRITICAL: Nie znaleziono danych gracza inside Player_Data!")
    return
end

print("[CloudHub] 3. Player_Data znalezione. Szukam Remotes...")

local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local toServer = remotes and remotes:WaitForChild("To_Server", 5)
local Handle_Initiate_S = toServer and toServer:WaitForChild("Handle_Initiate_S", 5)

if not Handle_Initiate_S then
    warn("[CloudHub] BŁĄD CRITICAL: Nie znaleziono Remote Eventu Handle_Initiate_S!")
    return
end

print("[CloudHub] 4. Wszystkie instancje gotowe. Odpalam proces...")

-- ANTI-AFK
client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
end)

-- Kolejkowanie skryptu na teleport
local success, err = pcall(function()
    queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/dobretekonto123-sudo/batman12-0/refs/heads/main/dupe.lua"))()')
end)
if not success then
    warn("[CloudHub] Twój executor prawdopodobnie nie wspiera queue_on_teleport: " .. tostring(err))
end

-- INICJALIZACJA WARTOŚCI
local customProps = playerData:WaitForChild("Custom_Properties", 5)
local nezukoStuff = customProps and customProps:WaitForChild("Nezuko_pacifier_stuff", 5)
local shrinkProp = nezukoStuff and nezukoStuff:WaitForChild("Shrinkage", 5)

if not shrinkProp then
    warn("[CloudHub] BŁĄD: Nie znaleziono wartości Shrinkage!")
    return
end

Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 0)

-- GŁÓWNA LOGIKA DUPLIKACJI
local function startDupeProcess()
    print("[CloudHub] 5. Sprawdzam Backpack pod kątem Wen...")
    local wen = client.Backpack:WaitForChild("Wen", 5) -- skrócone do 5s do testu
    
    -- Faza 1: Zbieranie, jeśli nie ma przedmiotu
    if not wen then
        print("[CloudHub] Brak Wen w Backpacku. Odpalam Fazę 1 (Zbieranie)...")
        Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 69)

        while shrinkProp.Value ~= 69 do task.wait() end
        print("[CloudHub] Wartość Shrinkage zmieniona na 69.")

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

        print("[CloudHub] Znaleziono Wen w ekwipunku, zakładam...")
        local wenItem = inventoryItems:WaitForChild("Wen")
        Handle_Initiate_S:FireServer("change_equip_for_item", client, playerData.Inventory, wenItem)

        client.Backpack:WaitForChild("Wen")

        print("[CloudHub] Czekam na nabicie kwoty 150k...")
        while wenItem:WaitForChild("Amount").Value < 150000 do task.wait() end

        Handle_Initiate_S:FireServer("Change_Value", shrinkProp, 67)
        while shrinkProp.Value ~= 67 do task.wait() end

        print("[CloudHub] Faza 1 skończona. Robię Rejoin...")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
        return
    end

    -- Faza 2: Upuszczanie (Drop) i Rejoin
    print("[CloudHub] Wen wykryte w Backpacku. Odpalam Fazę 2 (Drop)...")
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
    print("[CloudHub] Przedmiot usunięty. Czekam na zwolnienie danych postaci...")

    while playerData.Parent do task.wait() end

    print("[CloudHub] Wszystko gotowe. Robię ostateczny Rejoin...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
end

task.spawn(startDupeProcess)
