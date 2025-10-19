
-- LocalScript

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar RemoteEvents
local RemotesFolder = ReplicatedStorage:WaitForChild("MusicRemotes")
local RequestMusicList = RemotesFolder:WaitForChild("RequestMusicList")
local AddMusicEvent = RemotesFolder:WaitForChild("AddMusicEvent")
local DeleteMusicEvent = RemotesFolder:WaitForChild("DeleteMusicEvent")
local CheckAdminEvent = RemotesFolder:WaitForChild("CheckAdminEvent")
local MusicUpdateEvent = RemotesFolder:WaitForChild("MusicUpdateEvent")
local SendVerifyRequest = RemotesFolder:WaitForChild("SendVerifyRequest")
local RequestVerifyList = RemotesFolder:WaitForChild("RequestVerifyList")
local VerifyUpdateEvent = RemotesFolder:WaitForChild("VerifyUpdateEvent")

-- Variables globales
local isAdmin = false
local currentSound = nil
local musicLibrary = {}
local verificationRequests = {}
local currentPlayingId = nil
local currentMusicData = nil
local isFullscreen = false
local currentMusicIndex = nil
local adPanel = nil
local adTimer = 0
local AD_INTERVAL = 10 -- segundos entre anuncios

-----

-- CREACIÓN DE INTERFAZ DE USUARIO (GUI)

