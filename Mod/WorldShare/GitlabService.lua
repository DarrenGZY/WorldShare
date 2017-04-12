var gitlabHost =config.dataSource.innerGitlab.host || "git.keepwork.com";
    app.factory('gitlab', ['$http', function ($http) {
        var gitlab = {
            inited: false,
            username: '',   // gitlab �û���
            projectId: undefined,
            projectName: 'keepworkDataSource',
            host: gitlabHost,
            apiBase:  'http://' + gitlabHost + '/api/v4',
            httpHeader: {
                //'Accept': 'application/vnd.github.full+json',  // ���������
            },
        };

        // http����
        gitlab.httpRequest = function (method, url, data, cb, errcb) {
            var config = {
                method: method,
                url: this.apiBase + url,
                headers: this.httpHeader,
                skipAuthorization: true,  // �������satellizer��֤
            };
            if (method == "POST" || method == "PUT") {
                config.data = data;
            } else {
                config.params = data;
            }

            $http(config).then(function (response) {
                //console.log(response);
                typeof cb == 'function' && cb(response.data);
            }).catch(function (response) {
                console.log(response);
                typeof errcb == 'function' && errcb(response);
            });
        }

        gitlab.getFileUrlPrefix = function () {
            return '/projects/' + gitlab.projectId + '/repository/files/';
        }

        gitlab.getCommitMessagePrefix = function () {
            return "keepwork commit: ";
        }
        gitlab.getCommitUrlPrefix = function (params) {
            params = params || {}
            return 'http://' + gitlab.host + '/' + (params.username || gitlab.username) + '/' + (params.projectName || gitlab.projectName) + '/'+ (params.path || '');
        }
        gitlab.getRawContentUrlPrefix = function (params) {
            params = params || {}
            return 'http://' + gitlab.host + '/' + (params.username || gitlab.username) + '/' + (params.projectName || gitlab.projectName) + '/raw/master/' + (params.path || '');
        }
        gitlab.getContentUrlPrefix = function (params) {
            params = params || {}
            return 'http://' + gitlab.host + '/' + (params.username || gitlab.username) + '/' + (params.projectName || gitlab.projectName) + '/blob/master/' + (params.path || '');
        }

        // ����ļ��б�
        gitlab.getTree = function (isRecursive, cb, errcb) {
            var url = '/projects/' + gitlab.projectId + '/repository/tree';
            gitlab.httpRequest("GET", url, {recursive:isRecursive}, cb, errcb);
        }

        // commit
        gitlab.listCommits = function (data, cb, errcb) {
            //data.ref_name = data.ref_name || 'master';
            var url = '/projects/' + gitlab.projectId + '/repository/commits';
            gitlab.httpRequest('GET', url, data, cb, errcb);
        };

        // д�ļ�
        gitlab.writeFile = function (params, cb, errcb) {
            //params.content = Base64.encode(params.content);
            var url = gitlab.getFileUrlPrefix() + encodeURIComponent(params.path);
            params.commit_message = /*params.message ||*/ gitlab.getCommitMessagePrefix() + params.path;
            params.branch = params.branch || "master";
            gitlab.httpRequest("GET", url, {path: params.path, ref: params.branch}, function (data) {
                // �Ѵ���
                gitlab.httpRequest("PUT", url, params, cb, errcb)
            }, function () {
                gitlab.httpRequest("POST", url, params, cb, errcb)
            });
        }

        // ��ȡ�ļ�
        gitlab.getContent = function (params, cb, errcb) {
            var url = gitlab.getFileUrlPrefix() + encodeURIComponent(params.path) + '/raw';
            params.ref = params.ref || "master";
            gitlab.httpRequest("GET", url, params, cb, errcb);
        }

        // ɾ���ļ�
        gitlab.deleteFile = function (params, cb, errcb) {
            var url = gitlab.getFileUrlPrefix() + params.path;
            params.commit_message = /*params.message ||*/ gitlab.getCommitMessagePrefix() + params.path;
            params.branch = params.branch || 'master';
            gitlab.httpRequest("DELETE", url, params, cb, errcb)
        }

        // �ϴ�ͼƬ
        gitlab.uploadImage = function (params, cb, errcb) {
            //params path, content
            var path = params.path;
            var content = params.content;
            if (!path) {
                path = 'img_' + (new Date()).getTime();
            }
            path = 'images/' + path;
            /*data:image/png;base64,iVBORw0KGgoAAAANS*/
            content = content.split(',');
            if (content.length > 1) {
                var imgType = content[0];
                content = content[1];
                imgType = imgType.match(/image\/([\w]+)/)
                imgType = imgType && imgType[1];
                if (imgType) {
                    path = path + '.' + imgType;
                }
            } else {
                content = content[0];
            }
            //console.log(content);
            gitlab.writeFile({
                path: path,
                message: gitlab.getCommitMessagePrefix() + path,
                content: content,
                encoding: 'base64'
            }, function (data) {
                cb && cb(gitlab.getRawContentUrlPrefix() + data.file_path);
            }, errcb);
        }
        // ��ʼ��
        gitlab.init = function (token, username, projectName, cb, errcb) {
            if (gitlab.inited || !gitlab.host)
                return;

            gitlab.username = username;
            gitlab.httpHeader["PRIVATE-TOKEN"] = token;
            gitlab.projectName = projectName || gitlab.projectName;

            if (!token)
                return;

            gitlab.httpRequest("GET", "/projects", {search: gitlab.projectName, owned:true}, function (projectList) {
                // ������Ŀ�Ƿ����
                for (var i = 0; i < projectList.length; i++) {
                    if (projectList[i].name == gitlab.projectName) {
                        gitlab.projectId = projectList[i].id;
                        gitlab.inited = true;
                        cb && cb(projectList[i]);
                        return;
                    }
                }
                // �������򴴽���Ŀ
                gitlab.httpRequest("POST", "/projects", {name: gitlab.projectName, visibility:'public',request_access_enabled:true}, function (data) {
                    //console.log(data);
                    gitlab.projectId = data.id;
                    gitlab.inited = true;
                    cb && cb(data);
                    return;
                }, errcb)
            }, errcb);
        }

        gitlab.isInited = function () {
            return gitlab.inited;
        }

        return function () {
            return angular.copy(gitlab);
        }
    }]);