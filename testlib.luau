local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local Teams = game:GetService('Teams')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end)

local ScreenGui = Instance.new('ScreenGui')
ProtectGui(ScreenGui)

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
    Registry = {},
    RegistryMap = {},
    HudRegistry = {},
    
    -- Modern color scheme
    FontColor = Color3.fromRGB(240, 240, 240),
    MainColor = Color3.fromRGB(30, 30, 35),
    BackgroundColor = Color3.fromRGB(25, 25, 30),
    AccentColor = Color3.fromRGB(100, 150, 255),
    SecondaryColor = Color3.fromRGB(80, 130, 235),
    OutlineColor = Color3.fromRGB(60, 60, 70),
    RiskColor = Color3.fromRGB(255, 80, 80),
    SuccessColor = Color3.fromRGB(80, 200, 120),
    
    Black = Color3.new(0, 0, 0),
    White = Color3.new(1, 1, 1),
    Font = Enum.Font.Gotham,
    TitleFont = Enum.Font.GothamBold,
    
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = ScreenGui,
    
    -- Modern design properties
    CornerRadius = UDim.new(0, 8),
    ShadowIntensity = 0.3,
    TransitionTime = 0.15
}

-- Enhanced rainbow effect
local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 300)
        if Hue > 1 then Hue = 0 end
        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.85, 1)
    end
end))

-- Utility functions
function Library:Create(Class, Properties)
    local Instance = type(Class) == 'string' and Instance.new(Class) or Class
    for Property, Value in next, Properties do
        Instance[Property] = Value
    end
    return Instance
end

function Library:AddCorner(Instance, Radius)
    local Corner = Library:Create('UICorner', {
        CornerRadius = Radius or Library.CornerRadius,
        Parent = Instance
    })
    return Corner
end

function Library:AddShadow(Instance)
    local Shadow = Library:Create('ImageLabel', {
        Name = 'Shadow',
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = 'rbxassetid://5554236805',
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = -1,
        Parent = Instance
    })
    return Shadow
end

function Library:ApplyTextStroke(Instance)
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0),
        Thickness = 1.2,
        LineJoinMode = Enum.LineJoinMode.Round,
        Parent = Instance
    })
end

function Library:CreateLabel(Properties, IsHud)
    local Label = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 14,
        TextStrokeTransparency = 0.8,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = true
    })
    
    Library:ApplyTextStroke(Label)
    Library:AddToRegistry(Label, { TextColor3 = 'FontColor' }, IsHud)
    return Library:Create(Label, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    local DragStart, StartPos

    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(Mouse.X - Instance.AbsolutePosition.X, Mouse.Y - Instance.AbsolutePosition.Y)
            if not Cutoff or ObjPos.Y <= Cutoff then
                DragStart = Input.Position
                StartPos = Instance.Position
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        DragStart = nil
                    end
                end)
            end
        end
    end)

    Instance.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement and DragStart then
            local Delta = Input.Position - DragStart
            Instance.Position = UDim2.new(
                StartPos.X.Scale, StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
            )
        end
    end)
end

function Library:AddHoverEffect(Instance, Properties, PropertiesDefault)
    Library:OnHighlight(Instance, Instance, Properties, PropertiesDefault)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx
        end
    end)

    HighlightInstance.MouseLeave:Connect(function()
        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx
        end
    end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 13)
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.fromOffset(X + 12, Y + 8),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false
    })
    
    Library:AddCorner(Tooltip, UDim.new(0, 6))
    Library:AddShadow(Tooltip)

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(6, 4),
        Size = UDim2.fromOffset(X, Y),
        TextSize = 13,
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip
    })

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor'
    })

    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then return end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 15)
        Tooltip.Visible = true
        
        while IsHovering do
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 15)
            RunService.Heartbeat:Wait()
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

