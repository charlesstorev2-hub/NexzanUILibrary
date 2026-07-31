--[[
    WindUI Player Tools Add-on / UI Library
    Bahasa: Indonesia

    Tujuan:
    - Membuat window WindUI.
    - Menambah icon Player di topbar WindUI lewat API CreateTopbarButton.
    - Saat icon diklik, muncul dropdown kecil yang bisa di-scroll.
    - Dropdown berisi WalkSpeed, JumpPower, NoClip, Full Bright, FOV, Gravity, HipHeight,
      Infinite Jump, reset, dan koneksi website/config.

    Catatan etika & keamanan:
    Pakai script ini hanya untuk game/experience Roblox milik Anda sendiri, private server,
    admin panel, QA/testing, atau fitur yang memang Anda izinkan. Jangan dipakai untuk
    mengeksploitasi game orang lain atau melanggar ToS/aturan game.

    Cara pakai cepat via loadstring setelah file ini Anda host di raw URL milik Anda:

        local HubLib = loadstring(game:HttpGet("https://domain-kamu.com/WindUI_PlayerTools_Library.lua"))()
        HubLib.new({
            Window = {
                Title = "Nama Hub Kamu",
                Author = "by Kamu",
            },
            Website = {
                Enabled = true,
                Homepage = "https://domain-kamu.com",
                ConfigUrl = "https://domain-kamu.com/config.json",

                -- Demi keamanan default-nya false. Aktifkan hanya kalau URL remote script
                -- 100% milik Anda dan Anda paham risikonya.
                AllowRemoteScript = false,
                RemoteScriptUrl = "https://domain-kamu.com/remote.lua",
            },
            Security = {
                -- Kosong = semua user bisa. Untuk game publik, isi whitelist UserId.
                AllowedUserIds = {},
            }
        }):Init()

    Kalau ingin langsung paste sebagai script executor/testing, bagian AUTORUN di bawah
    bisa Anda ubah menjadi true dan edit DEFAULT_CONFIG.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local AUTORUN = false -- Ubah true kalau file ini mau langsung jalan saat dipaste/loadstring.

local DEFAULT_CONFIG = {
    WindUI = {
        Version = "1.6.66",
        -- "selected" = release spesifik sesuai Version, "latest" = latest release,
        -- "dist" = branch main/dist/main.lua, biasanya lebih tidak stabil.
        LoadMode = "selected",
        Object = nil, -- Isi kalau Anda sudah punya object WindUI dari luar.
    },

    Window = {
        Title = "My Roblox Hub",
        Icon = "user-round",
        Author = "by YourName",
        Folder = "MyRobloxHub",
        Size = UDim2.fromOffset(580, 420),
        Theme = "Dark",
        ToggleKey = Enum.KeyCode.RightControl,
        Acrylic = true,
        Resizable = true,
    },

    QuickMenu = {
        Enabled = true,
        TopbarIcon = "user-round",
        -- Kalau posisi icon belum tepat di samping minimize, ubah angka ini.
        -- Semakin besar/kecil efeknya tergantung layout internal WindUI.
        TopbarOrder = 998,
        Width = 286,
        Height = 356,
        OffsetFromMouse = Vector2.new(-260, 8),
        CloseWhenClickOutside = true,
    },

    PlayerTools = {
        AddWindUITab = true,
        WalkSpeed = { Min = 16, Max = 200, Default = 16, Step = 1 },
        JumpPower = { Min = 50, Max = 250, Default = 50, Step = 1 },
        FieldOfView = { Min = 60, Max = 120, Default = 70, Step = 1 },
        Gravity = { Min = 0, Max = 300, Default = 196.2, Step = 1 },
        HipHeight = { Min = 0, Max = 15, Default = 2, Step = 0.5 },
    },

    Website = {
        Enabled = false,
        Homepage = "https://domain-kamu.com",
        ConfigUrl = "", -- contoh: https://domain-kamu.com/config.json
        PingUrl = "", -- opsional, contoh: https://domain-kamu.com/ping?uid={userid}&name={username}
        AllowRemoteScript = false,
        RemoteScriptUrl = "",
    },

    Security = {
        -- Kosong = bebas. Isi UserId owner/admin agar hanya user tertentu yang bisa pakai.
        AllowedUserIds = {},
        StudioOnly = false,
    }
}

local function cloneTable(tbl)
    local output = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            output[k] = cloneTable(v)
        else
            output[k] = v
        end
    end
    return output
end

local function deepMerge(base, override)
    local output = cloneTable(base)
    override = override or {}
    for k, v in pairs(override) do
        if type(v) == "table" and type(output[k]) == "table" then
            output[k] = deepMerge(output[k], v)
        else
            output[k] = v
        end
    end
    return output
end

local function safePcall(callback, ...)
    local ok, result = pcall(callback, ...)
    if ok then
        return true, result
    end
    warn("[WindUI PlayerTools]", result)
    return false, result
end

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function makeStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(80, 88, 110)
    stroke.Transparency = transparency or 0.35
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function makePadding(parent, l, t, r, b)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, l or 0)
    padding.PaddingTop = UDim.new(0, t or 0)
    padding.PaddingRight = UDim.new(0, r or 0)
    padding.PaddingBottom = UDim.new(0, b or 0)
    padding.Parent = parent
    return padding
end

local function formatNumber(value, step)
    if step and step < 1 then
        return string.format("%.1f", value)
    end
    return tostring(math.floor(value + 0.5))
end

local function roundToStep(value, min, max, step)
    step = step or 1
    local rounded = math.floor(((value - min) / step) + 0.5) * step + min
    if rounded < min then rounded = min end
    if rounded > max then rounded = max end
    return rounded
end

function Library.new(userConfig)
    local self = setmetatable({}, Library)
    self.Config = deepMerge(DEFAULT_CONFIG, userConfig or {})
    self.Connections = {}
    self.SliderHandles = {}
    self.ToggleHandles = {}
    self.State = {
        WalkSpeed = self.Config.PlayerTools.WalkSpeed.Default,
        JumpPower = self.Config.PlayerTools.JumpPower.Default,
        FieldOfView = self.Config.PlayerTools.FieldOfView.Default,
        Gravity = self.Config.PlayerTools.Gravity.Default,
        HipHeight = self.Config.PlayerTools.HipHeight.Default,
        NoClip = false,
        FullBright = false,
        InfiniteJump = false,
    }
    self.Original = {}
    self.FullBrightBackup = nil
    self.WindUI = self.Config.WindUI.Object
    self.Window = nil
    self.Gui = nil
    self.Dropdown = nil
    return self
end

function Library:_track(connection)
    if connection then
        table.insert(self.Connections, connection)
    end
    return connection
end

function Library:_isAllowed()
    if not LocalPlayer then
        return false, "Script ini harus berjalan di client/LocalScript."
    end

    if self.Config.Security.StudioOnly and not RunService:IsStudio() then
        return false, "StudioOnly aktif, script hanya boleh jalan di Roblox Studio."
    end

    local allowed = self.Config.Security.AllowedUserIds or {}
    if #allowed == 0 then
        return true
    end

    for _, userId in ipairs(allowed) do
        if tonumber(userId) == LocalPlayer.UserId then
            return true
        end
    end

    return false, "UserId " .. tostring(LocalPlayer.UserId) .. " belum ada di whitelist."
end

function Library:_httpGet(url)
    if not url or url == "" then
        return nil
    end

    -- Executor request API jika tersedia.
    local requestFn = nil
    if typeof(request) == "function" then
        requestFn = request
    elseif typeof(http_request) == "function" then
        requestFn = http_request
    elseif type(syn) == "table" and typeof(syn.request) == "function" then
        requestFn = syn.request
    end

    if requestFn then
        local ok, response = pcall(function()
            return requestFn({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Cache-Control"] = "no-cache",
                }
            })
        end)
        if ok and response then
            return response.Body or response.body or response.Response or response.response
        end
    end

    -- game:HttpGet untuk environment yang mendukung.
    local okGameHttp, body = pcall(function()
        return game:HttpGet(url)
    end)
    if okGameHttp and body then
        return body
    end

    -- HttpService fallback. Di client biasa biasanya tidak bisa, tapi berguna di Studio/server.
    local okHttpService, serviceBody = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if okHttpService and serviceBody then
        return serviceBody
    end

    return nil
