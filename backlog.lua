--[[-------------------------------------------------------------------------
  Copyright (c) 2007-2010, Trond A Ekseth
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of Mitsugo nor the names of its contributors
        may be used to endorse or promote products derived from this
        software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]

local print = function(msg, frame) (frame or ChatFrame1):AddMessage("|cff33ff99Mitsugo:|r "..tostring(msg)) end

local flashtab = function(cf)
	local tab = _G[cf:GetName().."TabFlash"]

	if(not cf.isDocked or (cf == SELECTED_DOCK_FRAME) or UIFrameIsFlashing(tab)) then
		return
	end
	tab:Show()
	-- IT WILL FLASH FOREVER!
	-- no it won't!
	FCF_FlashTab(tab)
end

local db
local session
local sessions
local addon = CreateFrame"Frame"

addon.ADDON_LOADED = function(self, event, addon)
	if(addon == "Mitsugo") then
		db = MitsugoDB
		if(not db) then
			db = {
				-- The number of whispers we can output at the start of a new session.
				wlimit = 10,
				-- The number of sessions we should keep whispers for. This has to be 2 or higher.
				slimit = 2,
				sessions = {},
				date = "[%d/%m %H:%M]",
			}
			MitsugoDB = db
		end

		sessions = db.sessions
	end
end

addon.PLAYER_LOGIN = function(self, event)
	session = {}
	table.insert(sessions, 1, session)

	while(#sessions > db.slimit) do
		table.remove(sessions)
	end
end

addon.UPDATE_CHAT_WINDOWS = function(self, event)
	if(sessions[1]) then
		for i=1, NUM_CHAT_WINDOWS do
			local cf = _G["ChatFrame"..i]
			if(cf:IsEventRegistered"CHAT_MSG_WHISPER") then
				local p
				for k, w in ipairs(sessions[1]) do
					local player, msg, date, inform = w:match"^([^\031]+)\031([^\031]+)\031([^\031]+)\031(%d)$"
					player = ("|Hplayer:%s|h[%1$s]|h"):format(player)
					player = (inform == "1" and CHAT_WHISPER_INFORM_GET or CHAT_WHISPER_GET):format(player)
					print(("%s - %s %s"):format(date, player, msg), cf)

					p = true
				end

				if(p) then flashtab(cf) end
			end
		end
	end
end

addon.CHAT_MSG_WHISPER = function(self, event, msg, player)
	table.insert(session, ("%s\031%s\031%s\031%s"):format(player, msg, date(db.date), (event == "CHAT_MSG_WHISPER_INFORM" and 1) or 0))

	while(#session > db.wlimit) do
		table.remove(session, 1)
	end
end
addon.CHAT_MSG_WHISPER_INFORM = addon.CHAT_MSG_WHISPER

addon:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)

addon:RegisterEvent"CHAT_MSG_WHISPER"
addon:RegisterEvent"CHAT_MSG_WHISPER_INFORM"
addon:RegisterEvent"PLAYER_LOGIN"
addon:RegisterEvent"UPDATE_CHAT_WINDOWS"
addon:RegisterEvent"ADDON_LOADED"
