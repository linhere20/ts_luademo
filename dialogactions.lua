local DialogActions = {}

function processDialog(state)
	for key, value in pairs(DialogActions) do
		local status, state = value(state)
		
		if state ~= nil then
			return state
		end
		
		if status == gc.ok then
			return nil
		elseif status == gc.continue then
		end
	end
end

function DialogActions.noSIMCard()
	local noSIMRes = res.dialog.noSIMCard
	if multiColor(noSIMRes.multi) then
		ilog("dialog. 未安装SIM卡")
		tap(noSIMRes.x, noSIMRes.y)
		mSleep(1000)
		return gc.ok
	end
	return gc.continue
end
