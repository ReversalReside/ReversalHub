return function(env)
	local BaseWorkspace = game:GetService("ReplicatedFirst"):FindFirstChild('Sealz.fs') or Instance.new('Folder',game:GetService("ReplicatedFirst"));

	BaseWorkspace.Name = 'Sealz.fs';

	local __get_path_c = function(path)
		return (string.find(path,'/',1,true) and string.split(path,'/')) or (string.find(path,'\\',1,true) and string.split(path,'\\')) or {path};
	end;

	local __get_path = function(path)
		local main = __get_path_c(path);

		local block = BaseWorkspace;

		for i,v in next , main do
			block = block[v];
		end;

		return block;
	end;

	env.readfile = function(path)
		local path : StringValue = __get_path(path);

		return path.Value;
	end;

	env.isfile = function(path)
		local success , message = pcall(function()
			return __get_path(path);
		end);

		if success and not message:IsA("Folder") then
			return true;
		end;

		return false;
	end;

	env.isfolder = function(path)
		local success , message = pcall(function()
			return __get_path(path);
		end);

		if success and message:IsA("Folder") then
			return true;
		end;

		return false;
	end;

	env.writefile = function(path,content)
		local main = __get_path_c(path);

		local block = BaseWorkspace;

		for i,v in next , main do
			local item = block:FindFirstChild(v);
			if not item then
				local c = Instance.new('StringValue',block);

				c.Name = tostring(v);
				c.Value = content;
			else
				if item:IsA('StringValue') and tostring(item) == v then
					item.Name = tostring(v);
					item.Value = content;
				end;

				block = item;
			end;
		end;
	end;

	env.listfiles = function(path)
		local fold = __get_path(path);
		local pa = {};

		for i,v in next , fold:GetChildren() do
			if v:IsA('StringValue') then
				table.insert(pa,path..'/'..tostring(v));
			end;
		end;

		return pa;
	end;

	env.makefolder = function(path)
		local main = __get_path_c(path);

		local block = BaseWorkspace;

		for i,v in next , main do
			local item = block:FindFirstChild(v);
			if not item then
				local c = Instance.new('Folder',block);

				c.Name = tostring(v);
			else
				block = item;
			end;
		end;
	end;

	env.delfile = function(path)
		local main = __get_path_c(path);

		local block = BaseWorkspace;

		for i,v in next , main do
			local item = block:FindFirstChild(v);
			if item and item:IsA('StringValue') then
				item:Destroy();
			else
				block = item;
			end;
		end;
	end;
end
