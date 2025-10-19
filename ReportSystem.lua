
-- ReportSystem.lua - Sistema de Reportes y Moderación

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemotesFolder = ReplicatedStorage:WaitForChild("MusicRemotes")
local SendReportEvent = RemotesFolder:WaitForChild("SendReportEvent")
local RequestReportsEvent = RemotesFolder:WaitForChild("RequestReportsEvent")
local ReportUpdateEvent = RemotesFolder:WaitForChild("ReportUpdateEvent")
local UpdateMusicStatusEvent = RemotesFolder:WaitForChild("UpdateMusicStatusEvent")

local ReportSystem = {}
ReportSystem.Reports = {}

-- Crear interfaz de reporte
function ReportSystem.CreateReportUI(parentGui, musicData)
	local ReportFrame = Instance.new("Frame")
	ReportFrame.Name = "ReportFrame"
	ReportFrame.Size = UDim2.new(1, 0, 1, 0)
	ReportFrame.Position = UDim2.new(0, 0, 0, 0)
	ReportFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ReportFrame.BackgroundTransparency = 0.3
	ReportFrame.ZIndex = 100
	ReportFrame.Visible = false
	ReportFrame.Parent = parentGui

	local ReportPanel = Instance.new("Frame")
	ReportPanel.Size = UDim2.new(0, 500, 0, 600)
	ReportPanel.Position = UDim2.new(0.5, -250, 0.5, -300)
	ReportPanel.BackgroundColor3 = Color3.fromRGB(25, 29, 35)
	ReportPanel.ZIndex = 101
	ReportPanel.Parent = ReportFrame

	local PanelCorner = Instance.new("UICorner")
	PanelCorner.CornerRadius = UDim.new(0, 15)
	PanelCorner.Parent = ReportPanel

	-- Título
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -40, 0, 50)
	Title.Position = UDim2.new(0, 20, 0, 20)
	Title.BackgroundTransparency = 1
	Title.Text = "🚨 Reportar Música"
	Title.TextColor3 = Color3.fromRGB(28, 184, 231)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 26
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.ZIndex = 102
	Title.Parent = ReportPanel

	-- Información de la música
	local MusicInfo = Instance.new("TextLabel")
	MusicInfo.Size = UDim2.new(1, -40, 0, 40)
	MusicInfo.Position = UDim2.new(0, 20, 0, 80)
	MusicInfo.BackgroundTransparency = 1
	MusicInfo.Text = "🎵 " .. musicData.Title .. " - " .. musicData.Artist
	MusicInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	MusicInfo.Font = Enum.Font.Gotham
	MusicInfo.TextSize = 16
	MusicInfo.TextXAlignment = Enum.TextXAlignment.Left
	MusicInfo.ZIndex = 102
	MusicInfo.Parent = ReportPanel

	-- Motivos de reporte
	local reasons = {
		"Contenido inapropiado",
		"Infracción de derechos de autor",
		"Spam o contenido engañoso",
		"Violencia o discurso de odio",
		"Contenido sexual explícito",
		"Información incorrecta",
		"Otro motivo"
	}

	local selectedReason = nil
	local reasonButtons = {}

	local ReasonsScroll = Instance.new("ScrollingFrame")
	ReasonsScroll.Size = UDim2.new(1, -40, 0, 280)
	ReasonsScroll.Position = UDim2.new(0, 20, 0, 130)
	ReasonsScroll.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	ReasonsScroll.BorderSizePixel = 0
	ReasonsScroll.ScrollBarThickness = 6
	ReasonsScroll.ScrollBarImageColor3 = Color3.fromRGB(28, 184, 231)
	ReasonsScroll.CanvasSize = UDim2.new(0, 0, 0, #reasons * 55)
	ReasonsScroll.ZIndex = 102
	ReasonsScroll.Parent = ReportPanel

	local ReasonsCorner = Instance.new("UICorner")
	ReasonsCorner.CornerRadius = UDim.new(0, 10)
	ReasonsCorner.Parent = ReasonsScroll

	for i, reason in ipairs(reasons) do
		local ReasonBtn = Instance.new("TextButton")
		ReasonBtn.Size = UDim2.new(1, -20, 0, 45)
		ReasonBtn.Position = UDim2.new(0, 10, 0, (i - 1) * 55 + 5)
		ReasonBtn.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
		ReasonBtn.Text = reason
		ReasonBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		ReasonBtn.Font = Enum.Font.Gotham
		ReasonBtn.TextSize = 15
		ReasonBtn.ZIndex = 103
		ReasonBtn.Parent = ReasonsScroll

		local BtnCorner = Instance.new("UICorner")
		BtnCorner.CornerRadius = UDim.new(0, 8)
		BtnCorner.Parent = ReasonBtn

		table.insert(reasonButtons, ReasonBtn)

		ReasonBtn.MouseButton1Click:Connect(function()
			selectedReason = reason
			for _, btn in ipairs(reasonButtons) do
				btn.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
				btn.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
			ReasonBtn.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
			ReasonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
	end

	-- Descripción adicional
	local DescBox = Instance.new("TextBox")
	DescBox.Size = UDim2.new(1, -40, 0, 80)
	DescBox.Position = UDim2.new(0, 20, 0, 425)
	DescBox.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	DescBox.PlaceholderText = "Descripción adicional (opcional)..."
	DescBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	DescBox.Text = ""
	DescBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	DescBox.Font = Enum.Font.Gotham
	DescBox.TextSize = 14
	DescBox.MultiLine = true
	DescBox.TextWrapped = true
	DescBox.TextXAlignment = Enum.TextXAlignment.Left
	DescBox.TextYAlignment = Enum.TextYAlignment.Top
	DescBox.ZIndex = 102
	DescBox.Parent = ReportPanel

	local DescPadding = Instance.new("UIPadding")
	DescPadding.PaddingLeft = UDim.new(0, 10)
	DescPadding.PaddingRight = UDim.new(0, 10)
	DescPadding.PaddingTop = UDim.new(0, 10)
	DescPadding.Parent = DescBox

	local DescCorner = Instance.new("UICorner")
	DescCorner.CornerRadius = UDim.new(0, 8)
	DescCorner.Parent = DescBox

	-- Botones
	local SendBtn = Instance.new("TextButton")
	SendBtn.Size = UDim2.new(0.48, 0, 0, 50)
	SendBtn.Position = UDim2.new(0, 20, 0, 520)
	SendBtn.BackgroundColor3 = Color3.fromRGB(28, 184, 231)
	SendBtn.Text = "Enviar Reporte"
	SendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	SendBtn.Font = Enum.Font.GothamBold
	SendBtn.TextSize = 16
	SendBtn.ZIndex = 102
	SendBtn.Parent = ReportPanel

	local SendCorner = Instance.new("UICorner")
	SendCorner.CornerRadius = UDim.new(0, 10)
	SendCorner.Parent = SendBtn

	local CancelBtn = Instance.new("TextButton")
	CancelBtn.Size = UDim2.new(0.48, 0, 0, 50)
	CancelBtn.Position = UDim2.new(0.52, 0, 0, 520)
	CancelBtn.BackgroundColor3 = Color3.fromRGB(50, 54, 62)
	CancelBtn.Text = "Cancelar"
	CancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CancelBtn.Font = Enum.Font.GothamBold
	CancelBtn.TextSize = 16
	CancelBtn.ZIndex = 102
	CancelBtn.Parent = ReportPanel

	local CancelCorner = Instance.new("UICorner")
	CancelCorner.CornerRadius = UDim.new(0, 10)
	CancelCorner.Parent = CancelBtn

	-- Eventos
	SendBtn.MouseButton1Click:Connect(function()
		if selectedReason then
			local reportData = {
				MusicId = musicData.Id,
				MusicTitle = musicData.Title,
				MusicArtist = musicData.Artist,
				Reason = selectedReason,
				Description = DescBox.Text
			}
			SendReportEvent:FireServer(reportData)
			ReportFrame.Visible = false
		end
	end)

	CancelBtn.MouseButton1Click:Connect(function()
		ReportFrame.Visible = false
	end)

	return ReportFrame
end

-- Crear tarjeta de reporte para admins
function ReportSystem.CreateReportCard(reportData, parent, onAction)
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(1, 0, 0, 180)
	Card.BackgroundColor3 = Color3.fromRGB(35, 39, 47)
	Card.Parent = parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 12)
	Corner.Parent = Card

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 15)
	Padding.PaddingRight = UDim.new(0, 15)
	Padding.PaddingTop = UDim.new(0, 12)
	Padding.PaddingBottom = UDim.new(0, 12)
	Padding.Parent = Card

	-- Info música reportada
	local MusicTitle = Instance.new("TextLabel")
	MusicTitle.Size = UDim2.new(1, 0, 0, 25)
	MusicTitle.Position = UDim2.new(0, 0, 0, 0)
	MusicTitle.BackgroundTransparency = 1
	MusicTitle.Text = "🎵 " .. reportData.MusicTitle .. " - " .. reportData.MusicArtist
	MusicTitle.TextColor3 = Color3.fromRGB(28, 184, 231)
	MusicTitle.Font = Enum.Font.GothamBold
	MusicTitle.TextSize = 15
	MusicTitle.TextXAlignment = Enum.TextXAlignment.Left
	MusicTitle.Parent = Card

	-- Reportado por
	local Reporter = Instance.new("TextLabel")
	Reporter.Size = UDim2.new(1, 0, 0, 20)
	Reporter.Position = UDim2.new(0, 0, 0, 25)
	Reporter.BackgroundTransparency = 1
	Reporter.Text = "👤 Reportado por: " .. reportData.ReporterName
	Reporter.TextColor3 = Color3.fromRGB(180, 180, 180)
	Reporter.Font = Enum.Font.Gotham
	Reporter.TextSize = 13
	Reporter.TextXAlignment = Enum.TextXAlignment.Left
	Reporter.Parent = Card

	-- Motivo
	local Reason = Instance.new("TextLabel")
	Reason.Size = UDim2.new(1, 0, 0, 20)
	Reason.Position = UDim2.new(0, 0, 0, 45)
	Reason.BackgroundTransparency = 1
	Reason.Text = "⚠️ Motivo: " .. reportData.Reason
	Reason.TextColor3 = Color3.fromRGB(255, 193, 7)
	Reason.Font = Enum.Font.GothamBold
	Reason.TextSize = 14
	Reason.TextXAlignment = Enum.TextXAlignment.Left
	Reason.Parent = Card

	-- Descripción
	if reportData.Description and reportData.Description ~= "" then
		local Desc = Instance.new("TextLabel")
		Desc.Size = UDim2.new(1, 0, 0, 35)
		Desc.Position = UDim2.new(0, 0, 0, 65)
		Desc.BackgroundTransparency = 1
		Desc.Text = "📝 " .. reportData.Description
		Desc.TextColor3 = Color3.fromRGB(200, 200, 200)
		Desc.Font = Enum.Font.Gotham
		Desc.TextSize = 12
		Desc.TextXAlignment = Enum.TextXAlignment.Left
		Desc.TextWrapped = true
		Desc.Parent = Card
	end

	-- Botones de acción
	local DeleteBtn = Instance.new("TextButton")
	DeleteBtn.Size = UDim2.new(0.3, -5, 0, 40)
	DeleteBtn.Position = UDim2.new(0, 0, 1, -45)
	DeleteBtn.BackgroundColor3 = Color3.fromRGB(211, 47, 47)
	DeleteBtn.Text = "🗑 Eliminar"
	DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	DeleteBtn.Font = Enum.Font.GothamBold
	DeleteBtn.TextSize = 13
	DeleteBtn.Parent = Card

	local DeleteCorner = Instance.new("UICorner")
	DeleteCorner.CornerRadius = UDim.new(0, 8)
	DeleteCorner.Parent = DeleteBtn

	local BlockBtn = Instance.new("TextButton")
	BlockBtn.Size = UDim2.new(0.3, -5, 0, 40)
	BlockBtn.Position = UDim2.new(0.33, 0, 1, -45)
	BlockBtn.BackgroundColor3 = Color3.fromRGB(255, 152, 0)
	BlockBtn.Text = "🚫 Bloquear"
	BlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	BlockBtn.Font = Enum.Font.GothamBold
	BlockBtn.TextSize = 13
	BlockBtn.Parent = Card

	local BlockCorner = Instance.new("UICorner")
	BlockCorner.CornerRadius = UDim.new(0, 8)
	BlockCorner.Parent = BlockBtn

	local DismissBtn = Instance.new("TextButton")
	DismissBtn.Size = UDim2.new(0.37, 0, 0, 40)
	DismissBtn.Position = UDim2.new(0.63, 5, 1, -45)
	DismissBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	DismissBtn.Text = "✓ Descartar"
	DismissBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	DismissBtn.Font = Enum.Font.GothamBold
	DismissBtn.TextSize = 13
	DismissBtn.Parent = Card

	local DismissCorner = Instance.new("UICorner")
	DismissCorner.CornerRadius = UDim.new(0, 8)
	DismissCorner.Parent = DismissBtn

	-- Eventos
	DeleteBtn.MouseButton1Click:Connect(function()
		if onAction then
			onAction("delete", reportData)
		end
	end)

	BlockBtn.MouseButton1Click:Connect(function()
		if onAction then
			onAction("block", reportData)
		end
	end)

	DismissBtn.MouseButton1Click:Connect(function()
		if onAction then
			onAction("dismiss", reportData)
		end
	end)

	return Card
end

return ReportSystem
