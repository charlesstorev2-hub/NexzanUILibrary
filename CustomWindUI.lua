-- Custom WindUI Library - Modifikasi oleh Anda
-- Menghubungkan ke website: https://website-anda.com (ubah sesuai URL Anda)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local YourWebsite = "https://website-anda.com"
local FontDefault = "rbxassetid://12187474592"

local CustomUI = {}
CustomUI.__index = CustomUI

function CustomUI:Init()
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "CustomWindUI"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.DisplayOrder = 999
    self.ScreenGui.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    -- Background bergerak garis hitam
    self.BgMoving = Instance.new("Frame")
    self.BgMoving.Name = "MovingBg"
    self.BgMoving.Size = UDim2.new(1, 0, 1, 0)
    self.BgMoving.Position = UDim2.new(0, 0, 0, 0)
    self.BgMoving.BackgroundColor3 = Color3.new(1, 1, 1)
    self.BgMoving.BorderSizePixel = 0
    self.BgMoving.ZIndex = 0
    self.BgMoving.Parent = self.ScreenGui

    -- Garis hitam bergerak
    self.LineBlack = Instance.new("Frame")
    self.LineBlack.Name = "MovingLine"
    self.LineBlack.Size = UDim2.new(0, 4, 1, 0)
    self.LineBlack.Position = UDim2.new(-0.05, 0, 0, 0)
    self.LineBlack.BackgroundColor3 = Color3.new(0, 0, 0)
    self.LineBlack.BorderSizePixel = 0
    self.LineBlack.ZIndex = 1
    self.LineBlack.Parent = self.BgMoving

    -- Animasi garis
    spawn(function()
        while true do
            for i = 0, 1, 0.005 do
                self.LineBlack.Position = UDim2.new(i - 0.05, 0, 0, 0)
                wait(0.01)
            end
        end
    end)
end

