-- [[ SORONICE UI LIBRARY - VERSION LOGIN CORRIGÉE V2 ]] --

local SoroniceLib = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer

-- Fonction interne pour créer le GUI de Login
local function SpawnLoginSystem(Settings)
    local Validated = false
    
    -- LOGIQUE DU MOT DE PASSE (CORRIGÉE)
    -- On définit le "Vrai" mot de passe
    local RealPassword = Settings.Key or "1234"
    
    -- Si l'utilisateur a choisi de prendre la clé sur un site :
    if Settings.GrabKeyFromSite and Settings.Key:sub(1,4) == "http" then
        pcall(function()
            local content = game:HttpGet(Settings.Key)
            -- Nettoyage du texte reçu (enlève les espaces et retours à la ligne)
            RealPassword = string.gsub(content, "\n", "")
            RealPassword = string.gsub(RealPassword, " ", "")
            RealPassword = string.gsub(RealPassword, "\r", "")
        end)
    end
    -- Si c'est juste un texte normal, RealPassword reste ce qu'il est.

    -- CRÉATION DU GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SoroniceLogin"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Fond flouté (SEULEMENT LE FLOU, PAS DE NOIR)
    local Blur = Instance.new("BlurEffect")
    Blur.Parent = game.Lighting
    Blur.Size = 24
    
    -- Cadre Principal (Invisible, sert juste à centrer l'image)
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundTransparency = 1 -- 100% transparent !
    MainFrame.Size = UDim2.new(1, 0, 1, 0)

    -- L'image principale (Le cadre avec le design vert/noir)
    local MainImage = Instance.new("ImageLabel")
    MainImage.Parent = MainFrame
    MainImage.AnchorPoint = Vector2.new(0.5, 0.5)
    MainImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainImage.BackgroundTransparency = 1.000
    MainImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainImage.Size = UDim2.new(0, 500, 0, 350) 
    MainImage.Image = "rbxassetid://114617892791025" -- Ton image de fond

    -- Titre (Repositionné en HAUT À GAUCHE dans la barre verte)
    local Title = Instance.new("TextLabel")
    Title.Parent = MainImage
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0.1, 0, 0.04, 0) -- Ajusté
    Title.Size = UDim2.new(0.5, 0, 0.15, 0)
    Title.Font = Enum.Font.FredokaOne 
    Title.Text = Settings.Title or "ACCÈS PREMIUM"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- BOUTONS DE LA BARRE DU HAUT (X et -)
    -- Le cadre noir des boutons (Image invisible sur ton screen, zone cliquable)
    
    -- BOUTON FERMER (X)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = MainImage
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Position = UDim2.new(0.92, 0, 0.14, 0) -- Position sur ton image
    CloseBtn.Size = UDim2.new(0.06, 0, 0.08, 0)
    CloseBtn.Text = ""
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        Blur:Destroy()
        script:Destroy() -- Arrête tout le script (Le hub ne chargera pas)
    end)

    -- BOUTON RÉDUIRE (-)
    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = MainImage
    MinBtn.BackgroundTransparency = 1
    MinBtn.Position = UDim2.new(0.85, 0, 0.14, 0) -- Juste à côté du X
    MinBtn.Size = UDim2.new(0.06, 0, 0.08, 0)
    MinBtn.Text = ""
    
    local Hidden = false
    MinBtn.MouseButton1Click:Connect(function()
        Hidden = true
        MainImage.Visible = false
        -- Notification système Roblox
        game.StarterGui:SetCore("SendNotification", {
            Title = "Soronice Hub",
            Text = "Appuie sur 'P' pour rouvrir le menu",
            Duration = 5
        })
    end)
    
    -- Gestion de la touche P pour rouvrir
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.P and Hidden then
            Hidden = false
            MainImage.Visible = true
        end
    end)

    -- ZONE DE TEXTE (Repositionnée À GAUCHE)
    local InputBg = Instance.new("ImageLabel")
    InputBg.Parent = MainImage
    InputBg.BackgroundTransparency = 1
    InputBg.Position = UDim2.new(0.18, 0, 0.42, 0) -- Plus à gauche
    InputBg.Size = UDim2.new(0.62, 0, 0.15, 0)
    InputBg.Image = "rbxassetid://75238927890132"
    
    -- Cadenas (Décoration)
    local LockIcon = Instance.new("ImageLabel")
    LockIcon.Parent = InputBg
    LockIcon.BackgroundTransparency = 1
    LockIcon.Position = UDim2.new(-0.02, 0, 0.2, 0)
    LockIcon.Size = UDim2.new(0.1, 0, 0.6, 0)
    LockIcon.Image = "rbxassetid://110855536039004"

    local KeyBox = Instance.new("TextBox")
    KeyBox.Parent = InputBg
    KeyBox.BackgroundTransparency = 1
    KeyBox.Position = UDim2.new(0.15, 0, 0, 0) -- Décalé après le cadenas
    KeyBox.Size = UDim2.new(0.8, 0, 1, 0)
    KeyBox.Font = Enum.Font.SourceSansBold
    KeyBox.Text = ""
    KeyBox.PlaceholderText = "Entrez la clé ici..."
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 18
    KeyBox.TextXAlignment = Enum.TextXAlignment.Left

    -- BOUTON 1 : Valider (Enter)
    local EnterBtn = Instance.new("TextButton")
    EnterBtn.Parent = MainImage
    EnterBtn.BackgroundColor3 = Color3.fromRGB(167, 167, 167)
    EnterBtn.Position = UDim2.new(0.5, 0, 0.68, 0) -- Ajusté hauteur
    EnterBtn.AnchorPoint = Vector2.new(0.5, 0)
    EnterBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
    EnterBtn.Text = "VALIDER"
    EnterBtn.Font = Enum.Font.SourceSansBold
    EnterBtn.TextSize = 18
    Instance.new("UICorner", EnterBtn).CornerRadius = UDim.new(0, 10)

    -- BOUTON 2 : Lien (Link)
    local LinkBtn = Instance.new("TextButton")
    LinkBtn.Parent = MainImage
    LinkBtn.BackgroundColor3 = Color3.fromRGB(167, 167, 167)
    LinkBtn.Position = UDim2.new(0.5, 0, 0.85, 0) -- En bas
    LinkBtn.AnchorPoint = Vector2.new(0.5, 0)
    LinkBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
    LinkBtn.Text = Settings.LinkText or "Obtenir la clé"
    LinkBtn.Font = Enum.Font.SourceSans
    LinkBtn.TextSize = 14
    Instance.new("UICorner", LinkBtn).CornerRadius = UDim.new(0, 10)

    -- FONCTION DE VÉRIFICATION
    local function Check()
        -- On compare ce qui est écrit avec le Vrai mot de passe
        if KeyBox.Text == RealPassword then
            Validated = true
            ScreenGui:Destroy()
            Blur:Destroy()
        else
            KeyBox.Text = ""
            KeyBox.PlaceholderText = "Mot de passe incorrect !"
            wait(1)
            KeyBox.PlaceholderText = "Entrez la clé ici..."
        end
    end

    EnterBtn.MouseButton1Click:Connect(Check)
    
    -- Copier le lien
    LinkBtn.MouseButton1Click:Connect(function()
        if Settings.Link then
            setclipboard(Settings.Link)
            LinkBtn.Text = "Lien copié !"
            wait(2)
            LinkBtn.Text = Settings.LinkText or "Obtenir la clé"
        end
    end)

    -- Bloquer le script tant que c'est pas validé
    repeat wait() until Validated or not ScreenGui.Parent
    if not Validated then 
        -- Si le GUI n'existe plus mais pas validé (fermé avec X), on arrête
        script:Destroy() 
        while true do wait(999) end -- Sécurité ultime pour stopper
    end
