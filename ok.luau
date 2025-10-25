[file name]: image.png
[file content begin]
18:38 34 -- AbsoluteContentSize is not a valid property name
Btack Begin

B Eeript 'ENNjtojoyxxtImbekBRIT', Line 1057 - function AddTab
Script 'ENNjtojOyxxtImbekBRIT', Line 974
Stack End

[file content end]

local InputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local CoreGui = game:GetService('CoreGui')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local RenderStepped = RunService.RenderStepped
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
    
    FontColor = Color3.fromRGB(240, 240, 240),
    MainColor = Color3.fromRGB(30, 30, 35),
    BackgroundColor = Color3.fromRGB(25, 25, 30),
    AccentColor = Color3.fromRGB(100, 150, 255),
    OutlineColor = Color3.fromRGB(60, 60, 70),
    RiskColor = Color3.fromRGB(255, 80, 80),
    
    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Gotham,
    
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = ScreenGui,
}

-- Utility functions
function Library:Create(Class, Properties)
    local Instance = type(Class) == 'string' and Instance.new(Class) or Class
    for Property, Value in next, Properties do
        Instance[Property] = Value
    end
    return Instance
end

function Library:CreateLabel(Properties, IsHud)
    local Label = Library:Create('TextLabel', {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 14,
        TextStrokeTransparency = 0.8,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    Library:AddToRegistry(Label, { TextColor3 = 'FontColor' }, IsHud)
    return Library:Create(Label, Properties)
end

function Library:ApplyTextStroke(Instance)
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0),
        Thickness = 1.2,
        LineJoinMode = Enum.LineJoinMode.Round,
        Parent = Instance
    })
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

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if Data then
        for i = #Library.Registry, 1, -1 do
            if Library.Registry[i] == Data then
                table.remove(Library.Registry, i)
            end
        end
        for i = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[i] == Data then
                table.remove(Library.HudRegistry, i)
            end
        end
        Library.RegistryMap[Instance] = nil
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

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

-- Watermark implementation
local WatermarkOuter = Library:Create('Frame', {
    BackgroundColor3 = Library.MainColor,
    BorderColor3 = Library.OutlineColor,
    Position = UDim2.new(0, 10, 0, 10),
    Size = UDim2.new(0, 200, 0, 30),
    Visible = false,
    ZIndex = 50,
    Parent = ScreenGui
})

Library:MakeDraggable(WatermarkOuter)

local WatermarkLabel = Library:CreateLabel({
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 5, 0, 0),
    Text = 'Watermark',
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 51,
    Parent = WatermarkOuter
})

function Library:SetWatermarkVisibility(Bool)
    WatermarkOuter.Visible = Bool
end

function Library:SetWatermark(Text)
    local X, Y = Library:GetTextBounds(Text, Library.Font, 13)
    WatermarkOuter.Size = UDim2.new(0, X + 20, 0, 30)
    WatermarkLabel.Text = Text
    Library:SetWatermarkVisibility(true)
end

-- Notify implementation
function Library:Notify(Text, Time)
    Time = Time or 5
    
    local Notification = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0.5, -150, 0, 10),
        Size = UDim2.new(0, 300, 0, 60),
        ZIndex = 100,
        Parent = ScreenGui
    })

    local MessageLabel = Library:CreateLabel({
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 1, -16),
        Text = Text,
        TextSize = 13,
        TextWrapped = true,
        Parent = Notification
    })

    task.spawn(function()
        wait(Time)
        Notification:Destroy()
    end)
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

