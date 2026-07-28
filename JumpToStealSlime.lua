--[[ ======================================================================
     NEXZAN HUB | ULTRA MAX SPEED AUTO WINS
     Version : 4.0.0
     Author  : Nexzan Hub
     UI Lib  : WindUI (Footagesus) - https://footagesus.github.io/treehub-web/docs/windui

     TAB ORDER :
        Catalog
        ────────────────────────
        Main Features
        ────────────────────────
        Player Features
        Player Info
        Server Info
        Setting Theme
====================================================================== ]]

-- ======================================================================
-- SERVICES
-- ======================================================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local UserInputService    = game:GetService("UserInputService")
local Stats               = game:GetService("Stats")
local TeleportService     = game:GetService("TeleportService")
local MarketplaceService  = game:GetService("MarketplaceService")
local HttpService         = game:GetService("HttpService")
local VirtualUser         = game:GetService("VirtualUser")
local Workspace           = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- ======================================================================
-- INFORMASI HUB
-- ======================================================================
local HUB_NAME    = "Nexzan Hub"
local HUB_VERSION = "4.0.0"
local HUB_DEV     = "Nexzan Hub"
local HUB_DISCORD = "https://discord.gg/syBYFrPts"
local HUB_YOUTUBE = "https://www.youtube.com/@Nexzan_hub"
local HUB_WEBSITE = "https://scriptvaultnexzanv2www.netlify.app/"
local HUB_CREDITS = "Made by Nexzan"

-- ======================================================================
-- EXECUTOR & DEVICE DETECT
-- ======================================================================
local ExecutorName = "Unknown"
pcall(function()
    if identifyexecutor then
        ExecutorName = identifyexecutor()
    elseif getexecutorname then
        ExecutorName = getexecutorname()
    end
end)

local Device = "Unknown"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    Device = "Mobile"
elseif UserInputService.KeyboardEnabled then
    Device = "PC"
elseif UserInputService.GamepadEnabled then
    Device = "Console"
end

-- ======================================================================
-- GAME INFO
-- ======================================================================
local GameName    = "Unknown Game"
local CreatorName = "Unknown"
local CreatorId   = "0"

pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info then
        GameName    = info.Name or GameName
        CreatorName = (info.Creator and info.Creator.Name) or CreatorName
        CreatorId   = tostring((info.Creator and info.Creator.Id) or info.CreatorTargetId or 0)
    end
end)

-- ======================================================================
-- LOAD WINDUI (OFFICIAL)
-- ======================================================================
local WindUI = loadstring(game:HttpGet("https://github.com/charlesstorev2-hub/NexzanUILibrary/releases/download/NexzanHub%7COfficial/NexzanHubLibrary.lua"))()

pcall(function() WindUI:SetNotificationLower(true) end)

-- ======================================================================
-- HELPERS
-- ======================================================================
local Window

local function Notify(title, content, dur)
    pcall(function()
        WindUI:Notify({
            Title    = title or HUB_NAME,
            Content  = content or "",
            Duration = dur or 3,
            Icon     = "bell",
        })
    end)
end

local function Copy(text, label)
    local clip = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)
    local ok = false
    if clip then
        ok = pcall(clip, tostring(text))
    end
    if ok then
        Notify(HUB_NAME, (label or "Teks") .. " berhasil disalin!", 3)
    else
        Notify(HUB_NAME, "Executor tidak mendukung clipboard.", 3)
    end
end

local function SetDesc(obj, text)
    if not obj then return end
    pcall(function() obj:SetDesc(text) end)
end

local function GetHumanoid()
    local char = Player.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function GetRoot()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function Fmt(n)
    return string.format("%.1f", tonumber(n) or 0)
end

local function FmtTime(sec)
    sec = math.floor(tonumber(sec) or 0)
    return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60)
end

-- ======================================================================
-- WINDOW
-- ======================================================================
Window = WindUI:CreateWindow({
    Title            = HUB_NAME .. " | v" .. HUB_VERSION,
    Icon             = "shield",
    Author           = GameName,
    Folder           = "NexzanHub",
    Size             = UDim2.fromOffset(420, 260),
    Transparent      = true,
    Theme            = "Dark",
    Resizable        = true,
    SideBarWidth     = 170,
    HideSearchBar    = false,
    ScrollBarEnabled = true,
})

pcall(function()
    Window:EditOpenButton({
        Title        = HUB_NAME,
        Icon         = "shield",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("3B82F6"),
            Color3.fromHex("A855F7")
        ),
        Draggable = true,
        Enabled   = true,
    })
end)

-- ======================================================================
-- HEADER TAGS
-- ======================================================================
pcall(function()
    Window:Tag({ Title = Player.Name,          Icon = "user",       Color = Color3.fromHex("#00BFFF") })
    Window:Tag({ Title = ExecutorName,         Icon = "monitor",    Color = Color3.fromHex("#A855F7") })
    Window:Tag({ Title = GameName,             Icon = "gamepad-2",  Color = Color3.fromHex("#22C55E") })
    Window:Tag({ Title = "v" .. HUB_VERSION,   Icon = "badge-info", Color = Color3.fromHex("#06B6D4") })
    Window:Tag({ Title = Device,               Icon = "smartphone", Color = Color3.fromHex("#EC4899") })
end)

local PlayerTag, FPSTag, ClockTag, PingTag
pcall(function()
    PlayerTag = Window:Tag({ Title = "Players: 0/0", Icon = "users",    Color = Color3.fromRGB(0, 255, 100) })
    FPSTag    = Window:Tag({ Title = "FPS: 0",       Icon = "activity", Color = Color3.fromRGB(100, 150, 255) })
    ClockTag  = Window:Tag({ Title = "00:00:00",     Icon = "clock-3",  Color = Color3.fromRGB(0, 255, 255) })
    PingTag   = Window:Tag({ Title = "Ping: 0ms",    Icon = "wifi",     Color = Color3.fromRGB(100, 200, 255) })
end)

-- FPS global counter
local CurrentFPS  = 60
local _frames     = 0
local _lastTick   = tick()

RunService.RenderStepped:Connect(function()
    _frames = _frames + 1
    local now = tick()
    if now - _lastTick >= 1 then
        CurrentFPS = math.floor(_frames / (now - _lastTick))
        _frames    = 0
        _lastTick  = now
        pcall(function()
            if not FPSTag then return end
            FPSTag:SetTitle("FPS: " .. CurrentFPS)
            if CurrentFPS >= 50 then
                FPSTag:SetColor(Color3.fromRGB(0, 255, 0))
            elseif CurrentFPS >= 30 then
                FPSTag:SetColor(Color3.fromRGB(255, 200, 0))
            else
                FPSTag:SetColor(Color3.fromRGB(255, 0, 0))
            end
        end)
    end
end)