end

function Library:_getWindUIUrl()
    local mode = string.lower(tostring(self.Config.WindUI.LoadMode or "selected"))
    if mode == "latest" then
        return "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    end
    if mode == "dist" then
        return "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
    end
    return "https://github.com/Footagesus/WindUI/releases/download/" .. tostring(self.Config.WindUI.Version) .. "/main.lua"
end

function Library:_loadWindUI()
    if self.WindUI then
        return self.WindUI
    end

    local url = self:_getWindUIUrl()
    local source = self:_httpGet(url)
    assert(source and #source > 0, "Gagal mengambil WindUI dari: " .. tostring(url))

    assert(typeof(loadstring) == "function", "loadstring tidak tersedia di environment ini. Jika pakai Roblox Studio, gunakan ModuleScript/require atau aktifkan arsitektur server yang aman.")

    local fn, compileErr = loadstring(source)
    assert(fn, "Gagal compile WindUI: " .. tostring(compileErr))

    self.WindUI = fn()
    return self.WindUI
end

function Library:Notify(title, content, icon, duration)
    if self.WindUI and typeof(self.WindUI.Notify) == "function" then
        pcall(function()
            self.WindUI:Notify({
                Title = title or "Info",
                Content = content or "",
                Icon = icon or "info",
                Duration = duration or 3,
            })
        end)
    else
        warn("[WindUI PlayerTools] " .. tostring(title) .. " - " .. tostring(content))
    end
end

function Library:_captureOriginalValues()
    local humanoid = self:GetHumanoid()
    self.Original.Gravity = Workspace.Gravity
    self.Original.FieldOfView = Workspace.CurrentCamera and Workspace.CurrentCamera.FieldOfView or self.Config.PlayerTools.FieldOfView.Default

    if humanoid then
        self.Original.WalkSpeed = humanoid.WalkSpeed
        local okJumpPower, jumpPower = pcall(function()
            return humanoid.JumpPower
        end)
        self.Original.JumpPower = okJumpPower and jumpPower or self.Config.PlayerTools.JumpPower.Default
        self.Original.HipHeight = humanoid.HipHeight
    else
        self.Original.WalkSpeed = self.Config.PlayerTools.WalkSpeed.Default
        self.Original.JumpPower = self.Config.PlayerTools.JumpPower.Default
        self.Original.HipHeight = self.Config.PlayerTools.HipHeight.Default
    end

    self.State.WalkSpeed = self.Original.WalkSpeed
    self.State.JumpPower = self.Original.JumpPower
    self.State.FieldOfView = self.Original.FieldOfView
    self.State.Gravity = self.Original.Gravity
    self.State.HipHeight = self.Original.HipHeight
end

function Library:GetCharacter()
    return LocalPlayer and LocalPlayer.Character or nil
end

function Library:GetHumanoid()
    local character = self:GetCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

function Library:ApplyMovementSettings()
    local humanoid = self:GetHumanoid()
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = self.State.WalkSpeed
        end)
        pcall(function()
            humanoid.UseJumpPower = true
        end)
        pcall(function()
            humanoid.JumpPower = self.State.JumpPower
        end)
        pcall(function()
            humanoid.HipHeight = self.State.HipHeight
        end)
    end

    pcall(function()
        Workspace.Gravity = self.State.Gravity
    end)

    pcall(function()
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = self.State.FieldOfView
        end
    end)
