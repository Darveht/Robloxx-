-- ServerScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- DataStore para guardar las canciones
local MusicDataStore = DataStoreService:GetDataStore("AmazonMusicStore")

-- DataStore para solicitudes de verificación
local VerifyDataStore = DataStoreService:GetDataStore("VerifyRequests")

-- Lista de administradores
local Admins = {
	["Vegetl_t"] = true,
	-- Agrega más admins aquí: ["NombreUsuario"] = true,
}

-- RemoteEvents y RemoteFunctions (Se crean y se adjuntan a ReplicatedStorage)
local RemoteEventsFolder = Instance.new("Folder")
RemoteEventsFolder.Name = "MusicRemotes"
RemoteEventsFolder.Parent = ReplicatedStorage

local RequestMusicList = Instance.new("RemoteFunction")
RequestMusicList.Name = "RequestMusicList"
RequestMusicList.Parent = RemoteEventsFolder

local AddMusicEvent = Instance.new("RemoteEvent")
AddMusicEvent.Name = "AddMusicEvent"
AddMusicEvent.Parent = RemoteEventsFolder

local DeleteMusicEvent = Instance.new("RemoteEvent")
DeleteMusicEvent.Name = "DeleteMusicEvent"
DeleteMusicEvent.Parent = RemoteEventsFolder

local CheckAdminEvent = Instance.new("RemoteFunction")
CheckAdminEvent.Name = "CheckAdminEvent"
CheckAdminEvent.Parent = RemoteEventsFolder

local MusicUpdateEvent = Instance.new("RemoteEvent")
MusicUpdateEvent.Name = "MusicUpdateEvent"
MusicUpdateEvent.Parent = RemoteEventsFolder

local SendVerifyRequest = Instance.new("RemoteEvent")
SendVerifyRequest.Name = "SendVerifyRequest"
SendVerifyRequest.Parent = RemoteEventsFolder

local RequestVerifyList = Instance.new("RemoteFunction")
RequestVerifyList.Name = "RequestVerifyList"
RequestVerifyList.Parent = RemoteEventsFolder

local VerifyUpdateEvent = Instance.new("RemoteEvent")
VerifyUpdateEvent.Name = "VerifyUpdateEvent"
VerifyUpdateEvent.Parent = RemoteEventsFolder

-- Tabla local de canciones (cache)
local MusicLibrary = {}

-- Tabla de solicitudes de verificación
local VerificationRequests = {}

-----

-- FUNCIONES CORE

-- Cargar canciones desde DataStore
local function LoadMusicLibrary()
	local success, data = pcall(function()
		return MusicDataStore:GetAsync("MusicList")
	end)
	
	if success and data then
		MusicLibrary = data
		print("Biblioteca de música cargada:", #MusicLibrary, "canciones")
	else
		MusicLibrary = {}
		print("Iniciando nueva biblioteca de música o error al cargar.")
	end
end

-- Guardar canciones en DataStore
local function SaveMusicLibrary()
	local success, err = pcall(function()
		MusicDataStore:SetAsync("MusicList", MusicLibrary)
	end)
	
	if success then
		print("Biblioteca guardada exitosamente")
	else
		warn("Error al guardar biblioteca:", err)
	end
end

-- Cargar solicitudes de verificación
local function LoadRequests()
	local success, data = pcall(function()
		return VerifyDataStore:GetAsync("Requests")
	end)
	
	if success and data then
		VerificationRequests = data
		print("Solicitudes cargadas:", #VerificationRequests)
	else
		VerificationRequests = {}
		print("Iniciando nuevas solicitudes o error al cargar.")
	end
end

-- Guardar solicitudes de verificación
local function SaveRequests()
	local success, err = pcall(function()
		VerifyDataStore:SetAsync("Requests", VerificationRequests)
	end)
	
	if success then
		print("Solicitudes guardadas exitosamente")
	else
		warn("Error al guardar solicitudes:", err)
	end
end

-- Verificar si un jugador es admin
local function IsAdmin(player)
	return Admins[player.Name] or false
end

-----

-- CONEXIONES DE REMOTES

-- Función para obtener la lista de música
RequestMusicList.OnServerInvoke = function(player)
	return MusicLibrary
end

-- Verificar si es admin
CheckAdminEvent.OnServerInvoke = function(player)
	return IsAdmin(player)
end

-- Obtener lista de solicitudes (solo admins)
RequestVerifyList.OnServerInvoke = function(player)
	if IsAdmin(player) then
		return VerificationRequests
	end
	return {}
end

-- Agregar música (solo admins)
AddMusicEvent.OnServerEvent:Connect(function(player, musicData)
	if not IsAdmin(player) then
		warn(player.Name .. " intentó agregar música sin permisos")
		return
	end
	
	-- Validar datos
	if not musicData.Title or not musicData.Artist or not musicData.SoundId then
		warn("Datos de música inválidos")
		return
	end
	
	-- Crear nuevo registro de música
	local newMusic = {
		Id = #MusicLibrary + 1,
		Title = musicData.Title,
		Artist = musicData.Artist,
		SoundId = tonumber(musicData.SoundId), 
		Duration = musicData.Duration or "3:30",
		Album = musicData.Album or "Single",
		Genre = musicData.Genre or "Pop",
		AddedBy = player.Name,
		Timestamp = os.time()
	}
	
	table.insert(MusicLibrary, newMusic)
	SaveMusicLibrary()
	
	print(player.Name .. " agregó nueva música:", newMusic.Title)
	
	-- Notificar a todos los clientes
	MusicUpdateEvent:FireAllClients("ADD", newMusic)
end)

-- Eliminar música (solo admins)
DeleteMusicEvent.OnServerEvent:Connect(function(player, musicId)
	if not IsAdmin(player) then
		warn(player.Name .. " intentó eliminar música sin permisos")
		return
	end
	
	for i, music in ipairs(MusicLibrary) do
		if music.Id == musicId then
			table.remove(MusicLibrary, i)
			SaveMusicLibrary()
			print(player.Name .. " eliminó música ID:", musicId)
			
			-- Notificar a todos los clientes
			MusicUpdateEvent:FireAllClients("DELETE", musicId)
			break
		end
	end
end)

-- Enviar solicitud de verificación
SendVerifyRequest.OnServerEvent:Connect(function(player, message)
	if not message or message == "" then return end
	
	local req = {
		Id = #VerificationRequests + 1,
		User = player.Name,
		UserId = player.UserId,
		Message = message,
		Timestamp = os.time()
	}
	
	table.insert(VerificationRequests, req)
	SaveRequests()
	
	print(player.Name .. " envió solicitud de verificación")
	
	-- Notificar a admins online
	for _, p in ipairs(Players:GetPlayers()) do
		if IsAdmin(p) then
			VerifyUpdateEvent:FireClient(p, "NEW_REQUEST", req)
		end
	end
end)

-----

-- INICIALIZACIÓN

-- Cargar biblioteca al iniciar
LoadMusicLibrary()
LoadRequests()

-- Auto-guardar cada 5 minutos
task.spawn(function()
	while task.wait(300) do
		SaveMusicLibrary()
		SaveRequests()
	end
end)

local adminNames = {}
for name, _ in pairs(Admins) do
	table.insert(adminNames, name)
end

print("Amazon Music Server - Sistema iniciado")
print("Admins configurados:", table.concat(adminNames, ", "))