-- Ping global
local CurrentPing = 0
local function ReadPing()
    local ok, val = pcall(function()
        return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    if ok and val then CurrentPing = val end
    return CurrentPing
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if PlayerTag then
                PlayerTag:SetTitle("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
            end
            if ClockTag then
                ClockTag:SetTitle(os.date("%H:%M:%S"))
            end
            if PingTag then
                local p = ReadPing()
                PingTag:SetTitle("Ping: " .. p .. "ms")
                if p <= 50 then
                    PingTag:SetColor(Color3.fromRGB(0, 255, 0))
                elseif p <= 120 then
                    PingTag:SetColor(Color3.fromRGB(255, 200, 0))
                else
                    PingTag:SetColor(Color3.fromRGB(255, 0, 0))
                end
            end
        end)
    end
end)

-- ======================================================================
-- TAB ORDER  (Divider antar tab = Window:Divider())
-- ======================================================================
local TabCatalog = Window:Tab({ Title = "Catalog", Icon = "book-open", Desc = "Informasi Nexzan Hub" })

pcall(function() Window:Divider() end)

local TabMain = Window:Tab({ Title = "Main Features", Icon = "zap", Desc = "Automation utama" })

pcall(function() Window:Divider() end)

local TabPlayerFeatures = Window:Tab({ Title = "Player Features", Icon = "user-check", Desc = "Movement & utility" })
local TabPlayerInfo     = Window:Tab({ Title = "Player Info",     Icon = "user-round", Desc = "Statistik pemain" })
local TabServer         = Window:Tab({ Title = "Server Info",     Icon = "server",     Desc = "Statistik server" })
local TabThemes         = Window:Tab({ Title = "Setting Theme",   Icon = "palette",    Desc = "Ubah tema UI" })

TabCatalog:Select()

-- ======================================================================
-- STATE
-- ======================================================================
local autoFarmMoonBlockActive = false
local farmSavedPosition = nil
local autoFarmGalaxyBlockActive = false
local galaxySavedPosition = nil
local autoFarmBeachBlockActive = false
local beachSavedPosition = nil
local autoCollectCashActive = false
local autoUpgradeSlimeActive = false
local autoUpgradeJumpActive = false
local autoUpgradeCarryActive = false
local autoRebirthActive = false
local autoSellAllActive = false

local infJumpActive       = false
local infStaminaActive    = false
local sprintActive        = false
local noclipActive        = false
local flyActive           = false
local floatActive         = false
local platformStandActive = false
local antiRagdollActive   = false
local clickTeleportActive = false
local noFallDamageActive  = false
local fullHealthActive    = false

local baseWalkSpeed = 16
local sprintSpeed   = 60
local flySpeed      = 60
local savedPosition = nil

local flyBV, flyBG, flyConn = nil, nil, nil
local floatPart   = nil
local antiAfkConn = nil

local rollPlatformUI
task.spawn(function()
    pcall(function()
        rollPlatformUI = Player:WaitForChild("PlayerScripts", 10)
            :WaitForChild("Client", 10)
            :WaitForChild("RollPlatformUI", 10)
    end)
end)

-- ======================================================================
-- 1. CATALOG
-- ======================================================================
local CatOfficial = TabCatalog:Section({ Title = "Nexzan Hub Official", Icon = "sparkles", Opened = true })

CatOfficial:Paragraph({ Title = "Script Name",    Desc = "Nexzan Hub | Ultra Max Speed Auto Wins" })
CatOfficial:Paragraph({ Title = "Version Script", Desc = "v" .. HUB_VERSION })
CatOfficial:Paragraph({ Title = "Developer",      Desc = HUB_DEV })

TabCatalog:Divider()

local CatSocial = TabCatalog:Section({ Title = "Social & Community", Icon = "globe", Opened = true })

CatSocial:Paragraph({
    Title = "Discord Server",
    Desc  = HUB_DISCORD,
    Buttons = {
        { Title = "Copy", Icon = "copy", Callback = function() Copy(HUB_DISCORD, "Link Discord") end },
    }
})

CatSocial:Paragraph({
    Title = "YouTube",
    Desc  = HUB_YOUTUBE,
    Buttons = {
        { Title = "Copy", Icon = "copy", Callback = function() Copy(HUB_YOUTUBE, "Link YouTube") end },
    }
})

CatSocial:Paragraph({
    Title = "Website",
    Desc  = HUB_WEBSITE,
    Buttons = {
        { Title = "Copy", Icon = "copy", Callback = function() Copy(HUB_WEBSITE, "Link Website") end },
    }
})

TabCatalog:Divider()

local CatSession = TabCatalog:Section({ Title = "Session Information", Icon = "cpu", Opened = true })

CatSession:Paragraph({ Title = "Executor",     Desc = ExecutorName })
CatSession:Paragraph({ Title = "Device",       Desc = Device })
CatSession:Paragraph({ Title = "Current Game", Desc = GameName })
CatSession:Paragraph({ Title = "Place ID",     Desc = tostring(game.PlaceId) })
CatSession:Paragraph({ Title = "Job ID",       Desc = (game.JobId ~= "" and game.JobId) or "Studio / Local Server" })

TabCatalog:Divider()

local CatCopy = TabCatalog:Section({ Title = "Quick Copy", Icon = "clipboard-copy", Opened = true })

CatCopy:Button({
    Title = "Copy Discord",
    Desc  = "Salin link invite Discord Nexzan Hub",
    Icon  = "message-circle",
    IconAlign = "Left",
    Callback = function() Copy(HUB_DISCORD, "Link Discord") end
})

CatCopy:Button({
    Title = "Copy Website",
    Desc  = "Salin link website Nexzan Hub",
    Icon  = "link",
    IconAlign = "Left",
    Callback = function() Copy(HUB_WEBSITE, "Link Website") end
})

CatCopy:Button({
    Title = "Copy Job ID",
    Desc  = "Salin Job ID server saat ini",
    Icon  = "fingerprint",
    IconAlign = "Left",
    Callback = function() Copy(game.JobId, "Job ID") end
})

CatCopy:Button({
    Title = "Copy Place ID",
    Desc  = "Salin Place ID game saat ini",
    Icon  = "hash",
    IconAlign = "Left",
    Callback = function() Copy(tostring(game.PlaceId), "Place ID") end
})

TabCatalog:Divider()

local CatCredits = TabCatalog:Section({ Title = "Credits", Icon = "heart", Opened = true })
CatCredits:Paragraph({ Title = "Credits", Desc = HUB_CREDITS })

-- ======================================================================
-- 2. MAIN FEATURES
-- ======================================================================
local MainAutoFram = TabMain:Section({ Title = "Auto Fram", Icon = "zap", Opened = true })

-- Tambahkan ke dalam Section/Tab Main Features UI Anda
MainAutoFram:Toggle({
    Title = "Auto Farm Moon Lucky Block",
    Desc = "TP ke Moon Lucky Block, ambil otomatis, lalu kembali",
    Value = false,
    Callback = function(state)
        autoFarmMoonBlockActive = state
        if state then
            local root = GetRoot() -- Sesuaikan dengan fungsi get root character script Anda
            if root then
                farmSavedPosition = root.CFrame
            end
        end
    end
})

