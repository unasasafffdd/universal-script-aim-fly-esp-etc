-- ═══════════════════════════════════════════════════════════════
--   BogdanWare  ·  Sakura Edition  ·  Shader + HitSound + AntiFling + Wallbang
--   RightControl — меню   |   X — выгрузить скрипт
-- ═══════════════════════════════════════════════════════════════

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Tween       = game:GetService("TweenService")
local Lighting    = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")

local LP        = Players.LocalPlayer
local Camera    = workspace.CurrentCamera
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ==================== ВЫГРУЗКА ====================
local connections = {}
local unloaded = false
local cleanupFns = {}

local function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(connections, c)
    return c
end
local function onCleanup(fn) table.insert(cleanupFns, fn) end

-- ==================== КОНФИГ ====================
local Cfg = {
    ESP = {
        Enabled = false, FillColor = Color3.fromRGB(255, 158, 196),
        OutlineColor = Color3.fromRGB(255, 232, 242),
        FillTransparency = 0.55, OutlineTransparency = 0,
        ShowInfo = false, TeamCheck = false, MaxDistance = 1000,
        ShowHealth = true, ShowName = true, ShowDistance = true,
    },
    SilentAim = {
        Enabled = false, FOV = 150, TargetPart = "Head",
        TeamCheck = true, VisibleOnly = false, HitChance = 100,
        Prediction = 0.165, ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 100, 150),
        IgnoreDowned = true, RandomizeBone = false, Wallbang = false,
    },
    Aimbot = {
        Enabled = false, FOV = 220, Smoothness = 0.2,
        ShowFOV = true, FOVColor = Color3.fromRGB(216, 167, 232),
        TargetPart = "Head", VisibleOnly = false,
        HoldKey = true, Key = Enum.UserInputType.MouseButton2,
        Prediction = 0, MaxDistance = 1000,
    },
    Trigger = {
        Enabled = false, Delay = 0.05, VisibleOnly = true,
        TeamCheck = true, MaxDistance = 500,
    },
    Hitbox = { Enabled = false, Scale = 2, Transparency = 0.65, HeadOnly = false },
    Fly = { Enabled = false, Speed = 60, VerticalSpeed = 1 },
    Noclip = { Enabled = false, Radius = 5 },
    Spinner = {
        Enabled = false, Speed = 360, Axis = "Y", Mode = "Character",
        Direction = "CW", Bobbing = false, BobHeight = 2, BobSpeed = 8,
    },
    Fling = {
        Enabled = false, Method = "Impulse", Target = "All", TargetName = "",
        Range = 15, Power = 1500, AutoRepeat = false, Interval = 0.5,
        TeamCheck = true, IgnoreDowned = true,
        Key = Enum.KeyCode.F, HoldToFling = false,
    },
    SpeedHack = {
        Enabled = false, Method = "WalkSpeed", Speed = 60, JumpPower = 50,
        SprintOnly = false, SprintKey = Enum.KeyCode.LeftShift, AutoJump = false,
    },
    GodMode = { Enabled = false, MaxHealth = 1000000, AutoRespawn = false },
    BunnyHop = {
        Enabled = false, Power = 50,
        AutoStrafe = false, StrafePower = 30,
        OnlyOnGround = true, Key = Enum.KeyCode.Space, HoldKey = false,
    },
    AntiFling = {
        Enabled = false,
        Method = "Collide",       -- "Collide" | "Freeze" | "Reset"
        CheckInterval = 0.1,
        MaxVelocity = 200,
        AutoReset = false,
    },
    HitSound = {
        Enabled = false,
        SoundId = "rbxassetid://7147454322",  -- Osu hitmarker
        Volume = 0.5,
        HeadshotSoundId = "rbxassetid://7147454322",
        HeadshotVolume = 0.7,
    },
    Wallbang = {
        Enabled = false,
        MaxThickness = 5,          -- максимальная толщина стены в studs
        MaxDistance = 500,         -- макс. дистанция проверки
        TeamCheck = true,
        VisibleOnly = false,       -- если true — только через тонкие стены
    },
    Shader = {
        Enabled = false,
        Preset = "Cinematic",      -- "Cinematic" | "Neon" | "Pastel" | "Dark" | "Custom"
        BloomIntensity = 0.8,
        BloomSize = 24,
        BloomThreshold = 0.9,
        ColorBrightness = 0,
        ColorContrast = 0.15,
        ColorSaturation = 0.2,
        ColorTint = Color3.fromRGB(255, 220, 240),
        SunRaysIntensity = 0.05,
        SunRaysSpread = 1,
        DOFFocusDistance = 30,
        DOFInFocusRadius = 20,
        DOFBlurSize = 10,
        AtmosphereDensity = 0.3,
        AtmosphereOffset = 0.25,
        AtmosphereColor = Color3.fromRGB(199, 170, 220),
        FogEnd = 1000,
        FogStart = 0,
        FogColor = Color3.fromRGB(199, 170, 220),
        ClockTime = 14,
        Brightness = 2,
        Ambient = Color3.fromRGB(150, 150, 170),
        OutdoorAmbient = Color3.fromRGB(170, 170, 190),
    },
    Visuals = {
        Crosshair = true, CrosshairColor = Color3.fromRGB(255, 158, 196),
        CrosshairStyle = "Cross", CrosshairSize = 16, CrosshairThickness = 2,
    },
}

-- ==================== СОХРАНЕНИЕ ====================
local SAVE_FILE = "bogdanware_config.json"
local function packColor(c) return { __t = "Color3", r = c.R, g = c.G, b = c.B } end
local function unpackColor(t) return Color3.new(t.r, t.g, t.b) end

local function saveConfig()
    if not writefile then return end
    local data = {}
    for section, vals in pairs(Cfg) do
        data[section] = {}
        for k, v in pairs(vals) do
            local tv = typeof(v)
            if tv == "Color3" then data[section][k] = packColor(v)
            elseif tv == "boolean" or tv == "number" or tv == "string" then
                data[section][k] = v
            end
        end
    end
    local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then pcall(writefile, SAVE_FILE, enc) end
end

local function loadConfig()
    if not (isfile and readfile) then return end
    local ok0, exists = pcall(isfile, SAVE_FILE)
    if not ok0 or not exists then return end
    local ok, content = pcall(readfile, SAVE_FILE)
    if not ok then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or type(data) ~= "table" then return end
    for section, vals in pairs(data) do
        if Cfg[section] and type(vals) == "table" then
            for k, v in pairs(vals) do
                if type(v) == "table" and v.__t == "Color3" then
                    Cfg[section][k] = unpackColor(v)
                elseif type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                    if Cfg[section][k] ~= nil then Cfg[section][k] = v end
                end
            end
        end
    end
end

local saveQueued = false
local function queueSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(1, function()
        saveQueued = false
        pcall(saveConfig)
    end)
end
pcall(loadConfig)

-- ==================== ХЕЛПЕРЫ ====================
local function mk(class, props, parent)
    local i = Instance.new(class)
    if props then for k, v in pairs(props) do i[k] = v end end
    if parent then i.Parent = parent end
    return i
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end

local function stroke(p, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(120, 80, 110)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

local function grad(p, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2); g.Rotation = rot or 0; g.Parent = p
    return g
end

local SOFT   = TweenInfo.new(0.35, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.5,  Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function addRipple(btn)
    connect(btn.MouseButton1Click, function()
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        r.BackgroundTransparency = 0.55; r.BorderSizePixel = 0
        r.Size = UDim2.new(0, 0, 0, 0)
        r.Position = UDim2.new(0.5, 0, 0.5, 0)
        r.ZIndex = (btn.ZIndex or 1) + 5; r.Parent = btn
        corner(r, 999)
        Tween:Create(r, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, btn.AbsoluteSize.X * 2.4, 0, btn.AbsoluteSize.Y * 2.4),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(1.05, function() pcall(function() r:Destroy() end) end)
    end)
end

local function colorEq(a, b)
    return math.abs(a.R-b.R) < 0.05 and math.abs(a.G-b.G) < 0.05 and math.abs(a.B-b.B) < 0.05
end

-- ═════════ ПАЛИТРА ═════════
local ACCENT_1 = Color3.fromRGB(255, 158, 196)
local ACCENT_2 = Color3.fromRGB(216, 167, 232)
local ACCENT_3 = Color3.fromRGB(255, 179, 198)
local BG_DARK  = Color3.fromRGB(42, 26, 40)
local BG_CARD  = Color3.fromRGB(58, 34, 56)
local BG_HOVER = Color3.fromRGB(78, 46, 74)
local TEXT_MAIN = Color3.fromRGB(255, 232, 242)
local TEXT_DIM  = Color3.fromRGB(214, 168, 196)

-- ==================== GUI ====================
local gui     = mk("ScreenGui", { Name = "BogdanWare", ResetOnSpawn = false, IgnoreGuiInset = true }, PlayerGui)
local overlay = mk("ScreenGui", { Name = "BogdanOverlay", ResetOnSpawn = false, IgnoreGuiInset = true }, PlayerGui)
onCleanup(function() pcall(function() gui:Destroy() end); pcall(function() overlay:Destroy() end) end)

local WIN_W, WIN_H = 720, 560

local win = mk("Frame", {
    Name = "Main",
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    BackgroundColor3 = BG_DARK,
    BorderSizePixel = 0, Active = true, ClipsDescendants = false,
}, gui)
corner(win, 16)

-- ═════════ АНИМИРОВАННЫЙ GLOW ═════════
local glowLayers = {}

local GLOW_PALETTE = {
    Color3.fromRGB(255, 130, 190),
    Color3.fromRGB(245, 135, 215),
    Color3.fromRGB(230, 145, 230),
    Color3.fromRGB(210, 160, 235),
    Color3.fromRGB(185, 145, 250),
    Color3.fromRGB(165, 130, 245),
    Color3.fromRGB(195, 140, 240),
    Color3.fromRGB(225, 150, 245),
    Color3.fromRGB(255, 130, 190),
}

local function paletteAt(t)
    t = t % 1
    local n = #GLOW_PALETTE
    local scaled = t * (n - 1)
    local i = math.floor(scaled) + 1
    local frac = scaled - math.floor(scaled)
    local c1 = GLOW_PALETTE[i]
    local c2 = GLOW_PALETTE[math.min(i + 1, n)]
    return c1:Lerp(c2, frac)
end

local function buildGradientColors(phase, spread)
    local keys = {}
    local STEPS = 12
    for i = 0, STEPS do
        local t = i / STEPS
        local col = paletteAt(phase + t * spread)
        table.insert(keys, ColorSequenceKeypoint.new(t, col))
    end
    return ColorSequence.new(keys)
end

local function createGlowLayer(name, sizeOffset, posOffset, strokeThickness,
                               baseTransparency, zIndex, phaseOffset, spread)
    local f = mk("Frame", {
        Name = name,
        Size = UDim2.new(1, sizeOffset, 1, sizeOffset),
        Position = UDim2.new(0, posOffset, 0, posOffset),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = zIndex,
    }, win)
    corner(f, 16 + math.abs(posOffset))
    local s = stroke(f, ACCENT_1, strokeThickness, baseTransparency)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local g = Instance.new("UIGradient")
    g.Color = buildGradientColors(0, spread)
    g.Parent = s

    table.insert(glowLayers, {
        frame = f,
        stroke = s,
        grad = g,
        baseTransparency = baseTransparency,
        phaseOffset = phaseOffset,
        spread = spread,
        baseThickness = strokeThickness,
    })
    return f
end

createGlowLayer("GlowOuter", 30, -15, 12, 0.88, -4, 0.00, 0.55)
createGlowLayer("GlowMid",   18, -9,  8,  0.72, -3, 0.18, 0.70)
createGlowLayer("GlowInner", 8,  -4,  4,  0.5,  -2, 0.36, 0.85)
createGlowLayer("GlowEdge",  2,  -1,  2,  0.2,  -1, 0.52, 1.00)

task.spawn(function()
    local t = 0
    local colorAccum = 0
    local COLOR_INTERVAL = 0.04

    while not unloaded do
        task.wait(0.03)
        t = t + 0.03

        local breathe = math.sin(t * 0.35) * 0.18
        local colorPhase = (t * 0.045 + breathe)

        for i, layer in ipairs(glowLayers) do
            local pulse = (math.sin(t * 1.1 + i * 0.9) + 1) * 0.5
            local pulseAmount = 0.10 - i * 0.012
            pcall(function()
                layer.stroke.Transparency = layer.baseTransparency - pulse * pulseAmount
            end)
        end

        local edge = glowLayers[#glowLayers]
        if edge then
            pcall(function()
                edge.stroke.Thickness = edge.baseThickness + math.sin(t * 1.8) * 0.6
            end)
        end

        colorAccum = colorAccum + 0.03
        if colorAccum >= COLOR_INTERVAL then
            colorAccum = 0
            for i, layer in ipairs(glowLayers) do
                local ph = colorPhase + layer.phaseOffset
                pcall(function()
                    layer.grad.Color = buildGradientColors(ph, layer.spread)
                    layer.grad.Rotation = (t * 5 + i * 60) % 360
                end)
            end
        end
    end
end)

task.spawn(function()
    while not unloaded do
        task.wait(7)
        if unloaded then break end
        for i, layer in ipairs(glowLayers) do
            task.spawn(function()
                task.wait((i - 1) * 0.35)
                if unloaded then return end
                local origT = layer.baseThickness
                Tween:Create(layer.stroke,
                    TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { Thickness = origT * 1.45 }):Play()
                task.wait(1.8)
                if unloaded then return end
                Tween:Create(layer.stroke,
                    TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { Thickness = origT }):Play()
            end)
        end
    end
end)

-- Фон
local bgBack = mk("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(60, 36, 58),
    BorderSizePixel = 0, ZIndex = 0,
}, win)
corner(bgBack, 16)

local bgBackGrad = Instance.new("UIGradient")
bgBackGrad.Rotation = 45
bgBackGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 50, 80)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 70, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 40, 70)),
})
bgBackGrad.Parent = bgBack

