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
local SendChatEvent = RemotesFolder:WaitForChild("SendChatEvent")
local ChatUpdateEvent = RemotesFolder:WaitForChild("ChatUpdateEvent")

-- Variables globales
local isAdmin = false
local currentSound = nil
local musicLibrary = {}
local verificationRequests = {}
local currentPlayingId = nil
local currentMusicData = nil
local isFullscreen = false
local currentMusicIndex = nil

-----

-- CREACIÃN DE INTERFAZ DE USUARIO (GUI)

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

	-- Logo Glam Music
	local Logo = Instance.new("TextLabel")
	Logo.Name = "Logo"
	Logo.Size = UDim2.new(0, 300, 1, 0)
	Logo.Position = UDim2.new(0, 20, 0, 0)
	Logo.BackgroundTransparency = 1
	Logo.Text = "â¨ Glam Music"
	Logo.TextColor3 = Color3.fromRGB(28, 184, 231)
	Logo.Font = Enum.Font.GothamBold
	Logo.TextSize = 28
	Logo.TextXAlignment = Enum.TextXAlignment.Left
	Logo.Parent = TopBar

	-- BotÃ³n Comunidad (solo para admins)
	local CommunityButton
	if isAdmin then
		CommunityButton = Instance.new("TextButton")
		CommunityButton.Name = "CommunityButton"
		CommunityButton.Size = UDim2.new(0, 160, 0, 50)
		CommunityButton.Position = UDim2.new(1, -180, 0.5, -25)
		CommunityButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
		CommunityButton.Text = "ð¥ Comunidad"
		CommunityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		CommunityButton.Font = Enum.Font.GothamBold
		CommunityButton.TextSize = 16
		CommunityButton.BorderSizePixel = 0
		CommunityButton.Parent = TopBar

		local CommunityCorner = Instance.new("UICorner")
		CommunityCorner.CornerRadius = UDim.new(0, 10)
		CommunityCorner.Parent = CommunityButton
	end

	-- Ãrea de contenido
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

	-- Panel de BÃºsqueda
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
	SearchInput.PlaceholderText = "ð Buscar canciones, artistas..."
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

	-- Panel de VerificaciÃ³n
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
	Instructions.Text = "â VerificaciÃ³n de Artista\n\nSi eres un artista y quieres verificar tu cuenta,\nenvÃ­a un mensaje a los administradores."
	Instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instructions.Font = Enum.Font.Gotham
	Instructions.TextSize = 16
	Instructions.TextWrapped = true
	Instructions.Parent = VerifyPanel

	local MessageBox = Instance.new("TextBox")
	MessageBox.Size = UDim2.new(1, 0, 0, 180)
	MessageBox.Position = UDim2.new(0, 0, 0, 150)
	MessageBox.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	MessageBox.PlaceholderText = "Escribe tu mensaje aquÃ­..."
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

	-- Panel de Comunidad (Chat de Admins)
	local CommunityPanel = Instance.new("Frame")
	CommunityPanel.Name = "CommunityPanel"
	CommunityPanel.Size = UDim2.new(1, -40, 1, 0)
	CommunityPanel.Position = UDim2.new(0, 20, 0, 0)
	CommunityPanel.BackgroundTransparency = 1
	CommunityPanel.Visible = false
	CommunityPanel.Parent = ContentArea

	local CommunityTitle = Instance.new("TextLabel")
	CommunityTitle.Size = UDim2.new(1, 0, 0, 50)
	CommunityTitle.Position = UDim2.new(0, 0, 0, 0)
	CommunityTitle.BackgroundTransparency = 1
	CommunityTitle.Text = "ð¥ Comunidad de Desarrolladores"
	CommunityTitle.TextColor3 = Color3.fromRGB(28, 184, 231)
	CommunityTitle.Font = Enum.Font.GothamBold
	CommunityTitle.TextSize = 26
	CommunityTitle.TextXAlignment = Enum.TextXAlignment.Left
	CommunityTitle.Parent = CommunityPanel

	-- Lista de mensajes de chat
	local ChatList = Instance.new("ScrollingFrame")
	ChatList.Name = "ChatList"
	ChatList.Size = UDim2.new(1, 0, 1, -125)
	ChatList.Position = UDim2.new(0, 0, 0, 60)
	ChatList.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	ChatList.BorderSizePixel = 0
	ChatList.ScrollBarThickness = 8
	ChatList.ScrollBarImageColor3 = Color3.fromRGB(28, 184, 231)
	ChatList.CanvasSize = UDim2.new(0, 0, 0, 0)
	ChatList.Parent = CommunityPanel

	local ChatCorner = Instance.new("UICorner")
	ChatCorner.CornerRadius = UDim.new(0, 15)
	ChatCorner.Parent = ChatList

	local ChatLayout = Instance.new("UIListLayout")
	ChatLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ChatLayout.Padding = UDim.new(0, 8)
	ChatLayout.Parent = ChatList

	local ChatPadding = Instance.new("UIPadding")
	ChatPadding.PaddingLeft = UDim.new(0, 15)
	ChatPadding.PaddingRight = UDim.new(0, 15)
	ChatPadding.PaddingTop = UDim.new(0, 15)
	ChatPadding.PaddingBottom = UDim.new(0, 15)
	ChatPadding.Parent = ChatList

	ChatLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ChatList.CanvasSize = UDim2.new(0, 0, 0, ChatLayout.AbsoluteContentSize.Y + 30)
		ChatList.CanvasPosition = Vector2.new(0, ChatList.AbsoluteCanvasSize.Y)
	end)

	-- Input de mensaje
	local ChatInput = Instance.new("TextBox")
	ChatInput.Name = "ChatInput"
	ChatInput.Size = UDim2.new(1, -120, 0, 50)
	ChatInput.Position = UDim2.new(0, 0, 1, -55)
	ChatInput.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	ChatInput.PlaceholderText = "Escribe un mensaje..."
	ChatInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	ChatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	ChatInput.Font = Enum.Font.Gotham
	ChatInput.TextSize = 16
	ChatInput.TextXAlignment = Enum.TextXAlignment.Left
	ChatInput.ClearTextOnFocus = false
	ChatInput.Parent = CommunityPanel

	local ChatInputPadding = Instance.new("UIPadding")
	ChatInputPadding.PaddingLeft = UDim.new(0, 15)
	ChatInputPadding.Parent = ChatInput

	local ChatInputCorner = Instance.new("UICorner")
	ChatInputCorner.CornerRadius = UDim.new(0, 12)
	ChatInputCorner.Parent = ChatInput

	-- BotÃ³n enviar mensaje
	local SendChatButton = Instance.new("TextButton")
	SendChatButton.Size = UDim2.new(0, 100, 0, 50)
	SendChatButton.Position = UDim2.new(1, -100, 1, -55)
	SendChatButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	SendChatButton.Text = "Enviar"
	SendChatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SendChatButton.Font = Enum.Font.GothamBold
	SendChatButton.TextSize = 16
	SendChatButton.Parent = CommunityPanel

	local SendChatCorner = Instance.new("UICorner")
	SendChatCorner.CornerRadius = UDim.new(0, 12)
	SendChatCorner.Parent = SendChatButton

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
	AdminTitle.Text = "âï¸ Panel de AdministraciÃ³n"
	AdminTitle.TextColor3 = Color3.fromRGB(28, 184, 231)
	AdminTitle.Font = Enum.Font.GothamBold
	AdminTitle.TextSize = 26
	AdminTitle.TextXAlignment = Enum.TextXAlignment.Left
	AdminTitle.Parent = AdminPanel

	-- Formulario agregar mÃºsica
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

	local TitleInput = CreateInput("TitleInput", "TÃ­tulo de la canciÃ³n", UDim2.new(0, 0, 0, 0))
	local ArtistInput = CreateInput("ArtistInput", "Artista", UDim2.new(0.52, 0, 0, 0))
	local SoundIdInput = CreateInput("SoundIdInput", "ID de Sonido", UDim2.new(0, 0, 0, 60))
	local DurationInput = CreateInput("DurationInput", "DuraciÃ³n (ej: 3:45)", UDim2.new(0.52, 0, 0, 60))
	local AlbumInput = CreateInput("AlbumInput", "Ãlbum", UDim2.new(0, 0, 0, 120))
	local GenreInput = CreateInput("GenreInput", "GÃ©nero", UDim2.new(0.52, 0, 0, 120))

	-- BotÃ³n agregar
	local AddButton = Instance.new("TextButton")
	AddButton.Size = UDim2.new(1, 0, 0, 55)
	AddButton.Position = UDim2.new(0, 0, 0, 185)
	AddButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	AddButton.Text = "â Agregar MÃºsica"
	AddButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AddButton.Font = Enum.Font.GothamBold
	AddButton.TextSize = 18
	AddButton.BorderSizePixel = 0
	AddButton.Parent = FormFrame

	local AddCorner = Instance.new("UICorner")
	AddCorner.CornerRadius = UDim.new(0, 12)
	AddCorner.Parent = AddButton

	-- SecciÃ³n de solicitudes
	local RequestsTitle = Instance.new("TextLabel")
	RequestsTitle.Size = UDim2.new(1, 0, 0, 50)
	RequestsTitle.Position = UDim2.new(0, 0, 0, 460)
	RequestsTitle.BackgroundTransparency = 1
	RequestsTitle.Text = "ð Solicitudes de VerificaciÃ³n"
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

	-- BotÃ³n minimizar
	local MinimizeButton = Instance.new("TextButton")
	MinimizeButton.Size = UDim2.new(0, 60, 0, 60)
	MinimizeButton.Position = UDim2.new(0, 20, 0, 20)
	MinimizeButton.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	MinimizeButton.Text = "â"
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
	AlbumCover.Text = "ðµ"
	AlbumCover.TextColor3 = Color3.fromRGB(28, 184, 231)
	AlbumCover.Font = Enum.Font.GothamBold
	AlbumCover.TextSize = 120
	AlbumCover.ZIndex = 11
	AlbumCover.Parent = FullscreenPlayer

	local CoverCorner = Instance.new("UICorner")
	CoverCorner.CornerRadius = UDim.new(0, 20)
	CoverCorner.Parent = AlbumCover

	-- InformaciÃ³n de la canciÃ³n en fullscreen
	local FSSongTitle = Instance.new("TextLabel")
	FSSongTitle.Size = UDim2.new(1, -100, 0, 50)
	FSSongTitle.Position = UDim2.new(0, 50, 0.65, 0)
	FSSongTitle.BackgroundTransparency = 1
	FSSongTitle.Text = "Nombre de la CanciÃ³n"
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

	-- BotÃ³n anterior
	local FSPrevButton = Instance.new("TextButton")
	FSPrevButton.Name = "FSPrevButton"
	FSPrevButton.Size = UDim2.new(0, 65, 0, 65)
	FSPrevButton.Position = UDim2.new(0.5, -165, 0.5, -32.5)
	FSPrevButton.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	FSPrevButton.Text = "â®"
	FSPrevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FSPrevButton.Font = Enum.Font.GothamBold
	FSPrevButton.TextSize = 28
	FSPrevButton.ZIndex = 11
	FSPrevButton.Parent = ControlsFrame

	local FSPrevCorner = Instance.new("UICorner")
	FSPrevCorner.CornerRadius = UDim.new(1, 0)
	FSPrevCorner.Parent = FSPrevButton

	-- BotÃ³n play/pause (centrado)
	local FSPlayPauseButton = Instance.new("TextButton")
	FSPlayPauseButton.Name = "FSPlayPauseButton"
	FSPlayPauseButton.Size = UDim2.new(0, 80, 0, 80)
	FSPlayPauseButton.Position = UDim2.new(0.5, -40, 0.5, -40)
	FSPlayPauseButton.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	FSPlayPauseButton.Text = "â¶"
	FSPlayPauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FSPlayPauseButton.Font = Enum.Font.GothamBold
	FSPlayPauseButton.TextSize = 35
	FSPlayPauseButton.ZIndex = 11
	FSPlayPauseButton.Parent = ControlsFrame

	local FSPlayCorner = Instance.new("UICorner")
	FSPlayCorner.CornerRadius = UDim.new(1, 0)
	FSPlayCorner.Parent = FSPlayPauseButton

	-- BotÃ³n siguiente
	local FSNextButton = Instance.new("TextButton")
	FSNextButton.Name = "FSNextButton"
	FSNextButton.Size = UDim2.new(0, 65, 0, 65)
	FSNextButton.Position = UDim2.new(0.5, 100, 0.5, -32.5)
	FSNextButton.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	FSNextButton.Text = "â­"
	FSNextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	FSNextButton.Font = Enum.Font.GothamBold
	FSNextButton.TextSize = 28
	FSNextButton.ZIndex = 11
	FSNextButton.Parent = ControlsFrame

	local FSNextCorner = Instance.new("UICorner")
	FSNextCorner.CornerRadius = UDim.new(1, 0)
	FSNextCorner.Parent = FSNextButton

	-- Barra de navegaciÃ³n inferior
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

	local LibraryButton = CreateNavButton("ðµ", UDim2.new(0, 5, 0, 5))
	local SearchButton = CreateNavButton("ð", UDim2.new(tabWidth, 0, 0, 5))
	local VerifyButton = CreateNavButton("â", UDim2.new(tabWidth * 2, 0, 0, 5))
	
	local AdminButton
	if isAdmin then
		AdminButton = CreateNavButton("âï¸", UDim2.new(tabWidth * 3, 0, 0, 5))
	end

	-- Player de mÃºsica (barra inferior compacta)
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

	-- InformaciÃ³n de canciÃ³n
	local SongInfo = Instance.new("TextLabel")
	SongInfo.Name = "SongInfo"
	SongInfo.Size = UDim2.new(0.6, -100, 0, 30)
	SongInfo.Position = UDim2.new(0, 15, 0, 10)
	SongInfo.BackgroundTransparency = 1
	SongInfo.Text = "Sin reproducciÃ³n"
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
	PlayPauseButton.Text = "â¶"
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
	StopButton.Text = "â "
	StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	StopButton.Font = Enum.Font.GothamBold
	StopButton.TextSize = 20
	StopButton.Parent = PlayerBar

	local StopCorner = Instance.new("UICorner")
	StopCorner.CornerRadius = UDim.new(1, 0)
	StopCorner.Parent = StopButton

	-- AnimaciÃ³n de ondas de mÃºsica
	local WavesFrame = Instance.new("Frame")
	WavesFrame.Name = "WavesFrame"
	WavesFrame.Size = UDim2.new(0, 60, 0, 50)
	WavesFrame.Position = UDim2.new(0, 10, 0.5, -25)
	WavesFrame.BackgroundTransparency = 1
	WavesFrame.Visible = false
	WavesFrame.Parent = PlayerBar

	-- Crear 5 barras de onda
	local waves = {}
	for i = 1, 5 do
		local Wave = Instance.new("Frame")
		Wave.Size = UDim2.new(0, 8, 0, 10)
		Wave.Position = UDim2.new(0, (i - 1) * 12, 1, -10)
		Wave.AnchorPoint = Vector2.new(0, 1)
		Wave.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
		Wave.BorderSizePixel = 0
		Wave.Parent = WavesFrame

		local WaveCorner = Instance.new("UICorner")
		WaveCorner.CornerRadius = UDim.new(0, 4)
		WaveCorner.Parent = Wave

		table.insert(waves, Wave)
	end

	-- BotÃ³n expandir (ahora a la derecha, junto a los controles)
	local ExpandButton = Instance.new("TextButton")
	ExpandButton.Name = "ExpandButton"
	ExpandButton.Size = UDim2.new(0, 50, 0, 50)
	ExpandButton.Position = UDim2.new(1, -185, 0.5, -25)
	ExpandButton.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	ExpandButton.Text = "â¬"
	ExpandButton.TextColor3 = Color3.fromRGB(28, 184, 231)
	ExpandButton.Font = Enum.Font.GothamBold
	ExpandButton.TextSize = 20
	ExpandButton.Parent = PlayerBar

	local ExpandCorner = Instance.new("UICorner")
	ExpandCorner.CornerRadius = UDim.new(1, 0)
	ExpandCorner.Parent = ExpandButton

	-- CONEXIONES DE UI

	-- FunciÃ³n para expandir/contraer reproductor
	local function ToggleFullscreen()
		isFullscreen = not isFullscreen
		FullscreenPlayer.Visible = isFullscreen
		
		if isFullscreen and currentMusicData then
			FSSongTitle.Text = currentMusicData.Title
			FSArtistName.Text = currentMusicData.Artist .. " â¢ " .. (currentMusicData.Album or "")
			
			if currentSound and currentSound.Playing then
				FSPlayPauseButton.Text = "ââ"
			else
				FSPlayPauseButton.Text = "â¶"
			end
		end
	end

	ExpandButton.MouseButton1Click:Connect(ToggleFullscreen)
	MinimizeButton.MouseButton1Click:Connect(ToggleFullscreen)

	-- NavegaciÃ³n
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
		if isAdmin then
			CommunityPanel.Visible = false
		end
		SetActiveTab(LibraryButton)
	end)

	SearchButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = false
		SearchPanel.Visible = true
		VerifyPanel.Visible = false
		AdminPanel.Visible = false
		if isAdmin then
			CommunityPanel.Visible = false
		end
		SetActiveTab(SearchButton)
	end)

	VerifyButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = false
		SearchPanel.Visible = false
		VerifyPanel.Visible = true
		AdminPanel.Visible = false
		if isAdmin then
			CommunityPanel.Visible = false
		end
		SetActiveTab(VerifyButton)
	end)

	if isAdmin then
		AdminButton.MouseButton1Click:Connect(function()
			LibraryPanel.Visible = false
			SearchPanel.Visible = false
			VerifyPanel.Visible = false
			AdminPanel.Visible = true
			CommunityPanel.Visible = false
			SetActiveTab(AdminButton)
		end)
		
		CommunityButton.MouseButton1Click:Connect(function()
			LibraryPanel.Visible = false
			SearchPanel.Visible = false
			VerifyPanel.Visible = false
			AdminPanel.Visible = false
			CommunityPanel.Visible = true
		end)
	end

	-- BÃºsqueda
	SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		UpdateSearchResults(SearchResults, SearchInput.Text)
	end)

	-- Enviar verificaciÃ³n
	SendButton.MouseButton1Click:Connect(function()
		local message = MessageBox.Text
		if message ~= "" then
			SendVerifyRequest:FireServer(message)
			MessageBox.Text = ""
			ShowNotification(ScreenGui, "Solicitud enviada", Color3.fromRGB(46, 125, 50))
		end
	end)

	-- Agregar mÃºsica
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

	-- Controles de reproducciÃ³n (barra compacta)
	PlayPauseButton.MouseButton1Click:Connect(function()
		if currentSound then
			if currentSound.Playing then
				currentSound:Pause()
				PlayPauseButton.Text = "â¶"
				WavesFrame.Visible = false
				if isFullscreen then
					FSPlayPauseButton.Text = "â¶"
				end
			else
				currentSound:Play()
				PlayPauseButton.Text = "ââ"
				WavesFrame.Visible = true
				if isFullscreen then
					FSPlayPauseButton.Text = "ââ"
				end
			end
		end
	end)

	-- Controles de reproducciÃ³n (fullscreen)
	FSPlayPauseButton.MouseButton1Click:Connect(function()
		if currentSound then
			if currentSound.Playing then
				currentSound:Pause()
				FSPlayPauseButton.Text = "â¶"
				PlayPauseButton.Text = "â¶"
				WavesFrame.Visible = false
			else
				currentSound:Play()
				FSPlayPauseButton.Text = "ââ"
				PlayPauseButton.Text = "ââ"
				WavesFrame.Visible = true
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
			PlayPauseButton.Text = "â¶"
			FSPlayPauseButton.Text = "â¶"
			WavesFrame.Visible = false
		end
	end)

	SetActiveTab(LibraryButton)

	return ScreenGui, LibraryPanel, SearchPanel, VerifyPanel, AdminPanel, PlayerBar, SongInfo, ArtistInfo, PlayPauseButton, RequestsList, FullscreenPlayer, FSSongTitle, FSArtistName, FSPlayPauseButton, WavesFrame, waves, ControlsFrame:FindFirstChild("FSPrevButton"), ControlsFrame:FindFirstChild("FSNextButton"), CommunityPanel, ChatList, ChatInput, SendChatButton
