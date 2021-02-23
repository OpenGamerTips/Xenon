-- XenonInit.txt by H3x0R
-- The initial script executed before anything.
-- Handles crap like error handling which I'm too lazy to do in cpp.
local GameMeta = getrawmetatable(game)
local Index = GameMeta.__index
local Namecall = GameMeta.__namecall


setreadonly(GameMeta, false)
GameMeta.__index = newcc(function()

end)
setreadonly(GameMeta, true)