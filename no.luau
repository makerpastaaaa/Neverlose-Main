local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')
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
    
    -- Обновленная цветовая схема
    FontColor = Color3.fromRGB(240, 240, 240),
    MainColor = Color3.fromRGB(20, 20, 25),
    BackgroundColor = Color3.fromRGB(15, 15, 20),
    AccentColor = Color3.fromRGB(0, 150, 255), -- Более яркий акцент
    SecondaryColor = Color3.fromRGB(40, 40, 50),
    OutlineColor = Color3.fromRGB(50, 50, 60),
    RiskColor = Color3.fromRGB(255, 80, 80),
    SuccessColor = Color3.fromRGB(80, 255, 80),
    
    Black = Color3.new(0, 0, 0),
    White = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamMedium,
    
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = ScreenGui,
    
    -- Новые настройки
    CornerRadius = UDim.new(0, 4),
    TransitionTime = 0.15,
}

-- Улучшенная функция создания с автоматическими скруглениями
function Library:Create(Class, Properties)
    local Instance = type(Class) == 'string' and Instance.new(Class) or Class
    for Property, Value in next, Properties do
        Instance[Property] = Value
    end
    
    -- Автоматическое добавление скруглений для фреймов
    if (Class == 'Frame' or Class == 'ImageButton' or Class == 'TextBox') and not Properties.CornerRadius then
        local Corner = Instance.new('UICorner')
        Corner.CornerRadius = Library.CornerRadius
        Corner.Parent = Instance
    end
    
    return Instance
end

-- Улучшенный лейбл с лучшими настройками по умолчанию
function Library:CreateLabel(Properties, IsHud)
    local Label = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 13,
        TextStrokeTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    Library:AddToRegistry(Label, { TextColor3 = 'FontColor' }, IsHud)
    return Library:Create(Label, Properties)
end

-- Функция для плавных анимаций
function Library:Tween(Instance, Properties, Duration)
    local TweenInfo = TweenInfo.new(Duration or Library.TransitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local Tween = TweenService:Create(Instance, TweenInfo, Properties)
    Tween:Play()
    return Tween
end

-- Остальные утилиты остаются прежними...
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

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:SafeCallback(Func, ...)
    if not Func then return end
    local Success, Result = pcall(Func, ...)
    if not Success and Library.NotifyOnError then
        Library:Notify(Result, 3)
    end
    return Success, Result
end

function Library:MouseIsOverOpenedFrame()
    for Frame in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true
        end
    end
    return false
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

-- Улучшенная система уведомлений
function Library:Notify(Text, Time)
    Time = Time or 5
    
    local Notification = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -150, 0, 10),
        Size = UDim2.new(0, 300, 0, 60),
        ZIndex = 100,
        Parent = ScreenGui,
    })

    Library:Create('UIStroke', {
        Color = Library.AccentColor,
        Thickness = 2,
        Parent = Notification
    })

    local MessageLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 1, -16),
        Text = Text,
        TextSize = 13,
        TextWrapped = true,
        TextColor3 = Library.FontColor,
        Parent = Notification
    })

    -- Анимация появления
    Notification.Position = UDim2.new(0.5, -150, 0, -70)
    Library:Tween(Notification, {Position = UDim2.new(0.5, -150, 0, 10)})

    task.spawn(function()
        wait(Time)
        Library:Tween(Notification, {Position = UDim2.new(0.5, -150, 0, -70)}):Wait()
        Notification:Destroy()
    end)
end

-- Базовые аддоны для элементов
local BaseAddons = {}

do
    local Funcs = {}

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel

        local ColorPicker = {
            Value = Info.Default or Color3.new(1, 1, 1),
            Type = 'ColorPicker',
            Callback = Info.Callback or function() end,
        }

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 24, 0, 16),
            ZIndex = 6,
            Parent = ToggleLabel,
        })

        Library:Create('UIStroke', {
            Color = Library.OutlineColor,
            Thickness = 1,
            Parent = DisplayFrame
        })

        function ColorPicker:SetValue(Color)
            ColorPicker.Value = Color
            DisplayFrame.BackgroundColor3 = Color
            Library:SafeCallback(ColorPicker.Callback, Color)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
            Func(ColorPicker.Value)
        end

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                ColorPicker:SetValue(Color3.new(math.random(), math.random(), math.random()))
            end
        end)

        Options[Idx] = ColorPicker
        return self
    end

    BaseAddons.__index = Funcs