end

-----

-- FUNCIONES DE NAVEGACIÃN DE MÃSICA

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
		artistInfo.Text = musicData.Artist .. " â¢ " .. (musicData.Album or "")
		playButton.Text = "ââ"
		
		-- Mostrar animaciÃ³n de ondas
		if wavesFrame then
			wavesFrame.Visible = true
		end
		
		-- Actualizar pantalla completa si estÃ¡ visible
		if isFullscreen then
			fsSongTitle.Text = musicData.Title
			fsArtistName.Text = musicData.Artist .. " â¢ " .. (musicData.Album or "")
			fsPlayButton.Text = "ââ"
		end
	else
		warn("Error al reproducir mÃºsica:", err)
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

-- ANIMACIÃN DE ONDAS

local function AnimateWaves(wavesArray)
	task.spawn(function()
		while true do
			for i, wave in ipairs(wavesArray) do
				task.spawn(function()
					while true do
						local randomHeight = math.random(15, 45)
						local tweenInfo = TweenInfo.new(
							math.random(200, 400) / 1000,
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.InOut
						)
						local tween = TweenService:Create(wave, tweenInfo, {
							Size = UDim2.new(0, 8, 0, randomHeight)
						})
						tween:Play()
						task.wait(math.random(200, 400) / 1000)
					end
				end)
				task.wait(0.05)
			end
			task.wait(1)
		end
	end)
