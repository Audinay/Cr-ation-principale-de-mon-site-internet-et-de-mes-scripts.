-- [[ 
    SORONICE UI LIBRARY - VERSION V2 ULTIME (NON COMPRESSÉE)
    Script entièrement détaillé et étendu pour une lisibilité maximale.
    Intègre : Login System, AFK Invisible, Réglages, Dragging Sécurisé.
    Développé pour Soronice Hub.
]] --

local SoroniceLib = {}

-- :: SERVICES ROBLOX :: --
-- Nous récupérons tous les services nécessaires au fonctionnement du script
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser") -- Nécessaire pour le mode AFK invisible
local StarterGui = game:GetService("StarterGui")

-- :: VARIABLES LOCALES DU JOUEUR :: --
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- :: CONFIGURATION GLOBALE PAR DÉFAUT :: --
-- Ces paramètres peuvent être modifiés via le menu réglages
local Settings = {
    Keybind = Enum.KeyCode.P, -- Touche par défaut pour ouvrir/fermer le menu
    ThemeColor = Color3.fromRGB(20, 20, 20), -- Couleur de fond sombre
    AccentColor = Color3.fromRGB(0, 54, 203), -- Bleu Soronice (Boutons actifs)
    ToggleOffColor = Color3.fromRGB(40, 40, 40), -- Couleur quand désactivé
    TextColor = Color3.fromRGB(255, 255, 255) -- Couleur du texte
}

-- ============================================================================== --
--                            SYSTÈME AFK (ANTI-KICK)                             --
-- ============================================================================== --

local AfkEnabled = false
local AfkConnection = nil

-- Fonction pour activer ou désactiver le mode AFK
local function ToggleAfk(state)
    AfkEnabled = state
    
    if AfkEnabled then
        -- Connexion à l'événement Idled (quand le joueur ne bouge plus depuis 20 min)
        AfkConnection = LocalPlayer.Idled:Connect(function()
            if AfkEnabled then
                -- On simule un clic de souris virtuel
                -- Cela fait croire au serveur que le joueur est actif sans faire bouger le personnage
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                print("[Soronice Hub] Anti-Kick activé : Simulation d'activité invisible.")
            end
        end)
        
        -- Notification d'activation
        StarterGui:SetCore("SendNotification", {
            Title = "Mode AFK",
            Text = "Activé : Vous ne serez pas déconnecté (Méthode Invisible).",
            Duration = 5
        })
    else
        -- Désactivation : On coupe la connexion
        if AfkConnection then
            AfkConnection:Disconnect()
            AfkConnection = nil
        end
        
        StarterGui:SetCore("SendNotification", {
            Title = "Mode AFK",
            Text = "Désactivé.",
            Duration = 3
        })
    end
end

-- ============================================================================== --
--                          SYSTÈME DE LOGIN (MOT DE PASSE)                       --
-- ============================================================================== --