end

function Library:SetWalkSpeed(value)
    self.State.WalkSpeed = tonumber(value) or self.State.WalkSpeed
    self:ApplyMovementSettings()
end

function Library:SetJumpPower(value)
    self.State.JumpPower = tonumber(value) or self.State.JumpPower
    self:ApplyMovementSettings()
end

function Library:SetFOV(value)
    self.State.FieldOfView = tonumber(value) or self.State.FieldOfView
    self:ApplyMovementSettings()
end

function Library:SetGravity(value)
    self.State.Gravity = tonumber(value) or self.State.Gravity
    self:ApplyMovementSettings()
end

function Library:SetHipHeight(value)
    self.State.HipHeight = tonumber(value) or self.State.HipHeight
    self:ApplyMovementSettings()
end

function Library:SetNoClip(enabled)
    self.State.NoClip = enabled == true

    if self.NoClipConnection then
        self.NoClipConnection:Disconnect()
        self.NoClipConnection = nil
    end

    if self.State.NoClip then
        self.NoClipConnection = RunService.Stepped:Connect(function()
            local character = self:GetCharacter()
            if not character then return end
            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.CanCollide = false
                end
            end
        end)
    end
end

function Library:SetInfiniteJump(enabled)
    self.State.InfiniteJump = enabled == true

    if self.InfiniteJumpConnection then
        self.InfiniteJumpConnection:Disconnect()
        self.InfiniteJumpConnection = nil
    end

    if self.State.InfiniteJump then
        self.InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            local humanoid = self:GetHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

function Library:SetFullBright(enabled)
    self.State.FullBright = enabled == true

    if self.FullBrightConnection then
        self.FullBrightConnection:Disconnect()
        self.FullBrightConnection = nil
    end

    if self.State.FullBright then
        if not self.FullBrightBackup then
            self.FullBrightBackup = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                ExposureCompensation = Lighting.ExposureCompensation,
            }
        end

        local function applyBright()
            Lighting.Brightness = 2.5
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ExposureCompensation = 0.15
        end

        applyBright()
        self.FullBrightConnection = RunService.RenderStepped:Connect(applyBright)
    else
        if self.FullBrightBackup then
            for property, value in pairs(self.FullBrightBackup) do
                pcall(function()
                    Lighting[property] = value
                end)
            end
        end
        self.FullBrightBackup = nil
    end
end

function Library:ResetPlayerTools()
    self:SetNoClip(false)
    self:SetInfiniteJump(false)
    self:SetFullBright(false)

    self.State.WalkSpeed = self.Original.WalkSpeed or self.Config.PlayerTools.WalkSpeed.Default
    self.State.JumpPower = self.Original.JumpPower or self.Config.PlayerTools.JumpPower.Default
    self.State.FieldOfView = self.Original.FieldOfView or self.Config.PlayerTools.FieldOfView.Default
    self.State.Gravity = self.Original.Gravity or self.Config.PlayerTools.Gravity.Default
    self.State.HipHeight = self.Original.HipHeight or self.Config.PlayerTools.HipHeight.Default
    self:ApplyMovementSettings()

    if self.SliderHandles.WalkSpeed then self.SliderHandles.WalkSpeed:Set(self.State.WalkSpeed, true) end
    if self.SliderHandles.JumpPower then self.SliderHandles.JumpPower:Set(self.State.JumpPower, true) end
    if self.SliderHandles.FieldOfView then self.SliderHandles.FieldOfView:Set(self.State.FieldOfView, true) end
    if self.SliderHandles.Gravity then self.SliderHandles.Gravity:Set(self.State.Gravity, true) end
    if self.SliderHandles.HipHeight then self.SliderHandles.HipHeight:Set(self.State.HipHeight, true) end
    if self.ToggleHandles.NoClip then self.ToggleHandles.NoClip:Set(false, true) end
    if self.ToggleHandles.FullBright then self.ToggleHandles.FullBright:Set(false, true) end
    if self.ToggleHandles.InfiniteJump then self.ToggleHandles.InfiniteJump:Set(false, true) end

    self:Notify("Player Tools", "Semua setting player dikembalikan.", "rotate-ccw", 3)
