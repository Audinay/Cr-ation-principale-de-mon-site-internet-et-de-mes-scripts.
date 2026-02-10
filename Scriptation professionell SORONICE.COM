-- [[ SORONICE UI LIBRARY - STYLE V6 ]] --

local SoroniceLib = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Couleurs du Thème (Style Image 2)
local Theme = {
	MainBackground = Color3.fromRGB(20, 20, 20),
	SidebarBackground = Color3.fromRGB(10, 10, 10), -- Plus sombre
	Text = Color3.fromRGB(255, 255, 255),
	Accent = Color3.fromRGB(0, 54, 203), -- Le bleu de tes sliders
	ToggleOff = Color3.fromRGB(40, 40, 40),
	ToggleOn = Color3.fromRGB(0, 54, 203)
}

-- Fonction pour déplacer la fenêtre
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

function SoroniceLib:CreateWindow(Config)
	local TitleName = Config.Name or "SORONICE HUB"

	-- Nettoyage des anciennes fenêtres
	if game.CoreGui:FindFirstChild("Soronice_V6") then
		game.CoreGui:FindFirstChild("Soronice_V6"):Destroy()
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Soronice_V6"
	ScreenGui.Parent = game.CoreGui
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- LA FENÊTRE PRINCIPALE (Main)
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.BackgroundColor3 = Theme.MainBackground
	MainFrame.BackgroundTransparency = 0.2 -- Légèrement transparent comme sur l'image
	MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175) -- Centré
	MainFrame.Size = UDim2.new(0, 550, 0, 350) -- Taille rectangle standard
	
	-- Coins arrondis (Juste ce qu'il faut)
	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 10)
	MainCorner.Parent = MainFrame

	MakeDraggable(MainFrame, MainFrame)

	-- TITRE (En haut à gauche)
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Parent = MainFrame
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0, 20, 0, 10)
	TitleLabel.Size = UDim2.new(0, 200, 0, 30)
	TitleLabel.Font = Enum.Font.SourceSansBold
	TitleLabel.Text = TitleName
	TitleLabel.TextColor3 = Theme.Text
	TitleLabel.TextSize = 22
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- BOUTON FERMER (X) - Petit et discret
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Name = "Close"
	CloseBtn.Parent = MainFrame
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.Position = UDim2.new(1, -30, 0, 10)
	CloseBtn.Size = UDim2.new(0, 20, 0, 20)
	CloseBtn.Font = Enum.Font.SourceSansBold
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	CloseBtn.TextSize = 18
	
	CloseBtn.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	-- SIDEBAR (Colonne de gauche pour les onglets)
	local Sidebar = Instance.new("Frame")
	Sidebar.Parent = MainFrame
	Sidebar.BackgroundColor3 = Theme.SidebarBackground
	Sidebar.BackgroundTransparency = 0.5
	Sidebar.Position = UDim2.new(0, 10, 0, 50)
	Sidebar.Size = UDim2.new(0, 60, 0, 290) -- Colonne fine
	
	local SidebarCorner = Instance.new("UICorner")
	SidebarCorner.CornerRadius = UDim.new(0, 8)
	SidebarCorner.Parent = Sidebar

	local SidebarLayout = Instance.new("UIListLayout")
	SidebarLayout.Parent = Sidebar
	SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SidebarLayout.Padding = UDim.new(0, 10)
	SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- ZONE DE CONTENU (Là où il y a les boutons)
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Parent = MainFrame
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Position = UDim2.new(0, 80, 0, 50)
	ContentContainer.Size = UDim2.new(0, 460, 0, 290)

	local WindowFunctions = {}
	local FirstTab = true

	-- :: CRÉATION D'ONGLET (Carrés à gauche) :: --
	function WindowFunctions:CreateTab(TabName, TabImageId)
		-- Le bouton carré dans la sidebar
		local TabBtn = Instance.new("TextButton")
		TabBtn.Parent = Sidebar
		TabBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TabBtn.BackgroundTransparency = 0.5
		TabBtn.Size = UDim2.new(0, 45, 0, 45) -- Carré
		TabBtn.Text = ""
		
		local TabBtnCorner = Instance.new("UICorner")
		TabBtnCorner.CornerRadius = UDim.new(0, 8)
		TabBtnCorner.Parent = TabBtn

		-- L'image (Icone)
		if TabImageId and TabImageId ~= 0 then
			local Icon = Instance.new("ImageLabel")
			Icon.Parent = TabBtn
			Icon.BackgroundTransparency = 1
			Icon.Position = UDim2.new(0, 5, 0, 5)
			Icon.Size = UDim2.new(0, 35, 0, 35)
			Icon.Image = "rbxassetid://" .. tostring(TabImageId)
			Icon.ScaleType = Enum.ScaleType.Fit
		else
			-- Si pas d'image, on met la première lettre
			TabBtn.Text = string.sub(TabName, 1, 1)
			TabBtn.TextColor3 = Color3.fromRGB(200,200,200)
			TabBtn.TextSize = 20
			TabBtn.Font = Enum.Font.SourceSansBold
		end

		-- La page de contenu
		local Page = Instance.new("ScrollingFrame")
		Page.Name = TabName
		Page.Parent = ContentContainer
		Page.BackgroundTransparency = 1
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.ScrollBarThickness = 2
		Page.Visible = FirstTab

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.Parent = Page
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 8)

		-- Changement d'onglet
		TabBtn.MouseButton1Click:Connect(function()
			for _, v in pairs(ContentContainer:GetChildren()) do
				v.Visible = false
			end
			Page.Visible = true
		end)

		FirstTab = false
		local TabFunctions = {}

		-- :: 1. BOUTON (Petit, rectangle, propre) :: --
		function TabFunctions:CreateButton(Config)
			local Name = Config.Name or "Button"
			local Callback = Config.Callback or function() end

			local BtnFrame = Instance.new("Frame")
			BtnFrame.Parent = Page
			BtnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Fond sombre
			BtnFrame.Size = UDim2.new(1, -10, 0, 35) -- Hauteur fine
			
			local BtnCorner = Instance.new("UICorner")
			BtnCorner.CornerRadius = UDim.new(0, 6)
			BtnCorner.Parent = BtnFrame

			local Btn = Instance.new("TextButton")
			Btn.Parent = BtnFrame
			Btn.BackgroundTransparency = 1
			Btn.Size = UDim2.new(1, 0, 1, 0)
			Btn.Font = Enum.Font.SourceSans
			Btn.Text = "  " .. Name
			Btn.TextColor3 = Theme.Text
			Btn.TextSize = 16
			Btn.TextXAlignment = Enum.TextXAlignment.Left

			Btn.MouseButton1Click:Connect(function()
				TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
				wait(0.1)
				TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
				Callback()
			end)
		end

		-- :: 2. TOGGLE (Petit, à droite, discret) :: --
		function TabFunctions:CreateToggle(Config)
			local Name = Config.Name or "Toggle"
			local Callback = Config.Callback or function() end
			local Default = Config.CurrentValue or false

			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Parent = Page
			ToggleFrame.BackgroundTransparency = 1
			ToggleFrame.Size = UDim2.new(1, -10, 0, 35)

			local Label = Instance.new("TextLabel")
			Label.Parent = ToggleFrame
			Label.BackgroundTransparency = 1
			Label.Size = UDim2.new(0.7, 0, 1, 0)
			Label.Position = UDim2.new(0, 10, 0, 0)
			Label.Font = Enum.Font.SourceSans
			Label.Text = Name
			Label.TextColor3 = Theme.Text
			Label.TextSize = 16
			Label.TextXAlignment = Enum.TextXAlignment.Left

			-- Le bouton bascule (Switch)
			local SwitchBg = Instance.new("Frame")
			SwitchBg.Parent = ToggleFrame
			SwitchBg.BackgroundColor3 = Theme.ToggleOff
			SwitchBg.Position = UDim2.new(1, -60, 0.5, -12) -- À droite
			SwitchBg.Size = UDim2.new(0, 50, 0, 24) -- Petit rectangle arrondi
			
			local SwitchCorner = Instance.new("UICorner")
			SwitchCorner.CornerRadius = UDim.new(1, 0) -- Pill shape
			SwitchCorner.Parent = SwitchBg

			local Knob = Instance.new("Frame")
			Knob.Parent = SwitchBg
			Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Knob.Position = UDim2.new(0, 2, 0.5, -10)
			Knob.Size = UDim2.new(0, 20, 0, 20) -- Cercle
			
			local KnobCorner = Instance.new("UICorner")
			KnobCorner.CornerRadius = UDim.new(1, 0)
			KnobCorner.Parent = Knob

			local Btn = Instance.new("TextButton")
			Btn.Parent = SwitchBg
			Btn.BackgroundTransparency = 1
			Btn.Size = UDim2.new(1, 0, 1, 0)
			Btn.Text = ""

			local Toggled = Default

			local function UpdateState()
				if Toggled then
					TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOn}):Play()
					TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -22, 0.5, -10)}):Play()
				else
					TweenService:Create(SwitchBg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOff}):Play()
					TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -10)}):Play()
				end
				Callback(Toggled)
			end
			
			if Default then UpdateState() end

			Btn.MouseButton1Click:Connect(function()
				Toggled = not Toggled
				UpdateState()
			end)
		end

		-- :: 3. SLIDER (Style Bleu, boule ronde) :: --
		function TabFunctions:CreateSlider(Config)
			local Name = Config.Name or "Slider"
			local Min = Config.Range[1] or 0
			local Max = Config.Range[2] or 100
			local Default = Config.CurrentValue or Min
			local Callback = Config.Callback or function() end

			local SliderFrame = Instance.new("Frame")
			SliderFrame.Parent = Page
			SliderFrame.BackgroundTransparency = 1
			SliderFrame.Size = UDim2.new(1, -10, 0, 50) -- Un peu plus haut pour le texte

			-- Titre au dessus (comme sur l'image)
			local Label = Instance.new("TextLabel")
			Label.Parent = SliderFrame
			Label.BackgroundTransparency = 1
			Label.Position = UDim2.new(0, 10, 0, 0)
			Label.Size = UDim2.new(1, 0, 0, 20)
			Label.Font = Enum.Font.SourceSans
			Label.Text = Name
			Label.TextColor3 = Theme.Text
			Label.TextSize = 16
			Label.TextXAlignment = Enum.TextXAlignment.Left

			-- Valeur à droite (0%)
			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Parent = SliderFrame
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Position = UDim2.new(1, -60, 0, 0)
			ValueLabel.Size = UDim2.new(0, 50, 0, 20)
			ValueLabel.Font = Enum.Font.SourceSansBold
			ValueLabel.Text = tostring(Default) .. "%"
			ValueLabel.TextColor3 = Theme.Text
			ValueLabel.TextSize = 16
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

			-- Barre de fond (Noire)
			local Bar = Instance.new("Frame")
			Bar.Parent = SliderFrame
			Bar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			Bar.Position = UDim2.new(0, 10, 0, 25)
			Bar.Size = UDim2.new(1, -20, 0, 10)
			
			local BarCorner = Instance.new("UICorner")
			BarCorner.CornerRadius = UDim.new(1, 0)
			BarCorner.Parent = Bar

			-- Cercle Bleu (Knob)
			local Knob = Instance.new("TextButton")
			Knob.Parent = Bar
			Knob.BackgroundColor3 = Theme.Accent
			Knob.Size = UDim2.new(0, 20, 0, 20)
			Knob.AnchorPoint = Vector2.new(0.5, 0.5)
			Knob.Position = UDim2.new(0, 0, 0.5, 0)
			Knob.Text = ""
			
			local KnobCorner = Instance.new("UICorner")
			KnobCorner.CornerRadius = UDim.new(1, 0) -- Rond parfait
			KnobCorner.Parent = Knob

			local Dragging = false

			local function Update(Input)
				local SizeX = Bar.AbsoluteSize.X
				local PosX = Input.Position.X - Bar.AbsolutePosition.X
				local Percent = math.clamp(PosX / SizeX, 0, 1)
				
				Knob.Position = UDim2.new(Percent, 0, 0.5, 0)
				
				local Value = math.floor(Min + (Max - Min) * Percent)
				ValueLabel.Text = tostring(Value) .. "%"
				Callback(Value)
			end

			Knob.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
				end
			end)

			UserInputService.InputEnded:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = false
				end
			end)

			UserInputService.InputChanged:Connect(function(Input)
				if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
					Update(Input)
				end
			end)
		end

		return TabFunctions
	end

	return WindowFunctions
end

return SoroniceLib