end


-- :: DÉBUT DE LA LIBRARY PRINCIPALE :: --

function SoroniceLib:CreateWindow(Config)
    -- 1. VÉRIFICATION
    if Config.KeySystem == true then
        SpawnLoginSystem(Config.KeySettings or {})
    end

    -- 2. CRÉATION FENÊTRE (CODE GUI V6 OPTIMISÉ)
	local TitleName = Config.Name or "SORONICE HUB"

	if game.CoreGui:FindFirstChild("Soronice_V6") then
		game.CoreGui:FindFirstChild("Soronice_V6"):Destroy()
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Soronice_V6"
	ScreenGui.Parent = game.CoreGui
    
	local MainFrame = Instance.new("Frame")
	MainFrame.Parent = ScreenGui
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
	MainFrame.Size = UDim2.new(0, 550, 0, 350)
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
    
    -- Draggable simple
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

    local TitleLabel = Instance.new("TextLabel", MainFrame)
    TitleLabel.Text = TitleName
    TitleLabel.Font = Enum.Font.SourceSansBold; TitleLabel.TextSize = 22; TitleLabel.TextColor3 = Color3.new(1,1,1); TitleLabel.BackgroundTransparency=1
    TitleLabel.Position = UDim2.new(0,20,0,10); TitleLabel.Size = UDim2.new(0,200,0,30); TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local CloseBtn = Instance.new("TextButton", MainFrame)
    CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.new(0.6,0.6,0.6); CloseBtn.BackgroundTransparency=1; CloseBtn.Font=Enum.Font.SourceSansBold; CloseBtn.TextSize=18
    CloseBtn.Position = UDim2.new(1,-30,0,10); CloseBtn.Size = UDim2.new(0,20,0,20)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local Sidebar = Instance.new("Frame", MainFrame)
    Sidebar.BackgroundColor3 = Color3.fromRGB(10,10,10); Sidebar.BackgroundTransparency=0.5; Sidebar.Position=UDim2.new(0,10,0,50); Sidebar.Size=UDim2.new(0,60,0,290)
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0,8)
    Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0,10); Instance.new("UIListLayout", Sidebar).HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ContentContainer = Instance.new("Frame", MainFrame)
    ContentContainer.BackgroundTransparency=1; ContentContainer.Position=UDim2.new(0,80,0,50); ContentContainer.Size=UDim2.new(0,460,0,290)

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
