-- ======================================================================
-- ULTRA MAX SPEED AUTO FARM GODLY, OG, COLLECT, UPGRADE, POWER, SPEED, REBIRTH & BUY TOOLS
-- ======================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local Player = Players.LocalPlayer

-- Executor Detect
local ExecutorName = "Unknown"
pcall(function()
    if identifyexecutor then
        ExecutorName = identifyexecutor()
    elseif getexecutorname then
        ExecutorName = getexecutorname()
    end
end)

-- Deteksi Perangkat
local Device = "Unknown"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    Device = "Mobile"
elseif UserInputService.KeyboardEnabled then
    Device = "PC"
elseif UserInputService.GamepadEnabled then
    Device = "Console"
end

-- Load UI Library
local WindUI = loadstring(game:HttpGet("https://github.com/charlesstorev2-hub/NexzanUILibrary/releases/download/NexzanHub%7COfficial/NexzanHubLibrary.lua"))()

-- Inisialisasi Window Utama
local Window = WindUI:CreateWindow({
    Title = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    Icon = "github",
    Author = "Made Nexzan",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    Transparent = true,
    Background = "https://raw.githubusercontent.com/charlesstorev2-hub/NexzanUILibrary/refs/heads/main/images.jpg",
    BackgroundImageTransparency = 0.2,
})

Window:Tag({ Title = game.Players.LocalPlayer.Name, Icon = "user", Color = Color3.fromHex("#00BFFF") })
Window:Tag({ Title = identifyexecutor and identifyexecutor() or "Unknown", Icon = "monitor", Color = Color3.fromHex("#A855F7") })
Window:Tag({ Title = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, Icon = "gamepad-2", Color = Color3.fromHex("#22C55E") })
Window:Tag({ Title = "Nexzan Hub", Icon = "shield", Color = Color3.fromHex("#3B82F6") })
Window:Tag({ Title = "v7.0.0", Icon = "badge-info", Color = Color3.fromHex("#06B6D4") })
Window:Tag({ Title = Device, Icon = "smartphone", Color = Color3.fromHex("#EC4899") })

local PlayerTag = Window:Tag({ Title = "Players: 0/0", Color = Color3.fromRGB(0, 255, 100) })
task.spawn(function()
    while true do
        PlayerTag:SetTitle("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        task.wait(1)
    end
end)

local FPSTag = Window:Tag({ Title = "FPS: 0", Icon = "activity", Color = Color3.fromRGB(100, 150, 255) })
local lastUpdate = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastUpdate >= 1 then
        local fps = math.floor(frameCount / (now - lastUpdate))
        FPSTag:SetTitle("FPS: " .. fps)
        if fps >= 50 then FPSTag:SetColor(Color3.fromRGB(0, 255, 0))
        elseif fps >= 30 then FPSTag:SetColor(Color3.fromRGB(255, 200, 0))
        else FPSTag:SetColor(Color3.fromRGB(255, 0, 0)) end
        frameCount = 0
        lastUpdate = now
    end
end)

local ClockTag = Window:Tag({ Title = "Time: 00:00:00", Icon = "clock-3", Color = Color3.fromRGB(0, 255, 255) })
task.spawn(function()
    while true do
        ClockTag:SetTitle("Time: " .. os.date("%H:%M:%S"))
        task.wait(1)
    end
end)

local PingTag = Window:Tag({ Title = "Ping: 0ms", Icon = "wifi", Color = Color3.fromRGB(100, 200, 255) })
task.spawn(function()
    while true do
        local success, ping = pcall(function()
            local pingValue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            return math.floor(pingValue)
        end)
        if success and ping then
            PingTag:SetTitle("Ping: " .. ping .. "ms")
            if ping <= 50 then PingTag:SetColor(Color3.fromRGB(0, 255, 0))
            elseif ping <= 100 then PingTag:SetColor(Color3.fromRGB(255, 200, 0))
            elseif ping <= 200 then PingTag:SetColor(Color3.fromRGB(255, 150, 0))
            else PingTag:SetColor(Color3.fromRGB(255, 0, 0)) end
        end
        task.wait(2)
    end
end)

