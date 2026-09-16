-- ═══════════════════════════════════════════════════════════════
--   BogdanWare  ·  Sakura Edition
--   RightControl — меню   |   X — выгрузить скрипт полностью
-- ═══════════════════════════════════════════════════════════════

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Tween       = game:GetService("TweenService")
local Lighting    = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

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
        Enabled = true,
        FillColor = Color3.fromRGB(255, 158, 196),
        OutlineColor = Color3.fromRGB(255, 232, 242),
        FillTransparency = 0.55,
        OutlineTransparency = 0,
        ShowInfo = false,
        TeamCheck = false,
    },
    Aimbot = {
        Enabled = false,
        FOV = 220,
        Smoothness = 0.2,
        ShowFOV = true,
        FOVColor = Color3.fromRGB(216, 167, 232),
        TargetPart = "Head",
        VisibleOnly = false,
        HoldKey = true,
        Key = Enum.UserInputType.MouseButton2,
        ShowTargetLine = false,
        TargetLineColor = Color3.fromRGB(255, 158, 196),
    },
    Trigger = { Enabled = false, Delay = 0.05, VisibleOnly = true },
    Hitbox  = { Enabled = false, Scale = 2 },
    Fly     = { Enabled = false, Speed = 60, Noclip = true },
    Noclip  = { Enabled = false },
    Visuals = {
        Crosshair = true,
        CrosshairColor = Color3.fromRGB(255, 158, 196),
        CrosshairStyle = "Cross",
        Fullbright = false,
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
    if not pcall(isfile, SAVE_FILE) then return end
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
        saveConfig()
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
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function stroke(p, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(120, 80, 110)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function grad(p, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 0
    g.Parent = p
    return g
end

local function neon(p, color)
    return stroke(p, color, 1.5, 0.25)
end

-- ═════════ ПЛАВНЫЕ АНИМАЦИИ ═════════
local SOFT   = TweenInfo.new(0.35, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.5,  Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local GENTLE = TweenInfo.new(0.6,  Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)
local PRESS  = TweenInfo.new(0.2,  Enum.EasingStyle.Sine,  Enum.EasingDirection.Out)

local function addHover(btn, normalBg, hoverBg)
    local baseSize = btn.Size
    local basePos = btn.Position

    btn.MouseEnter:Connect(function()
        Tween:Create(btn, SMOOTH, {
            BackgroundColor3 = hoverBg or btn.BackgroundColor3,
            Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset, baseSize.Y.Scale, baseSize.Y.Offset + 2),
            Position = UDim2.new(basePos.X.Scale, basePos.X.Offset, basePos.Y.Scale, basePos.Y.Offset - 2),
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        Tween:Create(btn, SMOOTH, {
            BackgroundColor3 = normalBg or btn.BackgroundColor3,
            Size = baseSize,
            Position = basePos,
        }):Play()
    end)
end

local function addPress(btn)
    btn.MouseButton1Down:Connect(function()
        Tween:Create(btn, PRESS, {
            Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset - 2,
                             btn.Size.Y.Scale, btn.Size.Y.Offset - 2),
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        Tween:Create(btn, SMOOTH, {
            Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset + 2,
                             btn.Size.Y.Scale, btn.Size.Y.Offset + 2),
        }):Play()
    end)
end

-- ═════════ МЕДЛЕННЫЙ ПЛАВНЫЙ RIPPLE ═════════
local function addRipple(btn)
    connect(btn.MouseButton1Click, function()
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        r.BackgroundTransparency = 0.55
        r.BorderSizePixel = 0
        r.Size = UDim2.new(0, 0, 0, 0)
        r.Position = UDim2.new(0.5, 0, 0.5, 0)
        r.ZIndex = (btn.ZIndex or 1) + 5
        r.Parent = btn
        corner(r, 999)
        Tween:Create(r, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, btn.AbsoluteSize.X * 2.4, 0, btn.AbsoluteSize.Y * 2.4),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(1.05, function()
            pcall(function() r:Destroy() end)
        end)
    end)
end

local function colorEq(a, b)
    return math.abs(a.R-b.R) < 0.05 and math.abs(a.G-b.G) < 0.05 and math.abs(a.B-b.B) < 0.05
end

-- ═════════ РОЗОВАЯ ПАЛИТРА (САКУРА) ═════════
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

local WIN_W, WIN_H = 680, 500

local win = mk("Frame", {
    Name = "Main",
    Size = UDim2.new(0, WIN_W * 0.94, 0, WIN_H * 0.94),
    Position = UDim2.new(0.5, -WIN_W * 0.47, 0.5, -WIN_H * 0.47),
    BackgroundColor3 = BG_DARK,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true,
}, gui)
corner(win, 16)
neon(win, ACCENT_1)

Tween:Create(win, GENTLE, {
    Size = UDim2.new(0, WIN_W, 0, WIN_H),
    Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
}):Play()

-- ═════════ ФОН: САКУРА ═════════
local SAKURA_IDS = {
    "rbxassetid://84371640174947",
    "rbxassetid://102084406020002",
    "rbxassetid://15053053722",
    "rbxassetid://15591461393",
}

local bgBack = mk("Frame", {
    Name = "BackgroundBack",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(60, 36, 58),
    BorderSizePixel = 0,
    ZIndex = 0,
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

local bgImage = mk("ImageLabel", {
    Name = "BackgroundImage",
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Image = SAKURA_IDS[1],
    ImageTransparency = 0,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 1,
}, win)
corner(bgImage, 16)

task.spawn(function()
    for _, id in ipairs(SAKURA_IDS) do
        if unloaded then return end
        bgImage.Image = id
        task.wait(1.2)
        if bgImage.IsLoaded then
            return
        end
    end
    bgImage.ImageTransparency = 1
end)

local bgOverlay = mk("Frame", {
    Name = "BackgroundOverlay",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(42, 26, 40),
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    ZIndex = 2,
}, win)
corner(bgOverlay, 16)

local bgGrad = Instance.new("UIGradient")
bgGrad.Rotation = 90
bgGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.4),
    NumberSequenceKeypoint.new(0.5, 0.6),
    NumberSequenceKeypoint.new(1, 0.9),
})
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 26, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 45, 76)),
})
bgGrad.Parent = bgOverlay