-- Tambahkan ke dalam Section/Tab Main Features UI Anda
MainAutoFram:Toggle({
    Title = "Auto Farm Galaxy Lucky Block",
    Desc = "TP ke Galaxy Lucky Block, ambil otomatis, lalu kembali",
    Icon = "sparkles", -- Bisa diganti "zap" atau "target"
    Value = false,
    Callback = function(state)
        autoFarmGalaxyBlockActive = state
        if state then
            local root = GetRoot() -- Sesuaikan dengan fungsi get root character script Anda
            if root then
                galaxySavedPosition = root.CFrame
            end
        end
    end
})

MainAutoFram:Toggle({
    Title = "Auto Farm Beach Lucky Block",
    Desc = "TP ke Beach Lucky Block, ambil otomatis, lalu kembali",
    Icon = "sparkles", -- Bisa disesuaikan dengan ikon pilihan Anda
    Value = false,
    Callback = function(state)
        autoFarmBeachBlockActive = state
        if state then
            local root = GetRoot() -- Menggunakan fungsi GetRoot dari script utama Anda
            if root then
                beachSavedPosition = root.CFrame
            end
        end
    end
})

local MainAutoCollectMoney = TabMain:Section({ Title = "Auto Collect Money", Icon = "coins", Opened = true })

-- Toggle untuk Auto Collect Cash (1 sampai 50)
MainAutoCollectMoney:Toggle({
    Title = "Auto Collect Cash",
    Desc = "Otomatis collect earnings",
    Icon = "wallet",
    Value = false,
    Callback = function(state)
        autoCollectCashActive = state
    end
})

-- Membuat Section Baru untuk Upgrade
local UpgradeSection = TabMain:Section({ 
    Title = "Upgrade & Progression", 
    Icon = "arrow-up-circle", -- Ikon panah ke atas yang cocok untuk upgrade
    Opened = true 
})

-- Toggle untuk Auto Upgrade Slime (1 sampai 50)
UpgradeSection:Toggle({
    Title = "Auto Upgrade Slime",
    Desc = "Otomatis upgrade slime",
    Icon = "zap",
    Value = false,
    Callback = function(state)
        autoUpgradeSlimeActive = state
    end
})

UpgradeSection:Toggle({
    Title = "Auto Upgrade Jump",
    Desc = "otomatis Upgrade Jump",
    Icon = "zap",
    Value = false,
    Callback = function(state)
        autoUpgradeJumpActive = state
    end
})

-- Toggle untuk Auto Upgrade Carry Limit
UpgradeSection:Toggle({
    Title = "Auto Upgrade Carry",
    Desc = "Otomatis Upgrade Carry",
    Icon = "package",
    Value = false,
    Callback = function(state)
        autoUpgradeCarryActive = state
    end
})

-- Section Baru / Tambahan untuk Rebirth & Sell
local FarmAutomaticSection = TabMain:Section({ 
    Title = "SellAll & Rebirth", 
    Icon = "refresh-cw", -- Ikon putar/refresh yang cocok untuk rebirth & sell
    Opened = true 
})

-- Toggle untuk Auto Rebirth
FarmAutomaticSection:Toggle({
    Title = "Auto Rebirth",
    Desc = "Otomatis Rebirth",
    Icon = "award",
    Value = false,
    Callback = function(state)
        autoRebirthActive = state
    end
})

-- Toggle untuk Auto Sell All Slimes
FarmAutomaticSection:Toggle({
    Title = "Auto Sell All",
    Desc = "Otomatis Jual Semua",
    Icon = "dollar-sign",
    Value = false,
    Callback = function(state)
        autoSellAllActive = state
    end
})

-- ======================================================================
-- 3. PLAYER FEATURES
-- ======================================================================

-- MOVEMENT ------------------------------------------------------------
local PFMove = TabPlayerFeatures:Section({ Title = "Movement", Icon = "footprints", Opened = true })

PFMove:Slider({
    Title = "WalkSpeed",
    Desc  = "Ubah kecepatan jalan karakter",
    Value = { Min = 16, Max = 500, Default = 16 },
    Step  = 1,
    Callback = function(value)
        baseWalkSpeed = value
        pcall(function()
            local hum = GetHumanoid()
            if hum and not sprintActive then hum.WalkSpeed = value end
        end)
    end
})

PFMove:Slider({
    Title = "JumpPower",
    Desc  = "Ubah kekuatan lompat karakter",
    Value = { Min = 50, Max = 500, Default = 50 },
    Step  = 1,
    Callback = function(value)
        pcall(function()
            local hum = GetHumanoid()
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower    = value
            end
        end)
    end
})

PFMove:Slider({
    Title = "HipHeight",
    Desc  = "Atur tinggi pinggul karakter dari tanah",
    Value = { Min = 0, Max = 20, Default = 0 },
    Step  = 1,
    Callback = function(value)
        pcall(function()
            local hum = GetHumanoid()
            if hum then hum.HipHeight = value end
        end)
    end
})

PFMove:Slider({
    Title = "Gravity",
    Desc  = "Ubah gravitasi game (bawaan 196.2)",
    Value = { Min = 0, Max = 300, Default = 196 },
    Step  = 1,
    Callback = function(value)
        pcall(function() Workspace.Gravity = value end)
    end
})

PFMove:Slider({
    Title = "FOV",
    Desc  = "Atur Field of View kamera",
    Value = { Min = 70, Max = 120, Default = 70 },
    Step  = 1,
    Callback = function(value)
        pcall(function() Workspace.CurrentCamera.FieldOfView = value end)
    end
})

PFMove:Toggle({
    Title = "Sprint",
    Desc  = "Mode lari cepat",
    Icon  = "wind",
    Value = false,
    Callback = function(state)
        sprintActive = state
        pcall(function()
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = state and sprintSpeed or baseWalkSpeed end
        end)
    end
})

PFMove:Toggle({
    Title = "Infinite Jump",
    Desc  = "Melompat tanpa batas di udara",
    Icon  = "chevrons-up",
    Value = false,
    Callback = function(state) infJumpActive = state end
})

PFMove:Toggle({
    Title = "Infinite Stamina",
    Desc  = "Mencegah stamina berkurang",
    Icon  = "battery-full",
    Value = false,
    Callback = function(state) infStaminaActive = state end
})

TabPlayerFeatures:Divider()

-- CHARACTER -----------------------------------------------------------
local PFChar = TabPlayerFeatures:Section({ Title = "Character", Icon = "user", Opened = true })

PFChar:Button({
    Title = "Reset Character",
    Desc  = "Reset karakter (Health = 0)",
    Icon  = "skull",
    IconAlign = "Left",
    Callback = function()
        pcall(function()
            local hum = GetHumanoid()
            if hum then hum.Health = 0 end
        end)
        Notify(HUB_NAME, "Character direset.", 2)
    end
})