local bgOverlay = mk("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(42, 26, 40),
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0, ZIndex = 2,
}, win)
corner(bgOverlay, 16)

-- ==================== HEADER ====================
local header = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = Color3.fromRGB(52, 30, 50),
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0, Active = true, ZIndex = 5,
}, win)
corner(header, 16)

local titleLabel = mk("TextLabel", {
    Size = UDim2.new(1, -200, 1, 0),
    Position = UDim2.new(0, 22, 0, 0),
    BackgroundTransparency = 1, Text = "BOGDANWARE",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBlack, TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
}, header)

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 158, 196)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(216, 167, 232)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 158, 196)),
})
titleGradient.Parent = titleLabel

task.spawn(function()
    local offset = 0
    while not unloaded do
        task.wait(0.03)
        offset = (offset + 0.006) % 1
        titleGradient.Offset = Vector2.new(offset, 0)
    end
end)

local statusFrame = mk("Frame", {
    Size = UDim2.new(0, 260, 0, 30),
    Position = UDim2.new(1, -370, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(255, 230, 240),
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0, ZIndex = 6,
}, header)
corner(statusFrame, 6)
stroke(statusFrame, Color3.fromRGB(180, 110, 160), 1, 0.3)

local statusLbl = mk("TextLabel", {
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 5, 0, 0),
    BackgroundTransparency = 1,
    Text = "FPS: --  |  Online: --  |  Ping: --",
    TextColor3 = Color3.fromRGB(120, 60, 100),
    Font = Enum.Font.Code, TextSize = 11, ZIndex = 7,
}, statusFrame)

local fpsSamples = {}
connect(RunService.RenderStepped, function(dt)
    if unloaded then return end
    table.insert(fpsSamples, 1/dt)
    if #fpsSamples > 60 then table.remove(fpsSamples, 1) end
end)

task.spawn(function()
    while not unloaded do
        task.wait(0.5)
        if unloaded then break end
        local fps = 0
        for _, v in ipairs(fpsSamples) do fps = fps + v end
        fps = #fpsSamples > 0 and math.floor(fps / #fpsSamples) or 0
        local online = #Players:GetPlayers()
        local ping = 0
        pcall(function() ping = math.floor(LP:GetNetworkPing() * 1000) end)
        pcall(function()
            statusLbl.Text = string.format("FPS: %d  |  Online: %d  |  Ping: %dms", fps, online, ping)
        end)
    end
end)

local function headerBtn(txt, accent, xOff)
    local b = mk("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, xOff, 0.5, -16),
        BackgroundColor3 = Color3.fromRGB(255, 235, 245),
        BackgroundTransparency = 0.25, Text = txt,
        TextColor3 = Color3.fromRGB(120, 60, 100),
        Font = Enum.Font.GothamBold, TextSize = 14,
        AutoButtonColor = false, ZIndex = 6,
    }, header)
    corner(b, 8)
    stroke(b, accent, 1, 0.2)
    b.MouseEnter:Connect(function()
        Tween:Create(b, SMOOTH, {
            BackgroundTransparency = 0, BackgroundColor3 = accent,
            TextColor3 = Color3.fromRGB(80, 30, 60),
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        Tween:Create(b, SMOOTH, {
            BackgroundTransparency = 0.25,
            BackgroundColor3 = Color3.fromRGB(255, 235, 245),
            TextColor3 = Color3.fromRGB(120, 60, 100),
        }):Play()
    end)
    addRipple(b)
    return b
end

local minBtn   = headerBtn("-", ACCENT_1, -80)
local closeBtn = headerBtn("X", ACCENT_3, -44)

do
    local dragging, dragStart, startPos
    connect(header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)
    connect(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ==================== BODY ====================
local body = mk("Frame", {
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundTransparency = 1, ZIndex = 5,
}, win)

local searchFrame = mk("Frame", {
    Size = UDim2.new(0, 175, 0, 44),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(48, 28, 46),
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0, ZIndex = 10,
}, body)

mk("Frame", {
    Size = UDim2.new(1, -20, 0, 1),
    Position = UDim2.new(0, 10, 1, -1),
    BackgroundColor3 = ACCENT_1,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0, ZIndex = 10,
}, searchFrame)

local searchBox = mk("TextBox", {
    Size = UDim2.new(1, -24, 0, 30),
    Position = UDim2.new(0, 12, 0, 7),
    BackgroundColor3 = Color3.fromRGB(60, 36, 58),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = "Поиск...",
    PlaceholderColor3 = Color3.fromRGB(190, 140, 170),
    TextColor3 = TEXT_MAIN,
    Font = Enum.Font.Gotham, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 11,
}, searchFrame)
corner(searchBox, 6)
local searchStroke = stroke(searchBox, ACCENT_2, 1, 0.4)

searchBox.Focused:Connect(function()
    pcall(function()
        searchStroke.Color = ACCENT_1
        searchStroke.Thickness = 2
    end)
end)
searchBox.FocusLost:Connect(function()
    pcall(function()
        searchStroke.Color = ACCENT_2
        searchStroke.Thickness = 1
    end)
end)

local sidebar = mk("ScrollingFrame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 175, 1, -44),
    Position = UDim2.new(0, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(48, 28, 46),
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 5, Active = true,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = ACCENT_1,
    ScrollBarImageTransparency = 0.3,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ClipsDescendants = true,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, body)

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 5)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar

local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 8)
sidebarPad.PaddingLeft = UDim.new(0, 12)
sidebarPad.PaddingRight = UDim.new(0, 12)
sidebarPad.PaddingBottom = UDim.new(0, 10)
sidebarPad.Parent = sidebar

local function refreshSidebar()
    local totalH = sidebarLayout.AbsoluteContentSize.Y
        + sidebarPad.PaddingTop.Offset
        + sidebarPad.PaddingBottom.Offset
    sidebar.CanvasSize = UDim2.new(0, 0, 0, totalH)
end
sidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshSidebar)

connect(sidebar.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local newY = sidebar.CanvasPosition.Y - input.Position.Z * 30
        local maxY = math.max(0, sidebar.AbsoluteCanvasSize.Y - sidebar.AbsoluteSize.Y)
        sidebar.CanvasPosition = Vector2.new(0, math.clamp(newY, 0, maxY))
    end
end)

local content = mk("Frame", {
    Size = UDim2.new(1, -190, 1, -20),
    Position = UDim2.new(0, 180, 0, 10),
    BackgroundTransparency = 1,
    ClipsDescendants = true, ZIndex = 6,
}, body)

-- ==================== ВКЛАДКИ ====================
local pages, tabButtons = {}, {}
local currentTab
local TAB_H = 32
local TAB_GAP = 4

local function refreshCanvas(page)
    local layout = page:FindFirstChildOfClass("UIListLayout")
    if layout then
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end
end

local function selectTab(name)
    if not pages[name] or currentTab == name then return end
    currentTab = name
    for n, p in pairs(pages) do
        p.Visible = (n == name)
        if n == name then task.defer(function() refreshCanvas(p) end) end
    end
    for n, b in pairs(tabButtons) do
        local active = (n == name)
        pcall(function()
            Tween:Create(b, SMOOTH, {
                BackgroundColor3 = active and ACCENT_1 or Color3.fromRGB(56, 32, 54),
                BackgroundTransparency = active and 0.1 or 0.5,
                TextColor3 = active and Color3.fromRGB(80, 30, 60) or TEXT_DIM,
            }):Play()
        end)
    end
end

local function createTab(name)
    local page = mk("ScrollingFrame", {
        Name = "Page_" .. name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACCENT_1,
        ScrollBarImageTransparency = 0.2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false, ZIndex = 7,
        ClipsDescendants = true,
    }, content)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = page

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        refreshCanvas(page)
    end)
    task.defer(function() refreshCanvas(page) end)
    pages[name] = page

    local btn = mk("TextButton", {
        Name = "Tab_" .. name,
        Size = UDim2.new(1, 0, 0, TAB_H),
        BackgroundColor3 = Color3.fromRGB(56, 32, 54),
        BackgroundTransparency = 0.5,
        Text = "  " .. name,
        TextColor3 = TEXT_DIM,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false, Active = true, Selectable = true, ZIndex = 7,
    }, sidebar)
    corner(btn, 8)
    stroke(btn, ACCENT_1, 1, 0.9)
    tabButtons[name] = btn

    btn.MouseEnter:Connect(function()
        if currentTab == name then return end
        Tween:Create(btn, SMOOTH, {
            BackgroundColor3 = BG_HOVER, BackgroundTransparency = 0.2,
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        if currentTab == name then return end
        Tween:Create(btn, SMOOTH, {
            BackgroundColor3 = Color3.fromRGB(56, 32, 54),
            BackgroundTransparency = 0.5,
        }):Play()
    end)
    btn.MouseButton1Click:Connect(function() selectTab(name) end)

    if not currentTab then
        currentTab = name
        page.Visible = true
        btn.BackgroundColor3 = ACCENT_1
        btn.BackgroundTransparency = 0.1
        btn.TextColor3 = Color3.fromRGB(80, 30, 60)
    end

    task.defer(refreshSidebar)
    return page
end

-- ==================== ПОИСК ====================
local function applySearch()
    local q = string.lower(searchBox.Text)
    local page = pages[currentTab]
    if not page then return end
    for _, child in ipairs(page:GetChildren()) do
        if (child:IsA("Frame") or child:IsA("TextButton"))
           and not child:IsA("UIListLayout")
           and not child:IsA("UIPadding") then
            local isSection = false
            if child:IsA("Frame") then
                local first = child:GetChildren()[1]
                if first and first:IsA("Frame")
                   and first.Size and first.Size.X.Offset == 3
                   and first.BackgroundColor3 == ACCENT_1 then
                    isSection = true
                end
            end
            if isSection then
                child.Visible = true
            else
                local label = child:FindFirstChildOfClass("TextLabel")
                if label then
                    child.Visible = (q == "" or string.find(string.lower(label.Text), q, 1, true) ~= nil)
                else
                    child.Visible = (q == "")
                end
            end
        end
    end
end

connect(searchBox:GetPropertyChangedSignal("Text"), applySearch)

-- ==================== КОМПОНЕНТЫ ====================
local function makeSection(parent, title, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    mk("Frame", {
        Size = UDim2.new(0, 3, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = ACCENT_1, BorderSizePixel = 0, ZIndex = 8,
    }, row)
    mk("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title), TextColor3 = ACCENT_1,
        Font = Enum.Font.GothamBlack, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    }, row)
end

local function makeToggle(parent, label, default, callback, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = BG_CARD, BackgroundTransparency = 0.15,
        BorderSizePixel = 0, LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    corner(row, 10)
    stroke(row, ACCENT_1, 1, 1)

    mk("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    }, row)

    local track = mk("Frame", {
        Size = UDim2.new(0, 44, 0, 22),
        Position = UDim2.new(1, -60, 0.5, -11),
        BackgroundColor3 = default and ACCENT_1 or Color3.fromRGB(70, 44, 68),
        BorderSizePixel = 0, ZIndex = 8,
    }, row)
    corner(track, 11)

    local knob = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 245, 250),
        BorderSizePixel = 0, ZIndex = 9,
    }, track)
    corner(knob, 8)

    local hit = mk("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 10,
    }, row)

    local state = default
    local function set(v)
        state = v
        Tween:Create(knob, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
            Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        }):Play()
        Tween:Create(track, TweenInfo.new(0.35, Enum.EasingStyle.Sine), {
            BackgroundColor3 = state and ACCENT_1 or Color3.fromRGB(70, 44, 68),
        }):Play()
    end

    hit.MouseButton1Click:Connect(function()
        set(not state)
        if callback then pcall(callback, state) end
        queueSave()
    end)

    return { set = set, get = function() return state end }