-- ==================== HEADER ====================
local header = mk("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = Color3.fromRGB(52, 30, 50),
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 5,
}, win)
corner(header, 16)
mk("Frame", {
    Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = Color3.fromRGB(52, 30, 50),
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0, ZIndex = 5,
}, header)

-- ═════════ ПЕРЕЛИВАЮЩАЯСЯ НАДПИСЬ (РОЗОВО-ФИОЛЕТОВАЯ) ═════════
local titleLabel = mk("TextLabel", {
    Size = UDim2.new(1, -200, 1, 0),
    Position = UDim2.new(0, 22, 0, 0),
    BackgroundTransparency = 1,
    Text = "BOGDANWARE",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBlack,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 6,
}, header)

-- Розово-фиолетовый градиент в цвет интерфейса
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 158, 196)),  -- нежно-розовый
    ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 179, 198)),  -- персиково-розовый
    ColorSequenceKeypoint.new(0.40, Color3.fromRGB(240, 130, 180)),  -- малиново-розовый
    ColorSequenceKeypoint.new(0.60, Color3.fromRGB(216, 167, 232)),  -- лаванда
    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(180, 140, 220)),  -- фиолетово-розовый
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 158, 196)),  -- снова нежно-розовый
})
titleGradient.Rotation = 0
titleGradient.Offset = Vector2.new(0, 0)
titleGradient.Parent = titleLabel

-- Бесконечная анимация перелива
task.spawn(function()
    local offset = 0
    while not unloaded do
        task.wait(0.03)
        offset = (offset + 0.006) % 1
        titleGradient.Offset = Vector2.new(offset, 0)
    end
end)