function CustomUI:CreateMainWindow()
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainWindow"
    self.MainFrame.Size = UDim2.new(0, 520, 0, 340)
    self.MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.ZIndex = 10
    self.MainFrame.Parent = self.ScreenGui

    -- Header bar
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.Position = UDim2.new(0, 0, 0, 0)
    Header.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Header.BorderSizePixel = 0
    Header.ZIndex = 11
    Header.Parent = self.MainFrame

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Text = "Custom WindUI Library"
    Title.Size = UDim2.new(0.6, 0, 0, 40)
    Title.Position = UDim2.new(0.02, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 12
    Title.Parent = Header

    -- Link to website button
    local WebBtn = Instance.new("TextButton")
    WebBtn.Text = "Website Saya"
    WebBtn.Size = UDim2.new(0.18, 0, 0, 26)
    WebBtn.Position = UDim2.new(0.78, 0, 0.07, 0)
    WebBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    WebBtn.Font = Enum.Font.Gotham
    WebBtn.TextColor3 = Color3.new(1, 1, 1)
    WebBtn.TextSize = 12
    WebBtn.ZIndex = 12
    WebBtn.Parent = Header
    WebBtn.MouseButton1Click:Connect(function()
        setclipboard(YourWebsite)
        print("Link website disalin: " .. YourWebsite)
    end)

    -- Minimize
    local MinBtn = Instance.new("TextButton")
    MinBtn.Text = "-"
    MinBtn.Size = UDim2.new(0.06, 0, 0, 28)
    MinBtn.Position = UDim2.new(0.93, -8, 0.06, 0)
    MinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextColor3 = Color3.new(1, 1, 1)
    MinBtn.TextSize = 16
    MinBtn.ZIndex = 12
    MinBtn.Parent = Header
    MinBtn.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = false
        if self.RestoreBtn then
            self.RestoreBtn.Visible = true
        end
    end)

    -- Icon Player + Dropdown
    local PlayerIconBtn = Instance.new("ImageButton")
    PlayerIconBtn.Name = "PlayerIconBtn"
    PlayerIconBtn.Size = UDim2.new(0, 28, 0, 28)
    PlayerIconBtn.Position = UDim2.new(0.86, -28, 0.06, 0)
    PlayerIconBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    PlayerIconBtn.Image = "rbxassetid://6022668886" -- default user icon
    PlayerIconBtn.ZIndex = 12
    PlayerIconBtn.Parent = Header

    -- Dropdown Player (scrollable kecil)
    local PlayerDrop = Instance.new("Frame")
    PlayerDrop.Name = "PlayerDrop"
    PlayerDrop.Size = UDim2.new(0, 200, 0, 220)
    PlayerDrop.Position = UDim2.new(0, 340, 0.05, 40)
    PlayerDrop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    PlayerDrop.BorderSizePixel = 0
    PlayerDrop.Visible = false
    PlayerDrop.ZIndex = 15
    PlayerDrop.ClipsDescendants = true
    PlayerDrop.Parent = self.MainFrame

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ZIndex = 16
    ScrollFrame.Parent = PlayerDrop

    local function addPlayerFeature(name, desc, callback)
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(0.95, 0, 0, 35)
        item.Position = UDim2.new(0.025, 0, 0, 0)
        item.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        item.Font = Enum.Font.Gotham
        item.Text = name .. "\n" .. desc
        item.TextColor3 = Color3.new(1, 1, 1)
        item.TextSize = 11
        item.TextWrapped = true
        item.ZIndex = 16
        item.Parent = ScrollFrame
        item.MouseButton1Click:Connect(callback)
    end

    -- Slider Walkspeed
    addPlayerFeature("WalkSpeed", "Ubah kecepatan jalan", function()
        local plr = Players.LocalPlayer
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 60 end
    end)

    -- Slider Jump Power
    addPlayerFeature("Jump Power", "Tingkatkan lompatan", function()
        local plr = Players.LocalPlayer
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 120 end
    end)

    -- No Clip
    addPlayerFeature("No Clip", "Aktifkan/Nonaktifkan", function()
        local plr = Players.LocalPlayer
        local char = plr.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = not p.CanCollide end
            end
        end
    end)

    -- Full Bright
    addPlayerFeature("Full Bright", "Terang maksimal", function()
        local Lighting = game:GetService("Lighting")
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end)

    PlayerIconBtn.MouseButton1Click:Connect(function()
        PlayerDrop.Visible = not PlayerDrop.Visible
    end)

    -- Icon Gear / Setting + Dropdown Setting
    local GearBtn = Instance.new("ImageButton")
    GearBtn.Name = "GearBtn"
    GearBtn.Size = UDim2.new(0, 28, 0, 28)
    GearBtn.Position = UDim2.new(0.82, -30, 0.06, 0)
    GearBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    GearBtn.Image = "rbxassetid://6031091006" -- gear icon
    GearBtn.ZIndex = 12
    GearBtn.Parent = Header

    local SettingDrop = Instance.new("Frame")
    SettingDrop.Name = "SettingDrop"
    SettingDrop.Size = UDim2.new(0, 200, 0, 160)
    SettingDrop.Position = UDim2.new(0, 290, 0.05, 40)
    SettingDrop.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SettingDrop.BorderSizePixel = 0
    SettingDrop.Visible = false
    SettingDrop.ZIndex = 15
    SettingDrop.Parent = self.MainFrame

    -- Background Raw URL
    local bgLabel = Instance.new("TextLabel")
    bgLabel.Text = "Background URL Raw"
    bgLabel.Size = UDim2.new(0.9, 0, 0, 20)
    bgLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
    bgLabel.BackgroundTransparency = 1
    bgLabel.Font = Enum.Font.Gotham
    bgLabel.TextColor3 = Color3.new(1, 1, 1)
    bgLabel.TextSize = 12
    bgLabel.ZIndex = 16
    bgLabel.Parent = SettingDrop

    local bgInput = Instance.new("TextBox")
    bgInput.PlaceholderText = "Masukkan URL gambar raw"
    bgInput.Size = UDim2.new(0.9, 0, 0, 26)
    bgInput.Position = UDim2.new(0.05, 0, 0.26, 0)
    bgInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bgInput.Font = Enum.Font.Gotham
    bgInput.TextColor3 = Color3.new(1, 1, 1)
    bgInput.TextSize = 11
    bgInput.ZIndex = 16
    bgInput.Parent = SettingDrop
    bgInput.FocusLost:Connect(function()
        if bgInput.Text ~= "" then
            self.BgMoving.BackgroundTransparency = 1
            -- Untuk demo, kita set warna sebagai placeholder karena Roblox tidak support URL background langsung di UI
            -- Ganti dengan image jika ingin menggunakan ImageLabel
            local img = Instance.new("ImageLabel")
            img.Image = bgInput.Text
            img.Size = UDim2.new(1, 0, 1, 0)
            img.Position = UDim2.new(0, 0, 0, 0)
            img.ZIndex = 0
            img.Parent = self.BgMoving
        end
    end)

    -- Font Teks
    local fontLabel = Instance.new("TextLabel")
    fontLabel.Text = "Ganti Font (ID Asset)"
    fontLabel.Size = UDim2.new(0.9, 0, 0, 20)
    fontLabel.Position = UDim2.new(0.05, 0, 0.58, 0)
    fontLabel.BackgroundTransparency = 1
    fontLabel.Font = Enum.Font.Gotham
    fontLabel.TextColor3 = Color3.new(1, 1, 1)
    fontLabel.TextSize = 12
    fontLabel.ZIndex = 16
    fontLabel.Parent = SettingDrop

    local fontInput = Instance.new("TextBox")
    fontInput.PlaceholderText = "rbxassetid://..."
    fontInput.Size = UDim2.new(0.9, 0, 0, 26)
    fontInput.Position = UDim2.new(0.05, 0, 0.79, 0)
    fontInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    fontInput.Font = Enum.Font.Gotham
    fontInput.TextColor3 = Color3.new(1, 1, 1)
    fontInput.TextSize = 11
    fontInput.ZIndex = 16
    fontInput.Parent = SettingDrop
    fontInput.FocusLost:Connect(function()
        if fontInput.Text ~= "" then
            Title.Font = Enum.Font.SourceSans -- default
            Title.Font = Enum.Font.Gotham -- tetap default karena Font enum butuh loader khusus. Sebagai alternatif, ubah ukuran.
            -- Note: Font custom menggunakan SetFont di WindUI asli. Ini demo sederhana.
        end
    end)

    -- Ukuran UI
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Text = "Ukuran UI: 520x340 (Default)"
    sizeLabel.Size = UDim2.new(0.9, 0, 0, 20)
    sizeLabel.Position = UDim2.new(0.05, 0, 0.105, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextColor3 = Color3.new(1, 1, 1)
    sizeLabel.TextSize = 12
    sizeLabel.ZIndex = 16
    sizeLabel.Parent = SettingDrop

    GearBtn.MouseButton1Click:Connect(function()
        SettingDrop.Visible = not SettingDrop.Visible
    end)
end

function CustomUI:Show()
    self:Init()
    self:CreateMainWindow()
end

return CustomUI