end

function Library:ResetCharacter()
    local humanoid = self:GetHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
end

function Library:_getGuiParent()
    local okHui, hui = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return nil
    end)
    if okHui and hui then
        return hui
    end

    local okCore = pcall(function()
        return CoreGui.Name
    end)
    if okCore then
        return CoreGui
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    return playerGui
end

function Library:_createBaseGui()
    local parent = self:_getGuiParent()
    local guiName = "WindUI_PlayerTools_QuickDropdown"

    local oldGui = parent:FindFirstChild(guiName)
    if oldGui then
        oldGui:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = parent

    self.Gui = gui
    return gui
end

function Library:_createSlider(parent, options)
    local title = options.Title or "Slider"
    local min = tonumber(options.Min) or 0
    local max = tonumber(options.Max) or 100
    local default = tonumber(options.Default) or min
    local step = tonumber(options.Step) or 1
    local callback = options.Callback or function() end

    local row = Instance.new("Frame")
    row.Name = title .. "Row"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 58)
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "Title"
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(0, 0)
    label.Size = UDim2.new(1, -58, 0, 22)
    label.Font = Enum.Font.GothamMedium
    label.Text = title
    label.TextColor3 = Color3.fromRGB(235, 239, 255)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.BackgroundTransparency = 1
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, 0, 0, 0)
    valueLabel.Size = UDim2.fromOffset(54, 22)
    valueLabel.Font = Enum.Font.GothamSemibold
    valueLabel.TextColor3 = Color3.fromRGB(126, 185, 255)
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row

    local bar = Instance.new("TextButton")
    bar.Name = "Bar"
    bar.AutoButtonColor = false
    bar.Text = ""
    bar.BackgroundColor3 = Color3.fromRGB(36, 42, 58)
    bar.Position = UDim2.fromOffset(0, 31)
    bar.Size = UDim2.new(1, 0, 0, 10)
    bar.Parent = row
    makeCorner(bar, 8)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.fromRGB(88, 166, 255)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(0, 1)
    fill.Parent = bar
    makeCorner(fill, 8)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Parent = bar
    makeCorner(knob, 50)
    makeStroke(knob, Color3.fromRGB(88, 166, 255), 0, 2)

    local current = default
    local dragging = false

    local function render(value)
        local alpha = 0
        if max > min then
            alpha = (value - min) / (max - min)
        end
        alpha = math.clamp(alpha, 0, 1)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = formatNumber(value, step)
    end

    local handle = {}

    function handle:Set(value, silent)
        current = roundToStep(tonumber(value) or current, min, max, step)
        render(current)
        if not silent then
            callback(current)
        end
    end

    function handle:Get()
        return current
    end

    local function updateFromInput(input)
        local alpha = (input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X)
        alpha = math.clamp(alpha, 0, 1)
        local raw = min + ((max - min) * alpha)
        handle:Set(raw)
    end

    self:_track(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input)
        end
    end))

    self:_track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(input)
        end
    end))

    self:_track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    handle:Set(default, true)
    return handle
end

function Library:_createToggle(parent, options)
    local title = options.Title or "Toggle"
    local default = options.Default == true
    local callback = options.Callback or function() end

    local button = Instance.new("TextButton")
    button.Name = title .. "Toggle"
    button.AutoButtonColor = false
    button.Text = ""
    button.BackgroundColor3 = Color3.fromRGB(27, 32, 45)
    button.Size = UDim2.new(1, 0, 0, 42)
    button.Parent = parent
    makeCorner(button, 10)
    makeStroke(button, Color3.fromRGB(78, 87, 110), 0.55, 1)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromOffset(12, 0)
    label.Size = UDim2.new(1, -72, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = title
    label.TextColor3 = Color3.fromRGB(235, 239, 255)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button

    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, -12, 0.5, 0)
    track.Size = UDim2.fromOffset(42, 22)
    track.BackgroundColor3 = Color3.fromRGB(55, 61, 78)
    track.Parent = button
    makeCorner(track, 20)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.BackgroundColor3 = Color3.fromRGB(240, 244, 255)
    knob.Parent = track
    makeCorner(knob, 50)

    local state = default
    local handle = {}

    local function render(animated)
        local targetColor = state and Color3.fromRGB(72, 163, 255) or Color3.fromRGB(55, 61, 78)
        local targetPos = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if animated then
            TweenService:Create(track, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = targetColor }):Play()
            TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = targetPos }):Play()
        else
            track.BackgroundColor3 = targetColor
            knob.Position = targetPos
        end
    end

    function handle:Set(value, silent)
        state = value == true
        render(true)
        if not silent then
            callback(state)
        end
    end

    function handle:Get()
        return state
    end

    self:_track(button.MouseButton1Click:Connect(function()
        handle:Set(not state)
    end))

    render(false)
    return handle