PFChar:Button({
    Title = "Refresh Character",
    Desc  = "Respawn lalu kembali ke posisi terakhir",
    Icon  = "refresh-ccw",
    IconAlign = "Left",
    Callback = function()
        Notify(HUB_NAME, "Refreshing character...", 2)
        task.spawn(function()
            pcall(function()
                local root = GetRoot()
                local cf   = root and root.CFrame
                local hum  = GetHumanoid()
                if hum then hum.Health = 0 end
                Player.CharacterAdded:Wait()
                local newRoot = Player.Character:WaitForChild("HumanoidRootPart", 10)
                task.wait(0.4)
                if newRoot and cf then newRoot.CFrame = cf end
            end)
        end)
    end
})

PFChar:Button({
    Title = "Respawn",
    Desc  = "Melakukan respawn karakter",
    Icon  = "rotate-cw",
    IconAlign = "Left",
    Callback = function()
        pcall(function()
            if Player.Character then Player.Character:BreakJoints() end
        end)
        Notify(HUB_NAME, "Respawn...", 2)
    end
})

PFChar:Button({
    Title = "Heal Character",
    Desc  = "Memulihkan darah karakter penuh",
    Icon  = "heart-pulse",
    IconAlign = "Left",
    Callback = function()
        pcall(function()
            local hum = GetHumanoid()
            if hum then hum.Health = hum.MaxHealth end
        end)
        Notify(HUB_NAME, "Health dipulihkan.", 2)
    end
})

PFChar:Toggle({
    Title = "Full Health",
    Desc  = "Mengunci darah agar selalu penuh",
    Icon  = "shield-plus",
    Value = false,
    Callback = function(state) fullHealthActive = state end
})

PFChar:Toggle({
    Title = "No Fall Damage",
    Desc  = "Menghilangkan damage saat jatuh",
    Icon  = "feather",
    Value = false,
    Callback = function(state) noFallDamageActive = state end
})

TabPlayerFeatures:Divider()

-- PHYSICS -------------------------------------------------------------
local PFPhys = TabPlayerFeatures:Section({ Title = "Physics", Icon = "atom", Opened = true })

PFPhys:Toggle({
    Title = "Noclip",
    Desc  = "Menembus dinding dan objek padat",
    Icon  = "ghost",
    Value = false,
    Callback = function(state) noclipActive = state end
})

local function StopFly()
    pcall(function()
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        local hum = GetHumanoid()
        if hum then hum.PlatformStand = platformStandActive end
    end)
end

local function StartFly()
    local root = GetRoot()
    local hum  = GetHumanoid()
    if not root or not hum then
        flyActive = false
        Notify(HUB_NAME, "Karakter belum siap.", 3)
        return
    end

    pcall(function()
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name     = "NexzanFlyVelocity"
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent   = root

        flyBG = Instance.new("BodyGyro")
        flyBG.Name      = "NexzanFlyGyro"
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.P         = 9e4
        flyBG.CFrame    = root.CFrame
        flyBG.Parent    = root

        hum.PlatformStand = true

        flyConn = RunService.RenderStepped:Connect(function()
            if not flyActive or not flyBV or not flyBG then return end
            local cam = Workspace.CurrentCamera
            local dir = Vector3.zero

            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            end

            local h = GetHumanoid()
            if h then
                if h.MoveDirection.Magnitude > 0 then dir = dir + h.MoveDirection end
                if h.Jump then dir = dir + Vector3.new(0, 1, 0) end
            end

            if dir.Magnitude > 0 then
                flyBV.Velocity = dir.Unit * flySpeed
            else
                flyBV.Velocity = Vector3.zero
            end
            flyBG.CFrame = cam.CFrame
        end)
    end)
end

PFPhys:Toggle({
    Title = "Fly",
    Desc  = "PC: WASD + Space/Ctrl | Mobile: joystick",
    Icon  = "plane",
    Value = false,
    Callback = function(state)
        flyActive = state
        if state then StartFly() else StopFly() end
    end
})

PFPhys:Slider({
    Title = "Fly Speed",
    Desc  = "Atur kecepatan terbang",
    Value = { Min = 10, Max = 300, Default = 60 },
    Step  = 5,
    Callback = function(value) flySpeed = value end
})

PFPhys:Toggle({
    Title = "Float",
    Desc  = "Platform tak terlihat di bawah kaki",
    Icon  = "cloud",
    Value = false,
    Callback = function(state)
        floatActive = state
        if state then
            pcall(function()
                local root = GetRoot()
                if not root then return end
                floatPart = Instance.new("Part")
                floatPart.Name         = "NexzanFloatPart"
                floatPart.Size         = Vector3.new(6, 1, 6)
                floatPart.Anchored     = true
                floatPart.CanCollide   = true
                floatPart.Transparency = 1
                floatPart.Parent       = Workspace
                floatPart.CFrame       = root.CFrame * CFrame.new(0, -3.5, 0)
            end)
        else
            pcall(function()
                if floatPart then floatPart:Destroy() floatPart = nil end
            end)
        end
    end
})

PFPhys:Toggle({
    Title = "Platform Stand",
    Desc  = "Aktifkan PlatformStand pada humanoid",
    Icon  = "square-stack",
    Value = false,
    Callback = function(state)
        platformStandActive = state
        pcall(function()
            local hum = GetHumanoid()
            if hum and not flyActive then hum.PlatformStand = state end
        end)
    end
})

PFPhys:Toggle({
    Title = "Anti Ragdoll",
    Desc  = "Mencegah karakter terjatuh / ragdoll",
    Icon  = "person-standing",
    Value = false,
    Callback = function(state) antiRagdollActive = state end
})

TabPlayerFeatures:Divider()

-- TELEPORT ------------------------------------------------------------
local PFTp = TabPlayerFeatures:Section({ Title = "Teleport", Icon = "move-3d", Opened = true })

PFTp:Toggle({
    Title = "Click Teleport",
    Desc  = "PC tekan F, Mobile tap layar untuk teleport",
    Icon  = "mouse-pointer-click",
    Value = false,
    Callback = function(state)
        clickTeleportActive = state
        if state then Notify(HUB_NAME, "Click Teleport aktif.", 3) end
    end
})

PFTp:Button({
    Title = "Teleport To Spawn",
    Desc  = "Teleport ke titik spawn",
    Icon  = "flag",
    IconAlign = "Left",
    Callback = function()
        pcall(function()
            local root = GetRoot()
            if not root then return end
            local spawnCF
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("SpawnLocation") then spawnCF = v.CFrame break end
            end
            root.CFrame = (spawnCF or CFrame.new(0, 25, 0)) + Vector3.new(0, 5, 0)
        end)
        Notify(HUB_NAME, "Teleport ke Spawn.", 2)
    end
})

PFTp:Button({
    Title = "Teleport To Safe Position",
    Desc  = "Teleport ke atas untuk menghindari bahaya",
    Icon  = "shield-check",
    IconAlign = "Left",
    Callback = function()
        pcall(function()
            local root = GetRoot()
            if root then root.CFrame = root.CFrame + Vector3.new(0, 40, 0) end
        end)
        Notify(HUB_NAME, "Teleport ke posisi aman.", 2)
    end
})