-- Crear GUI principal
local function CreateMainGUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AmazonMusicGUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = playerGui

	-- Fondo principal (estilo Amazon Music: degradado oscuro)
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.Position = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(11, 14, 17)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	-- Gradiente de fondo
	local Gradient = Instance.new("UIGradient")
	Gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 14, 17)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 28, 34))
	}
	Gradient.Rotation = 45
	Gradient.Parent = MainFrame

	-- Barra superior (estilo Amazon Music)
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 70)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(17, 21, 26)
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MainFrame

	-- Logo Amazon Music
	local Logo = Instance.new("TextLabel")
	Logo.Name = "Logo"
	Logo.Size = UDim2.new(0, 300, 1, 0)
	Logo.Position = UDim2.new(0, 20, 0, 0)
	Logo.BackgroundTransparency = 1
	Logo.Text = "🎵 Amazon Music"
	Logo.TextColor3 = Color3.fromRGB(28, 184, 231) -- Color azul Amazon
	Logo.Font = Enum.Font.GothamBold
	Logo.TextSize = 28
	Logo.TextXAlignment = Enum.TextXAlignment.Left
	Logo.Parent = TopBar

	-- Botón cerrar
	local CloseButton = Instance.new("TextButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Size = UDim2.new(0, 50, 0, 50)
	CloseButton.Position = UDim2.new(1, -60, 0.5, -25)
	CloseButton.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	CloseButton.Text = "✕"
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 20
	CloseButton.BorderSizePixel = 0
	CloseButton.Parent = TopBar

	local CloseCorner = Instance.new("UICorner")
	CloseCorner.CornerRadius = UDim.new(0, 10)
	CloseCorner.Parent = CloseButton

	CloseButton.MouseButton1Click:Connect(function()
		MainFrame.Visible = false
		if currentSound then
			currentSound:Pause()
		end
	end)

	-- Área de contenido
	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, 0, 1, -190)
	ContentArea.Position = UDim2.new(0, 0, 0, 70)
	ContentArea.BackgroundTransparency = 1
	ContentArea.BorderSizePixel = 0
	ContentArea.Parent = MainFrame

	-- Panel de Biblioteca
	local LibraryPanel = Instance.new("ScrollingFrame")
	LibraryPanel.Name = "LibraryPanel"
	LibraryPanel.Size = UDim2.new(1, -40, 1, 0)
	LibraryPanel.Position = UDim2.new(0, 20, 0, 0)
	LibraryPanel.BackgroundTransparency = 1
	LibraryPanel.BorderSizePixel = 0
	LibraryPanel.ScrollBarThickness = 8
	LibraryPanel.ScrollBarImageColor3 = Color3.fromRGB(28, 184, 231)
	LibraryPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
	LibraryPanel.Parent = ContentArea
	LibraryPanel.Visible = true

	local LibraryLayout = Instance.new("UIListLayout")
	LibraryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	LibraryLayout.Padding = UDim.new(0, 12)
	LibraryLayout.Parent = LibraryPanel

	LibraryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		LibraryPanel.CanvasSize = UDim2.new(0, 0, 0, LibraryLayout.AbsoluteContentSize.Y + 20)
	end)

	-- Panel de Búsqueda
	local SearchPanel = Instance.new("Frame")
	SearchPanel.Name = "SearchPanel"
	SearchPanel.Size = UDim2.new(1, -40, 1, 0)
	SearchPanel.Position = UDim2.new(0, 20, 0, 0)
	SearchPanel.BackgroundTransparency = 1
	SearchPanel.Visible = false
	SearchPanel.Parent = ContentArea

	local SearchInput = Instance.new("TextBox")
	SearchInput.Name = "SearchInput"
	SearchInput.Size = UDim2.new(1, 0, 0, 50)
	SearchInput.Position = UDim2.new(0, 0, 0, 0)
	SearchInput.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	SearchInput.PlaceholderText = "🔍 Buscar canciones, artistas..."
	SearchInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	SearchInput.Font = Enum.Font.Gotham
	SearchInput.TextSize = 18
	SearchInput.TextXAlignment = Enum.TextXAlignment.Left
	SearchInput.Parent = SearchPanel

	local SearchPadding = Instance.new("UIPadding")
	SearchPadding.PaddingLeft = UDim.new(0, 15)
	SearchPadding.Parent = SearchInput

	local SearchCorner = Instance.new("UICorner")
	SearchCorner.CornerRadius = UDim.new(0, 25)
	SearchCorner.Parent = SearchInput

	local SearchResults = Instance.new("ScrollingFrame")
	SearchResults.Name = "SearchResults"
	SearchResults.Size = UDim2.new(1, 0, 1, -65)
	SearchResults.Position = UDim2.new(0, 0, 0, 65)
	SearchResults.BackgroundTransparency = 1
	SearchResults.ScrollBarThickness = 8
	SearchResults.ScrollBarImageColor3 = Color3.fromRGB(28, 184, 231)
	SearchResults.CanvasSize = UDim2.new(0, 0, 0, 0)
	SearchResults.Parent = SearchPanel

	local SearchLayout = Instance.new("UIListLayout")
	SearchLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SearchLayout.Padding = UDim.new(0, 12)
	SearchLayout.Parent = SearchResults

	SearchLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SearchResults.CanvasSize = UDim2.new(0, 0, 0, SearchLayout.AbsoluteContentSize.Y + 20)
	end)

	-- Panel de Verificación
	local VerifyPanel = Instance.new("Frame")
	VerifyPanel.Name = "VerifyPanel"
	VerifyPanel.Size = UDim2.new(1, -40, 1, 0)
	VerifyPanel.Position = UDim2.new(0, 20, 0, 0)
	VerifyPanel.BackgroundTransparency = 1
	VerifyPanel.Visible = false
	VerifyPanel.Parent = ContentArea

	local Instructions = Instance.new("TextLabel")
	Instructions.Size = UDim2.new(1, 0, 0, 120)
	Instructions.Position = UDim2.new(0, 0, 0, 20)
	Instructions.BackgroundTransparency = 1
	Instructions.Text = "✅ Verificación de Artista\n\nSi eres un artista y quieres verificar tu cuenta,\nenvía un mensaje a los administradores."
	Instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instructions.Font = Enum.Font.Gotham
	Instructions.TextSize = 16
	Instructions.TextWrapped = true
	Instructions.Parent = VerifyPanel

	local MessageBox = Instance.new("TextBox")
	MessageBox.Size = UDim2.new(1, 0, 0, 180)
	MessageBox.Position = UDim2.new(0, 0, 0, 150)
	MessageBox.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	MessageBox.PlaceholderText = "Escribe tu mensaje aquí..."
	MessageBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	MessageBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	MessageBox.Font = Enum.Font.Gotham
	MessageBox.TextSize = 16
	MessageBox.MultiLine = true
	MessageBox.TextWrapped = true
	MessageBox.TextXAlignment = Enum.TextXAlignment.Left
	MessageBox.TextYAlignment = Enum.TextYAlignment.Top
	MessageBox.Parent = VerifyPanel

	local MessagePadding = Instance.new("UIPadding")
	MessagePadding.PaddingLeft = UDim.new(0, 15)
	MessagePadding.PaddingRight = UDim.new(0, 15)
	MessagePadding.PaddingTop = UDim.new(0, 15)
	MessagePadding.Parent = MessageBox

	local MessageCorner = Instance.new("UICorner")
	MessageCorner.CornerRadius = UDim.new(0, 12)
	MessageCorner.Parent = MessageBox

	local SendButton = Instance.new("TextButton")
	SendButton.Size = UDim2.new(1, 0, 0, 55)
	SendButton.Position = UDim2.new(0, 0, 0, 350)
	SendButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	SendButton.Text = "Enviar Solicitud"
	SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SendButton.Font = Enum.Font.GothamBold
	SendButton.TextSize = 18
	SendButton.Parent = VerifyPanel

	local SendCorner = Instance.new("UICorner")
	SendCorner.CornerRadius = UDim.new(0, 12)
	SendCorner.Parent = SendButton

	-- Panel de Admin
	local AdminPanel = Instance.new("Frame")
	AdminPanel.Name = "AdminPanel"
	AdminPanel.Size = UDim2.new(1, -40, 1, 0)
	AdminPanel.Position = UDim2.new(0, 20, 0, 0)
	AdminPanel.BackgroundTransparency = 1
	AdminPanel.Visible = false
	AdminPanel.Parent = ContentArea

	local AdminTitle = Instance.new("TextLabel")
	AdminTitle.Size = UDim2.new(1, 0, 0, 50)
	AdminTitle.Position = UDim2.new(0, 0, 0, 0)
	AdminTitle.BackgroundTransparency = 1
	AdminTitle.Text = "⚙️ Panel de Administración"
	AdminTitle.TextColor3 = Color3.fromRGB(28, 184, 231)
	AdminTitle.Font = Enum.Font.GothamBold
	AdminTitle.TextSize = 26
	AdminTitle.TextXAlignment = Enum.TextXAlignment.Left
	AdminTitle.Parent = AdminPanel

	-- Formulario agregar música
	local FormFrame = Instance.new("Frame")
	FormFrame.Size = UDim2.new(1, 0, 0, 380)
	FormFrame.Position = UDim2.new(0, 0, 0, 60)
	FormFrame.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	FormFrame.BorderSizePixel = 0
	FormFrame.Parent = AdminPanel

	local FormCorner = Instance.new("UICorner")
	FormCorner.CornerRadius = UDim.new(0, 15)
	FormCorner.Parent = FormFrame

	local FormPadding = Instance.new("UIPadding")
	FormPadding.PaddingLeft = UDim.new(0, 20)
	FormPadding.PaddingRight = UDim.new(0, 20)
	FormPadding.PaddingTop = UDim.new(0, 20)
	FormPadding.PaddingBottom = UDim.new(0, 20)
	FormPadding.Parent = FormFrame

	-- Helper function para crear inputs
	local function CreateInput(name, placeholder, position)
		local InputFrame = Instance.new("Frame")
		InputFrame.Size = UDim2.new(0.48, 0, 0, 45)
		InputFrame.Position = position
		InputFrame.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
		InputFrame.BorderSizePixel = 0
		InputFrame.Parent = FormFrame
		
		local InputCorner = Instance.new("UICorner")
		InputCorner.CornerRadius = UDim.new(0, 8)
		InputCorner.Parent = InputFrame
		
		local TextBox = Instance.new("TextBox")
		TextBox.Name = name
		TextBox.Size = UDim2.new(1, -20, 1, 0)
		TextBox.Position = UDim2.new(0, 10, 0, 0)
		TextBox.BackgroundTransparency = 1
		TextBox.PlaceholderText = placeholder
		TextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
		TextBox.Text = ""
		TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.Font = Enum.Font.Gotham
		TextBox.TextSize = 15
		TextBox.TextXAlignment = Enum.TextXAlignment.Left
		TextBox.ClearTextOnFocus = false
		TextBox.Parent = InputFrame
		
		return TextBox
	end

	local TitleInput = CreateInput("TitleInput", "Título de la canción", UDim2.new(0, 0, 0, 0))
	local ArtistInput = CreateInput("ArtistInput", "Artista", UDim2.new(0.52, 0, 0, 0))
	local SoundIdInput = CreateInput("SoundIdInput", "ID de Sonido", UDim2.new(0, 0, 0, 60))
	local DurationInput = CreateInput("DurationInput", "Duración (ej: 3:45)", UDim2.new(0.52, 0, 0, 60))
	local AlbumInput = CreateInput("AlbumInput", "Álbum", UDim2.new(0, 0, 0, 120))
	local GenreInput = CreateInput("GenreInput", "Género", UDim2.new(0.52, 0, 0, 120))

	-- Botón agregar
	local AddButton = Instance.new("TextButton")
	AddButton.Size = UDim2.new(1, 0, 0, 55)
	AddButton.Position = UDim2.new(0, 0, 0, 185)
	AddButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	AddButton.Text = "➕ Agregar Música"
	AddButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AddButton.Font = Enum.Font.GothamBold
	AddButton.TextSize = 18
	AddButton.BorderSizePixel = 0
	AddButton.Parent = FormFrame

	local AddCorner = Instance.new("UICorner")
	AddCorner.CornerRadius = UDim.new(0, 12)
	AddCorner.Parent = AddButton

	-- Sección de solicitudes
	local RequestsTitle = Instance.new("TextLabel")
	RequestsTitle.Size = UDim2.new(1, 0, 0, 50)
	RequestsTitle.Position = UDim2.new(0, 0, 0, 460)
	RequestsTitle.BackgroundTransparency = 1
	RequestsTitle.Text = "📋 Solicitudes de Verificación"
	RequestsTitle.TextColor3 = Color3.fromRGB(28, 184, 231)
	RequestsTitle.Font = Enum.Font.GothamBold
	RequestsTitle.TextSize = 24
	RequestsTitle.TextXAlignment = Enum.TextXAlignment.Left
	RequestsTitle.Parent = AdminPanel

	local RequestsList = Instance.new("ScrollingFrame")
	RequestsList.Name = "RequestsList"
	RequestsList.Size = UDim2.new(1, 0, 1, -520)
	RequestsList.Position = UDim2.new(0, 0, 0, 520)
	RequestsList.BackgroundTransparency = 1
	RequestsList.ScrollBarThickness = 8
	RequestsList.ScrollBarImageColor3 = Color3.fromRGB(28, 184, 231)
	RequestsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	RequestsList.Parent = AdminPanel

	local RequestsLayout = Instance.new("UIListLayout")
	RequestsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	RequestsLayout.Padding = UDim.new(0, 12)
	RequestsLayout.Parent = RequestsList

	RequestsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		RequestsList.CanvasSize = UDim2.new(0, 0, 0, RequestsLayout.AbsoluteContentSize.Y + 20)
	end)

	-- PANEL DE ANUNCIOS
	local AdPanel = Instance.new("Frame")
	AdPanel.Name = "AdPanel"
	AdPanel.Size = UDim2.new(1, 0, 1, 0)
	AdPanel.Position = UDim2.new(0, 0, 0, 0)
	AdPanel.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
	AdPanel.Visible = false
	AdPanel.ZIndex = 20
	AdPanel.Parent = MainFrame

	local AdGradient = Instance.new("UIGradient")
	AdGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(189, 68, 68)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 126, 34)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(241, 196, 15))
	}
	AdGradient.Rotation = 45
	AdGradient.Parent = AdPanel

	local AdContainer = Instance.new("Frame")
	AdContainer.Size = UDim2.new(0, 600, 0, 400)
	AdContainer.Position = UDim2.new(0.5, -300, 0.5, -200)
	AdContainer.BackgroundColor3 = Color3.fromRGB(25, 29, 35)
	AdContainer.ZIndex = 21
	AdContainer.Parent = AdPanel

	local AdContainerCorner = Instance.new("UICorner")
	AdContainerCorner.CornerRadius = UDim.new(0, 20)
	AdContainerCorner.Parent = AdContainer

	local AdIcon = Instance.new("TextLabel")
	AdIcon.Size = UDim2.new(1, 0, 0, 120)
	AdIcon.Position = UDim2.new(0, 0, 0, 40)
	AdIcon.BackgroundTransparency = 1
	AdIcon.Text = "🎮"
	AdIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	AdIcon.Font = Enum.Font.GothamBold
	AdIcon.TextSize = 80
	AdIcon.ZIndex = 22
	AdIcon.Parent = AdContainer

	local AdTitle = Instance.new("TextLabel")
	AdTitle.Size = UDim2.new(1, -60, 0, 50)
	AdTitle.Position = UDim2.new(0, 30, 0, 170)
	AdTitle.BackgroundTransparency = 1
	AdTitle.Text = "¡Únete a Roblox!"
	AdTitle.TextColor3 = Color3.fromRGB(28, 184, 231)
	AdTitle.Font = Enum.Font.GothamBold
	AdTitle.TextSize = 38
	AdTitle.ZIndex = 22
	AdTitle.Parent = AdContainer

	local AdDescription = Instance.new("TextLabel")
	AdDescription.Size = UDim2.new(1, -60, 0, 80)
	AdDescription.Position = UDim2.new(0, 30, 0, 230)
	AdDescription.BackgroundTransparency = 1
	AdDescription.Text = "Crea, juega y comparte experiencias increíbles\ncon millones de jugadores en todo el mundo"
	AdDescription.TextColor3 = Color3.fromRGB(200, 200, 200)
	AdDescription.Font = Enum.Font.Gotham
	AdDescription.TextSize = 18
	AdDescription.TextWrapped = true
	AdDescription.ZIndex = 22
	AdDescription.Parent = AdContainer

	local AdLabel = Instance.new("TextLabel")
	AdLabel.Size = UDim2.new(0, 200, 0, 35)
	AdLabel.Position = UDim2.new(0.5, -100, 1, -50)
	AdLabel.BackgroundColor3 = Color3.fromRGB(189, 68, 68)
	AdLabel.Text = "ANUNCIO"
	AdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	AdLabel.Font = Enum.Font.GothamBold
	AdLabel.TextSize = 16
	AdLabel.ZIndex = 22
	AdLabel.Parent = AdContainer

	local AdLabelCorner = Instance.new("UICorner")
	AdLabelCorner.CornerRadius = UDim.new(0, 8)
	AdLabelCorner.Parent = AdLabel

	-- REPRODUCTOR EN PANTALLA COMPLETA
	local FullscreenPlayer = Instance.new("Frame")
	FullscreenPlayer.Name = "FullscreenPlayer"
	FullscreenPlayer.Size = UDim2.new(1, 0, 1, 0)
	FullscreenPlayer.Position = UDim2.new(0, 0, 0, 0)
	FullscreenPlayer.BackgroundColor3 = Color3.fromRGB(11, 14, 17)
	FullscreenPlayer.Visible = false
	FullscreenPlayer.ZIndex = 10
	FullscreenPlayer.Parent = MainFrame

	local FSGradient = Instance.new("UIGradient")
	FSGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 28, 34)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(28, 184, 231)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 14, 17))
	}
	FSGradient.Rotation = 135
	FSGradient.Parent = FullscreenPlayer

	-- Botón minimizar
	local MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Size = UDim2.new(0, 60, 0, 60)
	MinimizeButton.Position = UDim2.new(0, 20, 0, 20)
	MinimizeButton.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	MinimizeButton.Text = "⌄"
	MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	MinimizeButton.Font = Enum.Font.GothamBold
	MinimizeButton.TextSize = 30
	MinimizeButton.ZIndex = 11
	MinimizeButton.Parent = FullscreenPlayer

	local MinCorner = Instance.new("UICorner")
	MinCorner.CornerRadius = UDim.new(1, 0)
	MinCorner.Parent = MinimizeButton

	-- Portada grande (simulada con emoji)
	local AlbumCover = Instance.new("TextLabel")
	AlbumCover.Size = UDim2.new(0, 350, 0, 350)
	AlbumCover.Position = UDim2.new(0.5, -175, 0.3, -175)
	AlbumCover.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	AlbumCover.Text = "🎵"
	AlbumCover.TextColor3 = Color3.fromRGB(28, 184, 231)
	AlbumCover.Font = Enum.Font.GothamBold
	AlbumCover.TextSize = 120
	AlbumCover.ZIndex = 11
	AlbumCover.Parent = FullscreenPlayer

	local CoverCorner = Instance.new("UICorner")
	CoverCorner.CornerRadius = UDim.new(0, 20)
	CoverCorner.Parent = AlbumCover

	-- Información de la canción en fullscreen
	local FSSongTitle = Instance.new("TextLabel")
	FSSongTitle.Size = UDim2.new(1, -100, 0, 50)
	FSSongTitle.Position = UDim2.new(0, 50, 0.65, 0)
	FSSongTitle.BackgroundTransparency = 1
	FSSongTitle.Text = "Nombre de la Canción"
	FSSongTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	FSSongTitle.Font = Enum.Font.GothamBold
	FSSongTitle.TextSize = 32
	FSSongTitle.ZIndex = 11
	FSSongTitle.Parent = FullscreenPlayer

	local FSArtistName = Instance.new("TextLabel")
	FSArtistName.Size = UDim2.new(1, -100, 0, 35)
	FSArtistName.Position = UDim2.new(0, 50, 0.7, 0)
	FSArtistName.BackgroundTransparency = 1
	FSArtistName.Text = "Artista"
	FSArtistName.TextColor3 = Color3.fromRGB(180, 180, 180)
	FSArtistName.Font = Enum.Font.Gotham
	FSArtistName.TextSize = 22
	FSArtistName.ZIndex = 11
	FSArtistName.Parent = FullscreenPlayer

	-- Controles grandes centrados
	local ControlsFrame = Instance.new("Frame")
	ControlsFrame.Size = UDim2.new(0, 400, 0, 100)
	ControlsFrame.Position = UDim2.new(0.5, -200, 0.85, -50)
	ControlsFrame.BackgroundTransparency = 1
	ControlsFrame.ZIndex = 11
	ControlsFrame.Parent = FullscreenPlayer

	-- Botón anterior
	local FSPrevButton = Instance.new("TextButton")
	FSPrevButton.Name = "FSPrevButton"
	FSPrevButton.Size = UDim2.new(0, 65, 0, 65)
	FSPrevButton.Position = UDim2.new(0.5, -165, 0.5, -32.5)
	FSPrevButton.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	FSPrevButton.Text = "⏮"
	FSPrevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FSPrevButton.Font = Enum.Font.GothamBold
	FSPrevButton.TextSize = 28
	FSPrevButton.ZIndex = 11
	FSPrevButton.Parent = ControlsFrame

	local FSPrevCorner = Instance.new("UICorner")
	FSPrevCorner.CornerRadius = UDim.new(1, 0)
	FSPrevCorner.Parent = FSPrevButton

	-- Botón play/pause (centrado)
	local FSPlayPauseButton = Instance.new("TextButton")
	FSPlayPauseButton.Name = "FSPlayPauseButton"
	FSPlayPauseButton.Size = UDim2.new(0, 80, 0, 80)
	FSPlayPauseButton.Position = UDim2.new(0.5, -40, 0.5, -40)
	FSPlayPauseButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	FSPlayPauseButton.Text = "▶"
	FSPlayPauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FSPlayPauseButton.Font = Enum.Font.GothamBold
	FSPlayPauseButton.TextSize = 35
	FSPlayPauseButton.ZIndex = 11
	FSPlayPauseButton.Parent = ControlsFrame

	local FSPlayCorner = Instance.new("UICorner")
	FSPlayCorner.CornerRadius = UDim.new(1, 0)
	FSPlayCorner.Parent = FSPlayPauseButton

	-- Botón siguiente
	local FSNextButton = Instance.new("TextButton")
	FSNextButton.Name = "FSNextButton"
	FSNextButton.Size = UDim2.new(0, 65, 0, 65)
	FSNextButton.Position = UDim2.new(0.5, 100, 0.5, -32.5)
	FSNextButton.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	FSNextButton.Text = "⏭"
	FSNextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FSNextButton.Font = Enum.Font.GothamBold
	FSNextButton.TextSize = 28
	FSNextButton.ZIndex = 11
	FSNextButton.Parent = ControlsFrame

	local FSNextCorner = Instance.new("UICorner")
	FSNextCorner.CornerRadius = UDim.new(1, 0)
	FSNextCorner.Parent = FSNextButton

	-- Barra de navegación inferior
	local NavBar = Instance.new("Frame")
	NavBar.Name = "NavBar"
	NavBar.Size = UDim2.new(1, 0, 0, 70)
	NavBar.Position = UDim2.new(0, 0, 1, -70)
	NavBar.BackgroundColor3 = Color3.fromRGB(17, 21, 26)
	NavBar.BorderSizePixel = 0
	NavBar.Parent = MainFrame

	local numTabs = isAdmin and 4 or 3
	local tabWidth = 1 / numTabs

	local function CreateNavButton(text, position)
		local Button = Instance.new("TextButton")
		Button.Size = UDim2.new(tabWidth, -10, 0, 60)
		Button.Position = position
		Button.BackgroundTransparency = 1
		Button.Text = text
		Button.TextColor3 = Color3.fromRGB(180, 180, 180)
		Button.Font = Enum.Font.GothamBold
		Button.TextSize = 14
		Button.Parent = NavBar
		return Button
	end

	local LibraryButton = CreateNavButton("🎵", UDim2.new(0, 5, 0, 5))
	local SearchButton = CreateNavButton("🔍", UDim2.new(tabWidth, 0, 0, 5))
	local VerifyButton = CreateNavButton("✅", UDim2.new(tabWidth * 2, 0, 0, 5))
	
	local AdminButton
	if isAdmin then
		AdminButton = CreateNavButton("⚙️", UDim2.new(tabWidth * 3, 0, 0, 5))
	end

	-- Player de música (barra inferior compacta)
	local PlayerBar = Instance.new("Frame")
	PlayerBar.Name = "PlayerBar"
	PlayerBar.Size = UDim2.new(1, 0, 0, 80)
	PlayerBar.Position = UDim2.new(0, 0, 1, -150)
	PlayerBar.BackgroundColor3 = Color3.fromRGB(25, 29, 35)
	PlayerBar.BorderSizePixel = 0
	PlayerBar.Visible = false
	PlayerBar.Parent = MainFrame

	local PlayerGradient = Instance.new("UIGradient")
	PlayerGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 29, 35)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 39, 47))
	}
	PlayerGradient.Rotation = 90
	PlayerGradient.Parent = PlayerBar

	-- Información de canción
	local SongInfo = Instance.new("TextLabel")
	SongInfo.Name = "SongInfo"
	SongInfo.Size = UDim2.new(0.6, -100, 0, 30)
	SongInfo.Position = UDim2.new(0, 15, 0, 10)
	SongInfo.BackgroundTransparency = 1
	SongInfo.Text = "Sin reproducción"
	SongInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
	SongInfo.Font = Enum.Font.GothamBold
	SongInfo.TextSize = 16
	SongInfo.TextXAlignment = Enum.TextXAlignment.Left
	SongInfo.TextTruncate = Enum.TextTruncate.AtEnd
	SongInfo.Parent = PlayerBar

	local ArtistInfo = Instance.new("TextLabel")
	ArtistInfo.Name = "ArtistInfo"
	ArtistInfo.Size = UDim2.new(0.6, -100, 0, 25)
	ArtistInfo.Position = UDim2.new(0, 15, 0, 40)
	ArtistInfo.BackgroundTransparency = 1
	ArtistInfo.Text = ""
	ArtistInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
	ArtistInfo.Font = Enum.Font.Gotham
	ArtistInfo.TextSize = 14
	ArtistInfo.TextXAlignment = Enum.TextXAlignment.Left
	ArtistInfo.TextTruncate = Enum.TextTruncate.AtEnd
	ArtistInfo.Parent = PlayerBar

	-- Controles
	local PlayPauseButton = Instance.new("TextButton")
	PlayPauseButton.Name = "PlayPauseButton"
	PlayPauseButton.Size = UDim2.new(0, 50, 0, 50)
	PlayPauseButton.Position = UDim2.new(1, -120, 0.5, -25)
	PlayPauseButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	PlayPauseButton.Text = "▶"
	PlayPauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayPauseButton.Font = Enum.Font.GothamBold
	PlayPauseButton.TextSize = 20
	PlayPauseButton.Parent = PlayerBar

	local PlayCorner = Instance.new("UICorner")
	PlayCorner.CornerRadius = UDim.new(1, 0)
	PlayCorner.Parent = PlayPauseButton

	local StopButton = Instance.new("TextButton")
	StopButton.Name = "StopButton"
	StopButton.Size = UDim2.new(0, 50, 0, 50)
	StopButton.Position = UDim2.new(1, -60, 0.5, -25)
	StopButton.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	StopButton.Text = "■"
	StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	StopButton.Font = Enum.Font.GothamBold
	StopButton.TextSize = 20
	StopButton.Parent = PlayerBar

	local StopCorner = Instance.new("UICorner")
	StopCorner.CornerRadius = UDim.new(1, 0)
	StopCorner.Parent = StopButton

	-- Botón expandir
	local ExpandButton = Instance.new("TextButton")
	ExpandButton.Name = "ExpandButton"
	ExpandButton.Size = UDim2.new(0, 30, 0, 30)
	ExpandButton.Position = UDim2.new(0, 10, 0, 10)
	ExpandButton.BackgroundTransparency = 1
	ExpandButton.Text = "⬆"
	ExpandButton.TextColor3 = Color3.fromRGB(28, 184, 231)
	ExpandButton.Font = Enum.Font.GothamBold
	ExpandButton.TextSize = 18
	ExpandButton.Parent = PlayerBar

	-- CONEXIONES DE UI

	-- Función para expandir/contraer reproductor
	local function ToggleFullscreen()
		isFullscreen = not isFullscreen
		FullscreenPlayer.Visible = isFullscreen
		
		if isFullscreen and currentMusicData then
			FSSongTitle.Text = currentMusicData.Title
			FSArtistName.Text = currentMusicData.Artist .. " • " .. (currentMusicData.Album or "")
			
			if currentSound and currentSound.Playing then
				FSPlayPauseButton.Text = "❚❚"
			else
				FSPlayPauseButton.Text = "▶"
			end
		end
	end

	ExpandButton.MouseButton1Click:Connect(ToggleFullscreen)
	MinimizeButton.MouseButton1Click:Connect(ToggleFullscreen)

	-- Navegación
	local function SetActiveTab(button)
		LibraryButton.TextColor3 = Color3.fromRGB(180, 180, 180)
		SearchButton.TextColor3 = Color3.fromRGB(180, 180, 180)
		VerifyButton.TextColor3 = Color3.fromRGB(180, 180, 180)
		if isAdmin then
			AdminButton.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
		button.TextColor3 = Color3.fromRGB(28, 184, 231)
	end

	LibraryButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = true
		SearchPanel.Visible = false
		VerifyPanel.Visible = false
		AdminPanel.Visible = false
		SetActiveTab(LibraryButton)
	end)

	SearchButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = false
		SearchPanel.Visible = true
		VerifyPanel.Visible = false
		AdminPanel.Visible = false
		SetActiveTab(SearchButton)
	end)

	VerifyButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = false
		SearchPanel.Visible = false
		VerifyPanel.Visible = true
		AdminPanel.Visible = false
		SetActiveTab(VerifyButton)
	end)

	if isAdmin then
		AdminButton.MouseButton1Click:Connect(function()
			LibraryPanel.Visible = false
			SearchPanel.Visible = false
			VerifyPanel.Visible = false
			AdminPanel.Visible = true
			SetActiveTab(AdminButton)
		end)
	end

	-- Búsqueda
	SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		UpdateSearchResults(SearchResults, SearchInput.Text)
	end)

	-- Enviar verificación
	SendButton.MouseButton1Click:Connect(function()
		local message = MessageBox.Text
		if message ~= "" then
			SendVerifyRequest:FireServer(message)
			MessageBox.Text = ""
			ShowNotification(ScreenGui, "Solicitud enviada", Color3.fromRGB(46, 125, 50))
		end
	end)

	-- Agregar música
	AddButton.MouseButton1Click:Connect(function()
		local title = TitleInput.Text
		local artist = ArtistInput.Text
		local soundId = SoundIdInput.Text
		
		if title ~= "" and artist ~= "" and soundId ~= "" then
			local musicData = {
				Title = title,
				Artist = artist,
				SoundId = soundId,
				Duration = DurationInput.Text ~= "" and DurationInput.Text or "3:30",
				Album = AlbumInput.Text ~= "" and AlbumInput.Text or "Single",
				Genre = GenreInput.Text ~= "" and GenreInput.Text or "Pop"
			}
			
			AddMusicEvent:FireServer(musicData)
			
			-- Limpiar campos
			TitleInput.Text = ""
			ArtistInput.Text = ""
			SoundIdInput.Text = ""
			DurationInput.Text = ""
			AlbumInput.Text = ""
			GenreInput.Text = ""
		end
	end)

	-- Controles de reproducción (barra compacta)
	PlayPauseButton.MouseButton1Click:Connect(function()
		if currentSound then
			if currentSound.Playing then
				currentSound:Pause()
				PlayPauseButton.Text = "▶"
				if isFullscreen then
					FSPlayPauseButton.Text = "▶"
				end
			else
				currentSound:Play()
				PlayPauseButton.Text = "❚❚"
				if isFullscreen then
					FSPlayPauseButton.Text = "❚❚"
				end
			end
		end
	end)

	-- Controles de reproducción (fullscreen)
	FSPlayPauseButton.MouseButton1Click:Connect(function()
		if currentSound then
			if currentSound.Playing then
				currentSound:Pause()
				FSPlayPauseButton.Text = "▶"
				PlayPauseButton.Text = "▶"
			else
				currentSound:Play()
				FSPlayPauseButton.Text = "❚❚"
				PlayPauseButton.Text = "❚❚"
			end
		end
	end)

	StopButton.MouseButton1Click:Connect(function()
		if currentSound then
			currentSound:Stop()
			currentSound:Destroy()
			currentSound = nil
			PlayerBar.Visible = false
			FullscreenPlayer.Visible = false
			isFullscreen = false
			currentPlayingId = nil
			currentMusicData = nil
			PlayPauseButton.Text = "▶"
			FSPlayPauseButton.Text = "▶"
		end
	end)

	SetActiveTab(LibraryButton)

	return ScreenGui, LibraryPanel, SearchPanel, VerifyPanel, AdminPanel, PlayerBar, SongInfo, ArtistInfo, PlayPauseButton, RequestsList, FullscreenPlayer, FSSongTitle, FSArtistName, FSPlayPauseButton, AdPanel, ControlsFrame:FindFirstChild("FSPrevButton"), ControlsFrame:FindFirstChild("FSNextButton")