end

function Library:_createButton(parent, options)
    local title = options.Title or "Button"
    local callback = options.Callback or function() end
    local color = options.Color or Color3.fromRGB(42, 91, 155)

    local button = Instance.new("TextButton")
    button.Name = title .. "Button"
    button.AutoButtonColor = true
    button.BackgroundColor3 = color
    button.Size = UDim2.new(1, 0, 0, 40)
    button.Font = Enum.Font.GothamSemibold
    button.Text = title
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 13
    button.Parent = parent
    makeCorner(button, 10)

    self:_track(button.MouseButton1Click:Connect(callback))
    return button
end

function Library:_createDivider(parent, text)
    local label = Instance.new("TextLabel")
    label.Name = tostring(text or "Divider")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 24)
    label.Font = Enum.Font.GothamBold
    label.Text = string.upper(text or "SECTION")
    label.TextColor3 = Color3.fromRGB(140, 151, 178)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

function Library:_createQuickDropdown()
    if not self.Config.QuickMenu.Enabled then
        return
    end

    local gui = self:_createBaseGui()

    local panel = Instance.new("Frame")
    panel.Name = "PlayerDropdown"
    panel.Visible = false
    panel.BackgroundColor3 = Color3.fromRGB(16, 19, 29)
    panel.BorderSizePixel = 0
    panel.Size = UDim2.fromOffset(self.Config.QuickMenu.Width, self.Config.QuickMenu.Height)
    panel.Position = UDim2.fromOffset(24, 92)
    panel.Parent = gui
    makeCorner(panel, 14)
    makeStroke(panel, Color3.fromRGB(96, 112, 150), 0.28, 1)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 29, 44)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 22)),
    })
    gradient.Rotation = 90
    gradient.Parent = panel

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 58)
    header.Parent = panel

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.BackgroundColor3 = Color3.fromRGB(33, 40, 59)
    avatar.Position = UDim2.fromOffset(12, 10)
    avatar.Size = UDim2.fromOffset(38, 38)
    avatar.Image = ""
    avatar.Parent = header
    makeCorner(avatar, 50)
    makeStroke(avatar, Color3.fromRGB(90, 167, 255), 0.25, 1)

    task.spawn(function()
        local ok, thumbnail = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        if ok and thumbnail then
            avatar.Image = thumbnail
        end
    end)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(60, 9)
    title.Size = UDim2.new(1, -100, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.Text = LocalPlayer.DisplayName or LocalPlayer.Name
    title.TextColor3 = Color3.fromRGB(245, 247, 255)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local sub = Instance.new("TextLabel")
    sub.Name = "Subtitle"
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.fromOffset(60, 30)
    sub.Size = UDim2.new(1, -100, 0, 18)
    sub.Font = Enum.Font.Gotham
    sub.Text = "Player Quick Tools"
    sub.TextColor3 = Color3.fromRGB(147, 158, 187)
    sub.TextSize = 12
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = header

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -12, 0, 13)
    close.Size = UDim2.fromOffset(30, 30)
    close.BackgroundColor3 = Color3.fromRGB(34, 40, 58)
    close.AutoButtonColor = true
    close.Font = Enum.Font.GothamBold
    close.Text = "×"
    close.TextColor3 = Color3.fromRGB(235, 239, 255)
    close.TextSize = 18
    close.Parent = header
    makeCorner(close, 8)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Position = UDim2.fromOffset(10, 60)
    scroll.Size = UDim2.new(1, -20, 1, -70)
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(88, 166, 255)
    scroll.Parent = panel

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = scroll
    makePadding(scroll, 2, 2, 8, 8)

    self:_createDivider(scroll, "Movement")
    self.SliderHandles.WalkSpeed = self:_createSlider(scroll, {
        Title = "WalkSpeed",
        Min = self.Config.PlayerTools.WalkSpeed.Min,
        Max = self.Config.PlayerTools.WalkSpeed.Max,
        Default = self.State.WalkSpeed,
        Step = self.Config.PlayerTools.WalkSpeed.Step,
        Callback = function(value)
            self:SetWalkSpeed(value)
        end,
    })

    self.SliderHandles.JumpPower = self:_createSlider(scroll, {
        Title = "Jump Power",
        Min = self.Config.PlayerTools.JumpPower.Min,
        Max = self.Config.PlayerTools.JumpPower.Max,
        Default = self.State.JumpPower,
        Step = self.Config.PlayerTools.JumpPower.Step,
        Callback = function(value)
            self:SetJumpPower(value)
        end,
    })

    self.SliderHandles.HipHeight = self:_createSlider(scroll, {
        Title = "Hip Height",
        Min = self.Config.PlayerTools.HipHeight.Min,
        Max = self.Config.PlayerTools.HipHeight.Max,
        Default = self.State.HipHeight,
        Step = self.Config.PlayerTools.HipHeight.Step,
        Callback = function(value)
            self:SetHipHeight(value)
        end,
    })

    self.ToggleHandles.NoClip = self:_createToggle(scroll, {
        Title = "No Clip",
        Default = false,
        Callback = function(state)
            self:SetNoClip(state)
        end,
    })

    self.ToggleHandles.InfiniteJump = self:_createToggle(scroll, {
        Title = "Infinite Jump",
        Default = false,
        Callback = function(state)
            self:SetInfiniteJump(state)
        end,
    })

    self:_createDivider(scroll, "Visual")
    self.ToggleHandles.FullBright = self:_createToggle(scroll, {
        Title = "Full Bright",
        Default = false,
        Callback = function(state)
            self:SetFullBright(state)
        end,
    })

    self.SliderHandles.FieldOfView = self:_createSlider(scroll, {
        Title = "Field Of View",
        Min = self.Config.PlayerTools.FieldOfView.Min,
        Max = self.Config.PlayerTools.FieldOfView.Max,
        Default = self.State.FieldOfView,
        Step = self.Config.PlayerTools.FieldOfView.Step,
        Callback = function(value)
            self:SetFOV(value)
        end,
    })

    self.SliderHandles.Gravity = self:_createSlider(scroll, {
        Title = "Gravity",
        Min = self.Config.PlayerTools.Gravity.Min,
        Max = self.Config.PlayerTools.Gravity.Max,
        Default = self.State.Gravity,
        Step = self.Config.PlayerTools.Gravity.Step,
        Callback = function(value)
            self:SetGravity(value)
        end,
    })

    self:_createDivider(scroll, "Actions")
    self:_createButton(scroll, {
        Title = "Reset Player Tools",
        Color = Color3.fromRGB(52, 116, 192),
        Callback = function()
            self:ResetPlayerTools()
        end,
    })

    self:_createButton(scroll, {
        Title = "Reset Character",
        Color = Color3.fromRGB(179, 72, 72),
        Callback = function()
            self:ResetCharacter()
        end,
    })

    if self.Config.Website.Homepage and self.Config.Website.Homepage ~= "" then
        self:_createDivider(scroll, "Website")
        self:_createButton(scroll, {
            Title = "Copy Website URL",
            Color = Color3.fromRGB(63, 86, 145),
            Callback = function()
                if typeof(setclipboard) == "function" then
                    setclipboard(self.Config.Website.Homepage)
                    self:Notify("Website", "URL website sudah dicopy ke clipboard.", "link", 3)
                else
                    self:Notify("Website", self.Config.Website.Homepage, "link", 5)
                end
            end,
        })

        self:_createButton(scroll, {
            Title = "Reload Website Config",
            Color = Color3.fromRGB(63, 86, 145),
            Callback = function()
                self:SyncWebsiteConfig(true)
            end,
        })
    end

    local owner = self
    local dropdown = {}
    dropdown.Panel = panel

    function dropdown:OpenAtMouse()
        local mouse = UserInputService:GetMouseLocation()
        local camera = Workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local width = panel.AbsoluteSize.X > 0 and panel.AbsoluteSize.X or self.Panel.Size.X.Offset
        local height = panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y or self.Panel.Size.Y.Offset
        local offset = owner.Config.QuickMenu.OffsetFromMouse or Vector2.new(-260, 8)

        local x = mouse.X + offset.X
        local y = mouse.Y + offset.Y
        x = math.clamp(x, 8, math.max(8, viewport.X - width - 8))
        y = math.clamp(y, 42, math.max(42, viewport.Y - height - 8))

        panel.Position = UDim2.fromOffset(x, y)
        panel.Visible = true
        panel.BackgroundTransparency = 1
        TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
    end

    function dropdown:ToggleAtMouse()
        if panel.Visible then
            panel.Visible = false
        else
            self:OpenAtMouse()
        end
    end

    function dropdown:Close()
        panel.Visible = false
    end

    self:_track(close.MouseButton1Click:Connect(function()
        dropdown:Close()
    end))

    if self.Config.QuickMenu.CloseWhenClickOutside then
        self:_track(UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if not panel.Visible then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end

            local pos = input.Position
            local absPos = panel.AbsolutePosition
            local absSize = panel.AbsoluteSize
            local inside = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y
            if not inside then
                panel.Visible = false
            end
        end))
    end

    self.Dropdown = dropdown
    return dropdown
