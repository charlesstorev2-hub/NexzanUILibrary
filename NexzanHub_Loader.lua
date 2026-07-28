--[[
    ============================================================
    NEXZAN HUB - LOADER 1 FILE (ALL-IN-ONE)
    ============================================================
    File ini BERISI library NexzanHub lengkap + demo.
    TINGGAL EXECUTE file ini di executor mana pun
    (Delta / Codex / Hydrogen / Wave / Solara / Synapse, PC & Mobile)
    -> UI langsung muncul. Tidak butuh readfile/workspace/internet.

    Kalau UI tidak muncul, buka console (F9) dan baca pesan
    [NexzanHub] yang muncul di awal execute.
    ============================================================
]]

local NexzanHub = (function()
--[[
    Nexzan Hub UI Library v1.0

    - Window 340 x 280 (proporsional untuk PC & Mobile)
    - Floating Minimize Pill (draggable + glow)
    - 18 Tema dari FluentPro + RGB Mode
    - Key System (modal 300 x 160)
    - Elements: Section, Button (ripple), Toggle, Slider,
      Dropdown (single/multi + search), Input, ColorPicker,
      Keybind, Paragraph / CodeBox (copy to clipboard)
    - Support executor PC & Mobile (pcall protected)
--]]

--// =========================
--// Services (cloneref safe)
--// =========================
local cloneref = (typeof(cloneref) == "function" and cloneref) or function(i) return i end
local TweenService      = cloneref(game:GetService("TweenService"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local RunService        = cloneref(game:GetService("RunService"))
local Players           = cloneref(game:GetService("Players"))
local TextService       = cloneref(game:GetService("TextService"))
local LocalPlayer       = Players.LocalPlayer -- bisa nil sesaat; semua akses dibungkus pcall

--// =========================
--// Utility
--// =========================
local function RandomString(len)
    len = len or 12
    local t = {}
    for i = 1, len do
        t[i] = string.char(math.random(97, 122))
    end
    return table.concat(t)
end

local function GetRootGui()
    local ok, res
    if typeof(gethui) == "function" then
        ok, res = pcall(gethui)
        if ok and res then return res end
    end
    if typeof(get_hidden_gui) == "function" then
        ok, res = pcall(get_hidden_gui)
        if ok and res then return res end
    end
    ok, res = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    if ok and res then return res end
    ok, res = pcall(function()
        return LocalPlayer and (LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui"))
    end)
    if ok and res then return res end
    return game:GetService("CoreGui") -- resort terakhir
end

local function ProtectGui(gui)
    if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    end
    if typeof(protect_gui) == "function" then
        pcall(protect_gui, gui)
    end
    if typeof(protectgui) == "function" then
        pcall(protectgui, gui)
    end
end

local function Tween(obj, info, props)
    local tw = TweenService:Create(obj, info or TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Round(num, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(num * m + 0.5) / m
end

local function Blend(c1, c2, a)
    return Color3.new(c1.R + (c2.R - c1.R) * a, c1.G + (c2.G - c1.G) * a, c1.B + (c2.B - c1.B) * a)
end

local function MakeDraggable(handle, target, speed)
    local dragging = false
    local dragStart, startPos
    local info = TweenInfo.new(speed or 0.12, Enum.EasingStyle.Quad)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Tween(target, info, {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            })
        end
    end)
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

--// =========================
--// Library Core
--// =========================
local NexzanHub = {
    Version = "1.0",
    Flags = {},
    Connections = {},
    ThemeRegistry = {},
    CurrentTheme = nil,
    CurrentThemeName = "",
    RGBHue = 0,
    OpenColorPickers = {},
}

NexzanHub.Icons = {
    Check       = "rbxassetid://10709790644",
    ChevronDown = "rbxassetid://10709790948",
    X           = "rbxassetid://10747384394",
    Minus       = "rbxassetid://10734896206",
    Copy        = "rbxassetid://10709812159",
    Search      = "rbxassetid://10734943674",
    Code        = "rbxassetid://10709810463",
    Key         = "rbxassetid://10723416652",
    Eye         = "rbxassetid://10723346959",
    Home        = "rbxassetid://10723407389",
    Settings    = "rbxassetid://10734950309",
    Loader      = "rbxassetid://10709810948",
}

--// =========================
--// Themes (diambil dari FluentPro)
--// =========================
NexzanHub.ThemeNames = {
    "Blood Red", "Ash Gray", "Charcoal", "Pearl White", "Neon Purple",
    "Deep Ocean", "Midnight Blue", "Royal Blue", "Galaxy Purple",
    "Cosmic Violet", "AMOLED", "RGB", "Neon Cyber", "Arctic Frost",
    "Cotton Candy", "Orange", "Cyanic", "Amber Glow",
}

-- Key map (sederhana dari palet FluentPro):
--   Accent   = warna aksen utama
--   Main     = AcrylicMain (background window)
--   Sidebar  = Tab
--   Element  = Element
--   Dark     = ElementBorder
--   Stroke   = InElementBorder
--   Text     = Text
--   SubText  = SubText
--   Hover    = Hover
--   Title    = warna teks judul "Nexzan" (putih di tema gelap, gelap di tema terang)
NexzanHub.Themes = {
    ["Blood Red"] = {
        Accent = Color3.fromRGB(180, 10, 20),
        Main = Color3.fromRGB(35, 8, 10),
        Sidebar = Color3.fromRGB(28, 5, 8),
        Element = Color3.fromRGB(130, 12, 22),
        Dark = Color3.fromRGB(18, 3, 5),
        Stroke = Color3.fromRGB(150, 18, 28),
        Text = Color3.fromRGB(255, 230, 230),
        SubText = Color3.fromRGB(210, 175, 178),
        Hover = Color3.fromRGB(180, 10, 20),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Ash Gray"] = {
        Accent = Color3.fromRGB(150, 150, 150),
        Main = Color3.fromRGB(45, 45, 45),
        Sidebar = Color3.fromRGB(35, 35, 35),
        Element = Color3.fromRGB(60, 60, 60),
        Dark = Color3.fromRGB(25, 25, 25),
        Stroke = Color3.fromRGB(90, 90, 90),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(120, 120, 120),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Charcoal"] = {
        Accent = Color3.fromRGB(120, 160, 255),
        Main = Color3.fromRGB(20, 20, 20),
        Sidebar = Color3.fromRGB(15, 15, 15),
        Element = Color3.fromRGB(35, 35, 35),
        Dark = Color3.fromRGB(12, 12, 12),
        Stroke = Color3.fromRGB(60, 60, 60),
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(170, 170, 170),
        Hover = Color3.fromRGB(90, 160, 255),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Pearl White"] = {
        Accent = Color3.fromRGB(60, 160, 255),
        Main = Color3.fromRGB(240, 240, 240),
        Sidebar = Color3.fromRGB(225, 225, 225),
        Element = Color3.fromRGB(214, 214, 214),
        Dark = Color3.fromRGB(200, 200, 200),
        Stroke = Color3.fromRGB(200, 200, 200),
        Text = Color3.fromRGB(20, 20, 20),
        SubText = Color3.fromRGB(90, 90, 90),
        Hover = Color3.fromRGB(60, 160, 255),
        Title = Color3.fromRGB(38, 38, 38),
    },
    ["Neon Purple"] = {
        Accent = Color3.fromRGB(180, 0, 255),
        Main = Color3.fromRGB(10, 0, 30),
        Sidebar = Color3.fromRGB(5, 0, 20),
        Element = Color3.fromRGB(40, 0, 90),
        Dark = Color3.fromRGB(3, 0, 12),
        Stroke = Color3.fromRGB(155, 0, 245),
        Text = Color3.fromRGB(252, 245, 255),
        SubText = Color3.fromRGB(210, 185, 255),
        Hover = Color3.fromRGB(150, 0, 255),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Deep Ocean"] = {
        Accent = Color3.fromRGB(0, 200, 255),
        Main = Color3.fromRGB(10, 25, 40),
        Sidebar = Color3.fromRGB(5, 15, 25),
        Element = Color3.fromRGB(15, 40, 60),
        Dark = Color3.fromRGB(0, 10, 20),
        Stroke = Color3.fromRGB(0, 110, 165),
        Text = Color3.fromRGB(240, 248, 255),
        SubText = Color3.fromRGB(180, 210, 230),
        Hover = Color3.fromRGB(0, 150, 200),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Midnight Blue"] = {
        Accent = Color3.fromRGB(140, 120, 240),
        Main = Color3.fromRGB(10, 8, 25),
        Sidebar = Color3.fromRGB(8, 5, 20),
        Element = Color3.fromRGB(35, 25, 85),
        Dark = Color3.fromRGB(5, 3, 15),
        Stroke = Color3.fromRGB(70, 55, 155),
        Text = Color3.fromRGB(220, 220, 255),
        SubText = Color3.fromRGB(170, 170, 210),
        Hover = Color3.fromRGB(100, 80, 200),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Royal Blue"] = {
        Accent = Color3.fromRGB(50, 120, 230),
        Main = Color3.fromRGB(10, 25, 50),
        Sidebar = Color3.fromRGB(8, 20, 45),
        Element = Color3.fromRGB(11, 45, 105),
        Dark = Color3.fromRGB(5, 15, 35),
        Stroke = Color3.fromRGB(11, 70, 160),
        Text = Color3.fromRGB(220, 235, 255),
        SubText = Color3.fromRGB(170, 190, 220),
        Hover = Color3.fromRGB(15, 82, 186),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Galaxy Purple"] = {
        Accent = Color3.fromRGB(195, 100, 255),
        Main = Color3.fromRGB(12, 5, 25),
        Sidebar = Color3.fromRGB(8, 3, 20),
        Element = Color3.fromRGB(55, 20, 95),
        Dark = Color3.fromRGB(5, 2, 14),
        Stroke = Color3.fromRGB(130, 50, 195),
        Text = Color3.fromRGB(242, 232, 255),
        SubText = Color3.fromRGB(200, 178, 228),
        Hover = Color3.fromRGB(160, 60, 220),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Cosmic Violet"] = {
        Accent = Color3.fromRGB(115, 90, 175),
        Main = Color3.fromRGB(12, 10, 22),
        Sidebar = Color3.fromRGB(8, 6, 16),
        Element = Color3.fromRGB(34, 23, 70),
        Dark = Color3.fromRGB(5, 3, 10),
        Stroke = Color3.fromRGB(60, 42, 120),
        Text = Color3.fromRGB(230, 225, 245),
        SubText = Color3.fromRGB(185, 175, 210),
        Hover = Color3.fromRGB(80, 60, 140),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["AMOLED"] = {
        Accent = Color3.fromRGB(255, 255, 255),
        Main = Color3.fromRGB(0, 0, 0),
        Sidebar = Color3.fromRGB(0, 0, 0),
        Element = Color3.fromRGB(10, 10, 10),
        Dark = Color3.fromRGB(0, 0, 0),
        Stroke = Color3.fromRGB(30, 30, 30),
        Text = Color3.fromRGB(255, 255, 255),
        SubText = Color3.fromRGB(150, 150, 150),
        Hover = Color3.fromRGB(22, 22, 22),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["RGB"] = {
        Accent = Color3.fromRGB(0, 255, 180),
        Main = Color3.fromRGB(8, 8, 14),
        Sidebar = Color3.fromRGB(5, 5, 15),
        Element = Color3.fromRGB(20, 20, 35),
        Dark = Color3.fromRGB(5, 5, 12),
        Stroke = Color3.fromRGB(0, 200, 160),
        Text = Color3.fromRGB(220, 255, 245),
        SubText = Color3.fromRGB(100, 220, 190),
        Hover = Color3.fromRGB(0, 50, 40),
        Title = Color3.fromRGB(255, 255, 255),
        IsRGB = true,
    },
    ["Neon Cyber"] = {
        Accent = Color3.fromRGB(57, 255, 20),
        Main = Color3.fromRGB(5, 10, 5),
        Sidebar = Color3.fromRGB(3, 8, 3),
        Element = Color3.fromRGB(10, 26, 10),
        Dark = Color3.fromRGB(3, 8, 3),
        Stroke = Color3.fromRGB(35, 160, 15),
        Text = Color3.fromRGB(200, 255, 190),
        SubText = Color3.fromRGB(80, 200, 60),
        Hover = Color3.fromRGB(15, 40, 15),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Arctic Frost"] = {
        Accent = Color3.fromRGB(100, 180, 240),
        Main = Color3.fromRGB(215, 235, 248),
        Sidebar = Color3.fromRGB(225, 242, 255),
        Element = Color3.fromRGB(200, 230, 248),
        Dark = Color3.fromRGB(170, 210, 238),
        Stroke = Color3.fromRGB(140, 185, 218),
        Text = Color3.fromRGB(20, 50, 80),
        SubText = Color3.fromRGB(80, 120, 155),
        Hover = Color3.fromRGB(150, 200, 235),
        Title = Color3.fromRGB(30, 60, 95),
    },
    ["Cotton Candy"] = {
        Accent = Color3.fromRGB(255, 130, 190),
        Main = Color3.fromRGB(255, 228, 248),
        Sidebar = Color3.fromRGB(255, 238, 252),
        Element = Color3.fromRGB(250, 210, 238),
        Dark = Color3.fromRGB(228, 178, 218),
        Stroke = Color3.fromRGB(235, 170, 215),
        Text = Color3.fromRGB(75, 25, 55),
        SubText = Color3.fromRGB(145, 75, 115),
        Hover = Color3.fromRGB(238, 182, 222),
        Title = Color3.fromRGB(85, 30, 65),
    },
    ["Orange"] = {
        Accent = Color3.fromRGB(255, 140, 30),
        Main = Color3.fromRGB(4, 2, 0),
        Sidebar = Color3.fromRGB(4, 2, 0),
        Element = Color3.fromRGB(22, 10, 2),
        Dark = Color3.fromRGB(0, 0, 0),
        Stroke = Color3.fromRGB(200, 90, 10),
        Text = Color3.fromRGB(255, 240, 220),
        SubText = Color3.fromRGB(220, 175, 130),
        Hover = Color3.fromRGB(255, 140, 30),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Cyanic"] = {
        Accent = Color3.fromRGB(57, 197, 187),
        Main = Color3.fromRGB(8, 18, 22),
        Sidebar = Color3.fromRGB(6, 14, 18),
        Element = Color3.fromRGB(14, 38, 46),
        Dark = Color3.fromRGB(4, 10, 14),
        Stroke = Color3.fromRGB(40, 165, 160),
        Text = Color3.fromRGB(210, 248, 246),
        SubText = Color3.fromRGB(130, 210, 205),
        Hover = Color3.fromRGB(57, 197, 187),
        Title = Color3.fromRGB(255, 255, 255),
    },
    ["Amber Glow"] = {
        Accent = Color3.fromRGB(255, 170, 40),
        Main = Color3.fromRGB(18, 10, 4),
        Sidebar = Color3.fromRGB(12, 6, 1),
        Element = Color3.fromRGB(32, 16, 4),
        Dark = Color3.fromRGB(8, 4, 1),
        Stroke = Color3.fromRGB(200, 130, 30),
        Text = Color3.fromRGB(255, 245, 225),
        SubText = Color3.fromRGB(230, 195, 145),
        Hover = Color3.fromRGB(255, 170, 40),
        Title = Color3.fromRGB(255, 255, 255),
    },
}

-- Aliases
NexzanHub.Themes["RGB Mode"] = NexzanHub.Themes["RGB"]
--// =========================
--// Theme Engine
--// =========================
local ThemeRegistry = NexzanHub.ThemeRegistry

local function Register(obj, map)
    ThemeRegistry[obj] = map
    return obj
end
NexzanHub.Register = Register

local function ResolveThemeColor(key, theme)
    if key == "Topbar" then
        return Blend(theme.Main, Color3.new(0, 0, 0), 0.18)
    end
    return theme[key]
end

function NexzanHub:ApplyTheme()
    local theme = NexzanHub.CurrentTheme
    if not theme then return end
    for obj, map in pairs(ThemeRegistry) do
        local alive = pcall(function() return obj.Parent end)
        if alive then
            for prop, key in pairs(map) do
                pcall(function()
                    if type(key) == "function" then
                        obj[prop] = key(theme)
                    else
                        obj[prop] = ResolveThemeColor(key, theme)
                    end
                end)
            end
        else
            ThemeRegistry[obj] = nil
        end
    end
end

function NexzanHub:SetTheme(name)
    if name == "RGB Mode" then name = "RGB" end
    local theme = NexzanHub.Themes[name]
    assert(theme, "[NexzanHub] Tema tidak ditemukan: " .. tostring(name))
    NexzanHub.CurrentThemeName = name
    NexzanHub.CurrentTheme = setmetatable({}, { __index = theme }) -- copy-on-write
    -- salin agar bisa override accent tanpa merusak tema aslinya
    NexzanHub:ApplyTheme()
end

function NexzanHub:GetTheme()
    return NexzanHub.CurrentTheme
end

function NexzanHub:GetThemeNames()
    return NexzanHub.ThemeNames
end

-- RGB Mode: rotasi hue accent setiap frame
RunService.Heartbeat:Connect(function(dt)
    local theme = NexzanHub.CurrentTheme
    if theme and theme.IsRGB then
        NexzanHub.RGBHue = (NexzanHub.RGBHue + dt * 0.25) % 1
        theme.Accent = Color3.fromHSV(NexzanHub.RGBHue, 0.85, 1)
        NexzanHub:ApplyTheme()
    end
end)

--// =========================
--// Notification System
--// =========================
local NotifyGui
local NotifyHolder

local function BuildNotifyHolder()
    if NotifyGui then return end
    NotifyGui = Instance.new("ScreenGui")
    NotifyGui.Name = "NexzanNotify_" .. RandomString(6)
    NotifyGui.ResetOnSpawn = false
    NotifyGui.IgnoreGuiInset = true
    NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotifyGui.DisplayOrder = 9999
    ProtectGui(NotifyGui)
    NotifyGui.Parent = GetRootGui()

    NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "Holder"
    NotifyHolder.AnchorPoint = Vector2.new(1, 0)
    NotifyHolder.Position = UDim2.new(1, -8, 0, 8)
    NotifyHolder.Size = UDim2.new(0, 210, 1, -16)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Parent = NotifyGui

    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = NotifyHolder
end

function NexzanHub:Notify(cfg)
    cfg = cfg or {}
    if not NexzanHub.CurrentTheme then
        NexzanHub:SetTheme("Blood Red")
    end
    BuildNotifyHolder()

    local duration = cfg.Duration or 3
    local theme = NexzanHub.CurrentTheme

    local box = Instance.new("Frame")
    box.BackgroundColor3 = theme.Dark
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1, 0, 0, 52)
    box.ClipsDescendants = true
    box.Parent = NotifyHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box

    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Stroke
    stroke.Transparency = 0.2
    stroke.Thickness = 1
    stroke.Parent = box

    local accentBar = Instance.new("Frame")
    accentBar.BackgroundColor3 = theme.Accent
    accentBar.BorderSizePixel = 0
    accentBar.Size = UDim2.new(0, 3, 1, -10)
    accentBar.Position = UDim2.new(0, 5, 0, 5)
    accentBar.BackgroundTransparency = 1
    accentBar.Parent = box
    local abCorner = Instance.new("UICorner")
    abCorner.CornerRadius = UDim.new(1, 0)
    abCorner.Parent = accentBar

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 16, 0, 7)
    title.Size = UDim2.new(1, -22, 0, 16)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = theme.Text
    title.TextTransparency = 1
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Text = tostring(cfg.Title or "Nexzan Hub")
    title.Parent = box

    local body = Instance.new("TextLabel")
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0, 16, 0, 23)
    body.Size = UDim2.new(1, -22, 0, 22)
    body.Font = Enum.Font.Gotham
    body.TextSize = 11
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.TextColor3 = theme.SubText
    body.TextTransparency = 1
    body.Text = tostring(cfg.Content or "")
    body.Parent = box

    local hasBody = body.Text ~= ""
    if not hasBody then
        title.Position = UDim2.new(0, 16, 0, 18)
    end
    local targetH = hasBody and 50 or 38
    box.Size = UDim2.new(1, 0, 0, hasBody and 50 or 38)

    -- animasi masuk
    box.BackgroundTransparency = 1
    stroke.Transparency = 1
    Tween(box, TweenInfo.new(0.35), { BackgroundTransparency = 0.08 })
    Tween(stroke, TweenInfo.new(0.35), { Transparency = 0.2 })
    Tween(accentBar, TweenInfo.new(0.35), { BackgroundTransparency = 0 })
    Tween(title, TweenInfo.new(0.35), { TextTransparency = 0 })
    Tween(body, TweenInfo.new(0.35), { TextTransparency = 0 })

    local closed = false
    local function close()
        if closed then return end
        closed = true
        Tween(box, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
        Tween(stroke, TweenInfo.new(0.3), { Transparency = 1 })
        Tween(accentBar, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
        Tween(title, TweenInfo.new(0.3), { TextTransparency = 1 })
        Tween(body, TweenInfo.new(0.3), { TextTransparency = 1 })
        task.wait(0.3)
        Tween(box, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 0) })
        task.wait(0.26)
        box:Destroy()
    end

    Register(box, { BackgroundColor3 = "Dark" })
    Register(stroke, { Color = "Stroke" })
    Register(accentBar, { BackgroundColor3 = "Accent" })
    Register(title, { TextColor3 = "Text" })
    Register(body, { TextColor3 = "SubText" })

    task.delay(duration, close)
    return { Close = close }
end

--// =========================
--// Window Creation
--// =========================
function NexzanHub:CreateWindow(cfg)
    cfg = cfg or {}
    if not NexzanHub.CurrentTheme then
        NexzanHub:SetTheme("Blood Red")
    end
    if cfg.Theme then -- tema dari config diutamakan
        NexzanHub:SetTheme(cfg.Theme)
    end

    local WindowSize = cfg.Size or UDim2.new(0, 340, 0, 280) -- presisi 340x280
    local ToggleKey = cfg.Keybind or cfg.ToggleKey or Enum.KeyCode.RightControl
    if type(ToggleKey) == "string" then
        local okK, resK = pcall(function() return Enum.KeyCode[ToggleKey] end)
        ToggleKey = (okK and resK) or Enum.KeyCode.RightControl
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NexzanHub_" .. RandomString(8)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 1000
    ProtectGui(gui)

    -- fallback parent: CoreGui -> PlayerGui
    local okn, errn = pcall(function()
        gui.Parent = GetRootGui()
    end)
    if not okn then
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
    end

    local Window = {
        Gui = gui,
        Tabs = {},
        CurrentTab = nil,
        Minimized = false,
        Visible = true,
        KeySystemPassed = false,
    }

    -- ===== Main Frame (340 x 280) =====
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.Size = UDim2.new(0, 0, 0, 0) -- intro tween
    Main.BackgroundColor3 = NexzanHub.CurrentTheme.Main
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Visible = false
    Main.Active = true
    Main.Parent = gui
    Register(Main, { BackgroundColor3 = "Main" })

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = Main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = NexzanHub.CurrentTheme.Stroke
    mainStroke.Transparency = 0.25
    mainStroke.Thickness = 1
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = Main
    Register(mainStroke, { Color = "Stroke" })

    -- glow ambien di belakang window
    local glowFrame = Instance.new("Frame")
    glowFrame.Name = "Glow"
    glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowFrame.Size = UDim2.new(1, 24, 1, 24)
    glowFrame.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
    glowFrame.BackgroundTransparency = 0.97
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = 0
    glowFrame.Parent = Main
    Register(glowFrame, { BackgroundColor3 = "Accent" })
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 20)
    glowCorner.Parent = glowFrame

    -- ===== Topbar =====
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 32)
    Topbar.BackgroundColor3 = NexzanHub.CurrentTheme.Main
    Topbar.BackgroundTransparency = 0
    Topbar.BorderSizePixel = 0
    Topbar.ZIndex = 5
    Topbar.Parent = Main
    Register(Topbar, { BackgroundColor3 = function(t) return Blend(t.Main, Color3.new(0,0,0), 0.18) end })

    local topbarLine = Instance.new("Frame")
    topbarLine.BorderSizePixel = 0
    topbarLine.AnchorPoint = Vector2.new(0, 1)
    topbarLine.Position = UDim2.new(0, 0, 1, 0)
    topbarLine.Size = UDim2.new(1, 0, 0, 1)
    topbarLine.BackgroundColor3 = NexzanHub.CurrentTheme.Stroke
    topbarLine.BackgroundTransparency = 0.5
    topbarLine.ZIndex = 5
    topbarLine.Parent = Topbar
    Register(topbarLine, { BackgroundColor3 = "Stroke" })

    -- accent dot
    local logoDot = Instance.new("Frame")
    logoDot.Size = UDim2.new(0, 16, 0, 16)
    logoDot.Position = UDim2.new(0, 10, 0.5, -8)
    logoDot.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
    logoDot.BorderSizePixel = 0
    logoDot.ZIndex = 6
    logoDot.Parent = Topbar
    Register(logoDot, { BackgroundColor3 = "Accent" })
    local logoDotCorner = Instance.new("UICorner")
    logoDotCorner.CornerRadius = UDim.new(0, 5)
    logoDotCorner.Parent = logoDot
    local logoDotGrad = Instance.new("UIGradient")
    logoDotGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.55, 0.55, 0.55)),
    })
    logoDotGrad.Rotation = 45
    logoDotGrad.Parent = logoDot

    -- Title: "Nexzan" (putih) + " Hub" (accent)
    local function MakeTitleLabel(parent, size, z)
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Parent = parent
        local lay = Instance.new("UIListLayout")
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Padding = UDim.new(0, 0)
        lay.Parent = holder

        local l1 = Instance.new("TextLabel")
        l1.BackgroundTransparency = 1
        l1.Font = Enum.Font.GothamBold
        l1.TextSize = size
        l1.Text = "Nexzan"
        l1.TextColor3 = NexzanHub.CurrentTheme.Title
        l1.LayoutOrder = 1
        l1.ZIndex = z
        l1.Parent = holder
        Register(l1, { TextColor3 = "Title" })

        local l2 = Instance.new("TextLabel")
        l2.BackgroundTransparency = 1
        l2.Font = Enum.Font.GothamBold
        l2.TextSize = size
        l2.Text = " Hub"
        l2.TextColor3 = NexzanHub.CurrentTheme.Accent
        l2.LayoutOrder = 2
        l2.ZIndex = z
        l2.Parent = holder
        Register(l2, { TextColor3 = "Accent" })

        local function resize()
            local s1 = TextService:GetTextSize(l1.Text, l1.TextSize, l1.Font, Vector2.new(1e5, 1e5))
            local s2 = TextService:GetTextSize(l2.Text, l2.TextSize, l2.Font, Vector2.new(1e5, 1e5))
            l1.Size = UDim2.new(0, s1.X + 1, 1, 0)
            l2.Size = UDim2.new(0, s2.X + 1, 1, 0)
            holder.Size = UDim2.new(0, s1.X + s2.X + 2, 0, size + 6)
        end
        resize()
        return holder
    end

    local titleHolder = MakeTitleLabel(Topbar, 13, 6)
    titleHolder.Position = UDim2.new(0, 32, 0.5, -9)

    -- Topbar buttons (minimize & close)
    local function MakeTopbarBtn(iconImg, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 22, 0, 22)
        btn.Position = UDim2.new(1, -8 - (order - 1) * 26, 0.5, -11)
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.BackgroundColor3 = NexzanHub.CurrentTheme.Element
        btn.BackgroundTransparency = 0.35
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 6
        btn.Parent = Topbar
        Register(btn, { BackgroundColor3 = "Element" })
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.Position = UDim2.new(0.5, 0, 0.5, 0)
        img.Size = UDim2.new(0, 12, 0, 12)
        img.Image = iconImg
        img.ImageColor3 = NexzanHub.CurrentTheme.SubText
        img.ZIndex = 7
        img.Parent = btn
        Register(img, { ImageColor3 = "SubText" })

        btn.MouseEnter:Connect(function()
            Tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0 })
            Tween(img, TweenInfo.new(0.15), { ImageColor3 = NexzanHub.CurrentTheme.Text })
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.35 })
            Tween(img, TweenInfo.new(0.15), { ImageColor3 = NexzanHub.CurrentTheme.SubText })
        end)
        return btn
    end

    local minimizeBtn = MakeTopbarBtn(NexzanHub.Icons.Minus, 2)
    local closeBtn = MakeTopbarBtn(NexzanHub.Icons.X, 1)

    -- drag window dari topbar
    MakeDraggable(Topbar, Main, 0.1)

    Window._Main = Main
    Window._WindowSize = WindowSize
    -- ===== Sidebar =====
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.new(0, 0, 0, 32)
    Sidebar.Size = UDim2.new(0, 100, 1, -32)
    Sidebar.BackgroundColor3 = NexzanHub.CurrentTheme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.ZIndex = 4
    Sidebar.Parent = Main
    Register(Sidebar, { BackgroundColor3 = "Sidebar" })

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 10)
    sidebarCorner.Parent = Sidebar

    -- patch agar hanya sudut kiri yang bulat (tutup kanan)
    local sidebarPatch = Instance.new("Frame")
    sidebarPatch.BorderSizePixel = 0
    sidebarPatch.Size = UDim2.new(0, 12, 1, 0)
    sidebarPatch.Position = UDim2.new(1, -12, 0, 0)
    sidebarPatch.BackgroundColor3 = NexzanHub.CurrentTheme.Sidebar
    sidebarPatch.ZIndex = 4
    sidebarPatch.Parent = Sidebar
    Register(sidebarPatch, { BackgroundColor3 = "Sidebar" })

    local sidebarLine = Instance.new("Frame")
    sidebarLine.BorderSizePixel = 0
    sidebarLine.AnchorPoint = Vector2.new(1, 0)
    sidebarLine.Position = UDim2.new(1, 0, 0, 0)
    sidebarLine.Size = UDim2.new(0, 1, 1, 0)
    sidebarLine.BackgroundColor3 = NexzanHub.CurrentTheme.Stroke
    sidebarLine.BackgroundTransparency = 0.5
    sidebarLine.ZIndex = 5
    sidebarLine.Parent = Sidebar
    Register(sidebarLine, { BackgroundColor3 = "Stroke" })

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "TabScroll"
    tabScroll.Position = UDim2.new(0, 5, 0, 6)
    tabScroll.Size = UDim2.new(1, -10, 1, -12)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 2
    tabScroll.ScrollBarImageColor3 = NexzanHub.CurrentTheme.Stroke
    tabScroll.ScrollBarImageTransparency = 0.4
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabScroll.ZIndex = 5
    tabScroll.Parent = Sidebar
    Register(tabScroll, { ScrollBarImageColor3 = "Stroke" })

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabScroll

    -- ===== Content Area =====
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Position = UDim2.new(0, 100, 0, 32)
    Content.Size = UDim2.new(1, -100, 1, -32)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ZIndex = 3
    Content.ClipsDescendants = true
    Content.Parent = Main
    Window._Content = Content

    -- ===== Floating Minimize Pill =====
    local Pill = Instance.new("Frame")
    Pill.Name = "MinimizePill"
    Pill.Size = UDim2.new(0, 148, 0, 32)
    Pill.Position = UDim2.new(0.5, -74, 1, -46)
    Pill.AnchorPoint = Vector2.new(0, 0)
    Pill.BackgroundColor3 = NexzanHub.CurrentTheme.Dark
    Pill.BackgroundTransparency = 0.08
    Pill.BorderSizePixel = 0
    Pill.Visible = false
    Pill.ZIndex = 50
    Pill.Active = true
    Pill.Parent = gui
    Register(Pill, { BackgroundColor3 = "Dark" })

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = Pill

    local pillStroke = Instance.new("UIStroke")
    pillStroke.Color = NexzanHub.CurrentTheme.Accent
    pillStroke.Transparency = 0.25
    pillStroke.Thickness = 1.5
    pillStroke.Parent = Pill
    Register(pillStroke, { Color = "Accent" })

    -- glow lembut di belakang pill
    local pillGlow1 = Instance.new("Frame")
    pillGlow1.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
    pillGlow1.BackgroundTransparency = 0.88
    pillGlow1.BorderSizePixel = 0
    pillGlow1.Size = UDim2.new(1, 10, 1, 10)
    pillGlow1.AnchorPoint = Vector2.new(0.5, 0.5)
    pillGlow1.Position = UDim2.new(0.5, 0, 0.5, 0)
    pillGlow1.ZIndex = -1
    pillGlow1.Parent = Pill
    Register(pillGlow1, { BackgroundColor3 = "Accent" })
    local pgCorner1 = Instance.new("UICorner")
    pgCorner1.CornerRadius = UDim.new(1, 0)
    pgCorner1.Parent = pillGlow1

    local pillGlow2 = Instance.new("Frame")
    pillGlow2.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
    pillGlow2.BackgroundTransparency = 0.94
    pillGlow2.BorderSizePixel = 0
    pillGlow2.Size = UDim2.new(1, 22, 1, 22)
    pillGlow2.AnchorPoint = Vector2.new(0.5, 0.5)
    pillGlow2.Position = UDim2.new(0.5, 0, 0.5, 0)
    pillGlow2.ZIndex = -2
    pillGlow2.Parent = Pill
    Register(pillGlow2, { BackgroundColor3 = "Accent" })
    local pgCorner2 = Instance.new("UICorner")
    pgCorner2.CornerRadius = UDim.new(1, 0)
    pgCorner2.Parent = pillGlow2

    local pillDot = Instance.new("Frame")
    pillDot.Size = UDim2.new(0, 14, 0, 14)
    pillDot.Position = UDim2.new(0, 11, 0.5, -7)
    pillDot.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
    pillDot.BorderSizePixel = 0
    pillDot.ZIndex = 51
    pillDot.Parent = Pill
    Register(pillDot, { BackgroundColor3 = "Accent" })
    local pillDotCorner = Instance.new("UICorner")
    pillDotCorner.CornerRadius = UDim.new(0, 5)
    pillDotCorner.Parent = pillDot
    local pillDotGrad = Instance.new("UIGradient")
    pillDotGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.55, 0.55, 0.55)),
    })
    pillDotGrad.Rotation = 45
    pillDotGrad.Parent = pillDot

    local pillTitle = MakeTitleLabel(Pill, 12, 51)
    pillTitle.Position = UDim2.new(0, 32, 0.5, -8)

    local pillClick = Instance.new("TextButton")
    pillClick.BackgroundTransparency = 1
    pillClick.Size = UDim2.new(1, 0, 1, 0)
    pillClick.Text = ""
    pillClick.ZIndex = 55
    pillClick.Parent = Pill

    MakeDraggable(Pill, Pill, 0.1)

    Window._Pill = Pill

    -- ===== Minimize / Restore =====
    local animating = false

    local function ShowPill()
        Pill.Visible = true
        Pill.Position = UDim2.new(0, -170, 1, -46)
        Tween(Pill, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 14, 1, -46)
        })
    end

    local function HidePill(cb)
        Tween(Pill, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(0, -170, 1, -46)
        })
        task.delay(0.35, function()
            Pill.Visible = false
            if cb then cb() end
        end)
    end

    function Window:Minimize()
        if Window.Minimized or animating then return end
        animating = true
        Window.Minimized = true
        Window._SavedPos = Main.Position -- simpan posisi drag terakhir
        local full = Window._WindowSize
        Main.ClipsDescendants = true
        -- animasi collapse ke tengah bawah
        local curPos = Main.Position
        local collapse = Tween(Main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
            Size = UDim2.new(full.X.Scale, full.X.Offset, 0, 0),
            Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset + math.floor(full.Y.Offset / 2)),
        })
        collapse.Completed:Connect(function()
            Main.Visible = false
            animating = false
        end)
        task.delay(0.18, ShowPill)
    end

    function Window:Restore()
        if not Window.Minimized or animating then return end
        animating = true
        Window.Minimized = false
        local full = Window._WindowSize
        Main.Visible = true
        local restorePos = Window._SavedPos or UDim2.new(0.5, 0, 0.5, 0)
        Main.Size = UDim2.new(full.X.Scale, full.X.Offset, 0, 0)
        Main.Position = UDim2.new(restorePos.X.Scale, restorePos.X.Offset, restorePos.Y.Scale, restorePos.Y.Offset + math.floor(full.Y.Offset / 2))
        local expand = Tween(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = full,
            Position = restorePos,
        })
        expand.Completed:Connect(function()
            animating = false
        end)
        HidePill()
    end

    function Window:ToggleMinimize()
        if Window.Minimized then
            Window:Restore()
        else
            Window:Minimize()
        end
    end

    minimizeBtn.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)

    pillClick.MouseButton1Click:Connect(function()
        Window:Restore()
    end)

    -- keybind global untuk minimize (default RightControl)
    table.insert(NexzanHub.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == ToggleKey then
            Window:ToggleMinimize()
        end
    end))

    function Window:SetKeybind(newKey)
        if type(newKey) == "string" then
            local okK, resK = pcall(function() return Enum.KeyCode[newKey] end)
            newKey = (okK and resK) or nil
        end
        if newKey then ToggleKey = newKey end
    end

    function Window:Destroy()
        for _, c in ipairs(NexzanHub.Connections) do
            pcall(function() c:Disconnect() end)
        end
        NexzanHub.Connections = {}
        Tween(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
            Size = UDim2.new(0, 0, 0, 0),
        })
        Pill.Visible = false
        task.wait(0.32)
        gui:Destroy()
        if NotifyGui then pcall(function() NotifyGui:Destroy() end) NotifyGui = nil end
    end

    -- intro open animation
    local function OpenIntro()
        Main.Visible = true
        Window.Visible = true
        local full = Window._WindowSize
        Main.Size = UDim2.new(full.X.Scale, full.X.Offset, 0, 0)
        Main.Position = UDim2.new(0.5, 0, 0.5, math.floor(full.Y.Offset / 2))
        Tween(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = full,
            Position = UDim2.new(0.5, 0, 0.5, 0),
        })
    end
    Window._OpenIntro = OpenIntro
    -- =========================
    -- Tab System
    -- =========================
    function Window:AddTab(tabCfg)
        tabCfg = tabCfg or {}
        local tabName = tabCfg.Name or "Tab"
        local tabIcon = tabCfg.Icon or NexzanHub.Icons.Code

        local Tab = { Name = tabName, Sections = {} }

        -- tombol tab di sidebar
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = NexzanHub.CurrentTheme.Element
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ClipsDescendants = true
        btn.ZIndex = 6
        btn.Parent = tabScroll
        Register(btn, { BackgroundColor3 = "Element" })
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 7)
        btnCorner.Parent = btn

        local accentMark = Instance.new("Frame")
        accentMark.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
        accentMark.BorderSizePixel = 0
        accentMark.Size = UDim2.new(0, 3, 0, 0)
        accentMark.Position = UDim2.new(0, 3, 0.5, 0)
        accentMark.AnchorPoint = Vector2.new(0, 0.5)
        accentMark.ZIndex = 7
        accentMark.BackgroundTransparency = 1
        accentMark.Parent = btn
        Register(accentMark, { BackgroundColor3 = "Accent" })
        local amCorner = Instance.new("UICorner")
        amCorner.CornerRadius = UDim.new(1, 0)
        amCorner.Parent = accentMark

        local icon = Instance.new("ImageLabel")
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.new(0, 9, 0.5, -7)
        icon.Size = UDim2.new(0, 14, 0, 14)
        icon.Image = tabIcon
        icon.ImageColor3 = NexzanHub.CurrentTheme.SubText
        icon.ZIndex = 7
        icon.Parent = btn
        Register(icon, { ImageColor3 = function(t) return Tab.Selected and t.Accent or t.SubText end })

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 28, 0, 0)
        label.Size = UDim2.new(1, -32, 1, 0)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Text = tabName
        label.TextColor3 = NexzanHub.CurrentTheme.SubText
        label.ZIndex = 7
        label.Parent = btn
        Register(label, { TextColor3 = function(t) return Tab.Selected and t.Text or t.SubText end })

        -- halaman konten
        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. tabName
        page.Size = UDim2.new(1, 0, 1, 0)
        page.Position = UDim2.new(0, 0, 0, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.ScrollBarImageColor3 = NexzanHub.CurrentTheme.Stroke
        page.ScrollBarImageTransparency = 0.4
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.ZIndex = 3
        page.Parent = Content
        Register(page, { ScrollBarImageColor3 = "Stroke" })

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 7)
        pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        pageLayout.Parent = page

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, 7)
        pagePadding.PaddingBottom = UDim.new(0, 7)
        pagePadding.PaddingLeft = UDim.new(0, 7)
        pagePadding.PaddingRight = UDim.new(0, 7)
        pagePadding.Parent = page

        Tab._Page = page
        Tab._Button = btn

        local function Select()
            for _, t in ipairs(Window.Tabs) do
                t.Selected = false
                t._Page.Visible = false
                local b = t._Button
                local mk = b:FindFirstChildOfClass("Frame")
                Tween(b, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
                if mk then Tween(mk, TweenInfo.new(0.2), { BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 0) }) end
            end
            Tab.Selected = true
            page.Visible = true
            Tween(btn, TweenInfo.new(0.2), { BackgroundTransparency = 0.15 })
            Tween(accentMark, TweenInfo.new(0.2), { BackgroundTransparency = 0, Size = UDim2.new(0, 3, 0, 16) })
            Window.CurrentTab = Tab
            NexzanHub:ApplyTheme()
        end

        Tab.Select = Select

        btn.MouseButton1Click:Connect(Select)
        btn.MouseEnter:Connect(function()
            if not Tab.Selected then
                Tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.7 })
            end
        end)
        btn.MouseLeave:Connect(function()
            if not Tab.Selected then
                Tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
            end
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            task.defer(Select)
        end

        -- =========================
        -- Section
        -- =========================
        function Tab:AddSection(secCfg)
            secCfg = secCfg or {}
            local secName = secCfg.Name or "Section"

            local Section = { Elements = {} }

            local box = Instance.new("Frame")
            box.Size = UDim2.new(1, 0, 0, 30)
            box.BackgroundColor3 = NexzanHub.CurrentTheme.Element
            box.BackgroundTransparency = 0.25
            box.BorderSizePixel = 0
            box.ZIndex = 4
            box.Parent = page
            Register(box, { BackgroundColor3 = "Element" })

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 8)
            boxCorner.Parent = box

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = NexzanHub.CurrentTheme.Stroke
            boxStroke.Transparency = 0.55
            boxStroke.Thickness = 1
            boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            boxStroke.Parent = box
            Register(boxStroke, { Color = "Stroke" })

            -- judul section
            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.new(0, 10, 0, 5)
            title.Size = UDim2.new(1, -20, 0, 16)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 11
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.TextTruncate = Enum.TextTruncate.AtEnd
            title.Text = secName
            title.TextColor3 = NexzanHub.CurrentTheme.Accent
            title.ZIndex = 5
            title.Parent = box
            Register(title, { TextColor3 = "Accent" })

            local titleLine = Instance.new("Frame")
            titleLine.BorderSizePixel = 0
            titleLine.AnchorPoint = Vector2.new(0, 1)
            titleLine.Size = UDim2.new(1, -20, 0, 1)
            titleLine.BackgroundColor3 = NexzanHub.CurrentTheme.Stroke
            titleLine.BackgroundTransparency = 0.6
            titleLine.ZIndex = 5
            titleLine.Parent = box
            Register(titleLine, { BackgroundColor3 = "Stroke" })

            -- garis judul align kanan teks
            local function AlignTitleLine()
                local ts = TextService:GetTextSize(title.Text, title.TextSize, title.Font, Vector2.new(1e5, 1e5))
                titleLine.Position = UDim2.new(0, 14 + ts.X, 0, 13)
                titleLine.Size = UDim2.new(1, -24 - ts.X, 0, 1)
            end
            task.defer(AlignTitleLine)

            -- container elemen
            local elemHolder = Instance.new("Frame")
            elemHolder.BackgroundTransparency = 1
            elemHolder.Position = UDim2.new(0, 0, 0, 22)
            elemHolder.Size = UDim2.new(1, 0, 0, 0)
            elemHolder.ZIndex = 4
            elemHolder.Parent = box

            local elemLayout = Instance.new("UIListLayout")
            elemLayout.SortOrder = Enum.SortOrder.LayoutOrder
            elemLayout.Padding = UDim.new(0, 3)
            elemLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            elemLayout.Parent = elemHolder

            local elemPadding = Instance.new("UIPadding")
            elemPadding.PaddingTop = UDim.new(0, 2)
            elemPadding.PaddingBottom = UDim.new(0, 6)
            elemPadding.PaddingLeft = UDim.new(0, 6)
            elemPadding.PaddingRight = UDim.new(0, 6)
            elemPadding.Parent = elemHolder

            -- auto resize section box
            local function UpdateSize()
                local contentH = elemLayout.AbsoluteContentSize.Y
                box.Size = UDim2.new(1, 0, 0, 22 + contentH + 8)
                elemHolder.Size = UDim2.new(1, 0, 0, contentH)
            end
            elemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSize)
            Section._UpdateSize = UpdateSize
            Section._Holder = elemHolder
            Section._Box = box
            -- =========================
            -- Element Base Helpers
            -- =========================
            local function NewRow(height)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, height or 28)
                row.BackgroundColor3 = NexzanHub.CurrentTheme.Dark
                row.BackgroundTransparency = 0.35
                row.BorderSizePixel = 0
                row.ZIndex = 5
                row.ClipsDescendants = true
                row.Parent = elemHolder
                Register(row, { BackgroundColor3 = "Dark" })
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 6)
                c.Parent = row
                return row
            end

            local function NewNameLabel(row, text)
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0, 9, 0, 0)
                lbl.Size = UDim2.new(1, -90, 1, 0)
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 11
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.Text = text
                lbl.TextColor3 = NexzanHub.CurrentTheme.Text
                lbl.ZIndex = 6
                lbl.Parent = row
                Register(lbl, { TextColor3 = "Text" })
                return lbl
            end

            local function SetFlag(flag, value)
                if flag then NexzanHub.Flags[flag] = value end
            end

            -- =========================
            -- Button (+ ripple)
            -- =========================
            function Section:AddButton(bCfg)
                bCfg = bCfg or {}
                local name = bCfg.Name or "Button"
                local callback = bCfg.Callback or function() end

                local row = NewRow(28)
                row.BackgroundTransparency = 0.1
                ThemeRegistry[row] = { BackgroundColor3 = "Element" }

                local stroke = Instance.new("UIStroke")
                stroke.Color = NexzanHub.CurrentTheme.Stroke
                stroke.Transparency = 0.7
                stroke.Thickness = 1
                stroke.Parent = row
                Register(stroke, { Color = "Stroke" })

                -- accent strip kiri
                local strip = Instance.new("Frame")
                strip.Size = UDim2.new(0, 3, 1, -10)
                strip.Position = UDim2.new(0, 5, 0, 5)
                strip.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
                strip.BorderSizePixel = 0
                strip.ZIndex = 6
                strip.Parent = row
                Register(strip, { BackgroundColor3 = "Accent" })
                local stripC = Instance.new("UICorner")
                stripC.CornerRadius = UDim.new(1, 0)
                stripC.Parent = strip

                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0, 16, 0, 0)
                lbl.Size = UDim2.new(1, -20, 1, 0)
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 11
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.Text = name
                lbl.TextColor3 = NexzanHub.CurrentTheme.Text
                lbl.ZIndex = 6
                lbl.Parent = row
                Register(lbl, { TextColor3 = "Text" })

                local click = Instance.new("TextButton")
                click.Size = UDim2.new(1, 0, 1, 0)
                click.BackgroundTransparency = 1
                click.Text = ""
                click.ZIndex = 8
                click.Parent = row

                click.MouseEnter:Connect(function()
                    Tween(row, TweenInfo.new(0.15), { BackgroundTransparency = 0 })
                    Tween(stroke, TweenInfo.new(0.15), { Transparency = 0.35 })
                    Tween(lbl, TweenInfo.new(0.15), { Position = UDim2.new(0, 18, 0, 0) })
                end)
                click.MouseLeave:Connect(function()
                    Tween(row, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 })
                    Tween(stroke, TweenInfo.new(0.15), { Transparency = 0.7 })
                    Tween(lbl, TweenInfo.new(0.15), { Position = UDim2.new(0, 16, 0, 0) })
                end)

                click.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        -- ripple effect
                        local ripple = Instance.new("Frame")
                        ripple.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
                        ripple.BackgroundTransparency = 0.5
                        ripple.BorderSizePixel = 0
                        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
                        ripple.Position = UDim2.new(0, input.Position.X - row.AbsolutePosition.X, 0, input.Position.Y - row.AbsolutePosition.Y)
                        ripple.Size = UDim2.new(0, 0, 0, 0)
                        ripple.ZIndex = 7
                        ripple.Parent = row
                        local rc = Instance.new("UICorner")
                        rc.CornerRadius = UDim.new(1, 0)
                        rc.Parent = ripple
                        local maxSize = math.max(row.AbsoluteSize.X, row.AbsoluteSize.Y) * 2.2
                        Tween(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, maxSize, 0, maxSize),
                            BackgroundTransparency = 1,
                        })
                        task.delay(0.55, function() ripple:Destroy() end)
                        task.spawn(callback)
                    end
                end)

                local api = {}
                function api:SetText(t) lbl.Text = t end
                function api:Fire() task.spawn(callback) end
                return api
            end

            -- =========================
            -- Toggle
            -- =========================
            function Section:AddToggle(tCfg)
                tCfg = tCfg or {}
                local name = tCfg.Name or "Toggle"
                local value = tCfg.Default or false
                local flag = tCfg.Flag
                local callback = tCfg.Callback or function() end

                local row = NewRow(28)
                local lbl = NewNameLabel(row, name)

                local switch = Instance.new("Frame")
                switch.Size = UDim2.new(0, 34, 0, 16)
                switch.Position = UDim2.new(1, -44, 0.5, -8)
                switch.BackgroundColor3 = NexzanHub.CurrentTheme.Stroke
                switch.BorderSizePixel = 0
                switch.ZIndex = 6
                switch.Parent = row
                Register(switch, { BackgroundColor3 = function(t) return value and t.Accent or t.Stroke end })
                local sc = Instance.new("UICorner")
                sc.CornerRadius = UDim.new(1, 0)
                sc.Parent = switch

                local knob = Instance.new("Frame")
                knob.Size = UDim2.new(0, 12, 0, 12)
                knob.Position = UDim2.new(0, 2, 0.5, -6)
                knob.BackgroundColor3 = NexzanHub.CurrentTheme.Text
                knob.BorderSizePixel = 0
                knob.ZIndex = 7
                knob.Parent = switch
                Register(knob, { BackgroundColor3 = "Text" })
                local kc = Instance.new("UICorner")
                kc.CornerRadius = UDim.new(1, 0)
                kc.Parent = knob

                local click = Instance.new("TextButton")
                click.Size = UDim2.new(1, 0, 1, 0)
                click.BackgroundTransparency = 1
                click.Text = ""
                click.ZIndex = 8
                click.Parent = row

                local api = {}

                local function Render(animate)
                    local info = animate and TweenInfo.new(0.2, Enum.EasingStyle.Quad) or TweenInfo.new(0)
                    if value then
                        Tween(switch, info, { BackgroundColor3 = NexzanHub.CurrentTheme.Accent })
                        Tween(knob, info, { Position = UDim2.new(1, -14, 0.5, -6), BackgroundColor3 = Color3.new(1, 1, 1) })
                    else
                        Tween(switch, info, { BackgroundColor3 = NexzanHub.CurrentTheme.Stroke })
                        Tween(knob, info, { Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = NexzanHub.CurrentTheme.SubText })
                    end
                end

                function api:SetValue(v, noCallback)
                    value = not not v
                    Render(true)
                    SetFlag(flag, value)
                    if not noCallback then task.spawn(callback, value) end
                end

                function api:GetValue() return value end

                click.MouseButton1Click:Connect(function()
                    api:SetValue(not value)
                end)

                click.MouseEnter:Connect(function()
                    Tween(knob, TweenInfo.new(0.15), { Size = UDim2.new(0, 13, 0, 13), Position = value and UDim2.new(1, -15, 0.5, -6.5) or UDim2.new(0, 2, 0.5, -6.5) })
                end)
                click.MouseLeave:Connect(function()
                    Tween(knob, TweenInfo.new(0.15), { Size = UDim2.new(0, 12, 0, 12) })
                    api:SetValue(value, true) -- reset posisi knob
                end)

                Render(false)
                SetFlag(flag, value)
                if tCfg.Default then task.spawn(callback, value) end
                return api
            end

            -- =========================
            -- Slider
            -- =========================
            function Section:AddSlider(sCfg)
                sCfg = sCfg or {}
                local name = sCfg.Name or "Slider"
                local min = sCfg.Min or 0
                local max = sCfg.Max or 100
                local decimals = sCfg.Rounding or sCfg.Decimals or 0
                local value = sCfg.Default or min
                local suffix = sCfg.Suffix or ""
                local flag = sCfg.Flag
                local callback = sCfg.Callback or function() end
                value = math.clamp(Round(value, decimals), min, max)

                local row = NewRow(40)
                local lbl = NewNameLabel(row, name)
                lbl.Size = UDim2.new(1, -70, 0, 16)

                local valueBox = Instance.new("Frame")
                valueBox.AnchorPoint = Vector2.new(1, 0)
                valueBox.Position = UDim2.new(1, -9, 0, 6)
                valueBox.Size = UDim2.new(0, 34, 0, 14)
                valueBox.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                valueBox.BorderSizePixel = 0
                valueBox.ZIndex = 6
                valueBox.Parent = row
                Register(valueBox, { BackgroundColor3 = "Element" })
                local vbCorner = Instance.new("UICorner")
                vbCorner.CornerRadius = UDim.new(0, 5)
                vbCorner.Parent = valueBox

                local valueLbl = Instance.new("TextLabel")
                valueLbl.BackgroundTransparency = 1
                valueLbl.Size = UDim2.new(1, 0, 1, 0)
                valueLbl.Font = Enum.Font.GothamMedium
                valueLbl.TextSize = 10
                valueLbl.TextColor3 = NexzanHub.CurrentTheme.Accent
                valueLbl.Text = tostring(value) .. suffix
                valueLbl.ZIndex = 7
                valueLbl.Parent = valueBox
                Register(valueLbl, { TextColor3 = "Accent" })

                local track = Instance.new("Frame")
                track.AnchorPoint = Vector2.new(0, 1)
                track.Position = UDim2.new(0, 10, 1, -8)
                track.Size = UDim2.new(1, -20, 0, 5)
                track.BackgroundColor3 = NexzanHub.CurrentTheme.Stroke
                track.BorderSizePixel = 0
                track.ZIndex = 6
                track.Parent = row
                Register(track, { BackgroundColor3 = "Stroke" })
                local tc = Instance.new("UICorner")
                tc.CornerRadius = UDim.new(1, 0)
                tc.Parent = track

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
                fill.BorderSizePixel = 0
                fill.ZIndex = 7
                fill.Parent = track
                Register(fill, { BackgroundColor3 = "Accent" })
                local fc = Instance.new("UICorner")
                fc.CornerRadius = UDim.new(1, 0)
                fc.Parent = fill

                local knob = Instance.new("Frame")
                knob.AnchorPoint = Vector2.new(0.5, 0.5)
                knob.Size = UDim2.new(0, 9, 0, 9)
                knob.Position = UDim2.new(0, 0, 0.5, 0)
                knob.BackgroundColor3 = Color3.new(1, 1, 1)
                knob.BorderSizePixel = 0
                knob.ZIndex = 8
                knob.Parent = track
                local kc = Instance.new("UICorner")
                kc.CornerRadius = UDim.new(1, 0)
                kc.Parent = knob
                local ks = Instance.new("UIStroke")
                ks.Color = NexzanHub.CurrentTheme.Accent
                ks.Thickness = 1
                ks.Parent = knob
                Register(ks, { Color = "Accent" })

                local hitbox = Instance.new("TextButton")
                hitbox.BackgroundTransparency = 1
                hitbox.Size = UDim2.new(1, 0, 0, 18)
                hitbox.AnchorPoint = Vector2.new(0, 0.5)
                hitbox.Position = UDim2.new(0, 0, 0.5, 0)
                hitbox.Text = ""
                hitbox.ZIndex = 9
                hitbox.Parent = track

                local api = {}
                local dragging = false

                local function UpdateVisual(animate)
                    local alpha = (max - min) > 0 and ((value - min) / (max - min)) or 0
                    local sz = UDim2.new(alpha, 0, 1, 0)
                    local pos = UDim2.new(alpha, 0, 0.5, 0)
                    if animate then
                        Tween(fill, TweenInfo.new(0.1), { Size = sz })
                        Tween(knob, TweenInfo.new(0.1), { Position = pos })
                    else
                        fill.Size = sz
                        knob.Position = pos
                    end
                    valueLbl.Text = tostring(Round(value, decimals)) .. suffix
                    -- fit value box width
                    local ts = TextService:GetTextSize(valueLbl.Text, valueLbl.TextSize, valueLbl.Font, Vector2.new(1e5, 1e5))
                    valueBox.Size = UDim2.new(0, ts.X + 10, 0, 14)
                end

                local function SetFromInput(input, fire)
                    local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    value = Round(min + (max - min) * pos, decimals)
                    UpdateVisual(false)
                    SetFlag(flag, value)
                    if fire ~= false then task.spawn(callback, value) end
                end

                hitbox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Tween(knob, TweenInfo.new(0.1), { Size = UDim2.new(0, 11, 0, 11) })
                        SetFromInput(input)
                    end
                end)
                hitbox.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        Tween(knob, TweenInfo.new(0.1), { Size = UDim2.new(0, 9, 0, 9) })
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        SetFromInput(input)
                    end
                end)

                function api:SetValue(v, fire)
                    value = math.clamp(Round(v, decimals), min, max)
                    UpdateVisual(true)
                    SetFlag(flag, value)
                    if fire ~= false then task.spawn(callback, value) end
                end
                function api:GetValue() return value end

                UpdateVisual(false)
                SetFlag(flag, value)
                return api
            end
            -- =========================
            -- Dropdown (Single & Multi)
            -- =========================
            function Section:AddDropdown(dCfg)
                dCfg = dCfg or {}
                local name = dCfg.Name or "Dropdown"
                local values = dCfg.Values or dCfg.Options or {}
                local multi = dCfg.Multi or false
                local flag = dCfg.Flag
                local callback = dCfg.Callback or function() end

                local selected
                if multi then
                    selected = {}
                    if type(dCfg.Default) == "table" then
                        for _, v in ipairs(dCfg.Default) do selected[v] = true end
                    end
                else
                    selected = dCfg.Default or (values[1])
                end

                local ITEM_H = 22
                local SEARCH_H = 24
                local MAX_LIST = 110

                -- holder utuh (bisa expand)
                local holder = Instance.new("Frame")
                holder.Size = UDim2.new(1, 0, 0, 28)
                holder.BackgroundTransparency = 1
                holder.BorderSizePixel = 0
                holder.ClipsDescendants = true
                holder.ZIndex = 12
                holder.Parent = elemHolder

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 28)
                row.BackgroundColor3 = NexzanHub.CurrentTheme.Dark
                row.BackgroundTransparency = 0.35
                row.BorderSizePixel = 0
                row.ZIndex = 12
                row.Parent = holder
                Register(row, { BackgroundColor3 = "Dark" })
                local rowC = Instance.new("UICorner")
                rowC.CornerRadius = UDim.new(0, 6)
                rowC.Parent = row

                local lbl = NewNameLabel(row, name)
                lbl.ZIndex = 13
                lbl.Size = UDim2.new(1, -76, 1, 0)

                local currentLbl = Instance.new("TextLabel")
                currentLbl.BackgroundTransparency = 1
                currentLbl.AnchorPoint = Vector2.new(1, 0.5)
                currentLbl.Position = UDim2.new(1, -26, 0.5, 0)
                currentLbl.Size = UDim2.new(0, 60, 0, 14)
                currentLbl.Font = Enum.Font.Gotham
                currentLbl.TextSize = 10
                currentLbl.TextXAlignment = Enum.TextXAlignment.Right
                currentLbl.TextTruncate = Enum.TextTruncate.AtEnd
                currentLbl.TextColor3 = NexzanHub.CurrentTheme.SubText
                currentLbl.ZIndex = 13
                currentLbl.Parent = row
                Register(currentLbl, { TextColor3 = "SubText" })

                local chevron = Instance.new("ImageLabel")
                chevron.BackgroundTransparency = 1
                chevron.AnchorPoint = Vector2.new(1, 0.5)
                chevron.Position = UDim2.new(1, -8, 0.5, 0)
                chevron.Size = UDim2.new(0, 12, 0, 12)
                chevron.Image = NexzanHub.Icons.ChevronDown
                chevron.ImageColor3 = NexzanHub.CurrentTheme.SubText
                chevron.Rotation = 0
                chevron.ZIndex = 13
                chevron.Parent = row
                Register(chevron, { ImageColor3 = "SubText" })

                local rowBtn = Instance.new("TextButton")
                rowBtn.Size = UDim2.new(1, 0, 1, 0)
                rowBtn.BackgroundTransparency = 1
                rowBtn.Text = ""
                rowBtn.ZIndex = 14
                rowBtn.Parent = row

                -- list container
                local listFrame = Instance.new("Frame")
                listFrame.Position = UDim2.new(0, 0, 0, 31)
                listFrame.Size = UDim2.new(1, 0, 0, 0)
                listFrame.BackgroundColor3 = NexzanHub.CurrentTheme.Dark
                listFrame.BorderSizePixel = 0
                listFrame.ClipsDescendants = true
                listFrame.ZIndex = 13
                listFrame.Parent = holder
                Register(listFrame, { BackgroundColor3 = "Dark" })
                local lfCorner = Instance.new("UICorner")
                lfCorner.CornerRadius = UDim.new(0, 6)
                lfCorner.Parent = listFrame
                local lfStroke = Instance.new("UIStroke")
                lfStroke.Color = NexzanHub.CurrentTheme.Stroke
                lfStroke.Transparency = 0.5
                lfStroke.Thickness = 1
                lfStroke.Parent = listFrame
                Register(lfStroke, { Color = "Stroke" })

                local searchBox
                if #values > 5 then
                    local sbHolder = Instance.new("Frame")
                    sbHolder.Size = UDim2.new(1, -8, 0, 20)
                    sbHolder.Position = UDim2.new(0, 4, 0, 4)
                    sbHolder.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                    sbHolder.BorderSizePixel = 0
                    sbHolder.ZIndex = 14
                    sbHolder.Parent = listFrame
                    Register(sbHolder, { BackgroundColor3 = "Element" })
                    local sbC = Instance.new("UICorner")
                    sbC.CornerRadius = UDim.new(0, 5)
                    sbC.Parent = sbHolder

                    local sbIcon = Instance.new("ImageLabel")
                    sbIcon.BackgroundTransparency = 1
                    sbIcon.Position = UDim2.new(0, 5, 0.5, -5)
                    sbIcon.Size = UDim2.new(0, 10, 0, 10)
                    sbIcon.Image = NexzanHub.Icons.Search
                    sbIcon.ImageColor3 = NexzanHub.CurrentTheme.SubText
                    sbIcon.ZIndex = 15
                    sbIcon.Parent = sbHolder
                    Register(sbIcon, { ImageColor3 = "SubText" })

                    searchBox = Instance.new("TextBox")
                    searchBox.BackgroundTransparency = 1
                    searchBox.Position = UDim2.new(0, 19, 0, 0)
                    searchBox.Size = UDim2.new(1, -22, 1, 0)
                    searchBox.Font = Enum.Font.Gotham
                    searchBox.TextSize = 10
                    searchBox.PlaceholderText = "Search..."
                    searchBox.PlaceholderColor3 = NexzanHub.CurrentTheme.SubText
                    searchBox.Text = ""
                    searchBox.TextColor3 = NexzanHub.CurrentTheme.Text
                    searchBox.TextXAlignment = Enum.TextXAlignment.Left
                    searchBox.ClearTextOnFocus = false
                    searchBox.ZIndex = 15
                    searchBox.Parent = sbHolder
                    Register(searchBox, { TextColor3 = "Text" })
                end

                local optScroll = Instance.new("ScrollingFrame")
                optScroll.Position = UDim2.new(0, 3, 0, searchBox and SEARCH_H or 3)
                optScroll.Size = UDim2.new(1, -6, 1, searchBox and -(SEARCH_H + 3) or -6)
                optScroll.BackgroundTransparency = 1
                optScroll.BorderSizePixel = 0
                optScroll.ScrollBarThickness = 2
                optScroll.ScrollBarImageColor3 = NexzanHub.CurrentTheme.Stroke
                optScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                optScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                optScroll.ZIndex = 14
                optScroll.Parent = listFrame
                Register(optScroll, { ScrollBarImageColor3 = "Stroke" })

                local optLayout = Instance.new("UIListLayout")
                optLayout.SortOrder = Enum.SortOrder.LayoutOrder
                optLayout.Padding = UDim.new(0, 2)
                optLayout.Parent = optScroll

                local api = {}
                local open = false
                local optionButtons = {}

                local function DisplayText()
                    if multi then
                        local count = 0
                        local first
                        for _, v in ipairs(values) do
                            if selected[v] then count += 1 first = first or v end
                        end
                        if count == 0 then return "..." end
                        if count == 1 then return tostring(first) end
                        return tostring(count) .. " selected"
                    end
                    return tostring(selected or "...")
                end

                local function FireCb()
                    if multi then
                        local out = {}
                        for _, v in ipairs(values) do
                            if selected[v] then table.insert(out, v) end
                        end
                        task.spawn(callback, out)
                        SetFlag(flag, out)
                    else
                        task.spawn(callback, selected)
                        SetFlag(flag, selected)
                    end
                end

                local function RefreshOptionVisual(optBtn, optName, mark)
                    local isSel = multi and selected[optName] or (not multi and selected == optName)
                    local txt = optBtn:FindFirstChild("OptLabel")
                    if txt then
                        Tween(txt, TweenInfo.new(0.12), {
                            TextColor3 = isSel and NexzanHub.CurrentTheme.Accent or NexzanHub.CurrentTheme.SubText
                        })
                    end
                    if mark then
                        Tween(mark, TweenInfo.new(0.12), {
                            BackgroundTransparency = isSel and 0 or 0.75,
                            BackgroundColor3 = NexzanHub.CurrentTheme.Accent,
                        })
                    end
                end

                local function SetOpen(v)
                    open = v
                    local useSearch = searchBox ~= nil
                    local visibleCount = 0
                    for _, ob in ipairs(optionButtons) do
                        if ob.Visible then visibleCount += 1 end
                    end
                    local listH = math.clamp(visibleCount * (ITEM_H + 2) + 4, ITEM_H, MAX_LIST)
                    local extra = useSearch and SEARCH_H or 4
                    local target = open and (listH + extra + 5) or 0
                    Tween(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0, open and (31 + target) or 28) })
                    Tween(listFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Size = UDim2.new(1, 0, 0, target) })
                    Tween(chevron, TweenInfo.new(0.2), { Rotation = open and 180 or 0 })
                    holder.ZIndex = open and 30 or 12
                    row.ZIndex = open and 31 or 12
                end

                local function BuildOptions(filter)
                    table.clear(optionButtons)
                    for _, child in ipairs(optScroll:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for _, optName in ipairs(values) do
                        if not filter or filter == "" or string.find(string.lower(tostring(optName)), string.lower(filter), 1, true) then
                            local optBtn = Instance.new("TextButton")
                            optBtn.Size = UDim2.new(1, 0, 0, ITEM_H)
                            optBtn.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                            optBtn.BackgroundTransparency = 1
                            optBtn.BorderSizePixel = 0
                            optBtn.Text = ""
                            optBtn.AutoButtonColor = false
                            optBtn.ZIndex = 15
                            optBtn.Parent = optScroll
                            Register(optBtn, { BackgroundColor3 = "Element" })
                            local obC = Instance.new("UICorner")
                            obC.CornerRadius = UDim.new(0, 5)
                            obC.Parent = optBtn

                            local mark = Instance.new("Frame")
                            mark.Name = "Mark"
                            mark.Size = UDim2.new(0, 12, 0, 12)
                            mark.Position = UDim2.new(0, 6, 0.5, -6)
                            mark.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
                            mark.BackgroundTransparency = 0.75
                            mark.BorderSizePixel = 0
                            mark.ZIndex = 16
                            mark.Parent = optBtn
                            local mkC = Instance.new("UICorner")
                            mkC.CornerRadius = UDim.new(0, 3)
                            mkC.Parent = mark

                            local optLbl = Instance.new("TextLabel")
                            optLbl.Name = "OptLabel"
                            optLbl.BackgroundTransparency = 1
                            optLbl.Position = UDim2.new(0, 24, 0, 0)
                            optLbl.Size = UDim2.new(1, -28, 1, 0)
                            optLbl.Font = Enum.Font.Gotham
                            optLbl.TextSize = 10
                            optLbl.TextXAlignment = Enum.TextXAlignment.Left
                            optLbl.TextTruncate = Enum.TextTruncate.AtEnd
                            optLbl.Text = tostring(optName)
                            optLbl.TextColor3 = NexzanHub.CurrentTheme.SubText
                            optLbl.ZIndex = 16
                            optLbl.Parent = optBtn

                            optBtn.MouseButton1Click:Connect(function()
                                if multi then
                                    selected[optName] = not selected[optName] or nil
                                else
                                    selected = optName
                                end
                                currentLbl.Text = DisplayText()
                                for _, ob in ipairs(optionButtons) do
                                    RefreshOptionVisual(ob, ob:GetAttribute("OptName"), ob:FindFirstChild("Mark"))
                                end
                                FireCb()
                                if not multi then SetOpen(false) end
                            end)
                            optBtn.MouseEnter:Connect(function()
                                Tween(optBtn, TweenInfo.new(0.1), { BackgroundTransparency = 0.5 })
                            end)
                            optBtn.MouseLeave:Connect(function()
                                Tween(optBtn, TweenInfo.new(0.1), { BackgroundTransparency = 1 })
                            end)

                            optBtn:SetAttribute("OptName", optName)
                            RefreshOptionVisual(optBtn, optName, mark)
                            table.insert(optionButtons, optBtn)
                        end
                    end
                    if open then SetOpen(true) end
                end

                BuildOptions()
                currentLbl.Text = DisplayText()

                if searchBox then
                    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        BuildOptions(searchBox.Text)
                    end)
                end

                rowBtn.MouseButton1Click:Connect(function()
                    SetOpen(not open)
                end)

                function api:SetValue(v, fire)
                    if multi and type(v) == "table" then
                        selected = {}
                        for _, name in ipairs(v) do selected[name] = true end
                    elseif not multi then
                        selected = v
                    end
                    currentLbl.Text = DisplayText()
                    for _, ob in ipairs(optionButtons) do
                        RefreshOptionVisual(ob, ob:GetAttribute("OptName"), ob:FindFirstChild("Mark"))
                    end
                    if fire ~= false then FireCb() end
                end

                function api:GetValue()
                    if multi then
                        local out = {}
                        for _, v in ipairs(values) do
                            if selected[v] then table.insert(out, v) end
                        end
                        return out
                    end
                    return selected
                end

                function api:Refresh(newValues, keep)
                    values = newValues or values
                    if not keep then
                        if multi then selected = {} else selected = values[1] end
                    end
                    BuildOptions(searchBox and searchBox.Text)
                    currentLbl.Text = DisplayText()
                end

                SetFlag(flag, api:GetValue())
                Section._UpdateSize()
                return api
            end

            -- =========================
            -- Input / TextBox
            -- =========================
            function Section:AddInput(iCfg)
                iCfg = iCfg or {}
                local name = iCfg.Name or "Input"
                local default = iCfg.Default or ""
                local placeholder = iCfg.Placeholder or "..."
                local clearOnFocus = iCfg.ClearTextOnFocus ~= nil and iCfg.ClearTextOnFocus or true
                local numeric = iCfg.Numeric or false
                local flag = iCfg.Flag
                local callback = iCfg.Callback or function() end

                local row = NewRow(28)
                local lbl = NewNameLabel(row, name)
                lbl.Size = UDim2.new(0.5, -8, 1, 0)

                local boxHolder = Instance.new("Frame")
                boxHolder.AnchorPoint = Vector2.new(1, 0.5)
                boxHolder.Position = UDim2.new(1, -8, 0.5, 0)
                boxHolder.Size = UDim2.new(0.5, 0, 0, 20)
                boxHolder.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                boxHolder.BorderSizePixel = 0
                boxHolder.ZIndex = 6
                boxHolder.Parent = row
                Register(boxHolder, { BackgroundColor3 = "Element" })
                local bhC = Instance.new("UICorner")
                bhC.CornerRadius = UDim.new(0, 5)
                bhC.Parent = boxHolder
                local bhStroke = Instance.new("UIStroke")
                bhStroke.Color = NexzanHub.CurrentTheme.Stroke
                bhStroke.Transparency = 0.7
                bhStroke.Thickness = 1
                bhStroke.Parent = boxHolder
                Register(bhStroke, { Color = "Stroke" })

                local box = Instance.new("TextBox")
                box.BackgroundTransparency = 1
                box.Position = UDim2.new(0, 7, 0, 0)
                box.Size = UDim2.new(1, -14, 1, 0)
                box.Font = Enum.Font.Gotham
                box.TextSize = 10
                box.Text = tostring(default)
                box.PlaceholderText = placeholder
                box.PlaceholderColor3 = NexzanHub.CurrentTheme.SubText
                box.TextColor3 = NexzanHub.CurrentTheme.Text
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.ClearTextOnFocus = clearOnFocus
                box.ClipsDescendants = true
                box.ZIndex = 7
                box.Parent = boxHolder
                Register(box, { TextColor3 = "Text" })

                if numeric then
                    box:GetPropertyChangedSignal("Text"):Connect(function()
                        local cleaned = box.Text:gsub("[^%d%.%-]", "")
                        if cleaned ~= box.Text then box.Text = cleaned end
                    end)
                end

                box.Focused:Connect(function()
                    Tween(bhStroke, TweenInfo.new(0.15), { Color = NexzanHub.CurrentTheme.Accent, Transparency = 0.2 })
                end)
                box.FocusLost:Connect(function(enterPressed)
                    Tween(bhStroke, TweenInfo.new(0.15), { Color = NexzanHub.CurrentTheme.Stroke, Transparency = 0.7 })
                    SetFlag(flag, box.Text)
                    task.spawn(callback, box.Text, enterPressed)
                end)

                local api = {}
                function api:SetValue(v) box.Text = tostring(v) SetFlag(flag, box.Text) end
                function api:GetValue() return box.Text end
                SetFlag(flag, box.Text)
                return api
            end
            -- =========================
            -- ColorPicker
            -- =========================
            function Section:AddColorPicker(cCfg)
                cCfg = cCfg or {}
                local name = cCfg.Name or "ColorPicker"
                local color = cCfg.Default or Color3.fromRGB(255, 255, 255)
                local transparency = cCfg.Transparency or 0
                local flag = cCfg.Flag
                local callback = cCfg.Callback or function() end

                local h, s, v = color:ToHSV()

                local row = NewRow(28)
                local lbl = NewNameLabel(row, name)

                local preview = Instance.new("Frame")
                preview.AnchorPoint = Vector2.new(1, 0.5)
                preview.Position = UDim2.new(1, -9, 0.5, 0)
                preview.Size = UDim2.new(0, 42, 0, 14)
                preview.BackgroundColor3 = color
                preview.BorderSizePixel = 0
                preview.ZIndex = 6
                preview.Parent = row
                local pvC = Instance.new("UICorner")
                pvC.CornerRadius = UDim.new(0, 5)
                pvC.Parent = preview
                local pvStroke = Instance.new("UIStroke")
                pvStroke.Color = NexzanHub.CurrentTheme.Stroke
                pvStroke.Transparency = 0.5
                pvStroke.Thickness = 1
                pvStroke.Parent = preview
                Register(pvStroke, { Color = "Stroke" })

                local rowBtn = Instance.new("TextButton")
                rowBtn.Size = UDim2.new(1, 0, 1, 0)
                rowBtn.BackgroundTransparency = 1
                rowBtn.Text = ""
                rowBtn.ZIndex = 8
                rowBtn.Parent = row

                -- ===== Popup panel =====
                local popup = Instance.new("Frame")
                popup.Size = UDim2.new(0, 176, 0, 196)
                popup.BackgroundColor3 = NexzanHub.CurrentTheme.Dark
                popup.BorderSizePixel = 0
                popup.Visible = false
                popup.ZIndex = 200
                popup.Active = true
                popup.Parent = gui
                Register(popup, { BackgroundColor3 = "Dark" })
                local ppC = Instance.new("UICorner")
                ppC.CornerRadius = UDim.new(0, 8)
                ppC.Parent = popup
                local ppStroke = Instance.new("UIStroke")
                ppStroke.Color = NexzanHub.CurrentTheme.Stroke
                ppStroke.Transparency = 0.3
                ppStroke.Thickness = 1
                ppStroke.Parent = popup
                Register(ppStroke, { Color = "Stroke" })

                -- SV box
                local svBox = Instance.new("Frame")
                svBox.Size = UDim2.new(0, 130, 0, 130)
                svBox.Position = UDim2.new(0, 8, 0, 8)
                svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                svBox.BorderSizePixel = 0
                svBox.ZIndex = 201
                svBox.Parent = popup
                local svC = Instance.new("UICorner")
                svC.CornerRadius = UDim.new(0, 6)
                svC.Parent = svBox

                local whiteGrad = Instance.new("Frame")
                whiteGrad.Size = UDim2.new(1, 0, 1, 0)
                whiteGrad.BackgroundColor3 = Color3.new(1, 1, 1)
                whiteGrad.BorderSizePixel = 0
                whiteGrad.ZIndex = 202
                whiteGrad.Parent = svBox
                local wgC = Instance.new("UICorner")
                wgC.CornerRadius = UDim.new(0, 6)
                wgC.Parent = whiteGrad
                local wgGrad = Instance.new("UIGradient")
                wgGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })
                wgGrad.Parent = whiteGrad

                local blackGrad = Instance.new("Frame")
                blackGrad.Size = UDim2.new(1, 0, 1, 0)
                blackGrad.BackgroundColor3 = Color3.new(0, 0, 0)
                blackGrad.BorderSizePixel = 0
                blackGrad.ZIndex = 203
                blackGrad.Parent = svBox
                local bgC = Instance.new("UICorner")
                bgC.CornerRadius = UDim.new(0, 6)
                bgC.Parent = blackGrad
                local bgGrad = Instance.new("UIGradient")
                bgGrad.Rotation = 90
                bgGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                })
                bgGrad.Parent = blackGrad

                local svDot = Instance.new("Frame")
                svDot.Size = UDim2.new(0, 10, 0, 10)
                svDot.AnchorPoint = Vector2.new(0.5, 0.5)
                svDot.BackgroundColor3 = Color3.new(1, 1, 1)
                svDot.BorderSizePixel = 0
                svDot.ZIndex = 205
                svDot.Parent = svBox
                local svdC = Instance.new("UICorner")
                svdC.CornerRadius = UDim.new(1, 0)
                svdC.Parent = svDot
                local svdS = Instance.new("UIStroke")
                svdS.Color = Color3.new(0, 0, 0)
                svdS.Transparency = 0.5
                svdS.Thickness = 1
                svdS.Parent = svDot

                -- Hue slider
                local hueBar = Instance.new("Frame")
                hueBar.Size = UDim2.new(0, 12, 0, 130)
                hueBar.Position = UDim2.new(1, -20, 0, 8)
                hueBar.BorderSizePixel = 0
                hueBar.ZIndex = 201
                hueBar.Parent = popup
                local hbC = Instance.new("UICorner")
                hbC.CornerRadius = UDim.new(1, 0)
                hbC.Parent = hueBar
                local hbGrad = Instance.new("UIGradient")
                hbGrad.Rotation = 90
                hbGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                })
                hbGrad.Parent = hueBar

                local hueMark = Instance.new("Frame")
                hueMark.Size = UDim2.new(1, 4, 0, 2)
                hueMark.AnchorPoint = Vector2.new(0.5, 0)
                hueMark.Position = UDim2.new(0.5, 0, h, 0)
                hueMark.BackgroundColor3 = Color3.new(1, 1, 1)
                hueMark.BorderSizePixel = 0
                hueMark.ZIndex = 202
                hueMark.Parent = hueBar
                local hmS = Instance.new("UIStroke")
                hmS.Color = Color3.new(0, 0, 0)
                hmS.Thickness = 1
                hmS.Parent = hueMark

                -- Alpha slider
                local alphaBar = Instance.new("Frame")
                alphaBar.Size = UDim2.new(1, -16, 0, 10)
                alphaBar.Position = UDim2.new(0, 8, 0, 146)
                alphaBar.BackgroundColor3 = Color3.fromHSV(h, s, v)
                alphaBar.BorderSizePixel = 0
                alphaBar.ZIndex = 201
                alphaBar.Parent = popup
                local abC = Instance.new("UICorner")
                abC.CornerRadius = UDim.new(1, 0)
                abC.Parent = alphaBar
                local abStroke = Instance.new("UIStroke")
                abStroke.Color = NexzanHub.CurrentTheme.Stroke
                abStroke.Transparency = 0.6
                abStroke.Thickness = 1
                abStroke.Parent = alphaBar
                Register(abStroke, { Color = "Stroke" })

                local alphaMark = Instance.new("Frame")
                alphaMark.Size = UDim2.new(0, 2, 1, 4)
                alphaMark.AnchorPoint = Vector2.new(0, 0.5)
                alphaMark.Position = UDim2.new(1 - transparency, 0, 0.5, 0)
                alphaMark.BackgroundColor3 = Color3.new(1, 1, 1)
                alphaMark.BorderSizePixel = 0
                alphaMark.ZIndex = 202
                alphaMark.Parent = alphaBar
                local amS = Instance.new("UIStroke")
                amS.Color = Color3.new(0, 0, 0)
                amS.Thickness = 1
                amS.Parent = alphaMark

                -- Hex label + preview
                local hexBox = Instance.new("Frame")
                hexBox.Size = UDim2.new(0, 100, 0, 20)
                hexBox.Position = UDim2.new(0, 8, 1, -30)
                hexBox.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                hexBox.BorderSizePixel = 0
                hexBox.ZIndex = 201
                hexBox.Parent = popup
                Register(hexBox, { BackgroundColor3 = "Element" })
                local hxC = Instance.new("UICorner")
                hxC.CornerRadius = UDim.new(0, 5)
                hxC.Parent = hexBox

                local hexLbl = Instance.new("TextLabel")
                hexLbl.BackgroundTransparency = 1
                hexLbl.Size = UDim2.new(1, -8, 1, 0)
                hexLbl.Position = UDim2.new(0, 4, 0, 0)
                hexLbl.Font = Enum.Font.GothamMedium
                hexLbl.TextSize = 10
                hexLbl.TextXAlignment = Enum.TextXAlignment.Left
                hexLbl.TextColor3 = NexzanHub.CurrentTheme.Text
                hexLbl.ZIndex = 202
                hexLbl.Parent = hexBox
                Register(hexLbl, { TextColor3 = "Text" })

                local bigPreview = Instance.new("Frame")
                bigPreview.Size = UDim2.new(0, 48, 0, 20)
                bigPreview.Position = UDim2.new(1, -56, 1, -30)
                bigPreview.BackgroundColor3 = color
                bigPreview.BackgroundTransparency = transparency
                bigPreview.BorderSizePixel = 0
                bigPreview.ZIndex = 201
                bigPreview.Parent = popup
                local bpC = Instance.new("UICorner")
                bpC.CornerRadius = UDim.new(0, 5)
                bpC.Parent = bigPreview
                local bpS = Instance.new("UIStroke")
                bpS.Color = NexzanHub.CurrentTheme.Stroke
                bpS.Thickness = 1
                bpS.Parent = bigPreview
                Register(bpS, { Color = "Stroke" })

                local api = {}
                local popupOpen = false

                local function Apply(fire)
                    color = Color3.fromHSV(h, s, v)
                    svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    alphaBar.BackgroundColor3 = color
                    svDot.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueMark.Position = UDim2.new(0.5, 0, h, 0)
                    alphaMark.Position = UDim2.new(1 - transparency, 0, 0.5, 0)
                    preview.BackgroundColor3 = color
                    bigPreview.BackgroundColor3 = color
                    bigPreview.BackgroundTransparency = transparency
                    hexLbl.Text = "#" .. color:ToHex():upper() .. string.format("  A:%d%%", math.floor((1 - transparency) * 100 + 0.5))
                    SetFlag(flag, { Color = color, Transparency = transparency })
                    if fire ~= false then task.spawn(callback, color, transparency) end
                end

                -- drag helpers
                local function TrackDrag(frame, onMove)
                    local dragging = false
                    frame.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            onMove(input)
                        end
                    end)
                    frame.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
                            onMove(input)
                        end
                    end)
                end

                TrackDrag(svBox, function(input)
                    s = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                    Apply()
                end)

                TrackDrag(hueBar, function(input)
                    h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.995)
                    Apply()
                end)

                TrackDrag(alphaBar, function(input)
                    transparency = 1 - math.clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                    Apply()
                end)

                local function ClosePopup()
                    popupOpen = false
                    Tween(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        Size = UDim2.new(0, 176, 0, 0)
                    })
                    task.delay(0.2, function()
                        if not popupOpen then popup.Visible = false end
                    end)
                end

                local function OpenPopup()
                    popup.Visible = true
                    popupOpen = true
                    -- posisi dekat row, clamp ke layar
                    local camVp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
                    local x = math.clamp(row.AbsolutePosition.X + row.AbsoluteSize.X + 8, 8, camVp.X - 184)
                    local y = math.clamp(row.AbsolutePosition.Y - 40, 8, camVp.Y - 204)
                    popup.Position = UDim2.new(0, x, 0, y)
                    popup.Size = UDim2.new(0, 176, 0, 0)
                    Tween(popup, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(0, 176, 0, 196)
                    })
                end

                rowBtn.MouseButton1Click:Connect(function()
                    if popupOpen then ClosePopup() else OpenPopup() end
                end)

                table.insert(NexzanHub.Connections, UserInputService.InputBegan:Connect(function(input)
                    if not popupOpen then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        local p = input.Position
                        local ap, as = popup.AbsolutePosition, popup.AbsoluteSize
                        local inPopup = p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y
                        local rp, rs = row.AbsolutePosition, row.AbsoluteSize
                        local inRow = p.X >= rp.X and p.X <= rp.X + rs.X and p.Y >= rp.Y and p.Y <= rp.Y + rs.Y
                        if not inPopup and not inRow then
                            ClosePopup()
                        end
                    end
                end))

                function api:SetColor(newColor, newTrans)
                    h, s, v = newColor:ToHSV()
                    transparency = newTrans or transparency
                    Apply(false)
                end
                function api:GetColor() return color, transparency end

                Apply(false)
                return api
            end

            -- =========================
            -- Keybind
            -- =========================
            function Section:AddKeybind(kCfg)
                kCfg = kCfg or {}
                local name = kCfg.Name or "Keybind"
                local default = kCfg.Default
                local flag = kCfg.Flag
                local blacklist = kCfg.Blacklist or { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D }
                local callback = kCfg.Callback or function() end
                local onChanged = kCfg.OnChanged or function() end

                if type(default) == "string" then
                    local okK, resK = pcall(function()
                        return Enum.KeyCode[default] or Enum.UserInputType[default]
                    end)
                    default = (okK and resK) or nil
                end

                local current = default

                local function KeyName(k)
                    if not k then return "None" end
                    if k.EnumType == Enum.UserInputType then
                        if k == Enum.UserInputType.MouseButton1 then return "MB1" end
                        if k == Enum.UserInputType.MouseButton2 then return "MB2" end
                        if k == Enum.UserInputType.MouseButton3 then return "MB3" end
                        return k.Name
                    end
                    return k.Name
                end

                local row = NewRow(28)
                local lbl = NewNameLabel(row, name)

                local chip = Instance.new("Frame")
                chip.AnchorPoint = Vector2.new(1, 0.5)
                chip.Position = UDim2.new(1, -8, 0.5, 0)
                chip.Size = UDim2.new(0, 40, 0, 16)
                chip.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                chip.BorderSizePixel = 0
                chip.ZIndex = 6
                chip.Parent = row
                Register(chip, { BackgroundColor3 = "Element" })
                local chC = Instance.new("UICorner")
                chC.CornerRadius = UDim.new(0, 5)
                chC.Parent = chip
                local chStroke = Instance.new("UIStroke")
                chStroke.Color = NexzanHub.CurrentTheme.Stroke
                chStroke.Transparency = 0.6
                chStroke.Thickness = 1
                chStroke.Parent = chip
                Register(chStroke, { Color = "Stroke" })

                local chipLbl = Instance.new("TextLabel")
                chipLbl.BackgroundTransparency = 1
                chipLbl.Size = UDim2.new(1, 0, 1, 0)
                chipLbl.Font = Enum.Font.GothamMedium
                chipLbl.TextSize = 10
                chipLbl.TextColor3 = NexzanHub.CurrentTheme.SubText
                chipLbl.Text = KeyName(current)
                chipLbl.ZIndex = 7
                chipLbl.Parent = chip
                Register(chipLbl, { TextColor3 = "SubText" })

                local function FitChip()
                    local ts = TextService:GetTextSize(chipLbl.Text, chipLbl.TextSize, chipLbl.Font, Vector2.new(1e5, 1e5))
                    chip.Size = UDim2.new(0, math.max(30, ts.X + 12), 0, 16)
                end
                FitChip()

                local chipBtn = Instance.new("TextButton")
                chipBtn.Size = UDim2.new(1, 0, 1, 0)
                chipBtn.BackgroundTransparency = 1
                chipBtn.Text = ""
                chipBtn.ZIndex = 8
                chipBtn.Parent = chip

                local api = {}
                local listening = false

                local function SetKey(k, fire)
                    current = k
                    chipLbl.Text = KeyName(k)
                    FitChip()
                    SetFlag(flag, KeyName(k))
                    if fire ~= false then task.spawn(onChanged, KeyName(k)) end
                end

                chipBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    chipLbl.Text = "..."
                    FitChip()
                    Tween(chStroke, TweenInfo.new(0.15), { Color = NexzanHub.CurrentTheme.Accent, Transparency = 0.1 })
                end)

                table.insert(NexzanHub.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
                    local candidate
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        candidate = input.KeyCode
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.MouseButton2
                        or input.UserInputType == Enum.UserInputType.MouseButton3 then
                        candidate = input.UserInputType
                    end
                    if not candidate then return end

                    if listening then
                        if candidate == Enum.KeyCode.Escape then
                            SetKey(nil, true)
                        elseif candidate == Enum.KeyCode.Backspace or candidate == Enum.KeyCode.Delete then
                            SetKey(nil, true)
                        else
                            local banned = false
                            for _, b in ipairs(blacklist) do
                                local bEnum = b
                                if type(b) == "string" then
                                    local okB, resB = pcall(function()
                                        return Enum.KeyCode[b] or Enum.UserInputType[b]
                                    end)
                                    bEnum = (okB and resB) or nil
                                end
                                if bEnum and bEnum == candidate then banned = true break end
                            end
                            if not banned then
                                SetKey(candidate, true)
                            else
                                chipLbl.Text = KeyName(current)
                                FitChip()
                                NexzanHub:Notify({ Title = "Nexzan Hub", Content = "Key '" .. KeyName(candidate) .. "' di-blacklist!", Duration = 2 })
                            end
                        end
                        listening = false
                        Tween(chStroke, TweenInfo.new(0.15), { Color = NexzanHub.CurrentTheme.Stroke, Transparency = 0.6 })
                        return
                    end

                    -- trigger
                    if gpe then return end
                    if current and candidate == current then
                        task.spawn(callback, KeyName(current))
                    end
                end))

                function api:Set(newKey)
                    if type(newKey) == "string" then
                        local okK, resK = pcall(function()
                            return Enum.KeyCode[newKey] or Enum.UserInputType[newKey]
                        end)
                        newKey = (okK and resK) or nil
                    end
                    SetKey(newKey, true)
                end
                function api:Get() return KeyName(current) end

                SetFlag(flag, KeyName(current))
                return api
            end

            -- =========================
            -- Paragraph
            -- =========================
            function Section:AddParagraph(pCfg)
                pCfg = pCfg or {}
                local title = pCfg.Title or "Paragraph"
                local content = pCfg.Content or ""

                local holder = Instance.new("Frame")
                holder.Size = UDim2.new(1, 0, 0, 40)
                holder.BackgroundColor3 = NexzanHub.CurrentTheme.Dark
                holder.BackgroundTransparency = 0.35
                holder.BorderSizePixel = 0
                holder.ZIndex = 5
                holder.Parent = elemHolder
                Register(holder, { BackgroundColor3 = "Dark" })
                local hC = Instance.new("UICorner")
                hC.CornerRadius = UDim.new(0, 6)
                hC.Parent = holder

                local ttl = Instance.new("TextLabel")
                ttl.BackgroundTransparency = 1
                ttl.Position = UDim2.new(0, 9, 0, 5)
                ttl.Size = UDim2.new(1, -18, 0, 14)
                ttl.Font = Enum.Font.GothamBold
                ttl.TextSize = 11
                ttl.TextXAlignment = Enum.TextXAlignment.Left
                ttl.Text = title
                ttl.TextColor3 = NexzanHub.CurrentTheme.Text
                ttl.ZIndex = 6
                ttl.Parent = holder
                Register(ttl, { TextColor3 = "Text" })

                local body = Instance.new("TextLabel")
                body.BackgroundTransparency = 1
                body.Position = UDim2.new(0, 9, 0, 19)
                body.Size = UDim2.new(1, -18, 0, 0)
                body.Font = Enum.Font.Gotham
                body.TextSize = 10
                body.TextColor3 = NexzanHub.CurrentTheme.SubText
                body.TextXAlignment = Enum.TextXAlignment.Left
                body.TextYAlignment = Enum.TextYAlignment.Top
                body.TextWrapped = true
                body.Text = content
                body.ZIndex = 6
                body.AutomaticSize = Enum.AutomaticSize.Y
                body.Parent = holder
                Register(body, { TextColor3 = "SubText" })

                local api = {}
                local function Resize()
                    task.defer(function()
                        local h = 19 + body.TextBounds.Y + 8
                        holder.Size = UDim2.new(1, 0, 0, h)
                    end)
                end
                Resize()

                function api:Set(newTitle, newContent)
                    if newTitle then ttl.Text = newTitle end
                    if newContent then body.Text = newContent end
                    Resize()
                end
                return api
            end

            -- =========================
            -- Code Box (Copy ke Clipboard)
            -- =========================
            function Section:AddCodeBox(cbCfg)
                cbCfg = cbCfg or {}
                local title = cbCfg.Title or "Code"
                local content = cbCfg.Content or cbCfg.Code or ""

                local holder = Instance.new("Frame")
                holder.Size = UDim2.new(1, 0, 0, 44)
                holder.BackgroundColor3 = NexzanHub.CurrentTheme.Dark
                holder.BackgroundTransparency = 0.35
                holder.BorderSizePixel = 0
                holder.ZIndex = 5
                holder.Parent = elemHolder
                Register(holder, { BackgroundColor3 = "Dark" })
                local hC = Instance.new("UICorner")
                hC.CornerRadius = UDim.new(0, 6)
                hC.Parent = holder

                -- header
                local ttl = Instance.new("TextLabel")
                ttl.BackgroundTransparency = 1
                ttl.Position = UDim2.new(0, 9, 0, 4)
                ttl.Size = UDim2.new(1, -60, 0, 13)
                ttl.Font = Enum.Font.GothamBold
                ttl.TextSize = 10
                ttl.TextXAlignment = Enum.TextXAlignment.Left
                ttl.TextColor3 = NexzanHub.CurrentTheme.Accent
                ttl.Text = title
                ttl.ZIndex = 6
                ttl.Parent = holder
                Register(ttl, { TextColor3 = "Accent" })

                local copyBtn = Instance.new("TextButton")
                copyBtn.AnchorPoint = Vector2.new(1, 0)
                copyBtn.Position = UDim2.new(1, -5, 0, 3)
                copyBtn.Size = UDim2.new(0, 46, 0, 14)
                copyBtn.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                copyBtn.BorderSizePixel = 0
                copyBtn.Text = ""
                copyBtn.AutoButtonColor = false
                copyBtn.ZIndex = 7
                copyBtn.Parent = holder
                Register(copyBtn, { BackgroundColor3 = "Element" })
                local cbC = Instance.new("UICorner")
                cbC.CornerRadius = UDim.new(0, 4)
                cbC.Parent = copyBtn

                local copyIcon = Instance.new("ImageLabel")
                copyIcon.BackgroundTransparency = 1
                copyIcon.Size = UDim2.new(0, 10, 0, 10)
                copyIcon.Position = UDim2.new(0, 4, 0.5, -5)
                copyIcon.Image = NexzanHub.Icons.Copy
                copyIcon.ImageColor3 = NexzanHub.CurrentTheme.SubText
                copyIcon.ZIndex = 8
                copyIcon.Parent = copyBtn
                Register(copyIcon, { ImageColor3 = "SubText" })

                local copyLbl = Instance.new("TextLabel")
                copyLbl.BackgroundTransparency = 1
                copyLbl.Position = UDim2.new(0, 16, 0, 0)
                copyLbl.Size = UDim2.new(1, -18, 1, 0)
                copyLbl.Font = Enum.Font.GothamMedium
                copyLbl.TextSize = 9
                copyLbl.TextXAlignment = Enum.TextXAlignment.Left
                copyLbl.TextColor3 = NexzanHub.CurrentTheme.SubText
                copyLbl.Text = "Copy"
                copyLbl.ZIndex = 8
                copyLbl.Parent = copyBtn
                Register(copyLbl, { TextColor3 = "SubText" })

                -- code area
                local codeHolder = Instance.new("Frame")
                codeHolder.Position = UDim2.new(0, 6, 0, 20)
                codeHolder.Size = UDim2.new(1, -12, 1, -26)
                codeHolder.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                codeHolder.BorderSizePixel = 0
                codeHolder.ClipsDescendants = true
                codeHolder.ZIndex = 6
                codeHolder.Parent = holder
                Register(codeHolder, { BackgroundColor3 = "Element" })
                local chC = Instance.new("UICorner")
                chC.CornerRadius = UDim.new(0, 5)
                chC.Parent = codeHolder

                local codeLbl = Instance.new("TextLabel")
                codeLbl.BackgroundTransparency = 1
                codeLbl.Position = UDim2.new(0, 7, 0, 5)
                codeLbl.Size = UDim2.new(1, -14, 1, -10)
                codeLbl.Font = Enum.Font.Code
                codeLbl.TextSize = 10
                codeLbl.TextColor3 = NexzanHub.CurrentTheme.SubText
                codeLbl.TextXAlignment = Enum.TextXAlignment.Left
                codeLbl.TextYAlignment = Enum.TextYAlignment.Top
                codeLbl.TextWrapped = true
                codeLbl.Text = content
                codeLbl.ZIndex = 7
                codeLbl.AutomaticSize = Enum.AutomaticSize.Y
                codeLbl.Parent = codeHolder
                Register(codeLbl, { TextColor3 = "SubText" })

                local api = {}
                local function Resize()
                    task.defer(function()
                        local th = codeLbl.TextBounds.Y + 10
                        codeHolder.Size = UDim2.new(1, -12, 0, math.max(18, th))
                        holder.Size = UDim2.new(1, 0, 0, 20 + math.max(18, th) + 6)
                        Section._UpdateSize()
                    end)
                end
                Resize()

                copyBtn.MouseButton1Click:Connect(function()
                    local ok = pcall(function()
                        if typeof(setclipboard) == "function" then
                            setclipboard(codeLbl.Text)
                        elseif typeof(toclipboard) == "function" then
                            toclipboard(codeLbl.Text)
                        end
                    end)
                    copyLbl.Text = ok and "Copied!" or "Failed"
                    copyLbl.TextColor3 = ok and NexzanHub.CurrentTheme.Accent or Color3.fromRGB(255, 80, 80)
                    task.delay(1, function()
                        copyLbl.Text = "Copy"
                        copyLbl.TextColor3 = NexzanHub.CurrentTheme.SubText
                    end)
                    if ok then
                        NexzanHub:Notify({ Title = "Nexzan Hub", Content = "Copied to Clipboard!", Duration = 2 })
                    end
                end)

                function api:Set(newTitle, newCode)
                    if newTitle then ttl.Text = newTitle end
                    if newCode then codeLbl.Text = newCode end
                    Resize()
                end
                return api
            end

            return Section
        end

        return Tab
    end

    -- =========================
    -- Key System
    -- =========================
    local keyCfg = cfg.KeySystem or cfg.Key
    if keyCfg and (keyCfg.Enabled ~= false) then
        local keys = keyCfg.Keys or keyCfg.Key or { "NEXZAN-HUB" }
        if type(keys) == "string" then keys = { keys } end
        local saveFile = keyCfg.SaveFile or "NexzanHub_Key.txt"
        local getKeyLink = keyCfg.GetKeyLink or keyCfg.Link
        local ksTitle = keyCfg.Title or "Key System"

        -- cek saved key
        local savedOk = false
        if keyCfg.SaveKey then
            pcall(function()
                if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(saveFile) then
                    local saved = readfile(saveFile)
                    for _, k in ipairs(keys) do
                        if saved == k then savedOk = true break end
                    end
                end
            end)
        end

        if savedOk then
            Window.KeySystemPassed = true
            task.defer(Window._OpenIntro)
        else
            -- dim overlay
            local dim = Instance.new("TextButton")
            dim.Size = UDim2.new(1, 0, 1, 0)
            dim.BackgroundColor3 = Color3.new(0, 0, 0)
            dim.BackgroundTransparency = 1
            dim.Text = ""
            dim.AutoButtonColor = false
            dim.ZIndex = 90
            dim.Parent = gui
            Tween(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.4 })

            -- modal 300 x 160 (intro dari kecil)
            local modal = Instance.new("Frame")
            modal.Size = UDim2.new(0, 280, 0, 0)
            modal.AnchorPoint = Vector2.new(0.5, 0.5)
            modal.Position = UDim2.new(0.5, 0, 0.5, 60)
            modal.BackgroundColor3 = NexzanHub.CurrentTheme.Main
            modal.BorderSizePixel = 0
            modal.ZIndex = 95
            modal.Active = true
            modal.ClipsDescendants = true
            modal.Parent = gui
            Register(modal, { BackgroundColor3 = "Main" })
            local mdC = Instance.new("UICorner")
            mdC.CornerRadius = UDim.new(0, 10)
            mdC.Parent = modal
            local mdStroke = Instance.new("UIStroke")
            mdStroke.Color = NexzanHub.CurrentTheme.Accent
            mdStroke.Transparency = 0.3
            mdStroke.Thickness = 1.5
            mdStroke.Parent = modal
            Register(mdStroke, { Color = "Accent" })

            -- animasi muncul modal
            Tween(modal, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 300, 0, 160),
                Position = UDim2.new(0.5, 0, 0.5, 0),
            })

            local ksTitleHolder = MakeTitleLabel(modal, 14, 96)
            ksTitleHolder.AnchorPoint = Vector2.new(0.5, 0)
            ksTitleHolder.Position = UDim2.new(0.5, 0, 0, 14)

            local ksSub = Instance.new("TextLabel")
            ksSub.BackgroundTransparency = 1
            ksSub.AnchorPoint = Vector2.new(0.5, 0)
            ksSub.Position = UDim2.new(0.5, 0, 0, 36)
            ksSub.Size = UDim2.new(1, -20, 0, 14)
            ksSub.Font = Enum.Font.Gotham
            ksSub.TextSize = 10
            ksSub.TextColor3 = NexzanHub.CurrentTheme.SubText
            ksSub.Text = ksTitle
            ksSub.ZIndex = 96
            ksSub.Parent = modal
            Register(ksSub, { TextColor3 = "SubText" })

            local keyInputHolder = Instance.new("Frame")
            keyInputHolder.AnchorPoint = Vector2.new(0.5, 0)
            keyInputHolder.Position = UDim2.new(0.5, 0, 0, 58)
            keyInputHolder.Size = UDim2.new(1, -24, 0, 26)
            keyInputHolder.BackgroundColor3 = NexzanHub.CurrentTheme.Element
            keyInputHolder.BorderSizePixel = 0
            keyInputHolder.ZIndex = 96
            keyInputHolder.Parent = modal
            Register(keyInputHolder, { BackgroundColor3 = "Element" })
            local kiC = Instance.new("UICorner")
            kiC.CornerRadius = UDim.new(0, 6)
            kiC.Parent = keyInputHolder
            local kiStroke = Instance.new("UIStroke")
            kiStroke.Color = NexzanHub.CurrentTheme.Stroke
            kiStroke.Transparency = 0.4
            kiStroke.Thickness = 1
            kiStroke.Parent = keyInputHolder
            Register(kiStroke, { Color = "Stroke" })

            local keyIcon = Instance.new("ImageLabel")
            keyIcon.BackgroundTransparency = 1
            keyIcon.Position = UDim2.new(0, 8, 0.5, -6)
            keyIcon.Size = UDim2.new(0, 12, 0, 12)
            keyIcon.Image = NexzanHub.Icons.Key
            keyIcon.ImageColor3 = NexzanHub.CurrentTheme.Accent
            keyIcon.ZIndex = 97
            keyIcon.Parent = keyInputHolder
            Register(keyIcon, { ImageColor3 = "Accent" })

            local keyBox = Instance.new("TextBox")
            keyBox.BackgroundTransparency = 1
            keyBox.Position = UDim2.new(0, 26, 0, 0)
            keyBox.Size = UDim2.new(1, -32, 1, 0)
            keyBox.Font = Enum.Font.Gotham
            keyBox.TextSize = 11
            keyBox.PlaceholderText = "Enter key..."
            keyBox.PlaceholderColor3 = NexzanHub.CurrentTheme.SubText
            keyBox.Text = ""
            keyBox.TextColor3 = NexzanHub.CurrentTheme.Text
            keyBox.ClearTextOnFocus = false
            keyBox.ZIndex = 97
            keyBox.Parent = keyInputHolder
            Register(keyBox, { TextColor3 = "Text" })

            -- tombol verify
            local verifyBtn = Instance.new("TextButton")
            verifyBtn.AnchorPoint = Vector2.new(0.5, 0)
            verifyBtn.Position = UDim2.new(getKeyLink and 0.31 or 0.5, 0, 0, 92)
            verifyBtn.Size = UDim2.new(0, getKeyLink and 120 or 276, 0, 28)
            verifyBtn.BackgroundColor3 = NexzanHub.CurrentTheme.Accent
            verifyBtn.BorderSizePixel = 0
            verifyBtn.Font = Enum.Font.GothamBold
            verifyBtn.TextSize = 12
            verifyBtn.TextColor3 = NexzanHub.CurrentTheme.Title
            verifyBtn.Text = "Verify Key"
            verifyBtn.AutoButtonColor = false
            verifyBtn.ZIndex = 96
            verifyBtn.Parent = modal
            Register(verifyBtn, { BackgroundColor3 = "Accent", TextColor3 = "Title" })
            local vbC = Instance.new("UICorner")
            vbC.CornerRadius = UDim.new(0, 7)
            vbC.Parent = verifyBtn

            local getKeyBtn
            if getKeyLink then
                getKeyBtn = Instance.new("TextButton")
                getKeyBtn.AnchorPoint = Vector2.new(0.5, 0)
                getKeyBtn.Position = UDim2.new(0.76, 0, 0, 92)
                getKeyBtn.Size = UDim2.new(0, 100, 0, 28)
                getKeyBtn.BackgroundColor3 = NexzanHub.CurrentTheme.Element
                getKeyBtn.BorderSizePixel = 0
                getKeyBtn.Font = Enum.Font.GothamMedium
                getKeyBtn.TextSize = 11
                getKeyBtn.TextColor3 = NexzanHub.CurrentTheme.Text
                getKeyBtn.Text = "Get Key"
                getKeyBtn.AutoButtonColor = false
                getKeyBtn.ZIndex = 96
                getKeyBtn.Parent = modal
                Register(getKeyBtn, { BackgroundColor3 = "Element", TextColor3 = "Text" })
                local gkC = Instance.new("UICorner")
                gkC.CornerRadius = UDim.new(0, 7)
                gkC.Parent = getKeyBtn

                getKeyBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        if typeof(setclipboard) == "function" then setclipboard(getKeyLink) end
                    end)
                    NexzanHub:Notify({ Title = "Nexzan Hub", Content = "Key link copied!", Duration = 2 })
                end)
            end

            local errorLbl = Instance.new("TextLabel")
            errorLbl.BackgroundTransparency = 1
            errorLbl.AnchorPoint = Vector2.new(0.5, 1)
            errorLbl.Position = UDim2.new(0.5, 0, 1, -6)
            errorLbl.Size = UDim2.new(1, -20, 0, 12)
            errorLbl.Font = Enum.Font.GothamMedium
            errorLbl.TextSize = 9
            errorLbl.TextColor3 = Color3.fromRGB(255, 90, 90)
            errorLbl.Text = ""
            errorLbl.ZIndex = 96
            errorLbl.Parent = modal

            local redColor = Color3.fromRGB(255, 60, 60)
            local function InvalidKey()
                NexzanHub:Notify({ Title = "Nexzan Hub", Content = "Invalid Key!", Duration = 2.5 })
                errorLbl.Text = "Invalid Key! Please try again."
                Tween(kiStroke, TweenInfo.new(0.1), { Color = redColor, Transparency = 0 })
                Tween(verifyBtn, TweenInfo.new(0.1), { BackgroundColor3 = redColor })
                -- shake animation
                local origin = modal.Position
                for i = 1, 4 do
                    Tween(modal, TweenInfo.new(0.05), { Position = origin + UDim2.new(0, (i % 2 == 0) and 6 or -6, 0, 0) })
                    task.wait(0.05)
                end
                Tween(modal, TweenInfo.new(0.05), { Position = origin })
                task.delay(0.6, function()
                    Tween(kiStroke, TweenInfo.new(0.3), { Color = NexzanHub.CurrentTheme.Stroke, Transparency = 0.4 })
                    Tween(verifyBtn, TweenInfo.new(0.3), { BackgroundColor3 = NexzanHub.CurrentTheme.Accent })
                end)
            end

            local passed = false
            local function Verify()
                if passed then return end
                local inputKey = keyBox.Text
                local valid = false
                for _, k in ipairs(keys) do
                    if inputKey == k then valid = true break end
                end
                if valid then
                    passed = true
                    Window.KeySystemPassed = true
                    errorLbl.Text = ""
                    Tween(verifyBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(60, 200, 90) })
                    verifyBtn.Text = "Success!"
                    NexzanHub:Notify({ Title = "Nexzan Hub", Content = "Key verified! Welcome.", Duration = 2.5 })
                    if keyCfg.SaveKey then
                        pcall(function()
                            if typeof(writefile) == "function" then writefile(saveFile, inputKey) end
                        end)
                    end
                    task.wait(0.55)
                    -- fade out
                    Tween(dim, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
                    Tween(modal, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                        Size = UDim2.new(0, 280, 0, 0),
                        Position = UDim2.new(0.5, 0, 0.5, 60),
                    })
                    task.wait(0.38)
                    dim:Destroy()
                    modal:Destroy()
                    Window._OpenIntro()
                else
                    InvalidKey()
                end
            end

            verifyBtn.MouseButton1Click:Connect(Verify)
            keyBox.FocusLost:Connect(function(enter)
                if enter then Verify() end
            end)
        end
    else
        Window.KeySystemPassed = true
        task.defer(Window._OpenIntro)
    end

    return Window
end

-- default theme
NexzanHub:SetTheme("Blood Red")

return NexzanHub

end)()