-- Enhanced toggle with smooth animations
function Library:CreateModernToggle(Info)
    local Toggle = {
        Value = Info.Default or false,
        Type = 'Toggle',
        Callback = Info.Callback or function() end,
        Risky = Info.Risky
    }

    local ToggleFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = Info.Parent
    })
    
    Library:AddCorner(ToggleFrame)

    local ToggleButton = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.new(0, 50, 0, 24),
        Position = UDim2.new(1, -54, 0.5, -12),
        Parent = ToggleFrame
    })
    
    Library:AddCorner(ToggleButton, UDim.new(0, 12))

    local ToggleKnob = Library:Create('Frame', {
        BackgroundColor3 = Library.FontColor,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 4, 0.5, -8),
        Parent = ToggleButton
    })
    
    Library:AddCorner(ToggleKnob, UDim.new(0, 8))

    local ToggleLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Text = Info.Text,
        TextSize = 14,
        TextColor3 = Toggle.Risky and Library.RiskColor or Library.FontColor,
        Parent = ToggleFrame
    })

    function Toggle:SetValue(Value)
        Toggle.Value = Value
        local TargetPosition = Value and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
        local TargetColor = Value and Library.AccentColor or Library.MainColor
        
        TweenService:Create(ToggleKnob, TweenInfo.new(Library.TransitionTime), {Position = TargetPosition}):Play()
        TweenService:Create(ToggleButton, TweenInfo.new(Library.TransitionTime), {BackgroundColor3 = TargetColor}):Play()
        
        Library:SafeCallback(Toggle.Callback, Value)
    end

    ToggleFrame.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Toggle:SetValue(not Toggle.Value)
        end
    end)

    Toggle:SetValue(Toggle.Value)
    return Toggle
end

-- Enhanced button with hover effects
function Library:CreateModernButton(Info)
    local Button = {
        Text = Info.Text,
        Callback = Info.Callback or function() end
    }

    local ButtonFrame = Library:Create('TextButton', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.new(1, 0, 0, 36),
        Text = '',
        AutoButtonColor = false,
        Parent = Info.Parent
    })
    
    Library:AddCorner(ButtonFrame)
    Library:AddShadow(ButtonFrame)

    local ButtonLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 1, 0),
        Text = Info.Text,
        TextColor3 = Library.FontColor,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = ButtonFrame
    })

    local HoverOverlay = Library:Create('Frame', {
        BackgroundColor3 = Library.White,
        BackgroundTransparency = 0.9,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = ButtonFrame
    })
    
    Library:AddCorner(HoverOverlay)

    ButtonFrame.MouseEnter:Connect(function()
        TweenService:Create(HoverOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
    end)

    ButtonFrame.MouseLeave:Connect(function()
        TweenService:Create(HoverOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.9}):Play()
    end)

    ButtonFrame.MouseButton1Click:Connect(function()
        Library:SafeCallback(Button.Callback)
        TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, 32)}):Play()
        TweenService:Create(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 36)}):Play()
    end)

    return Button
end