end

function Library:_createFallbackFloatingButton()
    if not self.Gui then
        self:_createBaseGui()
    end

    local button = Instance.new("TextButton")
    button.Name = "FallbackPlayerButton"
    button.AnchorPoint = Vector2.new(1, 0)
    button.Position = UDim2.new(1, -18, 0, 72)
    button.Size = UDim2.fromOffset(42, 42)
    button.BackgroundColor3 = Color3.fromRGB(23, 29, 45)
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.Text = "👤"
    button.TextSize = 18
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = self.Gui
    makeCorner(button, 12)
    makeStroke(button, Color3.fromRGB(96, 148, 220), 0.25, 1)

    self:_track(button.MouseButton1Click:Connect(function()
        if self.Dropdown then
            self.Dropdown:ToggleAtMouse()
        end
    end))
end

function Library:_createWindow()
    local WindUI = self:_loadWindUI()

    pcall(function()
        WindUI:SetNotificationLower(true)
    end)

    local windowConfig = {
        Title = self.Config.Window.Title,
        Icon = self.Config.Window.Icon,
        Author = self.Config.Window.Author,
        Folder = self.Config.Window.Folder,
        Size = self.Config.Window.Size,
        Theme = self.Config.Window.Theme,
        ToggleKey = self.Config.Window.ToggleKey,
        Acrylic = self.Config.Window.Acrylic,
        Resizable = self.Config.Window.Resizable,
        TopBarButtonIconSize = 18,
    }

    self.Window = WindUI:CreateWindow(windowConfig)
    return self.Window