end

-----

-- FUNCIONES DE NAVEGACIÓN DE MÚSICA

local function GetCurrentMusicIndex()
	if not currentPlayingId then return nil end
	for i, music in ipairs(musicLibrary) do
		if music.Id == currentPlayingId then
			return i
		end
	end
	return nil
end

local function PlayMusicAtIndex(index, playerBar, songInfo, artistInfo, playButton)
	if index < 1 or index > #musicLibrary then return end
	
	local musicData = musicLibrary[index]
	
	-- Detener sonido anterior
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
	end
	
	-- Crear nuevo sonido
	currentSound = Instance.new("Sound")
	currentSound.Name = "MusicSound"
	currentSound.SoundId = "rbxassetid://" .. tostring(musicData.SoundId)
	currentSound.Volume = 0.5
	currentSound.Looped = false
	currentSound.Parent = SoundService
	
	task.wait(0.1)
	
	local success, err = pcall(function()
		currentSound:Play()
	end)
	
	if success then
		currentPlayingId = musicData.Id
		currentMusicData = musicData
		currentMusicIndex = index
		playerBar.Visible = true
		songInfo.Text = musicData.Title
		artistInfo.Text = musicData.Artist .. " • " .. (musicData.Album or "")
		playButton.Text = "❚❚"
		
		-- Actualizar pantalla completa si está visible
		if isFullscreen then
			fsSongTitle.Text = musicData.Title
			fsArtistName.Text = musicData.Artist .. " • " .. (musicData.Album or "")
			fsPlayButton.Text = "❚❚"
		end
		
		-- Reiniciar timer de anuncios
		adTimer = 0
	else
		warn("Error al reproducir música:", err)
		if currentSound then
			currentSound:Destroy()
			currentSound = nil
		end
	end