end

local function makeSlider(parent, label, minVal, maxVal, default, callback, order, isInt)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = BG_CARD, BackgroundTransparency = 0.15,
        BorderSizePixel = 0, LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    corner(row, 10)
    stroke(row, ACCENT_2, 1, 1)

    local labelObj = mk("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18),
        Position = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1,
        Text = label .. "   " .. (isInt and tostring(math.floor(default)) or string.format("%.2f", default)),
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    }, row)

    local bar = mk("Frame", {
        Size = UDim2.new(1, -32, 0, 6),
        Position = UDim2.new(0, 16, 0, 34),
        BackgroundColor3 = Color3.fromRGB(72, 44, 70),
        BorderSizePixel = 0, ZIndex = 8,
    }, row)
    corner(bar, 3)

    local pct = (default - minVal) / (maxVal - minVal)
    local fill = mk("Frame", {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, ZIndex = 9,
    }, bar)
    corner(fill, 3)
    grad(fill, ACCENT_1, ACCENT_2, 0)

    local knob = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(pct, -8, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 245, 250),
        BorderSizePixel = 0, ZIndex = 10,
    }, bar)
    corner(knob, 8)
    stroke(knob, ACCENT_1, 1.5, 0.25)

    local hit = mk("TextButton", {
        Size = UDim2.new(1, 0, 3, 0),
        Position = UDim2.new(0, 0, 0.5, -1.5),
        BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 11,
    }, bar)

    local dragging = false
    local function update(input)
        local relX = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = minVal + (maxVal - minVal) * relX
        if isInt then value = math.floor(value + 0.5) end
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -8, 0.5, -8)
        labelObj.Text = label .. "   " .. (isInt and tostring(value) or string.format("%.2f", value))
        if callback then pcall(callback, value) end
        queueSave()
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    connect(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

local function makeChips(parent, label, options, default, callback, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = BG_CARD, BackgroundTransparency = 0.15,
        BorderSizePixel = 0, LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    corner(row, 10)
    stroke(row, ACCENT_3, 1, 1)

    mk("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18),
        Position = UDim2.new(0, 16, 0, 5),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    }, row)

    local strip = mk("Frame", {
        Size = UDim2.new(1, -28, 0, 26),
        Position = UDim2.new(0, 14, 0, 26),
        BackgroundTransparency = 1, ZIndex = 8,
    }, row)
    local stripLayout = Instance.new("UIListLayout")
    stripLayout.FillDirection = Enum.FillDirection.Horizontal
    stripLayout.Padding = UDim.new(0, 6)
    stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
    stripLayout.Parent = strip

    local current = default
    local chips = {}

    for _, opt in ipairs(options) do
        local c = mk("TextButton", {
            Size = UDim2.new(0, 80, 1, 0),
            BackgroundColor3 = (opt == current) and ACCENT_1 or Color3.fromRGB(70, 44, 68),
            Text = opt,
            TextColor3 = (opt == current) and Color3.fromRGB(80, 30, 60) or TEXT_DIM,
            Font = Enum.Font.GothamBold, TextSize = 11,
            AutoButtonColor = false, ZIndex = 9,
        }, strip)
        corner(c, 6)
        chips[opt] = c

        c.MouseButton1Click:Connect(function()
            current = opt
            for name, chip in pairs(chips) do
                local active = (name == opt)
                chip.BackgroundColor3 = active and ACCENT_1 or Color3.fromRGB(70, 44, 68)
                chip.TextColor3 = active and Color3.fromRGB(80, 30, 60) or TEXT_DIM
            end
            if callback then pcall(callback, opt) end
            queueSave()
        end)
    end
    return { get = function() return current end }
end

local function makeTextBox(parent, label, default, callback, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = BG_CARD, BackgroundTransparency = 0.15,
        BorderSizePixel = 0, LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    corner(row, 10)
    stroke(row, ACCENT_2, 1, 1)

    mk("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    }, row)

    local box = mk("TextBox", {
        Size = UDim2.new(0, 150, 0, 28),
        Position = UDim2.new(1, -166, 0.5, -14),
        BackgroundColor3 = Color3.fromRGB(70, 44, 68),
        BorderSizePixel = 0, Text = default or "",
        PlaceholderText = "Введите...",
        PlaceholderColor3 = Color3.fromRGB(150, 110, 140),
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, ZIndex = 9,
    }, row)
    corner(box, 6)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        if callback then pcall(callback, box.Text) end
        queueSave()
    end)
    return box
end

local COLOR_PRESETS = {
    Color3.fromRGB(255, 158, 196), Color3.fromRGB(255, 179, 198),
    Color3.fromRGB(216, 167, 232), Color3.fromRGB(255, 200, 220),
    Color3.fromRGB(240, 130, 180), Color3.fromRGB(255, 220, 180),
    Color3.fromRGB(180, 140, 220), Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(200, 170, 200), Color3.fromRGB(90, 50, 90),
    Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 255, 120),
}

local function makeColorPicker(parent, label, default, callback, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = BG_CARD, BackgroundTransparency = 0.15,
        BorderSizePixel = 0, LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    corner(row, 10)
    stroke(row, ACCENT_1, 1, 1)

    mk("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18),
        Position = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1, Text = label,
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    }, row)

    local strip = mk("Frame", {
        Size = UDim2.new(1, -28, 0, 26),
        Position = UDim2.new(0, 14, 0, 32),
        BackgroundTransparency = 1, ZIndex = 8,
    }, row)
    local stripLayout = Instance.new("UIListLayout")
    stripLayout.FillDirection = Enum.FillDirection.Horizontal
    stripLayout.Padding = UDim.new(0, 5)
    stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
    stripLayout.Parent = strip

    local swatches = {}
    for _, c in ipairs(COLOR_PRESETS) do
        local sw = mk("TextButton", {
            Size = UDim2.new(0, 24, 1, 0),
            BackgroundColor3 = c, Text = "",
            AutoButtonColor = false, ZIndex = 9,
        }, strip)
        corner(sw, 6)
        local s = stroke(sw, Color3.fromRGB(255, 232, 242), 2,
            colorEq(c, default) and 0 or 0.85)
        swatches[sw] = s

        sw.MouseButton1Click:Connect(function()
            for _, os in pairs(swatches) do os.Transparency = 0.85 end
            s.Transparency = 0
            if callback then pcall(callback, c) end
            queueSave()
        end)
    end
end

-- ==================== ОБЩИЕ ХЕЛПЕРЫ ====================
local function isVisible(part)
    if not part then return false end
    local o = Camera.CFrame.Position
    local dir = part.Position - o
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character or LP }
    local res = workspace:Raycast(o, dir, params)
    return not res or res.Instance:IsDescendantOf(part.Parent)
end

local function pickPart(char, partName)
    if not char then return nil end
    if partName == "Head" then return char:FindFirstChild("Head")
    elseif partName == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    elseif partName == "HumanoidRootPart" then
        return char:FindFirstChild("HumanoidRootPart")
    else
        local best, bd, cp = nil, nil, Camera.CFrame.Position
        for _, pt in ipairs(char:GetChildren()) do
            if pt:IsA("BasePart") then
                local d = (pt.Position - cp).Magnitude
                if not bd or d < bd then best, bd = pt, d end
            end
        end
        return best
    end
end

local function isDowned(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return true end
    return (char:GetAttribute("Downed") or char:GetAttribute("downed")) == true
end

-- ==================== SHADER ====================
local shaderEffects = {}
local shaderOriginals = {}

local function createShaderEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing then return existing end
    local fx = Instance.new(className)
    fx.Name = name
    fx.Parent = Lighting
    shaderEffects[name] = fx
    return fx
end

local function initShaderEffects()
    -- сохраняем оригиналы
    if not shaderOriginals.initialized then
        shaderOriginals.initialized = true
        shaderOriginals.Ambient = Lighting.Ambient
        shaderOriginals.OutdoorAmbient = Lighting.OutdoorAmbient
        shaderOriginals.Brightness = Lighting.Brightness
        shaderOriginals.ClockTime = Lighting.ClockTime
        shaderOriginals.FogEnd = Lighting.FogEnd
        shaderOriginals.FogStart = Lighting.FogStart
        shaderOriginals.FogColor = Lighting.FogColor
    end
    createShaderEffect("BloomEffect", "BogdanBloom")
    createShaderEffect("ColorCorrectionEffect", "BogdanColorCorrection")
    createShaderEffect("SunRaysEffect", "BogdanSunRays")
    createShaderEffect("DepthOfFieldEffect", "BogdanDepthOfField")
    createShaderEffect("Atmosphere", "BogdanAtmosphere")
end
onCleanup(initShaderEffects)

local function applyShaderPreset(preset)
    initShaderEffects()
    local bloom = shaderEffects.BogdanBloom
    local cc    = shaderEffects.BogdanColorCorrection
    local sun   = shaderEffects.BogdanSunRays
    local dof   = shaderEffects.BogdanDepthOfField
    local atm   = shaderEffects.BogdanAtmosphere

    if not (bloom and cc and sun and dof and atm) then return end

    if preset == "Cinematic" then
        bloom.Enabled = true; bloom.Intensity = 1.2; bloom.Size = 28; bloom.Threshold = 0.85
        cc.Enabled = true; cc.Brightness = -0.05; cc.Contrast = 0.25; cc.Saturation = 0.15
        cc.TintColor = Color3.fromRGB(255, 215, 235)
        sun.Enabled = true; sun.Intensity = 0.1; sun.Spread = 1.1
        dof.Enabled = true; dof.FocusDistance = 25; dof.InFocusRadius = 18; dof.FarIntensity = 0.4
        atm.Enabled = true; atm.Density = 0.35; atm.Offset = 0.2; atm.Color = Color3.fromRGB(199, 170, 220)
        Lighting.Brightness = 2.2
        Lighting.Ambient = Color3.fromRGB(130, 120, 150)
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 170)
        Lighting.ClockTime = 17.5
        Lighting.FogEnd = 1200
        Lighting.FogColor = Color3.fromRGB(199, 170, 220)
    elseif preset == "Neon" then
        bloom.Enabled = true; bloom.Intensity = 2.5; bloom.Size = 40; bloom.Threshold = 0.5
        cc.Enabled = true; cc.Brightness = 0.1; cc.Contrast = 0.45; cc.Saturation = 0.7
        cc.TintColor = Color3.fromRGB(255, 180, 255)
        sun.Enabled = true; sun.Intensity = 0.25; sun.Spread = 1.5
        dof.Enabled = false
        atm.Enabled = true; atm.Density = 0.2; atm.Offset = 0.4; atm.Color = Color3.fromRGB(255, 150, 230)
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(200, 150, 220)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 130, 210)
        Lighting.ClockTime = 22
        Lighting.FogEnd = 800
        Lighting.FogColor = Color3.fromRGB(180, 120, 200)
    elseif preset == "Pastel" then
        bloom.Enabled = true; bloom.Intensity = 0.7; bloom.Size = 20; bloom.Threshold = 0.95
        cc.Enabled = true; cc.Brightness = 0.15; cc.Contrast = -0.1; cc.Saturation = 0.35
        cc.TintColor = Color3.fromRGB(255, 230, 245)
        sun.Enabled = true; sun.Intensity = 0.05; sun.Spread = 0.9
        dof.Enabled = false
        atm.Enabled = true; atm.Density = 0.4; atm.Offset = 0.15; atm.Color = Color3.fromRGB(255, 210, 230)
        Lighting.Brightness = 2.5
        Lighting.Ambient = Color3.fromRGB(220, 200, 220)
        Lighting.OutdoorAmbient = Color3.fromRGB(230, 210, 230)
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1500
        Lighting.FogColor = Color3.fromRGB(255, 210, 230)
    elseif preset == "Dark" then
        bloom.Enabled = true; bloom.Intensity = 0.6; bloom.Size = 16; bloom.Threshold = 1
        cc.Enabled = true; cc.Brightness = -0.15; cc.Contrast = 0.5; cc.Saturation = -0.2
        cc.TintColor = Color3.fromRGB(150, 150, 200)
        sun.Enabled = false
        dof.Enabled = true; dof.FocusDistance = 15; dof.InFocusRadius = 12; dof.FarIntensity = 0.6
        atm.Enabled = true; atm.Density = 0.5; atm.Offset = 0.1; atm.Color = Color3.fromRGB(80, 80, 120)
        Lighting.Brightness = 0.8
        Lighting.Ambient = Color3.fromRGB(70, 70, 90)
        Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 100)
        Lighting.ClockTime = 2
        Lighting.FogEnd = 600
        Lighting.FogColor = Color3.fromRGB(60, 60, 90)
    else -- Custom
        bloom.Enabled = true
        bloom.Intensity = Cfg.Shader.BloomIntensity
        bloom.Size = Cfg.Shader.BloomSize
        bloom.Threshold = Cfg.Shader.BloomThreshold
        cc.Enabled = true
        cc.Brightness = Cfg.Shader.ColorBrightness
        cc.Contrast = Cfg.Shader.ColorContrast
        cc.Saturation = Cfg.Shader.ColorSaturation
        cc.TintColor = Cfg.Shader.ColorTint
        sun.Enabled = true
        sun.Intensity = Cfg.Shader.SunRaysIntensity
        sun.Spread = Cfg.Shader.SunRaysSpread
        dof.Enabled = true
        dof.FocusDistance = Cfg.Shader.DOFFocusDistance
        dof.InFocusRadius = Cfg.Shader.DOFInFocusRadius
        dof.FarIntensity = Cfg.Shader.DOFBlurSize / 20
        atm.Enabled = true
        atm.Density = Cfg.Shader.AtmosphereDensity
        atm.Offset = Cfg.Shader.AtmosphereOffset
        atm.Color = Cfg.Shader.AtmosphereColor
        Lighting.Brightness = Cfg.Shader.Brightness
        Lighting.Ambient = Cfg.Shader.Ambient
        Lighting.OutdoorAmbient = Cfg.Shader.OutdoorAmbient
        Lighting.ClockTime = Cfg.Shader.ClockTime
        Lighting.FogEnd = Cfg.Shader.FogEnd
        Lighting.FogStart = Cfg.Shader.FogStart
        Lighting.FogColor = Cfg.Shader.FogColor
    end