end

function Library:_createWindUITabs()
    if not self.Config.PlayerTools.AddWindUITab then
        return
    end
    if not self.Window then
        return
    end

    local homeTab = self.Window:Tab({
        Title = "Home",
        Icon = "house",
    })

    homeTab:Button({
        Title = "Buka Player Quick Menu",
        Icon = "user-round",
        Callback = function()
            if self.Dropdown then
                self.Dropdown:ToggleAtMouse()
            end
        end,
    })

    homeTab:Button({
        Title = "Sync Config Dari Website",
        Icon = "refresh-cw",
        Callback = function()
            self:SyncWebsiteConfig(true)
        end,
    })

    local playerTab = self.Window:Tab({
        Title = "Player",
        Icon = "user-round",
    })

    playerTab:Slider({
        Title = "WalkSpeed",
        Value = {
            Min = self.Config.PlayerTools.WalkSpeed.Min,
            Max = self.Config.PlayerTools.WalkSpeed.Max,
            Default = self.State.WalkSpeed,
        },
        Step = self.Config.PlayerTools.WalkSpeed.Step,
        Callback = function(value)
            self:SetWalkSpeed(value)
            if self.SliderHandles.WalkSpeed then self.SliderHandles.WalkSpeed:Set(value, true) end
        end,
    })

    playerTab:Slider({
        Title = "Jump Power",
        Value = {
            Min = self.Config.PlayerTools.JumpPower.Min,
            Max = self.Config.PlayerTools.JumpPower.Max,
            Default = self.State.JumpPower,
        },
        Step = self.Config.PlayerTools.JumpPower.Step,
        Callback = function(value)
            self:SetJumpPower(value)
            if self.SliderHandles.JumpPower then self.SliderHandles.JumpPower:Set(value, true) end
        end,
    })

    playerTab:Toggle({
        Title = "No Clip",
        Icon = "box",
        Value = false,
        Callback = function(state)
            self:SetNoClip(state)
            if self.ToggleHandles.NoClip then self.ToggleHandles.NoClip:Set(state, true) end
        end,
    })

    playerTab:Toggle({
        Title = "Infinite Jump",
        Icon = "chevrons-up",
        Value = false,
        Callback = function(state)
            self:SetInfiniteJump(state)
            if self.ToggleHandles.InfiniteJump then self.ToggleHandles.InfiniteJump:Set(state, true) end
        end,
    })

    playerTab:Toggle({
        Title = "Full Bright",
        Icon = "sun",
        Value = false,
        Callback = function(state)
            self:SetFullBright(state)
            if self.ToggleHandles.FullBright then self.ToggleHandles.FullBright:Set(state, true) end
        end,
    })

    playerTab:Slider({
        Title = "Field Of View",
        Value = {
            Min = self.Config.PlayerTools.FieldOfView.Min,
            Max = self.Config.PlayerTools.FieldOfView.Max,
            Default = self.State.FieldOfView,
        },
        Step = self.Config.PlayerTools.FieldOfView.Step,
        Callback = function(value)
            self:SetFOV(value)
            if self.SliderHandles.FieldOfView then self.SliderHandles.FieldOfView:Set(value, true) end
        end,
    })

    playerTab:Slider({
        Title = "Gravity",
        Value = {
            Min = self.Config.PlayerTools.Gravity.Min,
            Max = self.Config.PlayerTools.Gravity.Max,
            Default = self.State.Gravity,
        },
        Step = self.Config.PlayerTools.Gravity.Step,
        Callback = function(value)
            self:SetGravity(value)
            if self.SliderHandles.Gravity then self.SliderHandles.Gravity:Set(value, true) end
        end,
    })

    playerTab:Button({
        Title = "Reset Player Tools",
        Icon = "rotate-ccw",
        Callback = function()
            self:ResetPlayerTools()
        end,
    })
end

function Library:_installTopbarButton()
    if not self.Window or not self.Dropdown then
        return
    end

    local ok = pcall(function()
        self.Window:CreateTopbarButton(
            "PlayerQuickMenu",
            self.Config.QuickMenu.TopbarIcon,
            function()
                self.Dropdown:ToggleAtMouse()
            end,
            self.Config.QuickMenu.TopbarOrder,
            true,
            nil,
            18
        )
    end)

    if not ok then
        self:_createFallbackFloatingButton()
        self:Notify("Topbar", "CreateTopbarButton gagal, memakai tombol player floating.", "triangle-alert", 4)
    end
end