-- Мягкое свечение вокруг текста
local titleGlow = Instance.new("UIStroke")
titleGlow.Color = Color3.fromRGB(255, 180, 220)
titleGlow.Thickness = 1
titleGlow.Transparency = 0.7
titleGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
titleGlow.Parent = titleLabel

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
    Font = Enum.Font.Code,
    TextSize = 11,
    ZIndex = 7,
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
        BackgroundTransparency = 0.25,
        Text = txt,
        TextColor3 = Color3.fromRGB(120, 60, 100),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        AutoButtonColor = false,
        ZIndex = 6,
    }, header)
    corner(b, 8)
    stroke(b, accent, 1, 0.2)

    local baseSize = b.Size
    local basePos = b.Position
    b.MouseEnter:Connect(function()
        Tween:Create(b, SMOOTH, {
            BackgroundTransparency = 0,
            BackgroundColor3 = accent,
            TextColor3 = Color3.fromRGB(80, 30, 60),
            Size = UDim2.new(0, 33, 0, 33),
            Position = UDim2.new(1, xOff - 0.5, 0.5, -16.5),
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        Tween:Create(b, SMOOTH, {
            BackgroundTransparency = 0.25,
            BackgroundColor3 = Color3.fromRGB(255, 235, 245),
            TextColor3 = Color3.fromRGB(120, 60, 100),
            Size = baseSize,
            Position = basePos,
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
    Name = "Body",
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundTransparency = 1, ZIndex = 5,
}, win)

local sidebar = mk("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 175, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(48, 28, 46),
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 5,
    Active = true,
}, body)

local sideBarLine = mk("Frame", {
    Size = UDim2.new(0, 2, 1, -20),
    Position = UDim2.new(1, -2, 0, 10),
    BackgroundColor3 = ACCENT_1,
    BorderSizePixel = 0, ZIndex = 6,
}, sidebar)
grad(sideBarLine, ACCENT_1, ACCENT_2, 90)

local searchFrame = mk("Frame", {
    Size = UDim2.new(1, -24, 0, 34),
    Position = UDim2.new(0, 12, 0, 14),
    BackgroundColor3 = Color3.fromRGB(60, 36, 58),
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 6,
}, sidebar)
corner(searchFrame, 8)
local searchStroke = stroke(searchFrame, ACCENT_2, 1, 0.4)

local searchBox = mk("TextBox", {
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    PlaceholderText = "Search...",
    PlaceholderColor3 = Color3.fromRGB(190, 140, 170),
    TextColor3 = TEXT_MAIN,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 7,
}, searchFrame)

searchBox.Focused:Connect(function()
    Tween:Create(searchStroke, SOFT, { Color = ACCENT_1, Thickness = 2 }):Play()
    Tween:Create(searchFrame, SMOOTH, {
        Size = UDim2.new(1, -22, 0, 36),
        Position = UDim2.new(0, 11, 0, 13),
    }):Play()
end)
searchBox.FocusLost:Connect(function()
    Tween:Create(searchStroke, SOFT, { Color = ACCENT_2, Thickness = 1 }):Play()
    Tween:Create(searchFrame, SMOOTH, {
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.new(0, 12, 0, 14),
    }):Play()
end)

local content = mk("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -190, 1, -20),
    Position = UDim2.new(0, 180, 0, 10),
    BackgroundTransparency = 1,
    ClipsDescendants = true, ZIndex = 6,
}, body)

-- ==================== ВКЛАДКИ ====================
local pages, tabButtons = {}, {}
local currentTab
local tabIndex = 0
local TAB_Y_START = 60
local TAB_H = 36
local TAB_GAP = 8

local function refreshCanvas(page)
    local layout = page:FindFirstChildOfClass("UIListLayout")
    if layout then
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end
end

local function selectTab(name)
    if not pages[name] then return end
    if currentTab == name then return end
    currentTab = name
    for n, p in pairs(pages) do
        p.Visible = (n == name)
        if n == name then
            task.defer(function() refreshCanvas(p) end)
        end
    end
    for n, b in pairs(tabButtons) do
        local active = (n == name)
        pcall(function()
            Tween:Create(b, SMOOTH, {
                BackgroundColor3 = active and ACCENT_1 or Color3.fromRGB(56, 32, 54),
                BackgroundTransparency = active and 0.1 or 0.5,
                TextColor3 = active and Color3.fromRGB(80, 30, 60) or TEXT_DIM,
                Size = active and UDim2.new(1, -20, 0, TAB_H) or UDim2.new(1, -24, 0, TAB_H),
            }):Play()
            local s = b:FindFirstChildOfClass("UIStroke")
            if s then
                Tween:Create(s, SOFT, { Transparency = active and 0 or 0.9 }):Play()
            end
        end)
    end
end

local function createTab(name)
    local page = mk("ScrollingFrame", {
        Name = "Page_" .. name,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = ACCENT_1,
        ScrollBarImageTransparency = 0.2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false, ZIndex = 7,
        ClipsDescendants = true,
    }, content)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
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

    local y = TAB_Y_START + tabIndex * (TAB_H + TAB_GAP)
    tabIndex = tabIndex + 1

    local btn = mk("TextButton", {
        Name = "Tab_" .. name,
        Size = UDim2.new(1, -24, 0, TAB_H),
        Position = UDim2.new(0, 12, 0, y),
        BackgroundColor3 = Color3.fromRGB(56, 32, 54),
        BackgroundTransparency = 0.5,
        Text = "  " .. name,
        TextColor3 = TEXT_DIM,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Active = true,
        Selectable = true,
        ZIndex = 7,
    }, sidebar)
    corner(btn, 8)
    stroke(btn, ACCENT_1, 1, 0.9)
    tabButtons[name] = btn

    btn.MouseEnter:Connect(function()
        if currentTab == name then return end
        Tween:Create(btn, SMOOTH, {
            BackgroundColor3 = BG_HOVER,
            BackgroundTransparency = 0.2,
            Size = UDim2.new(1, -22, 0, TAB_H),
            Position = UDim2.new(0, 11, 0, y),
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        if currentTab == name then return end
        Tween:Create(btn, SMOOTH, {
            BackgroundColor3 = Color3.fromRGB(56, 32, 54),
            BackgroundTransparency = 0.5,
            Size = UDim2.new(1, -24, 0, TAB_H),
            Position = UDim2.new(0, 12, 0, y),
        }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)

    if not currentTab then
        currentTab = name
        page.Visible = true
        btn.BackgroundColor3 = ACCENT_1
        btn.BackgroundTransparency = 0.1
        btn.TextColor3 = Color3.fromRGB(80, 30, 60)
        btn.Size = UDim2.new(1, -20, 0, TAB_H)
        local s = btn:FindFirstChildOfClass("UIStroke")
        if s then s.Transparency = 0 end
    end

    return page
end

connect(searchBox:GetPropertyChangedSignal("Text"), function()
    local q = string.lower(searchBox.Text)
    local page = pages[currentTab]
    if not page then return end
    for _, child in ipairs(page:GetChildren()) do
        if (child:IsA("Frame") or child:IsA("TextButton"))
           and not child:IsA("UIListLayout")
           and not child:IsA("UIPadding") then
            local label = child:FindFirstChildOfClass("TextLabel")
            if label then
                child.Visible = (q == "" or string.find(string.lower(label.Text), q, 1, true) ~= nil)
            end
        end
    end
end)

-- ==================== КОМПОНЕНТЫ ====================
local function makeSection(parent, title, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    mk("Frame", {
        Size = UDim2.new(0, 3, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = ACCENT_1,
        BorderSizePixel = 0, ZIndex = 8,
    }, row)
    mk("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = ACCENT_1,
        Font = Enum.Font.GothamBlack,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8,
    }, row)
end

local function makeToggle(parent, label, default, callback, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = BG_CARD,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    corner(row, 10)
    local rowStroke = stroke(row, ACCENT_1, 1, 1)

    mk("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 8,
    }, row)

    local track = mk("Frame", {
        Size = UDim2.new(0, 46, 0, 24),
        Position = UDim2.new(1, -62, 0.5, -12),
        BackgroundColor3 = default and ACCENT_1 or Color3.fromRGB(70, 44, 68),
        BorderSizePixel = 0, ZIndex = 8,
    }, row)
    corner(track, 12)

    local knob = mk("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(255, 245, 250),
        BorderSizePixel = 0, ZIndex = 9,
    }, track)
    corner(knob, 9)

    local hit = mk("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 10,
    }, row)

    local state = default
    local baseSize = row.Size
    local basePos = row.Position

    local KNOB_TWEEN = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local TRACK_TWEEN = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    local function set(v, animate)
        state = v
        Tween:Create(knob, KNOB_TWEEN, {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        }):Play()
        Tween:Create(track, TRACK_TWEEN, {
            BackgroundColor3 = state and ACCENT_1 or Color3.fromRGB(70, 44, 68),
        }):Play()
        if animate ~= false then
            Tween:Create(row, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -4, 0, 42),
            }):Play()
            task.delay(0.15, function()
                Tween:Create(row, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = baseSize }):Play()
            end)
        end
    end

    hit.MouseButton1Click:Connect(function()
        set(not state)
        if callback then callback(state) end
        queueSave()
    end)

    hit.MouseEnter:Connect(function()
        Tween:Create(row, SMOOTH, {
            BackgroundColor3 = BG_HOVER,
            BackgroundTransparency = 0,
            Size = UDim2.new(1, -2, 0, 44),
            Position = UDim2.new(0, 1, 0, basePos.Y.Offset - 1),
        }):Play()
        Tween:Create(rowStroke, SOFT, { Transparency = 0.4 }):Play()
    end)
    hit.MouseLeave:Connect(function()
        Tween:Create(row, SMOOTH, {
            BackgroundColor3 = BG_CARD,
            BackgroundTransparency = 0.15,
            Size = baseSize,
            Position = basePos,
        }):Play()
        Tween:Create(rowStroke, SOFT, { Transparency = 1 }):Play()
    end)
    addRipple(hit)

    return { set = set, get = function() return state end }
