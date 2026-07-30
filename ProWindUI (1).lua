--[[
    ProWindUI.lua
    WindUI wrapper/mod untuk Roblox UI script.

    Fitur:
    - Load WindUI versi stabil.
    - Memasukkan semua theme dari FluentPro.txt sebagai WindUI theme.
    - Helper double section/kolom Left & Right.
    - Tombol topbar Player dan Theme/Palette di dekat tombol minimize WindUI.
    - Dropdown kecil scrollable untuk Player tools dan Theme selector.
    - Helper koneksi website untuk load script/json dari website kamu.

    Catatan: Gunakan untuk experience/game milikmu sendiri atau environment yang kamu punya izin.
]]

local ProWindUI = {}
ProWindUI.Version = "1.0.0"
ProWindUI.WindUIVersion = "1.6.66"
ProWindUI.DefaultWindUIUrl = "https://github.com/Footagesus/WindUI/releases/download/%s/main.lua"

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function RGB(t)
    return Color3.fromRGB(t[1], t[2], t[3])
end

local function cloneTable(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

local function round(n, step)
    step = step or 1
    return math.floor((n / step) + 0.5) * step
end

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
        return LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return CoreGui
end

local function protect(gui)
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
    if protectgui then pcall(protectgui, gui) end
end

ProWindUI.ThemeOrder = {
    "AMOLED", "Ash Gray", "Blood Red", "Cyanic", "Amber Glow", "Deep Violet",
    "Neon Cyber", "Neon Purple", "Royal Blue", "Deep Ocean", "RGB", "Orange",
    "Charcoal", "Pearl White", "Midnight Blue", "Galaxy Purple", "Cosmic Violet",
    "Cotton Candy", "Arctic Frost"
}

-- Theme dari FluentPro.txt, dikonversi ke schema WindUI:
-- Accent, Background, Outline, Text, Placeholder, Button, Icon.
-- Image/ImageTransparency disimpan untuk background window jika WindUI mendukungnya.
ProWindUI.FluentThemes = {
    ["AMOLED"] = {
        Accent = {255, 255, 255}, Background = {0, 0, 0}, Outline = {20, 20, 20},
        Text = {255, 255, 255}, Placeholder = {150, 150, 150}, Button = {10, 10, 10}, Icon = {255, 255, 255},
        ImageFile = "amoled.png",
        Image = "rbxassetid://134736124666311", ImageTransparency = 0,
    },
    ["Ash Gray"] = {
        Accent = {150, 150, 150}, Background = {60, 60, 60}, Outline = {90, 90, 90},
        Text = {240, 240, 240}, Placeholder = {170, 170, 170}, Button = {120, 120, 120}, Icon = {150, 150, 150},
        ImageFile = "ash-gray.png",
    },
    ["Blood Red"] = {
        Accent = {180, 10, 20}, Background = {35, 8, 10}, Outline = {140, 15, 25},
        Text = {255, 230, 230}, Placeholder = {210, 175, 178}, Button = {130, 12, 22}, Icon = {180, 10, 20},
        ImageFile = "blood-red.png",
        Image = "rbxassetid://121343473918667", ImageTransparency = 0.15,
    },
    ["Cyanic"] = {
        Accent = {57, 197, 187}, Background = {8, 18, 22}, Outline = {40, 170, 165},
        Text = {210, 248, 246}, Placeholder = {130, 210, 205}, Button = {14, 38, 46}, Icon = {57, 197, 187},
        ImageFile = "cyanic.png",
        Image = "rbxassetid://95656189244173", ImageTransparency = 0.12,
    },
    ["Amber Glow"] = {
        Accent = {255, 170, 40}, Background = {18, 10, 4}, Outline = {200, 130, 30},
        Text = {255, 245, 225}, Placeholder = {230, 195, 145}, Button = {38, 20, 5}, Icon = {255, 170, 40},
        ImageFile = "amber-glow.png",
        Image = "rbxassetid://107795771598485", ImageTransparency = 0.12,
    },
    ["Deep Violet"] = {
        Accent = {97, 62, 167}, Background = {20, 20, 20}, Outline = {110, 90, 130},
        Text = {240, 240, 240}, Placeholder = {170, 170, 170}, Button = {140, 120, 160}, Icon = {97, 62, 167},
        ImageFile = "deep-violet.png",
        Image = "rbxassetid://136310484943077", ImageTransparency = 0.15,
    },
    ["Neon Cyber"] = {
        Accent = {57, 255, 20}, Background = {5, 10, 5}, Outline = {40, 200, 20},
        Text = {200, 255, 190}, Placeholder = {80, 200, 60}, Button = {10, 22, 10}, Icon = {57, 255, 20},
        ImageFile = "neon-cyber.png",
    },
    ["Neon Purple"] = {
        Accent = {180, 0, 255}, Background = {5, 0, 15}, Outline = {140, 0, 255},
        Text = {252, 245, 255}, Placeholder = {210, 185, 255}, Button = {120, 0, 210}, Icon = {180, 0, 255},
        ImageFile = "neon-purple.png",
    },
    ["Royal Blue"] = {
        Accent = {15, 82, 186}, Background = {10, 25, 50}, Outline = {10, 65, 150},
        Text = {220, 235, 255}, Placeholder = {170, 190, 220}, Button = {9, 58, 135}, Icon = {15, 82, 186},
        ImageFile = "royal-blue.png",
    },
    ["Deep Ocean"] = {
        Accent = {0, 150, 200}, Background = {15, 30, 45}, Outline = {0, 100, 150},
        Text = {240, 248, 255}, Placeholder = {180, 210, 230}, Button = {0, 90, 135}, Icon = {0, 150, 200},
        ImageFile = "deep-ocean.png",
    },
    ["RGB"] = {
        Accent = {0, 255, 180}, Background = {8, 8, 14}, Outline = {0, 255, 180},
        Text = {220, 255, 245}, Placeholder = {100, 220, 190}, Button = {20, 20, 35}, Icon = {0, 255, 180},
        ImageFile = "rgb.png",
        IsRGB = true,
    },
    ["Orange"] = {
        Accent = {255, 140, 30}, Background = {4, 4, 4}, Outline = {200, 90, 10},
        Text = {255, 240, 220}, Placeholder = {220, 175, 130}, Button = {22, 10, 2}, Icon = {255, 140, 30},
        ImageFile = "orange.png",
        Image = "rbxassetid://122033436660262", ImageTransparency = 0.05,
    },
    ["Charcoal"] = {
        Accent = {102, 102, 102}, Background = {20, 20, 20}, Outline = {60, 60, 60},
        Text = {240, 240, 240}, Placeholder = {170, 170, 170}, Button = {35, 35, 35}, Icon = {102, 102, 102},
        ImageFile = "charcoal.png",
    },
    ["Pearl White"] = {
        Accent = {214, 214, 214}, Background = {240, 240, 240}, Outline = {200, 200, 200},
        Text = {20, 20, 20}, Placeholder = {90, 90, 90}, Button = {220, 220, 220}, Icon = {90, 90, 90},
        ImageFile = "pearl-white.png",
    },
    ["Midnight Blue"] = {
        Accent = {100, 80, 200}, Background = {10, 8, 25}, Outline = {60, 45, 140},
        Text = {220, 220, 255}, Placeholder = {170, 170, 210}, Button = {55, 40, 125}, Icon = {100, 80, 200},
        ImageFile = "midnight-blue.png",
    },
    ["Galaxy Purple"] = {
        Accent = {160, 60, 220}, Background = {12, 5, 25}, Outline = {120, 40, 185},
        Text = {242, 232, 255}, Placeholder = {200, 178, 228}, Button = {112, 40, 170}, Icon = {160, 60, 220},
        ImageFile = "galaxy-purple.png",
    },
    ["Cosmic Violet"] = {
        Accent = {80, 60, 140}, Background = {12, 10, 22}, Outline = {50, 35, 110},
        Text = {230, 225, 245}, Placeholder = {185, 175, 210}, Button = {50, 34, 104}, Icon = {80, 60, 140},
        ImageFile = "cosmic-violet.png",
    },
    ["Cotton Candy"] = {
        Accent = {255, 130, 190}, Background = {255, 225, 245}, Outline = {255, 190, 230},
        Text = {75, 25, 55}, Placeholder = {145, 75, 115}, Button = {255, 200, 235}, Icon = {255, 130, 190},
        ImageFile = "cotton-candy.png",
    },
    ["Arctic Frost"] = {
        Accent = {100, 180, 240}, Background = {185, 215, 235}, Outline = {200, 228, 248},
        Text = {20, 40, 70}, Placeholder = {65, 105, 148}, Button = {210, 235, 250}, Icon = {100, 180, 240},
        ImageFile = "arctic-frost.png",
    },
}

ProWindUI.ThemeMeta = {}
ProWindUI.RegisteredThemeObjects = {}

function ProWindUI:_ConvertTheme(name, raw)
    local t = {
        Name = name,
        Accent = RGB(raw.Accent),
        Background = RGB(raw.Background),
        Outline = RGB(raw.Outline),
        Text = RGB(raw.Text),
        Placeholder = RGB(raw.Placeholder),
        Button = RGB(raw.Button),
        Icon = RGB(raw.Icon or raw.Accent),
    }

    -- Tambahan key umum agar tetap rapi pada beberapa build WindUI.
    t.Element = t.Button
    t.ElementBorder = t.Outline
    t.SubText = t.Placeholder
    t.TitleBarLine = t.Outline
    t.Dropdown = t.Button
    t.DropdownBorder = t.Outline

    self.ThemeMeta[name] = {
        Image = raw.Image,
        ImageFile = raw.ImageFile,
        ImageTransparency = raw.ImageTransparency or 0.1,
        IsRGB = raw.IsRGB == true,
    }

    return t
end

function ProWindUI:RegisterThemes(WindUI)
    WindUI = WindUI or self.WindUI
    if not WindUI then return end

    for _, name in ipairs(self.ThemeOrder) do
        local raw = self.FluentThemes[name]
        if raw then
            local theme = self:_ConvertTheme(name, raw)
            self.RegisteredThemeObjects[name] = theme
            safeCall(function() WindUI:AddTheme(theme) end)
        end
    end
end

function ProWindUI:LoadWindUI(versionOrUrl)
    if self.WindUI then return self.WindUI end

    local url
    if type(versionOrUrl) == "string" and versionOrUrl:match("^https?://") then
        url = versionOrUrl
    else
        local version = versionOrUrl or self.WindUIVersion
        url = self.DefaultWindUIUrl:format(version)
    end

    local WindUI = loadstring(game:HttpGet(url, true))()
    self.WindUI = WindUI
    self:RegisterThemes(WindUI)
    return WindUI
end

function ProWindUI:Notify(title, content, duration)
    if self.WindUI and self.WindUI.Notify then
        return safeCall(function()
            return self.WindUI:Notify({
                Title = title or "ProWindUI",
                Content = content or "",
                Duration = duration or 4,
            })
        end)
    end
end

function ProWindUI:_StopRGB()
    if self._RGBConnection then
        self._RGBConnection:Disconnect()
        self._RGBConnection = nil
    end
end

function ProWindUI:_StartRGB()
    self:_StopRGB()
    local theme = self.RegisteredThemeObjects["RGB"]
    if not theme then return end

    local hue = 0
    self._RGBConnection = RunService.RenderStepped:Connect(function(dt)
        hue = (hue + dt * 0.12) % 1
        local col = Color3.fromHSV(hue, 1, 1)
        theme.Accent = col
        theme.Outline = col
        theme.Icon = col
        theme.ElementBorder = col
        theme.TitleBarLine = col
        if self.Window and self.Window.SetTheme then
            safeCall(function() self.Window:SetTheme("RGB") end)
        elseif self.WindUI and self.WindUI.SetTheme then
            safeCall(function() self.WindUI:SetTheme("RGB") end)
        end
        self:_RefreshOverlayTheme()
    end)
end

function ProWindUI:SetThemeImageBaseUrl(baseUrl)
    if type(baseUrl) ~= "string" or baseUrl == "" then return end
    self.ThemeImageBaseUrl = baseUrl:gsub("/$", "")
    if self.CurrentTheme then
        self:SetTheme(self.CurrentTheme)
    end
end

function ProWindUI:_ResolveThemeImage(name, meta)
    meta = meta or self.ThemeMeta[name]
    if self.ThemeImageBaseUrl and meta and meta.ImageFile then
        return self.ThemeImageBaseUrl:gsub("/$", "") .. "/" .. meta.ImageFile
    end
    return meta and meta.Image or nil
end

function ProWindUI:SetTheme(name)
    if not name or not self.FluentThemes[name] then return end
    self.CurrentTheme = name
    self:_StopRGB()

    if self.Window and self.Window.SetTheme then
        safeCall(function() self.Window:SetTheme(name) end)
    end
    if self.WindUI and self.WindUI.SetTheme then
        safeCall(function() self.WindUI:SetTheme(name) end)
    end

    local meta = self.ThemeMeta[name]
    if self.Window and meta then
        local image = self:_ResolveThemeImage(name, meta)
        if image and self.Window.SetBackgroundImage then
            safeCall(function() self.Window:SetBackgroundImage(image) end)
            if self.Window.SetBackgroundImageTransparency then
                safeCall(function() self.Window:SetBackgroundImageTransparency(meta.ImageTransparency) end)
            end
        elseif self.Window.SetBackgroundImage then
            -- Tidak semua build WindUI suka string kosong, jadi dibungkus pcall.
            safeCall(function() self.Window:SetBackgroundImage("") end)
        end
    end

    if meta and meta.IsRGB then
        self:_StartRGB()
    end

    self:_RefreshOverlayTheme()
end

function ProWindUI:CreateWindow(config)
    config = config or {}
    local WindUI = self:LoadWindUI(config.WindUIUrl or config.WindUIVersion)

    self.Website = config.Website or self.Website
    self.ThemeImageBaseUrl = config.ThemeImageBaseUrl or config.BackgroundBaseUrl or self.ThemeImageBaseUrl

    local windowConfig = cloneTable(config)
    windowConfig.Website = nil
    windowConfig.ThemeImageBaseUrl = nil
    windowConfig.BackgroundBaseUrl = nil
    windowConfig.WindUIUrl = nil
    windowConfig.WindUIVersion = nil
    windowConfig.Theme = windowConfig.Theme or "AMOLED"

    local Window = WindUI:CreateWindow(windowConfig)
    self.Window = Window
    self.CurrentTheme = windowConfig.Theme

    self:SetTheme(windowConfig.Theme)
    task.defer(function()
        self:_CreateQuickGui()
        self:_CreateTopbarButtons()
        self:_SetupCharacterReapply()
    end)

    return Window
end

-- Helper double section: membuat kolom Left & Right di dalam tab.
function ProWindUI:DoubleSection(Tab, leftConfig, rightConfig)
    leftConfig = leftConfig or { Title = "Left" }
    rightConfig = rightConfig or { Title = "Right" }

    local ok, HStack = pcall(function()
        return Tab:HStack({ AutoSpace = true })
    end)

    if ok and HStack then
        local LeftStack = HStack:VStack()
        local RightStack = HStack:VStack()
        local Left = LeftStack:Section(leftConfig)
        local Right = RightStack:Section(rightConfig)
        return Left, Right, LeftStack, RightStack
    end

    -- Fallback kalau build WindUI tidak punya HStack/VStack.
    local Left = Tab:Section(leftConfig)
    local Right = Tab:Section(rightConfig)
    return Left, Right, Tab, Tab
end

function ProWindUI:ConnectWebsite(baseUrl)
    assert(type(baseUrl) == "string" and baseUrl ~= "", "baseUrl website wajib string")
    self.Website = baseUrl:gsub("/$", "")

    local api = {}

    local function makeUrl(path)
        path = tostring(path or "")
        if path:match("^https?://") then return path end
        if path ~= "" and path:sub(1, 1) ~= "/" then path = "/" .. path end
        return self.Website .. path
    end

    function api:Get(path)
        local url = makeUrl(path)
        if game.HttpGet then
            return game:HttpGet(url, true)
        end
        return HttpService:GetAsync(url)
    end

    function api:JSON(path)
        return HttpService:JSONDecode(self:Get(path))
    end

    function api:Load(path, ...)
        local source = self:Get(path)
        local fn = assert(loadstring(source), "Gagal loadstring dari website: " .. tostring(path))
        return fn(...)
    end

    function api:Url(path)
        return makeUrl(path)
    end

    return api
end

function ProWindUI:OpenWebsite()
    local url = self.Website
    if not url or url == "" then
        self:Notify("Website", "Belum ada Website di config ProWindUI.", 4)
        return
    end

    local copied = false
    if setclipboard then
        copied = pcall(function() setclipboard(url) end)
    elseif toclipboard then
        copied = pcall(function() toclipboard(url) end)
    end

    safeCall(function() GuiService:OpenBrowserWindow(url) end)
    self:Notify("Website", copied and ("URL disalin: " .. url) or ("Website: " .. url), 5)
end

function ProWindUI:_GetThemeColors()
    local raw = self.FluentThemes[self.CurrentTheme or "AMOLED"] or self.FluentThemes.AMOLED
    return {
        accent = RGB(raw.Accent),
        bg = RGB(raw.Background),
        outline = RGB(raw.Outline),
        text = RGB(raw.Text),
        sub = RGB(raw.Placeholder),
        button = RGB(raw.Button),
    }
end

function ProWindUI:_RefreshOverlayTheme()
    if not self._OverlayObjects then return end
    local c = self:_GetThemeColors()
    for _, obj in ipairs(self._OverlayObjects) do
        if obj and obj.Parent then
            if obj:IsA("Frame") or obj:IsA("TextButton") or obj:IsA("ScrollingFrame") then
                if obj:GetAttribute("Role") == "Panel" then
                    obj.BackgroundColor3 = c.bg
                elseif obj:GetAttribute("Role") == "Button" then
                    obj.BackgroundColor3 = c.button
                elseif obj:GetAttribute("Role") == "Accent" then
                    obj.BackgroundColor3 = c.accent
                end
            end
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.TextColor3 = (obj:GetAttribute("SubText") and c.sub) or c.text
            end
            if obj:IsA("UIStroke") then
                obj.Color = c.outline
            end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                obj.ImageColor3 = c.accent
            end
        end
    end
end

function ProWindUI:_RegisterOverlay(obj)
    self._OverlayObjects = self._OverlayObjects or {}
    table.insert(self._OverlayObjects, obj)
    return obj
end

function ProWindUI:_CreateQuickGui()
    if self._QuickGui and self._QuickGui.Parent then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ProWindUI_QuickMenus"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999
    gui.Parent = getGuiParent()
    protect(gui)
    self._QuickGui = gui
    self._OverlayObjects = {}

    self._PlayerMenu = self:_BuildPanel("PlayerMenu", UDim2.fromOffset(260, 330), UDim2.new(1, -286, 0, 70), "Player Tools")
    self:_BuildPlayerTools(self._PlayerMenu.Scroll)

    self._ThemeMenu = self:_BuildPanel("ThemeMenu", UDim2.fromOffset(250, 330), UDim2.new(1, -548, 0, 70), "FluentPro Themes")
    self:_BuildThemeSelector(self._ThemeMenu.Scroll)

    self:_RefreshOverlayTheme()
end

function ProWindUI:_BuildPanel(name, size, pos, title)
    local c = self:_GetThemeColors()

    local panel = self:_RegisterOverlay(Instance.new("Frame"))
    panel.Name = name
    panel.Visible = false
    panel.Size = size
    panel.Position = pos
    panel.BackgroundColor3 = c.bg
    panel.BorderSizePixel = 0
    panel:SetAttribute("Role", "Panel")
    panel.Parent = self._QuickGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = self:_RegisterOverlay(Instance.new("UIStroke"))
    stroke.Color = c.outline
    stroke.Thickness = 1
    stroke.Transparency = 0.15
    stroke.Parent = panel

    local titleLabel = self:_RegisterOverlay(Instance.new("TextLabel"))
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(12, 8)
    titleLabel.Size = UDim2.new(1, -42, 0, 22)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title
    titleLabel.TextColor3 = c.text
    titleLabel.Parent = panel

    local close = self:_RegisterOverlay(Instance.new("TextButton"))
    close.Name = "Close"
    close.BackgroundTransparency = 1
    close.Position = UDim2.new(1, -32, 0, 7)
    close.Size = UDim2.fromOffset(24, 24)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 16
    close.Text = "×"
    close.TextColor3 = c.text
    close.Parent = panel
    close.MouseButton1Click:Connect(function() panel.Visible = false end)

    local scroll = self:_RegisterOverlay(Instance.new("ScrollingFrame"))
    scroll.Name = "Scroll"
    scroll.Position = UDim2.fromOffset(10, 38)
    scroll.Size = UDim2.new(1, -20, 1, -48)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = c.accent
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    return { Panel = panel, Scroll = scroll }
end

function ProWindUI:_ShowOnly(menuName)
    if self._PlayerMenu then self._PlayerMenu.Panel.Visible = menuName == "Player" and not self._PlayerMenu.Panel.Visible end
    if self._ThemeMenu then self._ThemeMenu.Panel.Visible = menuName == "Theme" and not self._ThemeMenu.Panel.Visible end
end

function ProWindUI:_CreateTopbarButtons()
    if self._TopbarCreated then return end
    self._TopbarCreated = true

    local Window = self.Window
    if Window and Window.CreateTopbarButton then
        safeCall(function()
            Window:CreateTopbarButton("ProWind_Player", "user", function()
                self:_ShowOnly("Player")
            end, 997, true, nil, 18)
        end)
        safeCall(function()
            Window:CreateTopbarButton("ProWind_Theme", "palette", function()
                self:_ShowOnly("Theme")
            end, 998, true, nil, 18)
        end)
        if self.Website then
            safeCall(function()
                Window:CreateTopbarButton("ProWind_Website", "globe", function()
                    self:OpenWebsite()
                end, 996, true, nil, 18)
            end)
        end
        return
    end

    -- Fallback jika CreateTopbarButton tidak tersedia.
    self:_CreateFloatingButtonsFallback()
end

function ProWindUI:_CreateFloatingButtonsFallback()
    local c = self:_GetThemeColors()
    local holder = self:_RegisterOverlay(Instance.new("Frame"))
    holder.Name = "FallbackTopButtons"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(92, 34)
    holder.Position = UDim2.new(1, -106, 0, 26)
    holder.Parent = self._QuickGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.Parent = holder

    local function mini(txt, cb)
        local b = self:_RegisterOverlay(Instance.new("TextButton"))
        b.Size = UDim2.fromOffset(34, 34)
        b.BackgroundColor3 = c.button
        b.TextColor3 = c.text
        b.Text = txt
        b.Font = Enum.Font.GothamBold
        b.TextSize = 16
        b:SetAttribute("Role", "Button")
        b.Parent = holder
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        b.MouseButton1Click:Connect(cb)
    end

    mini("👤", function() self:_ShowOnly("Player") end)
    mini("🎨", function() self:_ShowOnly("Theme") end)
end

function ProWindUI:_AddLabel(parent, text, sub)
    local c = self:_GetThemeColors()
    local label = self:_RegisterOverlay(Instance.new("TextLabel"))
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -2, 0, sub and 16 or 18)
    label.Font = sub and Enum.Font.Gotham or Enum.Font.GothamBold
    label.TextSize = sub and 11 or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.TextColor3 = sub and c.sub or c.text
    label:SetAttribute("SubText", sub == true)
    label.Parent = parent
    return label
