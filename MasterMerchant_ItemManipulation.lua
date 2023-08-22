local ItemChangeData

function MasterMerchant.NewLink(itemLink, movement)
  local subType, level = zo_strmatch(itemLink, '|H.-:item:.-:(%d-):(%d-):')
  subType = tonumber(subType)
  level = tonumber(level)

  local newValue = { NewSubtype = nil, NewLevel = nil }
  if ItemChangeData[subType] and ItemChangeData[subType][level] then
    newValue = ItemChangeData[subType][level][movement]
  end

  if newValue.NewSubtype == nil then
    return nil
  else
    return zo_strgsub(zo_strgsub(itemLink, '(|H.-:item:.-:)(%d-)(:.-)', '%1' .. newValue.NewSubtype .. '%3', 1),
      '(|H.-:item:.-:.-:)(%d-)(:.-)', '%1' .. newValue.NewLevel .. '%3', 1)
  end
end

function MasterMerchant.ItemCodeText(itemLink)
  return zo_strgsub(zo_strgsub(itemLink, '|H', '--'), '|h', ':h')
end

function MasterMerchant.LevelUp(itemLink)
  return MasterMerchant.NewLink(itemLink, 'LevelUp')
end

function MasterMerchant.LevelDown(itemLink)
  return MasterMerchant.NewLink(itemLink, 'LevelDown')
end

function MasterMerchant.QualityUp(itemLink)
  return MasterMerchant.NewLink(itemLink, 'QualityUp')
end

function MasterMerchant.QualityDown(itemLink)
  return MasterMerchant.NewLink(itemLink, 'QualityDown')
end

function MasterMerchant.Up(itemLink)
  local up = MasterMerchant.QualityUp(itemLink)
  if not up then
    up = MasterMerchant.LevelUp(itemLink)
    if up then
      local down = MasterMerchant.QualityDown(up)
      while down do
        up = down
        down = MasterMerchant.QualityDown(up)
      end
    end
  end
  return up
end

function MasterMerchant.Down(itemLink)
  local down = MasterMerchant.QualityDown(itemLink)
  if not down then
    down = MasterMerchant.LevelDown(itemLink)
    if down then
      local up = MasterMerchant.QualityUp(down)
      while up do
        down = up
        up = MasterMerchant.QualityUp(down)
      end
    end
  end
  return down
end

--[[
|H0:item:11008:39:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h green v1  less armor than standard
|H0:item:11008:40:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h green v2  less armor than standard
|H0:item:11008:41:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h green v3  less armor than standard
|H0:item:11008:42:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h green v4  less armor than standard

|H0:item:11008:43:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h green v5  less armor than standard
|H0:item:11008:85:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h blue v5

|H0:item:10927:44:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h v6
|H0:item:10927:45:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h v7
|H0:item:10927:46:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h v8
|H0:item:10927:47:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h v9
|H0:item:10927:48:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h v10

|H0:item:10927:49:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h blue 50
|H0:item:10927:50:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h blue 50 less armor
|H0:item:10927:51:50:0:0:0:0:0:0:0:0:0:0:0:0:7:0:0:0:10000:0|h|h green v1
]]

