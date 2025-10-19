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

-----

-- CREACIÓN DE INTERFAZ DE USUARIO (GUI)

-- Crear GUI principal
local function CreateMainGUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AmazonMusicGUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.IgnoreGuiInset = true  -- Para expandir a margen a margen, ignorando la barra superior de Roblox
	ScreenGui.Parent = playerGui

	-- Fondo principal (full screen, estilo TikTok: negro)
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(1, 0, 1, 0)
	MainFrame.Position = UDim2.new(0, 0, 0, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	-- Barra superior (ajustada a estilo TikTok, sin márgenes)
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 60)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MainFrame

	-- Logo
	local Logo = Instance.new("TextLabel")
	Logo.Name = "Logo"
	Logo.Size = UDim2.new(0, 250, 1, 0)
	Logo.Position = UDim2.new(0, 10, 0, 0)
	Logo.BackgroundTransparency = 1
	Logo.Text = "🎵 Amazon Music"
	Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
	Logo.Font = Enum.Font.GothamBold
	Logo.TextSize = 24
	Logo.TextXAlignment = Enum.TextXAlignment.Left
	Logo.Parent = TopBar

	-- Botón cerrar
	local CloseButton = Instance.new("TextButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Size = UDim2.new(0, 50, 0, 50)
	CloseButton.Position = UDim2.new(1, -50, 0.5, -25)
	CloseButton.BackgroundTransparency = 1
	CloseButton.Text = "✕"
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 20
	CloseButton.BorderSizePixel = 0
	CloseButton.Parent = TopBar

	CloseButton.MouseButton1Click:Connect(function()
		MainFrame.Visible = false
		if currentSound then
			currentSound:Stop()
		end
	end)

	-- Área de contenido (sin márgenes)
	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, 0, 1, -120)
	ContentArea.Position = UDim2.new(0, 0, 0, 60)
	ContentArea.BackgroundTransparency = 1
	ContentArea.BorderSizePixel = 0
	ContentArea.Parent = MainFrame

	-- Panel de Biblioteca
	local LibraryPanel = Instance.new("ScrollingFrame")
	LibraryPanel.Name = "LibraryPanel"
	LibraryPanel.Size = UDim2.new(1, 0, 1, 0)
	LibraryPanel.Position = UDim2.new(0, 0, 0, 0)
	LibraryPanel.BackgroundTransparency = 1
	LibraryPanel.BorderSizePixel = 0
	LibraryPanel.ScrollBarThickness = 6
	LibraryPanel.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	LibraryPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
	LibraryPanel.Parent = ContentArea
	LibraryPanel.Visible = true

	local LibraryLayout = Instance.new("UIListLayout")
	LibraryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	LibraryLayout.Padding = UDim.new(0, 5)
	LibraryLayout.Parent = LibraryPanel

	LibraryLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		LibraryPanel.CanvasSize = UDim2.new(0, 0, 0, LibraryLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Panel de Búsqueda
	local SearchPanel = Instance.new("Frame")
	SearchPanel.Name = "SearchPanel"
	SearchPanel.Size = UDim2.new(1, 0, 1, 0)
	SearchPanel.Position = UDim2.new(0, 0, 0, 0)
	SearchPanel.BackgroundTransparency = 1
	SearchPanel.Visible = false
	SearchPanel.Parent = ContentArea

	local SearchInput = Instance.new("TextBox")
	SearchInput.Name = "SearchInput"
	SearchInput.Size = UDim2.new(1, 0, 0, 40)
	SearchInput.Position = UDim2.new(0, 0, 0, 0)
	SearchInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	SearchInput.PlaceholderText = "Buscar música..."
	SearchInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	SearchInput.Font = Enum.Font.Gotham
	SearchInput.TextSize = 16
	SearchInput.Parent = SearchPanel

	local SearchCorner = Instance.new("UICorner")
	SearchCorner.CornerRadius = UDim.new(0, 20)
	SearchCorner.Parent = SearchInput

	local SearchResults = Instance.new("ScrollingFrame")
	SearchResults.Name = "SearchResults"
	SearchResults.Size = UDim2.new(1, 0, 1, -40)
	SearchResults.Position = UDim2.new(0, 0, 0, 40)
	SearchResults.BackgroundTransparency = 1
	SearchResults.ScrollBarThickness = 6
	SearchResults.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	SearchResults.CanvasSize = UDim2.new(0, 0, 0, 0)
	SearchResults.Parent = SearchPanel

	local SearchLayout = Instance.new("UIListLayout")
	SearchLayout.SortOrder = Enum.SortOrder.LayoutOrder
	SearchLayout.Padding = UDim.new(0, 5)
	SearchLayout.Parent = SearchResults

	SearchLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		SearchResults.CanvasSize = UDim2.new(0, 0, 0, SearchLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Panel de Verificación
	local VerifyPanel = Instance.new("Frame")
	VerifyPanel.Name = "VerifyPanel"
	VerifyPanel.Size = UDim2.new(1, 0, 1, 0)
	VerifyPanel.Position = UDim2.new(0, 0, 0, 0)
	VerifyPanel.BackgroundTransparency = 1
	VerifyPanel.Visible = false
	VerifyPanel.Parent = ContentArea

	local Instructions = Instance.new("TextLabel")
	Instructions.Size = UDim2.new(1, 0, 0, 100)
	Instructions.Position = UDim2.new(0, 0, 0, 0)
	Instructions.BackgroundTransparency = 1
	Instructions.Text = "Si quieres ser verificado, envía un mensaje a los administradores oficiales."
	Instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instructions.Font = Enum.Font.Gotham
	Instructions.TextSize = 16
	Instructions.TextWrapped = true
	Instructions.Parent = VerifyPanel

	local MessageBox = Instance.new("TextBox")
	MessageBox.Size = UDim2.new(1, 0, 0, 150)
	MessageBox.Position = UDim2.new(0, 0, 0, 100)
	MessageBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	MessageBox.PlaceholderText = "Escribe tu mensaje aquí..."
	MessageBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	MessageBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	MessageBox.Font = Enum.Font.Gotham
	MessageBox.TextSize = 14
	MessageBox.MultiLine = true
	MessageBox.Parent = VerifyPanel

	local MessageCorner = Instance.new("UICorner")
	MessageCorner.CornerRadius = UDim.new(0, 8)
	MessageCorner.Parent = MessageBox

	local SendButton = Instance.new("TextButton")
	SendButton.Size = UDim2.new(1, 0, 0, 50)
	SendButton.Position = UDim2.new(0, 0, 0, 250)
	SendButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	SendButton.Text = "Enviar"
	SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SendButton.Font = Enum.Font.GothamBold
	SendButton.TextSize = 16
	SendButton.Parent = VerifyPanel

	local SendCorner = Instance.new("UICorner")
	SendCorner.CornerRadius = UDim.new(0, 8)
	SendCorner.Parent = SendButton

	-- Panel de Admin
	local AdminPanel = Instance.new("Frame")
	AdminPanel.Name = "AdminPanel"
	AdminPanel.Size = UDim2.new(1, 0, 1, 0)
	AdminPanel.Position = UDim2.new(0, 0, 0, 0)
	AdminPanel.BackgroundTransparency = 1
	AdminPanel.Visible = false
	AdminPanel.Parent = ContentArea

	local AdminTitle = Instance.new("TextLabel")
	AdminTitle.Size = UDim2.new(1, 0, 0, 40)
	AdminTitle.Position = UDim2.new(0, 0, 0, 0)
	AdminTitle.BackgroundTransparency = 1
	AdminTitle.Text = "Panel de Administración"
	AdminTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	AdminTitle.Font = Enum.Font.GothamBold
	AdminTitle.TextSize = 22
	AdminTitle.TextXAlignment = Enum.TextXAlignment.Left
	AdminTitle.Parent = AdminPanel

	-- Formulario agregar música (sin márgenes)
	local FormFrame = Instance.new("Frame")
	FormFrame.Size = UDim2.new(1, 0, 0, 300)
	FormFrame.Position = UDim2.new(0, 0, 0, 40)
	FormFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	FormFrame.BorderSizePixel = 0
	FormFrame.Parent = AdminPanel

	local FormCorner = Instance.new("UICorner")
	FormCorner.CornerRadius = UDim.new(0, 8)
	FormCorner.Parent = FormFrame

	-- Helper function para crear inputs (ajustados)
	local function CreateInput(name, placeholder, position)
		local InputFrame = Instance.new("Frame")
		InputFrame.Size = UDim2.new(0.5, 0, 0, 40)
		InputFrame.Position = position
		InputFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		InputFrame.BorderSizePixel = 0
		InputFrame.Parent = FormFrame
		
		local InputCorner = Instance.new("UICorner")
		InputCorner.CornerRadius = UDim.new(0, 6)
		InputCorner.Parent = InputFrame
		
		local TextBox = Instance.new("TextBox")
		TextBox.Name = name
		TextBox.Size = UDim2.new(1, -10, 1, 0)
		TextBox.Position = UDim2.new(0, 5, 0, 0)
		TextBox.BackgroundTransparency = 1
		TextBox.PlaceholderText = placeholder
		TextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
		TextBox.Text = ""
		TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		TextBox.Font = Enum.Font.Gotham
		TextBox.TextSize = 14
		TextBox.TextXAlignment = Enum.TextXAlignment.Left
		TextBox.ClearTextOnFocus = false
		TextBox.Parent = InputFrame
		
		return TextBox
	end

	local TitleInput = CreateInput("TitleInput", "Título de la canción", UDim2.new(0, 0, 0, 0))
	local ArtistInput = CreateInput("ArtistInput", "Artista", UDim2.new(0.5, 0, 0, 0))
	local SoundIdInput = CreateInput("SoundIdInput", "ID de Sonido (números)", UDim2.new(0, 0, 0, 50))
	local DurationInput = CreateInput("DurationInput", "Duración (ej: 3:45)", UDim2.new(0.5, 0, 0, 50))
	local AlbumInput = CreateInput("AlbumInput", "Álbum (opcional)", UDim2.new(0, 0, 0, 100))
	local GenreInput = CreateInput("GenreInput", "Género (opcional)", UDim2.new(0.5, 0, 0, 100))

	-- Botón agregar (full width)
	local AddButton = Instance.new("TextButton")
	AddButton.Size = UDim2.new(1, 0, 0, 50)
	AddButton.Position = UDim2.new(0, 0, 0, 150)
	AddButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	AddButton.Text = "➕ Agregar Música"
	AddButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	AddButton.Font = Enum.Font.GothamBold
	AddButton.TextSize = 16
	AddButton.BorderSizePixel = 0
	AddButton.Parent = FormFrame

	local AddCorner = Instance.new("UICorner")
	AddCorner.CornerRadius = UDim.new(0, 8)
	AddCorner.Parent = AddButton

	-- Sección de solicitudes
	local RequestsTitle = Instance.new("TextLabel")
	RequestsTitle.Size = UDim2.new(1, 0, 0, 40)
	RequestsTitle.Position = UDim2.new(0, 0, 0, 340)
	RequestsTitle.BackgroundTransparency = 1
	RequestsTitle.Text = "Solicitudes de Verificación"
	RequestsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	RequestsTitle.Font = Enum.Font.GothamBold
	RequestsTitle.TextSize = 22
	RequestsTitle.TextXAlignment = Enum.TextXAlignment.Left
	RequestsTitle.Parent = AdminPanel

	local RequestsList = Instance.new("ScrollingFrame")
	RequestsList.Name = "RequestsList"
	RequestsList.Size = UDim2.new(1, 0, 1, -380)
	RequestsList.Position = UDim2.new(0, 0, 0, 380)
	RequestsList.BackgroundTransparency = 1
	RequestsList.ScrollBarThickness = 6
	RequestsList.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	RequestsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	RequestsList.Parent = AdminPanel

	local RequestsLayout = Instance.new("UIListLayout")
	RequestsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	RequestsLayout.Padding = UDim.new(0, 5)
	RequestsLayout.Parent = RequestsList

	RequestsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		RequestsList.CanvasSize = UDim2.new(0, 0, 0, RequestsLayout.AbsoluteContentSize.Y + 10)
	end)

	-- Barra de navegación inferior (estilo TikTok, full width)
	local NavBar = Instance.new("Frame")
	NavBar.Name = "NavBar"
	NavBar.Size = UDim2.new(1, 0, 0, 60)
	NavBar.Position = UDim2.new(0, 0, 1, -60)
	NavBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	NavBar.BorderSizePixel = 0
	NavBar.Parent = MainFrame

	local numTabs = isAdmin and 4 or 3
	local tabWidth = 1 / numTabs

	local LibraryButton = Instance.new("TextButton")
	LibraryButton.Name = "LibraryButton"
	LibraryButton.Size = UDim2.new(tabWidth, 0, 1, 0)
	LibraryButton.Position = UDim2.new(0, 0, 0, 0)
	LibraryButton.BackgroundTransparency = 1
	LibraryButton.Text = "🎵 Músicas"
	LibraryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	LibraryButton.Font = Enum.Font.GothamBold
	LibraryButton.TextSize = 14
	LibraryButton.Parent = NavBar

	local SearchButton = Instance.new("TextButton")
	SearchButton.Name = "SearchButton"
	SearchButton.Size = UDim2.new(tabWidth, 0, 1, 0)
	SearchButton.Position = UDim2.new(tabWidth, 0, 0, 0)
	SearchButton.BackgroundTransparency = 1
	SearchButton.Text = "🔍 Buscar"
	SearchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SearchButton.Font = Enum.Font.GothamBold
	SearchButton.TextSize = 14
	SearchButton.Parent = NavBar

	local VerifyButton = Instance.new("TextButton")
	VerifyButton.Name = "VerifyButton"
	VerifyButton.Size = UDim2.new(tabWidth, 0, 1, 0)
	VerifyButton.Position = UDim2.new(tabWidth * 2, 0, 0, 0)
	VerifyButton.BackgroundTransparency = 1
	VerifyButton.Text = "✅ Verificación"
	VerifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	LibraryButton.Font = Enum.Font.GothamBold
	VerifyButton.TextSize = 14
	VerifyButton.Parent = NavBar

	local AdminButton
	if isAdmin then
		AdminButton = Instance.new("TextButton")
		AdminButton.Name = "AdminButton"
		AdminButton.Size = UDim2.new(tabWidth, 0, 1, 0)
		AdminButton.Position = UDim2.new(tabWidth * 3, 0, 0, 0)
		AdminButton.BackgroundTransparency = 1
		AdminButton.Text = "⚙️ Admin"
		AdminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		AdminButton.Font = Enum.Font.GothamBold
		AdminButton.TextSize = 14
		AdminButton.Parent = NavBar
	end

	-- Player de música (parte inferior, arriba de nav, full width)
	local PlayerBar = Instance.new("Frame")
	PlayerBar.Name = "PlayerBar"
	PlayerBar.Size = UDim2.new(1, 0, 0, 60)
	PlayerBar.Position = UDim2.new(0, 0, 1, -120)
	PlayerBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	PlayerBar.BorderSizePixel = 0
	PlayerBar.Visible = false
	PlayerBar.Parent = MainFrame

	-- Información de canción
	local SongInfo = Instance.new("TextLabel")
	SongInfo.Name = "SongInfo"
	SongInfo.Size = UDim2.new(1, -100, 0, 30)
	SongInfo.Position = UDim2.new(0, 10, 0, 5)
	SongInfo.BackgroundTransparency = 1
	SongInfo.Text = "Sin reproducción"
	SongInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
	SongInfo.Font = Enum.Font.GothamBold
	SongInfo.TextSize = 14
	SongInfo.TextXAlignment = Enum.TextXAlignment.Left
	SongInfo.Parent = PlayerBar

	local ArtistInfo = Instance.new("TextLabel")
	ArtistInfo.Name = "ArtistInfo"
	ArtistInfo.Size = UDim2.new(1, -100, 0, 20)
	ArtistInfo.Position = UDim2.new(0, 10, 0, 30)
	ArtistInfo.BackgroundTransparency = 1
	ArtistInfo.Text = ""
	ArtistInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
	ArtistInfo.Font = Enum.Font.Gotham
	ArtistInfo.TextSize = 12
	ArtistInfo.TextXAlignment = Enum.TextXAlignment.Left
	ArtistInfo.Parent = PlayerBar

	-- Controles
	local PlayPauseButton = Instance.new("TextButton")
	PlayPauseButton.Name = "PlayPauseButton"
	PlayPauseButton.Size = UDim2.new(0, 40, 0, 40)
	PlayPauseButton.Position = UDim2.new(1, -90, 0.5, -20)
	PlayPauseButton.BackgroundTransparency = 1
	PlayPauseButton.Text = "▶"
	PlayPauseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayPauseButton.Font = Enum.Font.GothamBold
	PlayPauseButton.TextSize = 20
	PlayPauseButton.Parent = PlayerBar

	local StopButton = Instance.new("TextButton")
	StopButton.Name = "StopButton"
	StopButton.Size = UDim2.new(0, 40, 0, 40)
	StopButton.Position = UDim2.new(1, -40, 0.5, -20)
	StopButton.BackgroundTransparency = 1
	StopButton.Text = "■"
	StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	StopButton.Font = Enum.Font.GothamBold
	StopButton.TextSize = 18
	StopButton.Parent = PlayerBar

	-- CONEXIONES DE UI

	-- Navegación
	LibraryButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = true
		SearchPanel.Visible = false
		VerifyPanel.Visible = false
		AdminPanel.Visible = false
	end)

	SearchButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = false
		SearchPanel.Visible = true
		VerifyPanel.Visible = false
		AdminPanel.Visible = false
	end)

	VerifyButton.MouseButton1Click:Connect(function()
		LibraryPanel.Visible = false
		SearchPanel.Visible = false
		VerifyPanel.Visible = true
		AdminPanel.Visible = false
	end)

	if isAdmin then
		AdminButton.MouseButton1Click:Connect(function()
			LibraryPanel.Visible = false
			SearchPanel.Visible = false
			VerifyPanel.Visible = false
			AdminPanel.Visible = true
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
			-- Notificación
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0, 300, 0, 50)
			notification.AnchorPoint = Vector2.new(0.5, 0)
			notification.Position = UDim2.new(0.5, 0, 0, -50)
			notification.BackgroundColor3 = Color3.fromRGB(46, 125, 50)
			notification.Text = "Solicitud enviada"
			notification.TextColor3 = Color3.fromRGB(255, 255, 255)
			notification.Font = Enum.Font.GothamBold
			notification.TextSize = 14
			notification.Parent = ScreenGui
			
			local notifCorner = Instance.new("UICorner")
			notifCorner.Parent = notification
			
			local tweenIn = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, 20)})
			tweenIn:Play()
			task.wait(2)
			local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, -50)})
			tweenOut:Play()
			tweenOut.Completed:Wait()
			notification:Destroy()
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

	-- Controles de reproducción
	PlayPauseButton.MouseButton1Click:Connect(function()
		if currentSound then
			if currentSound.Playing then
				currentSound:Pause()
				PlayPauseButton.Text = "▶"
			else
				currentSound:Play()
				PlayPauseButton.Text = "❚❚"
			end
		end
	end)

	StopButton.MouseButton1Click:Connect(function()
		if currentSound then
			currentSound:Stop()
			PlayerBar.Visible = false
			currentPlayingId = nil
			PlayPauseButton.Text = "▶"
		end
	end)

	return ScreenGui, LibraryPanel, SearchPanel, VerifyPanel, AdminPanel, PlayerBar, SongInfo, ArtistInfo, PlayPauseButton, RequestsList
