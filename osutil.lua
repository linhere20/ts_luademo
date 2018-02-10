function osCommand(command)
	return os.execute(command)
end

function mkdir(path)
	--if not isFileExist(path) then
	return os.execute("mkdir -p "..path)
	--end
end

function unzip(path, to)
	return os.execute("unzip -o "..path.." -d "..to)
end

function tarx(path, to)
	return os.execute("tar -zxvf "..path.." -C "..to)
end

function rm(path)
	return os.execute("rm -rf "..path)
end

function installDeb(path)
	return os.execute("dpkg -i "..path)
end

function mv(path, to)
	return os.execute("mv "..path.." "..to)
end

function killAppByName(name)
	return os.execute("killall -9 "..name)
end