end

local function makeSlider(parent, label, minVal, maxVal, default, callback, order, isInt)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = BG_CARD,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0, LayoutOrder = order or 0, ZIndex = 7,
    }, parent)
    corner(row, 10)
    local rowStroke = stroke(row, ACCENT_2, 1, 1)

    local labelObj = mk("TextLabel", {
        Size = UDim2.new(1, -28, 0, 18),
        Position = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1,
        Text = label .. "   " .. (isInt and tostring(math.floor(default)) or string.format("%.2f", default)),
        TextColor3 = TEXT_MAIN,
        Font = Enum.Font.GothamMedium,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
    }, row)

    local bar = mk("Frame", {
        Size = UDim2.new(1, -32, 0, 6),
        Position = UDim2.new(0, 16, 0, 36),
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
        BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 11,
    }, bar)

    local dragging = false
    local baseSize = row.Size
    local basePos = row.Position

    local function update(input)
        local relX = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local value = minVal + (maxVal - minVal) * relX
        if isInt then value = math.floor(value + 0.5) end
        Tween:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Sine), { Size = UDim2.new(relX, 0, 1, 0) }):Play()
        knob.Position = UDim2.new(relX, -8, 0.5, -8)
        labelObj.Text = label .. "   " .. (isInt and tostring(value) or string.format("%.2f", value))
        if callback then callback(value) end
        queueSave()
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Tween:Create(knob, SMOOTH, {
                Size = UDim2.new(0, 22, 0, 22),
                Position = UDim2.new(knob.Position.X.Scale, -11, 0.5, -11),
            }):Play()
            Tween:Create(bar, SOFT, { Size = UDim2.new(1, -32, 0, 8) }):Play()
            update(input)
        end
    end)
    connect(UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                Tween:Create(knob, SMOOTH, {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(knob.Position.X.Scale, -8, 0.5, -8),
                }):Play()
                Tween:Create(bar, SOFT, { Size = UDim2.new(1, -32, 0, 6) }):Play()
            end
        end
    end)
    connect(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    hit.MouseEnter:Connect(function()
        Tween:Create(row, SMOOTH, {
            BackgroundColor3 = BG_HOVER,
            BackgroundTransparency = 0,
            Size = UDim2.new(1, -2, 0, 60),
            Position = UDim2.new(0, 1, 0, basePos.Y.Offset - 1),
        }):Play()
        Tween:Create(rowStroke, SOFT, { Transparency = 0.4 }):Play()
    end)
    hit.MouseLeave:Connect(function()
        Tween:Create(row, SMOOTH, {
            BackgroundColor3 = BG_CARD,
            BackgroundTransparency = 0.15,
            Size = baseSize,
            Position = basePos,
        }):Play()
        Tween:Create(rowStroke, SOFT, { Transparency = 1 }):Play()
    end)
end

local function makeChips(parent, label, options, default, callback, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = BG_CARD,
        BackgroundTransparency = 0.15,
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
        Size = UDim2.new(1, -28, 0, 28),
        Position = UDim2.new(0, 14, 0, 28),
        BackgroundTransparency = 1, ZIndex = 8,
    }, row)
    local stripLayout = Instance.new("UIListLayout")
    stripLayout.FillDirection = Enum.FillDirection.Horizontal
    stripLayout.Padding = UDim.new(0, 6)
    stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
    stripLayout.Parent = strip

    local current = default
    local chips = {}
    local CHIP_W = 80

    for _, opt in ipairs(options) do
        local c = mk("TextButton", {
            Size = UDim2.new(0, CHIP_W, 1, 0),
            BackgroundColor3 = (opt == current) and ACCENT_1 or Color3.fromRGB(70, 44, 68),
            Text = opt,
            TextColor3 = (opt == current) and Color3.fromRGB(80, 30, 60) or TEXT_DIM,
            Font = Enum.Font.GothamBold, TextSize = 11,
            AutoButtonColor = false, ZIndex = 9,
        }, strip)
        corner(c, 6)
        if opt == current then stroke(c, ACCENT_1, 1.5, 0.25) end
        chips[opt] = c

        local baseSize = c.Size

        addRipple(c)
        c.MouseButton1Click:Connect(function()
            current = opt
            for name, chip in pairs(chips) do
                local active = (name == opt)
                Tween:Create(chip, SMOOTH, {
                    BackgroundColor3 = active and ACCENT_1 or Color3.fromRGB(70, 44, 68),
                    TextColor3 = active and Color3.fromRGB(80, 30, 60) or TEXT_DIM,
                    Size = baseSize,
                }):Play()
            end
            if callback then callback(opt) end
            queueSave()
        end)
        c.MouseEnter:Connect(function()
            if opt ~= current then
                Tween:Create(c, SMOOTH, {
                    BackgroundColor3 = Color3.fromRGB(90, 58, 86),
                    Size = UDim2.new(0, CHIP_W + 4, 1, 0),
                }):Play()
            end
        end)
        c.MouseLeave:Connect(function()
            if opt ~= current then
                Tween:Create(c, SMOOTH, {
                    BackgroundColor3 = Color3.fromRGB(70, 44, 68),
                    Size = baseSize,
                }):Play()
            end
        end)
        c.MouseButton1Down:Connect(function()
            Tween:Create(c, PRESS, {
                Size = UDim2.new(0, CHIP_W - 4, 1, 0),
            }):Play()
        end)
        c.MouseButton1Up:Connect(function()
            Tween:Create(c, SMOOTH, { Size = baseSize }):Play()
        end)
    end
    return { get = function() return current end }