end

-----

-- GESTIÓN DE LA MÚSICA

-- Crear tarjeta de música (estilo TikTok: minimalista, full width)
local function CreateMusicCard(musicData, parent, playerBar, songInfo, artistInfo, playButton, isAdmin)
	local Card = Instance.new("Frame")
	Card.Name = "MusicCard_" .. musicData.Id
	Card.Size = UDim2.new(1, 0, 0, 60)
	Card.BackgroundTransparency = 1
	Card.Parent = parent
	Card.LayoutOrder = musicData.Id

	-- Título
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -150, 0, 20)
	Title.Position = UDim2.new(0, 10, 0, 5)
	Title.BackgroundTransparency = 1
	Title.Text = musicData.Title
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 16
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.Parent = Card

	-- Artista y duración
	local Artist = Instance.new("TextLabel")
	Artist.Size = UDim2.new(1, -150, 0, 20)
	Artist.Position = UDim2.new(0, 10, 0, 25)
	Artist.BackgroundTransparency = 1
	Artist.Text = musicData.Artist .. " • " .. musicData.Duration
	Artist.TextColor3 = Color3.fromRGB(180, 180, 180)
	Artist.Font = Enum.Font.Gotham
	Artist.TextSize = 12
	Artist.TextXAlignment = Enum.TextXAlignment.Left
	Artist.Parent = Card

	-- Botón play
	local PlayBtn = Instance.new("TextButton")
	PlayBtn.Size = UDim2.new(0, 120, 0, 40)
	PlayBtn.Position = UDim2.new(1, -130, 0.5, -20)
	PlayBtn.BackgroundTransparency = 1
	PlayBtn.Text = "▶ Reproducir"
	PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayBtn.Font = Enum.Font.GothamBold
	PlayBtn.TextSize = 14
	PlayBtn.Parent = Card

	PlayBtn.MouseButton1Click:Connect(function()
		if currentSound then
			currentSound:Stop()
			currentSound:Destroy()
		end
		
		currentSound = Instance.new("Sound")
		currentSound.SoundId = "rbxassetid://" .. musicData.SoundId
		currentSound.Volume = 0.5
		currentSound.Parent = SoundService
		currentSound:Play()
		
		currentPlayingId = musicData.Id
		playerBar.Visible = true
		songInfo.Text = musicData.Title
		artistInfo.Text = musicData.Artist .. " • " .. (musicData.Album or "")
		playButton.Text = "❚❚"
	end)

	if isAdmin then
		local DeleteBtn = Instance.new("TextButton")
		DeleteBtn.Size = UDim2.new(0, 40, 0, 40)
		DeleteBtn.Position = UDim2.new(1, -40, 0.5, -20)
		DeleteBtn.BackgroundTransparency = 1
		DeleteBtn.Text = "🗑"
		DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		DeleteBtn.Font = Enum.Font.GothamBold
		DeleteBtn.TextSize = 16
		DeleteBtn.Parent = Card
		
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
		if string.find(string.lower(music.Title), query) or string.find(string.lower(music.Artist), query) then
			CreateMusicCard(music, searchResults, playerBar, songInfo, artistInfo, playButton, isAdmin)
		end
	end