ItemChangeData = {
  ["Sample - Subtype: 30"] = {
    ["Sample - Level: 40"] = {
      LevelUp = { NewSubtype = 111, NewLevel = 111 },
      LevelDown = { NewSubtype = 111, NewLevel = 111 },
      QualityUp = { NewSubtype = 111, NewLevel = 111 },
      QualityDown = { NewSubtype = 111, NewLevel = 111 }
    }
  },
  [51] = { [50] = { LevelUp = { NewSubtype = 52, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 61, NewLevel = 50 }, QualityDown = { NewSubtype = 111, NewLevel = 50 } } },

  [52] = { [50] = { LevelUp = { NewSubtype = 53, NewLevel = 50 }, LevelDown = { NewSubtype = 51, NewLevel = 50 }, QualityUp = { NewSubtype = 62, NewLevel = 50 }, QualityDown = { NewSubtype = 112, NewLevel = 50 } } },

  [53] = { [50] = { LevelUp = { NewSubtype = 54, NewLevel = 50 }, LevelDown = { NewSubtype = 52, NewLevel = 50 }, QualityUp = { NewSubtype = 63, NewLevel = 50 }, QualityDown = { NewSubtype = 113, NewLevel = 50 } } },

  [54] = { [50] = { LevelUp = { NewSubtype = 55, NewLevel = 50 }, LevelDown = { NewSubtype = 53, NewLevel = 50 }, QualityUp = { NewSubtype = 64, NewLevel = 50 }, QualityDown = { NewSubtype = 114, NewLevel = 50 } } },

  [55] = { [50] = { LevelUp = { NewSubtype = 56, NewLevel = 50 }, LevelDown = { NewSubtype = 54, NewLevel = 50 }, QualityUp = { NewSubtype = 65, NewLevel = 50 }, QualityDown = { NewSubtype = 115, NewLevel = 50 } } },

  [56] = { [50] = { LevelUp = { NewSubtype = 57, NewLevel = 50 }, LevelDown = { NewSubtype = 55, NewLevel = 50 }, QualityUp = { NewSubtype = 66, NewLevel = 50 }, QualityDown = { NewSubtype = 116, NewLevel = 50 } } },

  [57] = { [50] = { LevelUp = { NewSubtype = 58, NewLevel = 50 }, LevelDown = { NewSubtype = 56, NewLevel = 50 }, QualityUp = { NewSubtype = 67, NewLevel = 50 }, QualityDown = { NewSubtype = 117, NewLevel = 50 } } },

  [58] = { [50] = { LevelUp = { NewSubtype = 59, NewLevel = 50 }, LevelDown = { NewSubtype = 57, NewLevel = 50 }, QualityUp = { NewSubtype = 68, NewLevel = 50 }, QualityDown = { NewSubtype = 118, NewLevel = 50 } } },

  [59] = { [50] = { LevelUp = { NewSubtype = 60, NewLevel = 50 }, LevelDown = { NewSubtype = 58, NewLevel = 50 }, QualityUp = { NewSubtype = 69, NewLevel = 50 }, QualityDown = { NewSubtype = 119, NewLevel = 50 } } },

  [60] = { [50] = { LevelUp = { NewSubtype = 229, NewLevel = 50 }, LevelDown = { NewSubtype = 59, NewLevel = 50 }, QualityUp = { NewSubtype = 70, NewLevel = 50 }, QualityDown = { NewSubtype = 120, NewLevel = 50 } } },

  [61] = { [50] = { LevelUp = { NewSubtype = 62, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 71, NewLevel = 50 }, QualityDown = { NewSubtype = 51, NewLevel = 50 } } },

  [62] = { [50] = { LevelUp = { NewSubtype = 63, NewLevel = 50 }, LevelDown = { NewSubtype = 61, NewLevel = 50 }, QualityUp = { NewSubtype = 72, NewLevel = 50 }, QualityDown = { NewSubtype = 52, NewLevel = 50 } } },

  [63] = { [50] = { LevelUp = { NewSubtype = 64, NewLevel = 50 }, LevelDown = { NewSubtype = 62, NewLevel = 50 }, QualityUp = { NewSubtype = 73, NewLevel = 50 }, QualityDown = { NewSubtype = 53, NewLevel = 50 } } },

  [64] = { [50] = { LevelUp = { NewSubtype = 65, NewLevel = 50 }, LevelDown = { NewSubtype = 63, NewLevel = 50 }, QualityUp = { NewSubtype = 74, NewLevel = 50 }, QualityDown = { NewSubtype = 54, NewLevel = 50 } } },

  [65] = { [50] = { LevelUp = { NewSubtype = 66, NewLevel = 50 }, LevelDown = { NewSubtype = 64, NewLevel = 50 }, QualityUp = { NewSubtype = 75, NewLevel = 50 }, QualityDown = { NewSubtype = 55, NewLevel = 50 } } },

  [66] = { [50] = { LevelUp = { NewSubtype = 67, NewLevel = 50 }, LevelDown = { NewSubtype = 65, NewLevel = 50 }, QualityUp = { NewSubtype = 76, NewLevel = 50 }, QualityDown = { NewSubtype = 56, NewLevel = 50 } } },

  [67] = { [50] = { LevelUp = { NewSubtype = 68, NewLevel = 50 }, LevelDown = { NewSubtype = 66, NewLevel = 50 }, QualityUp = { NewSubtype = 77, NewLevel = 50 }, QualityDown = { NewSubtype = 57, NewLevel = 50 } } },

  [68] = { [50] = { LevelUp = { NewSubtype = 69, NewLevel = 50 }, LevelDown = { NewSubtype = 67, NewLevel = 50 }, QualityUp = { NewSubtype = 78, NewLevel = 50 }, QualityDown = { NewSubtype = 58, NewLevel = 50 } } },

  [69] = { [50] = { LevelUp = { NewSubtype = 70, NewLevel = 50 }, LevelDown = { NewSubtype = 68, NewLevel = 50 }, QualityUp = { NewSubtype = 79, NewLevel = 50 }, QualityDown = { NewSubtype = 59, NewLevel = 50 } } },

  [70] = { [50] = { LevelUp = { NewSubtype = 232, NewLevel = 50 }, LevelDown = { NewSubtype = 69, NewLevel = 50 }, QualityUp = { NewSubtype = 80, NewLevel = 50 }, QualityDown = { NewSubtype = 60, NewLevel = 50 } } },

  [71] = { [50] = { LevelUp = { NewSubtype = 72, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 101, NewLevel = 50 }, QualityDown = { NewSubtype = 61, NewLevel = 50 } } },

  [72] = { [50] = { LevelUp = { NewSubtype = 73, NewLevel = 50 }, LevelDown = { NewSubtype = 71, NewLevel = 50 }, QualityUp = { NewSubtype = 102, NewLevel = 50 }, QualityDown = { NewSubtype = 62, NewLevel = 50 } } },

  [73] = { [50] = { LevelUp = { NewSubtype = 74, NewLevel = 50 }, LevelDown = { NewSubtype = 72, NewLevel = 50 }, QualityUp = { NewSubtype = 103, NewLevel = 50 }, QualityDown = { NewSubtype = 63, NewLevel = 50 } } },

  [74] = { [50] = { LevelUp = { NewSubtype = 75, NewLevel = 50 }, LevelDown = { NewSubtype = 73, NewLevel = 50 }, QualityUp = { NewSubtype = 104, NewLevel = 50 }, QualityDown = { NewSubtype = 64, NewLevel = 50 } } },

  [75] = { [50] = { LevelUp = { NewSubtype = 76, NewLevel = 50 }, LevelDown = { NewSubtype = 74, NewLevel = 50 }, QualityUp = { NewSubtype = 105, NewLevel = 50 }, QualityDown = { NewSubtype = 65, NewLevel = 50 } } },

  [76] = { [50] = { LevelUp = { NewSubtype = 77, NewLevel = 50 }, LevelDown = { NewSubtype = 75, NewLevel = 50 }, QualityUp = { NewSubtype = 106, NewLevel = 50 }, QualityDown = { NewSubtype = 66, NewLevel = 50 } } },

  [77] = { [50] = { LevelUp = { NewSubtype = 78, NewLevel = 50 }, LevelDown = { NewSubtype = 76, NewLevel = 50 }, QualityUp = { NewSubtype = 107, NewLevel = 50 }, QualityDown = { NewSubtype = 67, NewLevel = 50 } } },

  [78] = { [50] = { LevelUp = { NewSubtype = 79, NewLevel = 50 }, LevelDown = { NewSubtype = 77, NewLevel = 50 }, QualityUp = { NewSubtype = 108, NewLevel = 50 }, QualityDown = { NewSubtype = 68, NewLevel = 50 } } },

  [79] = { [50] = { LevelUp = { NewSubtype = 80, NewLevel = 50 }, LevelDown = { NewSubtype = 78, NewLevel = 50 }, QualityUp = { NewSubtype = 109, NewLevel = 50 }, QualityDown = { NewSubtype = 69, NewLevel = 50 } } },

  [80] = { [50] = { LevelUp = { NewSubtype = 233, NewLevel = 50 }, LevelDown = { NewSubtype = 79, NewLevel = 50 }, QualityUp = { NewSubtype = 110, NewLevel = 50 }, QualityDown = { NewSubtype = 70, NewLevel = 50 } } },

  [81] = { [50] = { LevelUp = { NewSubtype = 62, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 71, NewLevel = 50 }, QualityDown = { NewSubtype = 51, NewLevel = 50 } } },

  [82] = { [50] = { LevelUp = { NewSubtype = 63, NewLevel = 50 }, LevelDown = { NewSubtype = 61, NewLevel = 50 }, QualityUp = { NewSubtype = 72, NewLevel = 50 }, QualityDown = { NewSubtype = 52, NewLevel = 50 } } },

  [83] = { [50] = { LevelUp = { NewSubtype = 64, NewLevel = 50 }, LevelDown = { NewSubtype = 62, NewLevel = 50 }, QualityUp = { NewSubtype = 73, NewLevel = 50 }, QualityDown = { NewSubtype = 53, NewLevel = 50 } } },

  [84] = { [50] = { LevelUp = { NewSubtype = 65, NewLevel = 50 }, LevelDown = { NewSubtype = 63, NewLevel = 50 }, QualityUp = { NewSubtype = 74, NewLevel = 50 }, QualityDown = { NewSubtype = 54, NewLevel = 50 } } },

  [85] = { [50] = { LevelUp = { NewSubtype = 66, NewLevel = 50 }, LevelDown = { NewSubtype = 64, NewLevel = 50 }, QualityUp = { NewSubtype = 75, NewLevel = 50 }, QualityDown = { NewSubtype = 55, NewLevel = 50 } } },

  [86] = { [50] = { LevelUp = { NewSubtype = 67, NewLevel = 50 }, LevelDown = { NewSubtype = 65, NewLevel = 50 }, QualityUp = { NewSubtype = 76, NewLevel = 50 }, QualityDown = { NewSubtype = 56, NewLevel = 50 } } },

  [87] = { [50] = { LevelUp = { NewSubtype = 68, NewLevel = 50 }, LevelDown = { NewSubtype = 66, NewLevel = 50 }, QualityUp = { NewSubtype = 77, NewLevel = 50 }, QualityDown = { NewSubtype = 57, NewLevel = 50 } } },

  [88] = { [50] = { LevelUp = { NewSubtype = 69, NewLevel = 50 }, LevelDown = { NewSubtype = 67, NewLevel = 50 }, QualityUp = { NewSubtype = 78, NewLevel = 50 }, QualityDown = { NewSubtype = 58, NewLevel = 50 } } },

  [89] = { [50] = { LevelUp = { NewSubtype = 70, NewLevel = 50 }, LevelDown = { NewSubtype = 68, NewLevel = 50 }, QualityUp = { NewSubtype = 79, NewLevel = 50 }, QualityDown = { NewSubtype = 59, NewLevel = 50 } } },

  [90] = { [50] = { LevelUp = { NewSubtype = 232, NewLevel = 50 }, LevelDown = { NewSubtype = 69, NewLevel = 50 }, QualityUp = { NewSubtype = 80, NewLevel = 50 }, QualityDown = { NewSubtype = 60, NewLevel = 50 } } },

  [91] = { [50] = { LevelUp = { NewSubtype = 62, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 71, NewLevel = 50 }, QualityDown = { NewSubtype = 51, NewLevel = 50 } } },

  [92] = { [50] = { LevelUp = { NewSubtype = 63, NewLevel = 50 }, LevelDown = { NewSubtype = 61, NewLevel = 50 }, QualityUp = { NewSubtype = 72, NewLevel = 50 }, QualityDown = { NewSubtype = 52, NewLevel = 50 } } },

  [93] = { [50] = { LevelUp = { NewSubtype = 64, NewLevel = 50 }, LevelDown = { NewSubtype = 62, NewLevel = 50 }, QualityUp = { NewSubtype = 73, NewLevel = 50 }, QualityDown = { NewSubtype = 53, NewLevel = 50 } } },

  [94] = { [50] = { LevelUp = { NewSubtype = 65, NewLevel = 50 }, LevelDown = { NewSubtype = 63, NewLevel = 50 }, QualityUp = { NewSubtype = 74, NewLevel = 50 }, QualityDown = { NewSubtype = 54, NewLevel = 50 } } },

  [95] = { [50] = { LevelUp = { NewSubtype = 66, NewLevel = 50 }, LevelDown = { NewSubtype = 64, NewLevel = 50 }, QualityUp = { NewSubtype = 75, NewLevel = 50 }, QualityDown = { NewSubtype = 55, NewLevel = 50 } } },

  [96] = { [50] = { LevelUp = { NewSubtype = 67, NewLevel = 50 }, LevelDown = { NewSubtype = 65, NewLevel = 50 }, QualityUp = { NewSubtype = 76, NewLevel = 50 }, QualityDown = { NewSubtype = 56, NewLevel = 50 } } },

  [97] = { [50] = { LevelUp = { NewSubtype = 68, NewLevel = 50 }, LevelDown = { NewSubtype = 66, NewLevel = 50 }, QualityUp = { NewSubtype = 77, NewLevel = 50 }, QualityDown = { NewSubtype = 57, NewLevel = 50 } } },

  [98] = { [50] = { LevelUp = { NewSubtype = 69, NewLevel = 50 }, LevelDown = { NewSubtype = 67, NewLevel = 50 }, QualityUp = { NewSubtype = 78, NewLevel = 50 }, QualityDown = { NewSubtype = 58, NewLevel = 50 } } },

  [99] = { [50] = { LevelUp = { NewSubtype = 70, NewLevel = 50 }, LevelDown = { NewSubtype = 68, NewLevel = 50 }, QualityUp = { NewSubtype = 79, NewLevel = 50 }, QualityDown = { NewSubtype = 59, NewLevel = 50 } } },

  [100] = { [50] = { LevelUp = { NewSubtype = 232, NewLevel = 50 }, LevelDown = { NewSubtype = 69, NewLevel = 50 }, QualityUp = { NewSubtype = 80, NewLevel = 50 }, QualityDown = { NewSubtype = 60, NewLevel = 50 } } },

  [101] = { [50] = { LevelUp = { NewSubtype = 102, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 71, NewLevel = 50 } } },

  [102] = { [50] = { LevelUp = { NewSubtype = 103, NewLevel = 50 }, LevelDown = { NewSubtype = 101, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 72, NewLevel = 50 } } },

  [103] = { [50] = { LevelUp = { NewSubtype = 104, NewLevel = 50 }, LevelDown = { NewSubtype = 102, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 73, NewLevel = 50 } } },

  [104] = { [50] = { LevelUp = { NewSubtype = 105, NewLevel = 50 }, LevelDown = { NewSubtype = 103, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 74, NewLevel = 50 } } },

  [105] = { [50] = { LevelUp = { NewSubtype = 106, NewLevel = 50 }, LevelDown = { NewSubtype = 104, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 75, NewLevel = 50 } } },

  [106] = { [50] = { LevelUp = { NewSubtype = 107, NewLevel = 50 }, LevelDown = { NewSubtype = 105, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 76, NewLevel = 50 } } },

  [107] = { [50] = { LevelUp = { NewSubtype = 108, NewLevel = 50 }, LevelDown = { NewSubtype = 106, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 77, NewLevel = 50 } } },

  [108] = { [50] = { LevelUp = { NewSubtype = 109, NewLevel = 50 }, LevelDown = { NewSubtype = 107, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 78, NewLevel = 50 } } },

  [109] = { [50] = { LevelUp = { NewSubtype = 110, NewLevel = 50 }, LevelDown = { NewSubtype = 108, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 79, NewLevel = 50 } } },

  [110] = { [50] = { LevelUp = { NewSubtype = 234, NewLevel = 50 }, LevelDown = { NewSubtype = 109, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 80, NewLevel = 50 } } },

  [111] = { [50] = { LevelUp = { NewSubtype = 112, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 51, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [112] = { [50] = { LevelUp = { NewSubtype = 113, NewLevel = 50 }, LevelDown = { NewSubtype = 111, NewLevel = 50 }, QualityUp = { NewSubtype = 52, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [113] = { [50] = { LevelUp = { NewSubtype = 114, NewLevel = 50 }, LevelDown = { NewSubtype = 112, NewLevel = 50 }, QualityUp = { NewSubtype = 53, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [114] = { [50] = { LevelUp = { NewSubtype = 115, NewLevel = 50 }, LevelDown = { NewSubtype = 113, NewLevel = 50 }, QualityUp = { NewSubtype = 54, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [115] = { [50] = { LevelUp = { NewSubtype = 116, NewLevel = 50 }, LevelDown = { NewSubtype = 114, NewLevel = 50 }, QualityUp = { NewSubtype = 55, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [116] = { [50] = { LevelUp = { NewSubtype = 117, NewLevel = 50 }, LevelDown = { NewSubtype = 115, NewLevel = 50 }, QualityUp = { NewSubtype = 56, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [117] = { [50] = { LevelUp = { NewSubtype = 118, NewLevel = 50 }, LevelDown = { NewSubtype = 116, NewLevel = 50 }, QualityUp = { NewSubtype = 57, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [118] = { [50] = { LevelUp = { NewSubtype = 119, NewLevel = 50 }, LevelDown = { NewSubtype = 117, NewLevel = 50 }, QualityUp = { NewSubtype = 58, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [119] = { [50] = { LevelUp = { NewSubtype = 120, NewLevel = 50 }, LevelDown = { NewSubtype = 118, NewLevel = 50 }, QualityUp = { NewSubtype = 59, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [120] = { [50] = { LevelUp = { NewSubtype = 235, NewLevel = 50 }, LevelDown = { NewSubtype = 119, NewLevel = 50 }, QualityUp = { NewSubtype = 60, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [125] = { [50] = { LevelUp = { NewSubtype = 126, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 135, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [126] = { [50] = { LevelUp = { NewSubtype = 127, NewLevel = 50 }, LevelDown = { NewSubtype = 125, NewLevel = 50 }, QualityUp = { NewSubtype = 136, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [127] = { [50] = { LevelUp = { NewSubtype = 128, NewLevel = 50 }, LevelDown = { NewSubtype = 126, NewLevel = 50 }, QualityUp = { NewSubtype = 137, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [128] = { [50] = { LevelUp = { NewSubtype = 129, NewLevel = 50 }, LevelDown = { NewSubtype = 127, NewLevel = 50 }, QualityUp = { NewSubtype = 138, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [129] = { [50] = { LevelUp = { NewSubtype = 130, NewLevel = 50 }, LevelDown = { NewSubtype = 128, NewLevel = 50 }, QualityUp = { NewSubtype = 139, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [130] = { [50] = { LevelUp = { NewSubtype = 131, NewLevel = 50 }, LevelDown = { NewSubtype = 129, NewLevel = 50 }, QualityUp = { NewSubtype = 140, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [131] = { [50] = { LevelUp = { NewSubtype = 132, NewLevel = 50 }, LevelDown = { NewSubtype = 130, NewLevel = 50 }, QualityUp = { NewSubtype = 141, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [132] = { [50] = { LevelUp = { NewSubtype = 133, NewLevel = 50 }, LevelDown = { NewSubtype = 131, NewLevel = 50 }, QualityUp = { NewSubtype = 142, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [133] = { [50] = { LevelUp = { NewSubtype = 134, NewLevel = 50 }, LevelDown = { NewSubtype = 132, NewLevel = 50 }, QualityUp = { NewSubtype = 143, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [134] = { [50] = { LevelUp = { NewSubtype = 236, NewLevel = 50 }, LevelDown = { NewSubtype = 133, NewLevel = 50 }, QualityUp = { NewSubtype = 144, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [135] = { [50] = { LevelUp = { NewSubtype = 136, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 145, NewLevel = 50 }, QualityDown = { NewSubtype = 125, NewLevel = 50 } } },

  [136] = { [50] = { LevelUp = { NewSubtype = 137, NewLevel = 50 }, LevelDown = { NewSubtype = 135, NewLevel = 50 }, QualityUp = { NewSubtype = 146, NewLevel = 50 }, QualityDown = { NewSubtype = 126, NewLevel = 50 } } },

  [137] = { [50] = { LevelUp = { NewSubtype = 138, NewLevel = 50 }, LevelDown = { NewSubtype = 136, NewLevel = 50 }, QualityUp = { NewSubtype = 147, NewLevel = 50 }, QualityDown = { NewSubtype = 127, NewLevel = 50 } } },

  [138] = { [50] = { LevelUp = { NewSubtype = 139, NewLevel = 50 }, LevelDown = { NewSubtype = 137, NewLevel = 50 }, QualityUp = { NewSubtype = 148, NewLevel = 50 }, QualityDown = { NewSubtype = 128, NewLevel = 50 } } },

  [139] = { [50] = { LevelUp = { NewSubtype = 140, NewLevel = 50 }, LevelDown = { NewSubtype = 138, NewLevel = 50 }, QualityUp = { NewSubtype = 149, NewLevel = 50 }, QualityDown = { NewSubtype = 129, NewLevel = 50 } } },

  [140] = { [50] = { LevelUp = { NewSubtype = 141, NewLevel = 50 }, LevelDown = { NewSubtype = 139, NewLevel = 50 }, QualityUp = { NewSubtype = 150, NewLevel = 50 }, QualityDown = { NewSubtype = 130, NewLevel = 50 } } },

  [141] = { [50] = { LevelUp = { NewSubtype = 142, NewLevel = 50 }, LevelDown = { NewSubtype = 140, NewLevel = 50 }, QualityUp = { NewSubtype = 151, NewLevel = 50 }, QualityDown = { NewSubtype = 131, NewLevel = 50 } } },

  [142] = { [50] = { LevelUp = { NewSubtype = 143, NewLevel = 50 }, LevelDown = { NewSubtype = 141, NewLevel = 50 }, QualityUp = { NewSubtype = 152, NewLevel = 50 }, QualityDown = { NewSubtype = 132, NewLevel = 50 } } },

  [143] = { [50] = { LevelUp = { NewSubtype = 144, NewLevel = 50 }, LevelDown = { NewSubtype = 142, NewLevel = 50 }, QualityUp = { NewSubtype = 153, NewLevel = 50 }, QualityDown = { NewSubtype = 133, NewLevel = 50 } } },

  [144] = { [50] = { LevelUp = { NewSubtype = 237, NewLevel = 50 }, LevelDown = { NewSubtype = 143, NewLevel = 50 }, QualityUp = { NewSubtype = 154, NewLevel = 50 }, QualityDown = { NewSubtype = 134, NewLevel = 50 } } },

  [145] = { [50] = { LevelUp = { NewSubtype = 146, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 155, NewLevel = 50 }, QualityDown = { NewSubtype = 135, NewLevel = 50 } } },

  [146] = { [50] = { LevelUp = { NewSubtype = 147, NewLevel = 50 }, LevelDown = { NewSubtype = 145, NewLevel = 50 }, QualityUp = { NewSubtype = 156, NewLevel = 50 }, QualityDown = { NewSubtype = 136, NewLevel = 50 } } },

  [147] = { [50] = { LevelUp = { NewSubtype = 148, NewLevel = 50 }, LevelDown = { NewSubtype = 146, NewLevel = 50 }, QualityUp = { NewSubtype = 157, NewLevel = 50 }, QualityDown = { NewSubtype = 137, NewLevel = 50 } } },

  [148] = { [50] = { LevelUp = { NewSubtype = 149, NewLevel = 50 }, LevelDown = { NewSubtype = 147, NewLevel = 50 }, QualityUp = { NewSubtype = 158, NewLevel = 50 }, QualityDown = { NewSubtype = 138, NewLevel = 50 } } },

  [149] = { [50] = { LevelUp = { NewSubtype = 150, NewLevel = 50 }, LevelDown = { NewSubtype = 148, NewLevel = 50 }, QualityUp = { NewSubtype = 159, NewLevel = 50 }, QualityDown = { NewSubtype = 139, NewLevel = 50 } } },

  [150] = { [50] = { LevelUp = { NewSubtype = 151, NewLevel = 50 }, LevelDown = { NewSubtype = 149, NewLevel = 50 }, QualityUp = { NewSubtype = 160, NewLevel = 50 }, QualityDown = { NewSubtype = 140, NewLevel = 50 } } },

  [151] = { [50] = { LevelUp = { NewSubtype = 152, NewLevel = 50 }, LevelDown = { NewSubtype = 150, NewLevel = 50 }, QualityUp = { NewSubtype = 161, NewLevel = 50 }, QualityDown = { NewSubtype = 141, NewLevel = 50 } } },

  [152] = { [50] = { LevelUp = { NewSubtype = 153, NewLevel = 50 }, LevelDown = { NewSubtype = 151, NewLevel = 50 }, QualityUp = { NewSubtype = 162, NewLevel = 50 }, QualityDown = { NewSubtype = 142, NewLevel = 50 } } },

  [153] = { [50] = { LevelUp = { NewSubtype = 154, NewLevel = 50 }, LevelDown = { NewSubtype = 152, NewLevel = 50 }, QualityUp = { NewSubtype = 163, NewLevel = 50 }, QualityDown = { NewSubtype = 143, NewLevel = 50 } } },

  [154] = { [50] = { LevelUp = { NewSubtype = 238, NewLevel = 50 }, LevelDown = { NewSubtype = 153, NewLevel = 50 }, QualityUp = { NewSubtype = 164, NewLevel = 50 }, QualityDown = { NewSubtype = 144, NewLevel = 50 } } },

  [155] = { [50] = { LevelUp = { NewSubtype = 156, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = 165, NewLevel = 50 }, QualityDown = { NewSubtype = 145, NewLevel = 50 } } },

  [156] = { [50] = { LevelUp = { NewSubtype = 157, NewLevel = 50 }, LevelDown = { NewSubtype = 155, NewLevel = 50 }, QualityUp = { NewSubtype = 166, NewLevel = 50 }, QualityDown = { NewSubtype = 146, NewLevel = 50 } } },

  [157] = { [50] = { LevelUp = { NewSubtype = 158, NewLevel = 50 }, LevelDown = { NewSubtype = 156, NewLevel = 50 }, QualityUp = { NewSubtype = 167, NewLevel = 50 }, QualityDown = { NewSubtype = 147, NewLevel = 50 } } },

  [158] = { [50] = { LevelUp = { NewSubtype = 159, NewLevel = 50 }, LevelDown = { NewSubtype = 157, NewLevel = 50 }, QualityUp = { NewSubtype = 168, NewLevel = 50 }, QualityDown = { NewSubtype = 148, NewLevel = 50 } } },

  [159] = { [50] = { LevelUp = { NewSubtype = 160, NewLevel = 50 }, LevelDown = { NewSubtype = 158, NewLevel = 50 }, QualityUp = { NewSubtype = 169, NewLevel = 50 }, QualityDown = { NewSubtype = 149, NewLevel = 50 } } },

  [160] = { [50] = { LevelUp = { NewSubtype = 161, NewLevel = 50 }, LevelDown = { NewSubtype = 159, NewLevel = 50 }, QualityUp = { NewSubtype = 170, NewLevel = 50 }, QualityDown = { NewSubtype = 150, NewLevel = 50 } } },

  [161] = { [50] = { LevelUp = { NewSubtype = 162, NewLevel = 50 }, LevelDown = { NewSubtype = 160, NewLevel = 50 }, QualityUp = { NewSubtype = 171, NewLevel = 50 }, QualityDown = { NewSubtype = 151, NewLevel = 50 } } },

  [162] = { [50] = { LevelUp = { NewSubtype = 163, NewLevel = 50 }, LevelDown = { NewSubtype = 161, NewLevel = 50 }, QualityUp = { NewSubtype = 172, NewLevel = 50 }, QualityDown = { NewSubtype = 152, NewLevel = 50 } } },

  [163] = { [50] = { LevelUp = { NewSubtype = 164, NewLevel = 50 }, LevelDown = { NewSubtype = 162, NewLevel = 50 }, QualityUp = { NewSubtype = 173, NewLevel = 50 }, QualityDown = { NewSubtype = 153, NewLevel = 50 } } },

  [164] = { [50] = { LevelUp = { NewSubtype = 239, NewLevel = 50 }, LevelDown = { NewSubtype = 163, NewLevel = 50 }, QualityUp = { NewSubtype = 174, NewLevel = 50 }, QualityDown = { NewSubtype = 154, NewLevel = 50 } } },

  [165] = { [50] = { LevelUp = { NewSubtype = 166, NewLevel = 50 }, LevelDown = { NewSubtype = nil, NewLevel = nil }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 155, NewLevel = 50 } } },

  [166] = { [50] = { LevelUp = { NewSubtype = 167, NewLevel = 50 }, LevelDown = { NewSubtype = 165, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 156, NewLevel = 50 } } },

  [167] = { [50] = { LevelUp = { NewSubtype = 168, NewLevel = 50 }, LevelDown = { NewSubtype = 166, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 157, NewLevel = 50 } } },

  [168] = { [50] = { LevelUp = { NewSubtype = 169, NewLevel = 50 }, LevelDown = { NewSubtype = 167, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 158, NewLevel = 50 } } },

  [169] = { [50] = { LevelUp = { NewSubtype = 170, NewLevel = 50 }, LevelDown = { NewSubtype = 168, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 159, NewLevel = 50 } } },

  [170] = { [50] = { LevelUp = { NewSubtype = 171, NewLevel = 50 }, LevelDown = { NewSubtype = 169, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 160, NewLevel = 50 } } },

  [171] = { [50] = { LevelUp = { NewSubtype = 172, NewLevel = 50 }, LevelDown = { NewSubtype = 170, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 161, NewLevel = 50 } } },

  [172] = { [50] = { LevelUp = { NewSubtype = 173, NewLevel = 50 }, LevelDown = { NewSubtype = 171, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 162, NewLevel = 50 } } },

  [173] = { [50] = { LevelUp = { NewSubtype = 174, NewLevel = 50 }, LevelDown = { NewSubtype = 172, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 163, NewLevel = 50 } } },

  [174] = { [50] = { LevelUp = { NewSubtype = 240, NewLevel = 50 }, LevelDown = { NewSubtype = 173, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 164, NewLevel = 50 } } },

  [229] = { [50] = { LevelUp = { NewSubtype = 247, NewLevel = 50 }, LevelDown = { NewSubtype = 60, NewLevel = 50 }, QualityUp = { NewSubtype = 232, NewLevel = 50 }, QualityDown = { NewSubtype = 235, NewLevel = 50 } } },

  [232] = { [50] = { LevelUp = { NewSubtype = 250, NewLevel = 50 }, LevelDown = { NewSubtype = 70, NewLevel = 50 }, QualityUp = { NewSubtype = 233, NewLevel = 50 }, QualityDown = { NewSubtype = 229, NewLevel = 50 } } },

  [233] = { [50] = { LevelUp = { NewSubtype = 251, NewLevel = 50 }, LevelDown = { NewSubtype = 80, NewLevel = 50 }, QualityUp = { NewSubtype = 234, NewLevel = 50 }, QualityDown = { NewSubtype = 232, NewLevel = 50 } } },

  [234] = { [50] = { LevelUp = { NewSubtype = 252, NewLevel = 50 }, LevelDown = { NewSubtype = 110, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 233, NewLevel = 50 } } },

  [235] = { [50] = { LevelUp = { NewSubtype = 253, NewLevel = 50 }, LevelDown = { NewSubtype = 120, NewLevel = 50 }, QualityUp = { NewSubtype = 229, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [236] = { [50] = { LevelUp = { NewSubtype = 254, NewLevel = 50 }, LevelDown = { NewSubtype = 134, NewLevel = 50 }, QualityUp = { NewSubtype = 237, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [237] = { [50] = { LevelUp = { NewSubtype = 255, NewLevel = 50 }, LevelDown = { NewSubtype = 144, NewLevel = 50 }, QualityUp = { NewSubtype = 238, NewLevel = 50 }, QualityDown = { NewSubtype = 236, NewLevel = 50 } } },

  [238] = { [50] = { LevelUp = { NewSubtype = 256, NewLevel = 50 }, LevelDown = { NewSubtype = 154, NewLevel = 50 }, QualityUp = { NewSubtype = 239, NewLevel = 50 }, QualityDown = { NewSubtype = 237, NewLevel = 50 } } },

  [239] = { [50] = { LevelUp = { NewSubtype = 257, NewLevel = 50 }, LevelDown = { NewSubtype = 164, NewLevel = 50 }, QualityUp = { NewSubtype = 240, NewLevel = 50 }, QualityDown = { NewSubtype = 238, NewLevel = 50 } } },

  [240] = { [50] = { LevelUp = { NewSubtype = 258, NewLevel = 50 }, LevelDown = { NewSubtype = 174, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 239, NewLevel = 50 } } },

  [247] = { [50] = { LevelUp = { NewSubtype = 265, NewLevel = 50 }, LevelDown = { NewSubtype = 229, NewLevel = 50 }, QualityUp = { NewSubtype = 250, NewLevel = 50 }, QualityDown = { NewSubtype = 253, NewLevel = 50 } } },

  [250] = { [50] = { LevelUp = { NewSubtype = 268, NewLevel = 50 }, LevelDown = { NewSubtype = 232, NewLevel = 50 }, QualityUp = { NewSubtype = 251, NewLevel = 50 }, QualityDown = { NewSubtype = 247, NewLevel = 50 } } },

  [251] = { [50] = { LevelUp = { NewSubtype = 269, NewLevel = 50 }, LevelDown = { NewSubtype = 233, NewLevel = 50 }, QualityUp = { NewSubtype = 252, NewLevel = 50 }, QualityDown = { NewSubtype = 250, NewLevel = 50 } } },

  [252] = { [50] = { LevelUp = { NewSubtype = 270, NewLevel = 50 }, LevelDown = { NewSubtype = 234, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 251, NewLevel = 50 } } },

  [253] = { [50] = { LevelUp = { NewSubtype = 271, NewLevel = 50 }, LevelDown = { NewSubtype = 235, NewLevel = 50 }, QualityUp = { NewSubtype = 247, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [254] = { [50] = { LevelUp = { NewSubtype = 272, NewLevel = 50 }, LevelDown = { NewSubtype = 236, NewLevel = 50 }, QualityUp = { NewSubtype = 255, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [255] = { [50] = { LevelUp = { NewSubtype = 273, NewLevel = 50 }, LevelDown = { NewSubtype = 237, NewLevel = 50 }, QualityUp = { NewSubtype = 256, NewLevel = 50 }, QualityDown = { NewSubtype = 254, NewLevel = 50 } } },

  [256] = { [50] = { LevelUp = { NewSubtype = 274, NewLevel = 50 }, LevelDown = { NewSubtype = 238, NewLevel = 50 }, QualityUp = { NewSubtype = 257, NewLevel = 50 }, QualityDown = { NewSubtype = 255, NewLevel = 50 } } },

  [257] = { [50] = { LevelUp = { NewSubtype = 275, NewLevel = 50 }, LevelDown = { NewSubtype = 239, NewLevel = 50 }, QualityUp = { NewSubtype = 258, NewLevel = 50 }, QualityDown = { NewSubtype = 256, NewLevel = 50 } } },

  [258] = { [50] = { LevelUp = { NewSubtype = 276, NewLevel = 50 }, LevelDown = { NewSubtype = 240, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 257, NewLevel = 50 } } },

  [265] = { [50] = { LevelUp = { NewSubtype = 283, NewLevel = 50 }, LevelDown = { NewSubtype = 247, NewLevel = 50 }, QualityUp = { NewSubtype = 268, NewLevel = 50 }, QualityDown = { NewSubtype = 271, NewLevel = 50 } } },

  [268] = { [50] = { LevelUp = { NewSubtype = 286, NewLevel = 50 }, LevelDown = { NewSubtype = 250, NewLevel = 50 }, QualityUp = { NewSubtype = 269, NewLevel = 50 }, QualityDown = { NewSubtype = 265, NewLevel = 50 } } },

  [269] = { [50] = { LevelUp = { NewSubtype = 287, NewLevel = 50 }, LevelDown = { NewSubtype = 251, NewLevel = 50 }, QualityUp = { NewSubtype = 270, NewLevel = 50 }, QualityDown = { NewSubtype = 268, NewLevel = 50 } } },

  [270] = { [50] = { LevelUp = { NewSubtype = 288, NewLevel = 50 }, LevelDown = { NewSubtype = 252, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 269, NewLevel = 50 } } },

  [271] = { [50] = { LevelUp = { NewSubtype = 289, NewLevel = 50 }, LevelDown = { NewSubtype = 253, NewLevel = 50 }, QualityUp = { NewSubtype = 265, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [272] = { [50] = { LevelUp = { NewSubtype = 290, NewLevel = 50 }, LevelDown = { NewSubtype = 254, NewLevel = 50 }, QualityUp = { NewSubtype = 273, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [273] = { [50] = { LevelUp = { NewSubtype = 291, NewLevel = 50 }, LevelDown = { NewSubtype = 255, NewLevel = 50 }, QualityUp = { NewSubtype = 274, NewLevel = 50 }, QualityDown = { NewSubtype = 272, NewLevel = 50 } } },

  [274] = { [50] = { LevelUp = { NewSubtype = 292, NewLevel = 50 }, LevelDown = { NewSubtype = 256, NewLevel = 50 }, QualityUp = { NewSubtype = 275, NewLevel = 50 }, QualityDown = { NewSubtype = 273, NewLevel = 50 } } },

  [275] = { [50] = { LevelUp = { NewSubtype = 293, NewLevel = 50 }, LevelDown = { NewSubtype = 257, NewLevel = 50 }, QualityUp = { NewSubtype = 276, NewLevel = 50 }, QualityDown = { NewSubtype = 274, NewLevel = 50 } } },

  [276] = { [50] = { LevelUp = { NewSubtype = 294, NewLevel = 50 }, LevelDown = { NewSubtype = 258, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 275, NewLevel = 50 } } },

  [283] = { [50] = { LevelUp = { NewSubtype = 301, NewLevel = 50 }, LevelDown = { NewSubtype = 265, NewLevel = 50 }, QualityUp = { NewSubtype = 286, NewLevel = 50 }, QualityDown = { NewSubtype = 289, NewLevel = 50 } } },

  [286] = { [50] = { LevelUp = { NewSubtype = 304, NewLevel = 50 }, LevelDown = { NewSubtype = 268, NewLevel = 50 }, QualityUp = { NewSubtype = 287, NewLevel = 50 }, QualityDown = { NewSubtype = 283, NewLevel = 50 } } },

  [287] = { [50] = { LevelUp = { NewSubtype = 305, NewLevel = 50 }, LevelDown = { NewSubtype = 269, NewLevel = 50 }, QualityUp = { NewSubtype = 288, NewLevel = 50 }, QualityDown = { NewSubtype = 286, NewLevel = 50 } } },

  [288] = { [50] = { LevelUp = { NewSubtype = 306, NewLevel = 50 }, LevelDown = { NewSubtype = 270, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 287, NewLevel = 50 } } },

  [289] = { [50] = { LevelUp = { NewSubtype = 307, NewLevel = 50 }, LevelDown = { NewSubtype = 271, NewLevel = 50 }, QualityUp = { NewSubtype = 283, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [290] = { [50] = { LevelUp = { NewSubtype = 308, NewLevel = 50 }, LevelDown = { NewSubtype = 272, NewLevel = 50 }, QualityUp = { NewSubtype = 291, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [291] = { [50] = { LevelUp = { NewSubtype = 309, NewLevel = 50 }, LevelDown = { NewSubtype = 273, NewLevel = 50 }, QualityUp = { NewSubtype = 292, NewLevel = 50 }, QualityDown = { NewSubtype = 290, NewLevel = 50 } } },

  [292] = { [50] = { LevelUp = { NewSubtype = 310, NewLevel = 50 }, LevelDown = { NewSubtype = 274, NewLevel = 50 }, QualityUp = { NewSubtype = 293, NewLevel = 50 }, QualityDown = { NewSubtype = 291, NewLevel = 50 } } },

  [293] = { [50] = { LevelUp = { NewSubtype = 311, NewLevel = 50 }, LevelDown = { NewSubtype = 275, NewLevel = 50 }, QualityUp = { NewSubtype = 294, NewLevel = 50 }, QualityDown = { NewSubtype = 292, NewLevel = 50 } } },

  [294] = { [50] = { LevelUp = { NewSubtype = 312, NewLevel = 50 }, LevelDown = { NewSubtype = 276, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 293, NewLevel = 50 } } },

  [301] = { [50] = { LevelUp = { NewSubtype = 359, NewLevel = 50 }, LevelDown = { NewSubtype = 283, NewLevel = 50 }, QualityUp = { NewSubtype = 304, NewLevel = 50 }, QualityDown = { NewSubtype = 307, NewLevel = 50 } } },

  [304] = { [50] = { LevelUp = { NewSubtype = 362, NewLevel = 50 }, LevelDown = { NewSubtype = 286, NewLevel = 50 }, QualityUp = { NewSubtype = 305, NewLevel = 50 }, QualityDown = { NewSubtype = 301, NewLevel = 50 } } },

  [305] = { [50] = { LevelUp = { NewSubtype = 363, NewLevel = 50 }, LevelDown = { NewSubtype = 287, NewLevel = 50 }, QualityUp = { NewSubtype = 306, NewLevel = 50 }, QualityDown = { NewSubtype = 304, NewLevel = 50 } } },

  [306] = { [50] = { LevelUp = { NewSubtype = 364, NewLevel = 50 }, LevelDown = { NewSubtype = 288, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 305, NewLevel = 50 } } },

  [307] = { [50] = { LevelUp = { NewSubtype = 365, NewLevel = 50 }, LevelDown = { NewSubtype = 289, NewLevel = 50 }, QualityUp = { NewSubtype = 301, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [308] = { [50] = { LevelUp = { NewSubtype = 366, NewLevel = 50 }, LevelDown = { NewSubtype = 290, NewLevel = 50 }, QualityUp = { NewSubtype = 309, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [309] = { [50] = { LevelUp = { NewSubtype = 367, NewLevel = 50 }, LevelDown = { NewSubtype = 291, NewLevel = 50 }, QualityUp = { NewSubtype = 310, NewLevel = 50 }, QualityDown = { NewSubtype = 308, NewLevel = 50 } } },

  [310] = { [50] = { LevelUp = { NewSubtype = 368, NewLevel = 50 }, LevelDown = { NewSubtype = 292, NewLevel = 50 }, QualityUp = { NewSubtype = 311, NewLevel = 50 }, QualityDown = { NewSubtype = 309, NewLevel = 50 } } },

  [311] = { [50] = { LevelUp = { NewSubtype = 369, NewLevel = 50 }, LevelDown = { NewSubtype = 293, NewLevel = 50 }, QualityUp = { NewSubtype = 312, NewLevel = 50 }, QualityDown = { NewSubtype = 310, NewLevel = 50 } } },

  [312] = { [50] = { LevelUp = { NewSubtype = 370, NewLevel = 50 }, LevelDown = { NewSubtype = 294, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 311, NewLevel = 50 } } },

  [359] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 301, NewLevel = 50 }, QualityUp = { NewSubtype = 362, NewLevel = 50 }, QualityDown = { NewSubtype = 365, NewLevel = 50 } } },

  [362] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 304, NewLevel = 50 }, QualityUp = { NewSubtype = 363, NewLevel = 50 }, QualityDown = { NewSubtype = 359, NewLevel = 50 } } },

  [363] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 305, NewLevel = 50 }, QualityUp = { NewSubtype = 364, NewLevel = 50 }, QualityDown = { NewSubtype = 362, NewLevel = 50 } } },

  [364] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 306, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 363, NewLevel = 50 } } },

  [365] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 307, NewLevel = 50 }, QualityUp = { NewSubtype = 359, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [366] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 308, NewLevel = 50 }, QualityUp = { NewSubtype = 367, NewLevel = 50 }, QualityDown = { NewSubtype = nil, NewLevel = nil } } },

  [367] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 309, NewLevel = 50 }, QualityUp = { NewSubtype = 368, NewLevel = 50 }, QualityDown = { NewSubtype = 366, NewLevel = 50 } } },

  [368] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 310, NewLevel = 50 }, QualityUp = { NewSubtype = 369, NewLevel = 50 }, QualityDown = { NewSubtype = 367, NewLevel = 50 } } },

  [369] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 311, NewLevel = 50 }, QualityUp = { NewSubtype = 370, NewLevel = 50 }, QualityDown = { NewSubtype = 368, NewLevel = 50 } } },

  [370] = { [50] = { LevelUp = { NewSubtype = nil, NewLevel = nil }, LevelDown = { NewSubtype = 312, NewLevel = 50 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 369, NewLevel = 50 } } },


  [284] = { [50] = { LevelUp = { NewSubtype = 302, NewLevel = 50 }, LevelDown = { NewSubtype = 266, NewLevel = 50 }, QualityUp = { NewSubtype = 285, NewLevel = 50 }, QualityDown = { NewSubtype = 283, NewLevel = 50 } } },
  [285] = { [50] = { LevelUp = { NewSubtype = 303, NewLevel = 50 }, LevelDown = { NewSubtype = 267, NewLevel = 50 }, QualityUp = { NewSubtype = 288, NewLevel = 50 }, QualityDown = { NewSubtype = 284, NewLevel = 50 } } },

}

ItemChangeData[358] = ItemChangeData[359]

ItemChangeData[39] = ItemChangeData[51]
ItemChangeData[40] = ItemChangeData[52]
ItemChangeData[41] = ItemChangeData[53]
ItemChangeData[42] = ItemChangeData[54]
ItemChangeData[43] = ItemChangeData[55]
ItemChangeData[44] = ItemChangeData[56]
ItemChangeData[45] = ItemChangeData[57]
ItemChangeData[46] = ItemChangeData[58]
ItemChangeData[47] = ItemChangeData[59]
ItemChangeData[48] = ItemChangeData[60]

-- Drops
ItemChangeData[2] = {}
ItemChangeData[3] = {}
ItemChangeData[4] = {}
ItemChangeData[5] = {}
ItemChangeData[6] = {}

--Crafted
ItemChangeData[20] = {}
ItemChangeData[21] = {}
ItemChangeData[22] = {}
ItemChangeData[23] = {}
ItemChangeData[24] = {}

--Crafted also (maybe just level 1)
ItemChangeData[30] = {}
ItemChangeData[31] = {}
ItemChangeData[32] = {}
ItemChangeData[33] = {}
ItemChangeData[34] = {}

-- Odd balls
-- 37 = White named drop BOE
ItemChangeData[37] = {}
-- 9 = Green named drop BOE
ItemChangeData[9] = {}
-- 11 = Blue named drop BOE
ItemChangeData[11] = {}
-- 7 = blue named drop
ItemChangeData[7] = {}
-- 8 = purple named drop
ItemChangeData[8] = {}

for i = 1, 50 do
  ItemChangeData[2][i] = { LevelUp = { NewSubtype = 2, NewLevel = i + 1 }, LevelDown = { NewSubtype = 2, NewLevel = i - 1 }, QualityUp = { NewSubtype = 3, NewLevel = i }, QualityDown = { NewSubtype = nil, NewLevel = nil } }
  ItemChangeData[3][i] = { LevelUp = { NewSubtype = 3, NewLevel = i + 1 }, LevelDown = { NewSubtype = 3, NewLevel = i - 1 }, QualityUp = { NewSubtype = 4, NewLevel = i }, QualityDown = { NewSubtype = 2, NewLevel = i } }
  ItemChangeData[4][i] = { LevelUp = { NewSubtype = 4, NewLevel = i + 1 }, LevelDown = { NewSubtype = 4, NewLevel = i - 1 }, QualityUp = { NewSubtype = 5, NewLevel = i }, QualityDown = { NewSubtype = 3, NewLevel = i } }
  ItemChangeData[5][i] = { LevelUp = { NewSubtype = 5, NewLevel = i + 1 }, LevelDown = { NewSubtype = 5, NewLevel = i - 1 }, QualityUp = { NewSubtype = 6, NewLevel = i }, QualityDown = { NewSubtype = 4, NewLevel = i } }
  ItemChangeData[6][i] = { LevelUp = { NewSubtype = 6, NewLevel = i + 1 }, LevelDown = { NewSubtype = 6, NewLevel = i - 1 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 5, NewLevel = i } }

  ItemChangeData[20][i] = { LevelUp = { NewSubtype = 20, NewLevel = i + 1 }, LevelDown = { NewSubtype = 20, NewLevel = i - 1 }, QualityUp = { NewSubtype = 21, NewLevel = i }, QualityDown = { NewSubtype = nil, NewLevel = nil } }
  ItemChangeData[21][i] = { LevelUp = { NewSubtype = 21, NewLevel = i + 1 }, LevelDown = { NewSubtype = 21, NewLevel = i - 1 }, QualityUp = { NewSubtype = 22, NewLevel = i }, QualityDown = { NewSubtype = 20, NewLevel = i } }
  ItemChangeData[22][i] = { LevelUp = { NewSubtype = 22, NewLevel = i + 1 }, LevelDown = { NewSubtype = 22, NewLevel = i - 1 }, QualityUp = { NewSubtype = 23, NewLevel = i }, QualityDown = { NewSubtype = 21, NewLevel = i } }
  ItemChangeData[23][i] = { LevelUp = { NewSubtype = 23, NewLevel = i + 1 }, LevelDown = { NewSubtype = 23, NewLevel = i - 1 }, QualityUp = { NewSubtype = 24, NewLevel = i }, QualityDown = { NewSubtype = 22, NewLevel = i } }
  ItemChangeData[24][i] = { LevelUp = { NewSubtype = 24, NewLevel = i + 1 }, LevelDown = { NewSubtype = 24, NewLevel = i - 1 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 23, NewLevel = i } }

  ItemChangeData[30][i] = { LevelUp = { NewSubtype = 30, NewLevel = i + 1 }, LevelDown = { NewSubtype = 30, NewLevel = i - 1 }, QualityUp = { NewSubtype = 31, NewLevel = i }, QualityDown = { NewSubtype = nil, NewLevel = nil } }
  ItemChangeData[31][i] = { LevelUp = { NewSubtype = 31, NewLevel = i + 1 }, LevelDown = { NewSubtype = 31, NewLevel = i - 1 }, QualityUp = { NewSubtype = 32, NewLevel = i }, QualityDown = { NewSubtype = 30, NewLevel = i } }
  ItemChangeData[32][i] = { LevelUp = { NewSubtype = 32, NewLevel = i + 1 }, LevelDown = { NewSubtype = 32, NewLevel = i - 1 }, QualityUp = { NewSubtype = 33, NewLevel = i }, QualityDown = { NewSubtype = 31, NewLevel = i } }
  ItemChangeData[33][i] = { LevelUp = { NewSubtype = 33, NewLevel = i + 1 }, LevelDown = { NewSubtype = 33, NewLevel = i - 1 }, QualityUp = { NewSubtype = 34, NewLevel = i }, QualityDown = { NewSubtype = 32, NewLevel = i } }
  ItemChangeData[34][i] = { LevelUp = { NewSubtype = 34, NewLevel = i + 1 }, LevelDown = { NewSubtype = 34, NewLevel = i - 1 }, QualityUp = { NewSubtype = nil, NewLevel = nil }, QualityDown = { NewSubtype = 33, NewLevel = i } }

  ItemChangeData[37][i] = { LevelUp = { NewSubtype = 7, NewLevel = i + 1 }, LevelDown = { NewSubtype = 7, NewLevel = i - 1 }, QualityUp = { NewSubtype = 9, NewLevel = i }, QualityDown = { NewSubtype = nil, NewLevel = nil } }
  ItemChangeData[9][i] = { LevelUp = { NewSubtype = 9, NewLevel = i + 1 }, LevelDown = { NewSubtype = 9, NewLevel = i - 1 }, QualityUp = { NewSubtype = 11, NewLevel = i }, QualityDown = { NewSubtype = 37, NewLevel = i } }
  ItemChangeData[11][i] = { LevelUp = { NewSubtype = 11, NewLevel = i + 1 }, LevelDown = { NewSubtype = 11, NewLevel = i - 1 }, QualityUp = { NewSubtype = 8, NewLevel = i }, QualityDown = { NewSubtype = 9, NewLevel = i } }
  ItemChangeData[7][i] = { LevelUp = { NewSubtype = 7, NewLevel = i + 1 }, LevelDown = { NewSubtype = 7, NewLevel = i - 1 }, QualityUp = { NewSubtype = 8, NewLevel = i }, QualityDown = { NewSubtype = 9, NewLevel = i } }
  ItemChangeData[8][i] = { LevelUp = { NewSubtype = 8, NewLevel = i + 1 }, LevelDown = { NewSubtype = 8, NewLevel = i - 1 }, QualityUp = { NewSubtype = 6, NewLevel = i }, QualityDown = { NewSubtype = 7, NewLevel = i } }

end

ItemChangeData[2][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[3][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[4][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[5][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[6][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }

ItemChangeData[20][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[21][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[22][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[23][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[24][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }

ItemChangeData[30][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[31][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[32][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[33][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[34][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }

ItemChangeData[37][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[9][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[11][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[7][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }
ItemChangeData[8][1]['LevelDown'] = { NewSubtype = nil, NewLevel = nil }

-- Regular to Vet crossover

-- Drops
ItemChangeData[2][50]['LevelUp'] = { NewSubtype = 111, NewLevel = 50 }
ItemChangeData[3][50]['LevelUp'] = { NewSubtype = 51, NewLevel = 50 }
ItemChangeData[4][50]['LevelUp'] = { NewSubtype = 61, NewLevel = 50 }
ItemChangeData[5][50]['LevelUp'] = { NewSubtype = 71, NewLevel = 50 }
ItemChangeData[6][50]['LevelUp'] = { NewSubtype = 101, NewLevel = 50 }

-- Crafted
ItemChangeData[20][50]['LevelUp'] = { NewSubtype = 125, NewLevel = 50 }
ItemChangeData[21][50]['LevelUp'] = { NewSubtype = 135, NewLevel = 50 }
ItemChangeData[22][50]['LevelUp'] = { NewSubtype = 145, NewLevel = 50 }
ItemChangeData[23][50]['LevelUp'] = { NewSubtype = 155, NewLevel = 50 }
ItemChangeData[24][50]['LevelUp'] = { NewSubtype = 165, NewLevel = 50 }

-- Also Crafted (maybe just level 1)
ItemChangeData[30][50]['LevelUp'] = { NewSubtype = 125, NewLevel = 50 }
ItemChangeData[31][50]['LevelUp'] = { NewSubtype = 135, NewLevel = 50 }
ItemChangeData[32][50]['LevelUp'] = { NewSubtype = 145, NewLevel = 50 }
ItemChangeData[33][50]['LevelUp'] = { NewSubtype = 155, NewLevel = 50 }
ItemChangeData[34][50]['LevelUp'] = { NewSubtype = 165, NewLevel = 50 }

ItemChangeData[37][50]['LevelUp'] = { NewSubtype = 111, NewLevel = 50 }
ItemChangeData[9][50]['LevelUp'] = { NewSubtype = 51, NewLevel = 50 }
ItemChangeData[11][50]['LevelUp'] = { NewSubtype = 61, NewLevel = 50 }
ItemChangeData[7][50]['LevelUp'] = { NewSubtype = 61, NewLevel = 50 }
ItemChangeData[8][50]['LevelUp'] = { NewSubtype = 71, NewLevel = 50 }

-- Mirror to get back  Vet to Regular
ItemChangeData[111][50]['LevelDown'] = { NewSubtype = 2, NewLevel = 50 }
ItemChangeData[51][50]['LevelDown'] = { NewSubtype = 3, NewLevel = 50 }
ItemChangeData[61][50]['LevelDown'] = { NewSubtype = 4, NewLevel = 50 }
ItemChangeData[71][50]['LevelDown'] = { NewSubtype = 5, NewLevel = 50 }
ItemChangeData[101][50]['LevelDown'] = { NewSubtype = 6, NewLevel = 50 }

ItemChangeData[125][50]['LevelDown'] = { NewSubtype = 20, NewLevel = 50 }
ItemChangeData[135][50]['LevelDown'] = { NewSubtype = 21, NewLevel = 50 }
ItemChangeData[145][50]['LevelDown'] = { NewSubtype = 22, NewLevel = 50 }
ItemChangeData[155][50]['LevelDown'] = { NewSubtype = 23, NewLevel = 50 }
ItemChangeData[165][50]['LevelDown'] = { NewSubtype = 24, NewLevel = 50 }