end

local function disableShader()
    for _, fx in pairs(shaderEffects) do
        pcall(function() fx.Enabled = false end)
    end
    if shaderOriginals.initialized then
        pcall(function()
            Lighting.Ambient = shaderOriginals.Ambient
            Lighting.OutdoorAmbient = shaderOriginals.OutdoorAmbient
            Lighting.Brightness = shaderOriginals.Brightness
            Lighting.ClockTime = shaderOriginals.ClockTime
            Lighting.FogEnd = shaderOriginals.FogEnd
            Lighting.FogStart = shaderOriginals.FogStart
            Lighting.FogColor = shaderOriginals.FogColor
        end)
    end
end
onCleanup(disableShader)

-- ==================== HITSOUND ====================
local hitSoundConnection = nil
local lastHitPlayed = 0

local function playHitSound(headshot)
    local sid = headshot and Cfg.HitSound.HeadshotSoundId or Cfg.HitSound.SoundId
    local vol = headshot and Cfg.HitSound.HeadshotVolume or Cfg.HitSound.Volume
    local s = Instance.new("Sound")
    s.SoundId = sid
    s.Volume = vol
    s.Parent = SoundService
    s:Play()
    task.delay(2, function() pcall(function() s:Destroy() end) end)
end

local function startHitSound()
    if hitSoundConnection then
        pcall(function() hitSoundConnection:Disconnect() end)
    end

    local trackedHumans = {}

    local function trackCharacter(char)
        if not char or char == LP.Character then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if trackedHumans[hum] then return end

        trackedHumans[hum] = hum.HealthChanged:Connect(function(newHealth)
            if unloaded or not Cfg.HitSound.Enabled then return end
            local old = hum:GetAttribute("BogdanLastHealth") or hum.MaxHealth
            if newHealth < old and old - newHealth > 0 then
                local now = tick()
                if now - lastHitPlayed < 0.05 then return end
                lastHitPlayed = now

                local isHeadshot = false
                local myChar = LP.Character
                if myChar then
                    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                    local hisHead = char:FindFirstChild("Head")
                    if myRoot and hisHead then
                        -- эвристика: если урон > 60% от макс. HP — считаем хедшот
                        local dmg = old - newHealth
                        if dmg >= hum.MaxHealth * 0.5 then isHeadshot = true end
                    end
                end
                pcall(playHitSound, isHeadshot)
            end
            hum:SetAttribute("BogdanLastHealth", newHealth)
        end)

        hum:SetAttribute("BogdanLastHealth", hum.Health)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then trackCharacter(p.Character) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            p.CharacterAdded:Connect(function(c) task.wait(0.5); trackCharacter(c) end)
        end
    end

    hitSoundConnection = true
end

local function stopHitSound()
    if hitSoundConnection then
        hitSoundConnection = nil
    end
end
onCleanup(stopHitSound)

local function refreshHitSound()
    if Cfg.HitSound.Enabled then startHitSound()
    else stopHitSound() end
end

-- ==================== ANTIFLING ====================
local antiflingConnection = nil
local antiflingLastReset = 0

local function startAntiFling()
    if antiflingConnection then
        pcall(function() antiflingConnection:Disconnect() end)
    end

    antiflingConnection = RunService.Heartbeat:Connect(function()
        if unloaded or not Cfg.AntiFling.Enabled then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- 1. Сбрасываем коллизии у HRP других игроков (метод Collide)
        if Cfg.AntiFling.Method == "Collide" or Cfg.AntiFling.Method == "Freeze" then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local otherHrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if otherHrp and otherHrp.CanCollide then
                        pcall(function() otherHrp.CanCollide = false end)
                    end
                end
            end
        end

        -- 2. Отслеживаем свою скорость — если она аномальная, сбрасываем позицию
        if Cfg.AntiFling.Method == "Reset" or Cfg.AntiFling.AutoReset then
            local vel = hrp.AssemblyLinearVelocity
            if vel.Magnitude > Cfg.AntiFling.MaxVelocity then
                local now = tick()
                if now - antiflingLastReset > 0.5 then
                    antiflingLastReset = now
                    pcall(function()
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum.Sit = true
                            task.wait(0.05)
                            hum.Sit = false
                        end
                    end)
                end
            end
        end
    end)
end

local function stopAntiFling()
    if antiflingConnection then
        pcall(function() antiflingConnection:Disconnect() end)
        antiflingConnection = nil
    end
end
onCleanup(stopAntiFling)

local function refreshAntiFling()
    if Cfg.AntiFling.Enabled then startAntiFling()
    else stopAntiFling() end
end

-- ==================== WALLBANG ====================
local wallbangCount = 0
local wallbangDebug = false  -- для отладки, можно включить визуализацию

-- Проверяет, сколько "стен" между точкой и целью, и их суммарную толщину
local function checkWallbang(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local dir = (targetPos - origin)
    local dist = dir.Magnitude
    if dist > Cfg.Wallbang.MaxDistance then return false end
    dir = dir.Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character or LP }

    local totalThickness = 0
    local currentOrigin = origin
    local maxIters = 6

    for _ = 1, maxIters do
        local result = workspace:Raycast(currentOrigin, dir * Cfg.Wallbang.MaxDistance, params)
        if not result then return false end
        -- если попали в цель — ок
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return totalThickness <= Cfg.Wallbang.MaxThickness
        end
        -- посчитаем толщину стены
        local nextOrigin = result.Position + dir * 0.05
        local backParams = RaycastParams.new()
        backParams.FilterType = Enum.RaycastFilterType.Include
        backParams.FilterDescendantsInstances = { result.Instance }
        local back = workspace:Raycast(nextOrigin, -dir * 20, backParams)
        local thickness = 0
        if back then
            thickness = (nextOrigin - back.Position).Magnitude
        else
            thickness = 1  -- не смогли измерить, считаем тонкой
        end

        totalThickness = totalThickness + thickness
        if totalThickness > Cfg.Wallbang.MaxThickness then
            return false
        end

        currentOrigin = nextOrigin
    end
    return false
end

-- Расширенный поиск цели с wallbang (используется Silent Aim / Aimbot)
local function getTargetWithWallbang(baseGetTarget)
    return function()
        local t = baseGetTarget()
        if t and Cfg.Wallbang.Enabled then
            -- если цель за стеной — не отбрасываем, а помечаем
            local vis = isVisible(t)
            if not vis then
                if Cfg.Wallbang.VisibleOnly then
                    if checkWallbang(t) then return t end
                    return nil
                end
                return t  -- пропускаем сквозь стену
            end
        end
        return t
    end
end

-- ==================== SILENT AIM ====================
local silentTarget = nil

local function getSilentTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bd = nil, Cfg.SilentAim.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            if not (Cfg.SilentAim.TeamCheck and p.Team == LP.Team) then
                if not (Cfg.SilentAim.IgnoreDowned and isDowned(p.Character)) then
                    local part = pickPart(p.Character, Cfg.SilentAim.TargetPart)
                    if part then
                        local pass = true
                        if Cfg.SilentAim.VisibleOnly and not isVisible(part) then
                            if Cfg.Wallbang.Enabled and Cfg.SilentAim.Wallbang then
                                pass = checkWallbang(part)
                            else
                                pass = false
                            end
                        end
                        if pass and Cfg.Wallbang.Enabled and Cfg.SilentAim.Wallbang then
                            -- проверяем толщину стены, если цель не видна напрямую
                            if not isVisible(part) then
                                pass = checkWallbang(part)
                            end
                        end
                        if pass then
                            local sp, on = Camera:WorldToViewportPoint(part.Position)
                            if on and sp.Z > 0 then
                                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if d < bd then bd, best = d, part end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function getSilentHitPos(target)
    if not target then return nil end
    local pos = target.Position
    if Cfg.SilentAim.Prediction > 0 then
        pos = pos + target.Velocity * Cfg.SilentAim.Prediction
    end
    if Cfg.SilentAim.RandomizeBone then
        local size = target.Size
        pos = pos + Vector3.new(
            (math.random() - 0.5) * size.X * 0.6,
            (math.random() - 0.5) * size.Y * 0.6,
            (math.random() - 0.5) * size.Z * 0.6
        )
    end
    return pos
end

connect(RunService.RenderStepped, function()
    if unloaded then return end
    if Cfg.SilentAim.Enabled then
        silentTarget = getSilentTarget()
    else silentTarget = nil end
end)

local oldIndexHook
local hookOK = pcall(function()
    if not hookmetamethod then error("no hookmetamethod") end
    oldIndexHook = hookmetamethod(game, "__index", function(t, k)
        if Cfg.SilentAim.Enabled and silentTarget and not unloaded then
            local ok, isMouse = pcall(function() return t:IsA("Mouse") end)
            if ok and isMouse and (k == "Hit" or k == "Target") then
                if math.random(1, 100) <= Cfg.SilentAim.HitChance then
                    local hitPos = getSilentHitPos(silentTarget)
                    if hitPos then
                        if k == "Hit" then return CFrame.new(hitPos)
                        else return silentTarget end
                    end
                end
            end
        end
        return oldIndexHook(t, k)
    end)
end)