end

local function PlayNextSong(playerBar, songInfo, artistInfo, playButton)
	local index = GetCurrentMusicIndex()
	if index then
		local nextIndex = index + 1
		if nextIndex > #musicLibrary then
			nextIndex = 1 -- Volver al inicio
		end
		PlayMusicAtIndex(nextIndex, playerBar, songInfo, artistInfo, playButton)
	end
end

local function PlayPreviousSong(playerBar, songInfo, artistInfo, playButton)
	local index = GetCurrentMusicIndex()
	if index then
		local prevIndex = index - 1
		if prevIndex < 1 then
			prevIndex = #musicLibrary -- Ir al final
		end
		PlayMusicAtIndex(prevIndex, playerBar, songInfo, artistInfo, playButton)
	end
end

-- SISTEMA DE ANUNCIOS

local function ShowAd(adPanelFrame, playerBar, songInfo, artistInfo, playButton)
	if not currentSound or not currentSound.Playing then return end
	
	-- Pausar música
	currentSound:Pause()
	playButton.Text = "▶"
	if isFullscreen then
		fsPlayButton.Text = "▶"
	end
	
	-- Mostrar anuncio
	adPanelFrame.Visible = true
	
	-- Esperar 7 segundos
	task.wait(7)
	
	-- Ocultar anuncio
	adPanelFrame.Visible = false
	
	-- Reanudar música automáticamente
	if currentSound then
		currentSound:Play()
		playButton.Text = "❚❚"
		if isFullscreen then
			fsPlayButton.Text = "❚❚"
		end
	end
	
	-- Reiniciar timer
	adTimer = 0