PFTp:Button({
    Title = "Save Position",
    Desc  = "Simpan posisi karakter saat ini",
    Icon  = "bookmark",
    IconAlign = "Left",
    Callback = function()
        local root = GetRoot()
        if root then
            savedPosition = root.CFrame
            Notify(HUB_NAME, "Posisi tersimpan!", 2)
        else
            Notify(HUB_NAME, "Karakter tidak ditemukan.", 2)
        end
    end
})

PFTp:Button({
    Title = "Teleport To Saved Position",
    Desc  = "Kembali ke posisi yang tersimpan",
    Icon  = "map-pin",
    IconAlign = "Left",
    Callback = function()
        local root = GetRoot()
        if root and savedPosition then
            pcall(function() root.CFrame = savedPosition end)
            Notify(HUB_NAME, "Teleport ke posisi tersimpan.", 2)
        else
            Notify(HUB_NAME, "Belum ada posisi tersimpan.", 2)
        end
    end
})

TabPlayerFeatures:Divider()

-- UTILITY -------------------------------------------------------------
local PFUtil = TabPlayerFeatures:Section({ Title = "Utility", Icon = "wrench", Opened = true })

PFUtil:Toggle({
    Title = "Anti AFK",
    Desc  = "Mencegah kick otomatis karena idle",
    Icon  = "coffee",
    Value = false,
    Callback = function(state)
        if state then
            pcall(function()
                antiAfkConn = Player.Idled:Connect(function()
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                    end)
                end)
            end)
            Notify(HUB_NAME, "Anti AFK aktif.", 2)
        else
            pcall(function()
                if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
            end)
        end
    end
})

local function DoRejoin()
    Notify(HUB_NAME, "Rejoin server...", 3)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
end

local function DoServerHop()
    Notify(HUB_NAME, "Mencari server lain...", 3)
    task.spawn(function()
        local ok = pcall(function()
            local url  = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local data = HttpService:JSONDecode(game:HttpGet(url))
            local list = {}
            for _, srv in ipairs(data.data or {}) do
                if type(srv.id) == "string" and srv.id ~= game.JobId
                   and srv.playing and srv.maxPlayers and srv.playing < srv.maxPlayers then
                    table.insert(list, srv.id)
                end
            end
            if #list > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, list[math.random(1, #list)], Player)
            else
                TeleportService:Teleport(game.PlaceId, Player)
            end
        end)
        if not ok then
            pcall(function() TeleportService:Teleport(game.PlaceId, Player) end)
        end
    end)
end

PFUtil:Button({
    Title = "Rejoin Server",
    Desc  = "Masuk kembali ke server yang sama",
    Icon  = "repeat",
    IconAlign = "Left",
    Callback = DoRejoin
})

PFUtil:Button({
    Title = "Server Hop",
    Desc  = "Pindah ke server publik lain",
    Icon  = "shuffle",
    IconAlign = "Left",
    Callback = DoServerHop
})

PFUtil:Button({
    Title = "Copy Position",
    Desc  = "Salin koordinat karakter",
    Icon  = "crosshair",
    IconAlign = "Left",
    Callback = function()
        local root = GetRoot()
        if root then
            local p = root.Position
            Copy(string.format("%.2f, %.2f, %.2f", p.X, p.Y, p.Z), "Posisi")
        else
            Notify(HUB_NAME, "Karakter tidak ditemukan.", 2)
        end
    end
})

PFUtil:Button({
    Title = "Copy Username",
    Desc  = "Salin username akun Anda",
    Icon  = "user",
    IconAlign = "Left",
    Callback = function() Copy(Player.Name, "Username") end
})

PFUtil:Button({
    Title = "Copy UserID",
    Desc  = "Salin User ID akun Anda",
    Icon  = "id-card",
    IconAlign = "Left",
    Callback = function() Copy(tostring(Player.UserId), "User ID") end
})

PFUtil:Button({
    Title = "Copy JobID",
    Desc  = "Salin Job ID server saat ini",
    Icon  = "fingerprint",
    IconAlign = "Left",
    Callback = function() Copy(game.JobId, "Job ID") end
})

-- ======================================================================
-- 4. PLAYER INFO (REALTIME)
-- ======================================================================
local PIIdent = TabPlayerInfo:Section({ Title = "Identity", Icon = "badge-check", Opened = true })

local piUsername   = PIIdent:Paragraph({ Title = "Username",     Desc = Player.Name })
local piDisplay    = PIIdent:Paragraph({ Title = "Display Name", Desc = Player.DisplayName })
local piUserId     = PIIdent:Paragraph({ Title = "User ID",      Desc = tostring(Player.UserId) })
local piAccountAge = PIIdent:Paragraph({ Title = "Account Age",  Desc = Player.AccountAge .. " hari" })
local piTeam       = PIIdent:Paragraph({ Title = "Team",         Desc = "Memuat..." })
local piExecutor   = PIIdent:Paragraph({ Title = "Executor",     Desc = ExecutorName })
local piDevice     = PIIdent:Paragraph({ Title = "Device",       Desc = Device })

TabPlayerInfo:Divider()

local PIChar = TabPlayerInfo:Section({ Title = "Character", Icon = "user-round", Opened = true })

local piHealth    = PIChar:Paragraph({ Title = "Health",         Desc = "Memuat..." })
local piMaxHealth = PIChar:Paragraph({ Title = "Max Health",     Desc = "Memuat..." })
local piWalkSpeed = PIChar:Paragraph({ Title = "WalkSpeed",      Desc = "Memuat..." })
local piJumpPower = PIChar:Paragraph({ Title = "JumpPower",      Desc = "Memuat..." })
local piHipHeight = PIChar:Paragraph({ Title = "HipHeight",      Desc = "Memuat..." })
local piHumState  = PIChar:Paragraph({ Title = "Humanoid State", Desc = "Memuat..." })

TabPlayerInfo:Divider()

local PILive = TabPlayerInfo:Section({ Title = "Live Information", Icon = "radar", Opened = true })

local piCoordX     = PILive:Paragraph({ Title = "Coordinate X",   Desc = "0" })
local piCoordY     = PILive:Paragraph({ Title = "Coordinate Y",   Desc = "0" })
local piCoordZ     = PILive:Paragraph({ Title = "Coordinate Z",   Desc = "0" })
local piRotation   = PILive:Paragraph({ Title = "Rotation",       Desc = "0" })
local piLookVector = PILive:Paragraph({ Title = "LookVector",     Desc = "0, 0, 0" })
local piFloorMat   = PILive:Paragraph({ Title = "Floor Material", Desc = "-" })
local piTool       = PILive:Paragraph({ Title = "Current Tool",   Desc = "-" })

TabPlayerInfo:Divider()

local PIPerf = TabPlayerInfo:Section({ Title = "Performance", Icon = "cpu", Opened = true })

local piFPS    = PIPerf:Paragraph({ Title = "FPS",          Desc = "0" })
local piPing   = PIPerf:Paragraph({ Title = "Ping",         Desc = "0 ms" })
local piMemory = PIPerf:Paragraph({ Title = "Memory Usage", Desc = "0 MB" })

