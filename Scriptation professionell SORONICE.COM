-- [[ SORONICE UI LIBRARY - VERSION LOGIN INTEGRE ]] --

local SoroniceLib = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer

-- Fonction interne pour créer le GUI de Login
local function SpawnLoginSystem(Settings)
    local Validated = false
    local Password = Settings.Key or "1234"
    local Link = Settings.Link or "https://google.com"
    
    -- Si le mot de passe doit être récupéré en ligne (Raw Text)
    if Settings.GrabKeyFromSite then
        pcall(function()
            Password = game:HttpGet(Settings.Key)
            -- On enlève les espaces ou retours à la ligne inutiles
            Password = string.gsub(Password, "\n", "")
            Password = string.gsub(Password, " ", "")
        end)
    end

    -- Création du GUI (Ton design "Mot de passe very1")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SoroniceLogin"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Fond flouté (Optionnel)
    local Blur = Instance.new("BlurEffect")
    Blur.Parent = game.Lighting
    Blur.Size = 24

    local Frame = Instance.new("Frame")
    Frame.Parent = ScreenGui
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BackgroundTransparency = 0.5
    Frame.Size = UDim2.new(1, 0, 1, 0)

    -- L'image principale (Le cadre)
    local MainImage = Instance.new("ImageLabel")
    MainImage.Parent = Frame
    MainImage.AnchorPoint = Vector2.new(0.5, 0.5)
    MainImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainImage.BackgroundTransparency = 1.000
    MainImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainImage.Size = UDim2.new(0, 500, 0, 350) 
    MainImage.Image = "rbxassetid://114617892791025" -- Ton image de fond

    -- Titre
    local Title = Instance.new("TextLabel")
    Title.Parent = MainImage
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0.2, 0, 0.08, 0)
    Title.Size = UDim2.new(0.6, 0, 0.15, 0)
    Title.Font = Enum.Font.FredokaOne -- Font stylée
    Title.Text = Settings.Title or "SORONICE HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true

    -- Zone de texte (Input)
    local InputBg = Instance.new("ImageLabel")
    InputBg.Parent = MainImage
    InputBg.BackgroundTransparency = 1
    InputBg.Position = UDim2.new(0.15, 0, 0.4, 0)
    InputBg.Size = UDim2.new(0.7, 0, 0.15, 0)
    InputBg.Image = "rbxassetid://75238927890132"

    local KeyBox = Instance.new("TextBox")
    KeyBox.Parent = InputBg
    KeyBox.BackgroundTransparency = 1
    KeyBox.Position = UDim2.new(0.2, 0, 0, 0)
    KeyBox.Size = UDim2.new(0.75, 0, 1, 0)
    KeyBox.Font = Enum.Font.SourceSansBold
    KeyBox.Text = ""
    KeyBox.PlaceholderText = "Entrez la clé ici..."
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 18

    -- BOUTON 1 : Valider (Entrer)
    local EnterBtn = Instance.new("TextButton")
    EnterBtn.Parent = MainImage
    EnterBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    EnterBtn.BackgroundTransparency = 1 -- On utilise une image ou couleur
    EnterBtn.Position = UDim2.new(0.25, 0, 0.65, 0)
    EnterBtn.Size = UDim2.new(0.5, 0, 0.12, 0)
    EnterBtn.Font = Enum.Font.SourceSansBold
    EnterBtn.Text = "VALIDER"
    EnterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    EnterBtn.TextSize = 20
    
    -- Design du bouton Valider
    local EnterCorner = Instance.new("UICorner")
    EnterCorner.CornerRadius = UDim.new(0, 10)
    EnterCorner.Parent = EnterBtn
    local EnterVisual = Instance.new("Frame")
    EnterVisual.Parent = EnterBtn
    EnterVisual.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    EnterVisual.Size = UDim2.new(1,0,1,0)
    EnterVisual.ZIndex = -1
    Instance.new("UICorner", EnterVisual).CornerRadius = UDim.new(0, 10)

    -- BOUTON 2 : Obtenir la clé (Lien)
    local LinkBtn = Instance.new("TextButton")
    LinkBtn.Parent = MainImage
    LinkBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    LinkBtn.Position = UDim2.new(0.25, 0, 0.8, 0)
    LinkBtn.Size = UDim2.new(0.5, 0, 0.1, 0)
    LinkBtn.Font = Enum.Font.SourceSans
    LinkBtn.Text = Settings.LinkText or "Obtenir la clé (Copier Lien)"
    LinkBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    LinkBtn.TextSize = 14
    Instance.new("UICorner", LinkBtn).CornerRadius = UDim.new(0, 8)

    -- LOGIQUE
    local function Check()
        if KeyBox.Text == Password then
            Validated = true
            ScreenGui:Destroy()
            Blur:Destroy()
        else
            KeyBox.Text = ""
            KeyBox.PlaceholderText = "Faux !"
            wait(1)
            KeyBox.PlaceholderText = "Entrez la clé ici..."
        end
    end

    EnterBtn.MouseButton1Click:Connect(Check)
    
    LinkBtn.MouseButton1Click:Connect(function()
        setclipboard(Link)
        LinkBtn.Text = "Lien copié !"
        wait(2)
        LinkBtn.Text = Settings.LinkText or "Obtenir la clé (Copier Lien)"
    end)

    -- On attend que le mot de passe soit bon
    repeat wait() until Validated or not ScreenGui.Parent