end

local function StartAdSystem(adPanelFrame, playerBar, songInfo, artistInfo, playButton)
	task.spawn(function()
		while true do
			task.wait(1)
			
			if currentSound and currentSound.Playing then
				adTimer = adTimer + 1
				
				if adTimer >= AD_INTERVAL then
					ShowAd(adPanelFrame, playerBar, songInfo, artistInfo, playButton)
				end
			end
		end
	end)
end

-----

-- GESTIÓN DE LA MÚSICA

-- Función para mostrar notificaciones
local function ShowNotification(gui, message, color)
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0, 350, 0, 60)
	notification.AnchorPoint = Vector2.new(0.5, 0)
	notification.Position = UDim2.new(0.5, 0, 0, -60)
	notification.BackgroundColor3 = color
	notification.Text = message
	notification.TextColor3 = Color3.fromRGB(255, 255, 255)
	notification.Font = Enum.Font.GothamBold
	notification.TextSize = 16
	notification.Parent = gui
	
	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 12)
	notifCorner.Parent = notification
	
	local tweenIn = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, 20)})
	tweenIn:Play()
	task.wait(2.5)
	local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, -60)})
	tweenOut:Play()
	tweenOut.Completed:Wait()
	notification:Destroy()
end

-- Crear tarjeta de música (estilo Amazon Music)
local function CreateMusicCard(musicData, parent, playerBar, songInfo, artistInfo, playButton, isAdmin)
	local Card = Instance.new("Frame")
	Card.Name = "MusicCard_" .. musicData.Id
	Card.Size = UDim2.new(1, 0, 0, 75)
	Card.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	Card.Parent = parent
	Card.LayoutOrder = musicData.Id

	local CardCorner = Instance.new("UICorner")
	CardCorner.CornerRadius = UDim.new(0, 12)
	CardCorner.Parent = Card

	-- Mini portada
	local MiniCover = Instance.new("TextLabel")
	MiniCover.Size = UDim2.new(0, 60, 0, 60)
	MiniCover.Position = UDim2.new(0, 8, 0.5, -30)
	MiniCover.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	MiniCover.Text = "🎵"
	MiniCover.TextColor3 = Color3.fromRGB(255, 255, 255)
	MiniCover.Font = Enum.Font.GothamBold
	MiniCover.TextSize = 25
	MiniCover.Parent = Card

	local MiniCorner = Instance.new("UICorner")
	MiniCorner.CornerRadius = UDim.new(0, 8)
	MiniCorner.Parent = MiniCover

	-- Título
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -250, 0, 25)
	Title.Position = UDim2.new(0, 80, 0, 12)
	Title.BackgroundTransparency = 1
	Title.Text = musicData.Title
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 17
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.Parent = Card

	-- Artista y duración
	local Artist = Instance.new("TextLabel")
	Artist.Size = UDim2.new(1, -250, 0, 22)
	Artist.Position = UDim2.new(0, 80, 0, 38)
	Artist.BackgroundTransparency = 1
	Artist.Text = musicData.Artist .. " • " .. musicData.Duration .. " • " .. (musicData.Genre or "")
	Artist.TextColor3 = Color3.fromRGB(150, 150, 150)
	Artist.Font = Enum.Font.Gotham
	Artist.TextSize = 13
	Artist.TextXAlignment = Enum.TextXAlignment.Left
	Artist.Parent = Card

	-- Botón play
	local PlayBtn = Instance.new("TextButton")
	PlayBtn.Size = UDim2.new(0, 55, 0, 55)
	PlayBtn.Position = UDim2.new(1, -145, 0.5, -27.5)
	PlayBtn.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	PlayBtn.Text = "▶"
	PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayBtn.Font = Enum.Font.GothamBold
	PlayBtn.TextSize = 20
	PlayBtn.Parent = Card

	local PlayBtnCorner = Instance.new("UICorner")
	PlayBtnCorner.CornerRadius = UDim.new(1, 0)
	PlayBtnCorner.Parent = PlayBtn

	PlayBtn.MouseButton1Click:Connect(function()
		-- Buscar índice de esta canción
		local index = nil
		for i, music in ipairs(musicLibrary) do
			if music.Id == musicData.Id then
				index = i
				break
			end
		end
		
		if index then
			PlayMusicAtIndex(index, playerBar, songInfo, artistInfo, playButton)
		end
	end)

	if isAdmin then
		local DeleteBtn = Instance.new("TextButton")
		DeleteBtn.Size = UDim2.new(0, 50, 0, 50)
		DeleteBtn.Position = UDim2.new(1, -75, 0.5, -25)
		DeleteBtn.BackgroundColor3 = Color3.fromRGB(211, 47, 47)
		DeleteBtn.Text = "🗑"
		DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		DeleteBtn.Font = Enum.Font.GothamBold
		DeleteBtn.TextSize = 18
		DeleteBtn.Parent = Card
		
		local DeleteCorner = Instance.new("UICorner")
		DeleteCorner.CornerRadius = UDim.new(1, 0)
		DeleteCorner.Parent = DeleteBtn
		
		DeleteBtn.MouseButton1Click:Connect(function()
			DeleteMusicEvent:FireServer(musicData.Id)
		end)
	end

	return Card
