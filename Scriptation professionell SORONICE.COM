-- [[ 
    SORONICE UI LIBRARY - VERSION V6 "BLINDÉE"
    Intègre : Login, AFK, Réglages, Dragging, ET TOUS LES ÉLÉMENTS (ColorPicker, Label, Section).
]] --

local SoroniceLib = {}

-- :: SERVICES ROBLOX :: --
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

-- :: VARIABLES LOCALES :: --
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- :: CONFIGURATION GLOBALE :: --
local Settings = {
    Keybind = Enum.KeyCode.P,
    ThemeColor = Color3.fromRGB(20, 20, 20),
    AccentColor = Color3.fromRGB(0, 54, 203),
    ToggleOffColor = Color3.fromRGB(40, 40, 40),
    TextColor = Color3.fromRGB(255, 255, 255)
}

-- ============================================================================== --
--                            SYSTÈME AFK (ANTI-KICK)                             --
-- ============================================================================== --
local AfkEnabled = false
local AfkConnection = nil

local function ToggleAfk(state)
    AfkEnabled = state
    if AfkEnabled then
        AfkConnection = LocalPlayer.Idled:Connect(function()
            if AfkEnabled then
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end
        end)
        StarterGui:SetCore("SendNotification", {Title = "Mode AFK", Text = "Activé (Invisible).", Duration = 5})
    else
        if AfkConnection then AfkConnection:Disconnect() AfkConnection = nil end
        StarterGui:SetCore("SendNotification", {Title = "Mode AFK", Text = "Désactivé.", Duration = 3})
    end
end

-- ============================================================================== --
--                          SYSTÈME DE LOGIN (MOT DE PASSE)                       --
-- ============================================================================== --
local function SpawnLoginSystem(SettingsLogin)
    local Validated = false
    local RealPassword = SettingsLogin.Key or "1234"
    
    if SettingsLogin.GrabKeyFromSite == true then
        pcall(function()
            local content = game:HttpGet(SettingsLogin.Key)
            RealPassword = string.gsub(content, "%s+", "")
        end)
    end

    local LoginGui = Instance.new("ScreenGui")
    LoginGui.Name = "SoroniceLoginSystem"
    LoginGui.Parent = CoreGui
    
    local BlurEffect = Instance.new("BlurEffect", game.Lighting); BlurEffect.Size = 24
    
    local BackgroundImage = Instance.new("ImageLabel", LoginGui)
    BackgroundImage.AnchorPoint = Vector2.new(0.5, 0.5); BackgroundImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    BackgroundImage.Size = UDim2.new(0, 500, 0, 350); BackgroundImage.Image = "rbxassetid://114617892791025"; BackgroundImage.BackgroundTransparency = 1
    
    local TitleText = Instance.new("TextLabel", BackgroundImage)
    TitleText.BackgroundTransparency = 1; TitleText.Position = UDim2.new(0.1, 0, 0.04, 0); TitleText.Size = UDim2.new(0.5, 0, 0.15, 0)
    TitleText.Font = Enum.Font.FredokaOne; TitleText.Text = SettingsLogin.Title or "ACCÈS PREMIUM"; TitleText.TextColor3 = Color3.new(1,1,1); TitleText.TextScaled = true; TitleText.TextXAlignment = Enum.TextXAlignment.Left
    
    local CloseButton = Instance.new("TextButton", BackgroundImage)
    CloseButton.BackgroundTransparency = 1; CloseButton.Position = UDim2.new(0.92, 0, 0.14, 0); CloseButton.Size = UDim2.new(0.06, 0, 0.08, 0); CloseButton.Text = ""
    CloseButton.MouseButton1Click:Connect(function() LoginGui:Destroy(); BlurEffect:Destroy(); script:Destroy() end)
    
    local PasswordBox = Instance.new("TextBox", BackgroundImage)
    PasswordBox.BackgroundTransparency = 1; PasswordBox.Position = UDim2.new(0.33, 0, 0.42, 0); PasswordBox.Size = UDim2.new(0.47, 0, 0.15, 0)
    PasswordBox.Font = Enum.Font.SourceSansBold; PasswordBox.Text = ""; PasswordBox.PlaceholderText = "Mot de passe..."; PasswordBox.TextColor3 = Color3.new(1,1,1); PasswordBox.TextSize = 18
    
    local ValidateBtn = Instance.new("TextButton", BackgroundImage)
    ValidateBtn.BackgroundTransparency = 1; ValidateBtn.Position = UDim2.new(0.3, 0, 0.68, 0); ValidateBtn.Size = UDim2.new(0.4, 0, 0.12, 0); ValidateBtn.Text = ""
    
    local function Verify()
        if PasswordBox.Text == RealPassword then Validated = true; LoginGui:Destroy(); BlurEffect:Destroy() else PasswordBox.Text = "FAUX !" wait(1) PasswordBox.Text = "" end
    end
    ValidateBtn.MouseButton1Click:Connect(Verify)
    
    repeat wait() until Validated or not LoginGui.Parent
    if not Validated then script:Destroy() while true do wait(999) end end
