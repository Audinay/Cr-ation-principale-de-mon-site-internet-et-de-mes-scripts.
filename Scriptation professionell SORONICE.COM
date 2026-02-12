-- [[ SORONICE UI LIBRARY - V7.0 (V6.1 + HEADER PRO + DROPDOWN) ]] --

local SoroniceLib = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService") 
local HttpService = game:GetService("HttpService")
local LocalPlayer = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")

-- --- [ DÉTECTION MOBILE ] ---
local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- --- [ CONFIGURATION GLOBALE ] ---
local Settings = {
	Keybind = Enum.KeyCode.P,
	ThemeColor = Color3.fromRGB(20, 20, 20),
	AccentColor = Color3.fromRGB(0, 54, 203),
    TextColor = Color3.fromRGB(255, 255, 255),      -- Couleur Texte Principal
    SubTextColor = Color3.fromRGB(180, 180, 180)    -- Couleur Sous-Texte
}

-- --- [ TABLEAU DES ÉLÉMENTS ACTIFS ] ---
local ActiveToggles = {} 

-- --- [ SYSTÈME AFK ] ---
local antiAfkActive = false
LocalPlayer.Idled:Connect(function()
    if antiAfkActive then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- --- [ AJOUT : DÉTECTION NOM DU JEU ] ---
local GameNameText = "Détection..."
task.spawn(function()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then
        GameNameText = info.Name
    else
        GameNameText = "Jeu Inconnu"
    end
end)

-- --- [ FONCTION LOGIN ] ---
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
    LoginGui.ResetOnSpawn = false
    local BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Parent = game.Lighting
    BlurEffect.Size = 24
    local BackgroundImage = Instance.new("ImageLabel")
    BackgroundImage.Parent = LoginGui
    BackgroundImage.AnchorPoint = Vector2.new(0.5, 0.5)
    BackgroundImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    BackgroundImage.Size = UDim2.new(0, 500, 0, 350)
    BackgroundImage.Image = "rbxassetid://114617892791025"
    BackgroundImage.BackgroundTransparency = 1
    local TitleText = Instance.new("TextLabel")
    TitleText.Parent = BackgroundImage
    TitleText.BackgroundTransparency = 1
    TitleText.Position = UDim2.new(0.1, 0, 0.04, 0)
    TitleText.Size = UDim2.new(0.5, 0, 0.15, 0)
    TitleText.Font = Enum.Font.FredokaOne
    TitleText.Text = SettingsLogin.Title or "ACCÈS PREMIUM"
    TitleText.TextColor3 = Color3.new(1,1,1)
    TitleText.TextScaled = true
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    local CloseButton = Instance.new("TextButton")
    CloseButton.Parent = BackgroundImage
    CloseButton.BackgroundTransparency = 1
    CloseButton.Position = UDim2.new(0.92, 0, 0.14, 0)
    CloseButton.Size = UDim2.new(0.06, 0, 0.08, 0)
    CloseButton.Text = ""
    CloseButton.MouseButton1Click:Connect(function() LoginGui:Destroy() BlurEffect:Destroy() script:Destroy() end)
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
    local LinkBtn = Instance.new("TextButton")
    LinkBtn.Parent = BackgroundImage
    LinkBtn.BackgroundColor3 = Color3.fromRGB(167, 167, 167)
    LinkBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
    LinkBtn.AnchorPoint = Vector2.new(0.5, 0)
    LinkBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
    LinkBtn.Text = SettingsLogin.LinkText or "Obtenir la clé"
    LinkBtn.Font = Enum.Font.SourceSans
    LinkBtn.TextSize = 14
    Instance.new("UICorner", LinkBtn).CornerRadius = UDim.new(0, 10)
    local function Verify()
        if PasswordBox.Text == RealPassword then Validated = true LoginGui:Destroy() BlurEffect:Destroy()
        else PasswordBox.Text = "" PasswordBox.PlaceholderText = "Mot de passe INCORRECT !" wait(1.5) PasswordBox.PlaceholderText = "Entrez la clé ici..." end
    end
    ValidateBtn.MouseButton1Click:Connect(Verify)
    LinkBtn.MouseButton1Click:Connect(function()
        if SettingsLogin.Link then setclipboard(SettingsLogin.Link) LinkBtn.Text = "Lien copié !" wait(2) LinkBtn.Text = SettingsLogin.LinkText or "Obtenir la clé" end
    end)
    repeat wait() until Validated or not LoginGui.Parent
    if not Validated then script:Destroy() while true do wait(999) end end
end


-- --- [ CRÉATION DE LA FENÊTRE ] ---

function SoroniceLib:CreateWindow(Config)
    if Config.KeySystem == true then SpawnLoginSystem(Config.KeySettings or {}) end

	local TitleName = Config.Name or "SORONICE HUB"
    -- [NOUVEAUX PARAMÈTRES RÉCUPÉRÉS]
    local BrandLogoId = Config.BrandLogo or "" 
    local VersionTagText = Config.VersionTag or "" 
    local StatusIconsList = Config.StatusIcons or {}

	if CoreGui:FindFirstChild("Soronice_V6") then CoreGui:FindFirstChild("Soronice_V6"):Destroy() end
    if CoreGui:FindFirstChild("Soronice_V7") then CoreGui:FindFirstChild("Soronice_V7"):Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Soronice_V7"
	ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    -- [APPLY LOCK FUNCTION]
    local function ApplyLock(TargetFrame, ElementConfig)
        if not ElementConfig then return false end
        
        local IsLocked = ElementConfig.Locked or false
        local LockReason = nil 

        if ElementConfig.BannedUsers and type(ElementConfig.BannedUsers) == "table" then
            for _, bannedId in pairs(ElementConfig.BannedUsers) do
                if LocalPlayer.UserId == bannedId then
                    IsLocked = true
                    LockReason = "Banned"
                    break
                end
            end
        end

        if not LockReason and ElementConfig.GamePassID then
            IsLocked = true 
            LockReason = "Gamepass"
        end

        if IsLocked then
            TargetFrame.ClipsDescendants = true 
            local LockOverlay = Instance.new("ImageButton")
            LockOverlay.Name = "LockOverlay"
            LockOverlay.Parent = TargetFrame
            LockOverlay.BackgroundTransparency = 1
            LockOverlay.Size = UDim2.new(1, 0, 1, 0)
            LockOverlay.Position = UDim2.new(0, 0, 0, 0)
            LockOverlay.ZIndex = 50 
            LockOverlay.Image = "rbxassetid://139868914964686" 
            LockOverlay.ImageTransparency = 0.53 
            LockOverlay.MouseButton1Click:Connect(function()
                if LockReason == "Gamepass" and ElementConfig.GamePassID then
                    MarketplaceService:PromptGamePassPurchase(LocalPlayer, ElementConfig.GamePassID)
                elseif LockReason == "Banned" then
                    game.StarterGui:SetCore("SendNotification", {Title = "Accès Refusé", Text = "Permission refusée.", Duration = 3})
                end
            end)
            return true 
        end
        return false 
    end

    -- [BOUTON MAISON MOBILE]
    local MobileOpenBtn = nil
    if IsMobile then
        MobileOpenBtn = Instance.new("ImageButton")
        MobileOpenBtn.Name = "MobileOpenButton"
        MobileOpenBtn.Parent = ScreenGui
        MobileOpenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        MobileOpenBtn.BackgroundTransparency = 0.2
        MobileOpenBtn.Position = UDim2.new(0.1, 0, 0.1, 0) 
        MobileOpenBtn.Size = UDim2.new(0, 50, 0, 50)
        MobileOpenBtn.Image = Config.MobileImage or "rbxassetid://133601263847208"
        MobileOpenBtn.Visible = false 
        Instance.new("UICorner", MobileOpenBtn).CornerRadius = UDim.new(0, 12)
        local dragging_mob, dragInput_mob, dragStart_mob, startPos_mob
        MobileOpenBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging_mob = true
                dragStart_mob = input.Position
                startPos_mob = MobileOpenBtn.Position
            end
        end)
        MobileOpenBtn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput_mob = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput_mob and dragging_mob then
                local delta = input.Position - dragStart_mob
                MobileOpenBtn.Position = UDim2.new(startPos_mob.X.Scale, startPos_mob.X.Offset + delta.X, startPos_mob.Y.Scale, startPos_mob.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging_mob = false
            end
        end)
    end

	-- MAIN FRAME
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.BackgroundColor3 = Settings.ThemeColor
	MainFrame.BackgroundTransparency = 0.2
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local TargetSize
    if IsMobile then
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0) 
        TargetSize = UDim2.new(0, 400, 0, 270) -- Ajusté pour le nouveau header
    else
	    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        TargetSize = UDim2.new(0, 550, 0, 360) -- Ajusté pour le nouveau header
    end
    
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.ClipsDescendants = true 
    TweenService:Create(MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = TargetSize}):Play()
	
	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 10)
	MainCorner.Parent = MainFrame

	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Parent = MainFrame
	TopBar.BackgroundTransparency = 1 
	TopBar.Size = UDim2.new(1, 0, 0, 50) -- [MODIFIÉ: Plus grand pour contenir les infos]
    TopBar.Position = UDim2.new(0,0,0,0)
    TopBar.ZIndex = 10

    -- [NOUVEAU: CONTAINER GAUCHE (LOGO + TEXTES)]
    local LeftContainer = Instance.new("Frame", TopBar)
    LeftContainer.BackgroundTransparency = 1
    LeftContainer.Position = UDim2.new(0, 10, 0, 0)
    LeftContainer.Size = UDim2.new(0.6, 0, 1, 0)
    
    local LeftLayout = Instance.new("UIListLayout", LeftContainer)
    LeftLayout.FillDirection = Enum.FillDirection.Horizontal
    LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LeftLayout.Padding = UDim.new(0, 10)
    LeftLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- 1. Logo de Marque (Optionnel)
    if BrandLogoId ~= "" then
        local BrandLogo = Instance.new("ImageLabel", LeftContainer)
        BrandLogo.Size = UDim2.new(0, 32, 0, 32)
        BrandLogo.BackgroundTransparency = 1
        BrandLogo.Image = "rbxassetid://" .. BrandLogoId
        BrandLogo.LayoutOrder = 1
    end

    -- Container Textes Vertical
    local TextVerticalContainer = Instance.new("Frame", LeftContainer)
    TextVerticalContainer.BackgroundTransparency = 1
    TextVerticalContainer.Size = UDim2.new(0, 200, 0, 38)
    TextVerticalContainer.LayoutOrder = 2

	local TitleLabel = Instance.new("TextLabel", TextVerticalContainer)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Size = UDim2.new(1, 0, 0.6, 0)
	TitleLabel.Font = Enum.Font.FredokaOne
	TitleLabel.Text = TitleName
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleLabel.TextSize = 18
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- [AJOUT: NOM DU JEU SOUS LE TITRE]
    local GameLabel = Instance.new("TextLabel", TextVerticalContainer)
    GameLabel.BackgroundTransparency = 1
    GameLabel.Position = UDim2.new(0,0,0.6,0)
    GameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    GameLabel.Font = Enum.Font.SourceSans
    GameLabel.Text = GameNameText 
    GameLabel.TextColor3 = Settings.AccentColor
    GameLabel.TextSize = 14
    GameLabel.TextXAlignment = Enum.TextXAlignment.Left
    task.spawn(function()
        while GameNameText == "Détection..." do wait(0.1) end
        GameLabel.Text = GameNameText
    end)

    -- [NOUVEAU: CONTAINER DROITE]
    local RightContainer = Instance.new("Frame", TopBar)
    RightContainer.BackgroundTransparency = 1
    RightContainer.AnchorPoint = Vector2.new(1, 0)
    RightContainer.Position = UDim2.new(1, -10, 0, 0)
    RightContainer.Size = UDim2.new(0.4, 0, 1, 0)

    local RightLayout = Instance.new("UIListLayout", RightContainer)
    RightLayout.FillDirection = Enum.FillDirection.Horizontal
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RightLayout.Padding = UDim.new(0, 8)
    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Tag de Version
    if VersionTagText ~= "" then
        local TagContainer = Instance.new("Frame", RightContainer)
        TagContainer.BackgroundColor3 = Settings.AccentColor
        TagContainer.Size = UDim2.new(0, 0, 0, 20)
        TagContainer.AutomaticSize = Enum.AutomaticSize.X
        Instance.new("UICorner", TagContainer).CornerRadius = UDim.new(0, 4)
        local TagLabel = Instance.new("TextLabel", TagContainer)
        TagLabel.BackgroundTransparency = 1; TagLabel.Size = UDim2.new(1, 0, 1, 0); TagLabel.Font = Enum.Font.SourceSansBold
        TagLabel.Text = " " .. VersionTagText .. " "; TagLabel.TextColor3 = Settings.TextColor; TagLabel.TextSize = 12
    end

    -- Icônes de Statut
    if #StatusIconsList > 0 then
        local StatusContainer = Instance.new("Frame", RightContainer)
        StatusContainer.BackgroundTransparency = 1
        StatusContainer.Size = UDim2.new(0, 0, 0, 24)
        StatusContainer.AutomaticSize = Enum.AutomaticSize.X
        local StatusLayout = Instance.new("UIListLayout", StatusContainer); StatusLayout.FillDirection = Enum.FillDirection.Horizontal; StatusLayout.Padding = UDim.new(0, 5)
        for _, iconId in ipairs(StatusIconsList) do
            local Icon = Instance.new("ImageLabel", StatusContainer); Icon.Size = UDim2.new(0, 24, 0, 24); Icon.BackgroundTransparency = 1; Icon.Image = "rbxassetid://" .. iconId; Icon.ImageColor3 = Settings.SubTextColor
        end
    end
    
    -- [BOUTON DE RECHERCHE (LOUPE) AVEC TON NOUVEL ID]
    local SearchBtn = Instance.new("ImageButton", RightContainer) -- Parenté au RightContainer
    SearchBtn.Name = "SearchButton"
    SearchBtn.BackgroundTransparency = 1
    SearchBtn.Size = UDim2.new(0, 30, 0, 30)
    SearchBtn.Image = "rbxassetid://76095216033555" 
    SearchBtn.ImageColor3 = Color3.fromRGB(150, 150, 150)

	local MinBtn = Instance.new("TextButton", RightContainer)
	MinBtn.Name = "Minimize"
	MinBtn.BackgroundTransparency = 1
	MinBtn.Size = UDim2.new(0, 30, 0, 30)
	MinBtn.Font = Enum.Font.SourceSansBold
	MinBtn.Text = "-"
	MinBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	MinBtn.TextSize = 24
    
	local CloseBtn = Instance.new("TextButton", RightContainer)
	CloseBtn.Name = "Close"
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.Font = Enum.Font.SourceSansBold
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	CloseBtn.TextSize = 20

	local IsHidden = false
    local isAnimating = false

    local function ToggleVisibility()
        if isAnimating then return end
        isAnimating = true
        IsHidden = not IsHidden
        
        if IsHidden then
            local closeT = TweenService:Create(MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0)})
            closeT:Play()
            closeT.Completed:Wait()
            MainFrame.Visible = false
            if IsMobile and MobileOpenBtn then MobileOpenBtn.Visible = true end
        else
            if IsMobile and MobileOpenBtn then MobileOpenBtn.Visible = false end
            MainFrame.Visible = true
            local openT = TweenService:Create(MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = TargetSize})
            openT:Play()
            openT.Completed:Wait()
        end
        isAnimating = false
    end

	MinBtn.MouseButton1Click:Connect(ToggleVisibility)
    if IsMobile and MobileOpenBtn then MobileOpenBtn.MouseButton1Click:Connect(ToggleVisibility) end
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not IsMobile and not gameProcessed and input.KeyCode == Settings.Keybind then ToggleVisibility() end
    end)

	CloseBtn.MouseButton1Click:Connect(function() 
        for _, ToggleData in pairs(ActiveToggles) do
            if ToggleData.Callback then
                ToggleData.Callback(false) 
            end
        end
        local CloseTween = TweenService:Create(MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0)})
        CloseTween:Play()
        CloseTween.Completed:Wait() 
        ScreenGui:Destroy() 
    end)

    -- [BARRE DE RECHERCHE]
    local SearchBarFrame = Instance.new("Frame")
    SearchBarFrame.Name = "SearchBar"
    SearchBarFrame.Parent = MainFrame
    SearchBarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    SearchBarFrame.BorderSizePixel = 0
    SearchBarFrame.Position = UDim2.new(0, 80, 0, 55) -- Position ajustée
    SearchBarFrame.Size = UDim2.new(1, -90, 0, 0)
    SearchBarFrame.Visible = false
    SearchBarFrame.ClipsDescendants = true
    SearchBarFrame.ZIndex = 5
    Instance.new("UICorner", SearchBarFrame).CornerRadius = UDim.new(0, 6)

    local SearchInput = Instance.new("TextBox")
    SearchInput.Parent = SearchBarFrame
    SearchInput.BackgroundTransparency = 1
    SearchInput.Position = UDim2.new(0, 10, 0, 0)
    SearchInput.Size = UDim2.new(1, -20, 1, 0)
    SearchInput.Font = Enum.Font.SourceSans
    SearchInput.PlaceholderText = "Rechercher..."
    SearchInput.Text = ""
    SearchInput.TextColor3 = Color3.new(1, 1, 1)
    SearchInput.TextSize = 16
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ZIndex = 6

    local SearchOpen = false
    local isSearchAnimating = false

    local function ToggleSearch()
        if isSearchAnimating then return end
        isSearchAnimating = true
        SearchOpen = not SearchOpen

        if SearchOpen then
            SearchBarFrame.Visible = true
            TweenService:Create(SearchBarFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, -90, 0, 30)}):Play()
            SearchInput:CaptureFocus()
        else
            local closeTween = TweenService:Create(SearchBarFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, -90, 0, 0)})
            closeTween:Play()
            closeTween.Completed:Wait()
            SearchBarFrame.Visible = false
            SearchInput.Text = "" 
        end
        isSearchAnimating = false
    end
    SearchBtn.MouseButton1Click:Connect(ToggleSearch)

    UserInputService.InputBegan:Connect(function(input)
        if SearchOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local searchAbsPos = SearchBarFrame.AbsolutePosition
            local searchAbsSize = SearchBarFrame.AbsoluteSize
            -- Pas de fermeture automatique si on clique dessus, logique simple
            if not (mousePos.X >= searchAbsPos.X and mousePos.X <= searchAbsPos.X + searchAbsSize.X and mousePos.Y >= searchAbsPos.Y and mousePos.Y <= searchAbsPos.Y + searchAbsSize.Y) then
                 -- Si on clique en dehors
                 ToggleSearch()
            end
        end
    end)

    -- [DRAGGING SUR LA TOPBAR]
    -- On doit s'assurer que le drag ne se lance pas si on clique sur un bouton de la TopBar
	local dragging, dragInput, dragStart, startPos
	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local overButton = false
            -- Vérif simple si on est sur le container de droite (boutons)
            if input.Position.X > RightContainer.AbsolutePosition.X then overButton = true end
            
            if not overButton then
    			dragging = true
	    		dragStart = input.Position
		    	startPos = MainFrame.Position
            end
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

	local Sidebar = Instance.new("Frame")
	Sidebar.Parent = MainFrame
	Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	Sidebar.BackgroundTransparency = 0.5
	Sidebar.Position = UDim2.new(0, 10, 0, 60) -- Décalé vers le bas à cause du nouveau Header
	Sidebar.Size = UDim2.new(0, 60, 1, -70) 
    Sidebar.ClipsDescendants = true 
	local SidebarCorner = Instance.new("UICorner")
	SidebarCorner.CornerRadius = UDim.new(0, 8)
	SidebarCorner.Parent = Sidebar
    
    local SidebarScroll = Instance.new("ScrollingFrame")
    SidebarScroll.Parent = Sidebar
    SidebarScroll.BackgroundTransparency = 1
    SidebarScroll.Position = UDim2.new(0, 0, 0, 0)
    SidebarScroll.Size = UDim2.new(1, 0, 1, -50) 
    SidebarScroll.ScrollBarThickness = 0
    SidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
	local SidebarLayout = Instance.new("UIListLayout")
	SidebarLayout.Parent = SidebarScroll
	SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SidebarLayout.Padding = UDim.new(0, 10)
	SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	local ContentContainer = Instance.new("Frame")
	ContentContainer.Parent = MainFrame
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Position = UDim2.new(0, 80, 0, 60) -- Décalé vers le bas
    if IsMobile then
        ContentContainer.Size = UDim2.new(0, 310, 0, 200)
    else
	    ContentContainer.Size = UDim2.new(0, 460, 0, 290)
    end
    ContentContainer.ClipsDescendants = true 

    -- [FILTRAGE]
    local function FilterItems(searchText)
        searchText = string.lower(searchText)
        for _, page in pairs(ContentContainer:GetChildren()) do
            if page:IsA("ScrollingFrame") and page.Visible then
                for _, element in pairs(page:GetChildren()) do
                    if element:IsA("Frame") and element:GetAttribute("SearchName") then
                        local itemName = element:GetAttribute("SearchName")
                        if string.find(itemName, searchText) then
                            element.Visible = true
                        else
                            element.Visible = false
                        end
                    end
                end
            end
        end
    end
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        FilterItems(SearchInput.Text)
    end)


	local SettingsBtn = Instance.new("TextButton")
	SettingsBtn.Name = "Settings_Btn"
	SettingsBtn.Parent = Sidebar 
	SettingsBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	SettingsBtn.BackgroundTransparency = 0.5
    SettingsBtn.Position = UDim2.new(0.5, -22, 1, -50) 
    SettingsBtn.AnchorPoint = Vector2.new(0, 0) 
	SettingsBtn.Size = UDim2.new(0, 45, 0, 45)
	SettingsBtn.Text = ""
    SettingsBtn.ZIndex = 2 
    Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 8)
	local SettingsIcon = Instance.new("ImageLabel")
	SettingsIcon.Parent = SettingsBtn
	SettingsIcon.BackgroundTransparency = 1
	SettingsIcon.Position = UDim2.new(0, 5, 0, 5)
	SettingsIcon.Size = UDim2.new(0, 35, 0, 35)
	SettingsIcon.Image = "rbxassetid://74182569229556"

    local SettingsPage = Instance.new("ScrollingFrame")
    SettingsPage.Name = "Settings_Page"
    SettingsPage.Parent = ContentContainer
    SettingsPage.BackgroundTransparency = 1
    SettingsPage.Size = UDim2.new(1, 0, 1, 0)
    SettingsPage.ScrollBarThickness = 4
    SettingsPage.Visible = false 
    SettingsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
    SettingsPage.CanvasSize = UDim2.new(0,0,0,0)

    local SettingsLayout = Instance.new("UIListLayout")
    SettingsLayout.Parent = SettingsPage
    SettingsLayout.Padding = UDim.new(0, 8)
    SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    SettingsBtn.MouseButton1Click:Connect(function()
        for _, v in pairs(ContentContainer:GetChildren()) do v.Visible = false end
        SettingsPage.Visible = true
        for _, btn in pairs(SidebarScroll:GetChildren()) do
            if btn:IsA("TextButton") then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play() end
        end
        TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
    end)

	local WindowFunctions = {}
	local FirstTab = true

    local function CreateElement(Page, Type, Config)
        if Type == "Button" then
            local BtnFrame = Instance.new("Frame", Page)
			BtnFrame.BackgroundColor3 = Color3.fromRGB(30,30,30); BtnFrame.Size=UDim2.new(1,-10,0,35)
            Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0,6)
            BtnFrame:SetAttribute("SearchName", string.lower(Config.Name))

			local Btn = Instance.new("TextButton", BtnFrame)
			Btn.BackgroundTransparency=1; Btn.Size=UDim2.new(1,0,1,0); Btn.Font=Enum.Font.SourceSans; Btn.Text="  "..Config.Name; Btn.TextColor3=Color3.new(1,1,1); Btn.TextSize=16; Btn.TextXAlignment=Enum.TextXAlignment.Left
			
            local Locked = ApplyLock(BtnFrame, Config)

            if not Locked then 
    			Btn.MouseButton1Click:Connect(function() 
                    TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play(); wait(0.1)
                    TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(30,30,30)}):Play()
                    if Config.Callback then Config.Callback() end 
                end)
            else
                Btn.Active = false 
            end

        elseif Type == "Toggle" then
            local ToggleFrame = Instance.new("Frame", Page); ToggleFrame.BackgroundTransparency=1; ToggleFrame.Size=UDim2.new(1,-10,0,35)
            ToggleFrame:SetAttribute("SearchName", string.lower(Config.Name))

            local Label = Instance.new("TextLabel", ToggleFrame); Label.BackgroundTransparency=1; Label.Size=UDim2.new(0.7,0,1,0); Label.Position=UDim2.new(0,10,0,0); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.TextSize=16; Label.Font=Enum.Font.SourceSans
            local SwitchBg = Instance.new("Frame", ToggleFrame); SwitchBg.BackgroundColor3=Color3.fromRGB(40,40,40); SwitchBg.Position=UDim2.new(1,-60,0.5,-12); SwitchBg.Size=UDim2.new(0,50,0,24)
            Instance.new("UICorner", SwitchBg).CornerRadius=UDim.new(1,0)
            local Knob = Instance.new("Frame", SwitchBg); Knob.BackgroundColor3=Color3.new(1,1,1); Knob.Position=UDim2.new(0,2,0.5,-10); Knob.Size=UDim2.new(0,20,0,20)
            Instance.new("UICorner", Knob).CornerRadius=UDim.new(1,0)
            
            local Locked = ApplyLock(ToggleFrame, Config)

            local Toggled = Config.CurrentValue or false
            
            table.insert(ActiveToggles, {Callback = Config.Callback})

            local function Update()
                local TargetPos = Toggled and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
                local TargetCol = Toggled and Settings.AccentColor or Color3.fromRGB(40,40,40)
                TweenService:Create(Knob, TweenInfo.new(0.2), {Position=TargetPos}):Play()
                TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3=TargetCol}):Play()
                
                if Config.Callback then Config.Callback(Toggled) end
            end
            if Toggled then Update() end
            
            local Btn = Instance.new("TextButton", SwitchBg); Btn.BackgroundTransparency=1; Btn.Size=UDim2.new(1,0,1,0); Btn.Text=""
            if not Locked then
                Btn.MouseButton1Click:Connect(function() Toggled = not Toggled; Update() end)
            else
                Btn.Active = false
            end

        elseif Type == "Keybind" then
            local BindFrame = Instance.new("Frame", Page)
            BindFrame.BackgroundColor3 = Color3.fromRGB(30,30,30); BindFrame.Size=UDim2.new(1,-10,0,35)
            Instance.new("UICorner", BindFrame).CornerRadius = UDim.new(0,6)
            BindFrame:SetAttribute("SearchName", string.lower(Config.Name))

            local Label = Instance.new("TextLabel", BindFrame); Label.BackgroundTransparency=1; Label.Size=UDim2.new(0.7,0,1,0); Label.Position=UDim2.new(0,10,0,0); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.TextSize=16; Label.Font=Enum.Font.SourceSans
            local BindBtn = Instance.new("TextButton", BindFrame)
            BindBtn.BackgroundColor3 = Color3.fromRGB(40,40,40); BindBtn.Position=UDim2.new(1,-80,0.5,-12); BindBtn.Size=UDim2.new(0,70,0,24)
            BindBtn.Text = UserInputService:GetStringForKeyCode(Settings.Keybind)
            BindBtn.Font = Enum.Font.SourceSansBold; BindBtn.TextColor3 = Color3.new(1,1,1); BindBtn.TextSize = 14
            Instance.new("UICorner", BindBtn).CornerRadius=UDim.new(0,6)
            BindBtn.MouseButton1Click:Connect(function()
                BindBtn.Text = "..."
                local InputConnection
                InputConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        Settings.Keybind = input.KeyCode
                        BindBtn.Text = UserInputService:GetStringForKeyCode(input.KeyCode)
                        InputConnection:Disconnect()
                        game.StarterGui:SetCore("SendNotification", {Title = "Réglages", Text = "Nouvelle touche : " .. BindBtn.Text, Duration = 3})
                    end
                end)
            end)
        elseif Type == "Label" then
            local LabelFrame = Instance.new("Frame", Page); LabelFrame.BackgroundTransparency=1; LabelFrame.Size=UDim2.new(1,-10,0,25)
            LabelFrame:SetAttribute("SearchName", string.lower(Config.Text))
            local Txt = Instance.new("TextLabel", LabelFrame); Txt.BackgroundTransparency=1; Txt.Size=UDim2.new(1,0,1,0); Txt.Position=UDim2.new(0,10,0,0)
            Txt.Text = Config.Text; Txt.TextColor3 = Color3.new(1,1,1); Txt.TextXAlignment=Enum.TextXAlignment.Left; Txt.Font=Enum.Font.SourceSans; Txt.TextSize=16
        elseif Type == "Section" then
            local SectionFrame = Instance.new("Frame", Page); SectionFrame.BackgroundTransparency=1; SectionFrame.Size=UDim2.new(1,-10,0,30)
            SectionFrame:SetAttribute("SearchName", string.lower(Config.Text))
            local Txt = Instance.new("TextLabel", SectionFrame); Txt.BackgroundTransparency=1; Txt.Size=UDim2.new(1,0,1,0); Txt.Position=UDim2.new(0,10,0,0)
            Txt.Text = Config.Text; Txt.TextColor3 = Settings.AccentColor; Txt.TextXAlignment=Enum.TextXAlignment.Left; Txt.Font=Enum.Font.SourceSansBold; Txt.TextSize=18
        
        elseif Type == "ColorPicker" then
            local ColorFrame = Instance.new("Frame", Page)
            ColorFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); ColorFrame.Size = UDim2.new(1, -10, 0, 160)
            Instance.new("UICorner", ColorFrame).CornerRadius = UDim.new(0, 6)
            ColorFrame:SetAttribute("SearchName", string.lower(Config.Name))

            local Locked = ApplyLock(ColorFrame, Config)

            local Label = Instance.new("TextLabel", ColorFrame); Label.BackgroundTransparency=1; Label.Position=UDim2.new(0,10,0,5); Label.Size=UDim2.new(1,0,0,20)
            Label.Text = Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Font=Enum.Font.SourceSansBold; Label.TextSize=16

            local Preview = Instance.new("Frame", ColorFrame); Preview.Position=UDim2.new(0,10,0,30); Preview.Size=UDim2.new(0,30,0,30); Preview.BackgroundColor3=Config.Color or Color3.new(1,1,1)
            Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 4)

            local SVBox = Instance.new("TextButton", ColorFrame); SVBox.Position=UDim2.new(0, 60, 0, 30); SVBox.Size=UDim2.new(0, 150, 0, 100); SVBox.BackgroundColor3=Color3.new(1,0,0); SVBox.Text=""
            local SVGrad = Instance.new("UIGradient", SVBox); SVGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.new(1,1,1)), ColorSequenceKeypoint.new(1, Color3.new(1,0,0))}
            local SVBlack = Instance.new("ImageLabel", SVBox); SVBlack.Size=UDim2.new(1,0,1,0); SVBlack.Image="rbxassetid://156579757"; SVBlack.BackgroundTransparency=1
            
            local HueBar = Instance.new("TextButton", ColorFrame); HueBar.Position=UDim2.new(0, 60, 0, 135); HueBar.Size=UDim2.new(0, 150, 0, 15); HueBar.Text=""
            local HueGrad = Instance.new("UIGradient", HueBar); HueGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.new(1,0,0)), ColorSequenceKeypoint.new(0.167, Color3.new(1,1,0)), ColorSequenceKeypoint.new(0.333, Color3.new(0,1,0)),
                ColorSequenceKeypoint.new(0.5, Color3.new(0,1,1)), ColorSequenceKeypoint.new(0.667, Color3.new(0,0,1)), ColorSequenceKeypoint.new(0.833, Color3.new(1,0,1)), ColorSequenceKeypoint.new(1, Color3.new(1,0,0))
            }

            local function CreateInput(Placeholder, XOffset)
                local Box = Instance.new("TextBox", ColorFrame); Box.BackgroundColor3=Color3.fromRGB(40,40,40); Box.Position=UDim2.new(0, 220, 0, XOffset); Box.Size=UDim2.new(0, 40, 0, 25)
                Box.Font=Enum.Font.SourceSans; Box.PlaceholderText=Placeholder; Box.Text=""; Box.TextColor3=Color3.new(1,1,1); Box.TextSize=14
                Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
                return Box
            end
            local RBox = CreateInput("R", 30); local GBox = CreateInput("G", 60); local BBox = CreateInput("B", 90)
            local HexBox = Instance.new("TextBox", ColorFrame); HexBox.BackgroundColor3=Color3.fromRGB(40,40,40); HexBox.Position=UDim2.new(0, 220, 0, 120); HexBox.Size=UDim2.new(0, 60, 0, 25)
            HexBox.Font=Enum.Font.SourceSans; HexBox.PlaceholderText="#Hex"; HexBox.Text=""; HexBox.TextColor3=Color3.new(1,1,1); HexBox.TextSize=14
            Instance.new("UICorner", HexBox).CornerRadius = UDim.new(0, 4)

            local H, S, V = 0, 1, 1
            local function UpdateColor(NewH, NewS, NewV)
                H, S, V = NewH or H, NewS or S, NewV or V
                local NewColor = Color3.fromHSV(H, S, V)
                Preview.BackgroundColor3 = NewColor
                SVBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                RBox.Text = math.floor(NewColor.R * 255); GBox.Text = math.floor(NewColor.G * 255); BBox.Text = math.floor(NewColor.B * 255)
                if Config.Callback then Config.Callback(NewColor) end
            end

            if not Locked then
                local draggingHue, draggingSV = false, false
                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                        if draggingHue then
                            local percent = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                            UpdateColor(percent, nil, nil)
                        elseif draggingSV then
                            local s = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                            local v = 1 - math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                            UpdateColor(nil, s, v)
                        end
                    end
                end)
                HueBar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then draggingHue=true end end)
                SVBox.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then draggingSV=true end end)
                UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then draggingHue=false; draggingSV=false end end)
                local function FromRGB()
                    local r, g, b = tonumber(RBox.Text) or 0, tonumber(GBox.Text) or 0, tonumber(BBox.Text) or 0
                    local col = Color3.fromRGB(r, g, b)
                    local h, s, v = col:ToHSV()
                    UpdateColor(h, s, v)
                end
                RBox.FocusLost:Connect(FromRGB); GBox.FocusLost:Connect(FromRGB); BBox.FocusLost:Connect(FromRGB)
            else
                 RBox.Editable = false; GBox.Editable = false; BBox.Editable = false; HexBox.Editable = false
                 SVBox.Active = false; HueBar.Active = false
            end
        
        -- [NOUVEL ÉLÉMENT : MENU DÉROULANT (DROPDOWN)]
        elseif Type == "Dropdown" then
            local DropdownFrame = Instance.new("Frame", Page)
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(30,30,30); DropdownFrame.Size = UDim2.new(1, -10, 0, 35) 
            DropdownFrame.ClipsDescendants = true
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 6)
            DropdownFrame:SetAttribute("SearchName", string.lower(Config.Name))

            local Locked = ApplyLock(DropdownFrame, Config)
            local DropdownOpen = false
            local Options = Config.Options or {}
            local CurrentOption = Config.CurrentOption or Options[1] or "Sélectionner..."
            
            -- Bouton Principal
            local MainBtn = Instance.new("TextButton", DropdownFrame)
            MainBtn.BackgroundTransparency = 1; MainBtn.Size = UDim2.new(1, 0, 0, 35)
            MainBtn.Font = Enum.Font.SourceSans; MainBtn.Text = "  " .. Config.Name .. ": " .. CurrentOption
            MainBtn.TextColor3 = Color3.new(1,1,1); MainBtn.TextSize = 16; MainBtn.TextXAlignment = Enum.TextXAlignment.Left
            
            local ArrowIcon = Instance.new("ImageLabel", MainBtn)
            ArrowIcon.BackgroundTransparency = 1; ArrowIcon.Position = UDim2.new(1, -30, 0, 7); ArrowIcon.Size = UDim2.new(0, 20, 0, 20)
            ArrowIcon.Image = "rbxassetid://6034818372"

            -- Conteneur des options
            local OptionsContainer = Instance.new("Frame", DropdownFrame)
            OptionsContainer.BackgroundTransparency = 1; OptionsContainer.Position = UDim2.new(0, 0, 0, 35)
            OptionsContainer.Size = UDim2.new(1, 0, 0, 0); OptionsContainer.Visible = false
            local OptionsLayout = Instance.new("UIListLayout", OptionsContainer); OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder

            -- Création des boutons d'option
            for i, option in ipairs(Options) do
                local OptBtn = Instance.new("TextButton", OptionsContainer)
                OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); OptBtn.Size = UDim2.new(1, 0, 0, 30)
                OptBtn.Font = Enum.Font.SourceSans; OptBtn.Text = option; OptBtn.TextColor3 = Color3.fromRGB(200,200,200); OptBtn.TextSize = 14; OptBtn.BorderSizePixel = 0
                
                OptBtn.MouseButton1Click:Connect(function()
                    CurrentOption = option
                    MainBtn.Text = "  " .. Config.Name .. ": " .. CurrentOption
                    if Config.Callback then Config.Callback(CurrentOption) end
                    -- Fermer le dropdown après sélection
                    DropdownOpen = false
                    TweenService:Create(ArrowIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                    local closeT = TweenService:Create(DropdownFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, -10, 0, 35)})
                    closeT:Play(); closeT.Completed:Wait(); OptionsContainer.Visible = false
                end)
            end

            if not Locked then
                MainBtn.MouseButton1Click:Connect(function()
                    DropdownOpen = not DropdownOpen
                    if DropdownOpen then
                        OptionsContainer.Visible = true
                        local targetHeight = 35 + (#Options * 30)
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.2), {Rotation = 180}):Play()
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, -10, 0, targetHeight)}):Play()
                    else
                        TweenService:Create(ArrowIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                        local closeT = TweenService:Create(DropdownFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, -10, 0, 35)})
                        closeT:Play(); closeT.Completed:Wait(); OptionsContainer.Visible = false
                    end
                end)
            else MainBtn.Active = false end
        end
    end

    CreateElement(SettingsPage, "Toggle", {
        Name = "💤 Mode AFK (Anti-Kick)",
        CurrentValue = false,
        Callback = function(Value)
            antiAfkActive = Value
            if Value then game.StarterGui:SetCore("SendNotification", {Title = "Anti-AFK", Text = "Activé : Vous ne serez pas kické.", Duration = 3}) end
        end
    })
    
    if not IsMobile then CreateElement(SettingsPage, "Keybind", { Name = "Touche pour Cacher/Montrer", Callback = function() end }) end

	function WindowFunctions:CreateTab(TabName, TabImageId, LockConfig) 
		local TabBtn = Instance.new("TextButton", SidebarScroll) 
		TabBtn.BackgroundColor3 = Color3.new(0,0,0); TabBtn.BackgroundTransparency=0.5; TabBtn.Size=UDim2.new(0,45,0,45); TabBtn.Text=""
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0,8)
		if TabImageId and TabImageId ~= 0 then
			local Icon = Instance.new("ImageLabel", TabBtn)
			Icon.BackgroundTransparency=1; Icon.Position=UDim2.new(0,5,0,5); Icon.Size=UDim2.new(0,35,0,35); Icon.Image="rbxassetid://"..tostring(TabImageId)
		else
			TabBtn.Text = string.sub(TabName, 1, 1); TabBtn.TextColor3 = Color3.new(0.8,0.8,0.8); TabBtn.TextSize=20; TabBtn.Font=Enum.Font.SourceSansBold
		end

        -- [APPLY LOCK ON TAB BUTTON]
        local IsButtonLocked = false
        if LockConfig and LockConfig.Locked then
             if LockConfig.LockMode ~= "Frame" then 
                 IsButtonLocked = ApplyLock(TabBtn, LockConfig) 
             end
        end

		local Page = Instance.new("ScrollingFrame", ContentContainer)
		Page.BackgroundTransparency=1; Page.Size=UDim2.new(1,0,1,0); Page.ScrollBarThickness=6; Page.Visible=FirstTab
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y 
        Page.CanvasSize = UDim2.new(0,0,0,0)
        Page.VerticalScrollBarInset = Enum.ScrollBarInset.None

        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding = UDim.new(0,8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        -- [APPLY LOCK ON PAGE CONTENT]
        if LockConfig and LockConfig.Locked and LockConfig.LockMode == "Frame" then 
            ApplyLock(Page, LockConfig) 
        end

		TabBtn.MouseButton1Click:Connect(function()
            if IsButtonLocked then return end

            if SearchOpen then ToggleSearch() end

			for _,v in pairs(ContentContainer:GetChildren()) do v.Visible=false end
			Page.Visible=true
            TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play()
		end)
		FirstTab = false

		local TabFunctions = {}
		function TabFunctions:CreateButton(Config) CreateElement(Page, "Button", Config) end
        function TabFunctions:CreateToggle(Config) CreateElement(Page, "Toggle", Config) end
        function TabFunctions:CreateColorPicker(Config) CreateElement(Page, "ColorPicker", Config) end 
        function TabFunctions:CreateSection(Text) CreateElement(Page, "Section", {Text=Text}) end
        function TabFunctions:CreateLabel(Text) CreateElement(Page, "Label", {Text=Text}) end
        function TabFunctions:CreateDropdown(Config) CreateElement(Page, "Dropdown", Config) end -- [AJOUT FONCTION DROPDOWN]
        
        function TabFunctions:CreateSlider(Config)
             local SliderFrame = Instance.new("Frame", Page); SliderFrame.BackgroundTransparency=1; SliderFrame.Size=UDim2.new(1,-10,0,50)
             -- AJOUT ATTRIBUT POUR RECHERCHE
             SliderFrame:SetAttribute("SearchName", string.lower(Config.Name))

             local Locked = ApplyLock(SliderFrame, Config)
             local Label = Instance.new("TextLabel", SliderFrame); Label.BackgroundTransparency=1; Label.Position=UDim2.new(0,10,0,0); Label.Size=UDim2.new(1,0,0,20); Label.Text=Config.Name; Label.TextColor3=Color3.new(1,1,1); Label.TextXAlignment=Enum.TextXAlignment.Left; Label.Font=Enum.Font.SourceSans; Label.TextSize=16
             local ValLabel = Instance.new("TextLabel", SliderFrame); ValLabel.BackgroundTransparency=1; ValLabel.Position=UDim2.new(1,-60,0,0); ValLabel.Size=UDim2.new(0,50,0,20); ValLabel.TextColor3=Color3.new(1,1,1); ValLabel.TextXAlignment=Enum.TextXAlignment.Right; ValLabel.Font=Enum.Font.SourceSansBold; ValLabel.TextSize=16
             local Bar = Instance.new("Frame", SliderFrame); Bar.BackgroundColor3=Color3.fromRGB(10,10,10); Bar.Position=UDim2.new(0,10,0,25); Bar.Size=UDim2.new(1,-20,0,10); Instance.new("UICorner", Bar).CornerRadius=UDim.new(1,0)
             local Knob = Instance.new("TextButton", Bar); Knob.BackgroundColor3=Settings.AccentColor; Knob.Size=UDim2.new(0,20,0,20); Knob.AnchorPoint=Vector2.new(0.5,0.5); Knob.Position=UDim2.new(0,0,0.5,0); Knob.Text=""; Instance.new("UICorner", Knob).CornerRadius=UDim.new(1,0)
             local Min, Max = Config.Range[1] or 0, Config.Range[2] or 100
             local Default = Config.CurrentValue or Min; ValLabel.Text = tostring(Default).."%"
             Knob.Position = UDim2.new((Default-Min)/(Max-Min), 0, 0.5, 0)
             
             if not Locked then
                 local dragging = false
                 Knob.InputBegan:Connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end 
                 end)
                 UserInputService.InputEnded:Connect(function(input) 
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end 
                 end)
                 UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local Percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X, 0, 1)
                        Knob.Position = UDim2.new(Percent, 0, 0.5, 0)
                        local Val = math.floor(Min + (Max-Min)*Percent)
                        ValLabel.Text = tostring(Val).."%"
                        if Config.Callback then Config.Callback(Val) end
                    end
                 end)
            else
                Knob.Active = false 
            end
        end
		return TabFunctions
	end
	return WindowFunctions
end
return SoroniceLib