end

function ProWindUI:_AddButton(parent, title, callback)
    local c = self:_GetThemeColors()
    local b = self:_RegisterOverlay(Instance.new("TextButton"))
    b.Size = UDim2.new(1, -2, 0, 34)
    b.BackgroundColor3 = c.button
    b.TextColor3 = c.text
    b.Text = title
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.AutoButtonColor = true
    b:SetAttribute("Role", "Button")
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local stroke = self:_RegisterOverlay(Instance.new("UIStroke"))
    stroke.Color = c.outline
    stroke.Transparency = 0.45
    stroke.Parent = b
    b.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)
    return b
end

function ProWindUI:_AddToggle(parent, title, default, callback)
    local state = default == true
    local btn
    local function redraw()
        btn.Text = (state and "[ ON ]  " or "[ OFF ] ") .. title
    end
    btn = self:_AddButton(parent, "", function()
        state = not state
        redraw()
        safeCall(callback, state)
    end)
    redraw()
    return {
        Set = function(_, v)
            state = v == true
            redraw()
            safeCall(callback, state)
        end,
        Get = function() return state end,
    }
end

function ProWindUI:_AddSlider(parent, title, min, max, default, step, callback)
    local c = self:_GetThemeColors()
    local value = default or min
    step = step or 1

    local holder = self:_RegisterOverlay(Instance.new("Frame"))
    holder.Size = UDim2.new(1, -2, 0, 56)
    holder.BackgroundColor3 = c.button
    holder.BorderSizePixel = 0
    holder:SetAttribute("Role", "Button")
    holder.Parent = parent
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

    local stroke = self:_RegisterOverlay(Instance.new("UIStroke"))
    stroke.Color = c.outline
    stroke.Transparency = 0.5
    stroke.Parent = holder

    local label = self:_RegisterOverlay(Instance.new("TextLabel"))
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(10, 5)
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 12
    label.TextColor3 = c.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local bar = Instance.new("TextButton")
    bar.Text = ""
    bar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    bar.BorderSizePixel = 0
    bar.Position = UDim2.fromOffset(10, 32)
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = self:_RegisterOverlay(Instance.new("Frame"))
    fill.BackgroundColor3 = c.accent
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(0, 1)
    fill:SetAttribute("Role", "Accent")
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = self:_RegisterOverlay(Instance.new("Frame"))
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = c.accent
    knob.BorderSizePixel = 0
    knob:SetAttribute("Role", "Accent")
    knob.Parent = bar
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function set(v, fire)
        v = math.clamp(v, min, max)
        v = round(v, step)
        value = v
        local alpha = (v - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        label.Text = string.format("%s: %s", title, tostring(v))
        if fire ~= false then safeCall(callback, v) end
    end

    local function setFromX(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        set(min + (max - min) * alpha, true)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)

    set(value, false)
    return { Set = function(_, v) set(v, true) end, Get = function() return value end }
end

function ProWindUI:_GetHumanoid()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function ProWindUI:_ApplyWalkSpeed(v)
    self.PlayerSettings = self.PlayerSettings or {}
    self.PlayerSettings.WalkSpeed = v
    local hum = self:_GetHumanoid()
    if hum then safeCall(function() hum.WalkSpeed = v end) end
end

function ProWindUI:_ApplyJumpPower(v)
    self.PlayerSettings = self.PlayerSettings or {}
    self.PlayerSettings.JumpPower = v
    local hum = self:_GetHumanoid()
    if hum then
        safeCall(function() hum.UseJumpPower = true end)
        local ok = pcall(function() hum.JumpPower = v end)
        if not ok then
            safeCall(function() hum.JumpHeight = math.max(1, v / 7) end)
        end
    end
end

function ProWindUI:_SetNoclip(enabled)
    self.PlayerSettings = self.PlayerSettings or {}
    self.PlayerSettings.Noclip = enabled
    if self._NoclipConn then self._NoclipConn:Disconnect(); self._NoclipConn = nil end
    if not enabled then return end
    self._NoclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer and LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

function ProWindUI:_SetInfiniteJump(enabled)
    self.PlayerSettings = self.PlayerSettings or {}
    self.PlayerSettings.InfiniteJump = enabled
    if self._InfiniteJumpConn then self._InfiniteJumpConn:Disconnect(); self._InfiniteJumpConn = nil end
    if not enabled then return end
    self._InfiniteJumpConn = UserInputService.JumpRequest:Connect(function()
        local hum = self:_GetHumanoid()
        if hum then safeCall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end)
end

function ProWindUI:_SetFullBright(enabled)
    self.PlayerSettings = self.PlayerSettings or {}
    self.PlayerSettings.FullBright = enabled
    if enabled then
        if not self._OldLighting then
            self._OldLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    elseif self._OldLighting then
        for k, v in pairs(self._OldLighting) do safeCall(function() Lighting[k] = v end) end
        self._OldLighting = nil
    end
end

function ProWindUI:_SetupCharacterReapply()
    if self._CharAddedConn or not LocalPlayer then return end
    self._CharAddedConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.8)
        local s = self.PlayerSettings or {}
        if s.WalkSpeed then self:_ApplyWalkSpeed(s.WalkSpeed) end
        if s.JumpPower then self:_ApplyJumpPower(s.JumpPower) end
    end)