end

local COLOR_PRESETS = {
    Color3.fromRGB(255, 158, 196),
    Color3.fromRGB(255, 179, 198),
    Color3.fromRGB(216, 167, 232),
    Color3.fromRGB(255, 200, 220),
    Color3.fromRGB(240, 130, 180),
    Color3.fromRGB(255, 220, 180),
    Color3.fromRGB(180, 140, 220),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(200, 170, 200),
    Color3.fromRGB(90, 50, 90),
}

local function makeColorPicker(parent, label, default, callback, order)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = BG_CARD,
        BackgroundTransparency = 0.15,
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
            Size = UDim2.new(0, 26, 1, 0),
            BackgroundColor3 = c, Text = "",
            AutoButtonColor = false, ZIndex = 9,
        }, strip)
        corner(sw, 6)
        local s = stroke(sw, Color3.fromRGB(255, 232, 242), 2,
            colorEq(c, default) and 0 or 0.85)
        swatches[sw] = s

        addRipple(sw)
        sw.MouseButton1Click:Connect(function()
            for _, os in pairs(swatches) do
                Tween:Create(os, SOFT, { Transparency = 0.85 }):Play()
            end
            Tween:Create(s, SOFT, { Transparency = 0 }):Play()
            Tween:Create(sw, SMOOTH, {
                Size = UDim2.new(0, 32, 1, 0),
                Position = UDim2.new(sw.Position.X.Scale, -3, 0.5, 0),
            }):Play()
            task.delay(0.35, function()
                Tween:Create(sw, SMOOTH, {
                    Size = UDim2.new(0, 26, 1, 0),
                    Position = UDim2.new(sw.Position.X.Scale, 0, 0.5, 0),
                }):Play()
            end)
            if callback then callback(c) end
            queueSave()
        end)
        sw.MouseEnter:Connect(function()
            Tween:Create(sw, SMOOTH, {
                Size = UDim2.new(0, 30, 1, 0.05),
                Position = UDim2.new(sw.Position.X.Scale, -2, 0.5, -0.025),
            }):Play()
        end)
        sw.MouseLeave:Connect(function()
            Tween:Create(sw, SMOOTH, {
                Size = UDim2.new(0, 26, 1, 0),
                Position = UDim2.new(sw.Position.X.Scale, 0, 0.5, 0),
            }):Play()
        end)
    end
end

-- ==================== ESP ====================
local infoTags = {}
local function applyHighlight(char)
    if not char or char == LP.Character then return end
    local h = char:FindFirstChild("PlayerHighlight")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "PlayerHighlight"
        h.Parent = char
    end
    h.FillColor = Cfg.ESP.FillColor
    h.OutlineColor = Cfg.ESP.OutlineColor
    h.FillTransparency = Cfg.ESP.FillTransparency
    h.OutlineTransparency = Cfg.ESP.OutlineTransparency
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = char
    h.Enabled = Cfg.ESP.Enabled
end

local function applyInfoTag(char)
    if not char or char == LP.Character then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local tag = head:FindFirstChild("BogdanInfoTag")
    if not tag then
        local bg = Instance.new("BillboardGui")
        bg.Name = "BogdanInfoTag"
        bg.Size = UDim2.new(0, 180, 0, 40)
        bg.StudsOffset = Vector3.new(0, 2.5, 0)
        bg.AlwaysOnTop = true
        bg.MaxDistance = 500
        bg.Parent = head
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0.5, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(255, 232, 242)
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 14
        lbl.TextStrokeTransparency = 0.3; lbl.Parent = bg
        local dist = Instance.new("TextLabel")
        dist.Size = UDim2.new(1, 0, 0.5, 0)
        dist.Position = UDim2.new(0, 0, 0.5, 0)
        dist.BackgroundTransparency = 1
        dist.TextColor3 = Color3.fromRGB(255, 200, 220)
        dist.Font = Enum.Font.Gotham; dist.TextSize = 12
        dist.TextStrokeTransparency = 0.3; dist.Parent = bg
        infoTags[char] = { bg = bg, name = lbl, dist = dist }
    end
    local data = infoTags[char]
    data.bg.Enabled = Cfg.ESP.ShowInfo
    if Cfg.ESP.ShowInfo then
        local plr = Players:GetPlayerFromCharacter(char)
        if plr then
            data.name.Text = plr.Name
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local hisRoot = char:FindFirstChild("HumanoidRootPart")
            if myRoot and hisRoot then
                data.dist.Text = string.format("%d studs", math.floor((myRoot.Position - hisRoot.Position).Magnitude))
            end
        end
    end