-- Modern slider with smooth animations
function Library:CreateModernSlider(Info)
    local Slider = {
        Value = Info.Default or Info.Min,
        Min = Info.Min,
        Max = Info.Max,
        Rounding = Info.Rounding or 1,
        Callback = Info.Callback or function() end
    }

    local SliderFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        Size = UDim2.new(1, 0, 0, 60),
        Parent = Info.Parent
    })
    
    Library:AddCorner(SliderFrame)

    local SliderLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 0, 20),
        Text = Info.Text,
        TextSize = 14,
        Parent = SliderFrame
    })

    local SliderTrack = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.fromOffset(12, 35),
        Size = UDim2.new(1, -24, 0, 6),
        Parent = SliderFrame
    })
    
    Library:AddCorner(SliderTrack, UDim.new(0, 3))

    local SliderFill = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = SliderTrack
    })
    
    Library:AddCorner(SliderFill, UDim.new(0, 3))

    local SliderKnob = Library:Create('Frame', {
        BackgroundColor3 = Library.White,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Parent = SliderTrack
    })
    
    Library:AddCorner(SliderKnob, UDim.new(0, 8))
    Library:AddShadow(SliderKnob)

    local ValueLabel = Library:CreateLabel({
        Position = UDim2.new(1, -60, 0, 8),
        Size = UDim2.new(0, 48, 0, 20),
        Text = tostring(Slider.Value),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = SliderFrame
    })

    function Slider:SetValue(Value)
        Value = math.clamp(Value, Slider.Min, Slider.Max)
        Slider.Value = math.floor(Value / Slider.Rounding) * Slider.Rounding
        
        local Percent = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
        local FillSize = Percent * (SliderTrack.AbsoluteSize.X - 2)
        
        TweenService:Create(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(0, FillSize, 1, 0)}):Play()
        TweenService:Create(SliderKnob, TweenInfo.new(0.1), {Position = UDim2.new(Percent, 0, 0.5, 0)}):Play()
        
        ValueLabel.Text = tostring(Slider.Value)
        Library:SafeCallback(Slider.Callback, Slider.Value)
    end

    local IsDragging = false
    SliderTrack.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsDragging = true
            local Percent = (Mouse.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
            Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * Percent)
        end
    end)

    InputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            IsDragging = false
        end
    end)

    InputService.InputChanged:Connect(function(Input)
        if IsDragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
            local Percent = math.clamp((Mouse.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
            Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * Percent)
        end
    end)

    Slider:SetValue(Slider.Value)
    return Slider
end

-- Modern dropdown
function Library:CreateModernDropdown(Info)
    local Dropdown = {
        Values = Info.Values or {},
        Value = Info.Default,
        Callback = Info.Callback or function() end
    }

    local DropdownFrame = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = Info.Parent
    })
    
    Library:AddCorner(DropdownFrame)

    local DropdownButton = Library:Create('TextButton', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.new(1, -8, 0, 32),
        Position = UDim2.new(0, 4, 0, 4),
        Text = '',
        AutoButtonColor = false,
        Parent = DropdownFrame
    })
    
    Library:AddCorner(DropdownButton)

    local DropdownLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Text = Dropdown.Value or 'Select...',
        TextSize = 14,
        Parent = DropdownButton
    })

    local DropdownArrow = Library:Create('ImageLabel', {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -24, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Image = 'rbxassetid://3926305904',
        ImageColor3 = Library.FontColor,
        ImageRectOffset = Vector2.new(564, 284),
        ImageRectSize = Vector2.new(36, 36),
        Parent = DropdownButton
    })

    local DropdownList = Library:Create('ScrollingFrame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 4, 1, 4),
        Size = UDim2.new(1, -8, 0, 120),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Library.AccentColor,
        Visible = false,
        Parent = DropdownFrame
    })
    
    Library:AddCorner(DropdownList)
    Library:AddShadow(DropdownList)

    local ListLayout = Library:Create('UIListLayout', {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = DropdownList
    })

    function Dropdown:UpdateList()
        for _, Child in ipairs(DropdownList:GetChildren()) do
            if Child:IsA('TextButton') then
                Child:Destroy()
            end
        end

        for _, Value in ipairs(Dropdown.Values) do
            local Option = Library:Create('TextButton', {
                BackgroundColor3 = Library.MainColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 30),
                Text = '',
                AutoButtonColor = false,
                Parent = DropdownList
            })

            local OptionLabel = Library:CreateLabel({
                Size = UDim2.new(1, -12, 1, 0),
                Position = UDim2.fromOffset(12, 0),
                Text = Value,
                TextSize = 13,
                Parent = Option
            })

            Option.MouseButton1Click:Connect(function()
                Dropdown.Value = Value
                DropdownLabel.Text = Value
                DropdownList.Visible = false
                TweenService:Create(DropdownArrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
                Library:SafeCallback(Dropdown.Callback, Value)
            end)

            Library:AddHoverEffect(Option, 
                {BackgroundColor3 = 'BackgroundColor'},
                {BackgroundColor3 = 'MainColor'}
            )
        end

        DropdownList.CanvasSize = UDim2.new(0, 0, 0, #Dropdown.Values * 30)
    end

    DropdownButton.MouseButton1Click:Connect(function()
        DropdownList.Visible = not DropdownList.Visible
        TweenService:Create(DropdownArrow, TweenInfo.new(0.2), {
            Rotation = DropdownList.Visible and 180 or 0
        }):Play()
    end)

    Dropdown:UpdateList()
    return Dropdown
end

-- Enhanced window creation
function Library:CreateModernWindow(Config)
    Config = Config or {}
    
    local Window = {
        Tabs = {}
    }

    local Outer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = Config.Position or UDim2.fromOffset(100, 50),
        Size = Config.Size or UDim2.fromOffset(600, 450),
        Visible = false,
        ZIndex = 10,
        Parent = ScreenGui
    })
    
    Library:AddCorner(Outer, UDim.new(0, 12))
    Library:AddShadow(Outer)
    Library:MakeDraggable(Outer, 40)

    local TitleBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = Outer
    })
    
    Library:AddCorner(TitleBar, UDim.new(0, 12, 0, 12))

    local TitleLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Text = Config.Title or 'Modern UI',
        Font = Library.TitleFont,
        TextSize = 16,
        TextColor3 = Library.White,
        Parent = TitleBar
    })

    local CloseButton = Library:Create('TextButton', {
        BackgroundColor3 = Library.RiskColor,
        Position = UDim2.new(1, -32, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Text = '×',
        TextColor3 = Library.White,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Parent = TitleBar
    })
    
    Library:AddCorner(CloseButton, UDim.new(0, 6))

    local Content = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        Parent = Outer
    })

    local TabButtons = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        Size = UDim2.new(1, 0, 0, 48),
        Parent = Content
    })

    local TabContainer = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 48),
        Size = UDim2.new(1, 0, 1, -48),
        Parent = Content
    })

    function Window:AddTab(Name)
        local Tab = {}
        
        local TabButton = Library:Create('TextButton', {
            BackgroundColor3 = Library.BackgroundColor,
            Size = UDim2.new(0, 120, 1, 0),
            Text = '',
            AutoButtonColor = false,
            Parent = TabButtons
        })

        local TabLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            Text = Name,
            TextSize = 14,
            TextColor3 = Library.FontColor,
            Parent = TabButton
        })

        local TabHighlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 1, -3),
            BackgroundTransparency = 1,
            Parent = TabButton
        })

        local TabContent = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Library.AccentColor,
            Visible = false,
            Parent = TabContainer
        })

        local ContentLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = TabContent
        })

        ContentLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y)
        end)

        function Tab:Show()
            for _, OtherTab in pairs(Window.Tabs) do
                OtherTab:Hide()
            end
            
            TabContent.Visible = true
            TweenService:Create(TabHighlight, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundColor3 = Library.MainColor}):Play()
        end

        function Tab:Hide()
            TabContent.Visible = false
            TweenService:Create(TabHighlight, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundColor3 = Library.BackgroundColor}):Play()
        end

        function Tab:AddElement(ElementType, Info)
            Info.Parent = TabContent
            if ElementType == 'Toggle' then
                return Library:CreateModernToggle(Info)
            elseif ElementType == 'Button' then
                return Library:CreateModernButton(Info)
            elseif ElementType == 'Slider' then
                return Library:CreateModernSlider(Info)
            elseif ElementType == 'Dropdown' then
                return Library:CreateModernDropdown(Info)
            end
        end

        TabButton.MouseButton1Click:Connect(function()
            Tab:Show()
        end)

        Window.Tabs[Name] = Tab
        
        -- Show first tab
        if #Window.Tabs == 1 then
            Tab:Show()
        end

        return Tab
    end

    CloseButton.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)

    function Window:Toggle()
        Outer.Visible = not Outer.Visible
    end

    function Window:SetTitle(Title)
        TitleLabel.Text = Title
    end

    return Window