if not hookOK then
    warn("[BogdanWare] Silent Aim недоступен: hookmetamethod не поддерживается")
end

onCleanup(function()
    if oldIndexHook and hookmetamethod then
        pcall(function() hookmetamethod(game, "__index", oldIndexHook) end)
    end
end)

-- ==================== ESP ====================
local infoTags = {}
local function applyHighlight(char)
    if not char or char == LP.Character then return end
    local h = char:FindFirstChild("PlayerHighlight")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "PlayerHighlight"; h.Parent = char
    end
    h.FillColor = Cfg.ESP.FillColor
    h.OutlineColor = Cfg.ESP.OutlineColor
    h.FillTransparency = Cfg.ESP.FillTransparency
    h.OutlineTransparency = Cfg.ESP.OutlineTransparency
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = char
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local hisRoot = char:FindFirstChild("HumanoidRootPart")
    local inRange = true
    if myRoot and hisRoot then
        inRange = (myRoot.Position - hisRoot.Position).Magnitude <= Cfg.ESP.MaxDistance
    end
    local sameTeam = false
    if Cfg.ESP.TeamCheck then
        local p = Players:GetPlayerFromCharacter(char)
        if p and p.Team == LP.Team then sameTeam = true end
    end
    h.Enabled = Cfg.ESP.Enabled and inRange and not sameTeam
end

local function applyInfoTag(char)
    if not char or char == LP.Character then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local tag = head:FindFirstChild("BogdanInfoTag")
    if not tag then
        local bg = Instance.new("BillboardGui")
        bg.Name = "BogdanInfoTag"
        bg.Size = UDim2.new(0, 180, 0, 50)
        bg.StudsOffset = Vector3.new(0, 2.5, 0)
        bg.AlwaysOnTop = true; bg.MaxDistance = 500; bg.Parent = head
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0.33, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255, 232, 242)
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 14
        lbl.TextStrokeTransparency = 0.3; lbl.Parent = bg
        local hp = Instance.new("TextLabel")
        hp.Size = UDim2.new(1, 0, 0.33, 0)
        hp.Position = UDim2.new(0, 0, 0.33, 0)
        hp.BackgroundTransparency = 1
        hp.TextColor3 = Color3.fromRGB(255, 200, 220)
        hp.Font = Enum.Font.Gotham; hp.TextSize = 12
        hp.TextStrokeTransparency = 0.3; hp.Parent = bg
        local dist = Instance.new("TextLabel")
        dist.Size = UDim2.new(1, 0, 0.34, 0)
        dist.Position = UDim2.new(0, 0, 0.66, 0)
        dist.BackgroundTransparency = 1
        dist.TextColor3 = Color3.fromRGB(255, 200, 220)
        dist.Font = Enum.Font.Gotham; dist.TextSize = 12
        dist.TextStrokeTransparency = 0.3; dist.Parent = bg
        infoTags[char] = { bg = bg, name = lbl, hp = hp, dist = dist }
    end
    local data = infoTags[char]
    if not data then return end
    data.bg.Enabled = Cfg.ESP.ShowInfo
    if Cfg.ESP.ShowInfo then
        local plr = Players:GetPlayerFromCharacter(char)
        if plr then
            data.name.Text = Cfg.ESP.ShowName and plr.Name or ""
            local hum = char:FindFirstChildOfClass("Humanoid")
            if Cfg.ESP.ShowHealth and hum then
                data.hp.Text = string.format("%d / %d HP", math.floor(hum.Health), math.floor(hum.MaxHealth))
            else data.hp.Text = "" end
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local hisRoot = char:FindFirstChild("HumanoidRootPart")
            if Cfg.ESP.ShowDistance and myRoot and hisRoot then
                data.dist.Text = string.format("%d studs", math.floor((myRoot.Position - hisRoot.Position).Magnitude))
            else data.dist.Text = "" end
        end
    end
end

local function updateAllHighlights()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            applyHighlight(p.Character); applyInfoTag(p.Character)
        end
    end
end

local function clearESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("PlayerHighlight")
            if h then h:Destroy() end
            local head = p.Character:FindFirstChild("Head")
            if head then
                local t = head:FindFirstChild("BogdanInfoTag")
                if t then t:Destroy() end
            end
        end
    end
    infoTags = {}
end
onCleanup(clearESP)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        if p.Character then pcall(applyHighlight, p.Character); pcall(applyInfoTag, p.Character) end
        p.CharacterAdded:Connect(function(c) task.wait(0.5); pcall(applyHighlight, c); pcall(applyInfoTag, c) end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function(c) task.wait(0.5); pcall(applyHighlight, c); pcall(applyInfoTag, c) end)
end)

-- ==================== AIMBOT ====================
local currentTarget = nil
connect(RunService.RenderStepped, function()
    if unloaded then return end
    if not Cfg.Aimbot.Enabled then currentTarget = nil; return end
    if Cfg.Aimbot.HoldKey and not UIS:IsMouseButtonPressed(Cfg.Aimbot.Key) then
        currentTarget = nil; return
    end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bd = nil, Cfg.Aimbot.FOV
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local skipTeam = Cfg.ESP.TeamCheck and p.Team == LP.Team
            if not skipTeam then
                local part = pickPart(p.Character, Cfg.Aimbot.TargetPart)
                if part then
                    local hisRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    local inRange = true
                    if myRoot and hisRoot then
                        inRange = (myRoot.Position - hisRoot.Position).Magnitude <= Cfg.Aimbot.MaxDistance
                    end
                    local hide = Cfg.Aimbot.VisibleOnly and not isVisible(part)
                    if hide and Cfg.Wallbang.Enabled then
                        hide = not checkWallbang(part)
                    end
                    if inRange and not hide then
                        local sp, on = Camera:WorldToViewportPoint(part.Position)
                        if on and sp.Z > 0 then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < bd then bd, best = d, part end
                        end
                    end
                end
            end
        end
    end
    currentTarget = best
    if currentTarget then
        local targetPos = currentTarget.Position
        if Cfg.Aimbot.Prediction > 0 then
            targetPos = targetPos + currentTarget.Velocity * Cfg.Aimbot.Prediction
        end
        local targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 - Cfg.Aimbot.Smoothness)
    end
end)

-- ==================== TRIGGER ====================
local lastTrigger = 0
connect(RunService.RenderStepped, function()
    if unloaded then return end
    if not Cfg.Trigger.Enabled then return end
    if tick() - lastTrigger < Cfg.Trigger.Delay then return end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local unitRay = Camera:ViewportPointToRay(center.X, center.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LP.Character or LP }
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * Cfg.Trigger.MaxDistance, params)
    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local plr = Players:GetPlayerFromCharacter(model)
            if plr and plr ~= LP then
                if Cfg.Trigger.TeamCheck and plr.Team == LP.Team then return end
                if Cfg.Trigger.VisibleOnly and not isVisible(result.Instance) then
                    if not (Cfg.Wallbang.Enabled and checkWallbang(result.Instance)) then return end
                end
                lastTrigger = tick()
                local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
                pcall(function()
                    VirtualUser:Button1Down(Vector2.new(center.X, center.Y))
                    VirtualUser:Button1Up(Vector2.new(center.X, center.Y))
                end)
            end
        end
    end
end)

-- ==================== HITBOX ====================
local hitboxOriginal = {}

local function expandHitbox(char)
    if not char or char == LP.Character then return end
    if not hitboxOriginal[char] then hitboxOriginal[char] = {} end
    local store = hitboxOriginal[char]
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if Cfg.Hitbox.HeadOnly and part.Name ~= "Head" then continue end
            if not store[part.Name] then
                store[part.Name] = {
                    size = part.Size, transparency = part.Transparency,
                    cancollide = part.CanCollide,
                }
            end
            local target = store[part.Name].size * Cfg.Hitbox.Scale
            pcall(function()
                part.Size = target
                part.Transparency = Cfg.Hitbox.Transparency
                part.CanCollide = false; part.Massless = true
            end)
        end
    end
end

local function restoreHitbox(char)
    if not char then return end
    local store = hitboxOriginal[char]
    if not store then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and store[part.Name] then
            local o = store[part.Name]
            pcall(function()
                part.Size = o.size; part.Transparency = o.transparency
                part.CanCollide = o.cancollide; part.Massless = false
            end)
        end
    end
    hitboxOriginal[char] = nil
end

local function restoreAllHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then restoreHitbox(p.Character) end
    end
    hitboxOriginal = {}
end
onCleanup(restoreAllHitboxes)

local function refreshHitboxes()
    if Cfg.Hitbox.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then expandHitbox(p.Character) end
        end
    else restoreAllHitboxes() end
end

task.spawn(function()
    while not unloaded do
        task.wait(0.5)
        if Cfg.Hitbox.Enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then expandHitbox(p.Character) end
            end
        end
    end
end)

-- ==================== FULLBRIGHT ====================
local origAmb, origOut, origBri
local function setFullbright(on)
    if on then
        if not origAmb then
            origAmb = Lighting.Ambient; origOut = Lighting.OutdoorAmbient; origBri = Lighting.Brightness
        end
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
    elseif origAmb then
        Lighting.Ambient = origAmb; Lighting.OutdoorAmbient = origOut; Lighting.Brightness = origBri
    end
end
onCleanup(function() setFullbright(false) end)

-- ==================== NOCLIP ====================
local noclipTracked = {}
local function restoreAllNoclip()
    for part, old in pairs(noclipTracked) do
        pcall(function() part.CanCollide = old end)
    end
    noclipTracked = {}
end
onCleanup(restoreAllNoclip)

connect(RunService.Heartbeat, function()
    if unloaded then return end
    if not Cfg.Noclip.Enabled then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -8, 0), params)
    local groundPart = result and result.Instance or nil
    local nearby = {}
    local parts = workspace:GetPartBoundsInRadius(hrp.Position, Cfg.Noclip.Radius)
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and not p:IsDescendantOf(char) and p.Name ~= "Terrain" then
            nearby[p] = true
            if p ~= groundPart then
                if noclipTracked[p] == nil then noclipTracked[p] = p.CanCollide end
                p.CanCollide = false
            end
        end
    end
    for part, old in pairs(noclipTracked) do
        if not nearby[part] or part == groundPart then
            pcall(function() part.CanCollide = old end)
            noclipTracked[part] = nil
        end
    end
end)

-- ==================== FLY ====================
local function stopFly()
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        if hrp then
            local bv = hrp:FindFirstChild("BogdanFlyBV")
            if bv then bv:Destroy() end
        end
    end
end
onCleanup(stopFly)

connect(RunService.RenderStepped, function()
    if unloaded then return end
    if not Cfg.Fly.Enabled then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    local bv = hrp:FindFirstChild("BogdanFlyBV")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "BogdanFlyBV"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.zero; bv.Parent = hrp
    end
    local camCF = Camera.CFrame
    local moveDir = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, Cfg.Fly.VerticalSpeed, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, Cfg.Fly.VerticalSpeed, 0) end
    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * Cfg.Fly.Speed end
    bv.Velocity = moveDir
end)

-- ==================== SPINNER ====================
local spinAngle = 0
local spinBob = 0

local function stopSpinner()
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then
            local bv = hrp:FindFirstChild("BogdanSpinBV")
            if bv then bv:Destroy() end
        end
        if hum then hum.AutoRotate = true end
    end
end
onCleanup(stopSpinner)

