-- [[ SORONICE UI LIBRARY CORRIGÉE ]] --

local SoroniceLib = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- :: FONCTIONS UTILITAIRES :: --
local function MakeDraggable(topbarobject, object)
	local Dragging = nil
	local DragInput = nil
	local DragStart = nil
	local StartPosition = nil

	local function Update(input)
		local Delta = input.Position - DragStart
		object.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
	end

	topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = input.Position
			StartPosition = object.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	topbarobject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			DragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then
			Update(input)
		end
	end)
end

-- :: DÉBUT DE LA CRÉATION DE FENÊTRE :: --

function SoroniceLib:CreateWindow(Config)
	local TitleName = Config.Name or "SORONICE HUB"
	
	-- 1. Création du ScreenGui Principal
	-- On vérifie s'il existe déjà pour ne pas avoir de doublons
	if game.CoreGui:FindFirstChild("SoroniceLib_UI") then
		game.CoreGui:FindFirstChild("SoroniceLib_UI"):Destroy()
	end

	local MPKLM = Instance.new("ScreenGui")
	MPKLM.Name = "SoroniceLib_UI"
	MPKLM.Parent = game.CoreGui
	MPKLM.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	MPKLM.ResetOnSpawn = false

	-- 2. Le Conteneur Principal
	local MainContainer = Instance.new("Frame")
	MainContainer.Name = "MainContainer"
	MainContainer.Parent = MPKLM
	MainContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainContainer.BackgroundTransparency = 1.000
	MainContainer.Position = UDim2.new(0.268, 0, 0.179, 0)
	MainContainer.Size = UDim2.new(0.462, 0, 0.093, 0)

	-- 3. La fenêtre principale (HJP1)
	local HJP1 = Instance.new("Frame")
	HJP1.Name = "HJP1"
	HJP1.Parent = MainContainer
	HJP1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	HJP1.BackgroundTransparency = 0.600
	HJP1.Size = UDim2.new(1, 0, 6.979, 0)
    
    -- Rendre la fenêtre déplaçable
    MakeDraggable(HJP1, MainContainer)

	-- Header (Titre)
	local HeaderFrame = Instance.new("Frame")
	HeaderFrame.Name = "Header"
	HeaderFrame.Parent = HJP1
	HeaderFrame.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
	HeaderFrame.Size = UDim2.new(1, 0, 0.149, 0)
	Instance.new("UICorner", HeaderFrame)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Parent = HeaderFrame
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0, 10, 0, 0)
	TitleLabel.Size = UDim2.new(0.8, 0, 1, 0)
	TitleLabel.Font = Enum.Font.SourceSansBold
	TitleLabel.Text = TitleName
	TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleLabel.TextScaled = true
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Bouton Fermer (X)
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Name = "Close"
	CloseBtn.Parent = HJP1
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.Position = UDim2.new(0.94, 0, 0, 0)
	CloseBtn.Size = UDim2.new(0.06, 0, 0.11, 0)
	CloseBtn.Font = Enum.Font.SourceSansBold
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	CloseBtn.TextScaled = true
	
	CloseBtn.MouseButton1Click:Connect(function()
		MPKLM:Destroy()
	end)

	-- Zone des Onglets (Sidebar)
	local SidebarFrame = Instance.new("Frame")
	SidebarFrame.Name = "Sidebar"
	SidebarFrame.Parent = HJP1
	SidebarFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	SidebarFrame.BackgroundTransparency = 0.98
	SidebarFrame.Position = UDim2.new(0.022, 0, 0.18, 0)
	SidebarFrame.Size = UDim2.new(0.14, 0, 0.78, 0)
	Instance.new("UICorner", SidebarFrame)
    
    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Parent = SidebarFrame
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 5)

	-- Zone des Pages (Contenu)
	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Parent = HJP1
	ContentArea.BackgroundTransparency = 1
	ContentArea.Position = UDim2.new(0.18, 0, 0.18, 0)
	ContentArea.Size = UDim2.new(0.80, 0, 0.78, 0)

	local Window = {}
    local FirstTab = true

	-- :: FONCTION : Notify (Ajoutée pour compatibilité) ::
	function SoroniceLib:Notify(Config)
		-- Simple print pour l'instant ou création d'une petite frame
		-- Tu peux customiser ça plus tard
		print("[NOTIF]: " .. (Config.Title or "") .. " - " .. (Config.Content or ""))
	end

	function Window:CreateTab(TabName, TabIcon)
		TabName = TabName or "Tab"
		TabIcon = TabIcon or 0 -- ID Image
		
		-- 1. Création du bouton dans la Sidebar
		local TabButton = Instance.new("TextButton")
		TabButton.Name = TabName .. "_Btn"
		TabButton.Parent = SidebarFrame
		TabButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        if FirstTab then 
            TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40) 
        end
		TabButton.Size = UDim2.new(1, 0, 0.15, 0)
		TabButton.Font = Enum.Font.SourceSansBold
		TabButton.Text = ""
		TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		
		local TabCorner = Instance.new("UICorner")
		TabCorner.Parent = TabButton
		
        -- Texte de l'onglet (si pas d'icone)
        local TitleTab = Instance.new("TextLabel")
        TitleTab.Parent = TabButton
        TitleTab.BackgroundTransparency = 1
        TitleTab.Size = UDim2.new(1,0,1,0)
        TitleTab.Text = TabName
        TitleTab.TextColor3 = Color3.fromRGB(255,255,255)
        TitleTab.Font = Enum.Font.SourceSansBold
        TitleTab.TextSize = 14

		-- 2. Création de la Page
		local PageFrame = Instance.new("ScrollingFrame")
		PageFrame.Name = TabName .. "_Page"
		PageFrame.Parent = ContentArea
		PageFrame.BackgroundTransparency = 1
		PageFrame.Size = UDim2.new(1, 0, 1, 0)
		PageFrame.ScrollBarThickness = 4
        PageFrame.Visible = FirstTab 
        
        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = PageFrame
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)
        
        -- Logique de changement d'onglet
        TabButton.MouseButton1Click:Connect(function()
            for _, child in pairs(ContentArea:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, btn in pairs(SidebarFrame:GetChildren()) do
                if btn:IsA("TextButton") then 
                    TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play()
                end
            end
            PageFrame.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
        end)

        FirstTab = false 

		local TabFunctions = {}

		-- :: ÉLÉMENT : BUTTON :: --
		function TabFunctions:CreateButton(BtnConfig)
			local BtnText = BtnConfig.Name or "Button"
			local Callback = BtnConfig.Callback or function() end

			local BtnContainer = Instance.new("Frame")
			BtnContainer.Name = BtnText .. "_Container"
			BtnContainer.Parent = PageFrame
			BtnContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			BtnContainer.BackgroundTransparency = 1
			BtnContainer.Size = UDim2.new(1, 0, 0.15, 0)

			local ActualBtn = Instance.new("TextButton")
			ActualBtn.Parent = BtnContainer
			ActualBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ActualBtn.BackgroundTransparency = 1
			ActualBtn.Position = UDim2.new(0.1, 0, 0, 0)
			ActualBtn.Size = UDim2.new(0.8, 0, 1, 0)
			ActualBtn.Font = Enum.Font.SourceSansBold
			ActualBtn.Text = ""
            ActualBtn.ZIndex = 2
			
            local VisualFrame = Instance.new("Frame")
            VisualFrame.Parent = ActualBtn
            VisualFrame.Size = UDim2.new(1,0,1,0)
            VisualFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
            Instance.new("UICorner", VisualFrame).CornerRadius = UDim.new(0, 10)
            
            local TextL = Instance.new("TextLabel")
            TextL.Parent = VisualFrame
            TextL.BackgroundTransparency = 1
            TextL.Size = UDim2.new(1,0,1,0)
            TextL.Font = Enum.Font.SourceSansBold
            TextL.Text = BtnText
            TextL.TextColor3 = Color3.fromRGB(255,255,255)
            TextL.TextSize = 18

			ActualBtn.MouseButton1Click:Connect(function()
                TweenService:Create(VisualFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
                wait(0.1)
                TweenService:Create(VisualFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30,30,30)}):Play()
				Callback()
			end)
		end

		-- :: ÉLÉMENT : TOGGLE :: --
		function TabFunctions:CreateToggle(ToggleConfig)
			local ToggleName = ToggleConfig.Name or "Toggle"
			local Default = ToggleConfig.CurrentValue or false
			local Callback = ToggleConfig.Callback or function() end

			local ToggleContainer = Instance.new("Frame")
			ToggleContainer.Name = ToggleName
			ToggleContainer.Parent = PageFrame
			ToggleContainer.BackgroundTransparency = 1
			ToggleContainer.Size = UDim2.new(1, 0, 0.18, 0)

            local Bg = Instance.new("Frame")
            Bg.Parent = ToggleContainer
            Bg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            Bg.Position = UDim2.new(0.05, 0, 0.1, 0)
            Bg.Size = UDim2.new(0.9, 0, 0.8, 0)
            Instance.new("UICorner", Bg).CornerRadius = UDim.new(0, 25)

            local Label = Instance.new("TextLabel")
            Label.Parent = Bg
            Label.BackgroundTransparency = 1
            Label.Position = UDim2.new(0.05, 0, 0, 0)
            Label.Size = UDim2.new(0.6, 0, 1, 0)
            Label.Font = Enum.Font.SourceSansBold
            Label.Text = ToggleName
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.TextSize = 16
            Label.TextXAlignment = Enum.TextXAlignment.Left

            local SwitchBg = Instance.new("Frame")
            SwitchBg.Parent = Bg
            SwitchBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            SwitchBg.Position = UDim2.new(0.7, 0, 0.15, 0)
            SwitchBg.Size = UDim2.new(0.25, 0, 0.7, 0)
            Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)

            local Knob = Instance.new("Frame")
            Knob.Parent = SwitchBg
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Size = UDim2.new(0.4, 0, 0.9, 0)
            Knob.Position = UDim2.new(0.05, 0, 0.05, 0)
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

            local Toggled = Default
            local IsAnimating = false

            local function UpdateToggle()
                IsAnimating = true
                if Toggled then
                    TweenService:Create(Knob, TweenInfo.new(0.3), {Position = UDim2.new(0.55, 0, 0.05, 0)}):Play()
                    TweenService:Create(SwitchBg, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(106, 0, 255)}):Play()
                    task.spawn(function() Callback(true) end)
                else
                    TweenService:Create(Knob, TweenInfo.new(0.3), {Position = UDim2.new(0.05, 0, 0.05, 0)}):Play()
                    TweenService:Create(SwitchBg, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(15, 15, 15)}):Play()
                    Callback(false)
                end
                wait(0.3)
                IsAnimating = false
            end
            
            if Default then 
                Knob.Position = UDim2.new(0.55, 0, 0.05, 0)
                SwitchBg.BackgroundColor3 = Color3.fromRGB(106, 0, 255)
                task.spawn(function() Callback(true) end)
            end

            local TriggerBtn = Instance.new("TextButton")
            TriggerBtn.Parent = SwitchBg
            TriggerBtn.BackgroundTransparency = 1
            TriggerBtn.Size = UDim2.new(1,0,1,0)
            TriggerBtn.Text = ""
            
            TriggerBtn.MouseButton1Click:Connect(function()
                if IsAnimating then return end
                Toggled = not Toggled
                UpdateToggle()
            end)
		end

		-- :: ÉLÉMENT : SLIDER :: --
		function TabFunctions:CreateSlider(SliderConfig)
			local SliderName = SliderConfig.Name or "Slider"
			local Min = SliderConfig.Range[1] or 0
			local Max = SliderConfig.Range[2] or 100
			local DefaultValue = SliderConfig.CurrentValue or Min
			local Callback = SliderConfig.Callback or function() end

			local SliderFrame = Instance.new("Frame")
			SliderFrame.Name = SliderName
			SliderFrame.Parent = PageFrame
			SliderFrame.BackgroundTransparency = 1
			SliderFrame.Size = UDim2.new(1, 0, 0.18, 0)

            local Title = Instance.new("TextLabel")
            Title.Parent = SliderFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0.1, 0, 0, 0)
            Title.Size = UDim2.new(0.8, 0, 0.4, 0)
            Title.Font = Enum.Font.SourceSansBold
            Title.Text = SliderName
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.TextXAlignment = Enum.TextXAlignment.Left

			local BarBg = Instance.new("Frame")
			BarBg.Parent = SliderFrame
            BarBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            BarBg.Position = UDim2.new(0.1, 0, 0.5, 0)
            BarBg.Size = UDim2.new(0.8, 0, 0.4, 0)
            Instance.new("UICorner", BarBg).CornerRadius = UDim.new(0, 25)

            local Fill = Instance.new("Frame")
            Fill.Parent = BarBg
            Fill.BackgroundColor3 = Color3.fromRGB(0, 76, 255)
            Fill.BackgroundTransparency = 0.2
            Fill.Size = UDim2.new(0, 0, 1, 0)
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 20)

            local SliderBtn = Instance.new("TextButton")
            SliderBtn.Parent = BarBg
            SliderBtn.BackgroundColor3 = Color3.fromRGB(0, 54, 203)
            SliderBtn.BorderColor3 = Color3.fromRGB(60, 255, 0)
            SliderBtn.BorderSizePixel = 0
            SliderBtn.Size = UDim2.new(0, 20, 1, 0)
            SliderBtn.Text = ""
            Instance.new("UICorner", SliderBtn).CornerRadius = UDim.new(0, 100)
            
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Parent = BarBg
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Position = UDim2.new(0.75, 0, -1, 0)
            ValueLabel.Size = UDim2.new(0.2, 0, 1, 0)
            ValueLabel.Font = Enum.Font.SourceSans
            ValueLabel.Text = tostring(DefaultValue)
            ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

            local dragging = false

            local function UpdateSliderInput(input)
                local pos = UDim2.new(math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1), 0, 0.5, 0)
                local scale = pos.X.Scale
                SliderBtn.Position = UDim2.new(scale, -10, 0, 0)
                Fill.Size = UDim2.new(scale, 0, 1, 0)
                
                local preciseValue = Min + ((Max - Min) * scale)
                local finalValue = math.floor(preciseValue)
                
                ValueLabel.Text = tostring(finalValue)
                Callback(finalValue)
            end

            SliderBtn.InputBegan:Connect(function(input)
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
                    UpdateSliderInput(input)
                end
            end)
		end

		return TabFunctions
	end

	return Window
end

-- LA LIGNE MAGIQUE QUI TE MANQUAIT :
return SoroniceLib