-- Base addons for elements
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
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            Size = UDim2.new(0, 28, 0, 14),
            ZIndex = 6,
            Parent = ToggleLabel,
        })

        function ColorPicker:SetValue(Color)
            ColorPicker.Value = Color
            DisplayFrame.BackgroundColor3 = Color
            DisplayFrame.BorderColor3 = Library:GetDarkerColor(Color)
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

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self
        local ToggleLabel = self.TextLabel

        local KeyPicker = {
            Value = Info.Default or 'None',
            Toggled = false,
            Mode = Info.Mode or 'Toggle',
            Type = 'KeyPicker',
            Callback = Info.Callback or function() end,
            SyncToggleState = Info.SyncToggleState or false,
        }

        local PickOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 28, 0, 15),
            ZIndex = 6,
            Parent = ToggleLabel,
        })

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 7,
            Parent = PickOuter,
        })

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 13,
            Text = Info.Default or 'None',
            ZIndex = 8,
            Parent = PickInner,
        })

        local Picking = false

        function KeyPicker:SetValue(Key)
            DisplayLabel.Text = Key
            KeyPicker.Value = Key
            Library:SafeCallback(KeyPicker.Callback, Key)
        end

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true
                DisplayLabel.Text = '...'

                local Connection
                Connection = InputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        KeyPicker:SetValue(Input.KeyCode.Name)
                        Picking = false
                        Connection:Disconnect()
                    end
                end)
            end
        end)

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        Options[Idx] = KeyPicker
        return self
    end

    BaseAddons.__index = Funcs
end

-- Base groupbox implementation
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
            Size = UDim2.new(1, -4, 0, 15),
            TextSize = 14,
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

        Groupbox:AddBlank(5)
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
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 13, 0, 13),
            ZIndex = 5,
            Parent = Container,
        })

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = ToggleOuter,
        })

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0),
            Position = UDim2.new(1, 6, 0, 0),
            TextSize = 14,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6,
            Parent = ToggleInner,
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ToggleLabel,
        })

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 170, 1, 0),
            ZIndex = 8,
            Parent = ToggleOuter,
        })

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor
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

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Toggle:SetValue(not Toggle.Value)
            end
        end)

        Toggle:Display()
        Groupbox:AddBlank(5)
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
            Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = 14,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })
            Groupbox:AddBlank(3)
        end

        local SliderOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 13),
            ZIndex = 5,
            Parent = Container,
        })

        local SliderInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
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
            TextSize = 14,
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

        SliderInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local Percent = (Mouse.X - SliderInner.AbsolutePosition.X) / SliderInner.AbsoluteSize.X
                Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * Percent)
            end
        end)

        Slider:Display()
        Groupbox:AddBlank(6)
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
                Size = UDim2.new(1, 0, 0, 10),
                TextSize = 14,
                Text = Info.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                ZIndex = 5,
                Parent = Container,
            })
            Groupbox:AddBlank(3)
        end

        local DropdownOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = DropdownOuter,
        })

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0),
            Size = UDim2.new(1, -5, 1, 0),
            TextSize = 14,
            Text = Dropdown.Value or 'Select...',
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
            Parent = DropdownInner,
        })

        local DropdownArrow = Library:Create('ImageLabel', {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -16, 0.5, -6),
            Size = UDim2.new(0, 12, 0, 12),
            Image = 'rbxassetid://3926305904',
            ImageColor3 = Library.FontColor,
            ZIndex = 8,
            Parent = DropdownInner,
        })

        local ListOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Position = UDim2.new(0, 0, 1, 1),
            Size = UDim2.new(1, 0, 0, 100),
            Visible = false,
            ZIndex = 20,
            Parent = DropdownOuter,
        })

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 21,
            Parent = ListOuter,
        })

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ZIndex = 21,
            Parent = ListInner,
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
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = '',
                    AutoButtonColor = false,
                    Parent = Scrolling,
                })

                local OptionLabel = Library:CreateLabel({
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.fromOffset(6, 0),
                    Text = Value,
                    TextSize = 13,
                    Parent = Option,
                })

                Option.MouseButton1Click:Connect(function()
                    Dropdown.Value = Value
                    Dropdown:Display()
                    ListOuter.Visible = false
                    Library:SafeCallback(Dropdown.Callback, Value)
                end)
            end

            Scrolling.CanvasSize = UDim2.new(0, 0, 0, #Dropdown.Values * 20)
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
                ListOuter.Visible = not ListOuter.Visible
                if ListOuter.Visible then
                    Dropdown:UpdateList()
                end
            end
        end)

        Dropdown:Display()
        Groupbox:AddBlank(5)
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
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })

        local ButtonInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = ButtonOuter,
        })

        local ButtonLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0),
            TextSize = 14,
            Text = Info.Text,
            ZIndex = 6,
            Parent = ButtonInner,
        })

        ButtonInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Library:SafeCallback(Button.Callback)
            end
        end)

        Groupbox:AddBlank(5)
        Groupbox:Resize()
        return Button
    end

    function Funcs:AddInput(Idx, Info)
        local Textbox = {
            Value = Info.Default or '',
            Type = 'Input',
            Callback = Info.Callback or function() end,
        }

        local Groupbox = self
        local Container = Groupbox.Container

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15),
            TextSize = 14,
            Text = Info.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = Container,
        })

        Groupbox:AddBlank(1)

        local TextBoxOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(1, -4, 0, 20),
            ZIndex = 5,
            Parent = Container,
        })

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 6,
            Parent = TextBoxOuter,
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(5, 0),
            Size = UDim2.new(1, -10, 1, 0),
            Font = Library.Font,
            PlaceholderText = Info.Placeholder or '',
            Text = Info.Default or '',
            TextColor3 = Library.FontColor,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7,
            Parent = TextBoxInner,
        })

        function Textbox:SetValue(Text)
            Textbox.Value = Text
            Box.Text = Text
            Library:SafeCallback(Textbox.Callback, Textbox.Value)
        end

        if Info.Finished then
            Box.FocusLost:Connect(function()
                Textbox:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text)
            end)
        end

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func
            Func(Textbox.Value)
        end

        Groupbox:AddBlank(5)
        Groupbox:Resize()

        Options[Idx] = Textbox
        return Textbox
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
        
        Groupbox.BoxOuter.Size = UDim2.new(1, 0, 0, totalHeight + 10)
    end

    BaseGroupbox.__index = Funcs