-- ======================================================================
-- MEMBUAT TABS
-- ======================================================================
local TabMain = Window:Tab({ Title = "Main Features", Icon = "zap" })

pcall(function() Window:Divider() end)

local TabPlayerFeatures = Window:Tab({ Title = "Player Fitur", Icon = "user-check" })
local TabServer = Window:Tab({ Title = "Info Server", Icon = "server" })
local TabPlayerInfo = Window:Tab({ Title = "Info Player", Icon = "info" })
local TabThemes = Window:Tab({ Title = "Setting Thames", Icon = "palette" })

-- ======================================================================
-- VARIABEL & KOORDINAT
-- ======================================================================
local autoGodlyActive = false
local autoOGActive = false
local autoCollectActive = false
local autoUpgradeActive = false
local autoPowerActive = false
local autoSpeedActive = false
local autoRebirthActive = false
local maxFloorInput = 10 -- Dynamic Floor Input

-- Remote Events
local Events = ReplicatedStorage:WaitForChild("Events")
local RequestSlotUpgrade = Events:WaitForChild("RequestSlotUpgrade")
local PurchasePower = Events:WaitForChild("PurchasePower")
local PurchaseSpeed = Events:WaitForChild("PurchaseSpeed")
local BuyTool = Events:WaitForChild("BuyTool")
local RequestRebirth = Events:WaitForChild("RequestRebirth")

-- Mengambil Daftar Tools dari ReplicatedStorage.Tools
local availableTools = {}
pcall(function()
    local toolsFolder = ReplicatedStorage:WaitForChild("Tools", 5)
    if toolsFolder then
        for _, tool in pairs(toolsFolder:GetChildren()) do
            table.insert(availableTools, tool.Name)
        end
    end
end)

local selectedToolsList = {}

-- Koordinat Awal Scan
local scanCoords = Vector3.new(-1.90, 5.73, 721.41)

-- Koordinat TP Back (Base)
local returnCoords = Vector3.new(-0.65, 5.73, -584.89)

local infJumpActive = false
local noclipActive = false

-- Fungsi Teleport Aman
local function teleportTo(pos)
    local char = Player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        if typeof(pos) == "Vector3" then
            char.HumanoidRootPart.CFrame = CFrame.new(pos)
        elseif typeof(pos) == "CFrame" then
            char.HumanoidRootPart.CFrame = pos
        end
    end
end