connect(RunService.RenderStepped, function(dt)
    if unloaded then return end
    if not Cfg.Spinner.Enabled then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir = (Cfg.Spinner.Direction == "CCW") and -1 or 1
    local delta = math.rad(Cfg.Spinner.Speed) * dt * dir
    spinAngle = (spinAngle + delta) % (math.pi * 2)
    local mode = Cfg.Spinner.Mode
    local axis = Cfg.Spinner.Axis
    if mode == "Character" or mode == "Both" then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = false end
        local rot
        if axis == "X" then rot = CFrame.Angles(spinAngle, 0, 0)
        elseif axis == "Y" then rot = CFrame.Angles(0, spinAngle, 0)
        elseif axis == "Z" then rot = CFrame.Angles(0, 0, spinAngle)
        else rot = CFrame.Angles(spinAngle, spinAngle * 1.3, spinAngle * 0.7) end
        pcall(function() hrp.CFrame = CFrame.new(hrp.Position) * rot end)
    end
    if mode == "Camera" or mode == "Both" then
        Camera.CFrame = Camera.CFrame * CFrame.Angles(0, delta, 0)
    end
    if Cfg.Spinner.Bobbing then
        spinBob = spinBob + dt * Cfg.Spinner.BobSpeed
        local offsetY = math.sin(spinBob) * Cfg.Spinner.BobHeight
        local currentBV = hrp:FindFirstChild("BogdanSpinBV")
        if not currentBV then
            currentBV = Instance.new("BodyVelocity")
            currentBV.Name = "BogdanSpinBV"
            currentBV.MaxForce = Vector3.new(0, 1e5, 0)
            currentBV.Parent = hrp
        end
        currentBV.Velocity = Vector3.new(0, offsetY * 10, 0)
    end
end)

-- ==================== FLING ====================
local lastFlingTime = 0
local activeFlingBV = nil

local function getFlingTargetByName(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Name:lower() == name:lower() and p.Character then return p end
    end
    return nil
end

local function getFlingTargets()
    local myChar = LP.Character
    if not myChar then return {} end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return {} end
    local list = {}
    if Cfg.Fling.Target == "Player" and Cfg.Fling.TargetName ~= "" then
        local tp = getFlingTargetByName(Cfg.Fling.TargetName)
        if tp and tp.Character then
            local hrp = tp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local skip = false
                if Cfg.Fling.TeamCheck and tp.Team == LP.Team then skip = true end
                if Cfg.Fling.IgnoreDowned and isDowned(tp.Character) then skip = true end
                if not skip then table.insert(list, { player = tp, char = tp.Character, hrp = hrp, dist = 0 }) end
            end
        end
        return list
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local skip = false
                if Cfg.Fling.TeamCheck and p.Team == LP.Team then skip = true end
                if Cfg.Fling.IgnoreDowned and isDowned(p.Character) then skip = true end
                if not skip then
                    local dist = (hrp.Position - myRoot.Position).Magnitude
                    if dist <= Cfg.Fling.Range then
                        table.insert(list, { player = p, char = p.Character, hrp = hrp, dist = dist })
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    if Cfg.Fling.Target == "Nearest" then return list[1] and { list[1] } or {} end
    if Cfg.Fling.Target == "Cursor" then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local best, bd = nil, math.huge
        for _, t in ipairs(list) do
            local sp, on = Camera:WorldToViewportPoint(t.hrp.Position)
            if on and sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d < bd then bd, best = d, t end
            end
        end
        return best and { best } or {}
    end
    return list
end

local function flingVelocity(targets)
    for _, t in ipairs(targets) do
        pcall(function()
            local hrp = t.hrp
            local bv = hrp:FindFirstChild("BogdanFlingBV")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "BogdanFlingBV"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Parent = hrp; activeFlingBV = bv
            end
            local dir = Vector3.new(
                (math.random() - 0.5) * 2, math.random(0.5, 1.5), (math.random() - 0.5) * 2
            ).Unit
            bv.Velocity = dir * Cfg.Fling.Power
            task.delay(0.15, function()
                pcall(function()
                    if bv and bv.Parent then bv.Velocity = Vector3.new(0, Cfg.Fling.Power * 2, 0) end
                end)
            end)
            task.delay(0.35, function()
                pcall(function()
                    if bv and bv.Parent then bv:Destroy() end
                    if activeFlingBV == bv then activeFlingBV = nil end
                end)
            end)
        end)
    end
end

local function flingImpulse(targets)
    for _, t in ipairs(targets) do
        pcall(function()
            local hrp = t.hrp
            if hrp and hrp:IsA("BasePart") then
                local flingDir = Vector3.new(
                    (math.random() - 0.5) * 2, math.random(0.8, 1.5), (math.random() - 0.5) * 2
                ).Unit * Cfg.Fling.Power
                hrp:ApplyImpulse(flingDir)
                hrp:ApplyAngularImpulse(Vector3.new(
                    math.random(-Cfg.Fling.Power, Cfg.Fling.Power),
                    math.random(-Cfg.Fling.Power, Cfg.Fling.Power),
                    math.random(-Cfg.Fling.Power, Cfg.Fling.Power)
                ))
            end
        end)
    end
end

local function doFling()
    if unloaded then return end
    local now = tick()
    if now - lastFlingTime < 0.1 then return end
    lastFlingTime = now
    local targets = getFlingTargets()
    if #targets == 0 then return end
    if Cfg.Fling.Method == "Velocity" then flingVelocity(targets)
    else flingImpulse(targets) end
end

task.spawn(function()
    while not unloaded do
        task.wait(0.1)
        if unloaded then break end
        if Cfg.Fling.Enabled and Cfg.Fling.AutoRepeat then
            if tick() - lastFlingTime >= Cfg.Fling.Interval then doFling() end
        end
    end
end)

connect(UIS.InputBegan, function(input, gp)
    if unloaded or gp then return end
    if input.KeyCode == Cfg.Fling.Key and Cfg.Fling.Enabled and not Cfg.Fling.AutoRepeat then
        if not Cfg.Fling.HoldToFling then doFling() end
    end
end)

connect(RunService.Heartbeat, function()
    if unloaded then return end
    if not Cfg.Fling.Enabled or Cfg.Fling.AutoRepeat then return end
    if not Cfg.Fling.HoldToFling then return end
    if UIS:IsKeyDown(Cfg.Fling.Key) then
        if tick() - lastFlingTime >= 0.1 then doFling() end
    end
end)

onCleanup(function()
    if activeFlingBV then pcall(function() activeFlingBV:Destroy() end) end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bv = hrp:FindFirstChild("BogdanFlingBV")
                if bv then bv:Destroy() end
            end
        end
    end
end)

-- ==================== OVERLAY ====================
local fovFrame = mk("Frame", {
    Name = "FOVCircle", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
    Size = UDim2.new(0, 0, 0, 0),
}, overlay)
corner(fovFrame, 999)
local fovStroke = stroke(fovFrame, Cfg.Aimbot.FOVColor, 1.5, 0.3)

local silentFovFrame = mk("Frame", {
    Name = "SilentFOV", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
    Size = UDim2.new(0, 0, 0, 0),
}, overlay)
corner(silentFovFrame, 999)
local silentFovStroke = stroke(silentFovFrame, Cfg.SilentAim.FOVColor, 1.5, 0.4)

local crossContainer = mk("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 60, 0, 60),
    BackgroundTransparency = 1, ZIndex = 3,
}, overlay)
local crossParts = {}
local function rebuildCrosshair()
    for _, p in ipairs(crossParts) do p:Destroy() end
    crossParts = {}
    local style = Cfg.Visuals.CrosshairStyle
    if style == "None" then return end
    local col = Cfg.Visuals.CrosshairColor
    local sz = Cfg.Visuals.CrosshairSize
    local th = Cfg.Visuals.CrosshairThickness
    if style == "Dot" then
        local d = mk("Frame", { Size = UDim2.new(0, th * 2, 0, th * 2), Position = UDim2.new(0.5, -th, 0.5, -th),
            BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 4 }, crossContainer)
        corner(d, th * 2); table.insert(crossParts, d)
    elseif style == "Circle" then
        local c = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, sz + 6, 0, sz + 6),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 4 }, crossContainer)
        corner(c, 999); stroke(c, col, th, 0); table.insert(crossParts, c)
    elseif style == "X" then
        local l1 = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, sz, 0, th),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4, Rotation = 45 }, crossContainer)
        local l2 = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, sz, 0, th),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4, Rotation = -45 }, crossContainer)
        table.insert(crossParts, l1); table.insert(crossParts, l2)
    else
        local h = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, sz, 0, th),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4 }, crossContainer)
        local v = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, th, 0, sz),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4 }, crossContainer)
        table.insert(crossParts, h); table.insert(crossParts, v)
    end
end

connect(RunService.RenderStepped, function()
    if unloaded then return end
    fovFrame.Size = UDim2.new(0, Cfg.Aimbot.FOV * 2, 0, Cfg.Aimbot.FOV * 2)
    fovFrame.Visible = Cfg.Aimbot.ShowFOV and Cfg.Aimbot.Enabled
    fovStroke.Color = Cfg.Aimbot.FOVColor
    silentFovFrame.Size = UDim2.new(0, Cfg.SilentAim.FOV * 2, 0, Cfg.SilentAim.FOV * 2)
    silentFovFrame.Visible = Cfg.SilentAim.ShowFOV and Cfg.SilentAim.Enabled
    silentFovStroke.Color = Cfg.SilentAim.FOVColor
    crossContainer.Visible = Cfg.Visuals.Crosshair and Cfg.Visuals.CrosshairStyle ~= "None"
end)

-- ==================== СТРАНИЦЫ ====================
local pMain = createTab("Главное")
makeSection(pMain, "Основные", 1)
makeToggle(pMain, "ESP подсветка", Cfg.ESP.Enabled, function(v) Cfg.ESP.Enabled = v; updateAllHighlights() end, 2)
makeToggle(pMain, "Инфо-теги", Cfg.ESP.ShowInfo, function(v) Cfg.ESP.ShowInfo = v; updateAllHighlights() end, 3)
makeToggle(pMain, "Silent Aim", Cfg.SilentAim.Enabled, function(v) Cfg.SilentAim.Enabled = v end, 4)
makeToggle(pMain, "Aimbot", Cfg.Aimbot.Enabled, function(v) Cfg.Aimbot.Enabled = v end, 5)
makeToggle(pMain, "Trigger Bot", Cfg.Trigger.Enabled, function(v) Cfg.Trigger.Enabled = v end, 6)
makeToggle(pMain, "Hitbox Expander", Cfg.Hitbox.Enabled, function(v)
    Cfg.Hitbox.Enabled = v; refreshHitboxes()
end, 7)
makeToggle(pMain, "SpeedHack", Cfg.SpeedHack.Enabled, function(v)
    Cfg.SpeedHack.Enabled = v
    if not v then stopSpeedHack() end
end, 8)
makeToggle(pMain, "GodMode", Cfg.GodMode.Enabled, function(v)
    Cfg.GodMode.Enabled = v
    if not v then stopGodMode() end
end, 9)
makeToggle(pMain, "BunnyHop", Cfg.BunnyHop.Enabled, function(v)
    Cfg.BunnyHop.Enabled = v
    refreshBunnyHop()
end, 10)
makeToggle(pMain, "Spinner", Cfg.Spinner.Enabled, function(v)
    Cfg.Spinner.Enabled = v
    if not v then stopSpinner() end
end, 11)
makeToggle(pMain, "Fling", Cfg.Fling.Enabled, function(v) Cfg.Fling.Enabled = v end, 12)
makeToggle(pMain, "AntiFling", Cfg.AntiFling.Enabled, function(v)
    Cfg.AntiFling.Enabled = v; refreshAntiFling()
end, 13)
makeToggle(pMain, "HitSound", Cfg.HitSound.Enabled, function(v)
    Cfg.HitSound.Enabled = v; refreshHitSound()
end, 14)
makeToggle(pMain, "Wallbang", Cfg.Wallbang.Enabled, function(v) Cfg.Wallbang.Enabled = v end, 15)
makeSection(pMain, "Визуал", 16)
makeToggle(pMain, "Прицел", Cfg.Visuals.Crosshair, function(v) Cfg.Visuals.Crosshair = v end, 17)
makeToggle(pMain, "Fullbright", Cfg.Visuals.Fullbright, function(v)
    Cfg.Visuals.Fullbright = v; setFullbright(v)
end, 18)

-- Silent Aim
local pSilent = createTab("Silent Aim")
makeSection(pSilent, "Основные", 1)
makeToggle(pSilent, "Включить", Cfg.SilentAim.Enabled, function(v) Cfg.SilentAim.Enabled = v end, 2)
makeSlider(pSilent, "FOV", 30, 600, Cfg.SilentAim.FOV, function(v) Cfg.SilentAim.FOV = v end, 3, true)
makeChips(pSilent, "Часть тела", { "Head", "Torso", "HumanoidRootPart", "Nearest" },
    Cfg.SilentAim.TargetPart, function(v) Cfg.SilentAim.TargetPart = v end, 4)