end

-- Crear tarjeta de solicitud (ajustada)
local function CreateRequestCard(req, parent)
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(1, 0, 0, 80)
	Card.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	Card.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Card

	local UserLabel = Instance.new("TextLabel")
	UserLabel.Size = UDim2.new(1, -10, 0, 20)
	UserLabel.Position = UDim2.new(0, 5, 0, 5)
	UserLabel.BackgroundTransparency = 1
	UserLabel.Text = "Usuario: " .. req.User
	UserLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	UserLabel.Font = Enum.Font.GothamBold
	UserLabel.TextSize = 14
	UserLabel.TextXAlignment = Enum.TextXAlignment.Left
	UserLabel.Parent = Card

	local MessageLabel = Instance.new("TextLabel")
	MessageLabel.Size = UDim2.new(1, -10, 0, 40)
	MessageLabel.Position = UDim2.new(0, 5, 0, 25)
	MessageLabel.BackgroundTransparency = 1
	MessageLabel.Text = req.Message
	MessageLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	MessageLabel.Font = Enum.Font.Gotham
	MessageLabel.TextSize = 12
	MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageLabel.TextWrapped = true
	MessageLabel.Parent = Card

	local TimeLabel = Instance.new("TextLabel")
	TimeLabel.Size = UDim2.new(1, -10, 0, 20)
	TimeLabel.Position = UDim2.new(0, 5, 0, 65)
	TimeLabel.BackgroundTransparency = 1
	TimeLabel.Text = "Fecha: " .. os.date("%Y-%m-%d %H:%M", req.Timestamp)
	TimeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
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
local gui, libraryPanel, searchPanel, verifyPanel, adminPanel, playerBar, songInfo, artistInfo, playButton, requestsList = CreateMainGUI()

