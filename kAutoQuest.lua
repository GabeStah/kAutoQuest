local addon = CreateFrame('Frame')
local DEBUG = false
addon.complete_quests = {}
addon.incomplete_quests = {}

function addon:canAutomate ()
	if IsShiftKeyDown() then
		return false
	else
		return true
	end
end

function addon:strip_text (text)
	if not text then return end
	text = text:gsub('|c%x%x%x%x%x%x%x%x(.-)|r','%1')
	text = text:gsub('%[.*%]%s*','')
	text = text:gsub('(.+) %(.+%)', '%1')
	text = text:trim()
	return text
end

function addon:QUEST_PROGRESS ()
	if not self:canAutomate() then return end
  self:Debug('On QUEST_PROGRESS')
	if IsQuestCompletable() then
		CompleteQuest()
	end
end

function addon:QUEST_LOG_UPDATE ()
	if not self:canAutomate() then return end
  self:Debug('On QUEST_LOG_UPDATE')
	local start_entry = C_QuestLog.GetSelectedQuest()
	local num_entries = C_QuestLog.GetNumQuestLogEntries()
	local title
	local is_complete
	local no_objectives
  local questId

	if num_entries > 0 then
		for i = 1, num_entries do
			C_QuestLog.SetSelectedQuest(i)
			title, _, questId = C_QuestLog.GetInfo(i)
      is_complete = (questId and C_QuestLog.IsComplete(questId)) or false
			no_objectives = GetNumQuestLeaderBoards(i) == 0
		end
	end

	C_QuestLog.SetSelectedQuest(start_entry)
end

function addon:GOSSIP_SHOW ()
	if not self:canAutomate() then return end
  self:Debug('On GOSSIP_SHOW')

  local activeQuests = C_GossipInfo.GetActiveQuests()
  for index, quest in ipairs(activeQuests) do
    if quest.isComplete then
      C_GossipInfo.SelectActiveQuest(quest.questID)
    end
  end

  local options = C_GossipInfo.GetOptions()
  for index, gossipInfo in ipairs(options) do
    if (strfind(gossipInfo.name, "(Quest)")) then
      C_GossipInfo.SelectOption(gossipInfo.gossipOptionID)
    end
  end

  local availableQuests = C_GossipInfo.GetAvailableQuests()
  for index, quest in ipairs(availableQuests) do
    if (not quest.isTrivial) and (not quest.repeatable) then
      C_GossipInfo.SelectAvailableQuest(quest.questID)
    end
  end
end

function addon:QUEST_GREETING (...)
	if not self:canAutomate() then return end
  self:Debug('On QUEST_GREETING')

  for index=1, GetNumActiveQuests() do
		local quest, isComplete = GetActiveTitle(index)
		if isComplete then
			SelectActiveQuest(index)
		end
	end
end

-- function addon:IsAppropriate(name, byCache)
--   local daily
--   if byCache then
--       daily = (not not self.questCache[name])
--   else
--     -- for some reason questInfo in gossip table return data different from one from QuestCache
--     local questID = GetQuestID()
--     local qn = name or (questID and QuestCache:Get(questID).title or "")
--     daily = QuestIsDaily() or QuestIsWeekly() or (not not self.questCache[qn])
--   end

--   return self:_isAppropriate(daily)
-- end

function addon:MarkQuest(id, completed)
  if completed then
    self.complete_quests[id] = true
  else 
    self.incomplete_quests[id] = true
  end
end

function addon:IsQuestComplete(id)
  return self.complete_quests[id]
end

function addon:IsQuestIncomplete(id)
  return self.incomplete_quests[id]
end

function addon:QUEST_DETAIL ()
	if not self:canAutomate() then return end
  self:Debug('On QUEST_DETAIL')
	AcceptQuest()
end

function addon:QUEST_COMPLETE (event)
	if not self:canAutomate() then return end
  self:Debug('On QUEST_COMPLETE')
	if GetNumQuestChoices() <= 1 then
		GetQuestReward(1)
	end
end

function addon.onevent (self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function addon:Debug(...)
  if DEBUG then
    print(...)
  end
end

addon:SetScript('OnEvent', addon.onevent)
addon:RegisterEvent('GOSSIP_SHOW')
addon:RegisterEvent('QUEST_COMPLETE')
addon:RegisterEvent('QUEST_DETAIL')
addon:RegisterEvent('QUEST_FINISHED')
addon:RegisterEvent('QUEST_GREETING')
addon:RegisterEvent('QUEST_LOG_UPDATE')
addon:RegisterEvent('QUEST_PROGRESS')

_G.kAutoQuest = addon