end

-----

-- GESTIÃN DE LA MÃSICA

-- FunciÃ³n para mostrar notificaciones
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

-- Crear tarjeta de mÃºsica (estilo Amazon Music)
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
	MiniCover.Text = "ðµ"
	MiniCover.TextColor3 = Color3.fromRGB(255, 255, 255)
	MiniCover.Font = Enum.Font.GothamBold
	MiniCover.TextSize = 25
	MiniCover.Parent = Card

	local MiniCorner = Instance.new("UICorner")
	MiniCorner.CornerRadius = UDim.new(0, 8)
	MiniCorner.Parent = MiniCover

	-- TÃ­tulo
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

	-- Artista y duraciÃ³n
	local Artist = Instance.new("TextLabel")
	Artist.Size = UDim2.new(1, -250, 0, 22)
	Artist.Position = UDim2.new(0, 80, 0, 38)
	Artist.BackgroundTransparency = 1
	Artist.Text = musicData.Artist .. " â¢ " .. musicData.Duration .. " â¢ " .. (musicData.Genre or "")
	Artist.TextColor3 = Color3.fromRGB(150, 150, 150)
	Artist.Font = Enum.Font.Gotham
	Artist.TextSize = 13
	Artist.TextXAlignment = Enum.TextXAlignment.Left
	Artist.Parent = Card

	-- BotÃ³n play
	local PlayBtn = Instance.new("TextButton")
	PlayBtn.Size = UDim2.new(0, 55, 0, 55)
	PlayBtn.Position = UDim2.new(1, -145, 0.5, -27.5)
	PlayBtn.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	PlayBtn.Text = "â¶"
	PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayBtn.Font = Enum.Font.GothamBold
	PlayBtn.TextSize = 20
	PlayBtn.Parent = Card

	local PlayBtnCorner = Instance.new("UICorner")
	PlayBtnCorner.CornerRadius = UDim.new(1, 0)
	PlayBtnCorner.Parent = PlayBtn

	PlayBtn.MouseButton1Click:Connect(function()
		-- Buscar Ã­ndice de esta canciÃ³n
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
		DeleteBtn.Text = "ð"
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

-- Actualizar resultados de bÃºsqueda
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

-- Crear mensaje de chat
local function CreateChatMessage(messageData, parent)
	local MessageFrame = Instance.new("Frame")
	MessageFrame.Size = UDim2.new(1, 0, 0, 0)
	MessageFrame.BackgroundTransparency = 1
	MessageFrame.AutomaticSize = Enum.AutomaticSize.Y
	MessageFrame.Parent = parent

	local UserFrame = Instance.new("Frame")
	UserFrame.Size = UDim2.new(1, 0, 0, 25)
	UserFrame.BackgroundTransparency = 1
	UserFrame.Parent = MessageFrame

	local UserLabel = Instance.new("TextLabel")
	UserLabel.Size = UDim2.new(0, 0, 1, 0)
	UserLabel.AutomaticSize = Enum.AutomaticSize.X
	UserLabel.BackgroundTransparency = 1
	UserLabel.Text = messageData.User
	UserLabel.TextColor3 = Color3.fromRGB(28, 184, 231)
	UserLabel.Font = Enum.Font.GothamBold
	UserLabel.TextSize = 15
	UserLabel.TextXAlignment = Enum.TextXAlignment.Left
	UserLabel.Parent = UserFrame

	-- Icono de verificaciÃ³n azul para Vegetl_t
	if messageData.User == "Vegetl_t" then
		local VerifiedBadge = Instance.new("ImageLabel")
		VerifiedBadge.Size = UDim2.new(0, 18, 0, 18)
		VerifiedBadge.Position = UDim2.new(0, UserLabel.TextBounds.X + 5, 0.5, -9)
		VerifiedBadge.BackgroundTransparency = 1
		VerifiedBadge.Image = "rbxassetid://7045488196"
		VerifiedBadge.ImageColor3 = Color3.fromRGB(0, 162, 255)
		VerifiedBadge.Parent = UserFrame
	end

	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Size = UDim2.new(0, 100, 1, 0)
	TimeLabel.Position = UDim2.new(1, -100, 0, 0)
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.Text = os.date("%H:%M", messageData.Timestamp)
	TimeLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
	TimeLabel.Font = Enum.Font.Gotham
	TimeLabel.TextSize = 12
	TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
	TimeLabel.Parent = UserFrame

	local MessageText = Instance.new("TextLabel")
	MessageText.Size = UDim2.new(1, 0, 0, 0)
	MessageText.Position = UDim2.new(0, 0, 0, 25)
	MessageText.AutomaticSize = Enum.AutomaticSize.Y
	MessageText.BackgroundTransparency = 1
	MessageText.Text = messageData.Message
	MessageText.TextColor3 = Color3.fromRGB(220, 220, 220)
	MessageText.Font = Enum.Font.Gotham
	MessageText.TextSize = 14
	MessageText.TextXAlignment = Enum.TextXAlignment.Left
	MessageText.TextYAlignment = Enum.TextYAlignment.Top
	MessageText.TextWrapped = true
	MessageText.Parent = MessageFrame
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
	UserLabel.Text = "ð¤ " .. req.User
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
	TimeLabel.Text = "ð " .. os.date("%Y-%m-%d %H:%M", req.Timestamp)
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

-- INICIALIZACIÃN Y EVENTOS

task.wait(1)

-- Verificar si es admin
isAdmin = CheckAdminEvent:InvokeServer()

-- Variables para chat de comunidad
local chatMessages = {}

-- Crear GUI
local gui, libraryPanel, searchPanel, verifyPanel, adminPanel, playerBar, songInfo, artistInfo, playButton, requestsList, fullscreenPlayer, fsSongTitle, fsArtistName, fsPlayButton, wavesFrame, waves, fsPrevButton, fsNextButton, communityPanel, chatList, chatInput, sendChatButton = CreateMainGUI()

-- Funciones de chat (solo para admins)
if isAdmin and communityPanel then
	sendChatButton.MouseButton1Click:Connect(function()
		local message = chatInput.Text
		if message ~= "" then
			SendChatEvent:FireServer(message)
			chatInput.Text = ""
		end
	end)
	
	chatInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			sendChatButton.MouseButton1Click:Fire()
		end
	end)
	
	-- Recibir mensajes de chat en tiempo real
	ChatUpdateEvent.OnClientEvent:Connect(function(chatData)
		table.insert(chatMessages, chatData)
		CreateChatMessage(chatData, chatList)
	end)