-- Fungsi Pemicu Interaksi & Ubah ProximityPrompt Instant
local function triggerStealPrompt(targetPart)
    pcall(function()
        local parentObj = targetPart:IsA("Model") and targetPart or targetPart.Parent
        if parentObj then
            for _, prompt in pairs(parentObj:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    prompt.HoldDuration = 0
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait(0.05)
                        prompt:InputHoldEnd()
                    end
                end
            end
        end
    end)
end

-- Fungsi Mencari Target Berdasarkan Kata Kunci (Godly / OG)
local function findTargetByKeyword(keyword)
    local bestTarget = nil
    local shortestDistance = math.huge

    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("TextLabel") or descendant:IsA("TextMesh") or descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
            local textContent = ""
            if descendant:IsA("TextLabel") then
                textContent = descendant.Text
            elseif descendant:IsA("GuiObject") and descendant:FindFirstChildWhichIsA("TextLabel") then
                textContent = descendant:FindFirstChildWhichIsA("TextLabel").Text
            end

            if string.find(textContent:lower(), keyword:lower()) then
                local targetPart = nil
                local p = descendant.Parent
                while p and p ~= workspace do
                    if p:IsA("Model") and (p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")) then
                        targetPart = p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")
                        break
                    elseif p:IsA("BasePart") then
                        targetPart = p
                        break
                    end
                    p = p.Parent
                end

                if targetPart then
                    local dist = (targetPart.Position - scanCoords).Magnitude
                    if dist < 150 and dist < shortestDistance then
                        shortestDistance = dist
                        bestTarget = targetPart
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Fungsi Otomatis Mencari Plot Pemain
local function getMyPlot()
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, "Plot_") then
            if string.find(obj.Name, Player.Name) or string.find(obj.Name, "Nexzan_Hub") then
                return obj
            end
        end
    end
    return nil
end

-- ======================================================================
-- 1. TAB MAIN FEATURES
-- ======================================================================
TabMain:Section({ Title = "Auto Farm Brainrots" })

TabMain:Toggle({
    Title = "Auto Farm Godly",
    Description = "Otomatis Fram Godly",
    Default = false,
    Callback = function(state)
        autoGodlyActive = state
    end
})

TabMain:Toggle({
    Title = "Auto Farm OG",
    Description = "Otomatis Fram OG",
    Default = false,
    Callback = function(state)
        autoOGActive = state
    end
})

TabMain:Section({ Title = "Buy Tools Feature" })

TabMain:Dropdown({
    Title = "Pilih Tools (Multi Select)",
    Description = "Pilih Tools yang ingin dibeli.",
    Values = #availableTools > 0 and availableTools or { "Scissors", "Hammer", "Axe" },
    Multi = true,
    Default = {},
    Callback = function(selected)
        selectedToolsList = selected
    end
})

TabMain:Button({
    Title = "Buy Tools (Beli Tool Yang Dipilih)",
    Callback = function()
        pcall(function()
            if type(selectedToolsList) == "table" then
                for toolName, isSelected in pairs(selectedToolsList) do
                    if isSelected == true then
                        BuyTool:FireServer(toolName)
                        task.wait(0.05)
                    elseif type(toolName) == "number" and type(isSelected) == "string" then
                        BuyTool:FireServer(isSelected)
                        task.wait(0.05)
                    end
                end
            elseif type(selectedToolsList) == "string" then
                BuyTool:FireServer(selectedToolsList)
            end
        end)
    end
})

TabMain:Section({ Title = "Base Automation" })

TabMain:Input({
    Title = "Jumlah Max Floor",
    Description = "Masukkan jumlah lantai untuk Collect & Upgrade (Default: 10).",
    Default = "10",
    Placeholder = "Ketik angka lantai...",
    Callback = function(text)
        local num = tonumber(text)
        if num and num > 0 then
            maxFloorInput = num
        end
    end
})

TabMain:Toggle({
    Title = "Auto Collect Cash (Custom Floor)",
    Description = "Collect Cash Floor 1 sampai Floor Max (Slot 1-10).",
    Default = false,
    Callback = function(state)
        autoCollectActive = state
    end
})

TabMain:Toggle({
    Title = "Auto Upgrade (Custom Floor)",
    Description = "Otomatis Upgrade",
    Default = false,
    Callback = function(state)
        autoUpgradeActive = state
    end
})

TabMain:Toggle({
    Title = "Auto Purchase Power",
    Description = "Otomatis Upgared Power",
    Default = false,
    Callback = function(state)
        autoPowerActive = state
    end
})

TabMain:Toggle({
    Title = "Auto Purchase Speed",
    Description = "Otomatis Upgared Speed",
    Default = false,
    Callback = function(state)
        autoSpeedActive = state
    end
})

TabMain:Toggle({
    Title = "Auto Rebirth",
    Description = "Otomatis Rebirth",
    Default = false,
    Callback = function(state)
        autoRebirthActive = state
    end
})

-- Loop Utama Auto Farm (Godly & OG)
task.spawn(function()
    while true do
        if autoGodlyActive or autoOGActive then
            pcall(function()
                local keywordTarget = autoGodlyActive and "godly" or "og"
                
                teleportTo(scanCoords)
                task.wait(0.5)

                local targetPart = findTargetByKeyword(keywordTarget)

                if targetPart then
                    teleportTo(targetPart.CFrame + Vector3.new(0, 1.5, 0))
                    task.wait(0.2)

                    triggerStealPrompt(targetPart)
                    task.wait(0.3)

                    teleportTo(returnCoords)
                    task.wait(0.8)
                else
                    teleportTo(returnCoords)
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Loop Utama Fast Auto Collect Cash (FireTouch)
task.spawn(function()
    while true do
        if autoCollectActive then
            pcall(function()
                local char = Player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local myPlot = getMyPlot()

                if hrp and myPlot then
                    for floorNum = 1, maxFloorInput do
                        if not autoCollectActive then break end
                        
                        local floorObj = myPlot:FindFirstChild("Floor" .. floorNum)
                        if floorObj then
                            local slotsFolder = floorObj:FindFirstChild("Slots")
                            if slotsFolder then
                                for slotNum = 1, 10 do
                                    if not autoCollectActive then break end
                                    
                                    local slotObj = slotsFolder:FindFirstChild("Slot" .. slotNum)
                                    if slotObj then
                                        local collectBtn = slotObj:FindFirstChild("CollectButton")
                                        local touchPart = collectBtn and collectBtn:FindFirstChild("Part")

                                        if touchPart then
                                            firetouchinterest(hrp, touchPart, 0)
                                            firetouchinterest(hrp, touchPart, 1)
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(0.005)
                    end
                end
            end)
        end
        task.wait(0.05)
    end
end)

-- Loop Utama Auto Upgrade All Slots (Via Remote)
task.spawn(function()
    while true do
        if autoUpgradeActive then
            pcall(function()
                for floorNum = 1, maxFloorInput do
                    if not autoUpgradeActive then break end
                    for slotNum = 1, 10 do
                        if not autoUpgradeActive then break end
                        
                        RequestSlotUpgrade:FireServer("Floor" .. floorNum, "Slot" .. slotNum)
                        task.wait(0.01)
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- Loop Utama Auto Purchase Power
task.spawn(function()
    while true do
        if autoPowerActive then
            pcall(function()
                PurchasePower:FireServer(10)
            end)
        end
        task.wait(0.05)
    end
end)

-- Loop Utama Auto Purchase Speed
task.spawn(function()
    while true do
        if autoSpeedActive then
            pcall(function()
                PurchaseSpeed:FireServer(10)
            end)
        end
        task.wait(0.05)
    end
end)

-- Loop Utama Auto Rebirth
task.spawn(function()
    while true do
        if autoRebirthActive then
            pcall(function()
                RequestRebirth:FireServer()
            end)
        end
        task.wait(0.1)
    end
end)

-- ======================================================================
-- 2. TAB PLAYER FITUR
-- ======================================================================
TabPlayerFeatures:Section({ Title = "Movement Modifications" })

TabPlayerFeatures:Slider({
    Title = "WalkSpeed",
    Description = "Ubah kecepatan jalan karakter Anda.",
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(value)
        pcall(function()
            if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
                Player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
            end
        end)
    end
})

TabPlayerFeatures:Slider({
    Title = "JumpPower",
    Description = "Ubah kekuatan lompat karakter Anda.",
    Value = { Min = 50, Max = 500, Default = 50 },
    Callback = function(value)
        pcall(function()
            if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
                local hum = Player.Character:FindFirstChildOfClass("Humanoid")
                hum.UseJumpPower = true
                hum.JumpPower = value
            end
        end)
    end
})

TabPlayerFeatures:Section({ Title = "Physics Modifications" })

TabPlayerFeatures:Slider({
    Title = "Gravity",
    Description = "Ubah gravitasi game (Bawaan: 196.2).",
    Value = { Min = 0, Max = 300, Default = workspace.Gravity },
    Callback = function(value)
        workspace.Gravity = value
    end
})

TabPlayerFeatures:Toggle({
    Title = "Infinite Jump",
    Description = "Bisa melompat di udara berkali-kali tanpa batas.",
    Default = false,
    Callback = function(state)
        infJumpActive = state
    end
})

TabPlayerFeatures:Toggle({
    Title = "Noclip",
    Description = "Bisa menembus dinding dan objek padat.",
    Default = false,
    Callback = function(state)
        noclipActive = state
    end
})

UserInputService.JumpRequest:Connect(function()
    if infJumpActive then
        local char = Player.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ======================================================================
-- 3. TAB BAWAH: INFO SERVER
-- ======================================================================
TabServer:Section({ Title = "Server Statistics" })

local fpsLabel = TabServer:Paragraph({ Title = "Server FPS", Desc = "Memuat..." })
local pingLabel = TabServer:Paragraph({ Title = "Ping Anda", Desc = "Memuat ping..." })
local serverTimeLabel = TabServer:Paragraph({ Title = "Waktu Server", Desc = "Memuat waktu..." })
local playerCountLabel = TabServer:Paragraph({ Title = "Jumlah Player", Desc = "Memuat..." })

TabServer:Section({ Title = "Advanced Server Data" })
TabServer:Paragraph({
    Title = "Job ID",
    Desc = game.JobId ~= "" and game.JobId or "Bermain di Roblox Studio / Singleplayer"
})

-- Penghitung FPS
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
end)

task.spawn(function()
    while true do
        pcall(function()
            local pingVal = 0
            pcall(function() pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            if pingVal == 0 then pingVal = math.random(40, 80) end
            
            pingLabel:SetDesc(pingVal .. " ms")
            serverTimeLabel:SetDesc("Jam: " .. os.date("%H:%M:%S"))
            playerCountLabel:SetDesc(#Players:GetPlayers() .. " / " .. Players.MaxPlayers)
            fpsLabel:SetDesc(frameCount .. " FPS")
            
            frameCount = 0
        end)
        task.wait(1)
    end
end)

-- ======================================================================
-- 4. TAB BAWAH: INFO PLAYER
-- ======================================================================
TabPlayerInfo:Section({ Title = "Player Information" })

TabPlayerInfo:Paragraph({ Title = "Username", Desc = Player.Name .. " (@" .. Player.DisplayName .. ")" })
TabPlayerInfo:Paragraph({ Title = "User ID", Desc = tostring(Player.UserId) })
TabPlayerInfo:Divider()
TabPlayerInfo:Section({ Title = "Live Character Stats" })

local posParagraph = TabPlayerInfo:Paragraph({ Title = "Posisi Koordinat", Desc = "Mencari posisi..." })
local healthParagraph = TabPlayerInfo:Paragraph({ Title = "Status Darah", Desc = "Memuat..." })

task.spawn(function()
    while true do
        pcall(function()
            local char = Player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
                local hrp = char.HumanoidRootPart
                local hum = char.Humanoid
                posParagraph:SetDesc(string.format("X: %.1f, Y: %.1f, Z: %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
                healthParagraph:SetDesc(math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth))
            else
                posParagraph:SetDesc("Mati")
                healthParagraph:SetDesc("0 / 0")
            end
        end)
        task.wait(0.5)
    end
end)

-- ======================================================================
-- 5. TAB BAWAH: SETTING THAMES
-- ======================================================================
TabThemes:Section({ Title = "Theme Manager" })

local themeList = WindUI:GetFluentThemes()
table.insert(themeList, "Nexzan Dark")

TabThemes:Dropdown({
    Title = "Pilih Tema UI",
    Description = "Ubah tampilan tema UI secara langsung.",
    Values = themeList,
    Default = "Nexzan Dark",
    Callback = function(selectedTheme)
        pcall(function() WindUI:SetTheme(selectedTheme) end)
    end
})

-- ======================================================================
-- BACKGROUND TASKS
-- ======================================================================

-- 1. Noclip Loop
RunService.Stepped:Connect(function()
    if noclipActive then
        pcall(function()
            local char = Player.Character
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- Notifikasi Berhasil Load
WindUI:Notify({
    Title = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    Content = "Berhasil di Muat!",
    Duration = 3
})
