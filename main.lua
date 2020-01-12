ClassicGuildBank = LibStub("AceAddon-3.0"):NewAddon("ClassicGuildBank", "AceConsole-3.0", "AceEvent-3.0")

local defaults = {
  char = {
      deposits = {},
      history = {}
  },
}

function ClassicGuildBank:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("ClassicGuildBankDb", defaults)

  ClassicGuildBank:RegisterChatCommand('cgb', 'HandleChatCommand');
  ClassicGuildBank:RegisterChatCommand('cgb-deposit', 'HandleDepositCommand')
  ClassicGuildBank:RegisterChatCommand('cgb-history', 'HandleHistoryCommand')

  ClassicGuildBank:InitializeInboxButton();
  ClassicGuildBank:RegisterEvent('MAIL_SHOW');

end

function ClassicGuildBank:HandleChatCommand(input)  

  local bags = ClassicGuildBank:GetBags()
  local bagItems = ClassicGuildBank:GetBagItems()

  local exportString = '[' .. UnitName('player') .. ',' .. GetMoney() .. ',' .. GetLocale() .. '];'

  exportString = exportString .. '['

  for i=1, #bags do
    if i > 1 then
      exportString = exportString .. ','
    end

    exportString = exportString .. bags[i].container .. ',' 

    if bags[i].bagName == nil == false then
      exportString = exportString .. bags[i].bagName
    end
  end

  exportString = exportString .. '];'

  for i=1, #bagItems do
      exportString = exportString .. '[' .. bagItems[i].container .. ',' .. bagItems[i].slot .. ',' .. bagItems[i].itemID .. ',' .. bagItems[i].count .. '];'
  end

  local deposits = self.db.char.deposits 
  if #deposits > 0 then
    exportString  = exportString .. '[DEPOSITS]'
    for j=1, #deposits do
      local sender = deposits[j].sender;

      if sender == nil then
        sender = 'Unkown Sender'
      end

      exportString = exportString .. '[' .. sender .. ',' .. deposits[j].itemId .. ',' .. deposits[j].quantity .. ',' .. deposits[j].money .. '];'
    end

    tinsert(self.db.char.history, 1, { date=date(), deposits=self.db.char.deposits});
    self.db.char.deposits = {}
  end
  ClassicGuildBank:DisplayExportString(exportString)

end