end

-- Iniciar animaciÃ³n de ondas
AnimateWaves(waves)

-- Cargar biblioteca
musicLibrary = RequestMusicList:InvokeServer()
UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
UpdateSearchResults(searchPanel:FindFirstChild("SearchResults"), "")

if isAdmin then
	verificationRequests = RequestVerifyList:InvokeServer() or {}
	UpdateRequests(requestsList)
end

-- Conectar botones de navegaciÃ³n fullscreen
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

-- Escuchar actualizaciones de mÃºsica
MusicUpdateEvent.OnClientEvent:Connect(function(action, data)
	if action == "ADD" then
		table.insert(musicLibrary, data)
		UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
		UpdateSearchResults(searchPanel:FindFirstChild("SearchResults"), searchPanel:FindFirstChild("SearchInput").Text)
		
		if isAdmin then
			ShowNotification(gui, "â MÃºsica agregada: " .. data.Title, Color3.fromRGB(46, 125, 50))
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

-- Escuchar actualizaciones de verificaciÃ³n (solo admins)
if isAdmin then
	VerifyUpdateEvent.OnClientEvent:Connect(function(action, data)
		if action == "NEW_REQUEST" then
			table.insert(verificationRequests, data)
			UpdateRequests(requestsList)
			ShowNotification(gui, "ð¬ Nueva solicitud de " .. data.User, Color3.fromRGB(28, 184, 231))
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

print("ââââââââââââââââââââââââââââââââââââ")
print("â¨ Glam Music Sistema Iniciado")
print("Presiona 'M' para abrir la interfaz")
print("Estado Admin:", isAdmin and "â SÃ­" or "â No")
print("Canciones cargadas:", #musicLibrary)
print("ââââââââââââââââââââââââââââââââââââ")
