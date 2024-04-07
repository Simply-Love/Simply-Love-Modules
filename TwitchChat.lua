-- Twitch chat module for Simply Love
--
-- Copyright (c) 2022 Martin Natano
--
-- Permission to use, copy, modify, and/or distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
-- SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
-- OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
-- CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-------------------------------------------
-------( Configuration Parameters )--------
-------------------------------------------

local CHANNEL = ""

-- "justinfanNNN" can be used as login name to get anonymous read access to twitch chat.
local NICK = "justinfan" .. tostring(math.floor(MersenneTwister.Random(4096)))
local PASS = CRYPTMAN:GenerateRandomUUID()

local PADDING = 5
local FONT = "Common Normal"
local LINEHEIGHT = 24	-- must match the font metric
local BASELINE = 19	-- must match the font metric
local ZOOM = 0.75
local MAXMESSAGES = 30

local SHOW_BADGES = true
local SHOW_EMOTES = true

-------------------------------------------
----( End of configuration parameters )----
-------------------------------------------

local BADGES = {
	artist="🖌",
	broadcaster="🎥",
	moderator="🗡",
	no_audio="🔇",
	no_video="👁",
	subscriber="💃",
	vip="💎",
}

local EMOTES = {
	-- ADD YOUR OWN EMOTES HERE

	-- SL specific emotes
	Crab="🦀",
	Snowman="⛄",
	Hug="🤗",
	Thonk="🤔",
	Wave="🌊",
	Burger="🍔",
	Baguette="🥖",
	Strong="💪",
	Lips="👄",
	Rainbow="🌈",
	Copter="🚁",
	Candle="🕯",
	Tulip="🌷",
	Sweat="💦",
	Tower="🗼",
	RedHeart="❤",
	YellowHeart="💛",
	GreenHeart="💚",
	BlueHeart="💙",
	PurpleHeart="💜",
	BlackHeart="🖤",
	Airplane="✈",
	Star="⭐",
	Quad="🌟🌟🌟🌟",
	Tada="🎉",

	-- global twitch emotes
	[":("]="🙁",
	[":-("]="🙁",
	[":)"]="🙂",
	[":-)"]="🙂",
	[":/"]="😕",
	[":\\"]="😕",
	[":-/"]="😕",
	[":-\\"]="😕",
	[":|"]="😐",
	[":-|"]="😐",
	[";)"]="😉",
	[";-)"]="😉",
	[">("]="😠",
	["<3"]="💜",
	["8-)"]="😎",
	["B)"]="😎",
	["B-)"]="😎",
	[":-D"]="😀",
	[":D"]="😀",
	[":-o"]="😮",
	[":o"]="😮",
	[":-O"]="😮",
	[":O"]="😮",
	["o.o"]="👀",
	["o.O"]="👀",
	["O.o"]="👀",
	["O.O"]="👀",
	["o_o"]="👀",
	["o_O"]="👀",
	["O_o"]="👀",
	["O_O"]="👀",
	[":p"]="😛",
	[":P"]="😛",
	[":-p"]="😛",
	[":-P"]="😛",
	[";p"]="😜",
	[";P"]="😜",
	[";-p"]="😜",
	[";-P"]="😜",
	[":-z"]="😑",
	[":z"]="😑",
	[":-Z"]="😑",
	[":Z"]="😑",
	HolidayPresent="🎁",
	HolidayTree="🎄",
	HolidaySanta="🎅",
	PopCorn="🍿",
}


local messages = {}
local activeActor = nil
local ws = nil

local function redraw()
	if activeActor then
		activeActor:queuecommand("RedrawText")
	end
end