task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            SetDesc(piUsername,   Player.Name)
            SetDesc(piDisplay,    Player.DisplayName)
            SetDesc(piUserId,     tostring(Player.UserId))
            SetDesc(piAccountAge, Player.AccountAge .. " hari")
            SetDesc(piTeam,       Player.Team and Player.Team.Name or "No Team")
            SetDesc(piExecutor,   ExecutorName)
            SetDesc(piDevice,     Device)

            local hum  = GetHumanoid()
            local root = GetRoot()
            local char = Player.Character

            if hum then
                SetDesc(piHealth,    Fmt(hum.Health))
                SetDesc(piMaxHealth, Fmt(hum.MaxHealth))
                SetDesc(piWalkSpeed, Fmt(hum.WalkSpeed))
                SetDesc(piJumpPower, Fmt(hum.UseJumpPower and hum.JumpPower or hum.JumpHeight))
                SetDesc(piHipHeight, Fmt(hum.HipHeight))
                SetDesc(piHumState,  tostring(hum:GetState().Name))
                SetDesc(piFloorMat,  hum.FloorMaterial and hum.FloorMaterial.Name or "Air")
            else
                SetDesc(piHealth,    "0")
                SetDesc(piMaxHealth, "0")
                SetDesc(piWalkSpeed, "0")
                SetDesc(piJumpPower, "0")
                SetDesc(piHipHeight, "0")
                SetDesc(piHumState,  "Dead / Loading")
                SetDesc(piFloorMat,  "-")
            end

            if root then
                local pos  = root.Position
                local look = root.CFrame.LookVector
                local rx, ry, rz = root.CFrame:ToOrientation()
                SetDesc(piCoordX,     Fmt(pos.X))
                SetDesc(piCoordY,     Fmt(pos.Y))
                SetDesc(piCoordZ,     Fmt(pos.Z))
                SetDesc(piRotation,   string.format("X %.1f | Y %.1f | Z %.1f", math.deg(rx), math.deg(ry), math.deg(rz)))
                SetDesc(piLookVector, string.format("%.2f, %.2f, %.2f", look.X, look.Y, look.Z))
            else
                SetDesc(piCoordX, "-") SetDesc(piCoordY, "-") SetDesc(piCoordZ, "-")
                SetDesc(piRotation, "-") SetDesc(piLookVector, "-")
            end

            local tool = char and char:FindFirstChildOfClass("Tool")
            SetDesc(piTool, tool and tool.Name or "None")

            SetDesc(piFPS,  CurrentFPS .. " FPS")
            SetDesc(piPing, ReadPing() .. " ms")

            local mem = 0
            pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
            if mem == 0 then mem = collectgarbage("count") / 1024 end
            SetDesc(piMemory, string.format("%.1f MB", mem))
        end)
    end
end)

-- ======================================================================
-- 5. SERVER INFO (REALTIME)
-- ======================================================================
local SVGame = TabServer:Section({ Title = "Game Information", Icon = "gamepad-2", Opened = true })

SVGame:Paragraph({ Title = "Game Name",   Desc = GameName })
SVGame:Paragraph({ Title = "Creator",     Desc = CreatorName })
SVGame:Paragraph({ Title = "Creator ID",  Desc = CreatorId })
SVGame:Paragraph({ Title = "Place ID",    Desc = tostring(game.PlaceId) })
SVGame:Paragraph({ Title = "Universe ID", Desc = tostring(game.GameId) })
SVGame:Paragraph({ Title = "Job ID",      Desc = (game.JobId ~= "" and game.JobId) or "Studio / Local Server" })

TabServer:Divider()

local SVServer = TabServer:Section({ Title = "Server", Icon = "server", Opened = true })

local svPlayers    = SVServer:Paragraph({ Title = "Players",      Desc = "0" })
local svMaxPlayers = SVServer:Paragraph({ Title = "Max Players",  Desc = tostring(Players.MaxPlayers) })
local svServerAge  = SVServer:Paragraph({ Title = "Server Age",   Desc = "00:00:00" })
local svTime       = SVServer:Paragraph({ Title = "Current Time", Desc = "00:00:00" })

TabServer:Divider()

local SVPerf = TabServer:Section({ Title = "Performance", Icon = "cpu", Opened = true })

local svFPS     = SVPerf:Paragraph({ Title = "FPS",         Desc = "0" })
local svPing    = SVPerf:Paragraph({ Title = "Ping",        Desc = "0 ms" })
local svMemory  = SVPerf:Paragraph({ Title = "Memory",      Desc = "0 MB" })
local svPhysFPS = SVPerf:Paragraph({ Title = "Physics FPS", Desc = "0" })

TabServer:Divider()

local SVNet = TabServer:Section({ Title = "Network", Icon = "network", Opened = true })

local svReceive  = SVNet:Paragraph({ Title = "Receive",   Desc = "0 KB/s" })
local svSend     = SVNet:Paragraph({ Title = "Send",      Desc = "0 KB/s" })
local svDataPing = SVNet:Paragraph({ Title = "Data Ping", Desc = "0 ms" })

TabServer:Divider()

local SVAdv = TabServer:Section({ Title = "Advanced", Icon = "settings-2", Opened = true })

local svQuality   = SVAdv:Paragraph({ Title = "Graphics Quality",  Desc = "-" })
local svStreaming = SVAdv:Paragraph({ Title = "Streaming Enabled", Desc = "-" })
local svGravity   = SVAdv:Paragraph({ Title = "Workspace Gravity", Desc = "-" })

TabServer:Divider()

local SVAct = TabServer:Section({ Title = "Server Actions", Icon = "zap", Opened = true })

SVAct:Button({
    Title = "Copy Job ID",
    Desc  = "Salin Job ID server saat ini",
    Icon  = "fingerprint",
    IconAlign = "Left",
    Callback = function() Copy(game.JobId, "Job ID") end
})

SVAct:Button({
    Title = "Copy Place ID",
    Desc  = "Salin Place ID game saat ini",
    Icon  = "hash",
    IconAlign = "Left",
    Callback = function() Copy(tostring(game.PlaceId), "Place ID") end
})

SVAct:Button({
    Title = "Rejoin",
    Desc  = "Masuk kembali ke server yang sama",
    Icon  = "repeat",
    IconAlign = "Left",
    Callback = DoRejoin
})