end

-- ============================================================================== --
--                        CRÉATION DE LA FENÊTRE PRINCIPALE                       --
-- ============================================================================== --

function SoroniceLib:CreateWindow(Config)
    if Config.KeySystem == true then SpawnLoginSystem(Config.KeySettings or {}) end

    if CoreGui:FindFirstChild("Soronice_V6") then CoreGui:FindFirstChild("Soronice_V6"):Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Soronice_V6"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.BackgroundColor3 = Settings.ThemeColor; MainFrame.BackgroundTransparency = 0.2
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175); MainFrame.Size = UDim2.new(0, 550, 0, 350)
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.BackgroundTransparency = 1; TopBar.Size = UDim2.new(1, 0, 0, 40)
    
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end end)
    TopBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    local TitleLabel = Instance.new("TextLabel", TopBar)
    TitleLabel.BackgroundTransparency = 1; TitleLabel.Position = UDim2.new(0, 20, 0, 5); TitleLabel.Size = UDim2.new(0, 200, 0, 30)
    TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.Text = Config.Name or "SORONICE HUB"; TitleLabel.TextColor3 = Color3.new(1,1,1); TitleLabel.TextSize = 22; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.BackgroundTransparency = 1; CloseBtn.Position = UDim2.new(1, -30, 0, 5); CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Font = Enum.Font.SourceSansBold; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150); CloseBtn.TextSize = 20
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy(); ToggleAfk(false) end)

    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10); Sidebar.BackgroundTransparency = 0.5; Sidebar.Position = UDim2.new(0, 10, 0, 50); Sidebar.Size = UDim2.new(0, 60, 0, 290)
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
    local SidebarLayout = Instance.new("UIListLayout", Sidebar); SidebarLayout.Padding = UDim.new(0, 10); SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentContainer = Instance.new("Frame", MainFrame)
    ContentContainer.BackgroundTransparency = 1; ContentContainer.Position = UDim2.new(0, 80, 0, 50); ContentContainer.Size = UDim2.new(0, 460, 0, 290)

    -- SYSTÈME DE CRÉATION D'ÉLÉMENTS
    local function CreateElement(ParentPage, ElementType, ElementConfig)
        if ElementType == "Button" then
            local BtnFrame = Instance.new("Frame", ParentPage); BtnFrame.BackgroundColor3 = Color3.fromRGB(30,30,30); BtnFrame.Size = UDim2.new(1, -10, 0, 35)
            Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 6)
            local Btn = Instance.new("TextButton", BtnFrame); Btn.BackgroundTransparency = 1; Btn.Size = UDim2.new(1, 0, 1, 0); Btn.Font = Enum.Font.SourceSans; Btn.Text = "  "..ElementConfig.Name; Btn.TextColor3 = Settings.TextColor; Btn.TextSize = 16; Btn.TextXAlignment = Enum.TextXAlignment.Left
            Btn.MouseButton1Click:Connect(function() 
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play(); wait(0.1)
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
                if ElementConfig.Callback then ElementConfig.Callback() end 
            end)

        elseif ElementType == "Toggle" then
            local ToggleFrame = Instance.new("Frame", ParentPage); ToggleFrame.BackgroundTransparency = 1; ToggleFrame.Size = UDim2.new(1, -10, 0, 35)
            local Label = Instance.new("TextLabel", ToggleFrame); Label.BackgroundTransparency = 1; Label.Size = UDim2.new(0.7, 0, 1, 0); Label.Position = UDim2.new(0, 10, 0, 0); Label.Text = ElementConfig.Name; Label.TextColor3 = Settings.TextColor; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.TextSize = 16; Label.Font = Enum.Font.SourceSans
            local SwitchBg = Instance.new("Frame", ToggleFrame); SwitchBg.BackgroundColor3 = Settings.ToggleOffColor; SwitchBg.Position = UDim2.new(1, -60, 0.5, -12); SwitchBg.Size = UDim2.new(0, 50, 0, 24)
            Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
            local Knob = Instance.new("Frame", SwitchBg); Knob.BackgroundColor3 = Color3.new(1,1,1); Knob.Position = UDim2.new(0, 2, 0.5, -10); Knob.Size = UDim2.new(0, 20, 0, 20)
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
            local Toggled = ElementConfig.CurrentValue or false
            local function Update()
                local TargetPos = Toggled and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
                local TargetCol = Toggled and Settings.AccentColor or Settings.ToggleOffColor
                TweenService:Create(Knob, TweenInfo.new(0.2), {Position = TargetPos}):Play()
                TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = TargetCol}):Play()
                if ElementConfig.Callback then ElementConfig.Callback(Toggled) end
            end
            if Toggled then Update() end
            local Btn = Instance.new("TextButton", SwitchBg); Btn.BackgroundTransparency = 1; Btn.Size = UDim2.new(1,0,1,0); Btn.Text = ""
            Btn.MouseButton1Click:Connect(function() Toggled = not Toggled; Update() end)

        elseif ElementType == "Slider" then
             local SliderFrame = Instance.new("Frame", ParentPage); SliderFrame.BackgroundTransparency=1; SliderFrame.Size=UDim2.new(1,-10,0,50)
             local Label = Instance.new("TextLabel", SliderFrame); Label.BackgroundTransparency=1; Label.Position=UDim2.new(0,10,0,0); Label.Size=UDim2.new(1,0,0,20); Label.Text=ElementConfig.Name; Label.TextColor3=Settings.TextColor; Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Font=Enum.Font.SourceSans; Label.TextSize=16
             local ValLabel = Instance.new("TextLabel", SliderFrame); ValLabel.BackgroundTransparency=1; ValLabel.Position=UDim2.new(1,-60,0,0); ValLabel.Size=UDim2.new(0,50,0,20); ValLabel.TextColor3=Settings.TextColor; ValLabel.TextXAlignment=Enum.TextXAlignment.Right; ValLabel.Font=Enum.Font.SourceSansBold; ValLabel.TextSize=16
             local Bar = Instance.new("Frame", SliderFrame); Bar.BackgroundColor3=Color3.fromRGB(10,10,10); Bar.Position=UDim2.new(0,10,0,25); Bar.Size=UDim2.new(1,-20,0,10); Instance.new("UICorner", Bar).CornerRadius=UDim.new(1,0)
             local Knob = Instance.new("TextButton", Bar); Knob.BackgroundColor3=Settings.AccentColor; Knob.Size=UDim2.new(0,20,0,20); Knob.AnchorPoint=Vector2.new(0.5,0.5); Knob.Position=UDim2.new(0,0,0.5,0); Knob.Text=""; Instance.new("UICorner", Knob).CornerRadius=UDim.new(1,0)
             local Min, Max = ElementConfig.Range[1] or 0, ElementConfig.Range[2] or 100
             local Default = ElementConfig.CurrentValue or Min; ValLabel.Text = tostring(Default).."%"
             Knob.Position = UDim2.new((Default-Min)/(Max-Min), 0, 0.5, 0)
             local dragging = false
             Knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=true end end)
             UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end end)
             UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local Percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                    Knob.Position = UDim2.new(Percent, 0, 0.5, 0)
                    local Val = math.floor(Min + (Max-Min)*Percent)
                    ValLabel.Text = tostring(Val).."%"
                    if ElementConfig.Callback then ElementConfig.Callback(Val) end
                end
             end)

        elseif ElementType == "Label" then
            local LabelFrame = Instance.new("Frame", ParentPage); LabelFrame.BackgroundTransparency=1; LabelFrame.Size=UDim2.new(1,-10,0,25)
            local Txt = Instance.new("TextLabel", LabelFrame); Txt.BackgroundTransparency=1; Txt.Size=UDim2.new(1,0,1,0); Txt.Position=UDim2.new(0,10,0,0)
            Txt.Text = ElementConfig.Text; Txt.TextColor3 = Settings.TextColor; Txt.TextXAlignment=Enum.TextXAlignment.Left; Txt.Font=Enum.Font.SourceSans; Txt.TextSize=16

        elseif ElementType == "Section" then
            local SectionFrame = Instance.new("Frame", ParentPage); SectionFrame.BackgroundTransparency=1; SectionFrame.Size=UDim2.new(1,-10,0,30)
            local Txt = Instance.new("TextLabel", SectionFrame); Txt.BackgroundTransparency=1; Txt.Size=UDim2.new(1,0,1,0); Txt.Position=UDim2.new(0,10,0,0)
            Txt.Text = ElementConfig.Text; Txt.TextColor3 = Settings.AccentColor; Txt.TextXAlignment=Enum.TextXAlignment.Left; Txt.Font=Enum.Font.SourceSansBold; Txt.TextSize=18

        elseif ElementType == "ColorPicker" then
            -- Système simplifié de ColorPicker avec 3 Sliders (R, G, B) pour éviter les crashs et les assets manquants
            local CPFrame = Instance.new("Frame", ParentPage)
            CPFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); CPFrame.Size = UDim2.new(1, -10, 0, 130)
            Instance.new("UICorner", CPFrame).CornerRadius = UDim.new(0, 6)
            
            local Preview = Instance.new("Frame", CPFrame)
            Preview.Position = UDim2.new(0, 10, 0, 10); Preview.Size = UDim2.new(0, 30, 0, 30); Preview.BackgroundColor3 = ElementConfig.Color or Color3.new(1,1,1)
            Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 4)
            
            local Title = Instance.new("TextLabel", CPFrame)
            Title.BackgroundTransparency = 1; Title.Position = UDim2.new(0, 50, 0, 10); Title.Size = UDim2.new(0, 200, 0, 30)
            Title.Text = ElementConfig.Name; Title.TextColor3 = Color3.new(1,1,1); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Font = Enum.Font.SourceSansBold; Title.TextSize = 16

            local R, G, B = math.floor(Preview.BackgroundColor3.R*255), math.floor(Preview.BackgroundColor3.G*255), math.floor(Preview.BackgroundColor3.B*255)
            
            local function CreateRGBBar(YPos, Col, Val, Callback)
                local Bar = Instance.new("Frame", CPFrame); Bar.BackgroundColor3 = Color3.fromRGB(10,10,10); Bar.Position = UDim2.new(0, 10, 0, YPos); Bar.Size = UDim2.new(1, -20, 0, 10)
                Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)
                local Knob = Instance.new("TextButton", Bar); Knob.BackgroundColor3 = Col; Knob.Size = UDim2.new(0, 20, 0, 20); Knob.AnchorPoint = Vector2.new(0.5,0.5); Knob.Position = UDim2.new(Val/255, 0, 0.5, 0); Knob.Text = ""
                Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
                
                local dragging = false
                Knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local Percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                        Knob.Position = UDim2.new(Percent, 0, 0.5, 0)
                        Callback(math.floor(Percent * 255))
                    end
                end)
            end
            
            local function UpdateColor()
                local NewCol = Color3.fromRGB(R, G, B)
                Preview.BackgroundColor3 = NewCol
                if ElementConfig.Callback then ElementConfig.Callback(NewCol) end
            end

            CreateRGBBar(50, Color3.fromRGB(255,50,50), R, function(v) R = v; UpdateColor() end)
            CreateRGBBar(80, Color3.fromRGB(50,255,50), G, function(v) G = v; UpdateColor() end)
            CreateRGBBar(110, Color3.fromRGB(50,50,255), B, function(v) B = v; UpdateColor() end)
        end
    end

    local WindowFunctions = {}
    local FirstTab = true

    function WindowFunctions:CreateTab(TabName, TabImageId)
        local TabBtn = Instance.new("TextButton", Sidebar)
        TabBtn.BackgroundColor3 = Color3.new(0,0,0); TabBtn.BackgroundTransparency = 0.5; TabBtn.Size = UDim2.new(0, 45, 0, 45); TabBtn.Text = ""
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
        
        if TabImageId and TabImageId ~= 0 then
            local Icon = Instance.new("ImageLabel", TabBtn)
            Icon.BackgroundTransparency=1; Icon.Position=UDim2.new(0,5,0,5); Icon.Size=UDim2.new(0,35,0,35); Icon.Image="rbxassetid://"..tostring(TabImageId)
        else
            TabBtn.Text = string.sub(TabName, 1, 1); TabBtn.TextColor3 = Color3.new(0.8,0.8,0.8); TabBtn.TextSize=20; TabBtn.Font=Enum.Font.SourceSansBold
        end

        local Page = Instance.new("ScrollingFrame", ContentContainer)
        Page.BackgroundTransparency = 1; Page.Size = UDim2.new(1, 0, 1, 0); Page.ScrollBarThickness = 2; Page.Visible = FirstTab
        Instance.new("UIListLayout", Page).Padding = UDim.new(0, 8)

        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(ContentContainer:GetChildren()) do v.Visible = false end
            Page.Visible = true
        end)
        
        FirstTab = false
        local TabFunctions = {}
        
        -- Mapping des fonctions utilisateur
        function TabFunctions:CreateButton(C) CreateElement(Page, "Button", C) end
        function TabFunctions:CreateToggle(C) CreateElement(Page, "Toggle", C) end
        function TabFunctions:CreateSlider(C) CreateElement(Page, "Slider", C) end
        function TabFunctions:CreateLabel(Text) CreateElement(Page, "Label", {Text=Text}) end
        function TabFunctions:CreateSection(Text) CreateElement(Page, "Section", {Text=Text}) end
        function TabFunctions:CreateColorPicker(C) CreateElement(Page, "ColorPicker", C) end
        
        return TabFunctions
    end

    return WindowFunctions
end

return SoroniceLib