end

local function updateAllHighlights()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            applyHighlight(p.Character)
            applyInfoTag(p.Character)
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
    for _, data in pairs(infoTags) do
        if data.bg then data.bg:Destroy() end
    end
    infoTags = {}
end
onCleanup(clearESP)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        if p.Character then
            applyHighlight(p.Character); applyInfoTag(p.Character)
        end
        p.CharacterAdded:Connect(function(c)
            task.wait(0.5); applyHighlight(c); applyInfoTag(c)
        end)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function(c)
        task.wait(0.5); applyHighlight(c); applyInfoTag(c)
    end)
end)

-- ==================== AIMBOT ====================
local function getAimPart(char)
    if Cfg.Aimbot.TargetPart == "Head" then return char:FindFirstChild("Head")
    elseif Cfg.Aimbot.TargetPart == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
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

local function getTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bd = nil, Cfg.Aimbot.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local skipTeam = Cfg.ESP.TeamCheck and p.Team == LP.Team
            if not skipTeam then
                local part = getAimPart(p.Character)
                if part then
                    local hide = Cfg.Aimbot.VisibleOnly and not isVisible(part)
                    if not hide then
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
    return best
end

local currentTarget = nil
connect(RunService.RenderStepped, function()
    if unloaded then return end
    if not Cfg.Aimbot.Enabled then currentTarget = nil; return end
    if Cfg.Aimbot.HoldKey and not UIS:IsMouseButtonPressed(Cfg.Aimbot.Key) then
        currentTarget = nil; return
    end
    currentTarget = getTarget()
    if currentTarget then
        local targetCF = CFrame.lookAt(Camera.CFrame.Position, currentTarget.Position)
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
    local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local plr = Players:GetPlayerFromCharacter(model)
            if plr and plr ~= LP then
                if Cfg.Trigger.VisibleOnly and not isVisible(result.Instance) then return end
                lastTrigger = tick()
                local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:Button1Down(Vector2.new(center.X, center.Y))
                    vu:Button1Up(Vector2.new(center.X, center.Y))
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
            if not store[part.Name] then
                store[part.Name] = {
                    size = part.Size,
                    transparency = part.Transparency,
                    cancollide = part.CanCollide,
                }
            end
            local target = store[part.Name].size * Cfg.Hitbox.Scale
            if math.abs(part.Size.X - target.X) > 0.01
               or math.abs(part.Size.Y - target.Y) > 0.01
               or math.abs(part.Size.Z - target.Z) > 0.01 then
                pcall(function()
                    part.Size = target
                    part.Transparency = 0.65
                    part.CanCollide = false
                    part.Massless = true
                end)
            end
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
                part.Size = o.size
                part.Transparency = o.transparency
                part.CanCollide = o.cancollide
                part.Massless = false
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
    else
        restoreAllHitboxes()
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function(c)
            task.wait(0.8)
            if Cfg.Hitbox.Enabled and not unloaded then
                expandHitbox(c)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function(c)
        task.wait(0.8)
        if Cfg.Hitbox.Enabled and not unloaded then
            expandHitbox(c)
        end
    end)
end)

task.spawn(function()
    while not unloaded do
        task.wait(1)
        if unloaded then break end
        if Cfg.Hitbox.Enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    expandHitbox(p.Character)
                end
            end
        else
            if next(hitboxOriginal) ~= nil then
                restoreAllHitboxes()
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
    local parts = workspace:GetPartBoundsInRadius(hrp.Position, 5)
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") and not p:IsDescendantOf(char) and p.Name ~= "Terrain" and not p:IsDescendantOf(Camera) then
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
local function getFlyBV(hrp)
    local bv = hrp:FindFirstChild("BogdanFlyBV")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name = "BogdanFlyBV"
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
    end
    return bv
end
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
    local bv = getFlyBV(hrp)
    local camCF = Camera.CFrame
    local moveDir = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * Cfg.Fly.Speed end
    bv.Velocity = moveDir
end)

-- ==================== OVERLAY ====================
local fovFrame = mk("Frame", {
    Name = "FOVCircle", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2,
}, overlay)
corner(fovFrame, 999)
local fovStroke = stroke(fovFrame, Cfg.Aimbot.FOVColor, 1.5, 0.3)

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
    if style == "Dot" then
        local d = mk("Frame", { Size = UDim2.new(0, 4, 0, 4), Position = UDim2.new(0.5, -2, 0.5, -2),
            BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 4 }, crossContainer)
        corner(d, 4); table.insert(crossParts, d)
    elseif style == "Circle" then
        local c = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 4 }, crossContainer)
        corner(c, 999); stroke(c, col, 1.5, 0); table.insert(crossParts, c)
    elseif style == "X" then
        local l1 = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 16, 0, 2),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4, Rotation = 45 }, crossContainer)
        local l2 = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 16, 0, 2),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4, Rotation = -45 }, crossContainer)
        table.insert(crossParts, l1); table.insert(crossParts, l2)
    else
        local h = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 16, 0, 2),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4 }, crossContainer)
        local v = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 2, 0, 16),
            Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0,
            ZIndex = 4 }, crossContainer)
        table.insert(crossParts, h); table.insert(crossParts, v)
    end
