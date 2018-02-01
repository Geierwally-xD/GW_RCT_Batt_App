--[[
	---------------------------------------------------------
    Battery Percentage application converts capacity used (mAh)
	to percentage-range 100-0% from full to empty battery. 
	
	Possibility to define a 3-position switch to select between
	3 different size packs. If no switch is defined only battery
	1 is used.
	
	Voice announcement of battery percentage with switch
	
	Also app makes a LUA controls (switch) that can be used as
	any other switch, voices, alarms etc.
	
	Telemetry-screne on main-screen with Battery-
	symbol. Symbol is realtime - Charge gets lower on use.
	
	Localisation-file has to be as /Apps/GW_BATT/lang/xx/locale.jsn
	
	French translation courtesy from Daniel Memim
	Italian translation courtesy from Fabrizio Zaini
	Czech and Slovak translations by Michal Hutnik
	---------------------------------------------------------
	Based on Battery Percentage by Tero Salminen RC-Thoughts.com
	---------------------------------------------------------
	Released by Geierwally 11 2017
	---------------------------------------------------------
	1 add voltage limit check with own alarm control
	2 draw battery symbol and text red on capacity- 
	  or voltage alarm (grayed on 14 and 16 transmitters)
	3 increased stepwith for differnt battery types (capa intBoxes)  
	4 one app for all transmitters 14, 16, 24
	5 bugfix storage lack on 14 and 16 transmitters
	6 3 capacity alerts and 1 voltage alert configurable
	---------------------------------------------------------
--]]
--Configuration
--Local variables
local appLoaded = false
local main_lib = nil  -- lua main script
local initDelay = 0
local mem = 0
local debugmem = 0
local battVersion = "GW2.3.4"

-------------------------------------------------------------------- 
-- Initialization
--------------------------------------------------------------------
local function init(code)
	if(initDelay == 0)then
		initDelay = system.getTimeCounter()
	end	
	if(main_lib ~= nil) then
		local func = main_lib[1]
		func(battVersion) --init(0)
	end
end


--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop() 
	currentTimeF3K = system.getTimeCounter()
	 -- load current task
    if(main_lib == nil)then
		init(0)
		if((system.getTimeCounter() - initDelay > 5000)and(initDelay ~=0)) then
			if(appLoaded == false)then
				local memTxt = "max: "..mem.."K act: "..debugmem.."K"
				print(memTxt)
				main_lib = require("GW_Batt/Task/GW_Batt_Main")
				if(main_lib ~= nil)then
					appLoaded = true
					init(0)
					initDelay = 0
				end
				collectgarbage()
			end
		end
	else
		local func = main_lib[2] --loop()
		func() -- execute main loop
	end	
	debugmem = math.modf(collectgarbage('count'))
	if (mem < debugmem) then
		mem = debugmem
		local memTxt = "max: "..mem.."K act: "..debugmem.."K"
		print(memTxt)
	end
end
 
--------------------------------------------------------------------
return { init=init, loop=loop, author="Geierwally", version=battVersion, name="Battery Percentage"}