end

-- Window and Tab implementation
function Library:CreateWindow(Config)
    Config = Config or {}
    
    local Window = {
        Tabs = {}
    }

    local Outer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = Config.Position or UDim2.fromOffset(100, 50),
        Size = Config.Size or UDim2.fromOffset(550, 400),
        Visible = Config.AutoShow or false,
        ZIndex = 1,
        Parent = ScreenGui,
    })

    Library:MakeDraggable(Outer, 25)

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.AccentColor,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 1,
        Parent = Outer,
    })

    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0),
        Size = UDim2.new(0, 0, 0, 25),
        Text = Config.Title or 'UI Library',
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1,
        Parent = Inner,
    })

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 25),
        Size = UDim2.new(1, -16, 1, -33),
        ZIndex = 1,
        Parent = Inner,
    })

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor,
        BorderColor3 = Color3.new(0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = MainSectionOuter,
    })

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 21),
        ZIndex = 1,
        Parent = MainSectionInner,
    })

    local TabListLayout = Library:Create('UIListLayout', {
        Padding = UDim.new(0, Config.TabPadding or 0),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabArea,
    })

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Position = UDim2.new(0, 8, 0, 30),
        Size = UDim2.new(1, -16, 1, -38),
        ZIndex = 2,
        Parent = MainSectionInner,
    })

    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {},
            Tabboxes = {}
        }

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16)

        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor,
            BorderColor3 = Library.OutlineColor,
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0),
            ZIndex = 1,
            Parent = TabArea,
        })

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, -1),
            Text = Name,
            ZIndex = 1,
            Parent = TabButton,
        })

        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor,
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundTransparency = 1,
            ZIndex = 3,
            Parent = TabButton,
        })

        local TabFrame = Library:Create('Frame', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ZIndex = 2,
            Parent = TabContainer,
        })

        local LeftSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(0.5, -12, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })

        local RightSide = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 4, 0, 8),
            Size = UDim2.new(0.5, -12, 1, -16),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0,
            ZIndex = 2,
            Parent = TabFrame,
        })

        local LeftLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = LeftSide,
        })

        local RightLayout = Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Parent = RightSide,
        })

        -- Исправление: используем AbsoluteContentSize ScrollingFrame вместо UIListLayout
        for _, Side in next, { LeftSide, RightSide } do
            Side:GetPropertyChangedSignal('AbsoluteCanvasSize'):Connect(function()
                Side.CanvasSize = UDim2.fromOffset(0, Side.AbsoluteCanvasSize.Y)
            end)
        end

        function Tab:ShowTab()
            for _, OtherTab in pairs(Window.Tabs) do
                OtherTab:HideTab()
            end

            Blocker.BackgroundTransparency = 0
            TabButton.BackgroundColor3 = Library.MainColor
            TabFrame.Visible = true
        end

        function Tab:HideTab()
            Blocker.BackgroundTransparency = 1
            TabButton.BackgroundColor3 = Library.BackgroundColor
            TabFrame.Visible = false
        end

        function Tab:AddGroupbox(Info)
            local Groupbox = {}

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                Size = UDim2.new(1, 0, 0, 100),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor,
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 5,
                Parent = BoxInner,
            })

            local GroupboxLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 18),
                Position = UDim2.new(0, 4, 0, 2),
                TextSize = 14,
                Text = Info.Name,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = BoxInner,
            })

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, 20),
                Size = UDim2.new(1, -4, 1, -20),
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
                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2)
            end

            Groupbox.Container = Container
            Groupbox.BoxOuter = BoxOuter
            setmetatable(Groupbox, BaseGroupbox)

            Groupbox:AddBlank(3)
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

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {}
            }

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Library.OutlineColor,
                Size = UDim2.new(1, 0, 0, 0),
                ZIndex = 2,
                Parent = Info.Side == 1 and LeftSide or RightSide,
            })

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor,
                BorderColor3 = Color3.new(0, 0, 0),
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                ZIndex = 4,
                Parent = BoxOuter,
            })

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor,
                Size = UDim2.new(1, 0, 0, 2),
                ZIndex = 10,
                Parent = BoxInner,
            })

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 1),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 5,
                Parent = BoxInner,
            })

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = TabboxButtons,
            })

            function Tabbox:AddTab(Name)
                local Tab = {}

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor,
                    BorderColor3 = Color3.new(0, 0, 0),
                    Size = UDim2.new(0.5, 0, 1, 0),
                    ZIndex = 6,
                    Parent = TabboxButtons,
                })

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    TextSize = 14,
                    Text = Name,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7,
                    Parent = Button,
                })

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor,
                    Position = UDim2.new(0, 0, 1, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    Visible = false,
                    ZIndex = 9,
                    Parent = Button,
                })

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 4, 0, 20),
                    Size = UDim2.new(1, -4, 1, -20),
                    ZIndex = 1,
                    Visible = false,
                    Parent = BoxInner,
                })

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = Container,
                })

                function Tab:Show()
                    for _, OtherTab in pairs(Tabbox.Tabs) do
                        OtherTab:Hide()
                    end

                    Container.Visible = true
                    Block.Visible = true
                    Button.BackgroundColor3 = Library.BackgroundColor
                end

                function Tab:Hide()
                    Container.Visible = false
                    Block.Visible = false
                    Button.BackgroundColor3 = Library.MainColor
                end

                function Tab:Resize()
                    local TabCount = 0
                    for _ in pairs(Tabbox.Tabs) do
                        TabCount = TabCount + 1
                    end

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if Button:IsA('Frame') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0)
                        end
                    end

                    if not Container.Visible then return end

                    local Size = 0
                    for _, Element in next, Container:GetChildren() do
                        if Element:IsA('Frame') then
                            Size = Size + Element.Size.Y.Offset
                        end
                    end

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2)
                end

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Tab:Show()
                        Tab:Resize()
                    end
                end)

                Tab.Container = Container
                Tabbox.Tabs[Name] = Tab
                setmetatable(Tab, BaseGroupbox)

                Tab:AddBlank(3)
                Tab:Resize()

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show()
                end

                return Tab
            end

            Tab.Tabboxes[Info.Name or ''] = Tabbox
            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1 })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2 })
        end

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab()
            end
        end)

        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab()
        end

        Window.Tabs[Name] = Tab
        return Tab
    end

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title
    end

    return Window
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end

Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

-- Cleanup signal
Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance)
    end
end))

getgenv().Library = Library
return Library