makeSection(pSilent, "Поведение", 5)
makeToggle(pSilent, "Проверка команды", Cfg.SilentAim.TeamCheck, function(v) Cfg.SilentAim.TeamCheck = v end, 6)
makeToggle(pSilent, "Только видимые", Cfg.SilentAim.VisibleOnly, function(v) Cfg.SilentAim.VisibleOnly = v end, 7)
makeToggle(pSilent, "Игнор лежачих", Cfg.SilentAim.IgnoreDowned, function(v) Cfg.SilentAim.IgnoreDowned = v end, 8)
makeSlider(pSilent, "Шанс попадания (%)", 0, 100, Cfg.SilentAim.HitChance, function(v) Cfg.SilentAim.HitChance = v end, 9, true)
makeSlider(pSilent, "Предсказание", 0, 0.5, Cfg.SilentAim.Prediction, function(v) Cfg.SilentAim.Prediction = v end, 10)
makeToggle(pSilent, "Рандомизация точки", Cfg.SilentAim.RandomizeBone, function(v) Cfg.SilentAim.RandomizeBone = v end, 11)
makeSection(pSilent, "Wallbang", 12)
makeToggle(pSilent, "Стрелять сквозь стены", Cfg.SilentAim.Wallbang, function(v) Cfg.SilentAim.Wallbang = v end, 13)
makeToggle(pSilent, "Только тонкие стены", Cfg.Wallbang.VisibleOnly, function(v) Cfg.Wallbang.VisibleOnly = v end, 14)
makeSection(pSilent, "Визуал", 15)
makeToggle(pSilent, "Круг FOV", Cfg.SilentAim.ShowFOV, function(v) Cfg.SilentAim.ShowFOV = v end, 16)
makeColorPicker(pSilent, "Цвет круга", Cfg.SilentAim.FOVColor, function(c) Cfg.SilentAim.FOVColor = c end, 17)

-- Aimbot
local pAim = createTab("Aimbot")
makeSection(pAim, "Основные", 1)
makeToggle(pAim, "Включить", Cfg.Aimbot.Enabled, function(v) Cfg.Aimbot.Enabled = v end, 2)
makeSlider(pAim, "FOV", 50, 800, Cfg.Aimbot.FOV, function(v) Cfg.Aimbot.FOV = v end, 3, true)
makeSlider(pAim, "Сила аима", 1, 10, math.floor((1 - Cfg.Aimbot.Smoothness) * 10 + 0.5),
    function(v) Cfg.Aimbot.Smoothness = 1 - (v / 10) end, 4, true)
makeSlider(pAim, "Дистанция", 100, 2000, Cfg.Aimbot.MaxDistance, function(v) Cfg.Aimbot.MaxDistance = v end, 5, true)
makeSlider(pAim, "Предсказание", 0, 0.5, Cfg.Aimbot.Prediction, function(v) Cfg.Aimbot.Prediction = v end, 6)
makeChips(pAim, "Часть тела", { "Head", "Torso", "Nearest" }, Cfg.Aimbot.TargetPart,
    function(v) Cfg.Aimbot.TargetPart = v end, 7)
makeSection(pAim, "Поведение", 8)
makeToggle(pAim, "Только видимые", Cfg.Aimbot.VisibleOnly, function(v) Cfg.Aimbot.VisibleOnly = v end, 9)
makeToggle(pAim, "Удерживать кнопку", Cfg.Aimbot.HoldKey, function(v) Cfg.Aimbot.HoldKey = v end, 10)
makeToggle(pAim, "Круг FOV", Cfg.Aimbot.ShowFOV, function(v) Cfg.Aimbot.ShowFOV = v end, 11)

-- Trigger
local pTrig = createTab("Триггер")
makeSection(pTrig, "Trigger Bot", 1)
makeToggle(pTrig, "Включить", Cfg.Trigger.Enabled, function(v) Cfg.Trigger.Enabled = v end, 2)
makeSlider(pTrig, "Задержка", 0.01, 0.5, Cfg.Trigger.Delay, function(v) Cfg.Trigger.Delay = v end, 3)
makeSlider(pTrig, "Дистанция", 100, 2000, Cfg.Trigger.MaxDistance, function(v) Cfg.Trigger.MaxDistance = v end, 4, true)
makeToggle(pTrig, "Только видимые", Cfg.Trigger.VisibleOnly, function(v) Cfg.Trigger.VisibleOnly = v end, 5)
makeToggle(pTrig, "Проверка команды", Cfg.Trigger.TeamCheck, function(v) Cfg.Trigger.TeamCheck = v end, 6)
makeSection(pTrig, "Hitbox", 7)
makeToggle(pTrig, "Увеличивать", Cfg.Hitbox.Enabled, function(v)
    Cfg.Hitbox.Enabled = v; refreshHitboxes()
end, 8)
makeSlider(pTrig, "Множитель", 1.5, 5, Cfg.Hitbox.Scale, function(v)
    Cfg.Hitbox.Scale = v; refreshHitboxes()
end, 9)
makeSlider(pTrig, "Прозрачность", 0, 1, Cfg.Hitbox.Transparency, function(v)
    Cfg.Hitbox.Transparency = v; refreshHitboxes()
end, 10)
makeToggle(pTrig, "Только голова", Cfg.Hitbox.HeadOnly, function(v)
    Cfg.Hitbox.HeadOnly = v; refreshHitboxes()
end, 11)

-- ESP
local pEsp = createTab("ESP")
makeSection(pEsp, "Цвета", 1)
makeColorPicker(pEsp, "Заливка", Cfg.ESP.FillColor, function(c) Cfg.ESP.FillColor = c; updateAllHighlights() end, 2)
makeColorPicker(pEsp, "Обводка", Cfg.ESP.OutlineColor, function(c) Cfg.ESP.OutlineColor = c; updateAllHighlights() end, 3)
makeSection(pEsp, "Прозрачность", 4)
makeSlider(pEsp, "Заливка", 0, 1, Cfg.ESP.FillTransparency, function(v) Cfg.ESP.FillTransparency = v; updateAllHighlights() end, 5)
makeSlider(pEsp, "Обводка", 0, 1, Cfg.ESP.OutlineTransparency, function(v) Cfg.ESP.OutlineTransparency = v; updateAllHighlights() end, 6)
makeSection(pEsp, "Фильтры", 7)
makeToggle(pEsp, "Не светить союзников", Cfg.ESP.TeamCheck, function(v)
    Cfg.ESP.TeamCheck = v; updateAllHighlights()
end, 8)
makeSlider(pEsp, "Дистанция", 100, 5000, Cfg.ESP.MaxDistance, function(v)
    Cfg.ESP.MaxDistance = v; updateAllHighlights()
end, 9, true)
makeSection(pEsp, "Инфо", 10)
makeToggle(pEsp, "Имя", Cfg.ESP.ShowName, function(v) Cfg.ESP.ShowName = v end, 11)
makeToggle(pEsp, "HP", Cfg.ESP.ShowHealth, function(v) Cfg.ESP.ShowHealth = v end, 12)
makeToggle(pEsp, "Дистанция", Cfg.ESP.ShowDistance, function(v) Cfg.ESP.ShowDistance = v end, 13)

-- Визуал
local pVis = createTab("Визуал")
makeSection(pVis, "Прицел", 1)
makeToggle(pVis, "Показывать", Cfg.Visuals.Crosshair, function(v) Cfg.Visuals.Crosshair = v end, 2)
makeChips(pVis, "Стиль", { "Cross", "Dot", "Circle", "X", "None" }, Cfg.Visuals.CrosshairStyle, function(v)
    Cfg.Visuals.CrosshairStyle = v; rebuildCrosshair()
end, 3)
makeSlider(pVis, "Размер", 6, 40, Cfg.Visuals.CrosshairSize, function(v)
    Cfg.Visuals.CrosshairSize = v; rebuildCrosshair()
end, 4, true)
makeSlider(pVis, "Толщина", 1, 5, Cfg.Visuals.CrosshairThickness, function(v)
    Cfg.Visuals.CrosshairThickness = v; rebuildCrosshair()
end, 5, true)
makeColorPicker(pVis, "Цвет", Cfg.Visuals.CrosshairColor, function(c)
    Cfg.Visuals.CrosshairColor = c; rebuildCrosshair()
end, 6)
makeSection(pVis, "Окружение", 7)
makeToggle(pVis, "Fullbright", Cfg.Visuals.Fullbright, function(v)
    Cfg.Visuals.Fullbright = v; setFullbright(v)
end, 8)

-- SpeedHack
local pSpeed = createTab("SpeedHack")
makeSection(pSpeed, "Основные", 1)
makeToggle(pSpeed, "Включить", Cfg.SpeedHack.Enabled, function(v)
    Cfg.SpeedHack.Enabled = v
    if not v then stopSpeedHack() end
end, 2)
makeChips(pSpeed, "Метод", { "WalkSpeed", "Velocity", "CFrame" }, Cfg.SpeedHack.Method, function(v)
    Cfg.SpeedHack.Method = v
    stopSpeedHack()
end, 3)
makeSlider(pSpeed, "Скорость", 20, 500, Cfg.SpeedHack.Speed, function(v) Cfg.SpeedHack.Speed = v end, 4, true)
makeSlider(pSpeed, "Прыжок", 20, 200, Cfg.SpeedHack.JumpPower, function(v) Cfg.SpeedHack.JumpPower = v end, 5, true)
makeSection(pSpeed, "Условия", 6)
makeToggle(pSpeed, "Только при спринте", Cfg.SpeedHack.SprintOnly, function(v) Cfg.SpeedHack.SprintOnly = v end, 7)
makeToggle(pSpeed, "Авто-прыжок", Cfg.SpeedHack.AutoJump, function(v) Cfg.SpeedHack.AutoJump = v end, 8)

-- BunnyHop
local pBhop = createTab("BunnyHop")
makeSection(pBhop, "Основные", 1)
makeToggle(pBhop, "Включить BunnyHop", Cfg.BunnyHop.Enabled, function(v)
    Cfg.BunnyHop.Enabled = v
    refreshBunnyHop()
end, 2)
makeSlider(pBhop, "Сила прыжка", 20, 200, Cfg.BunnyHop.Power, function(v) Cfg.BunnyHop.Power = v end, 3, true)
makeSection(pBhop, "Поведение", 4)
makeToggle(pBhop, "Только на земле", Cfg.BunnyHop.OnlyOnGround, function(v) Cfg.BunnyHop.OnlyOnGround = v end, 5)
makeToggle(pBhop, "Держать пробел", Cfg.BunnyHop.HoldKey, function(v) Cfg.BunnyHop.HoldKey = v end, 6)
makeToggle(pBhop, "Авто-стрэйф", Cfg.BunnyHop.AutoStrafe, function(v) Cfg.BunnyHop.AutoStrafe = v end, 7)
makeSlider(pBhop, "Сила стрэйфа", 10, 100, Cfg.BunnyHop.StrafePower, function(v) Cfg.BunnyHop.StrafePower = v end, 8, true)

-- GodMode
local pGod = createTab("GodMode")
makeSection(pGod, "Основные", 1)
makeToggle(pGod, "Включить", Cfg.GodMode.Enabled, function(v)
    Cfg.GodMode.Enabled = v
    if not v then stopGodMode() end
end, 2)
makeSlider(pGod, "Max Health", 100, 10000000, Cfg.GodMode.MaxHealth, function(v) Cfg.GodMode.MaxHealth = v end, 3, true)
makeSection(pGod, "Дополнительно", 4)
makeToggle(pGod, "Авто-респавн", Cfg.GodMode.AutoRespawn, function(v) Cfg.GodMode.AutoRespawn = v end, 5)

