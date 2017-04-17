--[[
Title: GitlabService
Author(s):  big
Date:  2017.4.15
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/WorldShare/GitlabService.lua");
local GitlabService = commonlib.gettable("Mod.WorldShare.GitlabService");
------------------------------------------------------------
]]

local GitlabService = commonlib.gettable("Mod.WorldShare.GitlabService");

local gitlabHost = "git.keepwork.com";

local GitlabService = {
    inited      = false,
    username    = '',   -- gitlab �û���
    projectId   = nil,
    projectName = 'keepworkDataSource',
    host        = gitlabHost,
    apiBase     = 'http://' .. gitlabHost .. '/api/v4',
    httpHeader  = {
        --'Accept': 'application/vnd.github.full+json',  -- ���������
    },
};

-- http����
function GitlabService:httpRequest(method, url, data, cb, errcb)
    local config = {
        method  = method,
        url     = self.apiBase .. url,
        headers = self.httpHeader,
        skipAuthorization = true,  -- �������satellizer��֤
    };

    if (method == "POST" or method == "PUT") then
        config.data   = data;
    else
        config.params = data;
    end

--    $http(config).then(function (response) {
--        //console.log(response);
--        typeof cb == 'function' && cb(response.data);
--    }).catch(function (response) {
--        console.log(response);
--        typeof errcb == 'function' && errcb(response);
--    });
end

function GitlabService:getFileUrlPrefix()
    return '/projects/' .. GitlabService.projectId .. '/repository/files/';
end

function GitlabService:getCommitMessagePrefix()
    return "keepwork commit: ";
end

function GitlabService:getCommitUrlPrefix(params)
    params = params or {};
    return 'http://' .. GitlabService.host .. '/' .. (params.username or GitlabService.username) .. '/' .. (params.projectName or GitlabService.projectName) .. '/' .. (params.path or '');
end

function GitlabService:getRawContentUrlPrefix(params)
    params = params or {};
    return 'http://' .. GitlabService.host .. '/' .. (params.username or GitlabService.username) .. '/' .. (params.projectName or GitlabService.projectName) .. '/raw/master/' .. (params.path or '');
end

function GitlabService:getContentUrlPrefix(params)
    params = params or {};
    return 'http://' .. GitlabService.host .. '/' .. (params.username or GitlabService.username) .. '/' .. (params.projectName or GitlabService.projectName) .. '/blob/master/' .. (params.path or '');
end

-- ����ļ��б�
function GitlabService:getTree(isRecursive, cb, errcb)
    local url = '/projects/' .. GitlabService.projectId .. '/repository/tree';
    GitlabService:httpRequest("GET", url, {recursive = isRecursive}, cb, errcb);
end

-- commit
function GitlabService:listCommits(data, cb, errcb)
    --data.ref_name = data.ref_name || 'master';
    local url = '/projects/' .. GitlabService.projectId .. '/repository/commits';
    GitlabService:httpRequest('GET', url, data, cb, errcb);
end

-- д�ļ�
function GitlabService:writeFile(params, cb, errcb)
    --params.content = Base64.encode(params.content);
    local url = GitlabService:getFileUrlPrefix() .. encodeURIComponent(params.path);
    params.commit_message = GitlabService:getCommitMessagePrefix() + params.path;--/*params.message ||*/ 
    params.branch         = params.branch or "master";
    GitlabService:httpRequest("GET", url, {path = params.path, ref = params.branch}, function (data)
        -- �Ѵ���
        GitlabService:httpRequest("PUT", url, params, cb, errcb)
    end, function ()
		GitlabService:httpRequest("POST", url, params, cb, errcb)
    end);
end

-- ��ȡ�ļ�
function GitlabService:getContent(params, cb, errcb)
    local url  = GitlabService:getFileUrlPrefix() .. encodeURIComponent(params.path) .. '/raw';
    params.ref = params.ref or "master";
    GitlabService:httpRequest("GET", url, params, cb, errcb);
end

-- ɾ���ļ�
function GitlabService:deleteFile(params, cb, errcb)
    local url = GitlabService:getFileUrlPrefix() .. encodeURIComponent(params.path);
    params.commit_message = GitlabService:getCommitMessagePrefix() + params.path;-- /*params.message ||*/
    params.branch         = params.branch or 'master';
    GitlabService:httpRequest("DELETE", url, params, cb, errcb)
end

-- �ϴ�ͼƬ
function GitlabService:uploadImage(params, cb, errcb)
    --params path, content
    local path    = params.path;
    local content = params.content;

    if (not path) then
		--֮���޸�
        --path = 'img_' .. (new Date()).getTime();
    end

    path = 'images/' .. path;
    --/*data:image/png;base64,iVBORw0KGgoAAAANS*/
    content = content.split(',');

    if (content.length > 1) then
        local imgType = content[0];
        content = content[1];
        imgType = imgType.match(/image\/([\w]+)/);
        imgType = imgType and imgType[1];
        if (imgType) then
            path = path .. '.' .. imgType;
        end
    else
        content = content[0];
    end

    -- echo(content);
    GitlabService:writeFile({
        path = path,
        message  = GitlabService:getCommitMessagePrefix() .. path,
        content  = content,
        encoding = 'base64',
    }, function (data)
		--֮���޸�
        --cb && cb(gitlab.getRawContentUrlPrefix() + data.file_path);
    end, errcb);
end

-- ��ʼ��
function GitlabService:init(dataSource, cb, errcb)end
    if (GitlabService.inited) then
		if(cb) then
			cb();
		end

        return;
    end

    if (not dataSource.dataSourceUsername or not dataSource.dataSourceToken or not dataSource.apiBaseUrl) then
		if(errcb) then
			errcb();
		end

        return;
    end

    GitlabService.type        = dataSource.type;
    GitlabService.username    = dataSource.dataSourceUsername;
    GitlabService.httpHeader["PRIVATE-TOKEN"] = dataSource.dataSourceToken;
    GitlabService.projectName = dataSource.projectName or GitlabService.projectName;
    GitlabService.apiBase     = dataSource.apiBaseUrl;
    GitlabService.host        = GitlabService.apiBase.match(/http[s]?:\/\/[^\/]+/);
    GitlabService.host        = GitlabService.host and GitlabService.host[0];

    GitlabService:httpRequest("GET", "/projects", {search = GitlabService.projectName, owned = true}, function (projectList)
        -- ������Ŀ�Ƿ����
        for (var i = 0; i < projectList.length; i++) do
            if (projectList[i].name == GitlabService.projectName) {
                GitlabService.projectId = projectList[i].id;
                GitlabService.inited    = true;

				if(cb) then
					cb(projectList[i]);
				end

                return;
            }
        end

        -- �������򴴽���Ŀ
        GitlabService:httpRequest("POST", "/projects", {name = GitlabService.projectName, visibility = 'public',request_access_enabled = true}, function (data)
            -- echo(data);
            GitlabService.projectId = data.id;
            GitlabService.inited    = true;

			if(cb) then
				cb(data);
			end

            return;
        end, errcb)
    end, errcb);
end

function GitlabService:isInited()
    return GitlabService.inited;
end
