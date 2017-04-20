--[[
Title: EncodingGithub
Author(s):  big
Date:  2016.12.29
Desc: 
use the lib: corvent base64 and fit to github
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/EncodingGithub.lua");
local EncodingGithub = commonlib.gettable("Mod.WorldShare.helper.EncodingGithub");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");

local GitEncoding = commonlib.gettable("Mod.WorldShare.helper.GitEncoding");
local Encoding    = commonlib.gettable("System.Encoding");

-- =转成-equal  +转成-plus  /转成-slash
function GitEncoding.base64(text)
	if(text) then
		text = Encoding.base64(text);
		text = text:gsub("[=]"  , "-equal");
		text = text:gsub("[%+]" , "-plus");
		text = text:gsub("[/]"  , "-slash");

		--LOG.std(nil,"debug","text",text);

		return text;
	else
		return nil;
	end
end

function GitEncoding.unbase64(text)
	if(text) then
		text = text:gsub("[-equal]" , "=");
		text = text:gsub("[-plus]"  , "+");
		text = text:gsub("[-slash]" , "/");

		return Encoding.unbase64(text);
	else
		return nil;
	end
end