-- Cargar biblioteca
musicLibrary = RequestMusicList:InvokeServer()
UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
UpdateSearchResults(searchPanel:FindFirstChild("SearchResults"), "")

if isAdmin then
	verificationRequests = RequestVerifyList:InvokeServer() or {}
	UpdateRequests(requestsList)
end

-- Escuchar actualizaciones de música
MusicUpdateEvent.OnClientEvent:Connect(function(action, data)
	if action == "ADD" then
		table.insert(musicLibrary, data)
		UpdateLibrary(libraryPanel, playerBar, songInfo, artistInfo, playButton)
		UpdateSearchResults(searchPanel:FindFirstChild("SearchResults"), searchPanel:FindFirstChild("SearchInput").Text)
		
		if isAdmin then
			-- Notificación
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0, 300, 0, 50)
			notification.AnchorPoint = Vector2.new(0.5, 0)
			notification.Position = UDim2.new(0.5, 0, 0, -50)
			notification.BackgroundColor3 = Color3.fromRGB(46, 125, 50)
			notification.Text = "✓ Música agregada exitosamente"
			notification.TextColor3 = Color3.fromRGB(255, 255, 255)
			notification.Font = Enum.Font.GothamBold
			notification.TextSize = 14
			notification.Parent = gui
			
			local notifCorner = Instance.new("UICorner")
			notifCorner.Parent = notification
			
			local tweenIn = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, 20)})
			tweenIn:Play()
			task.wait(2)
			local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, -50)})
			tweenOut:Play()
			tweenOut.Completed:Wait()
			notification:Destroy()
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
			playerBar.Visible = false
			currentPlayingId = nil
		end
	end
