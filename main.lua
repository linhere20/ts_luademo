require "TSLib"
sz = require "sz"
json = sz.json
thread = require "thread"
class = require "middleclass"
require "dateutil"
require "fileutil"
require "httputil"
require "funcutil"
require "osutil"
require "tableutil"
require "tsutil"
require "config"
require "dialogactions"
require "runtimedata"
require "ilog"
require "StateConfig"

function main()
	StateMgr:new("mainTask"):start()
end

local status, err = tryCatch(main)
if not status then
	ilog("occur an exception causes the program crashed!")
	ilog("errInfo: "..err)
	--error(err) --throw an exception to the TouchSprite
	dialog(err, 30)
	lua_restart()
end