-- Spinner
local pSpin = createTab("Spinner")
makeSection(pSpin, "Основные", 1)
makeToggle(pSpin, "Включить", Cfg.Spinner.Enabled, function(v)
    Cfg.Spinner.Enabled = v
    if not v then stopSpinner() end
end, 2)
makeSlider(pSpin, "Скорость (град/сек)", 30, 3000, Cfg.Spinner.Speed, function(v) Cfg.Spinner.Speed = v end, 3, true)
makeChips(pSpin, "Режим", { "Character", "Camera", "Both" }, Cfg.Spinner.Mode, function(v) Cfg.Spinner.Mode = v end, 4)
makeChips(pSpin, "Ось", { "X", "Y", "Z", "XYZ" }, Cfg.Spinner.Axis, function(v) Cfg.Spinner.Axis = v end, 5)
makeChips(pSpin, "Направление", { "CW", "CCW" }, Cfg.Spinner.Direction, function(v) Cfg.Spinner.Direction = v end, 6)
makeSection(pSpin, "Дополнительно", 7)
makeToggle(pSpin, "Подпрыгивание", Cfg.Spinner.Bobbing, function(v) Cfg.Spinner.Bobbing = v end, 8)
makeSlider(pSpin, "Высота", 0.5, 10, Cfg.Spinner.BobHeight, function(v) Cfg.Spinner.BobHeight = v end, 9)
makeSlider(pSpin, "Скорость", 1, 30, Cfg.Spinner.BobSpeed, function(v) Cfg.Spinner.BobSpeed = v end, 10, true)

-- Fling
local pFling = createTab("Fling")
makeSection(pFling, "Основные", 1)
makeToggle(pFling, "Включить", Cfg.Fling.Enabled, function(v) Cfg.Fling.Enabled = v end, 2)
makeChips(pFling, "Метод", { "Impulse", "Velocity" }, Cfg.Fling.Method, function(v) Cfg.Fling.Method = v end, 3)
makeChips(pFling, "Цель", { "All", "Nearest", "Cursor", "Player" }, Cfg.Fling.Target, function(v) Cfg.Fling.Target = v end, 4)
makeTextBox(pFling, "Имя цели (Player)", Cfg.Fling.TargetName, function(v) Cfg.Fling.TargetName = v end, 5)
makeSlider(pFling, "Радиус", 3, 50, Cfg.Fling.Range, function(v) Cfg.Fling.Range = v end, 6, true)
makeSlider(pFling, "Мощность", 100, 5000, Cfg.Fling.Power, function(v) Cfg.Fling.Power = v end, 7, true)
makeSection(pFling, "Авто", 8)
makeToggle(pFling, "Авто-повтор", Cfg.Fling.AutoRepeat, function(v) Cfg.Fling.AutoRepeat = v end, 9)
makeSlider(pFling, "Интервал", 0.1, 3, Cfg.Fling.Interval, function(v) Cfg.Fling.Interval = v end, 10)
makeToggle(pFling, "Удерживать клавишу (F)", Cfg.Fling.HoldToFling, function(v) Cfg.Fling.HoldToFling = v end, 11)
makeSection(pFling, "Фильтры", 12)
makeToggle(pFling, "Не флингать союзников", Cfg.Fling.TeamCheck, function(v) Cfg.Fling.TeamCheck = v end, 13)
makeToggle(pFling, "Игнор лежачих", Cfg.Fling.IgnoreDowned, function(v) Cfg.Fling.IgnoreDowned = v end, 14)

-- AntiFling
local pAnti = createTab("AntiFling")
makeSection(pAnti, "Основные", 1)
makeToggle(pAnti, "Включить AntiFling", Cfg.AntiFling.Enabled, function(v)
    Cfg.AntiFling.Enabled = v; refreshAntiFling()
end, 2)
makeChips(pAnti, "Метод", { "Collide", "Freeze", "Reset" }, Cfg.AntiFling.Method, function(v) Cfg.AntiFling.Method = v end, 3)
makeSlider(pAnti, "Макс. скорость", 50, 1000, Cfg.AntiFling.MaxVelocity, function(v) Cfg.AntiFling.MaxVelocity = v end, 4, true)
makeSection(pAnti, "Дополнительно", 5)
makeToggle(pAnti, "Авто-сброс позиции", Cfg.AntiFling.AutoReset, function(v) Cfg.AntiFling.AutoReset = v end, 6)

-- HitSound
local pHit = createTab("HitSound")
makeSection(pHit, "Основные", 1)
makeToggle(pHit, "Включить HitSound", Cfg.HitSound.Enabled, function(v)
    Cfg.HitSound.Enabled = v; refreshHitSound()
end, 2)
makeSlider(pHit, "Громкость", 0, 1, Cfg.HitSound.Volume, function(v) Cfg.HitSound.Volume = v end, 3)
makeSlider(pHit, "Громкость хедшота", 0, 1, Cfg.HitSound.HeadshotVolume, function(v) Cfg.HitSound.HeadshotVolume = v end, 4)
makeSection(pHit, "Звуки", 5)
makeTextBox(pHit, "Sound ID", Cfg.HitSound.SoundId, function(v) Cfg.HitSound.SoundId = v end, 6)
makeTextBox(pHit, "Headshot Sound ID", Cfg.HitSound.HeadshotSoundId, function(v) Cfg.HitSound.HeadshotSoundId = v end, 7)

-- Wallbang
local pWall = createTab("Wallbang")
makeSection(pWall, "Основные", 1)
makeToggle(pWall, "Включить Wallbang", Cfg.Wallbang.Enabled, function(v) Cfg.Wallbang.Enabled = v end, 2)
makeSlider(pWall, "Макс. толщина стены", 0.5, 20, Cfg.Wallbang.MaxThickness, function(v) Cfg.Wallbang.MaxThickness = v end, 3)
makeSlider(pWall, "Макс. дистанция", 100, 2000, Cfg.Wallbang.MaxDistance, function(v) Cfg.Wallbang.MaxDistance = v end, 4, true)
makeSection(pWall, "Фильтры", 5)
makeToggle(pWall, "Только тонкие стены", Cfg.Wallbang.VisibleOnly, function(v) Cfg.Wallbang.VisibleOnly = v end, 6)
makeToggle(pWall, "Проверка команды", Cfg.Wallbang.TeamCheck, function(v) Cfg.Wallbang.TeamCheck = v end, 7)
makeSection(pWall, "Применение", 8)
makeToggle(pWall, "Silent Aim сквозь стены", Cfg.SilentAim.Wallbang, function(v) Cfg.SilentAim.Wallbang = v end, 9)

-- Shader
local pShader = createTab("Shader")
makeSection(pShader, "Основные", 1)
makeToggle(pShader, "Включить Shader", Cfg.Shader.Enabled, function(v)
    Cfg.Shader.Enabled = v
    if v then applyShaderPreset(Cfg.Shader.Preset)
    else disableShader() end
end, 2)
makeChips(pShader, "Пресет", { "Cinematic", "Neon", "Pastel", "Dark", "Custom" }, Cfg.Shader.Preset, function(v)
    Cfg.Shader.Preset = v
    if Cfg.Shader.Enabled then applyShaderPreset(v) end
end, 3)

makeSection(pShader, "Bloom", 4)
makeSlider(pShader, "Интенсивность", 0, 5, Cfg.Shader.BloomIntensity, function(v) Cfg.Shader.BloomIntensity = v end, 5)
makeSlider(pShader, "Размер", 0, 56, Cfg.Shader.BloomSize, function(v) Cfg.Shader.BloomSize = v end, 6, true)
makeSlider(pShader, "Порог", 0, 2, Cfg.Shader.BloomThreshold, function(v) Cfg.Shader.BloomThreshold = v end, 7)

makeSection(pShader, "Color Correction", 8)
makeSlider(pShader, "Яркость", -0.5, 0.5, Cfg.Shader.ColorBrightness, function(v) Cfg.Shader.ColorBrightness = v end, 9)
makeSlider(pShader, "Контраст", -0.5, 0.5, Cfg.Shader.ColorContrast, function(v) Cfg.Shader.ColorContrast = v end, 10)
makeSlider(pShader, "Насыщенность", -0.5, 1, Cfg.Shader.ColorSaturation, function(v) Cfg.Shader.ColorSaturation = v end, 11)
makeColorPicker(pShader, "Тинт", Cfg.Shader.ColorTint, function(c) Cfg.Shader.ColorTint = c end, 12)

makeSection(pShader, "Sun Rays", 13)
makeSlider(pShader, "Интенсивность", 0, 1, Cfg.Shader.SunRaysIntensity, function(v) Cfg.Shader.SunRaysIntensity = v end, 14)
makeSlider(pShader, "Распространение", 0.5, 2, Cfg.Shader.SunRaysSpread, function(v) Cfg.Shader.SunRaysSpread = v end, 15)

makeSection(pShader, "Depth of Field", 16)
makeSlider(pShader, "Дистанция фокуса", 5, 100, Cfg.Shader.DOFFocusDistance, function(v) Cfg.Shader.DOFFocusDistance = v end, 17, true)
makeSlider(pShader, "Радиус фокуса", 0, 50, Cfg.Shader.DOFInFocusRadius, function(v) Cfg.Shader.DOFInFocusRadius = v end, 18, true)
makeSlider(pShader, "Сила блюра", 0, 20, Cfg.Shader.DOFBlurSize, function(v) Cfg.Shader.DOFBlurSize = v end, 19)

makeSection(pShader, "Atmosphere", 20)
makeSlider(pShader, "Плотность", 0, 1, Cfg.Shader.AtmosphereDensity, function(v) Cfg.Shader.AtmosphereDensity = v end, 21)
makeSlider(pShader, "Смещение", 0, 1, Cfg.Shader.AtmosphereOffset, function(v) Cfg.Shader.AtmosphereOffset = v end, 22)
makeColorPicker(pShader, "Цвет", Cfg.Shader.AtmosphereColor, function(c) Cfg.Shader.AtmosphereColor = c end, 23)

makeSection(pShader, "Lighting", 24)
makeSlider(pShader, "Яркость", 0, 5, Cfg.Shader.Brightness, function(v) Cfg.Shader.Brightness = v end, 25)
makeSlider(pShader, "Время суток", 0, 24, Cfg.Shader.ClockTime, function(v) Cfg.Shader.ClockTime = v end, 26, true)
makeSlider(pShader, "Fog End", 100, 5000, Cfg.Shader.FogEnd, function(v) Cfg.Shader.FogEnd = v end, 27, true)
makeColorPicker(pShader, "Ambient", Cfg.Shader.Ambient, function(c) Cfg.Shader.Ambient = c end, 28)
makeColorPicker(pShader, "Outdoor Ambient", Cfg.Shader.OutdoorAmbient, function(c) Cfg.Shader.OutdoorAmbient = c end, 29)
makeColorPicker(pShader, "Fog Color", Cfg.Shader.FogColor, function(c) Cfg.Shader.FogColor = c end, 30)

-- ==================== СВОРАЧИВАНИЕ ====================
local normalSize = UDim2.new(0, WIN_W, 0, WIN_H)
local miniSize   = UDim2.new(0, WIN_W, 0, 56)
local minimized  = false

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Tween:Create(win, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = minimized and miniSize or normalSize,
    }):Play()
    body.Visible = not minimized
    minBtn.Text = minimized and "O" or "-"
end)

-- ==================== ВЫГРУЗКА ====================
local function unloadScript()
    if unloaded then return end
    unloaded = true
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    for _, fn in ipairs(cleanupFns) do pcall(fn) end
    cleanupFns = {}
    pcall(function() gui:Destroy() end)
    pcall(function() overlay:Destroy() end)
    saveQueued = true
end

closeBtn.MouseButton1Click:Connect(function() unloadScript() end)

UIS.InputBegan:Connect(function(input, gp)
    if unloaded then return end
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
        overlay.Enabled = gui.Enabled
    end
end)

-- ==================== ИНИЦИАЛИЗАЦИЯ ====================
rebuildCrosshair()
updateAllHighlights()
setFullbright(Cfg.Visuals.Fullbright)
if Cfg.Hitbox.Enabled then refreshHitboxes() end
if Cfg.BunnyHop.Enabled then refreshBunnyHop() end
if Cfg.HitSound.Enabled then refreshHitSound() end
if Cfg.AntiFling.Enabled then refreshAntiFling() end
if Cfg.Shader.Enabled then applyShaderPreset(Cfg.Shader.Preset) end
task.defer(refreshSidebar)

print("[BogdanWare] Загружен успешно! RightControl — меню, X — выгрузить")