end

function ProWindUI:_BuildPlayerTools(parent)
    local hum = self:_GetHumanoid()
    local currentSpeed = hum and hum.WalkSpeed or 16
    local currentJump = hum and hum.JumpPower or 50
    local cam = workspace.CurrentCamera

    self:_AddLabel(parent, "Movement")
    self:_AddSlider(parent, "WalkSpeed", 16, 200, currentSpeed, 1, function(v)
        self:_ApplyWalkSpeed(v)
    end)
    self:_AddSlider(parent, "Jump Power", 50, 300, currentJump, 1, function(v)
        self:_ApplyJumpPower(v)
    end)
    self:_AddToggle(parent, "No Clip", false, function(v)
        self:_SetNoclip(v)
    end)
    self:_AddToggle(parent, "Infinite Jump", false, function(v)
        self:_SetInfiniteJump(v)
    end)

    self:_AddLabel(parent, "Visual / World")
    self:_AddToggle(parent, "Full Bright", false, function(v)
        self:_SetFullBright(v)
    end)
    self:_AddSlider(parent, "FOV", 60, 120, cam and cam.FieldOfView or 70, 1, function(v)
        local camera = workspace.CurrentCamera
        if camera then camera.FieldOfView = v end
    end)
    self:_AddSlider(parent, "Gravity", 30, 196, workspace.Gravity, 1, function(v)
        workspace.Gravity = v
    end)

    self:_AddLabel(parent, "Utility")
    self:_AddButton(parent, "Reset Character", function()
        local h = self:_GetHumanoid()
        if h then h.Health = 0 end
    end)
    self:_AddButton(parent, "Copy Player Name", function()
        if setclipboard and LocalPlayer then setclipboard(LocalPlayer.Name) end
        self:Notify("Player", "Nama player disalin.", 3)
    end)
end

function ProWindUI:_BuildThemeSelector(parent)
    self:_AddLabel(parent, "Pilih theme dari FluentPro", true)
    for _, name in ipairs(self.ThemeOrder) do
        local raw = self.FluentThemes[name]
        if raw then
            local btn = self:_AddButton(parent, name, function()
                self:SetTheme(name)
                self:Notify("Theme", "Theme diganti ke " .. name, 3)
            end)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = "      " .. name

            local swatch = self:_RegisterOverlay(Instance.new("Frame"))
            swatch.Size = UDim2.fromOffset(16, 16)
            swatch.Position = UDim2.fromOffset(10, 9)
            swatch.BackgroundColor3 = RGB(raw.Accent)
            swatch.BorderSizePixel = 0
            swatch:SetAttribute("Role", "Static")
            swatch.Parent = btn
            Instance.new("UICorner", swatch).CornerRadius = UDim.new(1, 0)
        end
    end
end

return ProWindUI