end)

-- Escuchar actualizaciones de verificación (solo admins)
if isAdmin then
	VerifyUpdateEvent.OnClientEvent:Connect(function(action, data)
		if action == "NEW_REQUEST" then
			table.insert(verificationRequests, data)
			UpdateRequests(requestsList)
			
			-- Notificación
			local notification = Instance.new("TextLabel")
			notification.Size = UDim2.new(0, 300, 0, 50)
			notification.AnchorPoint = Vector2.new(0.5, 0)
			notification.Position = UDim2.new(0.5, 0, 0, -50)
			notification.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			notification.Text = "Nueva solicitud de " .. data.User
			notification.TextColor3 = Color3.fromRGB(255, 255, 255)
			notification.Font = Enum.Font.GothamBold
			notification.TextSize = 14
			notification.Parent = gui
			
			local notifCorner = Instance.new("UICorner")
			notifCorner.Parent = notification
			
			local tweenIn = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, 20)})
			tweenIn:Play()
			task.wait(2)
			local tweenOut = TweenService:Create(notification, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, -50)})
			tweenOut:Play()
			tweenOut.Completed:Wait()
			notification:Destroy()
		end
	end)
end

-- Comando para abrir/cerrar GUI
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.M then
		local mainFrame = gui:FindFirstChild("MainFrame")
		if mainFrame then
			mainFrame.Visible = not mainFrame.Visible
			if not mainFrame.Visible and currentSound then
				currentSound:Pause()
			end
		end
	end
end)

print("Amazon Music Cliente - Sistema iniciado")
print("Presiona ‘M’ para abrir/cerrar la interfaz")
print("Es admin:", isAdmin)
