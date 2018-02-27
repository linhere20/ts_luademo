res = res or {}

---------------------vpn begin-----------------------
res.vpn = {

	add = {
		typePos = {x = 80, y = 240}, --类型 
		pptpPos = {x = 100, y = 505}, --PPTP
		l2tpPos = {x = 100, y = 420}, --L2TP
		cfgRetPos = {x = 100, y = 80}, --添加配置返回按钮
		descPos = {x = 280, y = 400}, --描述
		finishPoint = {x = 568, y = 86, color = 0x007aff}, --完成按钮
		savePoint = {x = 442, y = 684, color = 0x007aff}, --保存按钮
		addVPNColorFuzzy = function() return findMultiColorInRegionFuzzy( 0x007aff, "31|3|0x007aff,75|2|0x007aff,98|2|0x007aff,121|4|0x007aff,160|4|0x1283ff,185|3|0x007aff", 90, 0, 0, 639, 1135) end,
	},
}
---------------------vpn end-------------------------

--------------------dialog begin---------------------
res.dialog = {

	noSIMCard = {
		multi = {
			{  219,  512, 0x9f9f9f},
			{  213,  522, 0xf7f7f7},
			{  243,  535, 0x000000},
			{  310,  584, 0xd2d2d6},
			{  311,  615, 0x007aff},
			{  327,  641, 0x007aff},
			{  444,  521, 0xf7f7f7},
			{  381,  534, 0x4c4c4c},
			{  318,  523, 0xf7f7f7},
		},
		x = 320, 
		y = 630
	},
}
--------------------dialog end---------------------