SVAct:Button({
    Title = "Server Hop",
    Desc  = "Pindah ke server publik lain",
    Icon  = "shuffle",
    IconAlign = "Left",
    Callback = DoServerHop
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            SetDesc(svPlayers,    #Players:GetPlayers() .. " Player")
            SetDesc(svMaxPlayers, tostring(Players.MaxPlayers))
            SetDesc(svServerAge,  FmtTime(Workspace.DistributedGameTime))
            SetDesc(svTime,       os.date("%H:%M:%S") .. "  |  " .. os.date("%d/%m/%Y"))

            SetDesc(svFPS,  CurrentFPS .. " FPS")
            SetDesc(svPing, ReadPing() .. " ms")

            local mem = 0
            pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
            if mem == 0 then mem = collectgarbage("count") / 1024 end
            SetDesc(svMemory, string.format("%.1f MB", mem))

            local phys = 0
            pcall(function() phys = Workspace:GetRealPhysicsFPS() end)
            SetDesc(svPhysFPS, string.format("%.0f FPS", phys))

            local rec, snd, dping = 0, 0, 0
            pcall(function() rec   = Stats.Network.ServerStatsItem["Data Receive Kbps"]:GetValue() end)
            pcall(function() snd   = Stats.Network.ServerStatsItem["Data Send Kbps"]:GetValue() end)
            pcall(function() dping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
            SetDesc(svReceive,  string.format("%.2f KB/s", rec))
            SetDesc(svSend,     string.format("%.2f KB/s", snd))
            SetDesc(svDataPing, string.format("%.0f ms", dping))

            local quality = "-"
            pcall(function()
                quality = tostring(UserSettings():GetService("UserGameSettings").SavedQualityLevel)
                quality = quality:gsub("Enum.SavedQualitySetting.", "")
            end)
            SetDesc(svQuality,   quality)
            SetDesc(svStreaming, Workspace.StreamingEnabled and "Enabled" or "Disabled")
            SetDesc(svGravity,   string.format("%.1f", Workspace.Gravity))
        end)
    end
end)

-- ======================================================================
-- 6. SETTING THEME
-- ======================================================================
local ThemeSection = TabThemes:Section({ Title = "Theme Manager", Icon = "palette", Opened = true })

local themeList = {}
pcall(function()
    local themes = WindUI:GetThemes()
    if type(themes) == "table" then
        for k, v in pairs(themes) do
            if type(k) == "string" then
                table.insert(themeList, k)
            elseif type(v) == "string" then
                table.insert(themeList, v)
            end
        end
    end
end)

if #themeList == 0 then
    themeList = { "Dark", "Light", "Red", "Blue", "Green", "Purple" }
end
table.sort(themeList)

local currentTheme = "Dark"
pcall(function() currentTheme = WindUI:GetCurrentTheme() or "Dark" end)

ThemeSection:Dropdown({
    Title = "Pilih Tema UI",
    Description = "Ubah tampilan tema UI secara langsung.",
    Values = themeList,
    Default = "Dark",
    Callback = function(selectedTheme)
        pcall(function() WindUI:SetTheme(selectedTheme) end)
    end
})
TabThemes:Divider()

local ThemeExtra = TabThemes:Section({ Title = "Window Settings", Icon = "settings", Opened = true })

ThemeExtra:Input({
    Title       = "UI Scale",
    Desc        = "Masukkan angka 0.5 - 1.5 (contoh: 0.6)",
    Icon        = "scaling",
    Placeholder = "0.6",
    Value       = "0.6",
    Callback = function(text)
        local scale = tonumber(text)
        if not scale then
            Notify(HUB_NAME, "Input harus berupa angka! Contoh: 1.0", 3)
            return
        end
        if scale < 0.5 or scale > 1.5 then
            Notify(HUB_NAME, "Nilai harus antara 0.5 sampai 1.5", 3)
            return
        end
        local ok = pcall(function() Window:SetUIScale(scale) end)
        if ok then
            Notify(HUB_NAME, "UI Scale diubah ke " .. scale, 2)
        else
            Notify(HUB_NAME, "Gagal mengubah UI Scale.", 3)
        end
    end
})
ThemeExtra:Toggle({
    Title = "Transparent Window",
    Desc  = "Aktifkan efek transparan pada window",
    Icon  = "droplet",
    Value = true,
    Callback = function(state)
        pcall(function() Window:ToggleTransparency(state) end)
    end
})

ThemeExtra:Button({
    Title = "Center Window",
    Desc  = "Kembalikan window ke tengah layar",
    Icon  = "move",
    IconAlign = "Left",
    Callback = function()
        pcall(function() Window:SetToTheCenter() end)
    end
})

-- ======================================================================
-- BACKGROUND : PLAYER FEATURES
-- ======================================================================

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if not infJumpActive then return end
    pcall(function()
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end)

-- Click Teleport
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not clickTeleportActive then return end
    if input.KeyCode ~= Enum.KeyCode.F and input.UserInputType ~= Enum.UserInputType.Touch then return end
    pcall(function()
        local mouse = Player:GetMouse()
        local root  = GetRoot()
        if root and mouse and mouse.Hit then
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end)
end)

-- Noclip / Anti Ragdoll / Float
RunService.Stepped:Connect(function()
    if noclipActive then
        pcall(function()
            local char = Player.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end)
    end

    if antiRagdollActive then
        pcall(function()
            local hum = GetHumanoid()
            if not hum then return end
            if not flyActive and not platformStandActive then hum.PlatformStand = false end
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            local st = hum:GetState()
            if st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end

    if floatActive and floatPart then
        pcall(function()
            local root = GetRoot()
            if root then
                floatPart.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.5, root.Position.Z)
            end
        end)
    end
end)

-- Full Health / No Fall Damage / Infinite Stamina / Sprint keeper
task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local hum = GetHumanoid()
            if not hum then return end

            if fullHealthActive then hum.Health = hum.MaxHealth end

            if noFallDamageActive then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end

            if infStaminaActive then
                for _, name in ipairs({ "Stamina", "stamina", "Energy", "Sprint" }) do
                    local v = Player:FindFirstChild(name, true)
                    if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then v.Value = 100 end
                    local c = Player.Character and Player.Character:FindFirstChild(name, true)
                    if c and (c:IsA("NumberValue") or c:IsA("IntValue")) then c.Value = 100 end
                end
            end

            if sprintActive and hum.WalkSpeed < sprintSpeed then
                hum.WalkSpeed = sprintSpeed
            end
        end)
    end
end)

-- Re-apply saat respawn
Player.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        hum.WalkSpeed = sprintActive and sprintSpeed or baseWalkSpeed
        hum.StateChanged:Connect(function(_, new)
            if noFallDamageActive and new == Enum.HumanoidStateType.Landed then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then root.AssemblyLinearVelocity = Vector3.zero end
            end
        end)
    end)
end)

-- ======================================================================
-- BACKGROUND : MAIN FEATURES AUTOMATION
-- ======================================================================