end

-- Actualizar biblioteca
local function UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
	for _, child in pairs(libraryPanel:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("MusicCard_") then
			child:Destroy()
		end
	end
	
	for _, music in ipairs(musicLibrary) do
		CreateMusicCard(music, libraryPanel, playerBar, songInfo, artistInfo, playButton, isAdmin)
	end
end

-- Actualizar resultados de búsqueda
local function UpdateSearchResults(searchResults, query)
	for _, child in pairs(searchResults:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("MusicCard_") then
			child:Destroy()
		end
	end
	
	query = string.lower(query)
	for _, music in ipairs(musicLibrary) do
		if string.find(string.lower(music.Title), query) or string.find(string.lower(music.Artist), query) or string.find(string.lower(music.Genre or ""), query) then
			CreateMusicCard(music, searchResults, playerBar, songInfo, artistInfo, playButton, isAdmin)
		end
	end
end

-- Crear tarjeta de solicitud
local function CreateRequestCard(req, parent)
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(1, 0, 0, 100)
	Card.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	Card.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = Card

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 15)
	Padding.PaddingRight = UDim.new(0, 15)
	Padding.PaddingTop = UDim.new(0, 10)
	Padding.PaddingBottom = UDim.new(0, 10)
	Padding.Parent = Card

	local UserLabel = Instance.new("TextLabel")
	UserLabel.Size = UDim2.new(1, 0, 0, 22)
	UserLabel.Position = UDim2.new(0, 0, 0, 0)
	UserLabel.BackgroundTransparency = 1
	UserLabel.Text = "👤 " .. req.User
	UserLabel.TextColor3 = Color3.fromRGB(28, 184, 231)
	UserLabel.Font = Enum.Font.GothamBold
	UserLabel.TextSize = 16
	UserLabel.TextXAlignment = Enum.TextXAlignment.Left
	UserLabel.Parent = Card

	local MessageLabel = Instance.new("TextLabel")
	MessageLabel.Size = UDim2.new(1, 0, 0, 45)
	MessageLabel.Position = UDim2.new(0, 0, 0, 25)
	MessageLabel.BackgroundTransparency = 1
	MessageLabel.Text = req.Message
	MessageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	MessageLabel.Font = Enum.Font.Gotham
	MessageLabel.TextSize = 14
	MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageLabel.TextWrapped = true
	MessageLabel.Parent = Card

	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Size = UDim2.new(1, 0, 0, 18)
	TimeLabel.Position = UDim2.new(0, 0, 1, -18)
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.Text = "📅 " .. os.date("%Y-%m-%d %H:%M", req.Timestamp)
	TimeLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
	TimeLabel.Font = Enum.Font.Gotham
	TimeLabel.TextSize = 12
	TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	TimeLabel.Parent = Card
end

-- Actualizar lista de solicitudes
local function UpdateRequests(requestsList)
	for _, child in pairs(requestsList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	for _, req in ipairs(verificationRequests) do
		CreateRequestCard(req, requestsList)
	end
end

-----

-- INICIALIZACIÓN Y EVENTOS

task.wait(1)

-- Verificar si es admin
isAdmin = CheckAdminEvent:InvokeServer()

-- Crear GUI
local gui, libraryPanel, searchPanel, verifyPanel, adminPanel, playerBar, songInfo, artistInfo, playButton, requestsList, fullscreenPlayer, fsSongTitle, fsArtistName, fsPlayButton, adPanelFrame, fsPrevButton, fsNextButton = CreateMainGUI()

-- Guardar referencia global
adPanel = adPanelFrame

-- Cargar biblioteca
musicLibrary = RequestMusicList:InvokeServer()
UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
UpdateSearchResults(searchPanel:FindFirstChild("SearchResults"), "")

if isAdmin then
	verificationRequests = RequestVerifyList:InvokeServer() or {}
	UpdateRequests(requestsList)
end

-- Conectar botones de navegación fullscreen
if fsPrevButton then
	fsPrevButton.MouseButton1Click:Connect(function()
		PlayPreviousSong(playerBar, songInfo, artistInfo, playButton)
	end)
end

if fsNextButton then
	fsNextButton.MouseButton1Click:Connect(function()
		PlayNextSong(playerBar, songInfo, artistInfo, playButton)
	end)
end

-- Iniciar sistema de anuncios
StartAdSystem(adPanel, playerBar, songInfo, artistInfo, playButton)

-- Escuchar actualizaciones de música
MusicUpdateEvent.OnClientEvent:Connect(function(action, data)
	if action == "ADD" then
		table.insert(musicLibrary, data)
		UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
		UpdateSearchResults(searchPanel:FindFirstChild("SearchResults"), searchPanel:FindFirstChild("SearchInput").Text)
		
		if isAdmin then
			ShowNotification(gui, "✓ Música agregada: " .. data.Title, Color3.fromRGB(46, 125, 50))
		end
	elseif action == "DELETE" then
		for i, music in ipairs(musicLibrary) do
			if music.Id == data then
				table.remove(musicLibrary, i)
				break
			end
		end
		UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
		UpdateSearchResults(searchPanel:FindFirstChild("SearchResults"), searchPanel:FindFirstChild("SearchInput").Text)
		
		if currentPlayingId == data and currentSound then
			currentSound:Stop()
			currentSound:Destroy()
			currentSound = nil
			playerBar.Visible = false
			fullscreenPlayer.Visible = false
			currentPlayingId = nil
			currentMusicData = nil
		end
	end
end)

-- Escuchar actualizaciones de verificación (solo admins)
if isAdmin then
	VerifyUpdateEvent.OnClientEvent:Connect(function(action, data)
		if action == "NEW_REQUEST" then
			table.insert(verificationRequests, data)
			UpdateRequests(requestsList)
			ShowNotification(gui, "📬 Nueva solicitud de " .. data.User, Color3.fromRGB(28, 184, 231))
		end
	end)
end

-- Comando para abrir/cerrar GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.M then
		local mainFrame = gui:FindFirstChild("MainFrame")
		if mainFrame then
			mainFrame.Visible = not mainFrame.Visible
			if not mainFrame.Visible and currentSound and currentSound.Playing then
				currentSound:Pause()
			end
		end
	end
end)

print("════════════════════════════════════")
print("🎵 Amazon Music Sistema Iniciado")
print("Presiona 'M' para abrir la interfaz")
print("Estado Admin:", isAdmin and "✓ Sí" or "✗ No")
print("Canciones cargadas:", #musicLibrary)
print("════════════════════════════════════")
