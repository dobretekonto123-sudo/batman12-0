repeat task.wait() until game:IsLoaded()
if getgenv().DUPE then return end
local Library = loadstring(game:HttpGetAsync("https://github.com/cloudman4416/Fluent_Clone/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/cloudman4416/Fluent_Clone/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/cloudman4416/Fluent_Clone/master/Addons/InterfaceManager.lua"))()

local options = Library.Options

warn("---------------------------------")

-- SERVICES
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local LocalizationService = game:GetService("LocalizationService")
local VirtualUser = game:GetService("VirtualUser")

local client = Players.LocalPlayer
local camera = workspace.CurrentCamera

playerData = ReplicatedStorage.Player_Data:WaitForChild(client.Name)

local Handle_Initiate_S = ReplicatedStorage.Remotes.To_Server:WaitForChild("Handle_Initiate_S")
local Handle_Initiate_S_ = ReplicatedStorage.Remotes.To_Server:WaitForChild("Handle_Initiate_S_")

client.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
end)

Handle_Initiate_S:FireServer("Change_Value", playerData:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage"), 0)

local viewportSize = camera.ViewportSize

local Window = Library:CreateWindow{
    Title = "Cloudhub | Project Slayer (discord.gg/wgFBpD7mRh)",
    TabWidth = math.clamp(viewportSize.X/8, 100, 150),
    Size = UDim2.fromOffset(viewportSize.X/2, viewportSize.Y/1.8),
    Resize = false, -- Resize this ^ Size according to a 1920x1080 screen, good for mobile users but may look weird on some devices
    MinSize = Vector2.new(470, 380),
    Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Obsidian",
    MinimizeKey = Enum.KeyCode.RightShift -- Used when theres no MinimizeKeybind
}

local Tabs = {
    ["Main"] = Window:AddTab({Title = "Dupe Hub", Icon = ""});
    ["Settings"] = Window:AddTab({Title = "Settings", Icon = "settings"});
}

Tabs["Main"]:AddToggle("tDupe", {
    Title = "Drop, Dupe, Rejoin";
    Default = false;
    Callback = function(Value)
        if Value then
            local wen = client.Backpack:WaitForChild("Wen", 10)
            if not wen then
                local shrink = playerData:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage")
                Handle_Initiate_S:FireServer("Change_Value", shrink, 69)

                while options.tDupe.Value and shrink.Value ~= 69 do task.wait() end
                if not options.tDupe.Value then return end

                while options.tDupe.Value and not playerData.Inventory.Items:FindFirstChild("Wen") do
                    local bag = workspace:WaitForChild("Money bag")
                    if bag.Position.Y < 0 then
                        bag:Destroy()
                        break
                    end
                    client.Character.HumanoidRootPart.CFrame = bag.CFrame
                    Handle_Initiate_S:FireServer("transfer_money_to_money_bag2", client, playerData, bag)
                    task.wait()
                end

                if not options.tDupe.Value then return end

                Handle_Initiate_S:FireServer("change_equip_for_item", client, playerData.Inventory, playerData.Inventory.Items.Wen)

                client.Backpack:WaitForChild("Wen")

                while playerData.Inventory.Items.Wen:WaitForChild("Amount").Value < 150000 do task.wait() end

                Handle_Initiate_S:FireServer("Change_Value", playerData:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage"), 67)

                while options.tDupe.Value and shrink.Value ~= 67 do task.wait() end


                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)

                return
            end
            if not options.tDupe.Value then return end
            wen.Parent = client.Character
            wen.Parent = workspace
            local tim = tick()
            while playerData.Inventory.Items:FindFirstChild("Wen") and (tick() - tim) < 5 do task.wait() end
            Handle_Initiate_S:FireServer("remove_item", playerData)

            while playerData.Parent do task.wait() end

            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
        end
    end
})

Tabs["Main"]:AddButton({
    Title = "Rejoin";
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
    end
})

Tabs["Main"]:AddButton({
    Title = "Map 1 Priv";
    Callback = function()
        TeleportService:Teleport(13883279773, client)
    end
})

Tabs["Main"]:AddButton({
    Title = "Map 2 Priv";
    Callback = function()
        TeleportService:Teleport(13883059853, client)
    end
})



makefolder("CloudHub")
makefolder("CloudHub/PJS")
makefolder("CloudHub/PJS/DUPE")
makefolder("CloudHub/PJS/" .. client.UserId)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("CloudHub")
InterfaceManager:BuildInterfaceSection(Tabs["Settings"])

SaveManager:IgnoreThemeSettings()
SaveManager:SetLibrary(Library)
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("CloudHub/PJS/DUPE/" .. client.UserId)
SaveManager:BuildConfigSection(Tabs["Settings"])

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()

getgenv().DUPE = true

--queue_on_teleport(`loadstring(readfile("Cloudhub/PJS/dupe.lua"))()`)
queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/cloudhub4416tuff/Dupe/refs/heads/main/dupe.lua"))()')