task.spawn(function()
    while true do
        if autoFarmMoonBlockActive then
            pcall(function()
                -- Menggunakan fungsi GetRoot bawaan script utama Anda, atau helper standar
                local char = game:GetService("Players").LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                
                if not farmSavedPosition then
                    farmSavedPosition = root.CFrame
                end
                
                -- Cari Moon Lucky Block di dalam workspace.Live.Slimes
                local targetBlock = nil
                local slimesFolder = workspace:FindFirstChild("Live") and workspace.Live:FindFirstChild("Slimes")
                if slimesFolder then
                    for _, obj in ipairs(slimesFolder:GetChildren()) do
                        if obj.Name == "Moon Lucky Block" then
                            targetBlock = obj
                            break
                        end
                    end
                end
                
                if targetBlock then
                    local rootPart = targetBlock:FindFirstChild("RootPart")
                    local prompt = rootPart and rootPart:FindFirstChild("StealPrompt")
                    
                    if rootPart then
                        -- 1. TP tepat di atas/dekat Moon Lucky Block
                        root.CFrame = rootPart.CFrame + Vector3.new(0, 2, 0)
                        
                        -- 2. Eksekusi instan ProximityPrompt
                        if prompt and prompt:IsA("ProximityPrompt") then
                            prompt.MaxActivationDistance = 9e9
                            prompt.HoldDuration = 0
                            
                            for _ = 1, 3 do
                                fireproximityprompt(prompt)
                                task.wait(0.05)
                            end
                        end
                        
                        task.wait(0.2)
                        
                        -- 3. TP kembali ke posisi awal
                        if farmSavedPosition then
                            root.CFrame = farmSavedPosition
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if autoFarmGalaxyBlockActive then
            pcall(function()
                -- Menggunakan fungsi GetRoot bawaan script utama Anda, atau helper standar
                local char = game:GetService("Players").LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                
                if not galaxySavedPosition then
                    galaxySavedPosition = root.CFrame
                end
                
                -- Cari Galaxy Lucky Block di dalam workspace.Live.Slimes
                local targetBlock = nil
                local slimesFolder = workspace:FindFirstChild("Live") and workspace.Live:FindFirstChild("Slimes")
                if slimesFolder then
                    for _, obj in ipairs(slimesFolder:GetChildren()) do
                        if obj.Name == "Galaxy Lucky Block" then
                            targetBlock = obj
                            break
                        end
                    end
                end
                
                if targetBlock then
                    local rootPart = targetBlock:FindFirstChild("RootPart")
                    local prompt = rootPart and rootPart:FindFirstChild("StealPrompt")
                    
                    if rootPart then
                        -- 1. TP tepat di atas/dekat Galaxy Lucky Block
                        root.CFrame = rootPart.CFrame + Vector3.new(0, 2, 0)
                        
                        -- 2. Eksekusi instan ProximityPrompt
                        if prompt and prompt:IsA("ProximityPrompt") then
                            prompt.MaxActivationDistance = 9e9
                            prompt.HoldDuration = 0
                            
                            for _ = 1, 3 do
                                fireproximityprompt(prompt)
                                task.wait(0.05)
                            end
                        end
                        
                        task.wait(0.2)
                        
                        -- 3. TP kembali ke posisi awal
                        if galaxySavedPosition then
                            root.CFrame = galaxySavedPosition
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if autoFarmBeachBlockActive then
            pcall(function()
                -- Mengambil root karakter menggunakan fungsi standar/bawaan script utama
                local char = game:GetService("Players").LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                
                if not beachSavedPosition then
                    beachSavedPosition = root.CFrame
                end
                
                -- Cari Beach Lucky Block di dalam workspace.Live.Slimes
                local targetBlock = nil
                local slimesFolder = workspace:FindFirstChild("Live") and workspace.Live:FindFirstChild("Slimes")
                if slimesFolder then
                    for _, obj in ipairs(slimesFolder:GetChildren()) do
                        if obj.Name == "Beach Lucky Block" then
                            targetBlock = obj
                            break
                        end
                    end
                end
                
                if targetBlock then
                    local rootPart = targetBlock:FindFirstChild("RootPart")
                    local prompt = rootPart and rootPart:FindFirstChild("StealPrompt")
                    
                    if rootPart then
                        -- 1. TP tepat di atas/dekat Beach Lucky Block
                        root.CFrame = rootPart.CFrame + Vector3.new(0, 2, 0)
                        
                        -- 2. Eksekusi instan ProximityPrompt
                        if prompt and prompt:IsA("ProximityPrompt") then
                            prompt.MaxActivationDistance = 9e9
                            prompt.HoldDuration = 0
                            
                            for _ = 1, 3 do
                                fireproximityprompt(prompt)
                                task.wait(0.05)
                            end
                        end
                        
                        task.wait(0.2)
                        
                        -- 3. TP kembali ke posisi awal
                        if beachSavedPosition then
                            root.CFrame = beachSavedPosition
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if autoCollectCashActive then
            pcall(function()
                local remote = game:GetService("ReplicatedStorage")
                    :WaitForChild("SharedModules")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("Collect Earnings")
                
                -- Looping dari 1 sampai 100 untuk argumen
                for i = 1, 100 do
                    if not autoCollectCashActive then break end
                    local args = {
                        [1] = tostring(i)
                    }
                    remote:FireServer(unpack(args))
                    task.wait(0.01) -- Jeda singkat agar aman dan tidak overload
                end
            end)
        end
        task.wait(0.1) -- Jeda sebelum mengulang dari awal lagi
    end
end)

task.spawn(function()
    while true do
        if autoUpgradeSlimeActive then
            pcall(function()
                local remote = game:GetService("ReplicatedStorage")
                    :WaitForChild("SharedModules")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("Upgrade Slime")
                
                -- Looping dari 1 sampai 50 untuk argumen upgrade
                for i = 1, 100 do
                    if not autoUpgradeSlimeActive then break end
                    local args = {
                        [1] = tostring(i)
                    }
                    remote:FireServer(unpack(args))
                    task.wait(0.01) -- Jeda singkat agar tidak spam berlebih
                end
            end)
        end
        task.wait(0.1) -- Jeda sebelum mengulang loop dari angka 1 lagi
    end
end)

-- Background Loop untuk Auto Upgrade Jump
task.spawn(function()
    while true do
        if autoUpgradeJumpActive then
            pcall(function()
                local args = {
                    [1] = 3
                }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("SharedModules")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("Buy Speed Upgrade")
                    :FireServer(unpack(args))
            end)
            task.wait(0.1) -- Jeda spam agar tidak berlebihan
        else
            task.wait(0.5)
        end
    end
end)

-- Background Loop untuk Auto Upgrade Carry
task.spawn(function()
    while true do
        if autoUpgradeCarryActive then
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("SharedModules")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("Upgrade Carry Limit")
                    :FireServer()
            end)
            task.wait(0.1) -- Jeda spam agar tidak berlebihan
        else
            task.wait(0.5)
        end
    end
end)

-- Background Loop untuk Auto Rebirth
task.spawn(function()
    while true do
        if autoRebirthActive then
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("SharedModules")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("Rebirth")
                    :FireServer()
            end)
            task.wait(0.2) -- Jeda spam agar tidak overload
        else
            task.wait(0.5)
        end
    end
end)

-- Background Loop untuk Auto Sell All Slimes
task.spawn(function()
    while true do
        if autoSellAllActive then
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("SharedModules")
                    :WaitForChild("Network")
                    :WaitForChild("Remotes")
                    :WaitForChild("Sell All Slimes")
                    :FireServer()
            end)
            task.wait(0.2) -- Jeda spam agar tidak overload
        else
            task.wait(0.5)
        end
    end
end)

-- ======================================================================
-- LOADED
-- ======================================================================
Notify(HUB_NAME, "v" .. HUB_VERSION .. " berhasil dimuat! " .. HUB_CREDITS, 5)