end

local targetLine = mk("Frame", {
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = Cfg.Aimbot.TargetLineColor,
    BorderSizePixel = 0, ZIndex = 3, Visible = false,
    Size = UDim2.new(0, 0, 0, 2),
}, overlay)

connect(RunService.RenderStepped, function()
    if unloaded then return end
    fovFrame.Size = UDim2.new(0, Cfg.Aimbot.FOV * 2, 0, Cfg.Aimbot.FOV * 2)
    fovFrame.Visible = Cfg.Aimbot.ShowFOV and Cfg.Aimbot.Enabled
    fovStroke.Color = Cfg.Aimbot.FOVColor
    crossContainer.Visible = Cfg.Visuals.Crosshair and Cfg.Visuals.CrosshairStyle ~= "None"
    if Cfg.Aimbot.ShowTargetLine and currentTarget then
        local sp, on = Camera:WorldToViewportPoint(currentTarget.Position)
        if on then
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local delta = Vector2.new(sp.X, sp.Y) - center
            local len = delta.Magnitude
            local mid = center + delta / 2
            targetLine.Size = UDim2.new(0, len, 0, 2)
            targetLine.Position = UDim2.new(0, mid.X, 0, mid.Y)
            targetLine.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            targetLine.BackgroundColor3 = Cfg.Aimbot.TargetLineColor
            targetLine.Visible = true
        else targetLine.Visible = false end
    else targetLine.Visible = false end
end)

-- ==================== СТРАНИЦЫ ====================
local pMain = createTab("Главное")
makeSection(pMain, "Основные", 1)
makeToggle(pMain, "ESP подсветка игроков", Cfg.ESP.Enabled, function(v)
    Cfg.ESP.Enabled = v; updateAllHighlights()
end, 2)
makeToggle(pMain, "Инфо-теги над игроками", Cfg.ESP.ShowInfo, function(v)
    Cfg.ESP.ShowInfo = v; updateAllHighlights()
end, 3)
makeToggle(pMain, "Aimbot", Cfg.Aimbot.Enabled, function(v) Cfg.Aimbot.Enabled = v end, 4)
makeToggle(pMain, "Trigger Bot", Cfg.Trigger.Enabled, function(v) Cfg.Trigger.Enabled = v end, 5)
makeToggle(pMain, "Hitbox Expander", Cfg.Hitbox.Enabled, function(v)
    Cfg.Hitbox.Enabled = v; refreshHitboxes()
end, 6)
makeSection(pMain, "Визуал", 7)
makeToggle(pMain, "Прицел", Cfg.Visuals.Crosshair, function(v) Cfg.Visuals.Crosshair = v end, 8)
makeToggle(pMain, "Fullbright", Cfg.Visuals.Fullbright, function(v)
    Cfg.Visuals.Fullbright = v; setFullbright(v)
end, 9)
makeSection(pMain, "Конфиг", 10)
local resetBtn = mk("TextButton", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = ACCENT_3,
    BackgroundTransparency = 0.1,
    Text = "Сбросить настройки",
    TextColor3 = Color3.fromRGB(80, 30, 60),
    Font = Enum.Font.GothamBold, TextSize = 13,
    AutoButtonColor = false, LayoutOrder = 11, ZIndex = 8,
}, pMain)
corner(resetBtn, 10)
stroke(resetBtn, ACCENT_1, 1.5, 0.25)
addRipple(resetBtn)