local function addMessage(msg)
	messages[#messages+1] = msg
	if #messages > MAXMESSAGES then
		table.remove(messages, 1)
	end
	redraw()
end

local function clearAllMessages()
	messages = {}
	addMessage({
		type="status",
		text="Chat was cleared by a moderator",
	})
	redraw()
end

local function clearMessagesByUser(target)
	for idx, msg in ipairs(messages) do
		if msg.type == "privmsg" and msg.tags["user-id"] == target then
			messages[idx] = {
				type="status",
				text="message deleted by a moderator.",
			}
		end
	end
	redraw()
end

local function clearMessageById(target)
	for idx, msg in ipairs(messages) do
		if msg.type == "privmsg" and msg.tags["id"] == target then
			messages[idx] = {
				type="status",
				text="message deleted by a moderator.",
			}
		end
	end
	redraw()
end

local function parseMessage(s)
	if s:sub(1, 5) == "PING " then
		local text = s:sub(6):gsub("[\r\n]*$", "")
		ws:Send("PONG " .. text)
		return
	end


	local _, _, tagsStr, sender, command, paramsStr = string.find(s, "^@([^ ]+) :([^! ]+)!?[^ ]* ([^ ]+) ?(.-)\r\n$")
	if tagsStr == nil or sender == nil or command == nil or paramsStr == nil then
		return
	end

	local tags = {}
	for key, value in string.gmatch(tagsStr, "([^;=]+)=([^;]*)") do
		if value ~= "" then
			tags[key] = value:gsub("\\s", " ")
		end
	end

	if command == "PRIVMSG" then
		local _, _, text = string.find(paramsStr, "^#[^ ]+ :?(.*)$")
		if text == nil then
			return
		end

		if SHOW_EMOTES then
			text = text:gsub("[%w_-<>:;()|/\\]+", EMOTES)
		end

		addMessage({
			type="privmsg",
			sender=sender,
			text=text,
			tags=tags,
		})
	elseif command == "CLEARCHAT" then
		local target = tags["target-user-id"]
		if target then
			clearMessagesByUser(target)
		else
			clearAllMessages()
		end
	elseif command == "CLEARMSG" then
		local target = tags["target-msg-id"]
		clearMessageById(target)
	elseif command == "USERNOTICE" then
		if tags["system-msg"] then
			addMessage({
				type="status",
				text=tags["system-msg"],
				msgId=tags["msg-id"],
			})
		end

		local _, _, text = string.find(paramsStr, "^#[^ ]+ :?(.*)$")
		if text then
			addMessage({
				type="privmsg",
				sender=sender,
				text=text,
				tags=tags,
			})
		end
	end
end

local function colorForSender(s)
	-- djb2 hash
	local hash = 5381
	for i = 1, #s do
		local c = string.byte(s, i)
		hash = (hash * 33 + c) % 4294967296
	end

	return color(SL.Colors[hash % #SL.Colors + 1])
end

ws = NETWORK:WebSocket{
	url="wss://irc-ws.chat.twitch.tv/",
	pingInterval=60,
	automaticReconnect=true,
	onMessage=function(msg)
		local msgType = ToEnumShortString(msg.type)
		if msgType == "Open" then
			addMessage({
				type="status",
				text="Welcome to the chat room!",
			})

			ws:Send("CAP REQ :twitch.tv/commands twitch.tv/tags")
			ws:Send("PASS " .. PASS)
			ws:Send("NICK " .. NICK)
			ws:Send("JOIN #" .. CHANNEL)
		elseif msgType == "Close" then
			addMessage({
				type="status",
				text="Disconnected",
			})
		elseif msgType == "Error" then
			addMessage({
				type="error",
				text=msg.reason,
			})
		elseif msgType == "Message" then
			parseMessage(msg.data)
		end

	end,
}


local function ChatActor(params)
	local function calculateGeometry(width, height)
		local textWidth = width - PADDING*2
		local textHeight = height - PADDING*2
		local maxLines = math.floor(textHeight / LINEHEIGHT / ZOOM)
		local extraYPadding = (textHeight - maxLines*LINEHEIGHT*ZOOM) / 2

		return {
			width=width,
			height=height,
			textWidth=textWidth,
			textHeight=textHeight,
			maxLines=maxLines,
			extraYPadding=extraYPadding,
		}
	end

	local geometry = calculateGeometry(params.width, params.height)

	return Def.ActorFrame{
		ModuleCommand=function(self)
			activeActor = self
			self:playcommand("SetGeometry")
			self:queuecommand("Resize")
			self:queuecommand("RedrawText")
		end,

		InitCommand=function(self)
			self:xy(params.x, params.y)
			self:SetSize(params.width, params.height)
		end,

		SetGeometryCommand=params.SetGeometryCommand,

		ResizeCommand=function(self)
			geometry = calculateGeometry(self:GetWidth(), self:GetHeight())
		end,

		Def.Quad{
			InitCommand=function(self)
				self:align(0, 0)
				self:diffuse(color("#000000bb"))
			end,
			ResizeCommand=function(self)
				self:zoomto(geometry.width, geometry.height)
			end,
		},

		LoadFont(FONT)..{
			Text="",
			InitCommand=function(self)
				self:align(0, 1)
				self:diffuse(color("#ffffff"))
				self:zoom(ZOOM)
			end,
			ResizeCommand=function(self)
				self:xy(PADDING, PADDING + geometry.textHeight - geometry.extraYPadding - (LINEHEIGHT - BASELINE)*ZOOM)
				self:wrapwidthpixels(geometry.textWidth / ZOOM)
			end,
			RedrawTextCommand=function(self)
				local window

				if #messages <= geometry.maxLines then
					window = {unpack(messages)}
				else
					window = {unpack(messages, #messages - geometry.maxLines + 1, #messages)}
				end

				while #window > 0 do
					local text = ""
					local attributes = {}

					for idx, msg in ipairs(window) do
						if idx > 1 then
							text = text .. "\n"
						end
						local position = text:utf8len()

						if msg.type == "privmsg" then
							local displayName = msg.tags["display-name"]
							if not displayName or displayName == "" then
								displayName = msg.sender
							end

							local displayColor
							if msg.tags.color then
								displayColor = color(msg.tags.color)
							else
								displayColor = colorForSender(msg.sender)
							end

							local badges = ""
							if msg.tags["msg-id"] == "announcement" then
								badges = badges .. "📣"
							end
							if SHOW_BADGES then
								for name in string.gmatch(msg.tags.badges or "", "([^,/]+)/[^,/]+") do
									if BADGES[name] then
										badges = badges .. BADGES[name]
									end
								end
							end

							if badges == "" then
								text = text .. displayName .. ": " .. msg.text
							else
								text = text .. badges .. " " .. displayName .. ": " .. msg.text
								position = position + badges:utf8len() + 1
							end

							attributes[#attributes+1] = {
								position=position,
								data={
									Length=displayName:utf8len(),
									Diffuse=displayColor,
								},
							}
						elseif msg.type == "status" then
							if msg.msgId == "subgift" or msg.msgId == "submysterygift" then
								text = text .. "🎁 "
								position = position + 2
							elseif msg.msgId == "sub" or msg.msgId == "resub" then
								text = text .. "🎉 "
								position = position + 2
							end

							text = text .. msg.text
							attributes[#attributes+1] = {
								position=position,
								data={
									Length=msg.text:utf8len(),
									Diffuse=color("#aaaaaa"),
								},
							}
						elseif msg.type == "error" then
							text = text .. msg.text
							attributes[#attributes+1] = {
								position=position,
								data={
									Length=msg.text:utf8len(),
									Diffuse=color("#ff0000"),
								},
							}
						end
					end

					self:settext(text)
					for attr in ivalues(attributes) do
						self:AddAttribute(attr.position, attr.data)
					end

					if self:GetHeight() <= geometry.textHeight / ZOOM then
						break
					else
						table.remove(window, 1)
						self:settext("")
						-- try again
					end
				end
			end,
		},
	}
end


local t = {}

t.ScreenTitleMenu = ChatActor{
	x=_screen.cx + 160,
	y=20,
	width=_screen.w/2 - 180,
	height=_screen.h - 54,
}
t.ScreenOptionsService = ChatActor{
	x=10,
	y=_screen.h - 72,
	width=_screen.w - 20,
	height=64,
}
t.ScreenSystemOptions = t.ScreenOptionsService
t.ScreenInputOptions = t.ScreenOptionsService
t.ScreenGraphicsSoundOptions = t.ScreenOptionsService
t.ScreenVisualOptions = t.ScreenOptionsService
t.ScreenAdvancedOptions = t.ScreenOptionsService
t.ScreenMenuTimerOptions = t.ScreenOptionsService
t.ScreenUSBProfileOptions = t.ScreenOptionsService
t.ScreenOptionsManageProfiles = t.ScreenOptionsService
t.ScreenThemeOptions = t.ScreenOptionsService
t.ScreenGrooveStatsOptions = t.ScreenOptionsService

t.ScreenTestInput = ChatActor{
	x=10,
	y=_screen.h - 110,
	width=_screen.w - 20,
	height=100,
}

t.ScreenSelectProfile = ChatActor{
	x=10,
	y=40,
	width=_screen.w - 20,
	height=82,
}
t.ScreenSelectColor = t.ScreenSelectProfile
t.ScreenSelectStyle = t.ScreenSelectProfile
t.ScreenSelectPlayMode = t.ScreenSelectProfile
t.ScreenSelectPlayMode2 = t.ScreenSelectProfile

t.ScreenSelectMusic = ChatActor{
	-- set in SetGeometryCommand
	x=0,
	y=0,
	width=100,
	height=100,

	SetGeometryCommand=function(self)
		if IsUsingWideScreen() then
			self:xy(_screen.cx - 330, 33)
			self:SetSize(320, 126)
		else
			self:xy(_screen.cx - 323, 34)
			self:SetSize(314, 124)
		end
	end
}

t.ScreenGameplay = ChatActor{
	-- set in SetGeometryCommand
	x=0,
	y=0,
	width=100,
	height=100,

	SetGeometryCommand=function(self)
		local p1Joined = GAMESTATE:IsSideJoined("PlayerNumber_P1")
		local p2Joined = GAMESTATE:IsSideJoined("PlayerNumber_P2")

		if p1Joined and p2Joined then
			self:visible(false)
		elseif p1Joined then
			local mods = SL.P1.ActiveModifiers
			local noteFieldIsCentered = (GetNotefieldX("PlayerNumber_P1") == _screen.cx)

			if noteFieldIsCentered then
				local width = (_screen.w - GetNotefieldWidth()) / 2 - 20
				local x = _screen.w - width - 10
				if mods.DataVisualizations ~= "None" or ThemePrefs.Get("EnableTournamentMode") then
					x = 10
				end
				self:xy(x, 90)
				self:SetSize(width, _screen.h - 100)
			else
				if mods.DataVisualizations == "Step Statistics" then
					self:xy(_screen.cx + 105, _screen.cy + 10)
					self:SetSize(_screen.w/2 - 105, 105)
				elseif mods.DataVisualizations == "None" then
					self:xy(_screen.cx + 50, 90)
					self:SetSize(_screen.w/2 - 60, _screen.h - 100)
				else
					self:visible(false)
				end
			end
		elseif p2Joined then
			local mods = SL.P2.ActiveModifiers
			local noteFieldIsCentered = (GetNotefieldX("PlayerNumber_P2") == _screen.cx)

			if noteFieldIsCentered then
				local width = (_screen.w - GetNotefieldWidth()) / 2 - 20
				local x = 10
				if mods.DataVisualizations ~= "None" or ThemePrefs.Get("EnableTournamentMode") then
					x = _screen.w - width - 10
				end
				self:xy(x, 90)
				self:SetSize(width, _screen.h - 100)
			else
				if mods.DataVisualizations == "Step Statistics" then
					self:xy(0, _screen.cy + 10)
					self:SetSize(_screen.w/2 - 105, 105)
				elseif mods.DataVisualizations == "None" then
					self:xy(10, 90)
					self:SetSize(_screen.w/2 - 60, _screen.h - 100)
				else
					self:visible(false)
				end
			end
		end
	end,
}

t.ScreenEvaluationStage = ChatActor{
	-- set in SetGeometryCommand
	x=0,
	y=0,
	width=100,
	height=100,

	SetGeometryCommand=function(self)
		local p1Joined = GAMESTATE:IsSideJoined("PlayerNumber_P1")
		local p2Joined = GAMESTATE:IsSideJoined("PlayerNumber_P2")

		if p1Joined and p2Joined then
			self:visible(false)
		elseif p1Joined then
			self:xy(_screen.cx + 156, 38)
			self:SetSize(_screen.w/2 - 166, 143)
		elseif p2Joined then
			self:xy(10, 38)
			self:SetSize(_screen.w/2 - 166, 143)
		end
	end
}
t.ScreenEvaluationNonstop = t.ScreenEvaluationStage

t.ScreenEvaluationSummary = ChatActor{
	-- set in SetGeometryCommand
	x=0,
	y=0,
	width=100,
	height=100,

	SetGeometryCommand=function(self)
		local p1Joined = GAMESTATE:IsSideJoined("PlayerNumber_P1")
		local p2Joined = GAMESTATE:IsSideJoined("PlayerNumber_P2")

		if p1Joined and p2Joined then
			self:visible(false)
		elseif p1Joined then
			self:xy(_screen.cx + 80, 42)
			self:SetSize(_screen.w/2 - 90, _screen.h - 52)
		elseif p2Joined then
			self:xy(10, 42)
			self:SetSize(_screen.w/2 - 90, _screen.h - 52)
		end
	end
}

t.ScreenNameEntryTraditional = ChatActor{
	-- set in SetGeometryCommand
	x=0,
	y=0,
	width=100,
	height=100,

	SetGeometryCommand=function(self)
		local p1Joined = GAMESTATE:IsSideJoined("PlayerNumber_P1")
		local p2Joined = GAMESTATE:IsSideJoined("PlayerNumber_P2")

		if p1Joined and p2Joined then
			self:visible(false)
		elseif p1Joined then
			self:xy(_screen.cx + 10, _screen.cy - 20 - _screen.h/14)
			self:SetSize(_screen.w/2 - 20, _screen.h/2 + _screen.h/14 + 10)
		elseif p2Joined then
			self:xy(10, _screen.cy - 20 - _screen.h/14)
			self:SetSize(_screen.w/2 - 20, _screen.h/2 + _screen.h/14 + 10)
		end
	end
}

return t