function ClassicGuildBank:HandleDepositCommand(input)
  local args = {}
  for s in string.gmatch(input, "%S+") do
    args[#args+1] = s
  end

  if #args == 0 then
    local deposits = self.db.char.deposits
    ClassicGuildBank:Print( #deposits .. ' item deposits waiting to be exported.  These will be included the next time you run the /cgb command.')
    return
  elseif #args == 1 then
    local arg = args[1]

    if arg == '-h' or arg == '-help' then
      ClassicGuildBank:Print('Classic Guild Bank Deposit Help:')
      ClassicGuildBank:Print('No argument    -- Lists out the number of deposits awaiting export')
      ClassicGuildBank:Print('-v or -verbose -- Lists out the deposits awaiting export including item name and sender')
      ClassicGuildBank:Print('-clear         -- Removes all deposits waiting to be exported')
      return
    end

    if arg == '-v' or arg == '-verbose' then
      local deposits = self.db.char.deposits
      for i=1, #deposits do
        local dep = deposits[i]

        if dep.itemId == -1 then
          ClassicGuildBank:Print( dep.sender .. ' Deposited - ' .. GetCoinText(dep.money, ",") )
        else 
          local itemName, itemLink = GetItemInfo(dep.itemId)
          ClassicGuildBank:Print( dep.sender .. ' Deposited - ' .. dep.quantity .. ' ' .. itemLink )
        end

      end
      return
    end

    if arg == '-clear' then
      self.db.char.deposits = {}
      ClassicGuildBank:Print('Deposits Cleared');
      return
    end

  end

end

function ClassicGuildBank:HandleHistoryCommand(input)
  local args = {}
  for s in string.gmatch(input, "%S+") do
    args[#args+1] = s
  end

  local history = self.db.char.history
  if #args == 0 then
    ClassicGuildBank:Print( #history .. ' deposit history entries. typing /cgb-history -[number: 1, 2, 3] will display detailed information about that entry.')
    return

  elseif #args == 1 then
    local numArg = tonumber(args[1])
    if numArg == nil then
      ClassicGuildBank:Print('/cgb-history requires its first argument to be a number.')
      return
    end

    local histNum = math.abs(numArg)
    
    if histNum > #history then
      ClassicGuildBank:Print( 'Argument: ' .. args[1] .. ' is larger than the bounds of the history table.')
      return
    end
    
    local entry = history[histNum];
    
    ClassicGuildBank:Print( 'Entry was added on: ' .. entry.date .. '\n Entry contains ' .. #entry.deposits .. 'Deposits \n Re run this command with the -load argument to load them to be exported.' )
  elseif #args == 2 and args[2] == '-load' then

    local numArg = tonumber(args[1])
    if numArg == nil then
      ClassicGuildBank:Print('/cgb-history requires its first argument to be a number')
      return
    end

    local histNum = math.abs(numArg)
    
    if histNum > #history then
      ClassicGuildBank:Print( 'Argument: ' .. args[1] .. ' is larger than the bounds of the history table')
      return
    end
    
    local entry = history[histNum];
    ClassicGuildBank:Print( #entry.deposits .. ' Deposits have been added to the deposits awaiting export. Run /cgb to export these deposits' )

    for i=1, #entry.deposits do
      local deposits = self.db.char.deposits
      deposits[#deposits + 1] = entry.deposits[i]
    end

    
  elseif #args == 2 and args[2] == '-clear' then
    local histNum = math.abs(tonumber(args[1]))
    
    if histNum > #history then
      ClassicGuildBank:Print( 'Argument: ' .. args[1] .. ' is larger than the bounds of the history table')
      return
    end
    
    local entry = history[histNum];
    ClassicGuildBank:Print( 'History entry from ' .. entry.date .. ' with ' .. #entry.deposits .. ' deposits has been deleted.')
    tremove(history, histNum)
  end
  
end

function ClassicGuildBank:MAIL_SHOW()
  ClassicGuildBank:GetDeposits()
end

function ClassicGuildBank:GetBags()
  local bags = {}

  for container = -1, 12 do
    bags[#bags + 1] = {
      container = container,
      bagName = GetBagName(container)
    }
  end

  return bags;
end

function ClassicGuildBank:GetBagItems()
  local bagItems = {}

  for container = -1, 12 do
    local numSlots = GetContainerNumSlots(container)

    for slot=1, numSlots do
      local texture, count, locked, quality, readable, lootable, link, isFiltered, hasNoValue, itemID = GetContainerItemInfo(container, slot)

      if itemID then
        bagItems[#bagItems + 1] = {                    
          container = container,
          slot = slot,
          itemID = itemID,
          count = count
        }
      end
    end
  end

  return bagItems
end

function ClassicGuildBank:DisplayExportString(exportString)

  local encoded = ClassicGuildBank:encode(exportString);
  
  CgbFrame:Show();
  CgbFrameScroll:Show()
  CgbFrameScrollText:Show()
  CgbFrameScrollText:SetText(encoded)
  CgbFrameScrollText:HighlightText()
  
  CgbFrameButton:SetScript("OnClick", function(self)
    CgbFrame:Hide();
    end
  );
end

local extract = _G.bit32 and _G.bit32.extract
if not extract then
	if _G.bit then
		local shl, shr, band = _G.bit.lshift, _G.bit.rshift, _G.bit.band
		extract = function( v, from, width )
			return band( shr( v, from ), shl( 1, width ) - 1 )
		end
	elseif _G._VERSION >= "Lua 5.3" then
		extract = load[[return function( v, from, width )
			return ( v >> from ) & ((1 << width) - 1)
		end]]()
	else
		extract = function( v, from, width )
			local w = 0
			local flag = 2^from
			for i = 0, width-1 do
				local flag2 = flag + flag
				if v % flag2 >= flag then
					w = w + 2^i
				end
				flag = flag2
			end
			return w
		end
	end
end

local char, concat = string.char, table.concat

function ClassicGuildBank:makeencoder( s62, s63, spad )
	local encoder = {}
	for b64code, char in pairs{[0]='A','B','C','D','E','F','G','H','I','J',
		'K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y',
		'Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n',
		'o','p','q','r','s','t','u','v','w','x','y','z','0','1','2',
		'3','4','5','6','7','8','9',s62 or '+',s63 or'/',spad or'='} do
		encoder[b64code] = char:byte()
	end
	return encoder
end

function ClassicGuildBank:encode( str )
	encoder = ClassicGuildBank:makeencoder()
	local t, k, n = {}, 1, #str
	local lastn = n % 3
	for i = 1, n-lastn, 3 do
		local a, b, c = str:byte( i, i+2 )
		local v = a*0x10000 + b*0x100 + c

		t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[extract(v,0,6)])
		k = k + 1
	end
	if lastn == 2 then
		local a, b = str:byte( n-1, n )
		local v = a*0x10000 + b*0x100
		t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[64])
	elseif lastn == 1 then
		local v = str:byte( n )*0x10000
		t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[64], encoder[64])
	end
	return concat( t )
end

function ClassicGuildBank:InitializeInboxButton()
  local btn = CreateFrame('Button', nil, InboxFrame, 'UIPanelButtonTemplate')
  btn:SetPoint('BOTTOM', -10, 460)
  btn:SetText('CGB Send Deposit')
  btn:SetWidth(130)
	btn:SetHeight(25)
  btn:SetScript('OnClick', function()
    ClassicGuildBank:SendDeposit()
  end)
  btn:SetScript('OnEvent', function(__, event)
    if (event == "PLAYER_LOGIN" and CT_MailMod and CT_MailMod.requestAddOnConflictResolution) then
      -- asks CT_MailMod to make some room so the button can fit.
      CT_MailMod:requestAddOnConflictResolution("ClassicGuildBank", 1, btn)
    end
  end)
  btn:RegisterEvent("PLAYER_LOGIN");
end

function ClassicGuildBank:SendDeposit()
  MailFrameTab_OnClick(self, 2);

  local uid = string.sub(ClassicGuildBank:CreateGuid(), 1, 8);

  local subject = 'CGBDeposit: ' .. uid;

  SendMailSubjectEditBox:SetText(subject);
end

function ClassicGuildBank:CreateGuid()
  local random = math.random;
  local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

  return string.gsub(template, '[xy]', function (c)
      local v = (c == 'x') and random(0, 0xf) or random(8, 0xb);
      return string.format('%x', v);
  end);
end


function ClassicGuildBank:GetDeposits()

  C_Timer.NewTimer(1, function()
    
    local numMail = GetInboxNumItems()
    local numMessages = 0
    local numItems = 0

    if numMail > 0 then    
      for mail=1, numMail do
        local _, _, sender, subject, money, COD, _, hasItem, wasRead, _, _, _, GM = GetInboxHeaderInfo(mail)
      
        local isCGBDeposit = subject:sub(1, #'CGBDeposit: ') == 'CGBDeposit: '
  
        if isCGBDeposit then
          local uid = subject:sub(12, 20);
  
          if ClassicGuildBank:IsNewDeposit(uid) then
            numMessages = numMessages + 1
  
            if money > 0 then 
              ClassicGuildBank:TrackDeposit(sender, -1, -1, money, uid)
            end

            for item=1, ATTACHMENTS_MAX_RECEIVE do
              local itemName, itemId, _, count, _, _ = GetInboxItem(mail, item)
              if itemName then 
                numItems = numItems + 1
                ClassicGuildBank:TrackDeposit(sender, itemId, count, 0, uid)
              end
            end
          end
        end
      end
    
      if numItems > 0 then 
        ClassicGuildBank:Print('Recorded ' .. numItems .. ' item deposits in ' .. numMessages .. ' messages from guild members.')
        ClassicGuildBank:Print('These deposits will be exported the next time you run the /cgb command.')
      else
        ClassicGuildBank:Print('No new deposits were found.')
      end
    end
  end)
end

function ClassicGuildBank:IsNewDeposit(uid)
  local returnValue = true;

  local deposits = self.db.char.deposits
  for i=1, #deposits do
    local dep = deposits[i]

    if dep.uid == uid then
      returnValue = false
    end
  end

  local history = self.db.char.history
  for i=1, #history do
    local historyDeposits = history[i].deposits

    for j=1, #historyDeposits do
      local historyDeposit = historyDeposits[j]

      if historyDeposit.uid == uid then
        returnValue = false
      end
    end
  end

  return returnValue;
end

function ClassicGuildBank:TrackDeposit(sender, itemId, quantity, money, uid)
  local index = #self.db.char.deposits + 1

  self.db.char.deposits[index] = {
    sender = sender,
    itemId = itemId,
    quantity = quantity,
    money = money,
    uid = uid
  }
end