end

-- Улучшенная реализация Groupbox
local BaseGroupbox = {}

do
    local Funcs = {}

    function Funcs:AddBlank(Size)
        local Groupbox = self
        local Container = Groupbox.Container

        Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Size),
            ZIndex = 1,
            Parent = Container,
        })
    end

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {}
        local Groupbox = self
        local Container = Groupbox.Container

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -8, 0, 18),
            TextSize = 13,
            Text = Text,
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })

        if not DoesWrap then
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4),
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TextLabel,
            })
        end

        Label.TextLabel = TextLabel
        Label.Container = Container

        function Label:SetText(NewText)
            TextLabel.Text = NewText
        end

        if not DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Groupbox:AddBlank(3)
        Groupbox:Resize()
        return Label
    end

    function Funcs:AddToggle(Idx, Info)
        local Toggle = {
            Value = Info.Default or false,
            Type = 'Toggle',
            Callback = Info.Callback or function() end,
            Risky = Info.Risky,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.SecondaryColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 32, 0, 18),
            ZIndex = 5,
            Parent = Container,
        })

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 1, 0, 1),
            ZIndex = 6,
            Parent = ToggleOuter,
        })

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 200, 1, 0),
            Position = UDim2.new(1, 8, 0, 0),
            TextSize = 13,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
            Parent = ToggleOuter,
        })

        function Toggle:Display()
            if Toggle.Value then
                Library:Tween(ToggleInner, {
                    BackgroundColor3 = Toggle.Risky and Library.RiskColor or Library.AccentColor,
                    Position = UDim2.new(0, 15, 0, 1)
                })
            else
                Library:Tween(ToggleInner, {
                    BackgroundColor3 = Library.MainColor,
                    Position = UDim2.new(0, 1, 0, 1)
                })
            end
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
            Func(Toggle.Value)
        end

        function Toggle:SetValue(Bool)
            Toggle.Value = Bool
            Toggle:Display()
            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
        end

        ToggleOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Toggle:SetValue(not Toggle.Value)
            end
        end)

        Toggle:Display()
        Groupbox:AddBlank(4)
        Groupbox:Resize()

        Toggle.TextLabel = ToggleLabel
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggles[Idx] = Toggle
        return Toggle
    end

    function Funcs:AddSlider(Idx, Info)
        local Slider = {
            Value = Info.Default or Info.Min,
            Min = Info.Min,
            Max = Info.Max,
            Rounding = Info.Rounding or 1,
            Type = 'Slider',
            Callback = Info.Callback or function() end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            local SliderHeader = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 12),
                TextSize = 12,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })
            Groupbox:AddBlank(2)
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.SecondaryColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -8, 0, 16),
            ZIndex = 5,
            Parent = Container,
        })

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = SliderOuter,
        })

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 7,
            Parent = SliderInner,
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 11,
            Text = tostring(Slider.Value),
            ZIndex = 9,
            Parent = SliderInner,
        })

        function Slider:Display()
            local Percent = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.new(Percent, 0, 1, 0)
            DisplayLabel.Text = tostring(Slider.Value)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
            Func(Slider.Value)
        end

        function Slider:SetValue(Value)
            Value = math.clamp(Value, Slider.Min, Slider.Max)
            Slider.Value = math.floor(Value / Slider.Rounding) * Slider.Rounding
            Slider:Display()
            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        local function UpdateSliderFromMouse()
            local Percent = math.clamp((Mouse.X - SliderInner.AbsolutePosition.X) / SliderInner.AbsoluteSize.X, 0, 1)
            Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * Percent)
        end

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                UpdateSliderFromMouse()
                
                local Connection
                Connection = InputService.InputChanged:Connect(function(MoveInput)
                    if MoveInput.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSliderFromMouse()
                    end
                end)
                
                InputService.InputEnded:Connect(function(EndInput)
                    if EndInput.UserInputType == Enum.UserInputType.MouseButton1 then
                        Connection:Disconnect()
                    end
                end)
            end
        end)

        Slider:Display()
        Groupbox:AddBlank(5)
        Groupbox:Resize()

        Options[Idx] = Slider
        return Slider
    end

    function Funcs:AddDropdown(Idx, Info)
        local Dropdown = {
            Values = Info.Values or {},
            Value = Info.Default,
            Type = 'Dropdown',
            Callback = Info.Callback or function() end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 12),
                TextSize = 12,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })
            Groupbox:AddBlank(2)
        end

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.SecondaryColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -8, 0, 22),
            ZIndex = 5,
            Parent = Container,
        })

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DropdownOuter,
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -25, 1, 0),
            TextSize = 12,
            Text = Dropdown.Value or 'Select...',
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
            Parent = DropdownInner,
        })

        local DropdownArrow = Library:Create('ImageLabel', {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -18, 0.5, -6),
            Size = UDim2.new(0, 12, 0, 12),
            Image = 'rbxassetid://6031091004',
            ImageColor3 = Library.FontColor,
            ZIndex = 8,
            Parent = DropdownInner,
        })

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, 2),
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            ZIndex = 20,
            Parent = DropdownOuter,
        })

        Library:Create('UIStroke', {
            Color = Library.OutlineColor,
            Thickness = 1,
            Parent = ListOuter
        })

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ZIndex = 21,
            Parent = ListOuter,
        })

        Library:Create('UIListLayout', {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Scrolling,
        })

        function Dropdown:Display()
            ItemList.Text = Dropdown.Value or 'Select...'
        end

        function Dropdown:UpdateList()
            for _, Child in ipairs(Scrolling:GetChildren()) do
                if Child:IsA('TextButton') then
                    Child:Destroy()
                end
            end

            for _, Value in ipairs(Dropdown.Values) do
                local Option = Library:Create('TextButton', {
                    BackgroundColor3 = Library.MainColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = '',
                    AutoButtonColor = false,
                    ZIndex = 22,
                    Parent = Scrolling,
                })

                local OptionLabel = Library:CreateLabel({
                    Size = UDim2.new(1, -8, 1, 0),
                    Position = UDim2.fromOffset(8, 0),
                    Text = Value,
                    TextSize = 11,
                    ZIndex = 23,
                    Parent = Option,
                })

                Option.MouseEnter:Connect(function()
                    Library:Tween(Option, {BackgroundColor3 = Library.SecondaryColor})
                end)

                Option.MouseLeave:Connect(function()
                    Library:Tween(Option, {BackgroundColor3 = Library.MainColor})
                end)

                Option.MouseButton1Click:Connect(function()
                    Dropdown.Value = Value
                    Dropdown:Display()
                    Dropdown:ToggleList()
                    Library:SafeCallback(Dropdown.Callback, Value)
                end)
            end

            local ContentSize = #Dropdown.Values * 20
            local MaxSize = math.min(ContentSize, 120)
            Scrolling.CanvasSize = UDim2.new(0, 0, 0, ContentSize)
            ListOuter.Size = UDim2.new(1, 0, 0, MaxSize)
        end

        function Dropdown:ToggleList()
            ListOuter.Visible = not ListOuter.Visible
            if ListOuter.Visible then
                Dropdown:UpdateList()
            end
        end

        function Dropdown:SetValue(Value)
            Dropdown.Value = Value
            Dropdown:Display()
            Library:SafeCallback(Dropdown.Callback, Value)
        end

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
            Func(Dropdown.Value)
        end

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dropdown:ToggleList()
            end
        end)

        Dropdown:Display()
        Groupbox:AddBlank(4)
        Groupbox:Resize()

        Options[Idx] = Dropdown
        return Dropdown
    end

    function Funcs:AddButton(Info)
        local Button = {
            Text = Info.Text,
            Callback = Info.Callback or function() end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local ButtonOuter = Library:Create('Frame', {
            BackgroundColor3 = Library.SecondaryColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, -8, 0, 22),
            ZIndex = 5,
            Parent = Container,
        })

        local ButtonInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = ButtonOuter,
        })

        local ButtonLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 12,
            Text = Info.Text,
            ZIndex = 6,
            Parent = ButtonInner,
        })

        ButtonInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Library:Tween(ButtonInner, {BackgroundColor3 = Library.AccentColor})
                Library:SafeCallback(Button.Callback)
                wait(0.1)
                Library:Tween(ButtonInner, {BackgroundColor3 = Library.MainColor})
            end
        end)

        Groupbox:AddBlank(4)
        Groupbox:Resize()
        return Button
    end

    function Funcs:Resize()
        local Groupbox = self
        local Container = Groupbox.Container
        
        local totalHeight = 0
        for _, child in ipairs(Container:GetChildren()) do
            if child:IsA('Frame') then
                totalHeight = totalHeight + child.Size.Y.Offset
            end
        end
        
        Groupbox.BoxOuter.Size = UDim2.new(1, 0, 0, totalHeight + 12)
    end

    BaseGroupbox.__index = Funcs
