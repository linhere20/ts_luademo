require "TSLib"
sz = require "sz"
json = sz.json
thread = require "thread"
class = require "middleclass"
require "config"
require "ilog"
require "State"

State.static.stateInjection = {
	before = function(state) 
		ilog(state.name.." global state before", false)
	end,
	after = function(state) 
		ilog(state.name.." global state after", false)
	end,
	whiteList = {gc.states.MainState}
}

local stateMgr = StateMgr:new("mainTask")
stateMgr:start()