local resetBaseSize = resetBtn.Size
resetBtn.MouseEnter:Connect(function()
    Tween:Create(resetBtn, SMOOTH, {
        Size = UDim2.new(1, -2, 0, 38),
        Position = UDim2.new(0, 1, 0, -1),
    }):Play()
end)
resetBtn.MouseLeave:Connect(function()
    Tween:Create(resetBtn, SMOOTH, {
        Size = resetBaseSize,
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()
end)
resetBtn.MouseButton1Click:Connect(function()
    if delfile then pcall(delfile, SAVE_FILE) end
    resetBtn.Text = "Сброшено — перезайди в игру"
    task.delay(2, function() resetBtn.Text = "Сбросить настройки" end)
end)

local pMove = createTab("Движение")
makeSection(pMove, "Fly", 1)
makeToggle(pMove, "Полёт", Cfg.Fly.Enabled, function(v)
    Cfg.Fly.Enabled = v
    if not v then stopFly() end
end, 2)
makeSlider(pMove, "Скорость полёта", 20, 300, Cfg.Fly.Speed, function(v) Cfg.Fly.Speed = v end, 3, true)
makeSection(pMove, "Noclip", 4)
makeToggle(pMove, "Умный Noclip", Cfg.Noclip.Enabled, function(v)
    Cfg.Noclip.Enabled = v
    if not v then restoreAllNoclip() end
end, 5)

local pAim = createTab("Aimbot")
makeSection(pAim, "Основные", 1)
makeSlider(pAim, "Радиус FOV", 50, 800, Cfg.Aimbot.FOV, function(v) Cfg.Aimbot.FOV = v end, 2, true)
makeSlider(pAim, "Сила аима", 1, 10, math.floor((1 - Cfg.Aimbot.Smoothness) * 10 + 0.5),
    function(v) Cfg.Aimbot.Smoothness = 1 - (v / 10) end, 3, true)
makeChips(pAim, "Часть тела", { "Head", "Torso", "Nearest" }, Cfg.Aimbot.TargetPart, function(v)
    Cfg.Aimbot.TargetPart = v
end, 4)
makeSection(pAim, "Поведение", 5)
makeToggle(pAim, "Только видимые цели", Cfg.Aimbot.VisibleOnly, function(v) Cfg.Aimbot.VisibleOnly = v end, 6)
makeToggle(pAim, "Удерживать кнопку для аима", Cfg.Aimbot.HoldKey, function(v) Cfg.Aimbot.HoldKey = v end, 7)
makeToggle(pAim, "Показывать круг FOV", Cfg.Aimbot.ShowFOV, function(v) Cfg.Aimbot.ShowFOV = v end, 8)
makeSection(pAim, "Линия до цели", 9)
makeToggle(pAim, "Показывать линию", Cfg.Aimbot.ShowTargetLine, function(v) Cfg.Aimbot.ShowTargetLine = v end, 10)
makeColorPicker(pAim, "Цвет линии", Cfg.Aimbot.TargetLineColor, function(c) Cfg.Aimbot.TargetLineColor = c end, 11)

local pTrig = createTab("Триггер")
makeSection(pTrig, "Trigger Bot", 1)
makeToggle(pTrig, "Автоматический выстрел", Cfg.Trigger.Enabled, function(v) Cfg.Trigger.Enabled = v end, 2)
makeSlider(pTrig, "Задержка (сек)", 0.01, 0.5, Cfg.Trigger.Delay, function(v) Cfg.Trigger.Delay = v end, 3)
makeToggle(pTrig, "Только видимые цели", Cfg.Trigger.VisibleOnly, function(v) Cfg.Trigger.VisibleOnly = v end, 4)
makeSection(pTrig, "Hitbox Expander", 5)
makeToggle(pTrig, "Увеличивать хитбокс", Cfg.Hitbox.Enabled, function(v)
    Cfg.Hitbox.Enabled = v; refreshHitboxes()
end, 6)
makeSlider(pTrig, "Множитель размера", 1.5, 5, Cfg.Hitbox.Scale, function(v)
    Cfg.Hitbox.Scale = v; refreshHitboxes()
end, 7)

local pEsp = createTab("ESP")
makeSection(pEsp, "Цвета", 1)
makeColorPicker(pEsp, "Цвет заливки", Cfg.ESP.FillColor, function(c)
    Cfg.ESP.FillColor = c; updateAllHighlights()
end, 2)
makeColorPicker(pEsp, "Цвет обводки", Cfg.ESP.OutlineColor, function(c)
    Cfg.ESP.OutlineColor = c; updateAllHighlights()
end, 3)
makeSection(pEsp, "Прозрачность", 4)
makeSlider(pEsp, "Заливка", 0, 1, Cfg.ESP.FillTransparency, function(v)
    Cfg.ESP.FillTransparency = v; updateAllHighlights()
end, 5)
makeSlider(pEsp, "Обводка", 0, 1, Cfg.ESP.OutlineTransparency, function(v)
    Cfg.ESP.OutlineTransparency = v; updateAllHighlights()
end, 6)
makeSection(pEsp, "Фильтры", 7)
makeToggle(pEsp, "Не светить союзников", Cfg.ESP.TeamCheck or false, function(v) Cfg.ESP.TeamCheck = v end, 8)

local pVis = createTab("Визуал")
makeSection(pVis, "Прицел", 1)
makeToggle(pVis, "Показывать прицел", Cfg.Visuals.Crosshair, function(v) Cfg.Visuals.Crosshair = v end, 2)
makeChips(pVis, "Стиль прицела", { "Cross", "Dot", "Circle", "X", "None" }, Cfg.Visuals.CrosshairStyle, function(v)
    Cfg.Visuals.CrosshairStyle = v; rebuildCrosshair()
end, 3)
makeColorPicker(pVis, "Цвет прицела", Cfg.Visuals.CrosshairColor, function(c)
    Cfg.Visuals.CrosshairColor = c; rebuildCrosshair()
end, 4)
makeSection(pVis, "Окружение", 5)
makeToggle(pVis, "Fullbright", Cfg.Visuals.Fullbright, function(v)
    Cfg.Visuals.Fullbright = v; setFullbright(v)
end, 6)
makeSection(pVis, "FOV Круг", 7)
makeColorPicker(pVis, "Цвет круга", Cfg.Aimbot.FOVColor, function(c) Cfg.Aimbot.FOVColor = c end, 8)

local pSkin = createTab("Скины")
makeSection(pSkin, "Noks Unlock All v2", 1)
local noksLoaded = false
makeToggle(pSkin, "Загрузить Noks Unlock All", false, function(v)
    if v and not noksLoaded then
        noksLoaded = true
        task.spawn(function()
            local ok, err = pcall(function()
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/thegop7y-ui/Noks-unlock-all-v2/refs/heads/main/Unlock-all"))()
            end)
            if not ok then
                warn("[BogdanWare] Noks error: " .. tostring(err))
                noksLoaded = false
            end
        end)
    end
end, 2)

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

closeBtn.MouseButton1Click:Connect(function()
    unloadScript()
end)

UIS.InputBegan:Connect(function(input, gp)
    if unloaded then return end
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
        overlay.Enabled = gui.Enabled
        if gui.Enabled then
            win.Size = UDim2.new(0, WIN_W * 0.96, 0, WIN_H * 0.96)
            Tween:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = normalSize,
            }):Play()
        end
    end
end)

-- ==================== ИНИЦИАЛИЗАЦИЯ ====================
rebuildCrosshair()
updateAllHighlights()
setFullbright(Cfg.Visuals.Fullbright)
if Cfg.Hitbox.Enabled then refreshHitboxes() end