end

-- Enhanced notification system
function Library:ShowNotification(Title, Message, Duration)
    Duration = Duration or 5
    
    local Notification = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(1, 10, 0, 10),
        Size = UDim2.new(0, 300, 0, 80),
        ZIndex = 100,
        Parent = ScreenGui
    })
    
    Library:AddCorner(Notification, UDim.new(0, 8))
    Library:AddShadow(Notification)

    local TitleLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 0, 20),
        Text = Title,
        TextSize = 14,
        Font = Library.TitleFont,
        TextColor3 = Library.AccentColor,
        Parent = Notification
    })

    local MessageLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(12, 30),
        Size = UDim2.new(1, -24, 1, -38),
        Text = Message,
        TextSize = 13,
        TextWrapped = true,
        Parent = Notification
    })

    local ProgressBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        Size = UDim2.new(1, 0, 0, 3),
        Position = UDim2.new(0, 0, 1, -3),
        Parent = Notification
    })
    
    Library:AddCorner(ProgressBar, UDim.new(0, 0, 0, 0))

    -- Slide in animation
    TweenService:Create(Notification, TweenInfo.new(0.3), {
        Position = UDim2.new(1, -310, 0, 10)
    }):Play()

    -- Progress bar animation
    TweenService:Create(ProgressBar, TweenInfo.new(Duration), {
        Size = UDim2.new(0, 0, 0, 3)
    }):Play()

    task.spawn(function()
        wait(Duration)
        TweenService:Create(Notification, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 10, 0, 10)
        }):Play()
        wait(0.3)
        Notification:Destroy()
    end)
end

-- Keep existing utility functions
function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:SafeCallback(Func, ...)
    if not Func then return end
    local Success, Result = pcall(Func, ...)
    if not Success and Library.NotifyOnError then
        Library:ShowNotification('Error', Result, 3)
    end
end

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Data = {
        Instance = Instance,
        Properties = Properties,
        Idx = #Library.Registry + 1
    }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then
        table.insert(Library.HudRegistry, Data)
    end
end

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

-- Initialize
Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
    if Input.KeyCode == Enum.KeyCode.RightControl then
        -- Toggle UI visibility
        for _, Element in pairs(ScreenGui:GetChildren()) do
            if Element:IsA('Frame') then
                Element.Visible = not Element.Visible
            end
        end
    end
end))

getgenv().Library = Library
return Library
