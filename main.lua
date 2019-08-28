ClassicGuildBank = LibStub("AceAddon-3.0"):NewAddon("ClassicGuildBank", "AceConsole-3.0")

function ClassicGuildBank:OnInitialize()
  ClassicGuildBank:RegisterChatCommand('cgb', 'HandleChatCommand');
end

function ClassicGuildBank:HandleChatCommand(input)
  local bags = ClassicGuildBank:GetBags()
  local bagItems = ClassicGuildBank:GetBagItems()

  local exportString = '[' .. UnitName('player') .. '];'

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

  ClassicGuildBank:DisplayExportString(exportString)

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

      if hasNoValue == false then
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

  local encoded = ClassicGuildBank:enc(exportString);

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

-- bitshift functions (<<, >> equivalent)
-- shift left
function ClassicGuildBank:lsh(value,shift)
	return math.fmod((value*(2^shift)), 256)
end

-- shift right
function ClassicGuildBank:rsh(value,shift)
  return math.fmod(math.floor(value/2^shift), 256)
end

-- return single bit (for OR)
function ClassicGuildBank:bit(x,b)
	return (math.fmod(x, 2^b) - math.fmod(x, 2^(b-1)) > 0)
end

-- logic OR for number values
function ClassicGuildBank:lor(x,y)
	result = 0
	for p=1,8 do result = result + (((ClassicGuildBank:bit(x,p) or ClassicGuildBank:bit(y,p)) == true) and 2^(p-1) or 0) end
	return result
end

-- function encode
-- encodes input string to base64.
function ClassicGuildBank:enc(data)
  -- encryption table
  local base64chars = {[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',[8]='I',[9]='J',[10]='K',[11]='L',[12]='M',[13]='N',[14]='O',[15]='P',[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',[21]='V',[22]='W',[23]='X',[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',[31]='f',[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',[40]='o',[41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',[48]='w',[49]='x',[50]='y',[51]='z',[52]='0',[53]='1',[54]='2',[55]='3',[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',[61]='9',[62]='-',[63]='_'}
  
  local bytes = {}
	local result = ""
  for spos=0,string.len(data)-1,3 do
    for byte=1,3 do bytes[byte] = string.byte(string.sub(data,(spos+byte))) or 0 end
    result = string.format('%s%s%s%s%s',
      result,
      base64chars[ClassicGuildBank:rsh(bytes[1],2)],
      base64chars[ClassicGuildBank:lor(ClassicGuildBank:lsh((math.fmod(bytes[1], 4)),4), ClassicGuildBank:rsh(bytes[2],4))] or "=",
      ((string.len(data)-spos) > 1) and base64chars[ClassicGuildBank:lor(ClassicGuildBank:lsh(
        math.fmod(bytes[2], 16)
      ,2), ClassicGuildBank:rsh(bytes[3],6))] or "=",
      ((string.len(data)-spos) > 2) and base64chars[(math.fmod(bytes[3], 64))] or "="
    )
  end
	return result
end