end

-- Улучшенное создание окна
function Library:CreateWindow(Config)
    Config = Config or {}
    
    local Window = {
        Tabs = {}
    }

    local Outer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Position = Config.Position or UDim2.fromOffset(100, 50),
        Size = Config.Size or UDim2.fromOffset(560, 360),
        Visible = Config.AutoShow or false,
        ZIndex = 1,
        Parent = ScreenGui,
    })

    Library:Create('UIStroke', {
        Color = Library.OutlineColor,
        Thickness = 1,
        Parent = Outer
    })

    Library:MakeDraggable(Outer, 30)

    local TopBar = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = 2,
        Parent = Outer,
    })

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Text = Config.Title or 'Premium UI',
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = TopBar,
    })

    local MainContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 1, -30),
        ZIndex = 1,
        Parent = Outer,
    })

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 28),
        ZIndex = 1,
        Parent = MainContainer,
    })

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabArea,
    })

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 8, 0, 40),
        Size = UDim2.new(1, -16, 1, -48),
        ZIndex = 2,
        Parent = MainContainer,
    })

    Library:Create('UIStroke', {
        Color = Library.OutlineColor,
        Thickness = 1,
        Parent = TabContainer
    })

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {},
            Tabboxes = {}
        }

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 13) + 20

        local TabButton = Library:Create('TextButton', {
            BackgroundColor3 = Library.SecondaryColor,
            BorderSizePixel = 0,
            Size = UDim2.new(0, TabButtonWidth, 1, 0),
            Text = '',
            AutoButtonColor = false,
            ZIndex = 2,
            Parent = TabArea,
        })

        local TabButtonLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            Text = Name,
            TextSize = 13,
            ZIndex = 3,
            Parent = TabButton,
        })

        local TabFrame = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2,
            Parent = TabContainer,
        })

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(0.5, -10, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ZIndex = 2,
            Parent = TabFrame,
        })

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 2, 0, 8),
            Size = UDim2.new(0.5, -10, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ZIndex = 2,
            Parent = TabFrame,
        })

        local LeftLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = LeftSide,
        })

        local RightLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = RightSide,
        })

        -- Исправление для автоматического размера контента
        for _, Side in next, { LeftSide, RightSide } do
            Side:GetPropertyChangedSignal('AbsoluteCanvasSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.AbsoluteCanvasSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _, OtherTab in pairs(Window.Tabs) do
                OtherTab:HideTab()
            end

            Library:Tween(TabButton, {BackgroundColor3 = Library.AccentColor})
            TabFrame.Visible = true
        end

        function Tab:HideTab()
            Library:Tween(TabButton, {BackgroundColor3 = Library.SecondaryColor})
            TabFrame.Visible = false
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.SecondaryColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 100),
                ZIndex = 3,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })

            Library:Create('UIStroke', {
                Color = Library.OutlineColor,
                Thickness = 1,
                Parent = BoxOuter
            })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, -8, 0, 20),
                Position = UDim2.new(0, 8, 0, 4),
                TextSize = 13,
                Text = Info.Name,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = BoxInner,
            })

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 6, 0, 24),
                Size = UDim2.new(1, -6, 1, -24),
                ZIndex = 1,
                Parent = BoxInner,
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Container,
            })

            function Groupbox:Resize()
                local Size = 0
                for _, Element in next, Container:GetChildren() do
                    if Element:IsA('Frame') then
                        Size = Size + Element.Size.Y.Offset
                    end
                end
                BoxOuter.Size = UDim2.new(1, 0, 0, 28 + Size + 2)
            end

            Groupbox.Container = Container
            Groupbox.BoxOuter = BoxOuter
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:AddBlank(4)
            Groupbox:Resize()

            Tab.Groupboxes[Info.Name] = Groupbox
            return Groupbox
        end

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2, Name = Name })
        end

        TabButton.MouseButton1Click:Connect(function()
            Tab:ShowTab()
        end)

        if #TabArea:GetChildren() == 2 then -- First tab
            Tab:ShowTab()
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    return Window
end

getgenv().Library = Library
return Library
