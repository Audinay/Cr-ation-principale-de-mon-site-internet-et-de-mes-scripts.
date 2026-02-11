-- [[ SORONICE UI LIBRARY - VERSION V3 CORRIGÉE AVEC LOGIN ACTIF (VERSION FINALE) ]] --

local SoroniceLib = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui") -- Ajouté pour les notifs

-- --- [ CONFIGURATION GLOBALE ] ---
local Settings = {
	Keybind = Enum.KeyCode.P, -- Touche par défaut
	ThemeColor = Color3.fromRGB(20, 20, 20), -- Couleur de fond
	AccentColor = Color3.fromRGB(0, 54, 203) -- Couleur des boutons
}

-- --- [ SYSTÈME AFK (Ton code intégré) ] ---
local antiAfkActive = false
LocalPlayer.Idled:Connect(function()
    if antiAfkActive then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- --- [ DÉBUT DE LA LIBRARY ] ---

function SoroniceLib:CreateWindow(Config)
    -- 1. GESTION DU LOGIN (CODE COMPLET RESTAURÉ ICI)
    if Config.KeySystem == true then
        local Validated = false
        local RealPassword = Config.KeySettings.Key or "1234"
        
        -- Si la clé est un lien, on va chercher le texte sur le site
        if Config.KeySettings.GrabKeyFromSite == true then
            pcall(function()
                local content = game:HttpGet(Config.KeySettings.Key)
                RealPassword = string.gsub(content, "%s+", "") -- Nettoyage du texte
            end)
        end

        -- Création du GUI Login
        local LoginGui = Instance.new("ScreenGui")
        LoginGui.Name = "SoroniceLoginSystem"
        LoginGui.Parent = CoreGui
        LoginGui.ResetOnSpawn = false
        
        local BlurEffect = Instance.new("BlurEffect")
        BlurEffect.Parent = game.Lighting
        BlurEffect.Size = 24
        
        -- Image de fond (Le cadre vert/noir)
        local BackgroundImage = Instance.new("ImageLabel")
        BackgroundImage.Parent = LoginGui
        BackgroundImage.AnchorPoint = Vector2.new(0.5, 0.5)
        BackgroundImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        BackgroundImage.Size = UDim2.new(0, 500, 0, 350)
        BackgroundImage.Image = "rbxassetid://114617892791025"
        BackgroundImage.BackgroundTransparency = 1
        
        -- Titre
        local TitleText = Instance.new("TextLabel")
        TitleText.Parent = BackgroundImage
        TitleText.BackgroundTransparency = 1
        TitleText.Position = UDim2.new(0.1, 0, 0.04, 0)
        TitleText.Size = UDim2.new(0.5, 0, 0.15, 0)
        TitleText.Font = Enum.Font.FredokaOne
        TitleText.Text = Config.KeySettings.Title or "ACCÈS PREMIUM"
        TitleText.TextColor3 = Color3.new(1,1,1)
        TitleText.TextScaled = true
        TitleText.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Bouton Fermer
        local CloseButton = Instance.new("TextButton")
        CloseButton.Parent = BackgroundImage
        CloseButton.BackgroundTransparency = 1
        CloseButton.Position = UDim2.new(0.92, 0, 0.14, 0)
        CloseButton.Size = UDim2.new(0.06, 0, 0.08, 0)
        CloseButton.Text = ""
        CloseButton.MouseButton1Click:Connect(function() 
            LoginGui:Destroy()
            BlurEffect:Destroy()
            script:Destroy() 
        end)
        
        -- Champ Mot de Passe
        local InputBg = Instance.new("ImageLabel")
        InputBg.Parent = BackgroundImage
        InputBg.BackgroundTransparency = 1
        InputBg.Position = UDim2.new(0.18, 0, 0.42, 0)
        InputBg.Size = UDim2.new(0.62, 0, 0.15, 0)
        InputBg.Image = "rbxassetid://75238927890132"

        local PasswordBox = Instance.new("TextBox")
        PasswordBox.Parent = InputBg
        PasswordBox.BackgroundTransparency = 1
        PasswordBox.Position = UDim2.new(0.15, 0, 0, 0)
        PasswordBox.Size = UDim2.new(0.8, 0, 1, 0)
        PasswordBox.Font = Enum.Font.SourceSansBold
        PasswordBox.Text = ""
        PasswordBox.PlaceholderText = "Entrez la clé ici..."
        PasswordBox.TextColor3 = Color3.new(1,1,1)
        PasswordBox.TextSize = 18
        PasswordBox.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Bouton Valider
        local ValidateBtn = Instance.new("TextButton")
        ValidateBtn.Parent = BackgroundImage
        ValidateBtn.BackgroundColor3 = Color3.fromRGB(167, 167, 167)
        ValidateBtn.Position = UDim2.new(0.5, 0, 0.68, 0)
        ValidateBtn.AnchorPoint = Vector2.new(0.5, 0)
        ValidateBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
        ValidateBtn.Text = "VALIDER"
        ValidateBtn.Font = Enum.Font.SourceSansBold
        ValidateBtn.TextSize = 18
        Instance.new("UICorner", ValidateBtn).CornerRadius = UDim.new(0, 10)
        
        -- Bouton Lien
        local LinkBtn = Instance.new("TextButton")
        LinkBtn.Parent = BackgroundImage
        LinkBtn.BackgroundColor3 = Color3.fromRGB(167, 167, 167)
        LinkBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
        LinkBtn.AnchorPoint = Vector2.new(0.5, 0)
        LinkBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
        LinkBtn.Text = Config.KeySettings.LinkText or "Obtenir la clé"
        LinkBtn.Font = Enum.Font.SourceSans
        LinkBtn.TextSize = 14
        Instance.new("UICorner", LinkBtn).CornerRadius = UDim.new(0, 10)
        
        local function Verify()
            if PasswordBox.Text == RealPassword then 
                Validated = true
                LoginGui:Destroy()
                BlurEffect:Destroy()
            else 
                PasswordBox.Text = ""
                PasswordBox.PlaceholderText = "Mot de passe INCORRECT !" 
                wait(1.5) 
                PasswordBox.PlaceholderText = "Entrez la clé ici..."
            end
        end
        
        ValidateBtn.MouseButton1Click:Connect(Verify)
        LinkBtn.MouseButton1Click:Connect(function()
            if Config.KeySettings.Link then 
                setclipboard(Config.KeySettings.Link)
                LinkBtn.Text = "Lien copié !"
                wait(2)
                LinkBtn.Text = Config.KeySettings.LinkText or "Obtenir la clé"
            end
        end)
        
        -- On bloque tout tant que le mot de passe n'est pas bon
        repeat wait() until Validated or not LoginGui.Parent
        if not Validated then script:Destroy() while true do wait(999) end end
    end

	local TitleName = Config.Name or "SORONICE HUB"

	if CoreGui:FindFirstChild("Soronice_V6") then
		CoreGui:FindFirstChild("Soronice_V6"):Destroy()
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Soronice_V6"
	ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

	-- MAIN FRAME
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.BackgroundColor3 = Settings.ThemeColor
	MainFrame.BackgroundTransparency = 0.2
	MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
	MainFrame.Size = UDim2.new(0, 550, 0, 350)
	
	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 10)
	MainCorner.Parent = MainFrame

    -- [ZONE BLANCHE] : BARRE DE DÉPLACEMENT
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Parent = MainFrame
	TopBar.BackgroundTransparency = 1 
	TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.Position = UDim2.new(0,0,0,0)

	local dragging, dragInput, dragStart, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
		end
	end)
	TopBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	-- TITRE
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Parent = TopBar
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0, 20, 0, 5)
	TitleLabel.Size = UDim2.new(0, 200, 0, 30)
	TitleLabel.Font = Enum.Font.SourceSansBold
	TitleLabel.Text = TitleName
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleLabel.TextSize = 22
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- [ZONE ROUGE] : LE TRUC POUR RENDRE VISIBLE/INVISIBLE (Refait)
	local MinBtn = Instance.new("TextButton")
	MinBtn.Name = "Minimize"
	MinBtn.Parent = TopBar
	MinBtn.BackgroundTransparency = 1
	MinBtn.Position = UDim2.new(1, -60, 0, 5)
	MinBtn.Size = UDim2.new(0, 30, 0, 30)
	MinBtn.Font = Enum.Font.SourceSansBold
	MinBtn.Text = "-"
	MinBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	MinBtn.TextSize = 24
    
    -- Logique de visibilité corrigée
	local IsHidden = false
    local NotifShown = false 

    local function ToggleVisibility()
        IsHidden = not IsHidden
        MainFrame.Visible = not IsHidden
        
        -- Notification une seule fois
        if IsHidden and not NotifShown then
            NotifShown = true
            game.StarterGui:SetCore("SendNotification", {
                Title = "Soronice Hub",
                Text = "Appuie sur '" .. UserInputService:GetStringForKeyCode(Settings.Keybind) .. "' pour rouvrir.",
                Duration = 5
            })
        end
    end

	MinBtn.MouseButton1Click:Connect(ToggleVisibility)

    -- Gestion de la touche clavier (Le "P")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Settings.Keybind then
            ToggleVisibility()
        end
    end)

	-- BOUTON FERMER (X)
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Name = "Close"
	CloseBtn.Parent = TopBar
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.Position = UDim2.new(1, -30, 0, 5)
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.Font = Enum.Font.SourceSansBold
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	CloseBtn.TextSize = 20
	
	CloseBtn.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	-- SIDEBAR
	local Sidebar = Instance.new("Frame")
	Sidebar.Parent = MainFrame
	Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	Sidebar.BackgroundTransparency = 0.5
	Sidebar.Position = UDim2.new(0, 10, 0, 50)
	Sidebar.Size = UDim2.new(0, 60, 0, 290)
	
	local SidebarCorner = Instance.new("UICorner")
	SidebarCorner.CornerRadius = UDim.new(0, 8)
	SidebarCorner.Parent = Sidebar

	local SidebarLayout = Instance.new("UIListLayout")
	SidebarLayout.Parent = Sidebar
	SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SidebarLayout.Padding = UDim.new(0, 10)
	SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	-- CONTENU
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Parent = MainFrame
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Position = UDim2.new(0, 80, 0, 50)
	ContentContainer.Size = UDim2.new(0, 460, 0, 290)

    -- [ZONE BLEUE] : BOUTON RÉGLAGES
	local SettingsBtn = Instance.new("TextButton")
	SettingsBtn.Name = "Settings_Btn"
	SettingsBtn.Parent = MainFrame 
	SettingsBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	SettingsBtn.BackgroundTransparency = 0.5
    SettingsBtn.Position = UDim2.new(0, 18, 1, -55)
	SettingsBtn.Size = UDim2.new(0, 45, 0, 45)
	SettingsBtn.Text = ""
    Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 8)
    
	local SettingsIcon = Instance.new("ImageLabel")
	SettingsIcon.Parent = SettingsBtn
	SettingsIcon.BackgroundTransparency = 1
	SettingsIcon.Position = UDim2.new(0, 5, 0, 5)
	SettingsIcon.Size = UDim2.new(0, 35, 0, 35)
	SettingsIcon.Image = "rbxassetid://74182569229556"

    -- PAGE RÉGLAGES
    local SettingsPage = Instance.new("ScrollingFrame")
    SettingsPage.Name = "Settings_Page"
    SettingsPage.Parent = ContentContainer
    SettingsPage.BackgroundTransparency = 1
    SettingsPage.Size = UDim2.new(1, 0, 1, 0)
    SettingsPage.ScrollBarThickness = 2
    SettingsPage.Visible = false 

    local SettingsLayout = Instance.new("UIListLayout")
    SettingsLayout.Parent = SettingsPage
    SettingsLayout.Padding = UDim.new(0, 8)

    -- Ouverture réglages
    SettingsBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(ContentContainer:GetChildren()) do
            v.Visible = false
        end
        SettingsPage.Visible = true
        for _, btn in pairs(Sidebar:GetChildren()) do
            if btn:IsA("TextButton") then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play()
            end
        end
        TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
    end)

	local WindowFunctions = {}
	local FirstTab = true

    -- CREATION ELEMENTS
    local function CreateElement(Page, Type, Config)
        if Type == "Button" then
            local BtnFrame = Instance.new("Frame", Page)
			BtnFrame.BackgroundColor3 = Color3.fromRGB(30,30,30); BtnFrame.Size=UDim2.new(1,-10,0,35)
            Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0,6)
			local Btn = Instance.new("TextButton", BtnFrame)
			Btn.BackgroundTransparency=1; Btn.Size=UDim2.new(1,0,1,0); Btn.Font=Enum.Font.SourceSans; Btn.Text="  "..Config.Name; Btn.TextColor3=Color3.new(1,1,1); Btn.TextSize=16; Btn.TextXAlignment=Enum.TextXAlignment.Left
			Btn.MouseButton1Click:Connect(function() 
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play(); wait(0.1)
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(30,30,30)}):Play()
                Config.Callback() 
            end)

        elseif Type == "Toggle" then
            local ToggleFrame = Instance.new("Frame", Page); ToggleFrame.BackgroundTransparency=1; ToggleFrame.Size=UDim2.new(1,-10,0,35)
            local Label = Instance.new("TextLabel", ToggleFrame); Label.BackgroundTransparency=1; Label.Size=UDim2.new(0.7,0,1,0); Label.Position=UDim2.new(0,10,0,0); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.TextSize=16; Label.Font=Enum.Font.SourceSans
            local SwitchBg = Instance.new("Frame", ToggleFrame); SwitchBg.BackgroundColor3=Color3.fromRGB(40,40,40); SwitchBg.Position=UDim2.new(1,-60,0.5,-12); SwitchBg.Size=UDim2.new(0,50,0,24)
            Instance.new("UICorner", SwitchBg).CornerRadius=UDim.new(1,0)
            local Knob = Instance.new("Frame", SwitchBg); Knob.BackgroundColor3=Color3.new(1,1,1); Knob.Position=UDim2.new(0,2,0.5,-10); Knob.Size=UDim2.new(0,20,0,20)
            Instance.new("UICorner", Knob).CornerRadius=UDim.new(1,0)
            local Toggled = Config.CurrentValue or false
            local function Update()
                local TargetPos = Toggled and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
                local TargetCol = Toggled and Settings.AccentColor or Color3.fromRGB(40,40,40)
                TweenService:Create(Knob, TweenInfo.new(0.2), {Position=TargetPos}):Play()
                TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3=TargetCol}):Play()
                Config.Callback(Toggled)
            end
            if Toggled then Update() end
            local Btn = Instance.new("TextButton", SwitchBg); Btn.BackgroundTransparency=1; Btn.Size=UDim2.new(1,0,1,0); Btn.Text=""
            Btn.MouseButton1Click:Connect(function() Toggled = not Toggled; Update() end)

        -- [LE TRUC POUR CHANGER (KEYBIND) - CORRIGÉ]
        elseif Type == "Keybind" then
            local BindFrame = Instance.new("Frame", Page)
            BindFrame.BackgroundColor3 = Color3.fromRGB(30,30,30); BindFrame.Size=UDim2.new(1,-10,0,35)
            Instance.new("UICorner", BindFrame).CornerRadius = UDim.new(0,6)
            local Label = Instance.new("TextLabel", BindFrame); Label.BackgroundTransparency=1; Label.Size=UDim2.new(0.7,0,1,0); Label.Position=UDim2.new(0,10,0,0); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.TextSize=16; Label.Font=Enum.Font.SourceSans
            
            local BindBtn = Instance.new("TextButton", BindFrame)
            BindBtn.BackgroundColor3 = Color3.fromRGB(40,40,40); BindBtn.Position=UDim2.new(1,-80,0.5,-12); BindBtn.Size=UDim2.new(0,70,0,24)
            BindBtn.Text = UserInputService:GetStringForKeyCode(Settings.Keybind)
            BindBtn.Font = Enum.Font.SourceSansBold; BindBtn.TextColor3 = Color3.new(1,1,1); BindBtn.TextSize = 14
            Instance.new("UICorner", BindBtn).CornerRadius=UDim.new(0,6)

            -- Nouvelle logique de changement de touche (Propre et sans bug)
            BindBtn.MouseButton1Click:Connect(function()
                BindBtn.Text = "..."
                local InputConnection
                InputConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        Settings.Keybind = input.KeyCode
                        BindBtn.Text = UserInputService:GetStringForKeyCode(input.KeyCode)
                        InputConnection:Disconnect() -- On coupe l'écoute immédiatement
                        game.StarterGui:SetCore("SendNotification", {Title = "Réglages", Text = "Nouvelle touche : " .. BindBtn.Text, Duration = 3})
                    end
                end)
            end)
        end
    end

    -- REMPLISSAGE AUTOMATIQUE RÉGLAGES
    CreateElement(SettingsPage, "Toggle", {
        Name = "💤 Mode AFK (Anti-Kick)",
        CurrentValue = false,
        Callback = function(Value)
            antiAfkActive = Value
            if Value then
                game.StarterGui:SetCore("SendNotification", {Title = "Anti-AFK", Text = "Activé : Vous ne serez pas kické.", Duration = 3})
            end
        end
    })
    
    CreateElement(SettingsPage, "Keybind", {
        Name = "Touche pour Cacher/Montrer",
        Callback = function() end 
    })

	-- :: FONCTIONS UTILISATEUR :: --
	function WindowFunctions:CreateTab(TabName, TabImageId)
		local TabBtn = Instance.new("TextButton", Sidebar)
		TabBtn.BackgroundColor3 = Color3.new(0,0,0); TabBtn.BackgroundTransparency=0.5; TabBtn.Size=UDim2.new(0,45,0,45); TabBtn.Text=""
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0,8)
		if TabImageId and TabImageId ~= 0 then
			local Icon = Instance.new("ImageLabel", TabBtn)
			Icon.BackgroundTransparency=1; Icon.Position=UDim2.new(0,5,0,5); Icon.Size=UDim2.new(0,35,0,35); Icon.Image="rbxassetid://"..tostring(TabImageId)
		else
			TabBtn.Text = string.sub(TabName, 1, 1); TabBtn.TextColor3 = Color3.new(0.8,0.8,0.8); TabBtn.TextSize=20; TabBtn.Font=Enum.Font.SourceSansBold
		end

		local Page = Instance.new("ScrollingFrame", ContentContainer)
		Page.BackgroundTransparency=1; Page.Size=UDim2.new(1,0,1,0); Page.ScrollBarThickness=2; Page.Visible=FirstTab
        Instance.new("UIListLayout", Page).Padding = UDim.new(0,8)

		TabBtn.MouseButton1Click:Connect(function()
			for _,v in pairs(ContentContainer:GetChildren()) do v.Visible=false end
			Page.Visible=true
            TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play()
		end)
		FirstTab = false

		local TabFunctions = {}
        
		function TabFunctions:CreateButton(Config) CreateElement(Page, "Button", Config) end
        function TabFunctions:CreateToggle(Config) CreateElement(Page, "Toggle", Config) end
        
        -- Fonctions vides pour éviter les erreurs (Demandé précédemment)
        function TabFunctions:CreateColorPicker(Config) end 
        function TabFunctions:CreateSection(Name) end
        function TabFunctions:CreateLabel(Text) end

        function TabFunctions:CreateSlider(Config)
             local SliderFrame = Instance.new("Frame", Page); SliderFrame.BackgroundTransparency=1; SliderFrame.Size=UDim2.new(1,-10,0,50)
             local Label = Instance.new("TextLabel", SliderFrame); Label.BackgroundTransparency=1; Label.Position=UDim2.new(0,10,0,0); Label.Size=UDim2.new(1,0,0,20); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Font=Enum.Font.SourceSans; Label.TextSize=16
             local ValLabel = Instance.new("TextLabel", SliderFrame); ValLabel.BackgroundTransparency=1; ValLabel.Position=UDim2.new(1,-60,0,0); ValLabel.Size=UDim2.new(0,50,0,20); ValLabel.TextColor3=Color3.new(1,1,1); ValLabel.TextXAlignment=Enum.TextXAlignment.Right; ValLabel.Font=Enum.Font.SourceSansBold; ValLabel.TextSize=16
             local Bar = Instance.new("Frame", SliderFrame); Bar.BackgroundColor3=Color3.fromRGB(10,10,10); Bar.Position=UDim2.new(0,10,0,25); Bar.Size=UDim2.new(1,-20,0,10); Instance.new("UICorner", Bar).CornerRadius=UDim.new(1,0)
             local Knob = Instance.new("TextButton", Bar); Knob.BackgroundColor3=Settings.AccentColor; Knob.Size=UDim2.new(0,20,0,20); Knob.AnchorPoint=Vector2.new(0.5,0.5); Knob.Position=UDim2.new(0,0,0.5,0); Knob.Text=""; Instance.new("UICorner", Knob).CornerRadius=UDim.new(1,0)
             local Min, Max = Config.Range[1] or 0, Config.Range[2] or 100
             local Default = Config.CurrentValue or Min; ValLabel.Text = tostring(Default).."%"
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
                    Config.Callback(Val)
                end
             end)
        end
		return TabFunctions
	end
	return WindowFunctions
end
return SoroniceLib
