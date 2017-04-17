--[[
Title: HttpRequest
Author(s):  big
Date:  2017.4.17
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/service/HttpRequest.lua");
local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest");
------------------------------------------------------------
]]

local HttpRequest = commonlib.gettable("Mod.WorldShare.service.HttpRequest");

HttpRequest.tryTimes = 0; 

function HttpRequest:GetUrl(_params,_callback)
	System.os.GetUrl(_params,function(err, msg, data)
		if(err == 200) then
			_callback(data,err);
		else
			self:retry(err, msg, data, _params, _callback);
		end
	end);
end

function HttpRequest:retry(_err, _msg, _data, _params, _callback)
	--LOG.std(nil,"debug","GithubService:retry",{_err});

	if(_err == 422 or _err == 404 or _err == 409) then
		_callback(_data,_err); -- ʧ��ʱ��ֱ�ӷ��صĴ���
		return;
	end

	if(self.tryTimes >= 3) then
		_callback(_data,_err);
		self.tryTimes = 0;
		return;
	end

	if(_err == 200 or _err == 201 or _err == 204 and _data ~= "") then
		_callback(_data,_err);
		self.tryTimes = 0;
	else
		self.tryTimes = self.tryTimes + 1;
		
		commonlib.TimerManager.SetTimeout(function()
			self:GetUrl(_params, _callback); -- �����ȡʧ����ݹ��ȡ����
		end, 2100);
	end
end