function Library:_applyWebsitePayload(payload, notify)
    if type(payload) ~= "table" then
        return
    end

    if self.Window then
        if type(payload.Title) == "string" and payload.Title ~= "" then
            pcall(function()
                self.Window:SetTitle(payload.Title)
            end)
        end
        if type(payload.Author) == "string" then
            pcall(function()
                self.Window:SetAuthor(payload.Author)
            end)
        end
        if type(payload.Icon) == "string" and payload.Icon ~= "" then
            pcall(function()
                self.Window:SetIcon(payload.Icon)
            end)
        end
        if type(payload.Theme) == "string" and payload.Theme ~= "" then
            pcall(function()
                self.Window:SetTheme(payload.Theme)
            end)
        end
    end

    if type(payload.Notification) == "table" then
        self:Notify(
            payload.Notification.Title or "Website",
            payload.Notification.Content or "Config website berhasil dimuat.",
            payload.Notification.Icon or "globe",
            payload.Notification.Duration or 4
        )
    elseif notify then
        self:Notify("Website", "Config website berhasil dimuat.", "globe", 3)
    end
end

function Library:SyncWebsiteConfig(notify)
    if not self.Config.Website.Enabled then
        if notify then
            self:Notify("Website", "Website.Enabled masih false.", "info", 3)
        end
        return nil
    end

    local configUrl = self.Config.Website.ConfigUrl
    if not configUrl or configUrl == "" then
        if notify then
            self:Notify("Website", "ConfigUrl belum diisi.", "info", 3)
        end
        return nil
    end

    local body = self:_httpGet(configUrl)
    if not body then
        if notify then
            self:Notify("Website", "Gagal mengambil config dari website.", "wifi-off", 4)
        end
        return nil
    end

    local ok, payload = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not ok then
        if notify then
            self:Notify("Website", "Config JSON tidak valid.", "file-warning", 4)
        end
        return nil
    end

    self:_applyWebsitePayload(payload, notify)
    return payload
end

function Library:PingWebsite()
    if not self.Config.Website.Enabled then
        return
    end

    local pingUrl = self.Config.Website.PingUrl
    if not pingUrl or pingUrl == "" then
        return
    end

    pingUrl = pingUrl:gsub("{userid}", tostring(LocalPlayer.UserId))
    pingUrl = pingUrl:gsub("{username}", HttpService:UrlEncode(LocalPlayer.Name))
    pingUrl = pingUrl:gsub("{displayname}", HttpService:UrlEncode(LocalPlayer.DisplayName or LocalPlayer.Name))

    task.spawn(function()
        self:_httpGet(pingUrl)
    end)
end

function Library:LoadRemoteWebsiteScript()
    if not self.Config.Website.Enabled then
        return false, "Website.Enabled false"
    end
    if not self.Config.Website.AllowRemoteScript then
        return false, "AllowRemoteScript false"
    end

    local url = self.Config.Website.RemoteScriptUrl
    if not url or url == "" then
        return false, "RemoteScriptUrl kosong"
    end

    local source = self:_httpGet(url)
    if not source then
        return false, "Gagal mengambil remote script"
    end

    if typeof(loadstring) ~= "function" then
        return false, "loadstring tidak tersedia di environment ini"
    end

    local fn, compileErr = loadstring(source)
    if not fn then
        return false, "Compile error: " .. tostring(compileErr)
    end

    task.spawn(function()
        local ok, runtimeErr = pcall(fn)
        if not ok then
            warn("[WindUI PlayerTools] Remote script error:", runtimeErr)
        end
    end)

    return true
end

function Library:_setupLifecycle()
    self:_track(LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.65)
        self:ApplyMovementSettings()
    end))

    self:_track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.wait(0.1)
        self:ApplyMovementSettings()
    end))
end

function Library:Init()
    local allowed, reason = self:_isAllowed()
    if not allowed then
        warn("[WindUI PlayerTools] Akses ditolak: " .. tostring(reason))
        return self
    end

    self:_captureOriginalValues()
    self:_loadWindUI()
    self:_createWindow()
    self:_createQuickDropdown()
    self:_installTopbarButton()
    self:_createWindUITabs()
    self:_setupLifecycle()
    self:ApplyMovementSettings()

    task.spawn(function()
        self:SyncWebsiteConfig(false)
        self:PingWebsite()

        if self.Config.Website.AllowRemoteScript then
            local ok, err = self:LoadRemoteWebsiteScript()
            if not ok and err ~= "AllowRemoteScript false" then
                warn("[WindUI PlayerTools]", err)
            end
        end
    end)

    self:Notify("WindUI Player Tools", "UI berhasil dimuat. Klik icon player di topbar.", "check", 4)
    return self
end

function Library:Destroy()
    self:SetNoClip(false)
    self:SetInfiniteJump(false)
    self:SetFullBright(false)

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(self.Connections)

    if self.NoClipConnection then self.NoClipConnection:Disconnect() end
    if self.InfiniteJumpConnection then self.InfiniteJumpConnection:Disconnect() end
    if self.FullBrightConnection then self.FullBrightConnection:Disconnect() end

    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end

    if self.Window then
        pcall(function()
            self.Window:Destroy()
        end)
    end
end

if AUTORUN then
    task.defer(function()
        getgenv().WindUIPlayerTools = Library.new({}):Init()
    end)
end

return Library