end


-- :: DÉBUT DE LA LIBRARY PRINCIPALE :: --

function SoroniceLib:CreateWindow(Config)
    -- 1. VÉRIFICATION DU MOT DE PASSE (Le fameux KLPJKR)
    -- Si KeySystem est "true", on lance le login AVANT de créer la fenêtre
    if Config.KeySystem == true then
        SpawnLoginSystem(Config.KeySettings or {})
    end

    -- 2. CRÉATION DE LA FENÊTRE NORMALE (Une fois le login passé)
	local TitleName = Config.Name or "SORONICE HUB"

	if game.CoreGui:FindFirstChild("Soronice_V6") then
		game.CoreGui:FindFirstChild("Soronice_V6"):Destroy()
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Soronice_V6"
	ScreenGui.Parent = game.CoreGui
    
    -- ... (Ici c'est ton code de GUI normal V6 que j'ai déjà fait, je le raccourcis pour la lisibilité)
    -- Le cadre principal
	local MainFrame = Instance.new("Frame")
	MainFrame.Parent = ScreenGui
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
	MainFrame.Size = UDim2.new(0, 550, 0, 350)
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
    
    -- Rendre draggable
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Titre et Bouton Fermer
    local TitleLabel = Instance.new("TextLabel", MainFrame)
    TitleLabel.Text = TitleName
    TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.TextSize = 22; TitleLabel.TextColor3 = Color3.new(1,1,1); TitleLabel.BackgroundTransparency=1
    TitleLabel.Position = UDim2.new(0,20,0,10); TitleLabel.Size = UDim2.new(0,200,0,30); TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local CloseBtn = Instance.new("TextButton", MainFrame)
    CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.new(0.6,0.6,0.6); CloseBtn.BackgroundTransparency=1; CloseBtn.Font=Enum.Font.SourceSansBold; CloseBtn.TextSize=18
    CloseBtn.Position = UDim2.new(1,-30,0,10); CloseBtn.Size = UDim2.new(0,20,0,20)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    -- Conteneurs
    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.BackgroundColor3 = Color3.fromRGB(10,10,10); Sidebar.BackgroundTransparency=0.5; Sidebar.Position=UDim2.new(0,10,0,50); Sidebar.Size=UDim2.new(0,60,0,290)
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,8)
    Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0,10); Instance.new("UIListLayout", Sidebar).HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentContainer = Instance.new("Frame", MainFrame)
    ContentContainer.BackgroundTransparency=1; ContentContainer.Position=UDim2.new(0,80,0,50); ContentContainer.Size=UDim2.new(0,460,0,290)

    -- Système d'onglets
	local WindowFunctions = {}
	local FirstTab = true

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
		end)
		FirstTab = false

		local TabFunctions = {}
        
        -- Bouton
		function TabFunctions:CreateButton(Config)
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
		end
        
        -- Toggle
        function TabFunctions:CreateToggle(Config)
            local ToggleFrame = Instance.new("Frame", Page); ToggleFrame.BackgroundTransparency=1; ToggleFrame.Size=UDim2.new(1,-10,0,35)
            local Label = Instance.new("TextLabel", ToggleFrame); Label.BackgroundTransparency=1; Label.Size=UDim2.new(0.7,0,1,0); Label.Position=UDim2.new(0,10,0,0); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.TextSize=16; Label.Font=Enum.Font.SourceSans
            local SwitchBg = Instance.new("Frame", ToggleFrame); SwitchBg.BackgroundColor3=Color3.fromRGB(40,40,40); SwitchBg.Position=UDim2.new(1,-60,0.5,-12); SwitchBg.Size=UDim2.new(0,50,0,24)
            Instance.new("UICorner", SwitchBg).CornerRadius=UDim.new(1,0)
            local Knob = Instance.new("Frame", SwitchBg); Knob.BackgroundColor3=Color3.new(1,1,1); Knob.Position=UDim2.new(0,2,0.5,-10); Knob.Size=UDim2.new(0,20,0,20)
            Instance.new("UICorner", Knob).CornerRadius=UDim.new(1,0)
            local Toggled = Config.CurrentValue or false
            local function Update()
                local TargetPos = Toggled and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
                local TargetCol = Toggled and Color3.fromRGB(0,54,203) or Color3.fromRGB(40,40,40)
                TweenService:Create(Knob, TweenInfo.new(0.2), {Position=TargetPos}):Play()
                TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3=TargetCol}):Play()
                Config.Callback(Toggled)
            end
            if Toggled then Update() end
            local Btn = Instance.new("TextButton", SwitchBg); Btn.BackgroundTransparency=1; Btn.Size=UDim2.new(1,0,1,0); Btn.Text=""
            Btn.MouseButton1Click:Connect(function() Toggled = not Toggled; Update() end)
        end

        -- Slider
        function TabFunctions:CreateSlider(Config)
             local SliderFrame = Instance.new("Frame", Page); SliderFrame.BackgroundTransparency=1; SliderFrame.Size=UDim2.new(1,-10,0,50)
             local Label = Instance.new("TextLabel", SliderFrame); Label.BackgroundTransparency=1; Label.Position=UDim2.new(0,10,0,0); Label.Size=UDim2.new(1,0,0,20); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Font=Enum.Font.SourceSans; Label.TextSize=16
             local ValLabel = Instance.new("TextLabel", SliderFrame); ValLabel.BackgroundTransparency=1; ValLabel.Position=UDim2.new(1,-60,0,0); ValLabel.Size=UDim2.new(0,50,0,20); ValLabel.TextColor3=Color3.new(1,1,1); ValLabel.TextXAlignment=Enum.TextXAlignment.Right; ValLabel.Font=Enum.Font.SourceSansBold; ValLabel.TextSize=16
             local Bar = Instance.new("Frame", SliderFrame); Bar.BackgroundColor3=Color3.fromRGB(10,10,10); Bar.Position=UDim2.new(0,10,0,25); Bar.Size=UDim2.new(1,-20,0,10); Instance.new("UICorner", Bar).CornerRadius=UDim.new(1,0)
             local Knob = Instance.new("TextButton", Bar); Knob.BackgroundColor3=Color3.fromRGB(0,54,203); Knob.Size=UDim2.new(0,20,0,20); Knob.AnchorPoint=Vector2.new(0.5,0.5); Knob.Position=UDim2.new(0,0,0.5,0); Knob.Text=""; Instance.new("UICorner", Knob).CornerRadius=UDim.new(1,0)
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