local function SpawnLoginSystem(SettingsLogin)
    local Validated = false
    local RealPassword = SettingsLogin.Key or "1234"
    
    -- Vérification si la clé doit être récupérée depuis un site web (Raw Text)
    if SettingsLogin.GrabKeyFromSite == true then
        local success, result = pcall(function()
            return game:HttpGet(SettingsLogin.Key)
        end)
        
        if success then
            -- Nettoyage de la chaîne de caractères (suppression des espaces vides et retours à la ligne)
            RealPassword = string.gsub(result, "\n", "")
            RealPassword = string.gsub(RealPassword, " ", "")
            RealPassword = string.gsub(RealPassword, "\r", "")
        else
            warn("[Soronice Hub] Erreur critique : Impossible de récupérer la clé en ligne.")
        end
    end

    -- Création du ScreenGui de Login
    local LoginGui = Instance.new("ScreenGui")
    LoginGui.Name = "SoroniceLoginSystem"
    LoginGui.Parent = CoreGui
    LoginGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Effet de Flou (Blur) dans le jeu
    local BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Parent = game.Lighting
    BlurEffect.Size = 24
    
    -- Cadre Invisible pour le centrage parfait
    local CenteringFrame = Instance.new("Frame")
    CenteringFrame.Parent = LoginGui
    CenteringFrame.BackgroundTransparency = 1
    CenteringFrame.Size = UDim2.new(1, 0, 1, 0)
    
    -- Image de Fond (Le Design Vert/Noir que tu as choisi)
    local BackgroundImage = Instance.new("ImageLabel")
    BackgroundImage.Name = "BackgroundImage"
    BackgroundImage.Parent = CenteringFrame
    BackgroundImage.AnchorPoint = Vector2.new(0.5, 0.5)
    BackgroundImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    BackgroundImage.BackgroundTransparency = 1.000
    BackgroundImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    BackgroundImage.Size = UDim2.new(0, 500, 0, 350)
    BackgroundImage.Image = "rbxassetid://114617892791025" -- Ton image de fond
    
    -- Titre "ACCÈS PREMIUM"
    local TitleText = Instance.new("TextLabel")
    TitleText.Parent = BackgroundImage
    TitleText.BackgroundTransparency = 1
    TitleText.Position = UDim2.new(0.1, 0, 0.04, 0)
    TitleText.Size = UDim2.new(0.5, 0, 0.15, 0)
    TitleText.Font = Enum.Font.FredokaOne
    TitleText.Text = SettingsLogin.Title or "ACCÈS PREMIUM"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextScaled = true
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Bouton Fermer (X)
    local CloseButton = Instance.new("TextButton")
    CloseButton.Parent = BackgroundImage
    CloseButton.BackgroundTransparency = 1
    CloseButton.Position = UDim2.new(0.92, 0, 0.14, 0)
    CloseButton.Size = UDim2.new(0.06, 0, 0.08, 0)
    CloseButton.Text = ""
    
    CloseButton.MouseButton1Click:Connect(function()
        LoginGui:Destroy()
        BlurEffect:Destroy()
        script:Destroy() -- Arrêt total du script si on ferme le login
    end)
    
    -- Bouton Réduire (-)
    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Parent = BackgroundImage
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Position = UDim2.new(0.85, 0, 0.14, 0)
    MinimizeButton.Size = UDim2.new(0.06, 0, 0.08, 0)
    MinimizeButton.Text = ""
    
    local IsLoginHidden = false
    MinimizeButton.MouseButton1Click:Connect(function()
        IsLoginHidden = true
        BackgroundImage.Visible = false
        StarterGui:SetCore("SendNotification", {
            Title = "Soronice Hub",
            Text = "Appuyez sur P pour rouvrir le login.",
            Duration = 5
        })
    end)
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.P and IsLoginHidden then
            IsLoginHidden = false
            BackgroundImage.Visible = true
        end
    end)
    
    -- Zone de saisie du Mot de Passe
    local InputBackground = Instance.new("ImageLabel")
    InputBackground.Parent = BackgroundImage
    InputBackground.BackgroundTransparency = 1
    InputBackground.Position = UDim2.new(0.18, 0, 0.42, 0)
    InputBackground.Size = UDim2.new(0.62, 0, 0.15, 0)
    InputBackground.Image = "rbxassetid://75238927890132"
    
    -- Icône Cadenas
    local LockIcon = Instance.new("ImageLabel")
    LockIcon.Parent = InputBackground
    LockIcon.BackgroundTransparency = 1
    LockIcon.Position = UDim2.new(-0.02, 0, 0.2, 0)
    LockIcon.Size = UDim2.new(0.1, 0, 0.6, 0)
    LockIcon.Image = "rbxassetid://110855536039004"
    
    -- Champ Texte (TextBox)
    local PasswordBox = Instance.new("TextBox")
    PasswordBox.Parent = InputBackground
    PasswordBox.BackgroundTransparency = 1
    PasswordBox.Position = UDim2.new(0.15, 0, 0, 0)
    PasswordBox.Size = UDim2.new(0.8, 0, 1, 0)
    PasswordBox.Font = Enum.Font.SourceSansBold
    PasswordBox.Text = ""
    PasswordBox.PlaceholderText = "Entrez la clé ici..."
    PasswordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    PasswordBox.TextSize = 18
    PasswordBox.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Bouton VALIDER
    local ValidateBtn = Instance.new("TextButton")
    ValidateBtn.Parent = BackgroundImage
    ValidateBtn.BackgroundColor3 = Color3.fromRGB(167, 167, 167)
    ValidateBtn.Position = UDim2.new(0.5, 0, 0.68, 0)
    ValidateBtn.AnchorPoint = Vector2.new(0.5, 0)
    ValidateBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
    ValidateBtn.Text = "VALIDER"
    ValidateBtn.Font = Enum.Font.SourceSansBold
    ValidateBtn.TextSize = 18
    
    local ValidateCorner = Instance.new("UICorner")
    ValidateCorner.CornerRadius = UDim.new(0, 10)
    ValidateCorner.Parent = ValidateBtn
    
    -- Bouton LIEN (Obtenir Clé)
    local LinkBtn = Instance.new("TextButton")
    LinkBtn.Parent = BackgroundImage
    LinkBtn.BackgroundColor3 = Color3.fromRGB(167, 167, 167)
    LinkBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
    LinkBtn.AnchorPoint = Vector2.new(0.5, 0)
    LinkBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
    LinkBtn.Text = SettingsLogin.LinkText or "Obtenir la clé"
    LinkBtn.Font = Enum.Font.SourceSans
    LinkBtn.TextSize = 14
    
    local LinkCorner = Instance.new("UICorner")
    LinkCorner.CornerRadius = UDim.new(0, 10)
    LinkCorner.Parent = LinkBtn
    
    -- Logique de validation du mot de passe
    local function VerifyPassword()
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
    
    ValidateBtn.MouseButton1Click:Connect(VerifyPassword)
    
    LinkBtn.MouseButton1Click:Connect(function()
        if SettingsLogin.Link then
            setclipboard(SettingsLogin.Link)
            LinkBtn.Text = "Lien copié dans le presse-papier !"
            wait(2)
            LinkBtn.Text = SettingsLogin.LinkText or "Obtenir la clé"
        end
    end)
    
    -- Boucle bloquante (Empêche le reste du script de charger tant que le login n'est pas passé)
    repeat wait() until Validated or not LoginGui.Parent
    
    if not Validated then
        script:Destroy()
        -- Boucle infinie de sécurité pour arrêter l'exécution si le joueur ferme sans valider
        while true do wait(99999) end
    end
end


-- ============================================================================== --
--                        CRÉATION DE LA FENÊTRE PRINCIPALE                       --
-- ============================================================================== --

function SoroniceLib:CreateWindow(Config)
    
    -- 1. Lancement du Login si l'option est activée dans la config
    if Config.KeySystem == true then
        SpawnLoginSystem(Config.KeySettings or {})
    end

    local TitleName = Config.Name or "SORONICE HUB"

    -- Nettoyage des anciennes instances pour éviter les doublons dans le CoreGui
    if CoreGui:FindFirstChild("Soronice_V6") then
        CoreGui:FindFirstChild("Soronice_V6"):Destroy()
    end

    -- Création du GUI Principal
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Soronice_V6"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Cadre Principal (MainFrame)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Settings.ThemeColor
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175) -- Centré au milieu de l'écran
    MainFrame.Size = UDim2.new(0, 550, 0, 350)
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    -- BARRE SUPÉRIEURE (TopBar) - Seule zone pour déplacer la fenêtre
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = MainFrame
    TopBar.BackgroundTransparency = 1
    TopBar.Size = UDim2.new(1, 0, 0, 40) -- Hauteur de 40 pixels
    TopBar.Position = UDim2.new(0, 0, 0, 0)

    -- Logique de Déplacement (Draggable) restreinte à la TopBar
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

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
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Titre du Hub
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

    -- BOUTON RÉDUIRE (-)
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeButton"
    MinimizeBtn.Parent = TopBar
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Position = UDim2.new(1, -60, 0, 5)
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Font = Enum.Font.SourceSansBold
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    MinimizeBtn.TextSize = 24
    
    local IsHidden = false
    local NotificationShown = false -- Variable pour empêcher le spam de notifications

    local function ToggleVisibility()
        IsHidden = not IsHidden
        MainFrame.Visible = not IsHidden
        
        -- On affiche la notification seulement la première fois qu'on cache le menu
        if IsHidden == true and NotificationShown == false then
            NotificationShown = true
            local KeyName = UserInputService:GetStringForKeyCode(Settings.Keybind)
            StarterGui:SetCore("SendNotification", {
                Title = "Soronice Hub",
                Text = "Appuyez sur '" .. KeyName .. "' pour afficher/cacher le menu.",
                Duration = 5
            })
        end
    end

    MinimizeBtn.MouseButton1Click:Connect(ToggleVisibility)

    -- Gestion de la touche clavier (Keybind) pour ouvrir/fermer
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Settings.Keybind then
            ToggleVisibility()
        end
    end)

    -- BOUTON FERMER (X)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseButton"
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
        -- On désactive le mode AFK en fermant le hub pour éviter les bugs
        ToggleAfk(false)
    end)

    -- SIDEBAR (Barre latérale gauche)
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
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

    -- CONTENEUR DE CONTENU (Pages)
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Parent = MainFrame
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Position = UDim2.new(0, 80, 0, 50)
    ContentContainer.Size = UDim2.new(0, 460, 0, 290)

    -- BOUTON RÉGLAGES (SETTINGS)
    -- Positionné en bas de la sidebar, centré
    local SettingsBtn = Instance.new("TextButton")
    SettingsBtn.Name = "Settings_Btn"
    SettingsBtn.Parent = MainFrame
    SettingsBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SettingsBtn.BackgroundTransparency = 0.5
    -- Centrage : Sidebar commence à X=10, largeur 60. Milieu = 40.
    -- Bouton largeur 45. 40 - (45/2) = 17.5. On arrondit à 18.
    SettingsBtn.Position = UDim2.new(0, 18, 1, -55) 
    SettingsBtn.Size = UDim2.new(0, 45, 0, 45)
    SettingsBtn.Text = ""
    
    local SettingsCorner = Instance.new("UICorner")
    SettingsCorner.CornerRadius = UDim.new(0, 8)
    SettingsCorner.Parent = SettingsBtn
    
    local SettingsIcon = Instance.new("ImageLabel")
    SettingsIcon.Parent = SettingsBtn
    SettingsIcon.BackgroundTransparency = 1
    SettingsIcon.Position = UDim2.new(0, 5, 0, 5)
    SettingsIcon.Size = UDim2.new(0, 35, 0, 35)
    SettingsIcon.Image = "rbxassetid://74182569229556" -- Image du Boulon que tu m'as donnée

    -- PAGE DES RÉGLAGES
    local SettingsPage = Instance.new("ScrollingFrame")
    SettingsPage.Name = "SettingsPage"
    SettingsPage.Parent = ContentContainer
    SettingsPage.BackgroundTransparency = 1
    SettingsPage.Size = UDim2.new(1, 0, 1, 0)
    SettingsPage.Visible = false
    SettingsPage.ScrollBarThickness = 2
    
    local SettingsPageLayout = Instance.new("UIListLayout")
    SettingsPageLayout.Parent = SettingsPage
    SettingsPageLayout.Padding = UDim.new(0, 8)

    -- Logique d'ouverture des réglages
    SettingsBtn.MouseButton1Click:Connect(function()
        -- Cacher toutes les pages
        for _, child in pairs(ContentContainer:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Visible = false
            end
        end
        -- Afficher la page réglages
        SettingsPage.Visible = true
        
        -- Réinitialiser la couleur des autres boutons
        for _, btn in pairs(Sidebar:GetChildren()) do
            if btn:IsA("TextButton") then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
            end
        end
        -- Mettre en surbrillance le bouton réglages
        TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
    end)

    -- :: SYSTÈME DE CRÉATION D'ÉLÉMENTS (FONCTIONS GÉNÉRIQUES) :: --
    
    local function CreateElement(ParentPage, ElementType, ElementConfig)
        
        -- TYPE: BOUTON SIMPLE
        if ElementType == "Button" then
            local BtnFrame = Instance.new("Frame")
            BtnFrame.Parent = ParentPage
            BtnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            BtnFrame.Size = UDim2.new(1, -10, 0, 35)
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 6)
            BtnCorner.Parent = BtnFrame
            
            local Btn = Instance.new("TextButton")
            Btn.Parent = BtnFrame
            Btn.BackgroundTransparency = 1
            Btn.Size = UDim2.new(1, 0, 1, 0)
            Btn.Font = Enum.Font.SourceSans
            Btn.Text = "  " .. ElementConfig.Name
            Btn.TextColor3 = Settings.TextColor
            Btn.TextSize = 16
            Btn.TextXAlignment = Enum.TextXAlignment.Left
            
            Btn.MouseButton1Click:Connect(function()
                -- Animation de clic
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                wait(0.1)
                TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
                -- Exécution du callback
                if ElementConfig.Callback then
                    ElementConfig.Callback()
                end
            end)

        -- TYPE: TOGGLE (BOUTON BASCULE)
        elseif ElementType == "Toggle" then
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Parent = ParentPage
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Size = UDim2.new(1, -10, 0, 35)
            
            local Label = Instance.new("TextLabel")
            Label.Parent = ToggleFrame
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.Text = ElementConfig.Name
            Label.TextColor3 = Settings.TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextSize = 16
            Label.Font = Enum.Font.SourceSans
            
            -- Fond du Switch
            local SwitchBg = Instance.new("Frame")
            SwitchBg.Parent = ToggleFrame
            SwitchBg.BackgroundColor3 = Settings.ToggleOffColor
            SwitchBg.Position = UDim2.new(1, -60, 0.5, -12)
            SwitchBg.Size = UDim2.new(0, 50, 0, 24)
            
            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(1, 0)
            SwitchCorner.Parent = SwitchBg
            
            -- Boule du Switch (Knob)
            local Knob = Instance.new("Frame")
            Knob.Parent = SwitchBg
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Position = UDim2.new(0, 2, 0.5, -10)
            Knob.Size = UDim2.new(0, 20, 0, 20)
            
            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = Knob
            
            local Toggled = ElementConfig.CurrentValue or false
            
            -- Fonction de mise à jour visuelle
            local function UpdateVisuals()
                local TargetPos
                local TargetColor
                
                if Toggled then
                    TargetPos = UDim2.new(1, -22, 0.5, -10)
                    TargetColor = Settings.AccentColor
                else
                    TargetPos = UDim2.new(0, 2, 0.5, -10)
                    TargetColor = Settings.ToggleOffColor
                end
                
                TweenService:Create(Knob, TweenInfo.new(0.2), {Position = TargetPos}):Play()
                TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = TargetColor}):Play()
                
                if ElementConfig.Callback then
                    ElementConfig.Callback(Toggled)
                end
            end
            
            -- Initialisation visuelle
            if Toggled then
                Knob.Position = UDim2.new(1, -22, 0.5, -10)
                SwitchBg.BackgroundColor3 = Settings.AccentColor
            end
            
            local TriggerBtn = Instance.new("TextButton")
            TriggerBtn.Parent = SwitchBg
            TriggerBtn.BackgroundTransparency = 1
            TriggerBtn.Size = UDim2.new(1, 0, 1, 0)
            TriggerBtn.Text = ""
            
            TriggerBtn.MouseButton1Click:Connect(function()
                Toggled = not Toggled
                UpdateVisuals()
            end)

        -- TYPE: KEYBIND (CHANGEMENT DE TOUCHE)
        elseif ElementType == "Keybind" then
            local BindFrame = Instance.new("Frame")
            BindFrame.Parent = ParentPage
            BindFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            BindFrame.Size = UDim2.new(1, -10, 0, 35)
            
            local BindCorner = Instance.new("UICorner")
            BindCorner.CornerRadius = UDim.new(0, 6)
            BindCorner.Parent = BindFrame
            
            local Label = Instance.new("TextLabel")
            Label.Parent = BindFrame
            Label.BackgroundTransparency = 1
            Label.Size = UDim2.new(0.7, 0, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.Text = ElementConfig.Name
            Label.TextColor3 = Settings.TextColor
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextSize = 16
            Label.Font = Enum.Font.SourceSans
            
            local BindBtn = Instance.new("TextButton")
            BindBtn.Parent = BindFrame
            BindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            BindBtn.Position = UDim2.new(1, -80, 0.5, -12)
            BindBtn.Size = UDim2.new(0, 70, 0, 24)
            BindBtn.Text = UserInputService:GetStringForKeyCode(Settings.Keybind)
            BindBtn.Font = Enum.Font.SourceSansBold
            BindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            BindBtn.TextSize = 14
            
            local BindBtnCorner = Instance.new("UICorner")
            BindBtnCorner.CornerRadius = UDim.new(0, 6)
            BindBtnCorner.Parent = BindBtn
            
            local Listening = false
            
            BindBtn.MouseButton1Click:Connect(function()
                Listening = true
                BindBtn.Text = "..."
                
                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        Settings.Keybind = input.KeyCode
                        BindBtn.Text = UserInputService:GetStringForKeyCode(input.KeyCode)
                        Listening = false
                        
                        StarterGui:SetCore("SendNotification", {
                            Title = "Réglages",
                            Text = "Nouvelle touche définie : " .. BindBtn.Text,
                            Duration = 3
                        })
                        
                        connection:Disconnect()
                    end
                end)
            end)
        end
    end

    -- :: REMPLISSAGE DE LA PAGE RÉGLAGES (AUTOMATIQUE) :: --
    
    -- Option 1 : Le mode AFK
    CreateElement(SettingsPage, "Toggle", {
        Name = "Mode AFK (Anti-Kick)",
        CurrentValue = false,
        Callback = function(Value)
            ToggleAfk(Value)
        end
    })
    
    -- Option 2 : Le changement de touche
    CreateElement(SettingsPage, "Keybind", {
        Name = "Touche pour Cacher/Montrer",
        Callback = function() end -- Logique interne au Keybind
    })

    local WindowFunctions = {}
    local FirstTab = true

    -- :: FONCTION PUBLIQUE : CRÉER UN ONGLET :: --
    function WindowFunctions:CreateTab(TabName, TabImageId)
        -- Création du bouton dans la sidebar
        local TabBtn = Instance.new("TextButton")
        TabBtn.Parent = Sidebar
        TabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        TabBtn.BackgroundTransparency = 0.5
        TabBtn.Size = UDim2.new(0, 45, 0, 45)
        TabBtn.Text = ""
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabBtn
        
        -- Gestion de l'icône ou du texte
        if TabImageId and TabImageId ~= 0 then
            local Icon = Instance.new("ImageLabel")
            Icon.Parent = TabBtn
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0, 5, 0, 5)
            Icon.Size = UDim2.new(0, 35, 0, 35)
            Icon.Image = "rbxassetid://" .. tostring(TabImageId)
            Icon.ScaleType = Enum.ScaleType.Fit
        else
            TabBtn.Text = string.sub(TabName, 1, 1)
            TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            TabBtn.TextSize = 20
            TabBtn.Font = Enum.Font.SourceSansBold
        end

        -- Création de la page de contenu
        local Page = Instance.new("ScrollingFrame")
        Page.Name = TabName .. "_Page"
        Page.Parent = ContentContainer
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 2
        Page.Visible = FirstTab -- Visible seulement si c'est le premier onglet
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = Page
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 8)

        -- Événement de clic sur l'onglet
        TabBtn.MouseButton1Click:Connect(function()
            -- Cacher toutes les pages
            for _, v in pairs(ContentContainer:GetChildren()) do
                v.Visible = false
            end
            -- Afficher la page actuelle
            Page.Visible = true
            
            -- Réinitialiser l'icône de réglages
            TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}):Play()
        end)
        
        FirstTab = false

        local TabFunctions = {}
        
        -- :: FONCTION PUBLIQUE : CRÉER UN BOUTON :: --
        function TabFunctions:CreateButton(Config)
            CreateElement(Page, "Button", Config)
        end
        
        -- :: FONCTION PUBLIQUE : CRÉER UN TOGGLE :: --
        function TabFunctions:CreateToggle(Config)
            CreateElement(Page, "Toggle", Config)
        end
        
        -- :: FONCTIONS DE CORRECTION (POUR ÉVITER LES ERREURS CONSOLE) :: --
        -- Ces fonctions existent mais sont vides pour empêcher le script de planter si appelé
        function TabFunctions:CreateColorPicker(Config)
            -- Fonctionnalité à venir, laissée vide pour éviter l'erreur "Missing Method"
        end
        
        function TabFunctions:CreateSection(Name)
            -- Section visuelle simple (non implémentée pour l'instant)
        end
        
        function TabFunctions:CreateLabel(Text)
            -- Label simple (non implémenté pour l'instant)
        end

        -- :: FONCTION PUBLIQUE : CRÉER UN SLIDER (BARRE DE DÉFILEMENT) :: --
        function TabFunctions:CreateSlider(Config)
             local SliderFrame = Instance.new("Frame")
             SliderFrame.Parent = Page
             SliderFrame.BackgroundTransparency = 1
             SliderFrame.Size = UDim2.new(1, -10, 0, 50)
             
             local Label = Instance.new("TextLabel")
             Label.Parent = SliderFrame
             Label.BackgroundTransparency = 1
             Label.Position = UDim2.new(0, 10, 0, 0)
             Label.Size = UDim2.new(1, 0, 0, 20)
             Label.Text = Config.Name
             Label.TextColor3 = Settings.TextColor
             Label.TextXAlignment = Enum.TextXAlignment.Left
             Label.Font = Enum.Font.SourceSans
             Label.TextSize = 16
             
             local ValLabel = Instance.new("TextLabel")
             ValLabel.Parent = SliderFrame
             ValLabel.BackgroundTransparency = 1
             ValLabel.Position = UDim2.new(1, -60, 0, 0)
             ValLabel.Size = UDim2.new(0, 50, 0, 20)
             ValLabel.TextColor3 = Settings.TextColor
             ValLabel.TextXAlignment = Enum.TextXAlignment.Right
             ValLabel.Font = Enum.Font.SourceSansBold
             ValLabel.TextSize = 16
             
             local Bar = Instance.new("Frame")
             Bar.Parent = SliderFrame
             Bar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
             Bar.Position = UDim2.new(0, 10, 0, 25)
             Bar.Size = UDim2.new(1, -20, 0, 10)
             
             local BarCorner = Instance.new("UICorner")
             BarCorner.CornerRadius = UDim.new(1, 0)
             BarCorner.Parent = Bar
             
             local Knob = Instance.new("TextButton")
             Knob.Parent = Bar
             Knob.BackgroundColor3 = Settings.AccentColor
             Knob.Size = UDim2.new(0, 20, 0, 20)
             Knob.AnchorPoint = Vector2.new(0.5, 0.5)
             Knob.Position = UDim2.new(0, 0, 0.5, 0)
             Knob.Text = ""
             
             local KnobCorner = Instance.new("UICorner")
             KnobCorner.CornerRadius = UDim.new(1, 0)
             KnobCorner.Parent = Knob
             
             local Min = Config.Range[1] or 0
             local Max = Config.Range[2] or 100
             local Default = Config.CurrentValue or Min
             
             ValLabel.Text = tostring(Default) .. "%"
             Knob.Position = UDim2.new((Default - Min) / (Max - Min), 0, 0.5, 0)

             local dragging = false
             
             Knob.InputBegan:Connect(function(input)
                 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                     dragging = true
                 end
             end)
             
             UserInputService.InputEnded:Connect(function(input)
                 if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                     dragging = false
                 end
             end)
             
             UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local SizeX = Bar.AbsoluteSize.X
                    local PosX = input.Position.X - Bar.AbsolutePosition.X
                    local Percent = math.clamp(PosX / SizeX, 0, 1)
                    
                    Knob.Position = UDim2.new(Percent, 0, 0.5, 0)
                    
                    local Val = math.floor(Min + (Max - Min) * Percent)
                    ValLabel.Text = tostring(Val) .. "%"
                    
                    if Config.Callback then
                        Config.Callback(Val)
                    end
                end
             end)
        end

        return TabFunctions
    end

    return WindowFunctions
end

return SoroniceLib
