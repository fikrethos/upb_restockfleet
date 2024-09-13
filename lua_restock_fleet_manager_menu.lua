--[[
    Yapılanlar

    Yapılacaklar listesi
    
   
    * manager ekranı güncelleme isteği geldiğinde gemiler sıraya konduktan sonra seçili olan gemiye konumlanmıyor

    * tWare bilgisi üzerinden macro kullanarak patlamış gemilerin tShipPlanı çıkartılacak
    * PlanData çıkarma işlemi stack şekline çevrilecek (öncesinde yedekleme yap, )
    * tanımlı 7.0 Color yapılarından birinin datasını sColor a yazacağız
    * 
]]
--call in md  param == { 0, 0, varsa pencere açıldığında konumlanacak $RFMKey, md options table global.$upbRF_DATA }
-- ffi setup
local ffi = require("ffi")
local C = ffi.C

local playerID

local debug0 = false         -- menu.çekirdekfonksiyonlarının giriş çıkışlarını görmek için
local debug1 = false        -- init (lua yükleme zamanı) için
local debug2 = false        -- menu.functionları içindeki detaylı döküm için
local debugW = false         -- table satırlarında ve widget olaylarında debug zamanı görünmesini istediğimiz değerler için
local debugWProps = false   -- tablelerin x,y width ve height değerlerini görmek için
local debugCheat = false    -- cheat penceresini eklemek için

local debugSettings = false -- md den gelen değişkenlerin dökümü için
local debugColorMod = false -- option mode da, frame tablelerinin zemin renkliliği için


local debugGetData = false           -- Player.entity.$md_RFM_DataChanged   değişim durumu kontrol dökümü
local debugData = false              -- Player.entity.$RM_Fleets .$FleetRecords $RebuildCues değişkenlerin dökümü
local debugDataDeep = false          
local debugConstruction = false      
local debugSubordinate = false       


-- menu variable - used by Helper and used for dynamic variables (e.g. inventory content, etc.)
local menu = {
    name = "RFM_Menu",
    title = "Restock Fleet Manager",
    fleetsTableData = {
        selected = nil,
        settoprow = nil,
        setselectedrow = nil,
    },
    shipsTableData = {
        selected = nil,
        settoprow = nil,
        setselectedrow = nil,
    },
}


local config = {
	mainLayer = 5,
	infoLayer = 4,
	contextLayer = 2,
	rowHeight = 17,
    mapRowHeight = Helper.standardTextHeight,
    propertySorterType = "name",
    infoFrameTableMode = "manager",
	leftBar = {
		{ name = "Fleets & Stations",   icon = "mapst_ol_stations", mode = "manager",   helpOverlayID = "mapst_po_stations",    helpOverlayText = "This category shows all RFM stations and ships." },
        { spacing = true },
        { name = "Options",	            icon = "mapst_objectlist",	mode = "options",   helpOverlayID = "mapst_ol_objectlist",	helpOverlayText = "This category shows options." },
        { spacing = true },
        { name = "Cheat",	            icon = "mapst_objectlist",	mode = "cheats",    helpOverlayID = "mapst_ol_objectlist",	helpOverlayText = "This category shows cheats." },
	},
	assignments = {
		["defence"]					= { name = ReadText(20208, 40301) },
		["positiondefence"]			= { name = ReadText(20208, 41501) },
		["attack"]					= { name = ReadText(20208, 40901) },
		["interception"]			= { name = ReadText(20208, 41001) },
		["bombardment"]				= { name = ReadText(20208, 41601) },
		["follow"]					= { name = ReadText(20208, 41301) },
		["supplyfleet"]				= { name = ReadText(20208, 40701) },
		["mining"]					= { name = ReadText(20208, 40201) },
		["trade"]					= { name = ReadText(20208, 40101) },
		["tradeforbuildstorage"]	= { name = ReadText(20208, 40801) },
		["assist"]					= { name = ReadText(20208, 41201) },
		["salvage"]					= { name = ReadText(20208, 41401) },
	},
    classOrder = {
        ["ship_xs"]		= 1,
        ["ship_s"]		= 2,
        ["ship_m"]		= 3,
        ["ship_l"]		= 4,
        ["ship_xl"]		= 5,
        ["station"]		= 6,
    },
    selectedRowBgColor = { r = 28, g = 77, b = 160, a = 100 }, --   ,
    blacklisttypes = {
        { type = "sectortravel",	name = ReadText(1001, 9165) },
        { type = "sectoractivity",	name = ReadText(1001, 9166) },
        { type = "objectactivity",	name = ReadText(1001, 9167) },
    },
    

}

config.sColor = {
    available = { r = 7, g = 29, b = 46, a = 100 },
    black = { r = 0, g = 0, b = 0, a = 100 },
    blue = { r = 90, g = 146, b = 186, a = 100 },
    brightyellow = { r = 255, g = 255, b = 0, a = 100 },
    changedvalue = { r = 255, g = 236, b = 81, a = 100 },
    checkboxgroup = { r = 0, g = 102, b = 238, a = 60 },
    cover = { r = 231, g = 244, b = 70, a = 100 },
    cyan = { r = 46, g = 209, b = 255, a = 100 },
    darkgreen = { r = 32, g = 150, b = 32, a = 100 },
    darkgrey = { r = 32, g = 32, b = 32, a = 100 },
    darkorange = { r = 128, g = 95, b = 0, a = 100 },
    done = { r = 38, g = 61, b = 78, a = 100 },
    green = { r = 0, g = 255, b = 0, a = 100 },
    grey = { r = 128, g = 128, b = 128, a = 100 },
    grey64 = { r = 64, g = 64, b = 64, a = 100 },
    illegal = { r = 255, g = 64, b = 0, a = 100 },
    illegaldark = { r = 128, g = 32, b = 0, a = 100 },
    lightgreen = { r = 100, g = 225, b = 0, a = 100 },
    lightgrey = { r = 192, g = 192, b = 192, a = 100 },
    mission = { r = 255, g = 190, b = 0, a = 100 },
    orange = { r = 255, g = 192, b = 0, a = 100 },
    playergreen = { r = 170, g = 255, b = 139, a = 100 },
    red = { r = 255, g = 0, b = 0, a = 100 },
    semitransparent = { r = 0, g = 0, b = 0, a = 95 },
    slidervalue = { r = 71, g = 136, b = 184, a = 100 },
    textred = { r = 255, g = 80, b = 80, a = 100 },
    transparent80 = { r = 0, g = 0, b = 0, a = 80 },
    transparent60 = { r = 0, g = 0, b = 0, a = 60 },
    transparent40 = { r = 0, g = 0, b = 0, a = 40 },
    transparent = { r = 0, g = 0, b = 0, a = 0 },
    unselectable = { r = 32, g = 32, b = 32, a = 100 },
    warning = { r = 192, g = 192, b = 0, a = 100 },
    warningorange = { r = 255, g = 138, b = 0, a = 100 },
    white = { r = 255, g = 255, b = 255, a = 100 },
    yellow = { r = 144, g = 144, b = 0, a = 100 },
    
    
    alertnormal = {r = 245, g = 40, b = 100, a = 100},
    alerthigh = {r = 236, g = 28, b = 28, a = 100},

    statusRed = {r = 255, g = 0, b = 0, a = 100},
    statusOrange = {r = 255, g = 64, b = 0, a = 100},
    statusYellow = {r = 255, g = 255, b = 0, a = 100},
    statusGreen = {r = 0, g = 255, b = 0, a = 100},

}

local x4Ver = tonumber(string.match(GetVersionString(), "(%w+)%."))
local xdebug = debug1 and DebugError(menu.name .. " .lua. X4 Ver:" .. tostring(x4Ver))
if x4Ver < 7 then
    config.Color = {
        
        boxtext_box_default = { r = 49, g = 69, b = 83, a = 60 },			        -- defaultBoxTextBoxColor ya da { r = 0,  g = 57, b = 76, a = 88 } olabilir
        boxtext_box_hidden = { r = 0, g = 0, b = 0, a = 0 },                        -- color.transparent

        button_background_default = { r = 49, g = 69, b = 83, a = 60 },             -- defaultButtonBackgroundColor
        button_background_hidden = { r = 0, g = 0, b = 0, a = 0 },                  -- color.transparent
        button_background_inactive = { r = 32, g = 32, b = 32, a = 100 },           -- color.darkgrey
        button_highlight_bigbutton = { r = 0, g = 149, b = 203, a = 100 },          -- { r = 0, g = 149, b = 203, a = 100 }
        button_highlight_default = { r = 71, g = 136, b = 184, a = 100 },           -- defaultButtonHighlightColor
        button_highlight_hidden = { r = 0, g = 0, b = 0, a = 0 },                   -- color.transparent
        button_highlight_inactive = { r = 80, g = 80, b = 80, a = 100 },            -- defaultUnselectableButtonHighlightColor
        
        crew_transfer = { r = 255, g = 255, b = 0, a = 100 },                       -- color.brightyellow

        dropdown_background_default = { r = 49, g = 69, b = 83, a = 60 },           -- defaultButtonBackgroundColor
        dropdown_background_inactive = { r = 31, g = 31, b = 31, a = 100 },         -- defaultUnselectableButtonBackgroundColor
        dropdown_highlight_default = { r = 71, g = 136, b = 184, a = 100 },         -- defaultButtonHighlightColor
        dropdown_highlight_inactive = { r = 80, g = 80, b = 80, a = 100 },          -- defaultUnselectableButtonHighlightColor
        
        checkbox_background_default = { r = 66, g = 92, b = 111, a = 100 },         -- defaultCheckBoxBackgroundColor

        editbox_background_default = { r = 49, g = 69, b = 83, a = 60 },            -- defaultEditBoxBackgroundColor

        flowchart_border_default = { r = 90, g = 146, b = 186, a = 100 },		-- light cyan
        flowchart_edge_default = { r = 255, g = 255, b = 255, a = 100 },            -- color.white
        flowchart_node_background = { r = 25, g = 25, b = 25, a = 100 },		-- dark grey
        flowchart_node_default = { r = 90, g = 146, b = 186, a = 100 },			    -- defaultFlowchartOutlineColor
        flowchart_value_default = { r = 0, g = 116, b = 153, a = 100 },		    -- cyan
        flowchart_slider_value1 = { r = 225, g = 149, b = 0, a = 100 },			-- orange
        flowchart_slider_diff1 = { r = 89, g = 52, b = 0, a = 100 },				-- defaultFlowchartDiff1Color brown
        flowchart_slider_value2 = { r = 66, g = 171, b = 61, a = 100 },			-- green
        flowchart_slider_diff2 = { r = 4, g = 89, b = 0, a = 100 },					-- defaultFlowchartDiff2Color dark green

        frame_background_black = { r = 0, g = 0, b = 0, a = 100 },                  -- color.black
        frame_background_semitransparent = { r = 0, g = 0, b = 0, a = 95 },         -- color.semitransparent
        frame_background2_notification = { r = 90, g = 146, b = 186, a = 100 },     -- color.blue

        graph_data_1 ={ r = 253, g =  91, b =  91, a = 100 },				        -- { r = 253, g =  91, b =  91, a = 100 }
        graph_data_2 = { r = 252, g = 171, b =  92, a = 100 },                      -- { r = 252, g = 171, b =  92, a = 100 }
        graph_data_3 = { r =  85, g = 172, b =   0, a = 100 },                      -- { r =  85, g = 172, b =   0, a = 100 }
        graph_data_4 = { r = 180, g = 250, b = 200, a = 100 },                      -- { r = 180, g = 250, b = 200, a = 100 }
        graph_data_5 = { r =   0, g = 175, b = 180, a = 100 },                      -- { r =   0, g = 175, b = 180, a = 100 }
        graph_data_6 = { r =  91, g = 133, b = 253, a = 100 },                      -- { r =  91, g = 133, b = 253, a = 100 }
        graph_data_7 = { r = 171, g =  91, b = 253, a = 100 },                      -- { r = 171, g =  91, b = 253, a = 100 }
        graph_data_8 = { r = 253, g =  91, b = 213, a = 100 },                      -- { r = 253, g =  91, b = 213, a = 100 }
        graph_grid = {r = 96, g = 96, b = 96, a = 80},                              -- {r = 96, g = 96, b = 96, a = 80}

        hint_background_orange = { r = 255, g = 192, b = 0, a = 100 },  	        -- color.orange
        hint_background_azure = { r = 90, g = 146, b = 186, a = 100 },	            -- color.blue
        
        icon_error = { r = 255, g = 0, b = 88, a = 100 },                           -- { r = 255, g = 0, b = 88, a = 100 }
        icon_error_inactive = { r = 179, g = 0, b = 62, a = 100 },                  -- { r = 179, g = 0, b = 62, a = 100 }
        icon_hidden = { r = 0, g = 0, b = 0, a = 0 },                               -- color.transparent
        icon_inactive = { r = 0, g = 0, b = 0, a = 60 },                            -- color.transparent60
        icon_mission = { r = 255, g = 190, b = 0, a = 100 },                        -- color.mission
        icon_normal = { r = 255, g = 255, b = 255, a = 100 },                       -- color.white
        icon_transparent = { r = 0, g = 0, b = 0, a = 1 },                          -- { r = 0, g = 0, b = 0, a = 1 }
        icon_warning = { r = 249, g = 132, b = 31, a = 100 },                       -- color.warningorange

        lso_node_error = { r = 255, g = 0, b = 0, a = 100 },                        -- color.red
        lso_node_warning = { r = 249, g = 132, b = 31, a = 100 },                   -- color.warningorange
        lso_node_removed = { r = 255, g = 0, b = 0, a = 100 },                      -- color.red
        lso_node_inactive = { r = 128, g = 128, b = 128, a = 100 },                 -- color.grey
        lso_slot_container = { r = 224, g = 79, b = 0, a = 100 },                   -- defaultFlowchartConnector3Color
        lso_slot_liquid = { r = 0, g = 154, b = 204, a = 100 },                     -- defaultFlowchartConnector2Color	
        lso_slot_solid = { r = 255, g = 220, b = 0, a = 100 },                      -- defaultFlowchartConnector1Color
        lso_slot_condensate = { r = 255, g = 153, b = 255, a = 100 },               -- defaultFlowchartConnector4Color
        
        order_override = { r = 255, g = 0, b = 0, a = 100 },                        -- color.red
        order_temp = { r = 90, g = 146, b = 186, a = 100 }, 				        -- color.blue

        player_cover = { r = 231, g = 244, b = 70, a = 100 },                       -- color.cover
        player_info_background = { r = 0, g = 0, b = 0, a = 60 },                   -- color.transparent60

        research_incomplete = { r = 128, g = 128, b = 128, a = 100 },               -- color.grey

        resource_liquid = { r = 0, g = 0, b = 255, a = 100 },                       -- { r = 0, g = 0, b = 255, a = 100 }
        resource_mineral = { r = 255, g = 0, b = 0, a = 100 },                      -- { r = 255, g = 0, b = 0, a = 100 } 
        resource_mineral_liquid = { r = 255, g = 0, b = 255, a = 100 },             -- { r = 255, g = 0, b = 255, a = 100 }

        row_background = { r = 0, g = 0, b = 0, a = 0 },                            -- color.transparent
        row_background_blue = { r = 0, g = 57, b = 76, a = 88 },                   -- { r = 0,  g = 57, b = 76, a = 88 }
        row_background_blue_opaque = { r = 0, g = 99, b = 134, a = 100 },          -- defaultTitleTrapezoidBackgroundColor { r = 66, g = 92, b = 111, a = 100 },
        row_background_immediate = { r = 0, g = 243, b = 0, a = 100 },              --  r = 0, g = 243, b = 0, a = 100 }
        row_background_selected = { r = 83, g = 116, b = 139, a = 60 },             -- defaultArrowRowBackgroundColor
        row_background_unselectable = { r = 32, g = 32, b = 32, a = 100 },          -- color.unselectable (color.darkgrey)
        row_separator = { r = 128, g = 128, b = 128, a = 100 },                     -- color.grey
        row_separator_encyclopedia = { r = 7, g = 29, b = 46, a = 100 },            -- color.available
        row_separator_white = { r = 255, g = 255, b = 255, a = 100 },               -- color.white
        row_title = { r = 66, g = 92, b = 111, a = 60 },                            -- defaultSimpleBackgroundColor
        row_title_background = { r = 49, g = 69, b = 83, a = 60 },                  -- defaultTitleBackgroundColor
        
        scenario_button_background = { r = 0, g = 0, b = 0, a = 100 },             -- { r = 0,  g = 0, b = 0, a = 100 }
        scenario_button_inactive = { r = 121, g = 121, b = 119, a = 100 },         -- { r = 121,  g = 121, b = 119, a = 100 }
        scenario_completed = { r = 246, g = 176, b = 114, a = 100 },               -- { r = 246,  g = 176, b = 114, a = 100 }
        scenario_completed_border = { r = 246, g = 176, b = 114, a = 100 },        -- { r = 246,  g = 176, b = 114, a = 100 }
        
        ship_retrieval = { r = 163, g = 193, b = 227, a = 100 },    				-- defaultUnselectableFontColor
        ship_stat_background = { r = 0, g = 0, b = 0, a = 60 },                    -- color.transparent60

        slider_arrow_click = { r = 0, g = 57, b = 76, a = 100},                     -- { r = 0, g = 57, b = 76, a = 100}  
        slider_arrow_disabled = { r = 91, g = 91, b = 89, a = 100 },                -- { r = 91, g = 91, b = 89, a = 100 }
        slider_arrow_highlight = { r = 255, g = 255, b = 255, a = 100 },            -- { r = 255, g = 255, b = 255, a = 100 }
        slider_arrow_normal = { r = 255, g = 255, b = 255, a = 100 },               -- { r = 255, g = 255, b = 255, a = 100 }
        slider_background_default = { r = 22, g = 34, b = 41, a = 60 },             -- defaultSliderCellBackgroundColor
        slider_background_inactive = { r = 40, g = 40, b = 40, a = 60 },            -- defaultSliderCellInactiveBackgroundColor
        slider_background_transparent = { r = 0, g = 0, b = 0, a = 0 },             -- color.transparent
        slider_diff_neg = { r = 216, g = 68, b = 29, a = 30 },                      -- defaultSliderCellNegativeValueColor
        slider_diff_pos = { r = 29, g = 216, b = 35, a = 30 },                      -- defaultSliderCellPositiveValueColor
        slider_value = { r = 99, g = 138, b = 166, a = 100 },                       -- defaultSliderCellValueColor , color.slidervalue
        slider_value_inactive = { r = 128, g = 128, b = 128, a = 100 },             -- color.grey

        statusbar_diff_neg_default = { r = 236, g = 53, b = 0, a = 30 },            -- defaultStatusBarNegChangeColor
        statusbar_diff_pos = { r = 66, g = 92, b = 111, a = 60 },                   -- defaultSimpleBackgroundColor
        statusbar_diff_pos_default = { r = 20, g = 222, b = 20, a = 30 },           -- defaultStatusBarPosChangeColor
        statusbar_marker_default = { r = 153, g = 213, b = 234, a = 100 },
        statusbar_marker_hidden = { r = 0, g = 0, b = 0, a = 0 },                   -- color.transparent
        statusbar_value_default = { r = 71, g = 136, b = 184, a = 100 },            -- defaultStatusBarValueColor
        statusbar_value_grey = { r = 128, g = 128, b = 128, a = 100 },              -- color.grey
        statusbar_value_orange = { r = 255, g = 192, b = 0, a = 100 },  	        -- color.orange
        statusbar_value_white = { r = 255, g = 255, b = 255, a = 100 },             -- color.white

        table_background_3d_editor = { r = 0, g = 0, b = 0, a = 60 },               -- color.transparent60
        table_background_default = { r = 255, g = 255, b = 255, a = 100 },          -- color.white

        text_boarding_done = { r = 0, g = 255, b = 0, a = 100 },                    -- color.green
        text_boarding_risk_verylow = { r = 0, g = 255, b = 0, a = 100 },            -- color.green
        text_boarding_risk_low = { r = 144, g = 144, b = 0, a = 100 },	            -- color.yellow		
        text_boarding_risk_medium = { r = 255, g = 192, b = 0, a = 100 },           -- color.orange
        text_boarding_risk_high = { r = 255, g = 0, b = 0, a = 100 },               -- color.red
        text_boarding_risk_veryhigh = { r = 255, g = 0, b = 0, a = 100 },           -- color.red
        text_boarding_risk_impossible = { r = 255, g = 0, b = 0, a = 100 },         -- color.red
        text_boarding_started = { r = 255, g = 192, b = 0, a = 100 },               -- color.orange
        text_boarding_waiting = { r = 255, g = 0, b = 0, a = 100 },                 -- color.red
        text_criticalerror = { r = 255, g = 0, b = 0, a = 100 },                    -- color.red
        text_enemy = { r = 248, g = 145, b = 178, a = 100 },                        -- holomapcolor.enemycolor
        text_error = { r = 255, g = 0, b = 0, a = 100 },                            -- color.red
        text_failure = { r = 255, g = 0, b = 0, a = 100 },                          -- color.red
        text_hidden = { r = 0, g = 0, b = 0, a = 0 },                               -- color.transparent
        text_hostile = { r = 255, g = 0, b = 88, a = 100 },                         -- holomapcolor.hostilecolor
        text_illegal = { r = 255, g = 64, b = 0, a = 100 },                         -- color.illegal
        text_illegal_inactive = { r = 128, g = 32, b = 0, a = 100 },                -- color.illegaldark
        text_inactive = { r = 128, g = 128, b = 128, a = 100 },                     -- color.grey
        text_inprogress = { r = 242, g = 242, b = 135, a = 100 },                   -- { r = 242, g = 242, b = 135, a = 100 }
        text_logbook_highlight = { r = 255, g = 0, b = 0, a = 100 },                -- color.red
        text_mission = { r = 255, g = 190, b = 0, a = 100 },                        -- color.mission
        text_negative = { r = 255, g = 0, b = 0, a = 100 },                         -- color.red
        text_neutral = { r = 242, g = 242, b = 135, a = 100 },                      -- { r = 242, g = 242, b = 135, a = 100 }
        text_normal = { r = 255, g = 255, b = 255, a = 100 },                       -- color.white
        text_player = { r = 0, g = 255, b = 0, a = 100 },                           -- color.green
        text_player_current = { r = 170, g = 255, b = 139, a = 100 },               -- color.playergreen
        text_positive = { r = 0, g = 255, b = 0, a = 100 },                         -- color.green
        text_skills = { r = 255, g = 255, b = 0, a = 100 },                         -- color.brightyellow
        text_skills_irrelevant = { r = 144, g = 144, b = 0, a = 100 },              -- color.yellow
        text_success = { r = 0, g = 255, b = 0, a = 100 },                          -- color.green
        text_warning = { r = 249, g = 132, b = 31, a = 100 },                       -- color.warningorange

        toplevel_arrow = { r = 128, g = 196, b = 255, a = 100 },                    -- { r = 128, g = 196, b = 255, a = 100 }
        toplevel_arrow_inactive = { r = 64, g = 98, b = 128, a = 100 },             -- { r = 64, g = 98, b = 128, a = 100 }

        trade_buyoffer = { r = 91, g = 148, b = 188, a = 100 },                     -- { r = 91, g = 148, b = 188, a = 100 }

        weapon_group_highlight = { r = 0, g = 102, b = 238, a = 60 },               -- color.checkboxgroup

    }
else
    config.Color = Color
end

local isDebugMode = pcall(debug.debug)

-- init menu and register witdh Helper
local function init()
    Menus = Menus or {}

    local founded = false
    for _, imenu in ipairs(Menus) do -- note that i is simply a placeholder for an ignored variable 
        if imenu.name == menu.name then
            founded = true
            break
        end
    end
    if not founded then
        table.insert(Menus, menu)
        local xdebug = debug1 and DebugError("Inserted " .. menu.name .. " in Menus")
        if Helper then
            Helper.registerMenu(menu)
            local xdebug = debug1 and DebugError("Registered " .. menu.name .. " in Menus")
        end
    else
        local xdebug = debug1 and DebugError("" .. menu.name .. " founded in Menus, Passed Insert and Register Proccess")
    end
    DebugError (menu.name .. " .lua file Init OK...")


    -- upgradewares
    menu.planDATA = {}
	menu.planDATA.upgradewares = {}
	for _, upgradetype in ipairs(Helper.upgradetypes) do
		if upgradetype.supertype ~= "group" then
			menu.planDATA.upgradewares[upgradetype.type] = {}
		end
	end
    menu.planDATA.allownonplayerblueprints = true
    local n = 0
    local buf
    n = C.GetNumAllEquipment(not menu.planDATA.allownonplayerblueprints)
    buf = ffi.new("EquipmentWareInfo[?]", n)
    n = C.GetAllEquipment(buf, n, not menu.planDATA.allownonplayerblueprints)
    if n > 0 then
        for i = 0, n - 1 do
            local type = ffi.string(buf[i].type)
            local entry = {}
            entry.ware = ffi.string(buf[i].ware)
            entry.macro = ffi.string(buf[i].macro)
            if type == "software" then
                entry.name = GetWareData(entry.ware, "name")
            else
                entry.name = GetMacroData(entry.macro, "name")
            end
            entry.objectamount = 0
            entry.isFromShipyard = true
            if (type == "lasertower") or (type == "satellite") or (type == "mine") or (type == "navbeacon") or (type == "resourceprobe") then
                type = "deployable"
            end
            if type == "" then
                DebugError(string.format("Could not find upgrade type for the equipment ware: '%s'. Check the ware tags.", entry.ware))
            else
                if menu.planDATA.upgradewares[type] then
                    table.insert(menu.planDATA.upgradewares[type], entry)
                else
                    menu.planDATA.upgradewares[type] = { entry }
                end
            end
        end
    end

    -- Signals
    menu.signals = {}
    local numsignals = C.GetNumAllSignals()
    local allsignals = ffi.new("SignalInfo[?]", numsignals)
    numsignals = C.GetAllSignals(allsignals, numsignals)
    for i = 0, numsignals - 1 do
        local signalid = ffi.string(allsignals[i].id)
        table.insert(menu.signals, {id = signalid, name = ffi.string(allsignals[i].name), description = ffi.string(allsignals[i].description), defaultresponse = ffi.string(allsignals[i].defaultresponse), responses = {} })
    
        local numresponses = C.GetNumAllResponsesToSignal(signalid)
        local allresponses = ffi.new("ResponseInfo[?]", numresponses)
        numresponses = C.GetAllResponsesToSignal(allresponses, numresponses, signalid)
        for j = 0, numresponses - 1 do
            table.insert(menu.signals[#menu.signals].responses, {id = ffi.string(allresponses[j].id), name = ffi.string(allresponses[j].name), description = ffi.string(allresponses[j].description)})
        end
    end
    
end

-- cleanup variables in menu, no need for the menu variable to keep all the data while the menu is not active
function menu.cleanup()
    local xdebug = debug0 and DebugError("cleanup")

    menu.mainFrame = nil
	menu.infoFrame = nil
	--menu.contextFrame = nil

    menu.infoFrameTableMode = config.infoFrameTableMode
    menu.propertySorterType = config.propertySorterType

    menu.mdDataChanged = nil
    menu.RM_Fleets = {}
    menu.RM_FleetRecords = {}
    menu.RM_RebuildCues = {}
    menu.active_stations = {}
    menu.blacklist_stations = {}
    menu.optionsTable_showyards = nil
    menu.optionsTable_showenemy = nil
    menu.optionsTable_showunknown = nil

    menu.isremoverespondwares = nil

    menu.details = {}   -- şimdilik prodce ship owner işlemlerinde kullanıyoruz
    menu.warningShown = nil

    -- Seçilen gemiye ait loadout işlemleri için
    menu.selectedShip = {}      
    menu.shipplan = {}

    menu.editedSettings = {}

    menu.fleets = {}
    menu.fleetcategories = {}
    menu.selectedfleet = nil

    menu.titleTable = {}
    menu.sideBarTable = {}
    menu.fleetTable = {}
    menu.sorterTable = {}
    menu.fleetShipsTable = {}
    menu.rightTable = {}
    menu.bottomTable = {}

    menu.queueupdate = nil
    menu.resetrow = nil

    menu.createInfoFrameRunning = nil
    menu.lastDataCheck = 0
    menu.lastrefresh = 0
    menu.refreshed = nil
    menu.noupdate = nil

	menu.settoprow = nil
	menu.setselectedrow = nil

    menu.shipsTableData = {
        selected = nil,
        settoprow = nil,
        setselectedrow = nil,
        selectedGroup = nil,
    }

    -- settoprow ve setselectedrow için daha genel bir table yapısı oluşturabilirsek tüm layerlardaki bilgileri burdan tajip edebiliriz
    menu.setSelectedRows = {}  -- şimdilik .sidebar için depoluyor, option page deki left table da eklendi
    menu.setTopRows = {}  -- option pagenin left tablası eklendi
    -- layerlardaki table handle lerini wiev create zamanı saklıyoruz
    menu.managerTable_fleet, menu.managerTable_sorter, menu.managerTable_fleetShips, menu.managerTable_right, menu.managerTable_bottom = nil, nil, nil, nil, nil
    menu.optionsTable_Top, menu.optionsTable_Bottom, menu.optionsTable_Left, menu.optionsTable_Right = nil, nil, nil, nil
end


function menu.onShowMenu()
    local xdebug = debug0 and DebugError("onShowMenu")

    playerID = ConvertStringTo64Bit(tostring(C.GetPlayerID()))

    menu.cleanup()

    menu.RM_Fleets = GetNPCBlackboard(playerID, "$RM_Fleets")
    menu.RM_FleetRecords = GetNPCBlackboard(playerID, "$FleetRecords")
    menu.RM_RebuildCues = GetNPCBlackboard(playerID, "$RebuildCues")

    if menu.param[3] then
        menu.selectedfleet = tonumber(menu.param[3])
    end
    if menu.param[4] then
        menu.infoFrameTableMode = menu.param[4]
    end
    menu.colorNormal, menu.colorAlert = config.sColor.statusGreen, config.sColor.statusRed
    if menu.param[5] and type(menu.param[5]) == "table"  then

        menu.editedSettings = menu.param[5]["Editing"]
        menu.defaultSettings = menu.param[5]["Default"]

        -- MD dosyalarındaki; true LUA ya geldiğinde 1, false ise 0 olarak geliyor. Lua için düzenlenmeli.
        menu.editedSettings.shownotification = (menu.param[5]["Editing"].shownotification == 1) and true or false
        menu.editedSettings.showhelp = (menu.param[5]["Editing"].showhelp == 1) and true or false
        menu.editedSettings.write_to_logbook = (menu.param[5]["Editing"].write_to_logbook == 1) and true or false
        menu.editedSettings.UsePlayerYards = (menu.param[5]["Editing"].UsePlayerYards == 1) and true or false
        menu.editedSettings.UseNPCYards = (menu.param[5]["Editing"].UseNPCYards == 1) and true or false
        menu.editedSettings.ValidUpdates.PYards.equipments = (menu.param[5]["Editing"].ValidUpdates.PYards.equipments == 1) and true or false
        menu.editedSettings.ValidUpdates.PYards.peoples = (menu.param[5]["Editing"].ValidUpdates.PYards.peoples == 1) and true or false
        menu.editedSettings.ValidUpdates.NYards.equipments = (menu.param[5]["Editing"].ValidUpdates.NYards.equipments == 1) and true or false
        menu.editedSettings.ValidUpdates.NYards.peoples = (menu.param[5]["Editing"].ValidUpdates.NYards.peoples == 1) and true or false
        menu.editedSettings.DebugFileDetail_Fleets = (menu.param[5]["Editing"].DebugFileDetail_Fleets == 1) and true or false
        menu.editedSettings.DebugFileDetail_Records = (menu.param[5]["Editing"].DebugFileDetail_Records == 1) and true or false
        for key, value in pairs(menu.editedSettings.failcases) do
            menu.editedSettings.failcases[key].check = menu.editedSettings.failcases[key].check == 1
        end
        


        menu.defaultSettings.shownotification = (menu.param[5]["Default"].shownotification == 1) and true or false
        menu.defaultSettings.showhelp = (menu.param[5]["Default"].showhelp == 1) and true or false
        menu.defaultSettings.write_to_logbook = (menu.param[5]["Default"].write_to_logbook == 1) and true or false
        menu.defaultSettings.UsePlayerYards = (menu.param[5]["Default"].UsePlayerYards == 1) and true or false
        menu.defaultSettings.UseNPCYards = (menu.param[5]["Default"].UseNPCYards == 1) and true or false
        menu.defaultSettings.ValidUpdates.PYards.equipments = (menu.param[5]["Default"].ValidUpdates.PYards.equipments == 1) and true or false
        menu.defaultSettings.ValidUpdates.PYards.peoples = (menu.param[5]["Default"].ValidUpdates.PYards.peoples == 1) and true or false
        menu.defaultSettings.ValidUpdates.NYards.equipments = (menu.param[5]["Default"].ValidUpdates.NYards.equipments == 1) and true or false
        menu.defaultSettings.ValidUpdates.NYards.peoples = (menu.param[5]["Default"].ValidUpdates.NYards.peoples == 1) and true or false
        menu.defaultSettings.DebugFileDetail_Fleets = (menu.param[5]["Default"].DebugFileDetail_Fleets == 1) and true or false
        menu.defaultSettings.DebugFileDetail_Records = (menu.param[5]["Default"].DebugFileDetail_Records == 1) and true or false
        for key, value in pairs(menu.defaultSettings.failcases) do
            menu.defaultSettings.failcases[key].check = menu.defaultSettings.failcases[key].check == 1
        end


        menu.colorNormal = menu.HexToColor(menu.editedSettings.normalColor)
        menu.colorAlert = menu.HexToColor(menu.editedSettings.alertColor)


    end
    
    menu.active_stations = GetNPCBlackboard(playerID, "$active_stations") or {}
    menu.blacklist_stations = GetNPCBlackboard(playerID, "$blacklist_stations") or {}
    --menu.tablePrint(menu.blacklist_stations, "DATA LOADED .blacklist_stations (" .. tostring(#menu.blacklist_stations) .. ") = ", true, true)

    menu.setdefaulttable = false

    -- (conversation menusünün altında kalıyor)
    -- Pencereyi negatif daralt 
    local nWidth, nHeight = 200, 130
    -- Pencereyi negatif kaydır 
    local nPosX , nPosY = 0, 200

    menu.viewWidth = math.floor(Helper.viewWidth * 6 / 7)  - nWidth
    menu.viewHeight = math.ceil(Helper.viewHeight * 4 / 5) - nHeight
    
    local PosX = math.floor((Helper.viewWidth - menu.viewWidth) / 2)  - nPosX
    local PosX = (PosX > 0 ) and PosX or 0
    local PosY = math.floor((Helper.viewHeight - menu.viewHeight) / 2)  - nPosY
    local PosY = (PosY > 0 ) and PosY or 0

    menu.borderOffsetX = PosX
	menu.borderOffsetY = PosY

	menu.sideBarWidth = Helper.sidebarWidth -- Helper.scaleX(40)
    menu.sideBarOffsetX = 0
	menu.sideBarOffsetY = 0

    menu.infoTableOffsetX = menu.borderOffsetX +  menu.sideBarWidth  + 2 * Helper.borderSize
    menu.infoTableWidth = menu.viewWidth - menu.sideBarWidth  - 4 * Helper.borderSize
    

    -- add content
    menu.display()

    local strDebug = string.format([[ Main & Info Frames
            Helper.viewWidth    : %s    Helper.viewHeight   : %s
            menu.borderOffsetX  : %s    menu.viewWidth      : %s
            menu.borderOffsetY  : %s    menu.viewHeight     : %s
            menu.sideBarOffsetX : %s    menu.sideBarWidth   : %s     
            Helper.borderSize   : %s

            menu.infoTableOffsetX : %s  menu.infoTableWidth : %s    ]],
        Helper.viewWidth,Helper.viewHeight,
        
        menu.borderOffsetX, menu.viewWidth,
        menu.borderOffsetY, menu.viewHeight,
        menu.sideBarOffsetX, menu.sideBarWidth, 
        Helper.borderSize,
        menu.infoTableOffsetX, menu.infoTableWidth
        )
    if debugWProps then DebugError(strDebug) end

end

function menu.Get_mdData()
    -- SetNPCBlackboard(playerID, "$md_RFM_DataChanged", false)
    menu.lastDataCheck = getElapsedTime()

    local isMdDataChanged = tonumber(GetNPCBlackboard(playerID, "$md_RFM_DataChanged")) == 1 and true or false
    local xdebug = debugGetData and DebugError("isMdDataChanged = " .. tostring(isMdDataChanged))
    if isMdDataChanged then
        
        local xdebug = debug0 and DebugError("MdDataChanged = " .. tostring(isMdDataChanged))
        
        menu.RM_Fleets = GetNPCBlackboard(playerID, "$RM_Fleets")
        
        menu.RM_FleetRecords = GetNPCBlackboard(playerID, "$FleetRecords")
        
        menu.RM_RebuildCues = GetNPCBlackboard(playerID, "$RebuildCues")
        
        menu.mdDataChanged = true
        
    end

end
function menu.initDataFromMdData()
    -- DebugError("mdRFMData : " .. tostring(menu.mdRFMData) .. " mdRBCData : ".. tostring(menu.mdRBCData) .. " mdFRData : ".. tostring(menu.mdFleetRecs))

    menu.fleets = {}
    --menu.tablePrint(menu.RM_Fleets[23], " menu.RM_Fleets = " , true, true)
    --menu.tablePrint(menu.RM_FleetRecords[23] , " menu.RM_FleetRecords[menu.selectedfleet] " , true, true)

    for RFMKey, entry in pairs(menu.RM_Fleets) do
        local data = menu.tablecopy(entry)
        --menu.tablePrint(menu.RM_FleetRecords[RFMKey])
        data.name = data.name or ""
        data.isStation =  (tonumber(data.isStation) == 1)   --(data.isStation == 1 or data.isStation == true) and true or false
        data.isShip = not data.isStation
        data.isLockedFleet = (tonumber(data.isLockedFleet) == 1)  --(data.isLockedFleet == 1 or data.isLockedFleet == true) and true or false
        data.autobuild = (tonumber(data.autobuild) == 1)

        local object64 = ConvertStringTo64Bit(tostring(data.commander.object))
        data.commander.idcode = (tonumber(object64) == 0) and "" or ffi.string(C.GetObjectIDCode(object64))

        object64 = ConvertStringTo64Bit(tostring(data.object))
        local isvalid = IsValidComponent(object64)
        data.idcode = (tonumber(object64) == 0) and "" or ffi.string(C.GetObjectIDCode(object64))
        
        --DebugError("RFMKey = " .. tostring(RFMKey) .. " , data.commander.idcode = " .. tostring(data.commander.idcode) ..  " , data.idcode = " .. tostring(data.idcode) .. " object64 = " .. tostring(object64) .. " , isvalid = " .. tostring(isvalid) .. " , data.shipid = " .. tostring(data.shipid)  )

        data.class = (tonumber(object64)  == 0) and menu.RM_FleetRecords[RFMKey][1].class or menu.RM_FleetRecords[RFMKey][data.shipid].class
        data.purpose = (tonumber(object64) == 0) and menu.RM_FleetRecords[RFMKey][1].purpose or menu.RM_FleetRecords[RFMKey][data.shipid].purpose

        --local class = ffi.string(C.GetComponentClass(object64))
        data.locationtext = object64 == 0 and data.sector or GetComponentData(object64, "sector")
        data.isdocked = false
        if object64 ~= 0 then
            data.isdocked = GetComponentData(object64, "isdocked")
        end
        --DebugError(string.format("id = %s , data.object = %s ,  object64 = %s", data.id, data.object, object64) )

        if object64 == 0 then
            data.icon = menu.RM_FleetRecords[RFMKey][1].icon
        else
            if C.IsComponentClass(object64, "ship") then
                data.icon = menu.RM_FleetRecords[RFMKey][data.shipid].icon
            else
                data.icon = GetComponentData(object64, "icon")
                if data.icon == "" then
                    data.icon = "maptr_hexagon"
                end
            end
        end
        data.color =  menu.HexToColor(data.alertstatus.color) 
        
        table.insert(menu.fleets, data )
    end

    table.sort(menu.fleets, menu.componentSorter(menu.propertySorterType))
    
    if debugDataDeep then
        local strDebug = ""
        for idx, fleet in pairs(menu.fleets) do
            strDebug = string.format([[
                RFMKey    : %s (listTable indx = %s)
                Promoted    : %s %s ( %s )
                Commander : %s ( %s )
                Sector     : %s ( current location = %s )
                class        : %s 
                purpose   : %s
                isStation  : %s
                isLocked  : %s
                DestroyedShips Count  : %s]]
                ,
                fleet.id, idx,
                fleet.name, fleet.idcode, fleet.object,
                fleet.commander.name, fleet.commander.object,
                fleet.sector, fleet.locationtext,
                fleet.class, fleet.purpose,
                fleet.isStation, fleet.isLockedFleet, #fleet.destroyedShipKeys
                )
            DebugError(strDebug)
        end
        
        DebugError("Total fleets  = " .. tostring(#menu.fleets) )
    end


    local shipfleets = {}
    local stationfleets = {}
    local dShips, dStations = "[", "["
    for indx , fleet in pairs(menu.fleets) do
        if fleet.isStation then
            dStations =  dStations .. "(" .. indx .. ")=" .. tostring(fleet.id) .. ","
            table.insert(stationfleets, fleet.id)
        else
            dShips =  dShips .. "(" .. indx .. ")=" .. tostring(fleet.id) .. ","
            table.insert(shipfleets, fleet.id)
        end
    end
    dShips = dShips .. "]"
    dStations = dStations .. "]"
    local xdebug = debugData and DebugError(string.format(" Ships = %s , Stations = %s ", dShips, dStations) )

    -- ayrılan fleetleri kategori listelerine dönüştürüyoruz
    menu.fleetcategories = {}
    if #shipfleets > 0 then
        table.insert(menu.fleetcategories, {
            name = "Ship Fleets",
            id = "shipfleets",
            fleetkeys = shipfleets
        }) -- Ship Fleets
    end
    if #stationfleets > 0 then
        table.insert(menu.fleetcategories, {
            name = "Station Fleets",
            id = "stationfleets",
            fleetkeys = stationfleets
        }) -- Station Fleets
    end

    if debugData then
        for _, data in ipairs(menu.fleetcategories) do
            DebugError("fleetcategories.name = " .. tostring(data.name) .. ",  fleetcategories.fleetkeys count = " .. tostring(#data.fleetkeys)  )
        end
    end

    local xdebug = debug2 and DebugError("initData  END")

end

function menu.display()

    -- frame:addTable  	açılmış frameye tablo ekler (kaç sütunlu olacağı burada bbelirlenir)
    -- table:addRow  	açılmış tabloya yeni bir satır ekler
    -- row[x]			oluşturulan (x tablo sütununa göre değerlendirilir) satır bilgisine özellik ekler

    -- create main frames  daha sonra birden fazla tablo için kullanabiliriz

    menu.lastrefresh = getElapsedTime()

    menu.createMainFrame()
    menu.createInfoFrame()

    menu.mdDataChanged = nil
    SetNPCBlackboard(playerID, "$md_RFM_DataChanged", false)

    local xdebug = debug0 and DebugError("display END")
end


function menu.createMainFrame()
	menu.createMainFrameRunning = true
	-- remove old data
	Helper.removeAllWidgetScripts(menu, config.mainLayer)

	menu.mainFrame = Helper.createFrameHandle(menu, {
		layer = config.mainLayer,
		width = menu.viewWidth ,
		height = menu.viewHeight,
		x = menu.borderOffsetX,
		y = menu.borderOffsetY,
	})

    -- sideBar, önce bunu yazalım,  menu.viewCreated içinde mainFrame için ilk layeri sideBarTableID e atıyoruz
    menu.sideBarTable = menu.createSideBar(menu.mainFrame)
    -- TopTittle
    menu.titleTable = menu.createTopTittleTable(menu.mainFrame)

    menu.mainFrame:setBackground("solid", { color = not debugColorMod and config.sColor.transparent or config.sColor.semitransparent })    -- 7.00 da

    menu.sideBarTable.properties.y = menu.titleTable:getFullHeight() + menu.titleTable.properties.y

    menu.infoTableHeight = menu.viewHeight - menu.titleTable:getFullHeight() - 3 * Helper.borderSize
    menu.infoTableOffsetY = menu.borderOffsetY + menu.titleTable.properties.y + menu.titleTable:getFullHeight() + Helper.borderSize

	menu.mainFrame:display()

    local xdebug = debug0 and DebugError("createMainFrame  :display")
end
function menu.createTopTittleTable(frame)
    --
    -- TITTLE TABLE
    --
    local row, ftable
    ftable = frame:addTable(1, { 
        skipTabChange = true,
      } )

    ftable:setDefaultCellProperties("text", { 
        halign = "center",
        font = Helper.titleFont,
        fontsize = 12,
    } )

    row = ftable:addRow(nil , { bgColor = config.Color.row_title_background }  )
    row[1]:createText(menu.title, {} )


    return ftable
end
function menu.createSideBar(frame)
	local spacingHeight = menu.sideBarWidth / 4
	local defaultInteractiveObject = false
	local ftable = frame:addTable(1, { 
        tabOrder = 3, 
        x = menu.sideBarOffsetX, 
        y = menu.sideBarOffsetY, 
        width = menu.sideBarWidth, 
        scaling = false, borderEnabled = false, reserveScrollBar = false, defaultInteractiveObject = defaultInteractiveObject 
    })

	local foundselection
	local leftbar = config.leftBar

	for idx, entry in ipairs(leftbar) do
		if (entry.condition == nil) or entry.condition() then
			if entry.spacing then
                if next(leftbar,idx) then
                    if leftbar[next(leftbar,idx)].mode == "cheats" and not debugCheat then
                    else
                        local row = ftable:addRow(false, { fixed = true })
                        row[1]:createIcon("mapst_seperator_line", { width = menu.sideBarWidth, height = spacingHeight })
                    end
                end
			else
				local mode = entry.mode
				local row = ftable:addRow(true, { fixed = true })
				local bgcolor = config.Color["row_title_background"]
                if entry.mode == menu.infoFrameTableMode then
                    bgcolor = config.Color["row_background_selected"]
                end
				local color = config.sColor.white   -- config.Color["icon_normal"]
                
				if mode == 'cheats' and not debugCheat then 
                
                else 
                    row[1]:createButton({ active = true, height = menu.sideBarWidth, bgColor = bgcolor, mouseOverText = entry.name, helpOverlayID = entry.helpOverlayID, helpOverlayText = entry.helpOverlayText }):setIcon(entry.icon, { color = color })
                    row[1].handlers.onClick = function () return menu.buttonToggleObjectList(mode) end
                end                    
			end
		end
	end

	ftable:setSelectedRow(menu.setSelectedRows.sideBar)
	menu.setSelectedRows.sideBar = nil

    return ftable
end
function menu.buttonToggleObjectList(objectlistparam)
    local oldidx, newidx
    local leftbar = config.leftBar
    local count = 1
	for _, entry in ipairs(leftbar) do
		if (entry.condition == nil) or entry.condition() then
			if entry.mode then
                if entry.mode == menu.infoFrameTableMode then
                    oldidx = count
                end
                if entry.mode == objectlistparam then
                    newidx = count
                end
            end
			count = count + 1
		end
		if oldidx and newidx then
			break
		end
    end

	if newidx then
		Helper.updateButtonColor(menu.sideBarTableID, newidx, 1, config.Color.row_background_selected)
	end
	if oldidx then
		Helper.updateButtonColor(menu.sideBarTableID, oldidx, 1, config.Color.button_background_default)
	end
    
    menu.createInfoFrameRunning = true

    --AddUITriggeredEvent(menu.name, objectlistparam, menu.infoFrameTableMode == objectlistparam and "off" or "on")

    menu.infoFrameTableMode = objectlistparam
    if newidx then
        SelectRow(menu.sideBarTableID, newidx)
    end

    menu.refreshMainFrame = true
    menu.setdefaulttable = true
	menu.createInfoFrame()

end

function menu.createInfoFrame()
    menu.createInfoFrameRunning = true
    menu.refreshed = true
    menu.noupdate = false

	-- remove old data
	Helper.clearDataForRefresh(menu, config.infoLayer)

	local frameProperties = {
        width = menu.infoTableWidth ,
        height = menu.infoTableHeight,
        x = menu.infoTableOffsetX,
        y = menu.infoTableOffsetY,
		standardButtons = {},
		layer = config.infoLayer,
	}
    -- Pencere
    menu.infoFrame = Helper.createFrameHandle(menu, frameProperties)
    menu.infoFrame:setBackground("solid", { color = not debugColorMod and config.sColor.semitransparent or config.sColor.available })    -- 7.00 da


    if (menu.infoFrameTableMode == "cheats") then
        menu.createCheatTable(menu.infoFrame)
    elseif (menu.infoFrameTableMode == "options") then
        menu.createOptionsTable(menu.infoFrame)
    else -- (menu.propertyMode == "manager") 
        menu.createManagerTables(menu.infoFrame)
    end

    menu.infoFrame:display()

    local strDebug = string.format([[ 
            .infoFrame.id       : %s
            .fleetTable.id      : %s
            .sorterTable.id     : %s
            .fleetShipsTable.id : %s
            .rightTable.id      : %s
            .bottomTable.id     : %s
            ]],
            menu.infoFrame.id, menu.fleetTable.id, menu.sorterTable.id, menu.fleetShipsTable.id, menu.rightTable.id, menu.bottomTable.id
        )
    if debugWProps then DebugError(strDebug) end

    local xdebug = debug0 and DebugError("createInfoFrame  :display")
end

function menu.createCheatTable(frame)
	-- (cheat only)
	local cheats = {
		[1] = {
			name = "Enable All Cheats",
			info = "Reveal stations, encyclopedia, map, research and adds money and seta.",
			callback = C.EnableAllCheats,
			shortcut = {"action", 290}, -- INPUT_ACTION_DEBUG_FEATURE_3
		},
		[2] = {
			name = "Reveal map",
			callback = C.RevealMap,
		},
		[3] = {
			name = "Reveal stations",
			callback = C.RevealStations,
		},
		[4] = {
			name = "Cheat 1bn Credits",
			callback = function () return C.AddPlayerMoney(100000000000) end,
		},
		[5] = {
			name = "Cheat SETA",
			callback = function () return AddInventory(nil, "inv_timewarp", 1) end,
		},
		[6] = {
			name = "Reveal encyclopedia",
			info = "Also reveals the map and completes all research.",
			callback = C.RevealEncyclopedia,
		},
		[7] = {
			name = "Spawn CVs",
			section = "gDebug_deployCVs",
		},
		[8] = {
			name = "Fill nearby Build Storages",
			section = "gDebug_station_buildresources",
		},
		[9] = {
			name = "Inc Crew skill",
			section = "gDebug_crewskill",
		},
		[10] = {
			name = "Open Flowchart Test",
			menu = "StationOverviewMenu",
		},
		[11] = {
			name = "Cheat All Research",
			callback = menu.cheatAllResearch,
		},
		[12] = {
			name = "Cheat Docking Traffic",
			sectionparam = C.CheatDockingTraffic,
			shortcut = {"action", 291}, -- INPUT_ACTION_DEBUG_FEATURE_4
		},
		[13] = {
			name = "Cheat Live Stream View Channels",
			info = "Makes all faction channels available in Live Stream View.",
			callback = C.CheatLiveStreamViewChannels,
		},
	}

	local ftable = frame:addTable(1 , { tabOrder = 1 })
	--ftable:addConnection(1, 2, true)
	ftable:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
	ftable:setDefaultCellProperties("button", { height = config.mapRowHeight })
	ftable:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })

	local row = ftable:addRow(false, { fixed = true, bgColor = config.Color.row_title_background })
	row[1]:createText("Cheats", Helper.headerRowCenteredProperties)

	for _, cheat in ipairs(cheats) do
		local row = ftable:addRow(true, {  })
		local shortcut = ""
		if cheat.shortcut then
			shortcut = Helper.formatOptionalShortcut(" \27A(%s)", cheat.shortcut[1], cheat.shortcut[2])
		end
		row[1]:createButton({ mouseOverText = cheat.info or "" }):setText(cheat.name .. shortcut)
		if cheat.callback then
			row[1].handlers.onClick = function () return cheat.callback() end
		elseif cheat.menu then
			row[1].handlers.onClick = function () Helper.closeMenuAndOpenNewMenu(menu, cheat.menu, {0, 0}) menu.cleanup() end
		elseif cheat.section then
			row[1].handlers.onClick = function () Helper.closeMenuForNewConversation(menu, cheat.section, ConvertStringToLuaID(tostring(C.GetPlayerComputerID())), nil, true) menu.cleanup() end
		end
	end

end

function menu.createOptionsTable(frame)

    local row, topTable

    local usableX = Helper.borderSize  
    local usablewidth = frame.properties.width - 2 * Helper.borderSize

    topTable = frame:addTable(10, {
        tabOrder = 0,
        borderEnabled = true,
        x = usableX,
        y = Helper.borderSize,  -- * tablenin 4 kenarına ait kendi borderları da var
        width = usablewidth,
        skipTabChange = true,
    })
   
    topTable.properties.backgroundID = not debugColorMod and "" or "solid"   
    topTable.properties.backgroundColor = not debugColorMod and config.Color["frame_background_semitransparent"] or config.sColor.blue    
    
	-- title
	local row = topTable:addRow(nil, { fixed = false, bgColor = config.Color.row_title_background })
	row[1]:setColSpan(10):createText("Options", Helper.headerRowCenteredProperties)
    row[1].properties.fontsize = 11

    local xdebug = debugWProps and DebugError("(frame.properties.width / 2) " .. tostring((frame.properties.width / 2)) .. " Helper.borderSize " .. tostring(Helper.borderSize) )
    local strDebug = string.format([[ Top Table
            topTable.properties.x : %s        topTable.properties.width    : %s
            topTable.properties.y : %s        topTable.properties.height   : %s
            topTable.properties.maxVisibleHeight : %s        topTable:getFullHeight()    : %s  ]],
            topTable.properties.x, topTable.properties.width,
            topTable.properties.y, topTable.properties.height,
            topTable.properties.maxVisibleHeight, topTable:getFullHeight()
        )
    if debugWProps then DebugError(strDebug) end
    
    menu.Settings_RowFormat(frame, topTable.properties.x, topTable.properties.y + topTable:getFullHeight(), usablewidth )
    
end
function menu.Settings_RowFormat(frame, offsetX, offsetY, width)
    local row

	local offset = 1 * Helper.borderSize
    local font, fontsize = Helper.standardFont, Helper.standardFontSize
    local map_fontsize = 9
    local map_textheight = math.ceil(C.GetTextHeight("Y", font, Helper.scaleFont(font, map_fontsize), Helper.viewWidth)) + 2 * offset
    local buttonHeight = Helper.standardTextHeight * 2

    local bottomTable = frame:addTable(7, {
        tabOrder = 3,
        x = offsetX ,
        y = frame.properties.height - buttonHeight - Helper.borderSize  ,
        width = width ,
        borderEnabled = true,
    })
    
    bottomTable.properties.backgroundID = not debugColorMod and "" or "solid"   
    bottomTable.properties.backgroundColor = not debugColorMod and config.Color["frame_background_semitransparent"] or config.sColor.orange

    local fixed = false

    row = bottomTable:addRow(true, { fixed = true, bgColor = config.sColor.transparent } )
    row[4]:createButton({ height = buttonHeight  }):setText("Restore Default Settings", { halign = "center" })
    row[4].handlers.onClick = menu.buttonRestoreDefault
    


    local subHeaderTextProperties = {
        halign = "center",
	    fontsize = 10,
	    cellBGColor = { r = 0, g = 0, b = 0, a = 0 },
	    titleColor = config.sColor.cyan
    }
    local subHeaderLeftTextProperties = {
        halign = "left",
	    fontsize = map_fontsize,
	    cellBGColor = { r = 0, g = 0, b = 0, a = 0 },
	    titleColor = config.Color.row_title
    }

    local subLineProperties = {
        fontsize = 1, 
        minRowHeight = 2,
    }
    local subLineTransparentProperties = {
        fontsize = 1, 
        minRowHeight = 2,
        cellBGColor = { r = 0, g = 0, b = 0, a = 0 },
    }

    
    -- Satır Ekle -  Kontrol bars
    --row = ftable:addRow(nil, { bgColor = config.sColor.orange })
    --row[1]:setColSpan(1):createText("", subLineProperties)

    --  
    local bltable
    local stationstable

    bltable = frame:addTable(13, { tabOrder = 1, width = ((width - (2 * Helper.borderSize )) / 2), x = offsetX, y = offsetY + 2 * Helper.borderSize, reserveScrollBar = true, skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })

    -- property tablar arasında geçiş yaptığımızda default table belirliyoruz
    -- çünkü her tab aynı tableleri içermiyor
    if menu.setdefaulttable then
        bltable.properties.defaultInteractiveObject = true   
        menu.setdefaulttable = nil
    end

    menu.optionsTable_showyards = menu.optionsTable_showyards or false
    row = bltable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(1):createCheckBox(function () return menu.optionsTable_showyards end, { width = map_textheight, height = map_textheight })
    row[2].handlers.onClick = function () menu.optionsTable_showyards = not menu.optionsTable_showyards; menu.refreshInfoFrame(); end
    row[3]:setColSpan(3):createText("Show Blacklist Yards", { mouseOverText = "Show stations list.", fontsize = map_fontsize })
    --

    local listfonstize = 11
    local listTextHeight = math.ceil(C.GetTextHeight("K", font, Helper.scaleFont(font, listfonstize), Helper.viewWidth)) + 2 * offset
    menu.activestations = {}
    for _,as in ipairs(menu.active_stations) do
        local entry = {}
        entry.object = as.object
        entry.name = as.name
        entry.sector = as.sector
        entry.object64 = ConvertStringTo64Bit(tostring(entry.object))
        entry.idcode = ffi.string(C.GetObjectIDCode(entry.object64))
        entry.macro, entry.faction, entry.sectorid = GetComponentData(entry.object64, "macro", "owner", "sectorid" )
        entry.factioncolor = GetFactionData(entry.faction, "color")
        entry.sectorowner = GetComponentData(entry.sectorid, "owner")
        entry.sectorownercolor = GetFactionData(entry.sectorowner, "color")
        entry.isplayerowned, entry.icon, entry.isenemy, entry.ishostile, entry.uirelation = GetComponentData(entry.object64, "isplayerowned", "icon", "isenemy", "ishostile", "uirelation")
        entry.isshipyard, entry.iswharf = GetComponentData(entry.object64, "isshipyard", "iswharf")
        entry.macroname = GetMacroData(entry.macro, "name")
        entry.isknownsector = C.IsKnownToPlayer(ConvertStringTo64Bit(tostring(entry.sectorid)))
        entry.isknown = C.IsKnownToPlayer(entry.object64)
        entry.islocked = false
        if (not entry.isknown) or entry.isenemy or entry.ishostile then
            entry.islocked = true
        end
        entry.selected = menu.checkInBlacklist(entry.object64)
        table.insert(menu.activestations , entry)
    end
    table.sort(menu.activestations, menu.componentSorter("name"))

    local stationsvisibleHeight = nil
    local maxrows = 12
    local totalrows = 0

    if menu.optionsTable_showyards then
        menu.optionsTable_showenemy = menu.optionsTable_showenemy or false
        menu.optionsTable_showunknown = menu.optionsTable_showunknown or false
    
        row = bltable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
        row[5]:setColSpan(1):createCheckBox(menu.optionsTable_showenemy , { width = map_textheight, height = map_textheight })
        row[5].handlers.onClick = function () menu.optionsTable_showenemy = not menu.optionsTable_showenemy; menu.refreshInfoFrame(); end
        row[6]:setColSpan(3):createText("Show Enemy or Hostile", { mouseOverText = "Show stations with restricted docking permission in the list.", fontsize = map_fontsize })
        
        row[9]:setColSpan(1):createCheckBox(menu.optionsTable_showunknown , { width = map_textheight, height = map_textheight })
        row[9].handlers.onClick = function (_, checked) menu.optionsTable_showunknown = checked; menu.refreshInfoFrame(); end
        row[10]:setColSpan(3):createText("Show Unknown", { mouseOverText = "show unknown stations in list.", fontsize = map_fontsize })

        row = bltable:addRow(nil, { bgColor = config.sColor.white })
        row[1]:setColSpan(1):createText("", subLineTransparentProperties)
        row[2]:setColSpan(11):createText(" ", subHeaderTextProperties)
        row[2].properties.titleColor = config.Color.text_inactive
        row[13]:setColSpan(1):createText("", subLineTransparentProperties)

        -- Marked stations will not be taken into account in station searches for ship production
        row = bltable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent } )
        row[2]:setColSpan(11):createText("Marked stations will be ignored for ship production", subHeaderTextProperties )
        row[2].properties.color = config.Color.text_warning
        row[2].properties.titleColor = config.Color.text_inactive

        row = bltable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent } )
        row[2]:setColSpan(7):createText("Stations", subHeaderTextProperties )
        row[9]:setColSpan(4):createText("Sector", subHeaderTextProperties )

        if #menu.activestations then
            
            stationstable = frame:addTable(13, { tabOrder = 8, width = ((width - (2 * Helper.borderSize )) / 2), x = offsetX, y = 0, reserveScrollBar = true, highlightMode = "off", skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })

            for k,entry in ipairs(menu.activestations) do

                local show = false
                if ((not entry.isknown) and menu.optionsTable_showunknown) then
                    show = true
                elseif (((entry.isenemy or entry.ishostile) and menu.optionsTable_showenemy )) and entry.isknown then 
                    show = true
                elseif entry.isknown and not entry.isenemy and not entry.ishostile then
                    show = true
                end
                if show then
                    totalrows = totalrows + 1

                    local unknowntext = Helper.convertColorToText(config.sColor.lightgrey) .. " Unknown "
                    local name = entry.name 
                    local coloredicon = string.format("%s\027[%s]", Helper.convertColorToText(entry.factioncolor), entry.icon) 
                    local coloredname = string.format("%s%s", Helper.convertColorToText(entry.factioncolor), name) 
                    local nameUnknownText = entry.isknown and "" or unknowntext
                    local ColoredIconName = string.format("%s%s%s ( %s )",coloredicon, nameUnknownText, coloredname, entry.idcode )
    
                    local sectorUnknownText = entry.isknownsector and "" or unknowntext
                    local ColoredSectorName = string.format("%s%s%s", sectorUnknownText, Helper.convertColorToText(entry.sectorownercolor), entry.sector )
    
    
                    row = stationstable:addRow(entry.object64, { fixed = fixed, bgColor = config.sColor.transparent80 } )
                    row[2]:setColSpan(1):createCheckBox( entry.selected , { active = not entry.islocked, width = listTextHeight , height = listTextHeight })
                    row[2].handlers.onClick = function(_, checked)
                        menu.checkbox_blacklist(checked, entry.object64)
                    end
                    row[3]:setColSpan(6):createText(ColoredIconName , { mouseOverText = "", fontsize = listfonstize, height = listTextHeight })
                    row[9]:setColSpan(4):createText(ColoredSectorName , { mouseOverText = "", fontsize = listfonstize - 1, height = listTextHeight })
    
                    if totalrows == maxrows then
                        stationsvisibleHeight = stationstable:getFullHeight()
                    end
                end
            end

            if stationsvisibleHeight then
                stationstable.properties.maxVisibleHeight = stationsvisibleHeight
            else
                stationstable.properties.maxVisibleHeight = stationstable:getFullHeight()
            end
            stationstable.properties.y = bltable.properties.y + bltable:getFullHeight()

        end
        
    end
    

    local leftTable = frame:addTable(13, {
        tabOrder = 2,
        x = offsetX ,
        width = ((width - (2 * Helper.borderSize )) / 2),
        borderEnabled = true,
    })
    local ftable = leftTable

    ftable.properties.backgroundID = not debugColorMod and "" or "solid"   
    ftable.properties.backgroundColor = not debugColorMod and config.Color["frame_background_semitransparent"] or config.sColor.checkboxgroup
    

    ftable:setColWidth(1, map_textheight / 2)
    
    ftable:setColWidth(2, map_textheight)
    ftable:setColWidth(5, map_textheight)

    ftable:setColWidth(9, map_textheight)
    ftable:setColWidth(11, map_textheight)

    ftable:setColWidth(13, map_textheight / 2)


    ftable:addEmptyRow(2*Helper.borderSize)
    -- ----------------------------------

    -- ----------------------------------
    row = ftable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(11):createText("Production Stations", subHeaderTextProperties)
    -- ----------------------------------
    --  UsePlayerYards
    row = ftable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(3):createText("Player Yards " , { mouseOverText = "Player shipyards will be checked first for the production of destroyed ships.", fontsize = map_fontsize })
    row[5]:setColSpan(1):createCheckBox(menu.editedSettings.UsePlayerYards, { width = map_textheight, height = map_textheight })
    row[5].handlers.onClick = menu.checkbox_UsePlayerYards
    --  UseNPCYards
    row[8]:setColSpan(3):createText("NPC Yards", { mouseOverText = "NPC shipyards will be included for the production of destroyed ships.", fontsize = map_fontsize })
    row[11]:setColSpan(1):createCheckBox(menu.editedSettings.UseNPCYards, { width = map_textheight, height = map_textheight })
    row[11].handlers.onClick = menu.checkbox_UseNPCYards

    -- ----------------------------------
    ftable:addEmptyRow()


    -- Satır Ekle -  Kontrol bars
    --row = ftable:addRow(nil, { bgColor = config.sColor.orange })
    --row[1]:setColSpan(1):createText("", subLineProperties)

    row = ftable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(11):createText("Valid Updates for Ship Loadout Records", subHeaderTextProperties)
    -- ----------------------------------
    row = ftable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(5):createText("Player Yards", subHeaderLeftTextProperties)
    row[8]:setColSpan(5):createText("NPC Yards", subHeaderLeftTextProperties)
    -- ----------------------------------
    row = ftable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[3]:setColSpan(2):createText("Equipments", { mouseOverText = "It updates the ship's changing 'equipments record' during equipment change or repair at a supply player station.", fontsize = map_fontsize })
    row[5]:setColSpan(1):createCheckBox(menu.editedSettings.ValidUpdates.PYards.equipments , { width = map_textheight, height = map_textheight })
    row[5].handlers.onClick = menu.checkbox_ValidUpdatesPYardsequipments

    row[9]:setColSpan(2):createText("Equipments", { mouseOverText = "It updates the ship's changing 'equipments record' during equipment change or repair at a supply npc station.", fontsize = map_fontsize })
    row[11]:setColSpan(1):createCheckBox(menu.editedSettings.ValidUpdates.NYards.equipments, { width = map_textheight, height = map_textheight })
    row[11].handlers.onClick = menu.checkbox_ValidUpdatesNYardsequipments


    row = ftable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[3]:setColSpan(2):createText("Crew", { mouseOverText = "It updates the ship's changing 'peoples record' during equipment change or repair at a supply player station.", fontsize = map_fontsize })
    row[5]:setColSpan(1):createCheckBox(menu.editedSettings.ValidUpdates.PYards.peoples, { width = map_textheight, height = map_textheight })
    row[5].handlers.onClick = menu.checkbox_ValidUpdatesPYardspeoples

    row[9]:setColSpan(2):createText("Crew", { mouseOverText = "It updates the ship's changing 'peoples record' during equipment change or repair at a supply npc station.", fontsize = map_fontsize })
    row[11]:setColSpan(1):createCheckBox(menu.editedSettings.ValidUpdates.NYards.peoples, { width = map_textheight, height = map_textheight })
    row[11].handlers.onClick = menu.checkbox_ValidUpdatesNYardspeoples

    -- ----------------------------------
    ftable:addEmptyRow()
    -- ----------------------------------

    -- Satır Ekle - Gri ince
    row = ftable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(11):createText("Helper", subHeaderTextProperties)
    -- ----------------------------------
    --  showhelp
    row = ftable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(3):createText("Show Help ", { mouseOverText = "Reports the destroy information of RFM ships on the Show Help popup window.", fontsize = map_fontsize })
    row[5]:setColSpan(1):createCheckBox(menu.editedSettings.showhelp, { width = map_textheight, height = map_textheight })
    row[5].handlers.onClick = menu.checkbox_showhelp
    --  write_to_logbook
    row[8]:setColSpan(3):createText("Write to logbook", { mouseOverText = "RFMs' exploding ships and production result reports will be written in the logbook.", fontsize = map_fontsize })
    row[11]:setColSpan(1):createCheckBox(menu.editedSettings.write_to_logbook, { width = map_textheight, height = map_textheight })
    row[11].handlers.onClick = menu.checkbox_write_to_logbook
    -- ----------------------------------
    ftable:addEmptyRow()


    -- Satır Ekle - Başlık Altı Çizili
    row = ftable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(11):createText("Auto Rebuilds", subHeaderTextProperties)
    -- ----------------------------------
    -- NextRetryTime
    row = ftable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(3):createText("Retry Time", { mouseOverText = "How long will it take for ships that failed to be produced to be attempted again automatically?", fontsize = map_fontsize })
    row[5]:setColSpan(8):createSliderCell({ min = 1, max = 30, step = 1, start = menu.editedSettings.NextRetryTime, suffix = ReadText(1001, 103), height = map_textheight })
    row[5].handlers.onSliderCellConfirm = menu.slidercell_NextRetryTime

    -- MoneyThreshold
    row = ftable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(3):createText("Player Money Threshold", { mouseOverText = "Never rebuild ships which reduces player money below this amount", fontsize = map_fontsize })
    row[5]:setColSpan(8):createSliderCell({ min = 0, max = menu.editedSettings.maxmoney, step = menu.editedSettings.moneystep, start = menu.editedSettings.playermoneythreshold, suffix = ReadText(1001, 101), height = map_textheight })
    row[5].handlers.onSliderCellConfirm = menu.slidercell_playermoneythreshold

    -- MoneyThreshold
    row = ftable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(3):createText("Max Allowed Ship Price", { mouseOverText = "Maximum price allowed for ship production. If the value requested for the ship's production fee at NPC stations exceeds this value, the ship will not be produced.", fontsize = map_fontsize })
    row[5]:setColSpan(8):createSliderCell({ min = 0, max = 9 * menu.editedSettings.maxmoney, step = menu.editedSettings.moneystep, start = menu.editedSettings.maxallowedpricepership, suffix = ReadText(1001, 101), height = map_textheight })
    row[5].handlers.onSliderCellConfirm = menu.slidercell_maxallowedpricepership
    
    -- ----------------------------------
    

    
    leftTable.properties.y = bltable.properties.y + bltable:getFullHeight() + (stationstable and stationstable.properties.maxVisibleHeight or 0) + 2*Helper.borderSize
    leftTable.properties.maxVisibleHeight = bottomTable.properties.y - Helper.borderSize - leftTable.properties.y

    local firstRowindex = 1
    local lastRowindex = 25
    local lastRowindex = lastRowindex - 1 
    --menu.setTopRows.optionsTable_Left = ((not menu.setTopRows.optionsTable_Left) or (menu.setTopRows.optionsTable_Left == 0)) and ((menu.setSelectedRows.optionsTable_Left and menu.setSelectedRows.optionsTable_Left > lastRowindex) and (menu.setSelectedRows.optionsTable_Left - (lastRowindex - firstRowindex) ) or firstRowindex) or menu.setTopRows.optionsTable_Left
    --leftTable:setTopRow(menu.setTopRows.optionsTable_Left)
    --leftTable:setSelectedRow(menu.setSelectedRows.optionsTable_Left)
    --menu.setSelectedRows.optionsTable_Left = nil
    --menu.setTopRows.optionsTable_Left = nil

    -- Satır Ekle -  Kontrol bars
    --row = ftable:addRow(nil, { bgColor = config.sColor.orange })
    --row[1]:setColSpan(1):createText("", subLineProperties)
    -- ----------------------------------

    local rightTable = frame:addTable(8, {
        tabOrder = 3,
        x = leftTable.properties.x  + leftTable.properties.width + Helper.borderSize + Helper.borderSize ,
        y = offsetY + 2 * Helper.borderSize ,
        width = leftTable.properties.width ,
        borderEnabled = true,

    })
    --local ftable = rightTable

    -- Satır Ekle -  Kontrol bars
    --row = rightTable:addRow(nil, { bgColor = config.sColor.orange })
    --row[1]:setColSpan(1):createText("", subLineProperties)

    rightTable.properties.backgroundID = not debugColorMod and "" or "solid"   
    rightTable.properties.backgroundColor = not debugColorMod and config.Color["frame_background_semitransparent"] or config.sColor.darkorange

    -- Satır Ekle - Başlık Altı Çizili
    row = rightTable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(6):createText("Attention!", subHeaderTextProperties)
    row[2].properties.color = config.Color.text_warning
    row[2].properties.titleColor = config.Color.text_inactive
    row = rightTable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(6):createText("  If the game is opened in Debug Mode and the options here are activated;", { color = config.sColor.lightgrey, fontsize = map_fontsize, wordwrap = true } )

    row = rightTable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(6):createText("  Depending on the number of RFMs and the size of the Fleets, the screen may freeze until the logs are written to file.", { color = config.sColor.lightgrey, fontsize = map_fontsize, titleColor = config.Color.text_inactive, wordwrap = true })
    -- ----------------------------------
    rightTable:addEmptyRow()
    -- ----------------------------------
    row = rightTable:addRow(false, { fixed = fixed, bgColor = config.sColor.transparent })
    row[2]:setColSpan(6):createText("Debugs", subHeaderTextProperties)
    -- ----------------------------------
    --  DebugChance
    row = rightTable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(2):createText("Debug Chance", { mouseOverText = "Debug Mod. It is only effective when running the game with debug mod support.", color = config.sColor.lightgrey, fontsize = map_fontsize })
    row[4]:setColSpan(1):createCheckBox(menu.editedSettings.DebugChance == 100 and true or false, { width = map_textheight, height = map_textheight })
    row[4].handlers.onClick = menu.checkbox_DebugChance
    --  DeepDebug
    row = rightTable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(2):createText("Deep Debug", { mouseOverText = "Deep Debug Mod. It is only effective when running the game with debug mod support.", color = config.sColor.lightgrey, fontsize = map_fontsize })
    row[4]:setColSpan(1):createCheckBox(menu.editedSettings.DeepDebug == 100 and true or false, { width = map_textheight, height = map_textheight })
    row[4].handlers.onClick = menu.checkbox_DeepDebug
    --  ChangesOnFleetDebug
    row = rightTable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(2):createText("Changes On Fleet Debug", { mouseOverText = "It displays the changes on the fleet (addition, removal, assigment change, explosion, undock, etc.) in the debug text file. DebugChance must be turned on. It is only effective when running the game with debug mod support.", color = config.sColor.lightgrey, fontsize = map_fontsize })
    row[4]:setColSpan(1):createCheckBox(menu.editedSettings.ChangesOnFleetDebug == 100 and true or false, { width = map_textheight, height = map_textheight })
    row[4].handlers.onClick = menu.checkbox_ChangesOnFleetDebug
    --  FleetLockStatusDebug
    row = rightTable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(2):createText("Fleet Lock Status", { mouseOverText = "It displays the changes on the fleet lock status  in the debug text file. DebugChance must be turned on. It is only effective when running the game with debug mod support.", color = config.sColor.lightgrey, fontsize = map_fontsize })
    row[4]:setColSpan(1):createCheckBox(menu.editedSettings.FleetLockStatusDebug == 100 and true or false, { width = map_textheight, height = map_textheight })
    row[4].handlers.onClick = menu.checkbox_FleetLockStatusDebug
    -- ----------------------------------
    rightTable:addEmptyRow()
    -- ----------------------------------
    --  DebugFileDetail_Fleets
    row = rightTable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(2):createText("Fleet DebugFile Details", { mouseOverText = "Detailed breakdown in RM_Fleets debugfile. DebugChance must be turned on. It is only effective when running the game with debug mod support.", color = config.sColor.lightgrey, fontsize = map_fontsize })
    row[4]:setColSpan(1):createCheckBox(menu.editedSettings.DebugFileDetail_Fleets, { width = map_textheight, height = map_textheight })
    row[4].handlers.onClick = menu.checkbox_DebugFileDetail_Fleets

    --  DebugFileDetail_Records
    row = rightTable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent } )
    row[2]:setColSpan(2):createText("Record DebugFile Details", { mouseOverText = "Detailed breakdown in RM_xx_FleetRecord debugfile. DebugChance must be turned on. It is only effective when running the game with debug mod support.", color = config.sColor.lightgrey, fontsize = map_fontsize })
    row[4]:setColSpan(1):createCheckBox(menu.editedSettings.DebugFileDetail_Records, { width = map_textheight, height = map_textheight })
    row[4].handlers.onClick = menu.checkbox_DebugFileDetail_Records
    
    
    -- ----------------------------------
    -- Satır Ekle -  kontrol blok
    --row = ftable:addRow(nil, { bgColor = config.sColor.orange })
    --row[1]:setColSpan(1):createText("", subLineProperties)
    -- ----------------------------------

    local strDebug = string.format([[ Left & Right & Bottom Tables
            leftTable.properties.x : %s        leftTable.properties.width    : %s
            leftTable.properties.y : %s        leftTable.properties.height   : %s
            leftTable.properties.maxVisibleHeight : %s        leftTable:getFullHeight()    : %s
            -----
            rightTable.properties.x: %s        rightTable.properties.width   : %s   
            rightTable.properties.y: %s        rightTable.properties.height  : %s   
            rightTable.properties.maxVisibleHeight: %s        rightTable:getFullHeight()   : %s   
            -----
            bottomTable.properties.x: %s        bottomTable.properties.width   : %s   
            bottomTable.properties.y: %s        bottomTable.properties.height  : %s   
            bottomTable.properties.maxVisibleHeight: %s        bottomTable:getFullHeight()   : %s   ]],
        leftTable.properties.x, leftTable.properties.width,
        leftTable.properties.y, leftTable.properties.height,
        leftTable.properties.maxVisibleHeight, leftTable:getFullHeight(),
        rightTable.properties.x, rightTable.properties.width,
        rightTable.properties.y, rightTable.properties.height,
        rightTable.properties.maxVisibleHeight, rightTable:getFullHeight(),
        bottomTable.properties.x, bottomTable.properties.width,
        bottomTable.properties.y, bottomTable.properties.height,
        bottomTable.properties.maxVisibleHeight, bottomTable:getFullHeight()
        )
    if debugWProps then DebugError(strDebug) end

end

function menu.createManagerTables(frame)

    local borderSize = Helper.borderSize  
    local usablewidth = frame.properties.width 
    local FleetTableWidthRatio = 4.5 / 13
    local ShipTableWidthRatio = 5 / 13
    local rightTableWidthScale = 1 - FleetTableWidthRatio - ShipTableWidthRatio

    local row
    local keywidth = C.GetTextWidth("999", Helper.headerRow1Font,
    Helper.scaleFont(Helper.headerRow1Font, Helper.headerRow1FontSize)) + 2 * (Helper.headerRow1Offsetx + borderSize)

    menu.initDataFromMdData()

    --
    -- Fleet TABLE
    --
    local offsetx = 0
    local offsety = 0
    local width = math.floor(usablewidth * FleetTableWidthRatio) 
    menu.fleetTable, menu.sorterTable = menu.createRFMFleetTable(frame, offsetx, offsety, width)

    --
    -- FleetShips TABLE
    --

    offsetx = menu.sorterTable.properties.x + menu.sorterTable.properties.width + 2 * borderSize
    offsety = 0
    width = ( math.floor(usablewidth  * ShipTableWidthRatio)  )  
    --height = menu.fleetTable.properties.y + menu.fleetTable.properties.height
    menu.fleetShipsTable = menu.createRFMFleetShipsTable(frame, offsetx, offsety, width)

   
    --    
    -- Right Status Table
    --
    offsetx = menu.fleetShipsTable.properties.x + menu.fleetShipsTable.properties.width + 2 * borderSize
    offsety = 0 -- borderSize
    width =  usablewidth - (offsetx)  - 1 * borderSize 
    menu.rightTable = menu.createRFMRightTable(frame, offsetx, offsety, width)

    --
    -- TABLE BOTTOM 
    --
    -- bottomTable TABLE
    --
    menu.bottomTable = menu.createRFMFBottomTable(frame, menu.rightTable.properties.x )
    
    -- Table y konumlarını ayarla
    offsety = menu.bottomTable:getVisibleHeight()
    menu.bottomTable.properties.y = frame.properties.height - borderSize - offsety
    menu.fleetTable.properties.maxVisibleHeight = menu.bottomTable.properties.y - menu.fleetTable.properties.y 
    menu.fleetShipsTable.properties.maxVisibleHeight = menu.bottomTable.properties.y 

    -- (table.index i atanacak)
    -- UP prevTable (ilk satırda basıldığında), DOWN nextTable (en son staırda basıldığında)
    -- LEFT prevHorizontalTable ,               RIGHT nextHorizontalTable (en son staırda basıldığında)
    menu.sorterTable.properties.prevTable = menu.bottomTable.index
    menu.sorterTable.properties.nextTable = menu.fleetTable.index
    menu.sorterTable.properties.nextHorizontalTable = menu.fleetShipsTable.index
    menu.fleetTable.properties.prevTable = menu.sorterTable.index
    menu.fleetTable.properties.nextTable = menu.bottomTable.index
    menu.fleetTable.properties.nextHorizontalTable = menu.fleetShipsTable.index
    menu.fleetShipsTable.properties.prevHorizontalTable = menu.fleetTable.index
    --menu.fleetShipsTable.properties.prevTable = menu.sorterTable.index
    --menu.fleetShipsTable.properties.nextTable = menu.bottomTable.index
    menu.bottomTable.properties.prevTable = menu.fleetTable.index
    menu.bottomTable.properties.nextTable = menu.sorterTable.index


    if debugWProps then
        local strDebug = string.format( 
            [[ 
            ---------------------------------------------------
            Helper.viewWidth = %s, Helper.viewHeight = %s, Helper.borderSize : %s
            viewWidth    : %s       viewHeight   : %s
            borderOffsetX : %s      borderOffsetY : %s
            sideBarWidth  : %s      infoTableWidth   : %s
            infoTableOffsetX : %s   infoTableOffsetY : %s 
            ---------------------------------------------------
            infoframe         : x %s, y %s, width %s, Height %s
            sorterTable       : x %s, y %s, width %s, Height %s
            fleetShipsTable : x %s, y %s, width %s, Height %s
            rightTable         : x %s, y %s, width %s, Height %s
            bottomTable     : x %s, y %s, width %s, Height %s   
            ]]
            ,
            Helper.viewWidth, Helper.viewHeight, Helper.borderSize,
            menu.viewWidth, menu.viewHeight, menu.borderOffsetX, menu.borderOffsetY,
            menu.sideBarWidth, menu.infoTableWidth, menu.infoTableOffsetX, menu.infoTableOffsetY,
            frame.properties.x, frame.properties.y, frame.properties.width, frame.properties.height,
            menu.sorterTable.properties.x, menu.sorterTable.properties.y, menu.sorterTable.properties.width, menu.sorterTable.properties.height,
            menu.fleetShipsTable.properties.x, menu.fleetShipsTable.properties.y, menu.fleetShipsTable.properties.width, menu.fleetShipsTable.properties.height,
            menu.rightTable.properties.x, menu.rightTable.properties.y, menu.rightTable.properties.width, menu.rightTable.properties.height,
            menu.bottomTable.properties.x, menu.bottomTable.properties.y, menu.bottomTable.properties.width, menu.bottomTable.properties.height
            )
            local xdebug = debugWProps and DebugError(strDebug)
    end


end
function menu.createRFMFleetTable(frame, offsetx, offsety, width)

    local row, ftable
    local keywidth = C.GetTextWidth("999", Helper.headerRow1Font,
    Helper.scaleFont(Helper.headerRow1Font, Helper.headerRow1FontSize)) + 2 * (Helper.headerRow1Offsetx + Helper.borderSize)
    --
    -- Fleet TABLE
    --
    ftable = frame:addTable(6, {
        tabOrder = 1,
        x = offsetx,
        y = offsety,
        width = width,
        height = height,
        multiSelect = false,
        borderEnabled = true,

    })

    ftable:setColWidth(1, keywidth)
    ftable:setColWidth(2, 1.5 * Helper.standardTextHeight)
    -- 3 de isim olacak, kalan boşluğu alacak
    ftable:setColWidth(4, 1.5 * Helper.standardTextHeight)
    ftable:setColWidth(5, 1.5 * Helper.standardTextHeight)
    ftable:setColWidth(6, 1.5 * Helper.standardTextHeight)
    ftable:setDefaultBackgroundColSpan(1, 6)

    if menu.setdefaulttable then
        ftable.properties.defaultInteractiveObject = true
        menu.setdefaulttable = nil
    end

    --
    -- fill in Fleet TABLE
    --
    menu.fillin_RFMFleetTable(ftable)

    --
    -- SORTER TAB TABLE
    --
    local tabtable
    local maxNumCategoryColumns =  math.floor(width / 40)
	if maxNumCategoryColumns > Helper.maxTableCols then
		maxNumCategoryColumns = Helper.maxTableCols
	end
    local numOfSorterColumns = 4 -- "sort by:", "rfm keys", "promoted name", "location"
    local colSpanPerSorterColumn = math.floor(maxNumCategoryColumns / numOfSorterColumns)
    tabtable = frame:addTable(maxNumCategoryColumns, {
         tabOrder = 2, 
         reserveScrollBar = false,
         x = offsetx,
         y = offsety,
    })

    local fixed = true

    if maxNumCategoryColumns > 0 then
		for i = 1, maxNumCategoryColumns do
			tabtable:setColWidth(i, 40, false)
		end
		local diff = width - maxNumCategoryColumns * (40 + Helper.borderSize)
		tabtable:setColWidth(maxNumCategoryColumns, 40 + diff, false)

        local row = tabtable:addRow(false, { fixed = fixed , bgColor = config.sColor.transparent } )
        row[1]:setColSpan(maxNumCategoryColumns):createText("Active RFM Fleets", { halign = "center", font = Helper.headerRow1Font, fontsize = Helper.headerRow1FontSize } )
        row = tabtable:addRow(false, { fixed = fixed, bgColor = config.sColor.grey } )
        row[1]:setColSpan(maxNumCategoryColumns):createText("", { height = 1 } )
    
        -- sorter row
        local row = tabtable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent })

        -- "sort by"
        row[1]:setColSpan(colSpanPerSorterColumn):createText(ReadText(1001, 2906) .. ReadText(1001, 120))
        local buttonheight = Helper.scaleY(config.mapRowHeight)
        -- "rfm key"
        local sorterColumn = 2
        local tableColumn = (sorterColumn - 1) * colSpanPerSorterColumn + 1
        local button = row[tableColumn]:setColSpan(colSpanPerSorterColumn):createButton({ scaling = false, height = buttonheight }):setText("RFM Key", { halign = "center", scaling = true })
        if menu.propertySorterType == "id" then
            button:setIcon("table_arrow_inv_down", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
        elseif menu.propertySorterType == "idinverse" then
            button:setIcon("table_arrow_inv_up", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
        end
        row[tableColumn].handlers.onClick = function () return menu.buttonPropertySorter("id") end
		-- "size"
		local sorterColumn = 3
		local tableColumn = (sorterColumn - 1) * colSpanPerSorterColumn + 1
		local button = row[tableColumn]:setColSpan(colSpanPerSorterColumn):createButton({ scaling = false, height = buttonheight }):setText(ReadText(1001, 8026), { halign = "center", scaling = true })
		if menu.propertySorterType == "class" then
			button:setIcon("table_arrow_inv_down", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		elseif menu.propertySorterType == "classinverse" then
            button:setIcon("table_arrow_inv_up", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		end
        row[tableColumn].handlers.onClick = function () return menu.buttonPropertySorter("class") end
		-- "name"
		sorterColumn = 4
		tableColumn = (sorterColumn - 1) * colSpanPerSorterColumn + 1
		local button = row[tableColumn]:setColSpan(colSpanPerSorterColumn):createButton({ scaling = false, height = buttonheight }):setText(ReadText(1001, 2809), { halign = "center", scaling = true })
		if menu.propertySorterType == "name" then
			button:setIcon("table_arrow_inv_down", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		elseif menu.propertySorterType == "nameinverse" then
			button:setIcon("table_arrow_inv_up", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		end
		row[tableColumn].handlers.onClick = function () return menu.buttonPropertySorter("name") end
		-- "sector"
		local row = tabtable:addRow(true, { fixed = fixed, bgColor = config.sColor.transparent })
		sorterColumn = 2
		tableColumn = (sorterColumn - 1) * colSpanPerSorterColumn + 1
		button = row[tableColumn]:setColSpan(colSpanPerSorterColumn):createButton({ scaling = false, height = buttonheight }):setText(ReadText(1001, 11284), { halign = "center", scaling = true })
		if menu.propertySorterType == "sector" then
			button:setIcon("table_arrow_inv_down", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		elseif menu.propertySorterType == "sectorinverse" then
			button:setIcon("table_arrow_inv_up", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		end
		row[tableColumn].handlers.onClick = function () return menu.buttonPropertySorter("sector") end
		-- "damaged (Locked fleet)"
		sorterColumn = 3
		tableColumn = (sorterColumn - 1) * colSpanPerSorterColumn + 1
		button = row[tableColumn]:setColSpan(colSpanPerSorterColumn):createButton({ scaling = false, height = buttonheight }):setText("Damaged", { halign = "center", scaling = true })
		if menu.propertySorterType == "locked" then
			button:setIcon("table_arrow_inv_down", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		elseif menu.propertySorterType == "lockedinverse" then
			button:setIcon("table_arrow_inv_up", { width = buttonheight, height = buttonheight, x = button:getColSpanWidth() - buttonheight })
		end
		row[tableColumn].handlers.onClick = function () return menu.buttonPropertySorter("locked") end

    end
    --DebugError(string.format("maxNumCategoryColumns %s , width = %s , (width / 40) = %s , numOfSorterColumns = %s , colSpanPerSorterColumn = %s", maxNumCategoryColumns, width, width / 40 ,  numOfSorterColumns, colSpanPerSorterColumn )  )

    ftable.properties.y = tabtable.properties.y + tabtable:getFullHeight() + Helper.borderSize
	

    return ftable, tabtable
end
function menu.fillin_RFMFleetTable(ftable)
    
    table.sort(menu.fleets, menu.componentSorter(menu.propertySorterType))

    --
    -- fill fleet Table
    --
    local row
    local found = nil
    -- entries
    if #menu.fleets > 0 then
        for i, entry in ipairs(menu.fleetcategories) do
            if #entry.fleetkeys > 0 then
                found = true
                -- category header
                local row = ftable:addRow(false, {  bgColor = config.sColor.transparent60 } ) 
                -- Helper.subHeaderTextProperties
                row[1]:setColSpan(6):createText(entry.name, Helper.headerRowCenteredProperties ) -- Kategori Adı - Ship Fleets or Station Fleets
                row[1].properties.halign = "center"

                -- category fleets
                for _, fleetkey in ipairs(entry.fleetkeys) do
                    
                    local fleet = menu.fleets[menu.findFleet(fleetkey)]

                    local row = menu.add_RFMFleetTable_FleetEntry(ftable, fleet)
                    
                    if menu.selectedfleet == fleetkey then
                        menu.setselectedrow = row.index
                    end
                    
                end

                -- kategoriler arsasına aralık koy
                if i < #menu.fleetcategories then
                    local row = ftable:addRow(false, { bgColor = config.sColor.transparent60 } )
                    row[1]:setColSpan(6):createText("", {height = 1} )
                end
            end
        end
    else 
        local row = ftable:addRow("none", { bgColor = config.sColor.transparent, interactive = false })
        row[1]:setColSpan(6):createText("-- " .. ReadText(1001, 32) .. " --", { halign = "center" })
    end


    -- scrol içermeyen satır sayısı 0
    -- kategori satırı (+1)
    -- = 1
    --  seçim yapılabilecek ilk satır 2
    -- görünen veri sayısı = 17 satır (!kategori satırları dahil yarım satırlık)
    --  ekrandaki en alt veri satırı = 17 
    --  seçili satırın altındaki de gözüksün diyoruz bu yüzden 18. satırdan büyük olma durumuna bakıcağız
    -- 16 den önce 1.den itibaren toplam 15 satır
    -- 
    menu.settoprow = ((not menu.settoprow) or (menu.settoprow == 0)) and ((menu.setselectedrow and menu.setselectedrow > 16) and (menu.setselectedrow - 15) or 1) or menu.settoprow
    ftable:setTopRow(menu.settoprow)
    ftable:setSelectedRow(menu.setselectedrow)
    menu.setselectedrow = nil
    menu.settoprow = nil

end
function menu.add_RFMFleetTable_FleetEntry(ftable, fleetEntry)

    local fleet = fleetEntry
    local font, fontsize = Helper.standardFont, Helper.standardFontSize

    local bgColor = config.sColor.transparent
    bgColor = (menu.selectedfleet == fleet.id) and config.selectedRowBgColor or bgColor

    local row = ftable:addRow( fleet.id  , { bgColor = bgColor })   --{ bgColor = bgColor }

    if menu.setselectedrow and menu.setselectedrow == row.index then
        --menu.selectedfleet = fleet.id
    end

    local object64 = ConvertStringTo64Bit(tostring(fleet.object))
    local currentordericon, currentorderrawicon, currentordercolor, currentordername, currentorderdescription, currentorderisoverride, currentordermouseovertext, targetname, behaviouricon, behaviourrawicon, behaviourname, behaviourdescription = "", "", nil, "", "", false, nil, nil, "", "", "", ""
    if C.IsComponentClass(object64, "ship") then
        currentordericon, currentorderrawicon, currentordercolor, currentordername, currentorderdescription, currentorderisoverride, currentordermouseovertext, targetname, behaviouricon, behaviourrawicon, behaviourname, behaviourdescription = menu.getOrderInfo(object64, true)
    end
    
    local isdocked = fleet.isdocked
    local locationtext = fleet.locationtext
    local normalrowcolor = config.sColor.green
    local color = tonumber(fleet.alertstatus.level) > 1 and fleet.color or normalrowcolor
    local icon = fleet.icon
    
    local textheight = C.GetTextHeight(" \n ", font, Helper.scaleFont(font, fontsize), Helper.viewWidth)
    
    local name = ((fleet.name == "") and fleet.commander.name or fleet.name)
    local idcode = ((fleet.idcode == "") and "   {   All Ships are DEAD   }" or fleet.idcode)
    row[1]:createText(fleet.id, { color = config.sColor.white , halign = "right" } )

    if fleet.isStation then
        row[2]:createIcon(icon, { scaling = true, width = textheight - 2 , height = textheight - 2  , color = color})
    else
        row[2]:createText(string.format("\027[%s]", icon), { color = color } )
    end
    -- debugW
    local mouseovertext = tonumber(fleet.alertstatus.level) > 1 and "Alert Status: \n" .. Helper.convertColorToText(color) .. fleet.alertstatus.text or ""
    row[3]:createText((name .. " " .. idcode .. ((debugW) and "   { row ".. tostring(row.index) .. " }" or "" ) ), { color = normalrowcolor, mouseOverText = mouseovertext  } )

    local Icon_OrderIconsGrp = row[4]:setColSpan(3):createIcon("solid", { scaling = false, color = { r = 0, g = 0, b = 0, a = 1 }, height = textheight })

    local mouseovertext = menu.GetMouseOverTextFromOrderIcons(currentordericon, currentordername, currentorderdescription, currentordermouseovertext, targetname, behaviouricon, behaviourname, behaviourdescription, isdocked )
    Icon_OrderIconsGrp.properties.mouseOverText = mouseovertext

    Icon_OrderIconsGrp:setText(
        currentorderisoverride
        and 
            function () return 
                --menu.overrideOrderIcon(currentordercolor, true, currentorderrawicon )
            menu.noneOverrideOrderIcon( menu.overrideOrderIcon(currentordercolor, true, currentorderrawicon) , behaviouricon, isdocked, locationtext)
            end
        or  
            menu.noneOverrideOrderIcon(currentordericon, behaviouricon, isdocked, locationtext)
        , { scaling = true, font = font, halign = "right", x = Helper.standardTextOffsetx }
            
    )
    return row
end

function menu.createRFMFleetShipsTable(frame, offsetx, offsety, width)
    local row, ftable
    local keywidth = C.GetTextWidth("999", Helper.headerRow1Font,
    Helper.scaleFont(Helper.headerRow1Font, Helper.headerRow1FontSize)) + 2 * (Helper.headerRow1Offsetx + Helper.borderSize)
    menu.shipIconWidth = menu.getShipIconWidth()  -- Helper.headerRow1Font, Helper.headerRow1FontSize
    --
    -- FleetShips TABLE
    -- 
    -- Key , name,   , location, 3x ordericons, hullbar
    ftable = frame:addTable(7, {
        tabOrder = 3,
        x = offsetx,
        y = offsety,
        width = width,
        borderEnabled = true,
		backgroundID = "solid",
		backgroundColor =  config.sColor.transparent,
    })
    if menu.setdefaulttable then
        ftable.properties.defaultInteractiveObject = true
        menu.setdefaulttable = nil
    end
    
    ftable:setDefaultBackgroundColSpan(1, 7)
    ftable:setColWidth(1, keywidth)
	ftable:setColWidth(3, 100)
    for i = 1, 3 do
        ftable:setColWidth(4 + i - 1, menu.shipIconWidth, true)
    end
    ftable:setColWidth(7 , menu.shipIconWidth, false)

    --  Tablo Başlığı
    -- Satır Ekle - 
    row = ftable:addRow(false, { fixed = true , bgColor = config.sColor.transparent } )
    -- Backroundu ve texti setle
    row[1]:setColSpan(7):createText("Recorded Ships Tree", { halign = "center", font = Helper.headerRow1Font, fontsize = Helper.headerRow1FontSize } )
    -- Satır Ekle - Gri ince
    row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.grey } )
    row[1]:setColSpan(7):createText("", { height = 1 } )
    -- Satır Ekle - Mavi kalın 
    row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
    -- Tablo Listesi Sütun Başlıkları
    -- 1. Sutun 
    row[1]:createText("Key", { font = Helper.standardFontBold , halign = "center" } )
    -- 2. Sutun Başlığı
    row[2]:setColSpan(1):createText("Name", { font = Helper.standardFontBold, halign = "left" } )
    row[7]:createText(" ", { font = Helper.standardFontBold, halign = "right" } )

    -- Tablo Listesi Sütun Başlıkları Altına Çizgi çek
    row = ftable:addRow(false, { fixed = true } )
    -- Satır Ekle - Gri ince
    row[1]:setColSpan(7):createText("", { height = 2 } )
    
    local fleetIndex = menu.findFleet(menu.selectedfleet)
    if not fleetIndex then return ftable end
    local fleet = menu.fleets[fleetIndex]
    fleet.subordinates = {}     -- shipid ye ait subordinatelerin listesini tutacak
    fleet.constructions = {}    -- constructions bilgisini tutacak
    fleet.leaderShips = {}      -- fleet içindeki komutanların listesini tutacak
    fleet.Records = {}          -- orj tableye ek olarak Ship Tablesinde yazdırabileceğimiz propertyler içerecek

    if not menu.RM_FleetRecords[menu.selectedfleet] then DebugError("RM_FleetRecords[" .. tostring(menu.selectedfleet) .. "] table yok..") end
    -- Dönüştürme işlemi, { [skey] = {}, .. }  olan table yi { {}, {}, ..} tablesine dönüştürüyoruz. rahat sort yapabilemk için
    for sKey, record in pairs(menu.RM_FleetRecords[menu.selectedfleet]) do
        local entry = menu.tablecopy(record)
        -- Çıkaracaklarımız var mı
        --menu.tableremoveKey(entry, "tPilot")
        --menu.tableremoveKey(entry, "tBulkCrew")
        --menu.tableremoveKey(entry, "tWare")
        table.insert(fleet.Records, entry)
    end

    -- hazırla: fleet.subordinates, fleet.leaderShips
    for index, record in pairs(fleet.Records) do
        local subordinates = {}
        
        subordinates = menu.GetSubordinates_From_FleetRecords(menu.selectedfleet, record.id)
        subordinates.hasRendered = #subordinates > 0

        fleet.subordinates["S_" .. tostring(record.id)] = subordinates

        if #subordinates > 0 then
            table.insert(fleet.leaderShips, record.id)
        end

        local debugText = string.format( [[i = %s, sKey = %s, name = %s %s, (#.subs %s),  subordinates = %s]],
        index, record.id, record.name, record.idcode, #subordinates, 
        menu.getstring_TableStructure(subordinates,"",false) )
        local xdebug = debugSubordinate and DebugError(debugText)
    end
    local xdebug = debugSubordinate and DebugError("leaderships = " .. menu.getstring_TableStructure(fleet.leaderShips,"", false) )

    local promotedshipkey = nil
    -- fleet.Records yapısına eklemeler yapacağız 
    for _, record in pairs(fleet.Records) do
        local object64 = ConvertStringTo64Bit(tostring(record.object))
        local idcode, isLost = "", false
        local color = config.sColor.green
        local statusIcon, statusMoseOverText = "", ""
        local isWaitingForRebuild, respondMsg = false, ""
        local build = nil
        local respond = {}
        local construction = {}
        local shipyard = {
            object = nil,
            object64 = nil,
            name = "",
            idcode = "",
            faction = "",
            factioncolor = "",
            sector = "",
            sectorid = nil,
            sectorowner = nil,
            sectorownercolor = "",
        }
        -- md den gelen değerler 'ID : xxx' şeklinde olduğundan ya string türünden karşılaştıracağız ya da 64 e convert edip rakamsal olarak karşılaştıracağız
        if (fleet.object) and (record.object) and (tostring(fleet.object) == tostring(record.object)) and (tonumber(fleet.id) == tonumber(menu.selectedfleet)) then
            promotedshipkey = record.id
        end
        if not promotedshipkey then
            promotedshipkey = 1
        end

        record.destroyed = (tonumber(record.destroyed) == 1) 

        if record.destroyed then
            local rebuildcue = menu.GetReBuildCue(menu.selectedfleet, record.id)
            if rebuildcue then
                build = rebuildcue.build

                isWaitingForRebuild = ( tonumber(rebuildcue.isWaitingForRebuild) == 1 )

                respondMsg = rebuildcue.respondMsg
                respond = menu.tablecopy(rebuildcue.respond)
                
                color = config.sColor.alertnormal
                statusIcon = "order_waitforsignal"
                statusMoseOverText = "Waiting for next check"
                
                local shipyardobject = rebuildcue.shipyard.object
                local shipyard64 = ConvertStringTo64Bit(tostring(shipyardobject))
                shipyard.object = shipyardobject
                shipyard.object64 = shipyard64
                if shipyard64 ~= 0 then
                    shipyard.name, shipyard.faction, shipyard.sector, shipyard.sectorid = GetComponentData(shipyard64, "name", "owner", "sector", "sectorid" )
                    shipyard.factioncolor = GetFactionData(shipyard.faction, "color")
                    shipyard.sectorowner = GetComponentData(shipyard.sectorid, "owner")
                    shipyard.sectorownercolor = GetFactionData(shipyard.sectorowner, "color")
                    shipyard.idcode = ffi.string(C.GetObjectIDCode(shipyard64))

                    construction = build and menu.GetConstructionFromShipyardBuilds(shipyard64, build) or construction

                    menu.fleets[fleetIndex].constructions["S_" .. tostring(record.id)] = construction

                    -- menu.tablePrint(construction, "construction = [" .. tostring(menu.selectedfleet) .. "][" .. tostring(record.id) .. "]" , true, true)
                    -- DebugError("HasSuitableBuildModule = " .. tostring(C.HasSuitableBuildModule(construction.buildingcontainer, construction.component, record.macro)))
                    statusIcon = "order_equip"
                    if construction.inprogress then
                        color = config.Color.text_inprogress
                        statusMoseOverText = "Ship In Construction"
                    else
                        color = config.Color.text_warning
                        statusMoseOverText = ReadText(1001, 8563)
                    end

                end
                local textDebug = string.format(
                    [[  %s-name = %s %s
                        reBuild CheckedTime = %s
                        isWaitingForRebuild = %s
                        shipyard64 = %s
                        build = %s 
                        construction.id = %s
                        construction.buildingcontainer = %s
                        construction.component = %s
                        construction.macro = %s
                        construction.factionid = %s
                        construction.buildercomponent = %s
                        construction.price = %s
                        construction.ismissingresources = %s
                        construction.queueposition = %s
                        construction.inprogress = %s ]],
                        record.id, record.name, record.idcode, record.reBuildTryNum, isWaitingForRebuild, shipyard64, build,
                        construction.id,
                        construction.buildingcontainer,
                        construction.component,
                        construction.macro,
                        construction.factionid,
                        construction.buildercomponent,
                        construction.price,
                        construction.ismissingresources,
                        construction.queueposition,
                        construction.inprogress
                    )
                if debugConstruction then
                    if debug0 and not debug2 then
                        if build then DebugError(textDebug) end
                    elseif debug0 and debug2 then
                        DebugError(textDebug)
                    end
                end
            else
                color = config.Color.text_criticalerror
                statusIcon = "maptr_illegal"
                statusMoseOverText = "Lost. Click to Rebuild Button for start rebuild"
                isLost = true
            end
        end

        record.color = color
        record.object64 = object64
        record.build = build
        record.isLost = isLost
        record.isWaitingForRebuild = isWaitingForRebuild
        record.respondMsg = respondMsg
        record.shipyard = shipyard
        record.respond = respond
        record.construction = construction
        record.statusIcon = statusIcon
        record.statusMoseOverText = statusMoseOverText
    end
    fleet.promotedshipkey = promotedshipkey

    table.sort(fleet.Records, menu.sortNameSectorAndIDCode)

    menu.createPropertySection(ftable, fleet.leaderShips, menu.propertySorterType)


    menu.shipsTableData.settoprow = ( (not menu.shipsTableData.settoprow) or (menu.shipsTableData.settoprow == 0)) and ((menu.shipsTableData.setselectedrow and menu.shipsTableData.setselectedrow > 36) and (menu.shipsTableData.setselectedrow - 31) or 5) or menu.shipsTableData.settoprow
    ftable:setTopRow(menu.shipsTableData.settoprow)
    ftable:setSelectedRow(menu.shipsTableData.setselectedrow)
    menu.shipsTableData.setselectedrow = nil
    menu.shipsTableData.settoprow = nil

    return ftable
end
function menu.createPropertySection(ftable, array, sorter)

    local fleet = menu.fleets[menu.findFleet(menu.selectedfleet)]

    if (not menu.shipsTableData.selected) and (not menu.shipsTableData.selectedGroup) then
        menu.shipsTableData.selected = 1
        menu.shipsTableData.selectedGroup = nil
    end

    -- leader shipkey herzaman 1 
    local shipKey = 1
    menu.createPropertyRow(ftable, shipKey, 0, fleet.sectorid, sorter)

end
function menu.createPropertyRow(ftable, component, iteration, commanderlocation, sorter)
    local maxicons = 0

    local fleet = menu.fleets[menu.findFleet(menu.selectedfleet)]

    local subordinates = fleet.subordinates["S_" .. tostring(component)] or {}
    local constructions = fleet.constructions["S_" .. tostring(component)] or {}

    local record = menu.GetRecord(menu.selectedfleet, component)

    local color, font, fontsize = config.sColor.green, Helper.standardFont, Helper.standardFontSize
    local bold = ""
    bold = "_bold"
    local star = ""
    if fleet.promotedshipkey == record.id then
        --color = config.sColor.lightgreen
        --fontsize = fontsize + 1.5
        --font = Helper.standardFontBold
        star = Helper.convertColorToText(config.sColor.brightyellow) .. "\27[menu_star_04" .. bold .. "]"
        if record.destroyed then
            star = Helper.convertColorToText(config.sColor.grey) .. "\27[menu_star_04" .. bold .. "]"    
        end
        
    end
    record.font = font
    record.fontsize = fontsize


    local doubleTextheight = C.GetTextHeight(" \n ", record.font, Helper.scaleFont(record.font, record.fontsize), Helper.viewWidth)
    local singleTextheight = C.GetTextHeight("99", record.font, Helper.scaleFont(record.font, record.fontsize), Helper.viewWidth)
    local centerOffsetY = math.floor((doubleTextheight - singleTextheight) / 2)
    local ShipIconWidth = math.floor(menu.getShipIconWidth(record.font, record.fontsize))

    local bgColor =  menu.isSelectedShipLine(component) and config.selectedRowBgColor or config.sColor.transparent
    local row = ftable:addRow({"property", component, nil, iteration}, {bgColor = bgColor} )

    row[1]:createText(component, { font = record.font, fontsize = record.fontsize,  color = record.color, halign = "right", minRowHeight = Helper.headerRow1Height, y = centerOffsetY, x = Helper.headerRow1Offsetx } )

    local ordersmouseovertext = ""
    local location, locationtext, isdocked = nil, "", false
    local currentordericon, currentorderrawicon, currentordercolor, currentordername, currentorderdescription, currentorderisoverride, currentordermouseovertext, targetname, behaviouricon, behaviourrawicon, behaviourname, behaviourdescription = "", "", nil, "", "", false, nil, "", "", "", "", ""
    local componentObject64 = ConvertStringTo64Bit(tostring(record.object))
    
    if componentObject64 ~= 0 then
        location, locationtext, isdocked = GetComponentData(componentObject64, "sectorid", "sector", "isdocked")
        if IsComponentClass(componentObject64, "ship") then
            currentordericon, currentorderrawicon, currentordercolor, currentordername, currentorderdescription, currentorderisoverride, currentordermouseovertext, targetname, behaviouricon, behaviourrawicon, behaviourname, behaviourdescription = menu.getOrderInfo(componentObject64, true)
            ordersmouseovertext = menu.GetMouseOverTextFromOrderIcons(currentordericon, currentordername, currentorderdescription, currentordermouseovertext, targetname, behaviouricon, behaviourname, behaviourdescription, isdocked )
        end
    end
    local displaylocation = location and not (commanderlocation and IsSameComponent(location, commanderlocation))


    -- durum iconu için mouse over tanımla
    local mouseovertext = ordersmouseovertext
    if record.statusIcon ~= "" then
        mouseovertext = mouseovertext .. record.statusMoseOverText
    end
    if record.respondMsg ~= "" then
        if mouseovertext ~= "" then
            mouseovertext = mouseovertext .. "\n"
        end
        mouseovertext = mouseovertext .. Helper.indentText(record.respondMsg, "  ", GetCurrentMouseOverWidth(), GetCurrentMouseOverFont())
    end

    local name, nameid, ShipIconAndName, progressText, timeleftText = record.name, record.idcode, "", "", ""
    name = string.format("\027[%s] %s", record.icon, name) 
    if record.construction.id then
        local err 
        locationtext = Helper.convertColorToText(record.shipyard.sectorownercolor) .. record.shipyard.sector
        if record.construction.inprogress then
            -- construction ilerleme durumu var (component oluşmuş)
            nameid = ffi.string(C.GetObjectIDCode(record.construction.component))
            -- *** değişken refreshden bağımsız her an güncellenmesi için function olarak atandı
            --progressText = function () return menu.getShipBuildProgress(record.construction.component) end
            timeleftText = 
            function () return 
                (record.construction.ismissingresources and "\27Y\27[warning] " or "") .. 
                Helper.formatTimeLeft(C.GetBuildProcessorEstimatedTimeLeft(record.construction.buildercomponent)) ..
                " ( " .. menu.getShipBuildProgress(record.construction.component) .. " )" ..
                " \n " .. locationtext
            end
        else
            if not C.HasSuitableBuildModule(record.construction.buildingcontainer, record.construction.component, record.macro) then
                err = ReadText(1001, 8563)
            end
            local duration = err and 0 or C.GetBuildTaskDuration(record.construction.buildingcontainer, record.construction.id)
            timeleftText = (err and (Helper.convertColorToText(config.Color.text_error) .. "") or ("#" .. record.construction.queueposition .. " - ")) .. Helper.formatTimeLeft(duration) ..
            " \n " .. locationtext
        end
        local mouseovertext = err and err or record.construction.ismissingresources and ReadText(1026, 3223) or ""
        for i = 1, iteration do
            name = "    " .. name
        end
        ShipIconAndName = string.format("%s%s %s %s", Helper.convertColorToText(record.color), name, nameid, (debugW and "   { row " .. tostring(row.index) .. " }" or "") )
        row[2]:setColSpan(1):createText( ShipIconAndName , { font = record.font, fontsize = record.fontsize, mouseOverText = mouseovertext , minRowHeight = Helper.headerRow1Height, y = Helper.headerRow1Offsety, x = Helper.headerRow1Offsetx } )
        row[3]:setColSpan(4):createText( timeleftText , { font = record.font, fontsize = record.fontsize, halign = "right", mouseOverText = mouseovertext , minRowHeight = Helper.headerRow1Height, y = Helper.headerRow1Offsety, x = Helper.headerRow1Offsetx } )

    else
        -- construction olmayan (1-hayatta olan gemi 2-üretim bulamayıp bekleyen 3- lost gemi)

        for i = 1, iteration do
            name = "    " .. name
        end
        --xspan = record.destroyed == 1 and 4 or 5
        ShipIconAndName = string.format("%s%s%s %s %s", star, Helper.convertColorToText(record.color), name, nameid, (debugW and "   { row " .. tostring(row.index) .. " }" or "") ) 
        row[2]:setColSpan(1):createText( ShipIconAndName, { font = record.font, fontsize = record.fontsize, mouseOverText = record.destroyed and mouseovertext or (star == "") and "" or "Promoted Commander", minRowHeight = Helper.headerRow1Height, y = Helper.headerRow1Offsety, x = Helper.headerRow1Offsetx } )
        
        local Icon_OrderIconsGrp = row[3]:setColSpan(4):createIcon("solid", { scaling = false, color = { r = 0, g = 0, b = 0, a = 1 }, height = doubleTextheight })
        Icon_OrderIconsGrp:setText(
            currentorderisoverride
            and function () return 
                --menu.overrideOrderIcon(currentordercolor, true, currentorderrawicon, "secondtext1truncated" .. "\n", isdocked and "\27[order_dockat]" or "") 
                menu.noneOverrideOrderIcon( menu.overrideOrderIcon(currentordercolor, true, currentorderrawicon) , behaviouricon, isdocked, locationtext)
                end
            or  menu.noneOverrideOrderIcon(currentordericon, behaviouricon, isdocked, displaylocation and locationtext or "")
            , { scaling = true, font = record.font, halign = "right", x = Helper.standardTextOffsetx }
                
        )

        Icon_OrderIconsGrp.properties.mouseOverText = ordersmouseovertext

    end


    if record.statusIcon ~= "" then
        row[7]:createText(string.format("\027[%s]", record.statusIcon), 
            { color = record.color , minRowHeight = Helper.headerRow1Height, halign = "center", y = centerOffsetY, x = 0} )
        row[7].properties.mouseOverText = mouseovertext
    else
        row[7]:createObjectShieldHullBar(record.object)
    end
    
    --row[1].properties.mouseOverText = mouseovertext
    --row[2].properties.mouseOverText = mouseovertext
    row[3].properties.mouseOverText = mouseovertext

    menu.createSubordinateSection(ftable, component, iteration, location or commanderlocation, sorter)

end
function menu.createSubordinateSection(ftable, component, iteration, location, sorter)
	local maxicons = 0
    
    local fleet = menu.fleets[menu.findFleet(menu.selectedfleet)]

    local subordinates = fleet.subordinates["S_" .. tostring(component)] or {}
	subordinates = menu.sortKeysListWithFleetRecords(menu.selectedfleet, subordinates, sorter) 

    local groups = {}
    for _, subordinate in ipairs(subordinates) do
        local record = menu.GetRecord(menu.selectedfleet, subordinate)
        local group = record.subordinategroupid

        local debugText = string.format( [[component   %s, subordinate %s, group %s]],
        component, subordinate, group )
        local xdebug = debugSubordinate and DebugError(debugText)

        if group and group > 0 then
            if groups[group] then
                table.insert(groups[group].subordinates, subordinate)
            else
                groups[group] = { assignment = record.assignment , subordinates = { subordinate } }
            end
        end
    end
    for group = 1, 10 do
        if groups[group] then
            local row = ftable:addRow({"subordinates" .. tostring(component) .. group, component, group}, { bgColor = config.sColor.transparent })
			local text = string.format(ReadText(1001, 8398), ReadText(20401, group))
			for i = 1, iteration + 1 do
				text = "    " .. text
			end
			row[2]:setColSpan(1):createText(text .. (debugW and "   { row " .. tostring(row.index) .. " }" or "") )
            local assignmenttext = config.assignments[groups[group].assignment] and config.assignments[groups[group].assignment].name or ""

            local groupiconstext = ""
            local groupmouseovertext = ""

            groupiconstext = assignmenttext
            row[3]:setColSpan(5):createText(groupiconstext, { halign = "left", mouseOverText = groupmouseovertext })
            
            for _, subordinate in ipairs(groups[group].subordinates) do
                menu.createPropertyRow(ftable, subordinate, iteration + 2, location, sorter)
            end
        end
    end
        
end

function menu.createRFMFBottomTable(frame, width)

    local row, ftable
    --
    -- button TABLE
    --
    ftable = frame:addTable(13, {
        tabOrder = 4,
        width = width,
        backgroundID = "solid",
        backgroundColor = config.sColor.transparent,
    })

    ftable:setColWidth(1, Helper.standardTextHeight)
    ftable:setColWidthPercent(2, 13)
    ftable:setColWidth(3, Helper.standardTextHeight)
    ftable:setColWidthPercent(4, 13)
    ftable:setColWidth(5, Helper.standardTextHeight)
    ftable:setColWidthPercent(6, 13)
    ftable:setColWidth(7, 2 * Helper.standardTextHeight)
    ftable:setColWidthPercent(8, 13)
    ftable:setColWidth(9, Helper.standardTextHeight)
    ftable:setColWidthPercent(10, 13)
    ftable:setColWidth(11, Helper.standardTextHeight)
    ftable:setColWidthPercent(12, 13)
    -- 13.colon boşta kalan boşluğu alacak

    -- Kılavuz 
    --row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.orange } )
    --row[1]:setColSpan(1):createText("", {})
    
    row = ftable:addRow(false, { fixed = true, } )
    row[1]:setColSpan(13):createText((""), {height = 3} )
    row[1].properties.halign = "center"
    
    local fleetIndex = menu.findFleet(menu.selectedfleet)
    local isSelectedFleet = (fleetIndex) and true or false
    local SelectedShip = menu.isSelectedShipLine(menu.shipsTableData.selected)

    row = ftable:addRow("buttonrow", { fixed = true, bgColor = config.sColor.transparent, } )
    
    local color = isSelectedFleet and Helper.convertColorToText(menu.fleets[fleetIndex].color) or config.sColor.white
    local reenablebuttonText = isSelectedFleet and string.format("Restart [ %sRFM %s \027X]", color, tostring(menu.selectedfleet)) or "Restart"
    local disablebuttonText = isSelectedFleet and string.format("Disable [ %sRFM %s \027X]", color, tostring(menu.selectedfleet)) or "Disable"
    row[2]:createButton({ active = isSelectedFleet } )
    row[2]:setText( reenablebuttonText, { halign = "center" } ) -- ReEnable Selected Fleet
    row[2].handlers.onClick = function() return menu.buttonReEnable() end

    row[4]:createButton({ active = isSelectedFleet } )
    row[4]:setText( disablebuttonText, { halign = "center" } ) -- Disable Selected Fleet
    row[4].handlers.onClick = function() return menu.buttonDisable() end

    if isSelectedFleet then
        local autobuildvalue = menu.fleets[fleetIndex].autobuild
        local autoBuildText = " ON "
        local autobuildcolor = config.sColor.statusGreen
        local mouseOverText = "When the ship belonging to this RFM destroyed, the rebuild process will be started automatically."
        if not autobuildvalue then
            autoBuildText = "OFF"
            autobuildcolor = config.sColor.statusRed
            mouseOverText = "When the ship belonging to this RFM destroyed, the rebuild process will NOT be started automatically."
        end
        local autoBuildText = string.format("Auto Build [ %s%s \027X]", Helper.convertColorToText( autobuildcolor ), autoBuildText) 
        row[6]:createButton({ active = isSelectedFleet, mouseOverText = mouseOverText } )
        row[6]:setText( autoBuildText, { halign = "center" } ) -- Toggle auto build for Selected Fleet
        row[6].handlers.onClick = function() 
                menu.RM_Fleets[menu.selectedfleet].autobuild = autobuildvalue and 0 or 1    -- md datasında true false değerleri 1 0 olarak geliyor
                menu.buttonAutoBuildChanged() 
                menu.refreshInfoFrame()
            end
    end

    local record = menu.GetRecord(menu.selectedfleet, SelectedShip) 

    row[8]:createButton({ active = function() return (record.object or record.build) and true or false end  } )
    row[8]:setText("Show on Map", { halign = "center" }) 
    row[8].handlers.onClick = menu.buttonOnShowMap

    if record.destroyed and not record.construction.buildingcontainer then
        local mouseOverText = "Removes the selected ship from the Restock Fleet records.\nOnly valid for exploded ships that cannot be produced."
        row[10]:createButton({ active = true, mouseOverText = mouseOverText  } )
        row[10]:setText("Remove Ship", { halign = "center" }) -- Rebuild 
        row[10].handlers.onClick = function() return menu.buttonRemoveShip() end
    end

    return ftable
end

function menu.createRFMRightTable(frame, offsetx, offsety, width)
    
    local ftable = frame:addTable(10, {
        tabOrder = 7,
        x = offsetx,
        y = offsety,
        width = width,
		backgroundID = "solid",
		backgroundColor = config.Color["table_background_3d_editor"], -- config.sColor.orange,
        skipTabChange = true,
        borderEnabled = true,
        
    })
    --ftable:setDefaultBackgroundColSpan(1, 10)    -- açılacak row sütunları arasındaki boşluğu kapatır

    local rowLabelProperties = {
        font = Helper.standardFont,
        fontsize = Helper.standardFontSize,
        x = Helper.standardTextOffsetx,
        y = Helper.standardTextOffsety,
        height = Helper.standardTextHeight - Helper.standardTextOffsety,
        color = config.sColor.blue,
        halign = "left"
    }
    local rowtimeProperties = {
        font = Helper.standardFont,
        fontsize = Helper.standardFontSize,
        x = Helper.standardTextOffsetx,
        y = Helper.standardTextOffsety,
        height = Helper.standardTextHeight - Helper.standardTextOffsety,
        color = config.sColor.orange,
        halign = "center"
    }
    local rowValueProperties = {
        font = Helper.standardFont,
        fontsize = Helper.standardFontSize,
        x = Helper.standardTextOffsetx,
        y = Helper.standardTextOffsety,
        height = Helper.standardTextHeight - Helper.standardTextOffsety,
        color = config.sColor.grey,
        halign = "left",
    }
    
    menu.headerWarningTextProperties = {
        font = Helper.headerRow1Font,
        fontsize = Helper.scaleFont(Helper.headerRow1Font, Helper.headerRow1FontSize),
        x = Helper.scaleX(Helper.headerRow1Offsetx),
        --y = math.floor((menu.titleData.height - Helper.scaleY(Helper.headerRow1Height)) / 2 + Helper.scaleY(Helper.headerRow1Offsety)),
        --minRowHeight = menu.titleData.height,
        scaling = false,
        cellBGColor = config.Color["row_background"],
        color = function () return menu.warningColor(config.Color["text_warning"]) end,
        titleColor = config.Color["text_warning"],
        halign = "center",
    }
    menu.rowAlertTextProperties = {
        font = Helper.standardFont,
        fontsize = Helper.scaleFont(Helper.standardFont, Helper.standardFontSize),
        x = Helper.scaleX(Helper.standardTextOffsetx),
        y = Helper.scaleX(Helper.standardTextOffsety),
        --y = math.floor((menu.titleData.height - Helper.scaleY(Helper.headerRow1Height)) / 2 + Helper.scaleY(Helper.headerRow1Offsety)),
        --minRowHeight = menu.titleData.height,
        scaling = false,
        cellBGColor = config.Color["row_background"],
        color = function () return menu.warningColor(config.Color.text_enemy) end,
        --titleColor = config.Color.text_enemy,
        halign = "left",
    }

    local statustable, resourcetable, produceownertable, constructiontable, destroytable
    local row

    local fleetIdx = menu.findFleet(menu.selectedfleet)
    if fleetIdx then 

        -- Fleet Details
        -- Satır Ekle - 
        row = ftable:addRow(false, { fixed = true , bgColor = config.sColor.transparent } )
        row[1]:setColSpan(10):createText("Fleet Commander", { halign = "center", font = Helper.headerRow1Font, fontsize = Helper.headerRow1FontSize } )

        row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.grey } )
        row[1]:setColSpan(10):createText("", { height = 1 } )
    
        local fleet, fleetKey, promoted, promotedid, commander, commanderid, sector, sectorcolor, orderid ={}, "", "", "", "", "", "", config.Color.text_normal, ""
        fleet = menu.tablecopy( menu.fleets[fleetIdx] )
        fleetKey = fleet.id
        promoted = fleet.name
        commander = fleet.commander.name
        promotedid = fleet.idcode ~= "" and " ( " .. fleet.idcode .. " ) " or fleet.idcode
        commanderid = fleet.commander.idcode ~= "" and  " ( " .. fleet.commander.idcode .. " ) " or fleet.commander.idcode
        sector = fleet.sector
        sectorcolor = GetFactionData(GetComponentData(fleet.sectorid, "owner"), "color")
        orderid = fleet.order.id
        

        row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
        row[1]:setColSpan(3):createText("Promoted:", rowLabelProperties)
        row[4]:setColSpan(7):createText(promoted ..  promotedid, rowValueProperties)

        row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
        row[1]:setColSpan(3):createText("Real:", rowLabelProperties)
        row[4]:setColSpan(7):createText(commander ..  commanderid, rowValueProperties)

        row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
        row[1]:setColSpan(3):createText("Order Location:", rowLabelProperties)
        if sector ~= "" then
            row[4]:setColSpan(7):createText(sector, rowValueProperties)
            row[4].properties.color = sectorcolor        
        end
    

        row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
        row[1]:setColSpan(3):createText("Default Order:", rowLabelProperties)
        row[4]:setColSpan(7):createText(orderid, rowValueProperties)
        row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
        row[1]:setColSpan(10):createText("", {height = 3})

        local SelectedShip = menu.isSelectedShipLine(menu.shipsTableData.selected)
        local record = SelectedShip and menu.GetRecord(menu.selectedfleet, SelectedShip)
        if record then 
            -- Selected Ship Details
            local name, nameid, commanderidx, commandername, commandernameid, assignment, subordinategroupid, subordinategrouptext = "", "", "", "", "", "", "", ""
            
            local isFleetLeader = (not record.commanderidx or record.commanderidx == -1) and true
            if not record.commanderidx then DebugError("rfm_" .. fleet.id .. "_" .. record.id .. " no have property .commaneridx" ) end
            name = record.name
            nameid = (record.idcode ~= "") and " ( " .. record.idcode .. " ) " or record.idcode
            local location, locationid
            local locationowner 
            local locationownercolor 

            commanderidx = debugW and " ( Ship Key = " .. tostring(record.commanderidx) .. " )" or ""
            commandername = not isFleetLeader and menu.RM_FleetRecords[menu.selectedfleet][record.commanderidx].name or "{ Fleet Commander }"
            commandernameid = not isFleetLeader and menu.RM_FleetRecords[menu.selectedfleet][record.commanderidx].idcode or ""
            subordinategroupid = not isFleetLeader and (debugW and " ( " .. record.subordinategroupid .. " )" or "") or ""
            subordinategrouptext = not isFleetLeader and record.subordinategrouptext or ""
            assignment = not isFleetLeader and config.assignments[record.assignment].name or ""
            -- Selected Ship Destroy Details
            local shipStatus, reBuildTryNum, respondMsg, shipyardname, shipyardsector, shipyardid, statusIcon, statusMoseOverText, passedTime, remainTime = "", 0, "", "", "", "", "", "", "", ""
            reBuildTryNum = record.reBuildTryNum
            shipyardname = record.shipyard.name
            shipyardsector = record.shipyard.sector
            shipyardid = shipyardname ~= "" and  " ( " .. record.shipyard.idcode .. " )" or record.shipyard.idcode
            respondMsg = record.respondMsg
            statusIcon = record.statusIcon
            statusMoseOverText = record.statusMoseOverText
            
            passedTime = function() return menu.getPassedTime(record.destroyedtime and record.destroyedtime or record.reBuildStartTime ) end
            local xremainTime = record.reBuildStartTime and (tonumber(record.reBuildStartTime) + tonumber(menu.editedSettings.NextRetryTime) * 60) + 0.8 or 0
            remainTime = record.reBuildStartTime and function() return menu.getRemainingTime(xremainTime) end or ""

            --[[ConvertMoneyString 
                1. parametre parasal değer
                2. parametre true = cent kısmını gösterir (.yy)
                3. parametre true = tutardaki basamak ayracını (x,xxx,xxx) gösterir
                4. parametre nil = 0, ya da rakam = gösterilecek basamak sayısı
                    (tutardaki basamak sayısı belirtilen rakamdan fazla ise tutarın yanına k, M gibi kısaltma yaparak tutarı belirtir)
                5. parametre hiç bir etki göstermiyor gibi
            ]]
            local fee
            fee = function() return Helper.convertColorToText(config.Color.text_inprogress) .. ConvertMoneyString(GetPlayerMoney(), false, true, nil, true) .. " " .. ReadText(1001, 101) .. "\027X" end
        
            --DebugError(".id = " .. tostring(record.id) .. " .destroyed = " ..  tostring(record.destroyed) .. " ,isWaitingForRebuild = " .. tostring(record.isWaitingForRebuild) .. " ,isLost = " .. tostring(record.isLost) .. " ,build = " .. tostring(record.build) .. " ,.construction = " .. tostring(record.construction.id) .. " ".. tostring(record.construction))  
            if record.destroyed then
                if record.isLost then
                    shipStatus = "Lost Ship. Need manual click to 'Rebuild' proccess.."
                    location = ""
                else
                    if record.build then
                        shipStatus = ""
                        location = record.shipyard.sector
                        locationownercolor = record.shipyard.sectorownercolor
                    else
                        shipStatus = "Waiting for next rebuild check"
                        location = ""
                    end
                end
            else
                location, locationid = GetComponentData(record.object64, "sector", "sectorid") 
                locationowner = GetComponentData(locationid, "owner")
                locationownercolor = GetFactionData(locationowner, "color")
            end


            menu.details = {}
            menu.details.producedowners = {}
            local macroname, ware = GetMacroData( record.macro , "name", "ware")
            if ware then
                local n = C.GetNumWareBlueprintOwners(ware)
                local buf = ffi.new("const char*[?]", n)
                n = C.GetWareBlueprintOwners(buf, n, ware)
                local first = true
                for i = 0, n - 1 do
                    local faction = ffi.string(buf[i])
                    local name = GetFactionData(faction, "name")
                    if IsKnownItem("factions", faction) then
                        --producedby = producedby .. ((producedby ~= "") and " , " or "" ) .. name	-- Produced by
                        table.insert(menu.details.producedowners, faction)
                    end
                end
                local numblueprints = C.GetNumBlueprints("", "", "")
                local blueprints = ffi.new("UIBlueprint[?]", numblueprints)
                numblueprints = C.GetBlueprints(blueprints, numblueprints, "", "", "")
                local playerblueprints = {}
                for i = 0, numblueprints - 1 do
                    local bware = ffi.string(blueprints[i].ware)
                    playerblueprints[bware] = true
                end
                --menu.tablePrint(playerblueprints, "playerblueprints = ", true, true)
                local owned = playerblueprints[ware]
                if owned then
                    table.insert(menu.details.producedowners, "player")
                end
            end


            row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
            row[1]:setColSpan(10):createText("Ship Details", { font = Helper.headerRow1Font, fontsize = Helper.headerRow1FontSize } )
            row[1].properties.halign = "center"

            row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
            row[1]:setColSpan(3):createText("Name:", rowLabelProperties)
            row[4]:setColSpan(7):createText(name .. nameid, rowValueProperties)

            row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
            row[1]:setColSpan(3):createText("Location :", rowLabelProperties)
            if location ~= "" then
                row[4]:setColSpan(7):createText(location, rowValueProperties)
                row[4].properties.color = locationownercolor 
            end

            row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
            row[1]:setColSpan(3):createText("Commander:", rowLabelProperties)
            row[4]:setColSpan(7):createText(commandername .. commandernameid .. (not isFleetLeader and commanderidx or "") , rowValueProperties)

            row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
            row[1]:setColSpan(3):createText(not isFleetLeader and "Sub. group:" or "", rowLabelProperties)
            row[4]:setColSpan(7):createText(subordinategrouptext .. (debugW and subordinategroupid or "" ), rowValueProperties)
            row[4].properties.halign = "left"

            row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
            row[1]:setColSpan(3):createText(not isFleetLeader and "Assignment:" or "", rowLabelProperties)
            row[4]:setColSpan(7):createText(assignment , rowValueProperties)
            row[4].properties.halign = "left"

            -- blinklerin başlayacağız zaman, nil olursa kapanır
            menu.warningShown = getElapsedTime()
            local alertShipPlanMsg = record.tShipPlan and "OK" or "To fix, detach from RFM and reattach"
            local row = ftable:addRow(false, { fixed = true })
            row[1]:setColSpan(3):createText("Loadout Status:", rowLabelProperties)
            row[4]:setColSpan(7):createText(alertShipPlanMsg , menu.rowAlertTextProperties )

            if record.tShipPlan then
                row[4].properties.color = config.sColor.grey
            end

            local ftableheight = ftable:getFullHeight() + Helper.borderSize

            local row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )   
            row[1]:setColSpan(3):createText("Produces Chassis", rowLabelProperties)

            --local ftableheight = ftable:getFullHeight()

            if #menu.details.producedowners > 0 then

                local prodvisibleHeight = nil
                local maxrows = 4
                local totalrows = 0
                -- * tabOrder verilemz ise kaydırma oluşturulmaz, ve tablo içinde kaydırmaya sebep olan satır oluşursa hata verir
                produceownertable = frame:addTable(10, { tabOrder = 8, width = ftable.properties.width, x = ftable.properties.x, y = 0, reserveScrollBar = true, highlightMode = "off", skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })
                --local row = produceownertable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                --row[1]:setColSpan(10):createText("Produced Chassis By:", rowLabelProperties)

                for i, faction in ipairs(menu.details.producedowners) do
                    totalrows = totalrows + 1
                    local factionname, factioncolor = GetFactionData(faction, "name", "color")
                    local row = produceownertable:addRow(true, {  } )   -- kaydırma çubuğu için row true ile açılacak ve properties boş olacak
                    row[4]:setColSpan(6):createText(factionname, rowValueProperties)
                    row[4].properties.color = factioncolor
                    row[4].properties.halign = "center"
                    if totalrows == maxrows then
                        prodvisibleHeight = produceownertable:getFullHeight()
                    end
                end
                if totalrows < maxrows then
                    for i= 1, maxrows - totalrows  do
                        local row = produceownertable:addRow(true, {  } )   -- kaydırma çubuğu için row true ile açılacak ve properties boş olacak
                        row[1]:setColSpan(10):createText(" ", rowValueProperties)
                    end
                end
                if prodvisibleHeight then
                    produceownertable.properties.maxVisibleHeight = prodvisibleHeight
                else
                    produceownertable.properties.maxVisibleHeight = produceownertable:getFullHeight()
                end
                produceownertable.properties.y = ftableheight -- - produceownertable:getVisibleHeight() - 2 * Helper.borderSize
            end

            -- Kılavuz 
            --row = ftable:addRow(false, { fixed = true, bgColor = config.sColor.orange } )
            --row[1]:setColSpan(1):createText("", {})

            local errors = {}
            if record.construction.buildingcontainer then
                constructiontable = frame:addTable(10, { tabOrder = 8, width = ftable.properties.width, x = ftable.properties.x, y = 0, reserveScrollBar = true, highlightMode = "off", skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })

                if not C.HasSuitableBuildModule(record.construction.buildingcontainer, record.construction.component, record.macro) then
                    errors[4] = ReadText(1001, 8563)
                end
            
                local considerCurrent = true
                local numorders = (considerCurrent and 1 or 0)
                local buildorders = ffi.new("UIBuildOrderList[?]", numorders)
                
                --DebugError(".macro = " .. tostring(record.macro) )
                --menu.tablePrint(record.tShipPlan or {}, ".tShipPlan = [" .. tostring(fleetKey) .. "][" .. tostring(SelectedShip) .. "]" , true, true)
                -- YAPILACAK: lua haberleşmeden dolayı record.tShipPlan  oluşmamış olabilir bug vs..  
                -- burda bir plan çıkarabiliriz. ayrıca md ye gödnerebiliriz güncellemek için
                local missingResources = {}
                if record.tShipPlan then
                    -- Mevcut gemi zaten shipyardda ekli, burdan bir daha sorgularsak sanki yeniden ekleme yapılıyor gibi missing resources ekleniyor
                    -- bu yüzden sanki eklenmemiş gibi davranıp (amount = 0) mevcut shipyardın missing değerlrini alacağız
                    if not errors[4] then
                        if considerCurrent then
                            local index = 0
                            buildorders[index].shipid = 0
                            buildorders[index].macroname = Helper.ffiNewString(record.macro)
                            buildorders[index].loadout = Helper.callLoadoutFunction(record.tShipPlan, nil, function (loadout, _) return loadout end, false)
                            buildorders[index].amount = 0
                        end
                        -- uint32_t GetNumMissingBuildResources2(UniverseID containerid, UIBuildOrderList* orders, uint32_t numorders, bool playercase);
                        local playercase = true     -- false yaparsak vizim macrodan hariç istasyonun ihtiyaç duyduğu diğer eksik malzemeler de gelir
                        local n = C.GetNumMissingBuildResources2(record.construction.buildingcontainer, buildorders, numorders, playercase)
                        local buf = ffi.new("UIWareInfo[?]", n)
                        n = C.GetMissingBuildResources(buf, n)
                        for i = 0, n - 1 do
                            table.insert(missingResources, { ware = ffi.string(buf[i].ware), amount = buf[i].amount })
                        end

                        for i = 1, 10 do
                            --table.insert(missingResources, { ware = "Template row", amount = 0 })
                        end
                        --menu.tablePrint(missingResources, "missingResources = [" .. tostring(fleetKey) .. "][" .. tostring(SelectedShip) .. "]" , true, true)
                    end
                end
                -- menu.tablePrint(missingResources, "NET missingResources = [" .. tostring(fleetKey) .. "][" .. tostring(SelectedShip) .. "]" , true, true)

                row = constructiontable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                row[1]:setColSpan(10):createText("Destroy Details" , Helper.subHeaderTextProperties)
                row[1].properties.halign = "center"

                row = constructiontable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                row[1]:setColSpan(2):createText("Station" , rowLabelProperties)
                row[3]:setColSpan(8):createText(Helper.convertColorToText(record.shipyard.factioncolor) .. shipyardname .. shipyardid , rowValueProperties)
                
                row = constructiontable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                row[1]:setColSpan(2):createText("location" , rowLabelProperties)
                row[3]:setColSpan(8):createText(Helper.convertColorToText(record.shipyard.sectorownercolor) .. shipyardsector , rowValueProperties)

                row = constructiontable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                row[1]:setColSpan(10):createText( " " , {} )


                local construction = record.construction 
                local color = (construction.factionid == "player") and config.Color.text_player or config.Color["text_normal"]
                
                --menu.tablePrint(construction, "construction = [" .. tostring(fleetKey) .. "][" .. tostring(SelectedShip) .. "]" , true, true)

                row = constructiontable:addRow({ "construction", record.shipyard.object, construction }, { fixed = true, bgColor = config.sColor.transparent } )
                if construction.inprogress then
                    color = config.sColor.lightgreen

                    -- ReadText(1026, 3223) = The station is missing resources for this build.
                    row[2]:setColSpan(6):createText(name .. " (" .. ffi.string(C.GetObjectIDCode(construction.component)) .. ")", { halign = "left", color = color })
                    row[8]:setColSpan(3):createText(function () return 
                        (construction.ismissingresources and (Helper.convertColorToText(config.Color.text_warning) .. "\27[warning] ") or "") .. 
                        Helper.formatTimeLeft(C.GetBuildProcessorEstimatedTimeLeft(construction.buildercomponent)) ..
                        " ( " .. menu.getShipBuildProgress(construction.component)  .. " ) " 
                        end, 
                        { halign = "right", color = color, mouseOverText = construction.ismissingresources and ReadText(1026, 3223) or "" })            
                else
                    color = config.sColor.darkgreen

                    local duration = errors[4] and 0 or C.GetBuildTaskDuration(construction.buildingcontainer, construction.id)
                    row[2]:setColSpan(6):createText(name, { color = color })
                    row[8]:setColSpan(1):createText("#" .. construction.queueposition , { halign = "center", color = color })
                    row[9]:setColSpan(2):createText(Helper.formatTimeLeft(duration), { halign = "right", color = color })
                end

                row[1]:createButton({  mouseOverText ="Cancel Construction", active = C.CanCancelConstruction(construction.buildingcontainer, construction.id) and ((construction.factionid == "player") or GetComponentData(ConvertStringTo64Bit(tostring(construction.buildingcontainer)), "isplayerowned")) } )
                row[1]:setText("X", { halign = "center" }) 
                row[1].handlers.onClick = function()
                        menu.buttonCancelConstruction(construction.buildingcontainer, construction.id )
                        menu.RM_RebuildCues[fleetKey][SelectedShip] = nil
                        menu.refreshInfoFrame()
                    end 
                
                --
                
                if #missingResources > 0 then
                    resourcetable = frame:addTable(2, { tabOrder = 8, width = ftable.properties.width, x = ftable.properties.x, y = 0, reserveScrollBar = true, highlightMode = "off", skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })
                    
                    local row = resourcetable:addRow(false, { fixed = true, bgColor = config.Color["row_title_background"] })
                    row[1]:setColSpan(2):createText(ReadText(1001, 8046), menu.headerWarningTextProperties)
                    -- disable blink effect
                    --row[1].properties.color = config.Color["text_warning"]

                    local visibleHeight = nil
                    for i, entry in ipairs(missingResources) do
                        local row = resourcetable:addRow(true, {  })
                        row[1]:createText(GetWareData(entry.ware, "name"), { color = config.Color["text_warning"] })
                        row[2]:createText(ConvertIntegerString(entry.amount, true, 0, true), { halign = "right", color = config.Color["text_warning"] })
                        if i == 5 then
                            visibleHeight = resourcetable:getFullHeight()
                        end
                    end

                    if visibleHeight then
                        resourcetable.properties.maxVisibleHeight = visibleHeight
                    else
                        resourcetable.properties.maxVisibleHeight = resourcetable:getFullHeight()
                    end
                    resourcetable.properties.y = frame.properties.height  - resourcetable:getVisibleHeight() - 2 * Helper.borderSize

                end

                constructiontable.properties.y = produceownertable.properties.y + produceownertable:getVisibleHeight()
            end

            menu.respondwares = {}

            if record.isLost or record.isWaitingForRebuild then
                
                local hasenginewares = false
                
                if record.respond.softwares or record.respond.equipmentwares then
                    for i, ware in ipairs(record.respond.softwares) do
                        local entry = {}
                        entry, hasenginewares = menu.Get_respondequipmentinfo(ware)
                        table.insert(menu.respondwares, entry )
                    end
                    for i, ware in ipairs(record.respond.equipmentwares) do
                        local entry = {}
                        entry, hasenginewares = menu.Get_respondequipmentinfo(ware)
                        table.insert(menu.respondwares, entry )
                    end
                    local wareclasssorder = {
                        thruster = 1,
                        engine = 2,
                        shield = 3,
                        missilelauncher = 4,
                        weapon = 5,
                        missileturret = 6,
                        turret = 7,
                        unit = 8,
                        missile = 9,
                        deployable = 10,
                        countermeasure = 11,
                        scanner = 12,
                        software = 13,
                        other = 14,
                    }
                    table.sort(menu.respondwares, function (a, b) return wareclasssorder[a.class] < wareclasssorder[b.class] end)
                end

                destroytable = frame:addTable(13, { tabOrder = 8, width = ftable.properties.width, x = ftable.properties.x, y = 0, reserveScrollBar = true, highlightMode = "off", skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })
                -- Kılavuz 
                --row = destroytable:addRow(false, { fixed = true, bgColor = config.sColor.orange } )
                --row[1]:setColSpan(1):createText("", {})

                row = destroytable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                row[1]:setColSpan(13):createText("Destroy Details", Helper.subHeaderTextProperties)
                row[1].properties.halign = "center"

                row = destroytable:addRow(true, { fixed = true, bgColor = config.sColor.transparent } )
                row[9]:setColSpan(5):createText(passedTime, rowtimeProperties)
                if not record.isLost then
                    row[1]:setColSpan(2):createText("Rebuild", rowLabelProperties)
                    row[3]:setColSpan(2):createText("#" .. tostring(reBuildTryNum) , rowValueProperties)
                    row[3].properties.halign = "center"
                    row[5]:setColSpan(4):createText(remainTime, rowtimeProperties)
                    row[5].properties.halign = "right"
                end

                row = destroytable:addRow(true, { fixed = true, bgColor = config.sColor.transparent } )
                if record.isWaitingForRebuild then
                    row[1]:setColSpan(13):createText(shipStatus , rowValueProperties)
                    row[1].properties.halign = "left"
                else
                    row[1]:setColSpan(13):createText(" " , rowValueProperties)
                end

                

                --row[5]:setColSpan(3):createText( "player money" , { halign="right", color = rowLabelProperties.color } )
                --row[8]:setColSpan(5):createText( fee , {} )
                local totalprice = 0
                local playermoney = GetPlayerMoney()
                local mouseOverTextF 
                local canbuild = nil

                if record.tShipPlan then

                    -- respond ware listesinde birşeyler varsa
                    menu.isremoverespondwares = menu.isremoverespondwares or false
                    if not menu.isremoverespondwares then menu.usestationengines = false end
                    
                    if record.respond.equipmentwares and #record.respond.equipmentwares > 0 then

                        
                        local yard64 = ConvertStringTo64Bit(tostring(record.respond.yard))
                        local name = ffi.string(C.GetComponentName( yard64 ))
                        local idcode = ffi.string(C.GetObjectIDCode( yard64 ))
                        local faction = GetComponentData(yard64, "owner" )
                        local factioncolor = GetFactionData(faction, "color")
                        
                        local enginelots = menu.getEngineSlotsPossibleWaresFromStation(yard64, record.macro, record.tShipPlan )
                        local newshipplan = menu.get_Removed_RespondWares_FromShipPlan(record.tShipPlan, menu.isremoverespondwares and menu.respondwares or {}, record.macro, menu.isremoverespondwares, menu.usestationengines and enginelots )
                        local objectprice, objectcrewprice = menu.get_ShipPriceFromStation(yard64, record.macro, newshipplan, record.tBulkCrew)
                        totalprice = objectprice + objectcrewprice

                        mouseOverTextF = function() return
                            "Object Price = " .. Helper.convertColorToText(config.Color.text_inprogress) .. ConvertMoneyString(objectprice, false, true, nil, true) .. " " .. ReadText(1001, 101) .. "\027X" .. "\n" .. 
                            "Crews Price = " .. Helper.convertColorToText(config.Color.text_inprogress) .. ConvertMoneyString(objectcrewprice, false, true, nil, true) .. " " .. ReadText(1001, 101) .. "\027X" .. "\n" .. 
                            Helper.convertColorToText(factioncolor) .. name .. " " .. idcode .. "\027X" .. "\n" ..
                            "Player Money = " .. Helper.convertColorToText(config.Color.text_inprogress) .. ConvertMoneyString(playermoney, false, true, nil, true) .. " " .. ReadText(1001, 101) .. "\027X"
                        end

                        local mouseOverText = "When checked, the 'reBuild' button takes action by removing all problematic ware(s)\n" .. 
                        Helper.convertColorToText(config.Color.text_enemy) .. "   The ship's loadout record will NOT change." .. "\027X"
                        row = destroytable:addRow(true, { fixed = true, bgColor = config.sColor.transparent, } )
                        row[2]:setColSpan(10):createText("Remove all listed respond ware(s)", { color = config.sColor.alertnormal, halign = "left", mouseOverText = mouseOverText })
                        row[12]:createCheckBox(menu.isremoverespondwares , { active = true, mouseOverText = mouseOverText, height = Helper.standardTextHeight, width = Helper.standardTextHeight })
                        row[12].handlers.onClick = function (_, checked)
                            menu.isremoverespondwares = checked
                            if not checked then menu.usestationengines = false end
                            menu.refreshInfoFrame()
                            end
                        
                        mouseOverText = "If it is checked, when the rebuild process is done, it selects a suitable engine(s) from the station's defined engines instead of incompatible engines."
                        menu.usestationengines = menu.usestationengines or false
                        if hasenginewares then
                            row = destroytable:addRow(true, { fixed = true, bgColor = config.sColor.transparent, } )
                            row[2]:setColSpan(10):createText("Replace engine(s) from station's defined engines", { color = (menu.isremoverespondwares and hasenginewares) and config.sColor.alerthigh or config.Color.text_inactive , halign = "left", mouseOverText = mouseOverText })
                            row[12]:createCheckBox(menu.usestationengines , { active = (menu.isremoverespondwares and hasenginewares), mouseOverText = mouseOverText, height = Helper.standardTextHeight, width = Helper.standardTextHeight })
                            row[12].handlers.onClick = function (_, checked)
                                menu.usestationengines = checked
                                menu.refreshInfoFrame()
                                end
                        end
                        canbuild = (playermoney >= totalprice) and true or false
                    end
                end

                

                if record.respond.equipmentwares and #record.respond.equipmentwares > 0 then
                    row = destroytable:addRow(true, { fixed = true, bgColor = config.sColor.transparent, } )
                    row[2]:setColSpan(3):createText("Build Price", { color = rowLabelProperties.color , halign = "right", mouseOverText = mouseOverTextF })
                    row[5]:setColSpan(5):createText( ConvertMoneyString(totalprice, false, true, nil, true) .. " " .. ReadText(1001, 101), { color = config.Color.text_inprogress , halign = "right" , mouseOverText = mouseOverTextF})

                    row = destroytable:addRow(true, { fixed = true, bgColor = config.sColor.transparent, } )
                    row[10]:setColSpan(3):createButton({  mouseOverText ="Rebuild process for this ship", active = canbuild and record.isWaitingForRebuild  or record.isLost or false  } )
                    row[10]:setText("Rebuild", { halign = "center" }) 
                    row[10].handlers.onClick = function() return menu.buttonRebuild() end
                        
                    row[2]:setColSpan(3):createText("Player Money", { color =  rowLabelProperties.color , halign = "right", mouseOverText = mouseOverTextF })
                    row[5]:setColSpan(5):createText( ConvertMoneyString(playermoney, false, true, nil, true) .. " " .. ReadText(1001, 101), { color = canbuild and config.Color.text_positive or config.Color.text_negative , halign = "right" , mouseOverText = mouseOverTextF})
                else
                    row = destroytable:addRow(true, { fixed = true, bgColor = config.sColor.transparent, } )
                    row[10]:setColSpan(3):createButton({  mouseOverText ="Rebuild process for this ship", active = record.isWaitingForRebuild  or record.isLost or false  } )
                    row[10]:setText("Rebuild", { halign = "center" }) 
                    row[10].handlers.onClick = function() return menu.buttonRebuild() end
                end

                -- record.isLost olanları da respond mesaj alalnında göster
                record.respond.statusmsg = record.respond.statusmsg or record.isLost and shipStatus
                
                --menu.warningShown = getElapsedTime()
                local visibleHeight = nil
                if record.respond.statusmsg then
                    resourcetable = frame:addTable(10, { tabOrder = 8, width = ftable.properties.width, x = ftable.properties.x, y = 0, reserveScrollBar = true, highlightMode = "off", skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })

                    local row = resourcetable:addRow(false, { fixed = true, bgColor = config.Color["row_title_background"] } )
                    row[1]:setColSpan(10):createText("Respond Message", menu.headerWarningTextProperties)

                    
                    local textTable = GetTextLines(tostring(record.respond.statusmsg), rowLabelProperties.font, rowLabelProperties.fontsize, resourcetable.properties.width - 2* Helper.borderSize)
                    local TextLines = {}
                    for i, line in ipairs(textTable) do
                        local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                        row[1]:setColSpan(10):createText(line , rowLabelProperties)
                        
                    end
                
                    --local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                    --row[1]:setColSpan(10):createText(tostring(record.respond.statusmsg) , rowLabelProperties)
                
                    if record.respond.class then
                        local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                        row[1]:setColSpan(10):createText( "Class = " .. tostring(record.respond.class)  , rowLabelProperties)
                    end
                    if record.respond.chassis then
                        local name = ffi.string( GetMacroData(record.respond.chassis, "name") )
                        local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                        row[1]:setColSpan(10):createText( "Chassis = " .. name  , rowLabelProperties)
                    end
                    if record.respond.faction then
                        local factionname, factioncolor = GetFactionData(record.respond.faction, "name", "color")
                        local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                        row[1]:setColSpan(2):createText( "Faction", rowLabelProperties)
                        row[3]:setColSpan(8):createText( factionname, rowLabelProperties)
                        row[3].properties.color = factioncolor
                    end
                    if record.respond.yard then
                        local yard64 = ConvertStringTo64Bit( tostring(record.respond.yard) )
                        local name = ffi.string(C.GetComponentName( yard64 ))
                        local idcode = ffi.string(C.GetObjectIDCode( yard64 ))
                        local faction = GetComponentData(yard64, "owner" )
                        local factioncolor = GetFactionData(faction, "color")
                        local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                        row[1]:setColSpan(2):createText( "Station", rowLabelProperties)
                        row[3]:setColSpan(8):createText( name .. " ( " .. idcode .. " )"  , rowLabelProperties)
                        row[3].properties.color = factioncolor
                    end
                    if record.respond.unknown then
                        local yard64 = ConvertStringTo64Bit( tostring(record.respond.unknown) )
                        local name = ffi.string(C.GetComponentName( yard64 ))
                        local idcode = ffi.string(C.GetObjectIDCode( yard64 ))
                        local faction, sectorid, sector = GetComponentData(yard64, "owner", "sectorid", "sector")
                        local factioncolor = GetFactionData(faction, "color")
                        local sectorowner = GetComponentData(sectorid, "owner")
                        local sectorownercolor = GetFactionData(sectorowner, "color")

                        local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                        row[1]:setColSpan(2):createText( "Station", rowLabelProperties)
                        row[3]:setColSpan(8):createText( name .. " ( " .. idcode .. " )"  , rowLabelProperties)
                        row[3].properties.color = factioncolor

                        local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                        row[1]:setColSpan(2):createText( "Sector", rowLabelProperties)
                        row[3]:setColSpan(8):createText( sector  , rowLabelProperties)
                        row[3].properties.color = sectorownercolor
    
                    end
                    -- Kılavuz 
                    --row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.orange } )
                    --row[1]:setColSpan(1):createText("", {})

                    if record.respond.price then
                        local price = ConvertMoneyString(record.respond.price, false, true, 0, true)
                        local playermoney = record.respond.playermoney and ConvertMoneyString(record.respond.playermoney, false, true, 0, true) or ""
                        local aftermoney = record.respond.playermoney and ConvertMoneyString(record.respond.playermoney - record.respond.price, false, true, 0, true) or ""
                        local checkmoney = record.respond.checkmoney and ConvertMoneyString(record.respond.checkmoney, false, true, 0, true) or ""
                        local fundsmoney = record.respond.fundsmoney and ConvertMoneyString(record.respond.fundsmoney, false, true, 0, true) or ""
                        if record.respond.playermoney then
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "Player Money", {color = rowLabelProperties.color, halign = "left" } )
                            row[6]:setColSpan(3):createText( playermoney .. " Cr", {color = rowValueProperties.color, halign = "right" } )
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "Ship Price", {color = rowLabelProperties.color, halign = "left" } )
                            row[6]:setColSpan(3):createText( price .. " Cr", {color = rowValueProperties.color, halign = "right", titleColor = config.sColor.grey  } )
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "After Reducing", {color = config.sColor.lightgrey, halign = "left" } )
                            row[6]:setColSpan(3):createText( aftermoney .. " Cr", {color = config.sColor.orange, halign = "right" } )
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "Threshold Money", {color = config.sColor.lightgrey, halign = "left" } )
                            row[6]:setColSpan(3):createText( checkmoney .. " Cr", {color = config.sColor.grey, halign = "right" } )
                        elseif record.respond.fundsmoney then
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "Player Money", {color = config.sColor.lightgrey, halign = "left" } )
                            row[6]:setColSpan(3):createText( fundsmoney .. " Cr", {color = config.sColor.orange, halign = "right" } )
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "Ship Price", {color = config.sColor.lightgrey , halign = "left" } )
                            row[6]:setColSpan(3):createText( price .. " Cr", {color = config.sColor.grey, halign = "right" } )
                        else
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "Ship Price", {color = config.sColor.lightgrey , halign = "left" } )
                            row[6]:setColSpan(3):createText( price .. " Cr", {color = config.sColor.orange, halign = "right" } )
                            local row = resourcetable:addRow(false, { fixed = true, bgColor = config.sColor.transparent } )
                            row[3]:setColSpan(3):createText( "Allowed Money", {color = config.sColor.lightgrey, halign = "left" } )
                            row[6]:setColSpan(3):createText( checkmoney .. " Cr", {color = config.sColor.grey, halign = "right" } )
                        end
                    end

                    -- döngü içinde row açılıcak , table scroll etkisi alacak bu yüzden table açılırken taborder > 0 verilmeli ve döngü  row lar true ile oluşturulmalı
                    local maxrows = 5
                    local totalrows = 0
                    if #menu.respondwares > 0 then
                        for i, ware in ipairs(menu.respondwares) do
                            totalrows = totalrows + 1
                            local row = resourcetable:addRow(true, {  } )
                            local color = (ware.class == "engine") and config.sColor.alertnormal or config.sColor.blue
                            row[1]:setColSpan(3):createText( "#" .. tostring(totalrows) .. " " .. ware.type , {color = rowValueProperties.color })
                            row[4]:setColSpan(7):createText( ware.name, {color = color })
                            if totalrows == maxrows then
                                visibleHeight = resourcetable:getFullHeight()
                            end
                        end
                    elseif record.respond.objects then
                        for i, line in ipairs(record.respond.objects) do
                            totalrows = totalrows + 1
                            local yard64 = ConvertStringTo64Bit( tostring(line) )
                            local name = ffi.string(C.GetComponentName( yard64 ))
                            local idcode = ffi.string(C.GetObjectIDCode( yard64 ))
                            local row = resourcetable:addRow(true, { bgColor = config.sColor.transparent } )
                            row[1]:setColSpan(2):createText( "Station #" .. tostring(i) , {color = config.sColor.blue })
                            row[3]:setColSpan(8):createText( name .. " " .. idcode, {color = rowValueProperties.color })
                            if totalrows == maxrows then
                                visibleHeight = resourcetable:getFullHeight()
                            end
                        end
                    elseif  record.respond.missinglicencedwares then
                        local missinglicencedwares = {}
                        for i, entry in ipairs(record.respond.missinglicencedwares) do
                            local entry2 = {}
                            entry2, _ = menu.Get_respondequipmentinfo(entry.ware)
                            entry2.licencetype = entry.licencetype
                            entry2.faction = entry.faction
                            table.insert(missinglicencedwares, entry2)
                        end

                        for i, entry in ipairs(missinglicencedwares) do
                            totalrows = totalrows + 1
                            local row = resourcetable:addRow(true, {  } )

                            row[1]:setColSpan(2):createText( "#" .. tostring(totalrows) .. " " .. entry.type , {color = rowValueProperties.color })
                            row[3]:setColSpan(4):createText( entry.name, {color = config.sColor.blue })
                            row[7]:setColSpan(4):createText( entry.licencetype, {color = config.sColor.alertnormal })
                            if totalrows == maxrows then
                                visibleHeight = resourcetable:getFullHeight()
                            end
                        end
                    end



                end
                if visibleHeight then
                    resourcetable.properties.maxVisibleHeight = visibleHeight
                else
                    resourcetable.properties.maxVisibleHeight = resourcetable:getFullHeight()
                end
                resourcetable.properties.y = frame.properties.height  - resourcetable:getVisibleHeight() - 2 * Helper.borderSize

                destroytable.properties.y = produceownertable.properties.y + produceownertable:getVisibleHeight()
            end

        end
    end

    
    -- Arada kalan bölgeyi kapatmak için
    local font, map_fontsize = Helper.standardFont, Helper.standardFontSize
    local map_textheight = math.ceil(C.GetTextHeight(" ", font, Helper.scaleFont(font, map_fontsize), 0)) 
    local buttonHeight = Helper.standardTextHeight
    --DebugError("map_textheight = " .. tostring(map_textheight) .. " , buttonHeight = " .. tostring(buttonHeight))
    --DebugError("FRAME .properties.height = " .. tostring(frame.properties.height) .." , :getAvailableHeight() = " .. tostring(frame:getAvailableHeight()) .. " , Helper.borderSize = " .. tostring(Helper.borderSize) )
    --DebugError("TABLE :hasScrollBar() = " .. tostring(ftable:hasScrollBar()) .. " , .properties.y = " .. tostring(ftable.properties.y) .. " , :getVisibleHeight() = " .. tostring(ftable:getVisibleHeight()) .. " , :getMaxVisibleHeight() = " .. tostring(ftable:getMaxVisibleHeight()) .. " , :getFullHeight() = " .. tostring(ftable:getFullHeight())  )
    -- boşluk kaldığını varsayıyorum şu an
    ftable.properties.maxVisibleHeight = ftable:getVisibleHeight() 
    --DebugError("      :getVisibleHeight() = " .. tostring(ftable:getVisibleHeight()) .. " , :getMaxVisibleHeight() = " .. tostring(ftable:getMaxVisibleHeight()) )
    
    local fheight
    if resourcetable then   -- recorddetails ve construct details vardır
        fheight = (resourcetable.properties.y - (2*Helper.borderSize) )
    else
        fheight = (frame.properties.height - (1*Helper.borderSize) )
        --fheight = (resourcetable and (resourcetable.properties.y - (2*Helper.borderSize) ) or (frame.properties.height - (1*Helper.borderSize) )) -  ftable.properties.maxVisibleHeight - 2*Helper.borderSize    
    end
    fheight = fheight - ftable.properties.maxVisibleHeight - 2*Helper.borderSize    

    --DebugError("     , resourcetable.y = " .. tostring((resourcetable and resourcetable.properties.y or nil ) ) ..  " , fheight = " .. tostring(fheight) )
    local freetable
    freetable = frame:addTable(2, {borderEnabled = false, reserveScrollBar = false, width = ftable.properties.width, x = ftable.properties.x, y = 0,highlightMode = "off", skipTabChange = true, backgroundID = "solid", backgroundColor = config.Color.table_background_3d_editor })

    local rowcount = math.floor( (fheight + Helper.borderSize) / (map_textheight + Helper.borderSize) )
    local kalan = (fheight - (map_textheight * rowcount) - (rowcount -1) * Helper.borderSize)
    --DebugError(" row count = " .. tostring(rowcount) .. " , kalan = " .. tostring(kalan ))
    for i=1, rowcount do
        row = freetable:addRow(false, { bgColor = config.sColor.grey } )
        row[1]:setColSpan(2):createText(" ", { font = font, fontsize = map_fontsize })
        --DebugError("i = ".. tostring(i) .. " , Row height = " .. tostring(row:getHeight() ) .. " , :getVisibleHeight() = " .. tostring(freetable:getVisibleHeight()) .. "  , :getMaxVisibleHeight() = " .. tostring(freetable:getMaxVisibleHeight()) .. " , :getFullHeight() = " .. tostring(freetable:getFullHeight())  )
    end
    -- getMaxVisibleHeight() değeri, .y bilgisine göre kalan yeri otomatik hesaplıyor. güncelleme için .y değerine atama yapalım
    freetable.properties.y = ftable.properties.y + ftable:getVisibleHeight() + 2*Helper.borderSize
    --DebugError("TABLE freetable :hasScrollBar() = " .. tostring(freetable:hasScrollBar()) .. " , .properties.y = " .. tostring(freetable.properties.y) .. " , :getVisibleHeight() = " .. tostring(freetable:getVisibleHeight()) .. " , :getMaxVisibleHeight() = " .. tostring(freetable:getMaxVisibleHeight()) .. " , :getFullHeight() = " .. tostring(freetable:getFullHeight())  )

    local eksik = math.floor((freetable:getMaxVisibleHeight() - freetable:getVisibleHeight()) / 5) -- height = 5  (fontsize 1 , minrowheight 1 için)
    --DebugError(" eksik = " .. tostring(eksik))
    -- framenin alt hizasını aşmaması için kalanı 1 eksik kadar yazdıracağız
    for i = 1, eksik -1 do
        row = freetable:addRow(false, {  } )
        row[1]:setColSpan(2):createText(" ", { fontsize = 1, minRowHeight = 1 })
    end
    freetable.properties.maxVisibleHeight = freetable:getVisibleHeight()
    freetable.properties.y = ftable.properties.y + ftable:getVisibleHeight() + 2*Helper.borderSize

    
    --DebugError("TABLE freetable :hasScrollBar() = " .. tostring(freetable:hasScrollBar()) .. " , .properties.y = " .. tostring(freetable.properties.y) .. " , :getVisibleHeight() = " .. tostring(freetable:getVisibleHeight()) .. " , :getMaxVisibleHeight() = " .. tostring(freetable:getMaxVisibleHeight()) .. " , :getFullHeight() = " .. tostring(freetable:getFullHeight())  )

    return ftable
end


function menu.Get_respondequipmentinfo(ware)
    
    local hasenginewares = false
    local name, transport, macro, tags = GetWareData(ware, "name", "transport", "component", "tags")
    local class = "other"
    local type = "other"
    if transport == "equipment" and macro ~= "" then
        if IsMacroClass(macro, "engine") then
            class = "engine"
            type = "engine"
            if tags["thruster"] then
                type = "thruster"
            end
            hasenginewares = true
        elseif IsMacroClass(macro, "shieldgenerator") then
            class = "shield"
            type = "shield"
        elseif IsMacroClass(macro, "missilelauncher") then
            class = "missilelauncher"
            type = "weapon"
        elseif IsMacroClass(macro, "missileturret") then
            class = "missileturret"
            type = "turret"
        elseif IsMacroClass(macro, "turret") then   -- özellikle önce turret mı diye bakacağız, yoksa turretlar da weapon sınıfıdır.
            class = "turret"
            type = "turret"
        elseif IsMacroClass(macro, "weapon") then
            class = "weapon"
            type = "weapon"
        elseif IsMacroClass(macro, "missile") then
            class = "missile"
            type = "missile"
        elseif IsMacroClass(macro, "countermeasure") then
            class = "countermeasure"
            type = "countermeasure"
        elseif GetMacroData(macro, "isunit") then
            class = "unit"
            type = "drone"
        elseif GetMacroData(macro, "isdeployable") then
            class = "deployable"
            type = "deployable"
        elseif IsMacroClass(macro, "scanner") then
            class = "scanner"
            type = "software"
        end
    elseif transport == "software" then
        class = "software"
        type = "software"
    end

    return {name = name, transport = transport, type = type, macro = macro, class = class , ware = ware, tags = tags}, hasenginewares
end




-- ----------------------------------------------------
-- WIDGETS
-- ----------------------------------------------------

function menu.Set_Md_Settings(changedProperty)

    local controlID = "changed.EditingSettings"
    local screenParam = { menu.editedSettings, changedProperty }
    AddUITriggeredEvent(menu.name, controlID, screenParam)
   
end

function menu.buttonReEnable()
    local xdebug = debug0 and DebugError("menu.buttonReEnable")
    local rfmKey = menu.selectedfleet
    --PlaySound("rfm_enable")

    local controlID = "ReEnable"
    local screenParam = {rfmKey}
    AddUITriggeredEvent(menu.name, controlID, screenParam)

    menu.refreshInfoFrame()

end
function menu.buttonDisable()

    local xdebug = debug0 and DebugError("menu.buttonDisable")

    local rfmKey = menu.selectedfleet

    PlaySound("rfm_disable")

    menu.tableremoveKey(menu.RM_Fleets, rfmKey)
    menu.initDataFromMdData()

    menu.selectedfleet = nil
    menu.changedFleet = true
    menu.shipsTableData.selected = nil
    menu.shipsTableData.selectedGroup = nil
    menu.refreshInfoFrame()

    local controlID = "Disabled"
    local screenParam = {rfmKey}
    AddUITriggeredEvent(menu.name, controlID, screenParam)
    
end

function menu.buttonAutoBuildChanged()

    local xdebug = debug0 and DebugError("menu.buttonAutoBuildChanged")
    PlaySound("rfm_click")

    local rfmKey = menu.selectedfleet
    
    local controlID = "changed.autobuild"
    local screenParam = {rfmKey}

    AddUITriggeredEvent(menu.name, controlID, screenParam)
   
end


function menu.buttonCancelConstruction(container, buildtaskid)
	--bool CancelConstruction(UniverseID containerid, BuildTaskID id);
	--bool CanCancelConstruction(UniverseID containerid, BuildTaskID id);
    --DebugError("container  = " .. tostring(container) .. " buildtaskid = " .. tostring(buildtaskid))
    if C.CanCancelConstruction(container, buildtaskid) then
        C.CancelConstruction(container, buildtaskid)
        --DebugError("Canceled construction ".. "container  = " .. tostring(container) .. " buildtaskid = " .. tostring(buildtaskid))
    end
end

function menu.buttonRebuild()

    PlaySound("rfm_click")
        
    local xdebug = debug0 and DebugError("menu.buttonRebuild")
    local rfmKey = menu.selectedfleet
    local shipKey = menu.shipsTableData.selected
    local BuildTaskID

    local record = menu.GetRecord(menu.selectedfleet, menu.shipsTableData.selected) 
    local isremoverespondwares = menu.isremoverespondwares or false
    local usestationengines = menu.usestationengines or false
    local yardLua = record.respond.yard
    local yard64 = ConvertStringTo64Bit(tostring(record.respond.yard))
    
    local newshipplan = menu.tablecopy(record.tShipPlan)

    -- specbuilt
    -- isremoverespondwares seçilmemiş ise zaten planda bir değişiklik yapılmadı neden luadan üretelim?
    if #menu.respondwares > 0 and  isremoverespondwares then
    
        local isplayerowned = GetComponentData(yard64, "isplayerowned")

        local enginelots = menu.getEngineSlotsPossibleWaresFromStation(yard64, record.macro, record.tShipPlan )
        newshipplan = menu.get_Removed_RespondWares_FromShipPlan(record.tShipPlan, menu.respondwares, record.macro, true, usestationengines and enginelots )
        --menu.tablePrint(newshipplan , " AFTER_1 newshipplan [" .. tostring(rfmKey) .. "][".. tostring(shipKey) .. "]" , true, true)
        local objectprice, objectcrewprice = menu.get_ShipPriceFromStation(yard64, record.macro, newshipplan, record.tBulkCrew)
        
        local haspaid 
        if not isplayerowned then
            -- Peşin ödeyin, inşaat tamamlandığında parayı alın
            if (objectprice + objectcrewprice) > 0 then
                TransferPlayerMoneyTo( 1 * (objectprice + objectcrewprice), yard64)
                haspaid = objectprice + objectcrewprice
            end
        end

        --[[
            Task eklediğimizde olan olaylar:
                buildercomponent = 0, queueposition > 0 ve component = 0 değerlerindedir
                1- md içinde anında event_player_build_added tetikleniyor (sadece build ve istasyon bilgileri aktif oluyor)
                2- henüz biz lua içinden çıkamış oluyoruz
                3- luadan çıktıktan sonra
                    a - progress başlamış olabilir queueposition = 0, buildercomponent(processor) > 0 ve component > 0
                        md içindeki olayları geciktireceğiz
                        luadan çıktıktan sonra  
                            * rfm key bilgileri ve taskinfo bilgileri md içine gönderiyoruz
                            * md build_add build_started başladığında bu bilgilerle kıyaslıyarak takibini yapıyoruz
                    b - başlatma takibini burda yapmadığımız için addtask verdiğimiz anda progress false dır ve queueposition > 0 olacaktır
                * - queueposition > 0, buildercomponent(processor) = 0 ve component = 0 (malzeme eksikliği)
                * - queueposition > 0, buildercomponent(processor) = 0 ve component = 0 (tüm processors ler dolu)
        ]]
        
        BuildTaskID = menu.add_build_to_construct_ship( yard64, record.macro, newshipplan, record.tIndividualInstructions, record.tBulkCrew, record.name, haspaid, (objectprice + objectcrewprice) )
        
        --[[
        typedef struct {
            BuildTaskID id;
            UniverseID buildingcontainer;
            UniverseID component;
            const char* macro;
            const char* factionid;
            UniverseID buildercomponent;
            int64_t price;
            bool ismissingresources;
            uint32_t queueposition;
        } BuildTaskInfo;
        BuildTaskInfo GetBuildTaskInfo(BuildTaskID id);
        ]]
        local buildtaskinfo = C.GetBuildTaskInfo(BuildTaskID)
        local taskid_LUA =  ConvertStringToLuaID(tostring(BuildTaskID))
        local taskid_64 =   ConvertStringTo64Bit(tostring(taskid_LUA))
        
        --SetNPCBlackboard(playerID, "$BuildTaskID", { tonumber(BuildTaskID), tonumber(taskid_LUA),  tonumber(taskid_64) } )

        local entry = { 
            id                  = buildtaskinfo.id, 
            buildingcontainer   = buildtaskinfo.buildingcontainer, 
            component           = buildtaskinfo.component, 
            buildercomponent    = buildtaskinfo.buildercomponent, 
            queueposition       = buildtaskinfo.queueposition,
            macro               = ffi.string(buildtaskinfo.macro),
            factionid           = ffi.string(buildtaskinfo.factionid), 
            price               = buildtaskinfo.price, 
            ismissingresources  = buildtaskinfo.ismissingresources,
            time                = C.GetCurrentGameTime(),
            BuildTaskID         = BuildTaskID,

        }
        --menu.tablePrint(entry, " entry buildtaskinfo = ", true, true)
        
        local buildingcontainer64 = ConvertStringTo64Bit(tostring(buildtaskinfo.buildingcontainer))
        local component64 = ConvertStringTo64Bit(tostring(buildtaskinfo.component))
        local buildercomponent64 = ConvertStringTo64Bit(tostring(buildtaskinfo.buildercomponent))

        if buildingcontainer64 ~= 0 then
            AddUITriggeredEvent(menu.name, "BuildTaskID", { 
                rfmKey, 
                shipKey, 
                ConvertStringToLuaID(tostring(entry.id)), 
                ConvertStringToLuaID(tostring(entry.buildingcontainer)), 
                ConvertStringToLuaID(tostring(entry.component)), 
                ConvertStringToLuaID(tostring(entry.buildercomponent)), 
                entry.queueposition, 
                entry.macro, 
                tonumber(entry.price), 
                entry.ismissingresources, 
                entry.time,
                tonumber(BuildTaskID)
            } )
            
        end
        
        menu.isremoverespondwares = false
    else
        local controlID = "Rebuild"
        local screenParam = {rfmKey, shipKey}
        AddUITriggeredEvent(menu.name, controlID, screenParam)
    end

    
    local report = {
        __RFM = rfmKey,
        __ShipKey = shipKey,
        _removerespondwares = isremoverespondwares,
        _usestationengines = usestationengines,
        isWaitingForRebuild = record.isWaitingForRebuild,
        tShipPlan = record.tShipPlan and true or false,
        yard64 = yard64,
        yardLua = yardLua
    }
    --menu.tablePrint(report, " report = " )

end


function menu.buttonOnShowMap()
    -- LUA idleri   ID : xxxx
    -- 64 idleri    xxxx
    -- MD ile lua arasındaki alınıp verilen sayısal veriler LUA tipi olmalı 
    local xdebug = debug0 and DebugError("menu.buttonOnShowMap")
    local rfmKey = menu.selectedfleet
    local rfmKeyIndex = menu.findFleet(rfmKey)
    local shipKey = menu.shipsTableData.selected

    local record = menu.GetRecord(rfmKey, shipKey)
    
    local object, object64, objectLUA
    local name, sectorid, sector, sector64, sectorLUA
    local showzone, focuscomponent

    if record.object == nil then
        object = record.shipyard.object
    else
        object = record.object
    end
    local object64 = ConvertStringTo64Bit(tostring(object))
    local objectLUA = ConvertStringToLuaID(tostring(object))
    name, sector, sectorid = GetComponentData(object64, "name", "sector", "sectorid")
    sector64 = ConvertIDTo64Bit(sectorid)
    sectorLUA = ConvertStringToLuaID(tostring(sector64))
    local textDebug = string.format(
        [[
        name =  %s
        object= %s
        object64 = %s
        objectLUA = %s
        sectorid = %s (%s)
        sector64 = %s
        sectorLUA = %s ]], name, object, object64, objectLUA, sectorid, sector, sector64, sectorLUA
    )
    
    if IsValidComponent(object) then
        
        local xdebug = debug2 and DebugError(textDebug)
        --local returnparam = { 'show_on_map_target', objectLUA }
        Helper.closeMenuAndReturn(menu, nil)

        local controlID = "show_on_map_target"
        local screenParam = objectLUA
        AddUITriggeredEvent(menu.name, controlID, screenParam)

        menu.cleanup()
    else
        PlaySound("ui_notification_pickup_fail")
        menu.refreshInfoFrame()
    end    

end

function menu.buttonRemoveShip()
    PlaySound("rfm_click")

    local xdebug = debug0 and DebugError("menu.buttonRebuild")
    local rfmKey = menu.selectedfleet
    local shipKey = menu.shipsTableData.selected

    menu.shipsTableData.selected = nil

    local controlID = "RemoveShip"
    local screenParam = {rfmKey, shipKey}
    AddUITriggeredEvent(menu.name, controlID, screenParam)
    
end

function menu.buttonRestoreDefault()
    PlaySound("rfm_click")
    menu.editedSettings = menu.tablecopy(menu.defaultSettings)
    menu.Set_Md_Settings("Reset to Default Settings " )
    menu.display()
end

function menu.checkbox_ShowInNotification(_, checked)
	menu.editedSettings.shownotification = checked
    menu.Set_Md_Settings("shownotification " .. tostring(menu.editedSettings.shownotification))
end
function menu.checkbox_showhelp(_, checked)
	menu.editedSettings.showhelp = checked
    menu.Set_Md_Settings("showhelp " .. tostring(menu.editedSettings.showhelp))
end
function menu.checkbox_write_to_logbook(_, checked)
	menu.editedSettings.write_to_logbook = checked
    menu.Set_Md_Settings("write_to_logbook " .. tostring(menu.editedSettings.write_to_logbook))
end

function menu.checkbox_UsePlayerYards(_, checked)
	menu.editedSettings.UsePlayerYards = checked
    menu.Set_Md_Settings("UsePlayerYards " .. tostring(menu.editedSettings.UsePlayerYards))
end
function menu.checkbox_UseNPCYards(_, checked)
	menu.editedSettings.UseNPCYards = checked
    menu.Set_Md_Settings("UseNPCYards " .. tostring(menu.editedSettings.UseNPCYards))
end

function menu.checkbox_blacklist(checked, component64)
    
    --DebugError("checked = [" .. tostring(checked) .. "]  , component = " .. tostring(component64) .. " name = " .. GetComponentData(component64, "name") .. " " .. ffi.string(C.GetObjectIDCode(component64)) .. " sector = " .. GetComponentData(component64, "sector"))

    --menu.tablePrint(menu.blacklist_stations, "BEFORE .blacklist_stations = ", true, true)

    if checked then
        table.insert(menu.blacklist_stations, ConvertStringToLuaID(tostring(component64)))
        --menu.tablePrint(menu.blacklist_stations, "ADDED .blacklist_stations = " , true, true)
    else
        for k,v in ipairs(menu.blacklist_stations) do
            if ConvertStringTo64Bit(tostring(v)) == component64 then
                table.remove(menu.blacklist_stations, k)
                --menu.tablePrint(menu.blacklist_stations, "REMOVED .blacklist_stations = " .. tostring(k), true, true)
                break
            end
        end
    end

    AddUITriggeredEvent(menu.name, "changed.blacklist", menu.blacklist_stations)

    --menu.refreshInfoFrame()

end

local function changed_buildstations()
    playerID = playerID or ConvertStringTo64Bit(tostring(C.GetPlayerID()))
    menu.active_stations = GetNPCBlackboard(playerID, "$active_stations")
    menu.blacklist_stations = GetNPCBlackboard(playerID, "$blacklist_stations")
    menu.refreshInfoFrame()
end
RegisterEvent("buildstations.changed", changed_buildstations)




function menu.checkbox_ValidUpdatesPYardsequipments(_, checked)
	menu.editedSettings.ValidUpdates.PYards.equipments = checked
    menu.Set_Md_Settings("ValidUpdates.PYards.equipments " .. tostring(menu.editedSettings.ValidUpdates.PYards.equipments))
end
function menu.checkbox_ValidUpdatesPYardspeoples(_, checked)
	menu.editedSettings.ValidUpdates.PYards.peoples = checked
    menu.Set_Md_Settings("ValidUpdates.PYards.peoples " .. tostring(menu.editedSettings.ValidUpdates.PYards.peoples))
end
function menu.checkbox_ValidUpdatesNYardsequipments(_, checked)
	menu.editedSettings.ValidUpdates.NYards.equipments = checked
    menu.Set_Md_Settings("ValidUpdates.NYards.equipments " .. tostring(menu.editedSettings.ValidUpdates.NYards.equipments))
end
function menu.checkbox_ValidUpdatesNYardspeoples(_, checked)
	menu.editedSettings.ValidUpdates.NYards.peoples = checked
    menu.Set_Md_Settings("ValidUpdates.NYards.peoples " .. tostring(menu.editedSettings.ValidUpdates.NYards.peoples))
end



function menu.slidercell_NextRetryTime(_, value)
	menu.editedSettings.NextRetryTime = value
    menu.Set_Md_Settings("NextRetryTime " .. tostring(value))
end
function menu.slidercell_playermoneythreshold(_, value)
	menu.editedSettings.playermoneythreshold = value
    menu.Set_Md_Settings("playermoneythreshold " .. tostring(value))
end
function menu.slidercell_maxallowedpricepership(_, value)
	menu.editedSettings.maxallowedpricepership = value
    menu.Set_Md_Settings("maxallowedpricepership " .. tostring(value))
end


function menu.checkbox_DebugChance(_, checked)
	menu.editedSettings.DebugChance = checked and 100 or 0
    menu.Set_Md_Settings("DebugChance " .. tostring(menu.editedSettings.DebugChance))
end
function menu.checkbox_DeepDebug(_, checked)
	menu.editedSettings.DeepDebug = checked and 100 or 0
    menu.Set_Md_Settings("DeepDebug " .. tostring(menu.editedSettings.DeepDebug))
end
function menu.checkbox_ChangesOnFleetDebug(_, checked)
	menu.editedSettings.ChangesOnFleetDebug = checked and 100 or 0
    menu.Set_Md_Settings("ChangesOnFleetDebug " .. tostring(menu.editedSettings.ChangesOnFleetDebug))
end
function menu.checkbox_FleetLockStatusDebug(_, checked)
	menu.editedSettings.FleetLockStatusDebug = checked and 100 or 0
    menu.Set_Md_Settings("FleetLockStatusDebug " .. tostring(menu.editedSettings.FleetLockStatusDebug))
end

function menu.checkbox_DebugFileDetail_Fleets(_, checked)
	menu.editedSettings.DebugFileDetail_Fleets = checked
    menu.Set_Md_Settings("DebugFileDetail_Fleets " .. tostring(menu.editedSettings.DebugFileDetail_Fleets))
end
function menu.checkbox_DebugFileDetail_Records(_, checked)
	menu.editedSettings.DebugFileDetail_Records = checked
    menu.Set_Md_Settings("DebugFileDetail_Records " .. tostring(menu.editedSettings.DebugFileDetail_Records))
end




-- ----------------------------------------------------
-- MENU FUNCTONS
-- ----------------------------------------------------
menu.updateInterval = 0.05

function menu.onUpdate()
    local curtime = getElapsedTime()

    if menu.mainFrame then
        menu.mainFrame:update()
    end

    if menu.infoFrame then
        menu.infoFrame:update()
    end

    local refreshing = false
    if (menu.lastDataCheck + 1) < curtime then
        local xdebug = debugGetData and DebugError("lastDataCheck = " .. menu.lastDataCheck .. "  curtime=" .. curtime)
        menu.Get_mdData()
    end

    if menu.infoFrameTableMode == "options" then 
        --return
    end

    if menu.lock then
        --return
    end
    if (menu.queueupdate and not menu.noupdate) then
        local xdebug = debug0 and DebugError("REFRESHING   queue update ")
        menu.refreshInfoFrame()
        return
    end

    if menu.mdDataChanged and (not menu.createInfoFrameRunning) then
        local xdebug = debug0 and DebugError("REFRESHING   mdDataChanged")
        menu.mdDataChanged = nil
        SetNPCBlackboard(playerID, "$md_RFM_DataChanged", false)
        menu.refreshInfoFrame()
        return
    end

    -- 2 sn de bir refresh gerekli mi
    if menu.lastrefresh + 2.0 < curtime then
        --refreshing = true
    end
    if refreshing and (not menu.noupdate) and (not menu.createInfoFrameRunning) then
		menu.lastrefresh = curtime
		menu.refreshInfoFrame()
	end

    if menu.refreshMainFrame then
        if not menu.createMainFrameRunning then
            
            local xdebug = debug0 and DebugError("REFRESHING   refreshMainFrame true" .. "  menu.infoFrameTableMode = " .. tostring(menu.infoFrameTableMode))
            menu.setSelectedRows.sideBar = Helper.currentTableRow[menu.sideBarTableID]

            menu.createMainFrame()
            menu.refreshMainFrame = nil
        end
    end

end

function menu.onRowChanged(row, rowdata, uitable, modified, input, source)
    
    menu.changedFleet = nil
    
    local xprint = false
        
    if uitable == menu.managerTable_fleet then
        menu.settoprow =  GetTopRow(menu.managerTable_fleet) 
        menu.setselectedrow =  Helper.currentTableRow[menu.managerTable_fleet]

        if menu.selectedfleet ~= rowdata then
            menu.selectedfleet = rowdata
            menu.changedFleet = true
            menu.isremoverespondwares = false
            menu.shipsTableData.settoprow = nil
            menu.shipsTableData.setselectedrow = nil
            menu.shipsTableData.selected = nil
            menu.shipsTableData.selectedGroup = nil

            xprint = true
            menu.queueupdate = true
        end
    end

        
    if uitable == menu.managerTable_fleetShips then
        menu.shipsTableData.setselectedrow = row
        menu.shipsTableData.settoprow = GetTopRow(menu.managerTable_fleetShips)
        if (type(rowdata) == "table") and 
            ( menu.shipsTableData.selected and (menu.shipsTableData.selected ~=  rowdata[2])
            or 
            menu.shipsTableData.selectedGroup ~= rowdata[3] 
            ) then

            menu.isremoverespondwares = false
            menu.shipsTableData.selected =  rowdata[2]
            menu.shipsTableData.selectedGroup = nil
            if rowdata[3] then 
                menu.shipsTableData.selectedGroup = rowdata[3]
            end
            
            xprint = true
            menu.queueupdate = true
        end
    end
        
        
    local textDebug = string.format(
        [[ onRowChanged
            fleetTable.id       = %s %s
            fleetShipsTable.id  = %s %s
            -----------------------
            uitable = %s    modified = %s
            row = %s
            rowdata: %s
            -----------------------
            .selected Fleet = %s
            .settoprow      = %s
            .setselectedrow = %s
            -----------------------
            .selected = %s      .selectedGroup = %s
            shipsTableData.settoprow            = %s
            menu.shipsTableData.setselectedrow  = %s
            ]],
            menu.fleetTable.id, menu.managerTable_fleet,
            menu.fleetShipsTable.id, menu.managerTable_fleetShips,
            uitable, modified,
            row,
            ( type(rowdata) == "table" 
            and 
                "[2]component = " .. tostring(rowdata[2]) .. " , [3]group=" .. tostring(rowdata[3]) .. " , [1]( " .. tostring(rowdata[1]).. " )"
            or 
                "ship = " .. tostring(rowdata) .. "" .. ""
            ),
            menu.selectedfleet,
            menu.settoprow,
            menu.setselectedrow,
            menu.shipsTableData.selected, menu.shipsTableData.selectedGroup,
            menu.shipsTableData.settoprow,
            menu.shipsTableData.setselectedrow

        )

    local xdebug = debugW and xprint and DebugError(textDebug)

end
function menu.refreshInfoFrame()
    if not menu.createInfoFrameRunning then
        local xdebug = debug2 and DebugError("REFRESH INFO FRAME   ")
        menu.queueupdate = nil
        
        if menu.infoFrameTableMode == "manager" then
            --[[ henüz kullanmıyoruz bu değişkenleri
                menu.selectedTops.managerTable_fleet = GetTopRow(menu.managerTable_fleet)
                menu.selectedTops.managerTable_sorter = GetTopRow(menu.managerTable_sorter)
                menu.selectedTops.managerTable_fleetShips = GetTopRow(menu.managerTable_fleetShips)
                menu.setSelectedRows.managerTable_fleet = Helper.currentTableRow[menu.managerTable_fleet]
                menu.setSelectedRows.managerTable_sorter = Helper.currentTableRow[menu.managerTable_sorter]
                menu.setSelectedRows.managerTable_fleetShips = Helper.currentTableRow[menu.managerTable_fleetShips]                ]]
            
            --menu.settoprow = menu.settoprow or GetTopRow(menu.managerTable_fleet) 
            --menu.setselectedrow = menu.setselectedrow or Helper.currentTableRow[menu.managerTable_fleet]
            --DebugError("menu.setselectedrow = " .. tostring(menu.setselectedrow))
            
            if menu.setselectedrow then
                --menu.selectedfleet = menu.rowDataMap[menu.managerTable_fleet][menu.setselectedrow]
                --DebugError("  menu.selectedfleet = " .. tostring(menu.selectedfleet))
                if not menu.changedFleet then
                    --menu.shipsTableData.settoprow = GetTopRow(menu.managerTable_fleetShips)
                    --menu.shipsTableData.setselectedrow = Helper.currentTableRow[menu.managerTable_fleetShips]
                    --menu.shipsTableData.selected = (menu.rowDataMap[menu.fleetShipsTable.id][menu.shipsTableData.setselectedrow][2]) and menu.rowDataMap[menu.fleetShipsTable.id][menu.shipsTableData.setselectedrow][2]
                    --menu.shipsTableData.selectedGroup =(menu.rowDataMap[menu.fleetShipsTable.id][menu.shipsTableData.setselectedrow][3]) and menu.rowDataMap[menu.fleetShipsTable.id][menu.shipsTableData.setselectedrow][3]
                end
            end
            
        end
        if menu.infoFrameTableMode == "options" then
            menu.setTopRows.optionsTable_Left = menu.setTopRows.optionsTable_Left or GetTopRow(menu.optionsTable_Left) 
            menu.setSelectedRows.optionsTable_Left = menu.setSelectedRows.optionsTable_Left or Helper.currentTableRow[menu.optionsTable_Left]
        end
        menu.createInfoFrame()
    end
end
function menu.viewCreated(layer, ...)
	local xdebug = debug2 and DebugError("viewCreated " .. " layer = " .. layer .. " ... = " .. tostring(...)  )
    if layer == config.mainLayer then
        menu.sideBarTableID = ...
        menu.createMainFrameRunning = false
    end
	if layer == config.infoLayer then
        local a,b,c,d,e,f,g = ...
        if menu.infoFrameTableMode == "manager" then
            --DebugError("1-flet " .. tostring(a) .. "  , 2-sort " .. tostring(b) .. "  , 3-ship " .. tostring(c) .. "  , 4-rght " .. tostring(d) .. "  , 5-butn " .. tostring(e)  )
            menu.managerTable_fleet, menu.managerTable_sorter, menu.managerTable_fleetShips, menu.managerTable_right, menu.managerTable_bottom = ...
        end
        if menu.infoFrameTableMode == "options" then
            --DebugError("1-top " .. tostring(a) .. "  , 2-botm " .. tostring(b) .. "  , 3-left " .. tostring(c) .. "  , 4-rght " .. tostring(d)  )
            menu.optionsTable_Top, menu.optionsTable_Bottom, menu.optionsTable_Left, menu.optionsTable_Right = ...
        end
        menu.createInfoFrameRunning = false
	end

end
function menu.onInteractiveElementChanged(tableid)
    --DebugError("onInteractiveElementChanged  " .. " tableid = " .. tostring(tableid)  )
    
    menu.lastactivetable = tableid
end
function menu.onCloseElement(dueToClose, layer)
    local xdebug = debug0 and DebugError("menu.onCloseElement " .. tostring(dueToClose) .. " layer " .. tostring(layer) )
    Helper.closeMenu(menu, dueToClose, layer )
    menu.cleanup()
end




-- ----------------------------------------------------
-- SORTERS
-- ----------------------------------------------------

function menu.sortNameSectorAndIDCode(a, b, invert)
	local sector_a_name = a.sector or ""
	local sector_b_name = b.sector or ""
	if sector_a_name == sector_b_name then
		return menu.sortNameAndIDCode(a, b, invert)
	else
		if invert then
			return sector_a_name > sector_b_name
		else
			return sector_a_name < sector_b_name
		end
	end
end
function menu.sortNameAndIDCode(a, b, invert)
	if a.name == b.name then
		if invert then
			return a.idcode > b.idcode
		else
			return a.idcode < b.idcode
		end
	end
	if invert then
		return a.name > b.name
	else
		return a.name < b.name
	end
end
function menu.sortCommanderNameAndIDCode(a, b, invert)
	if a.commander.name == b.commander.name then
		if invert then
			return a.commander.idcode > b.commander.idcode
		else
			return a.commander.idcode < b.commander.idcode
		end
	end
	if invert then
		return a.commander.name > b.commander.name
	else
		return a.commander.name < b.commander.name
	end
end
function menu.sortID(a, b, invert)
    if invert then
        return a.id > b.id
    else
        return a.id < b.id
    end
end
function menu.sortShipsByClassAndPurpose(a, b, invert)
	local aclass = config.classOrder[a.class] or 0
	local bclass = config.classOrder[b.class] or 0
	if aclass == bclass then
		local apurpose = (a.purpose ~= "") and Helper.purposeOrder[a.purpose] or 0
		local bpurpose = (b.purpose ~= "") and Helper.purposeOrder[b.purpose] or 0
		if apurpose == bpurpose then
			if invert then
				return a.name .. a.idcode > b.name .. b.idcode
			else
				return a.name .. a.idcode < b.name .. b.idcode
			end
		end
		if invert then
			return apurpose > bpurpose
		else
			return apurpose < bpurpose
		end
	else
		if invert then
			return aclass > bclass
		else
			return aclass < bclass
		end
	end
end
function menu.sortLockedAndSize(a, b, invert)
	if tostring(a.isLockedFleet) == tostring(b.isLockedFleet) then
        return menu.sortShipsByClassAndPurpose(a, b) --(a, b, invert)
	end
	if invert then
		return tostring(a.isLockedFleet) < tostring(b.isLockedFleet)
	else
		return tostring(a.isLockedFleet) > tostring(b.isLockedFleet)
	end
end

function menu.buttonPropertySorter(sorttype)
	if menu.propertySorterType == sorttype then
		menu.propertySorterType = sorttype .. "inverse"
	else
		menu.propertySorterType = sorttype
	end
	menu.refreshInfoFrame()
end

-- Default (sorttype == "name")
-- example : table.sort( table, menu.componentSorter("nameinverse") )
-- sorttype : name, nameinverse, id, idinverse, class, classinverse, sector, sectorinverse, promotedname, promotednameinverse, commandername, commandernameinverse
function menu.componentSorter(sorttype)
	local sorter = menu.sortNameAndIDCode
	if sorttype == "nameinverse" then
		sorter = function (a, b) return menu.sortNameAndIDCode(a, b, true) end
    elseif sorttype == "id" then
		sorter = menu.sortID
	elseif sorttype == "idinverse" then
		sorter = function (a, b) return menu.sortID(a, b, true) end
	elseif sorttype == "class" then
		sorter = menu.sortShipsByClassAndPurpose
	elseif sorttype == "classinverse" then
		sorter = function (a, b) return menu.sortShipsByClassAndPurpose(a, b, true) end
    elseif sorttype == "sector" then
		sorter = menu.sortNameSectorAndIDCode
	elseif sorttype == "sectorinverse" then
		sorter = function (a, b) return menu.sortNameSectorAndIDCode(a, b, true) end
    elseif sorttype == "commandername" then
		sorter = menu.sortCommanderNameAndIDCode
	elseif sorttype == "commandernameinverse" then
		sorter = function (a, b) return menu.sortCommanderNameAndIDCode(a, b, true) end
    elseif sorttype == "locked" then
		sorter = menu.sortLockedAndSize
	elseif sorttype == "lockedinverse" then
		sorter = function (a, b) return menu.sortLockedAndSize(a, b, true) end
    end
	return sorter
end

--- listedeki shipkey verilerini sorte'a gore dizer ve geri verir
---@param RFMKey any                -- RM_FleetRecords[RFMKey]
---@param shipKeysList any          -- sKey list
---@param sorter string             -- componentSorter(sorter)
---@param isConvertToLuaID any      -- sKey list convert to objectLuaID list
function menu.sortKeysListWithFleetRecords(RFMKey, shipKeysList, sorter, isConvertToLuaID)
	local sortedComponents = {}
	for _, key in ipairs(shipKeysList) do
        local record = menu.GetRecord(RFMKey, key)
        -- componentSorter içindeki karşılaştırma verileri için propertyler ekliyoruz
		table.insert(sortedComponents, { id = record.id, name = record.name , fleetname = "RFM_" .. record.id .. "_" , idcode = record.idcode, class = record.class , purpose = record.purpose, sector = record.sector })
	end
	table.sort(sortedComponents, menu.componentSorter(sorter))
    
    local returnvalue = {}
    if isConvertToLuaID then
        for _, entry in ipairs(sortedComponents) do
            table.insert(returnvalue, ConvertStringToLuaID(tostring(entry.id)))
        end
    else
        for _, entry in ipairs(sortedComponents) do
            table.insert(returnvalue, entry.id)
        end
    end
	
    return returnvalue
end



-- ----------------------------------------------------
-- USER FUNCS
-- ----------------------------------------------------

--- 'menu.blacklist_stations' icinde verilen 'object64' objeyi arar
---@param object64 any
---return true or false
function menu.checkInBlacklist(object64)
    for _,bs in ipairs(menu.blacklist_stations) do
        local bs64 = ConvertStringTo64Bit(tostring(bs))
        if object64 == bs64 then
            return true
        end
    end
    return false
end

--- fleets tablosundan RFMKey == fleet.id 
---@param RFMKey any
-- return index or nil
function menu.findFleet(RFMKey)
    for i, fleet in pairs(menu.fleets ) do
        if fleet.id == RFMKey then
            return i
        end
    end
    return nil
end

--- Duzenlenmis fleet.Records'dan sKey'e ait elementi verir
---@param RFMKey any
---@param sKey any
-- return element or {}
function menu.GetRecord(RFMKey, sKey)
    local fKeyIndex = menu.findFleet(RFMKey)
    if fKeyIndex and fKeyIndex > 0 then
        local fleet = menu.fleets[fKeyIndex]
        for i, entry in ipairs(fleet.Records ) do
            if entry.id == sKey then
                return entry
            end
        end
    end
    return {}
end

--- not shipsTableData.selectedGroup  and  shipsTableData.selected == shipKey
---@param shipKey any
-- return shipKey or nil
function menu.isSelectedShipLine(shipKey)
    if menu.shipsTableData.selected == shipKey and not menu.shipsTableData.selectedGroup then
        return shipKey
    end
    return nil
end

--- RM_RebuildCues[RFMKey][sKey] elementini verir
---@param RFMKey any
---@param sKey any
-- yoksa nil
function menu.GetReBuildCue(RFMKey, sKey)
    if menu.RM_RebuildCues[RFMKey] then
        if menu.RM_RebuildCues[RFMKey][sKey] then
            return menu.RM_RebuildCues[RFMKey][sKey]
        end
    end
    return nil
end

--- RM_FleetRecords[RFMKey] icindeki .commanderidx == skey olanlarin listesini geri verir
---@param RFMKey any
---@param shipKey any
--
-- varsa { shipid1, shipid2, .. } 
-- yoksa {}
function menu.GetSubordinates_From_FleetRecords(RFMKey, shipKey)
    local subordinates = {}
    for _, record in pairs(menu.RM_FleetRecords[RFMKey] ) do
        if record.commanderidx == shipKey then
            table.insert(subordinates, record.id)
        end
    end
    return subordinates
end

function menu.isObjectValid(object)
	if not C.IsComponentClass(object, "ship") and not (C.IsRealComponentClass(object, "station") and (not C.IsComponentWrecked(object))) and not GetComponentData(object, "isdeployable") and not C.IsComponentClass(object, "lockbox") then
		return false
	elseif C.IsComponentClass(object, "controllable") and C.IsUnit(object) then
		return false
	elseif (not C.IsObjectKnown(object)) or (not GetComponentData(ConvertStringTo64Bit(tostring(object)), "isradarvisible")) then
		return false
	end
	return true
end

function menu.GetConstructionFromShipyardBuilds(shipyard64, build64)
    
    shipyard64 = ConvertStringTo64Bit(tostring(shipyard64))
    build64 = ConvertStringTo64Bit(tostring(build64))

    local result = {}

    -- builds in progress
    local n = C.GetNumBuildTasks(shipyard64, 0, true, false)
    local buf = ffi.new("BuildTaskInfo[?]", n)
    n = C.GetBuildTasks(buf, n, shipyard64, 0, true, false)
    for i = 0, n - 1 do
        local factionid = ffi.string(buf[i].factionid)
        local bufid64 = ConvertStringTo64Bit(tostring(buf[i].id))
        if factionid == "player" then   -- Sadece player olanları al
            if IsSameComponent(build64, bufid64) then
                result = { id = buf[i].id, buildingcontainer = buf[i].buildingcontainer, component = buf[i].component, macro = ffi.string(buf[i].macro), factionid = ffi.string(buf[i].factionid), buildercomponent = buf[i].buildercomponent, price = buf[i].price, ismissingresources = buf[i].ismissingresources, queueposition = buf[i].queueposition, inprogress = true }
                return result
            end
        end
    end

    -- other builds
    local n = C.GetNumBuildTasks(shipyard64, 0, false, false)
    local buf = ffi.new("BuildTaskInfo[?]", n)
    n = C.GetBuildTasks(buf, n, shipyard64, 0, false, false)
    for i = 0, n - 1 do
        local component = buf[i].component
        local macro = ffi.string(buf[i].macro)
        local factionid = ffi.string(buf[i].factionid)
        local bufid64 = ConvertStringTo64Bit(tostring(buf[i].id))

        if factionid == "player" then   -- sadece player olanları al
            if (component == 0) and (macro ~= "") then
                if IsSameComponent(build64, bufid64) then
                    --DebugError("buf.id64 = " .. tostring(bufid64) .. " , build64 = " .. tostring(build64) )
                    result = { id = buf[i].id, buildingcontainer = buf[i].buildingcontainer, component = component, macro = macro, factionid = ffi.string(buf[i].factionid), buildercomponent = buf[i].buildercomponent, price = buf[i].price, ismissingresources = buf[i].ismissingresources, queueposition = buf[i].queueposition, inprogress = false, amount = 1, ids = { buf[i].id } }
                    return result
                end
            else
                if IsSameComponent(build64, bufid64) then
                    result = { id = buf[i].id, buildingcontainer = buf[i].buildingcontainer, component = buf[i].component, macro = ffi.string(buf[i].macro), factionid = ffi.string(buf[i].factionid), buildercomponent = buf[i].buildercomponent, price = buf[i].price, ismissingresources = buf[i].ismissingresources, queueposition = buf[i].queueposition, inprogress = false }
                    return result
                end
            end
        end
    end
    
    return result
end

function menu.GetShipyardConstructions(shipyard)

    local id = shipyard
    local convertedID = ConvertStringToLuaID(tostring(id))
    
    local shipyardname = GetComponentData(id, "name")
    DebugError(string.format("id = %s , convertedID = %s , name = %s", id, convertedID, shipyardname) )
    
    local constructions = {}
    local constructionshipsbymacro = {}
    -- builds in progress
    local n = C.GetNumBuildTasks(id, 0, true, false)
    local buf = ffi.new("BuildTaskInfo[?]", n)
    n = C.GetBuildTasks(buf, n, id, 0, true, false)
    for i = 0, n - 1 do
        local factionid = ffi.string(buf[i].factionid)
        if factionid == "player" then   -- Sadece player olanları al
            table.insert(constructions, { id = buf[i].id, buildingcontainer = buf[i].buildingcontainer, component = buf[i].component, macro = ffi.string(buf[i].macro), factionid = ffi.string(buf[i].factionid), buildercomponent = buf[i].buildercomponent, price = buf[i].price, ismissingresources = buf[i].ismissingresources, queueposition = buf[i].queueposition, inprogress = true })
            local strDebug = string.format(
                [[
                Builds In Progress (%s)
                id    : %s
                buildingcontainer : %s
                component : %s
                macro     : %s 
                factionid : %s 
                buildercomponent : %s
                price : %s
                ismissingresources : %s
                queueposition : %s
                inprogress : %s 
                ]]
                ,
                i+1,
                constructions[i+1].id,
                constructions[i+1].buildingcontainer,
                constructions[i+1].component,
                constructions[i+1].macro,
                constructions[i+1].factionid,
                constructions[i+1].buildercomponent,
                constructions[i+1].price,
                constructions[i+1].ismissingresources,
                constructions[i+1].queueposition,
                constructions[i+1].inprogress
                )
            DebugError(strDebug)
        end
    end
    if #constructions > 0 then
        table.insert(constructions, { empty = true })
    end
    -- other builds
    local n = C.GetNumBuildTasks(id, 0, false, false)
    local buf = ffi.new("BuildTaskInfo[?]", n)
    n = C.GetBuildTasks(buf, n, id, 0, false, false)
    for i = 0, n - 1 do
        local component = buf[i].component
        local macro = ffi.string(buf[i].macro)
        local factionid = ffi.string(buf[i].factionid)
        if factionid == "player" then   -- sadece player olanları al
            if (component == 0) and (macro ~= "") then
                if constructionshipsbymacro[macro] then
                    constructions[constructionshipsbymacro[macro]].amount = constructions[constructionshipsbymacro[macro]].amount + 1
                    table.insert(constructions[constructionshipsbymacro[macro]].ids, buf[i].id)

                    local strDebug = string.format(
                        [[
                        Builds In Tasks 1 (%s)  macro daha önce eklenmiş, sadece amount artacak ve ids lere eklenecek
                        id    : %s
                        buildingcontainer : %s
                        component : %s
                        macro     : %s 
                        factionid : %s 
                        buildercomponent : %s
                        price : %s
                        ismissingresources : %s
                        queueposition : %s
                        inprogress : %s 
                        amount : %s
                        ids count : %s
                        ]]
                        ,
                        i+1,
                        constructions[i+1].id,
                        constructions[i+1].buildingcontainer,
                        constructions[i+1].component,
                        constructions[i+1].macro,
                        constructions[i+1].factionid,
                        constructions[i+1].buildercomponent,
                        constructions[i+1].price,
                        constructions[i+1].ismissingresources,
                        constructions[i+1].queueposition,
                        constructions[i+1].inprogress,
                        constructions[i+1].amount,
                        #constructions[i+1].ids
                        )
                    DebugError(strDebug)

                else
                    table.insert(constructions, { id = buf[i].id, buildingcontainer = buf[i].buildingcontainer, component = component, macro = macro, factionid = ffi.string(buf[i].factionid), buildercomponent = buf[i].buildercomponent, price = buf[i].price, ismissingresources = buf[i].ismissingresources, queueposition = buf[i].queueposition, inprogress = false, amount = 1, ids = { buf[i].id } })
                    constructionshipsbymacro[macro] = #constructions

                    local strDebug = string.format(
                        [[
                        Builds In Tasks 2 (%s)  macro yok, amount 1 ve ids lere ekle
                        id    : %s
                        buildingcontainer : %s
                        component : %s
                        macro     : %s 
                        factionid : %s 
                        buildercomponent : %s
                        price : %s
                        ismissingresources : %s
                        queueposition : %s
                        inprogress : %s 
                        amount : %s
                        ids count : %s
                        ]]
                        ,
                        i+1,
                        constructions[i+1].id,
                        constructions[i+1].buildingcontainer,
                        constructions[i+1].component,
                        constructions[i+1].macro,
                        constructions[i+1].factionid,
                        constructions[i+1].buildercomponent,
                        constructions[i+1].price,
                        constructions[i+1].ismissingresources,
                        constructions[i+1].queueposition,
                        constructions[i+1].inprogress,
                        constructions[i+1].amount,
                        #constructions[i+1].ids
                        )
                    DebugError(strDebug)
        
                end
            else
                table.insert(constructions, { id = buf[i].id, buildingcontainer = buf[i].buildingcontainer, component = buf[i].component, macro = ffi.string(buf[i].macro), factionid = ffi.string(buf[i].factionid), buildercomponent = buf[i].buildercomponent, price = buf[i].price, ismissingresources = buf[i].ismissingresources, queueposition = buf[i].queueposition, inprogress = false })

                local strDebug = string.format(
                    [[
                    Builds In Tasks3 (%s)  Component oluşmuş
                    id    : %s
                    buildingcontainer : %s
                    component : %s
                    macro     : %s 
                    factionid : %s 
                    buildercomponent : %s
                    price : %s
                    ismissingresources : %s
                    queueposition : %s
                    inprogress : %s  ]]
                    ,
                    i+1,
                    constructions[i+1].id,
                    constructions[i+1].buildingcontainer,
                    constructions[i+1].component,
                    constructions[i+1].macro,
                    constructions[i+1].factionid,
                    constructions[i+1].buildercomponent,
                    constructions[i+1].price,
                    constructions[i+1].ismissingresources,
                    constructions[i+1].queueposition,
                    constructions[i+1].inprogress
                    )
                DebugError(strDebug)
        
            end
        end
    end



    return constructions

end

function menu.getBuildProgress(stationLuaID, name, componentLuaID)
	local buildprogress = 100
	if IsComponentConstruction(ConvertStringTo64Bit(tostring(componentLuaID))) then
		buildprogress = math.floor(C.GetCurrentBuildProgress(ConvertIDTo64Bit(stationLuaID)))
	elseif componentLuaID == 0 then
		buildprogress = "-"
	end

	if buildprogress == 100 then
		return name
	else
		return name .. " (" .. buildprogress .. " %)"
	end
end

function menu.getBuildTime(buildingprocessor, componentLuaID, ismissingresources)
	if IsComponentConstruction(ConvertStringTo64Bit(tostring(componentLuaID))) then
		return (ismissingresources and "\27Y\27[warning] " or "") .. ConvertTimeString(C.GetBuildProcessorEstimatedTimeLeft(buildingprocessor), "%h:%M:%S")
	else
		return ""
	end
end

function menu.getShipBuildProgress(shipLuaID)
	local buildprogress = 100
	if IsComponentConstruction(ConvertStringTo64Bit(tostring(shipLuaID))) then
		--buildprogress = math.floor(C.GetCurrentBuildProgress(shipLuaID))
        buildprogress = string.format("%.1f", C.GetCurrentBuildProgress(shipLuaID))
	elseif shipLuaID == 0 then
		buildprogress = "-"
	end

	if buildprogress == 100 then
		return ""
	else
		return buildprogress .. " %"
	end
end

function menu.getShipIconWidth(font, fontsize)
	local numbertext = "99"
	local minWidthPercent = 0.015

    local font = font and font or Helper.standardFont
    local fontsize = fontsize and fontsize or Helper.standardFontSize

	local textheight = math.ceil(C.GetTextHeight(numbertext, font, Helper.scaleFont(font, fontsize), Helper.viewWidth))
	local textwidth = math.ceil(C.GetTextWidth(numbertext, font, Helper.scaleFont(font, fontsize)))

	return math.max(minWidthPercent * menu.infoTableWidth, math.max(textheight, textwidth))
    --return math.max(textheight, textwidth)
end


function menu.GetMouseOverTextFromOrderIcons(currentordericon, currentordername, currentorderdescription, currentordermouseovertext, targetname, behaviouricon, behaviourname, behaviourdescription, isdocked )
    local mouseovertext = ""
    -- skip adding when behaviouricon was ignored (case: behaviour == HoldPosition AND order ~= null)
    if behaviouricon ~= "" and behaviourname and behaviourname ~= "" then
        if mouseovertext ~= "" then
            mouseovertext = mouseovertext .. "\n"
        end
        mouseovertext = mouseovertext .. behaviourname
    end
    -- skip adding when behaviouricon was ignored (case: behaviour == HoldPosition AND order ~= null)
    if behaviouricon ~= "" and behaviourdescription and behaviourdescription ~= "" then
        if mouseovertext ~= "" then
            mouseovertext = mouseovertext .. "\n"
        end
        mouseovertext = mouseovertext .. Helper.indentText(behaviourdescription, "  ", GetCurrentMouseOverWidth(), GetCurrentMouseOverFont()) 
    end
    if currentordername ~= "" then
        if mouseovertext ~= "" then
            mouseovertext = mouseovertext .. "\n"
        end
        mouseovertext = mouseovertext .. currentordername .. (currentordermouseovertext and ("\n\27R" .. currentordermouseovertext .. "\27X") or "")
    end
    if currentorderdescription and currentorderdescription ~= "" then
        if mouseovertext ~= "" then
            mouseovertext = mouseovertext .. "\n"
        end
        mouseovertext = mouseovertext .. Helper.indentText(currentorderdescription, "  ", GetCurrentMouseOverWidth(), GetCurrentMouseOverFont()) 
    end
    if targetname and tostring(targetname) ~= "" then
        if mouseovertext ~= "" then
            mouseovertext = mouseovertext .. "\n"
        end
        mouseovertext = mouseovertext .. Helper.indentText(targetname, "  ", GetCurrentMouseOverWidth(), GetCurrentMouseOverFont()) 
    end
    if isdocked then
        if mouseovertext ~= "" then
            mouseovertext = mouseovertext .. "\n"
        end
        mouseovertext = mouseovertext .. ReadText(1001, 3249)
    end
   
    return mouseovertext
end
function menu.noneOverrideOrderIcon(currentordericon, behaviouricon, isdocked, locationtext)
    
    local secondtext2 = ""
    if (currentordericon ~= "") or isdocked then
        secondtext2 = (currentordericon ~= "") and currentordericon or ""
        if isdocked then
            secondtext2 = secondtext2 .. " \27[order_dockat]"
        end
        if behaviouricon ~= "" then
            secondtext2 = Helper.convertColorToText(config.sColor.blue) .. behaviouricon .. "\27X" .. secondtext2
        end
    end
    --local secondtext2width = C.GetTextWidth(secondtext2, font , Helper.scaleFont(font, fontsize))
    return secondtext2 .. "\n" .. locationtext
end
function menu.overrideOrderIcon(normalcolor, usetext, icon,  prefix, postfix)
	-- number between 0 and 1, duration 1s
	local x = getElapsedTime() % 1

	normalcolor = normalcolor or config.Color.icon_normal
	local overridecolor = config.Color.order_override
	local color = {
		r = (1 - x) * overridecolor.r + x * normalcolor.r,
		g = (1 - x) * overridecolor.g + x * normalcolor.g,
		b = (1 - x) * overridecolor.b + x * normalcolor.b,
		a = (1 - x) * overridecolor.a + x * normalcolor.a,
	}
	if usetext then
		local colortext = Helper.convertColorToText(color) .. "\27[" .. icon .. "]\27X"
		return (prefix and prefix or "") .. colortext .. (postfix and postfix or "")
	else
		return color
	end
end
function menu.getOrderInfo(ship64, gettargetname)
	local isplayerowned, assignment, assignedpilot = GetComponentData(ship64, "isplayerowned", "assignment", "assignedpilot")
	if not isplayerowned then
		return "", "", nil, "", false, nil, "", "", ""
	end

	local waiticon = ""
	local orderdefinition = ffi.new("OrderDefinition")
	if C.GetOrderDefinition(orderdefinition, "Wait") then
		waiticon = ffi.string(orderdefinition.icon)
	end

	local orders, defaultorder = {}, {}
	local n = C.GetNumOrders(ship64)
	local buf = ffi.new("Order2[?]", n)
	n = C.GetOrders2(buf, n, ship64)
	for i = 0, n - 1 do
		local order = {}
		order.state = ffi.string(buf[i].state)
		order.statename = ffi.string(buf[i].statename)
		order.orderdef = ffi.string(buf[i].orderdef)
		order.actualparams = tonumber(buf[i].actualparams)
		order.enabled = buf[i].enabled
		order.isinfinite = buf[i].isinfinite
		order.issyncpointreached = buf[i].issyncpointreached
		order.istemporder = buf[i].istemporder
		order.isoverride = buf[i].isoverride

		local orderdefinition = ffi.new("OrderDefinition")
		if order.orderdef ~= nil and C.GetOrderDefinition(orderdefinition, order.orderdef) then
			order.orderdef = {}
			order.orderdef.id = ffi.string(orderdefinition.id)
			order.orderdef.icon = ffi.string(orderdefinition.icon)
			order.orderdef.name = ffi.string(orderdefinition.name)
			order.orderdef.description = ffi.string(orderdefinition.description)
		else
			order.orderdef = { id = "", icon = "", name = "", description = "" }
		end

		table.insert(orders, order)
	end

	local hasrealorders = false
	for _, order in ipairs(orders) do
		if order.enabled and (not order.istemporder) then
			hasrealorders = true
			break
		end
	end
	
	local buf = ffi.new("Order")
	if C.GetDefaultOrder(buf, ship64) then
		defaultorder.state = ffi.string(buf.state)
		defaultorder.statename = ffi.string(buf.statename)
		defaultorder.orderdef = ffi.string(buf.orderdef)
		defaultorder.actualparams = tonumber(buf.actualparams)
		defaultorder.enabled = buf.enabled
		defaultorder.issyncpointreached = buf.issyncpointreached
		defaultorder.istemporder = buf.istemporder

		local orderdefinition = ffi.new("OrderDefinition")
		if defaultorder.orderdef ~= nil and C.GetOrderDefinition(orderdefinition, defaultorder.orderdef) then
			defaultorder.orderdef = {}
			defaultorder.orderdef.id = ffi.string(orderdefinition.id)
			defaultorder.orderdef.icon = ffi.string(orderdefinition.icon)
			defaultorder.orderdef.name = ffi.string(orderdefinition.name)
			defaultorder.orderdef.description = ffi.string(orderdefinition.description)
		else
			defaultorder.orderdef = { id = "", icon = "", name = "", description = "" }
		end
	end

	local icon, name, description, color, isoverride, mouseovertext, targetname, behaviouricon, behaviourname, behaviourdescription = "", "", "", nil, false, nil, "", "", "", ""
	if #orders > 0 then
		-- there is an order
		local curindex = tonumber(C.GetOrderQueueCurrentIdx(ship64))
		local order = orders[curindex]
		name = order.orderdef.name
		description = order.orderdef.description
		icon = order.orderdef.icon
		isoverride = order.isoverride
		-- change icon to wait if the order is in the wait part
		if (order.orderdef.id == "MoveWait") or (order.orderdef.id == "MoveToObject") or (order.orderdef.id == "DockAndWait") then
			if order.issyncpointreached then
				icon = waiticon
			end
		end
		-- if all orders are temp they were spawned by a defaultorder
		if not hasrealorders then
			color = config.Color.order_temp
		end
		if gettargetname then
			local targets = {}
			Helper.ffiVLA(targets, "UniverseID", C.GetNumOrderLocationData, C.GetOrderLocationData, ship64, curindex, false)
			if #targets == 1 then
				local target = targets[1]
				targetname = ffi.string(C.GetComponentName(target))
				if C.IsComponentClass(target, "ship") then
					targetname = targetname .. " (" .. ffi.string(C.GetObjectIDCode(target)) .. ")"
				end
			elseif #targets > 0 then
				targetname = ReadText(1001, 3424)
			end
		end
		-- if there are normal orders also return information about the default order
		if next(defaultorder) then
			-- there is a defaultorder
			behaviourname = defaultorder.orderdef.name
			behaviourdescription = defaultorder.orderdef.description
			behaviouricon = defaultorder.orderdef.icon
			if (defaultorder.orderdef.id == "Wait") then
				-- do not show Wait default order
				behaviouricon = ""
			elseif (defaultorder.orderdef.id == "MoveWait") or (defaultorder.orderdef.id == "MoveToObject") or (defaultorder.orderdef.id == "DockAndWait") then
				if defaultorder.issyncpointreached then
					-- do not show these default orders if they reached the wait part
					behaviouricon = ""
				end
			end
		end
	elseif next(defaultorder) then
		-- there is a defaultorder
		name = defaultorder.orderdef.name
		description = defaultorder.orderdef.description
		icon = defaultorder.orderdef.icon
		-- change icon to wait if the order is in the wait part
		if (defaultorder.orderdef.id == "MoveWait") or (defaultorder.orderdef.id == "MoveToObject") or (defaultorder.orderdef.id == "DockAndWait") then
			if defaultorder.issyncpointreached then
				icon = waiticon
			end
		end
		color = config.sColor.blue
		if gettargetname then
			local targets = {}
			Helper.ffiVLA(targets, "UniverseID", C.GetNumOrderLocationData, C.GetOrderLocationData, ship64, 0, true)
			if #targets == 1 then
				local target = targets[1]
				targetname = ffi.string(C.GetComponentName(target))
				if C.IsComponentClass(target, "ship") then
					targetname = targetname .. " (" .. ffi.string(C.GetObjectIDCode(target)) .. ")"
				end
			elseif #targets > 0 then
				targetname = ReadText(1001, 3424)
			end
		end
	end

	if assignedpilot and (assignment == "assist") then
		-- if the ship is trying to mimic, but failed, mark the icon red
		local aicommandactionraw = GetComponentData(assignedpilot, "aicommandactionraw")
		if aicommandactionraw == "orderfailed" then
			color = config.Color.text_failure
			mouseovertext = ReadText(1026, 3268)
		end
	elseif C.HasControllableAnyOrderFailures(ship64) then
		-- if the ship had any order failure, mark the icon orange
		color = config.Color.text_warning
	end

	local texticon = ""
	if icon ~= "" then
		texticon = (color and Helper.convertColorToText(color) or "") .. "\27[" .. icon .. "]\27X"
	end
	local behaviourtexticon = ""
	if behaviouricon ~= "" then 
		behaviourtexticon = Helper.convertColorToText(config.Color.order_temp) .. "\27[" .. behaviouricon .. "]\27X"
	end
	return texticon, icon, color, name, description, isoverride, mouseovertext, targetname, behaviourtexticon, behaviouricon, behaviourname, behaviourdescription
end
function menu.HexToColor(hex, setAlpha)
    local hexRGB = string.gsub(hex, "#","")

    local color = {r = 0, g = 0, b = 0, a = 0}
    local strA, strR, strG, strB = hexRGB:sub(1,2), hexRGB:sub(3,4), hexRGB:sub(5,6), hexRGB:sub(7,8)
    local iAlpha = tonumber( "0x" .. strA ) - 155
    color.a = setAlpha and setAlpha or (iAlpha < 0 and 0 or iAlpha)
    color.r = tonumber( "0x" .. strR )
    color.g = tonumber( "0x" .. strG )
    color.b = tonumber( "0x" .. strB )
    -- DebugError ( "hexRGB = " .. hexRGB )
    -- DebugError ( "strA=\"" .. strA .. "\" strR=\"" .. strR .. "\" strG=\"" .. strG .. "\" strB=" .. strB )
    -- DebugError (" r=" .. color.r .. " g=" .. color.g .. " b=" .. color.b .. " a=" .. color.a )

    return color
end
function menu.getContainerNameAndColors(containerid, iteration, coloricon, colortext, showScanLevel)
	local convertedContainer = ConvertIDTo64Bit(containerid)
	local isplayer, revealpercent, name, faction, icon, ismissiontarget, isonlineobject, isenemy, ishostile = GetComponentData(containerid, "isplayerowned", "revealpercent", "name", "owner", "icon", "ismissiontarget", "isonlineobject", "isenemy", "ishostile")
	local unlocked = IsInfoUnlockedForPlayer(containerid, "name")

	local name = Helper.unlockInfo(unlocked, name .. " (" .. ffi.string(C.GetObjectIDCode(convertedContainer)) .. ")") .. (((not showScanLevel) or isplayer) and "" or " (" .. revealpercent .. " %)")

	if IsComponentClass(containerid, "ship") or IsComponentClass(containerid, "station") then
		local iconid = icon
		if iconid and iconid ~= "" then
            name = string.format("%s\027[%s]%s %s", coloricon, iconid, Helper.convertColorToText(colortext), name)
		end
	end
	local mouseover = "" --name
	for i = 1, iteration do
		name = "    " .. name
	end

	return name, mouseover
end
function menu.getPassedTime(time)
	local passedtime = C.GetCurrentGameTime() - time
	if passedtime < 0 then
		local xdebug = debug1 and DebugError(menu.name .. ".getPassedTime(): given time is in the future. Returning empty result")
		return ""
	end

	local timeformat = "%dd %Hh %Mm ago"
	if passedtime < 3600 then
		timeformat = "%mm %Ss ago"
	elseif passedtime < 3600 * 24 then
		timeformat = "%hh %Mm ago"
	end

	return ConvertTimeString(passedtime, timeformat)
end
function menu.getRemainingTime(time)
	local RemainingTime = time - C.GetCurrentGameTime()
	if RemainingTime < 0 then
		local xdebug = debug1 and DebugError(menu.name .. ".getRemainingTime(): given time is in the future. Returning empty result")
		return ""
	end

	local timeformat = "%dd %Hh %Mm %Ss"
	if RemainingTime < 3600 then
		timeformat = "%mm %Ss"
	elseif RemainingTime < 3600 * 24 then
		timeformat = "%hh %Mm %Ss"
	end

	return ConvertTimeString(RemainingTime, timeformat)
end
function menu.warningColor(normalcolor)
	local color = normalcolor

	local curtime = getElapsedTime()
	if menu.warningShown and (curtime < menu.warningShown + 2) then
        menu.warningShown = curtime
		-- number between 0 and 1, duration 1s
		local x = curtime % 1

		normalcolor = normalcolor or config.Color["text_warning"]
		local overridecolor = config.Color["text_normal"]
		color = {
			r = (1 - x) * overridecolor.r + x * normalcolor.r,
			g = (1 - x) * overridecolor.g + x * normalcolor.g,
			b = (1 - x) * overridecolor.b + x * normalcolor.b,
			a = (1 - x) * overridecolor.a + x * normalcolor.a,
		}
	end
	return color
end




-- ----------------------------------------------------
-- add_build_to_construct_ship FUNCTIONS
-- ----------------------------------------------------



--- 'yard64' istasyonuna ait 'macro'ya uygun SADECE ENGINE ve THRUSTER slotlarina ait possible macrolarini geri verir
---@param yard64 any        -- macroya uyumlu engine ve thruster macrolari alinacak istasyon
---@param macro any         -- engine ve thruster slotlari bulunacak obje macrosu
---@param tShipPlan any     -- tShipPlan verilmis ise geri donen slotlara currentmacro propertisi ekler
function menu.getEngineSlotsPossibleWaresFromStation(yard64, macro, tShipPlan )
    local upgradewares = {}

    local n = 0
    local buf
    -- uint32_t GetNumAvailableEquipment(UniverseID containerid, const char* classid);
    n = C.GetNumAvailableEquipment(yard64, "engine")
    buf = ffi.new("EquipmentWareInfo[?]", n)
    -- uint32_t GetAvailableEquipment(EquipmentWareInfo* result, uint32_t resultlen, UniverseID containerid, const char* classid);
    n = C.GetAvailableEquipment(buf, n, yard64, "engine")

    if n > 0 then
        for i = 0, n - 1 do
            local type = ffi.string(buf[i].type)
            local entry = {}
            entry.ware = ffi.string(buf[i].ware)
            entry.macro = ffi.string(buf[i].macro)
            
            if type == "software" then
                entry.name = GetWareData(entry.ware, "name")
            else
                entry.name = GetMacroData(entry.macro, "name")
            end
            if (type == "lasertower") or (type == "satellite") or (type == "mine") or (type == "navbeacon") or (type == "resourceprobe") then
                type = "deployable"
            end
            if type == "" then
                --DebugError(string.format("Could not find upgrade type for the equipment ware: '%s'. Check the ware tags. [Florian]", entry.ware))
            else
                if upgradewares[type] then
                    table.insert(upgradewares[type], entry)
                else
                    upgradewares[type] = { entry }
                end
            end
        end
    end
    
    --menu.tablePrint(upgradewares, " upgradewares = ", true, true)

    -- const char* GetSlotSize(UniverseID defensibleid, UniverseID moduleid, const char* macroname, bool ismodule, const char* upgradetypename, size_t slot);
    -- size_t GetNumUpgradeSlots(UniverseID destructibleid, const char* macroname, const char* upgradetypename);
    -- size_t GetNumVirtualUpgradeSlots(UniverseID objectid, const char* macroname, const char* upgradetypename);
    -- bool IsUpgradeMacroCompatible(UniverseID objectid, UniverseID moduleid, const char* macroname, bool ismodule, const char* upgradetypename, size_t slot, const char* upgrademacroname);
    -- bool IsVirtualUpgradeMacroCompatible(UniverseID defensibleid, const char* macroname, const char* upgradetypename, size_t slot, const char* upgrademacroname);

    local object = 0
    local slots = {}
    
    local type = "engine"
    slots[type] = {}
    for slotno = 1, tonumber(C.GetNumUpgradeSlots(object, macro, type)) do
        -- convert index from lua to C-style
        local slotsize = ffi.string(C.GetSlotSize(object, 0, macro, false, type, slotno))
        local currentmacro = tShipPlan[type][slotno].macro or ""
        local possiblemacros = {}
        for _, entry in ipairs(upgradewares[type] or {} ) do     -- or {} kullanmak gerekiyor, istasyon economic bir factiona ait olmayabilir
            if C.IsUpgradeMacroCompatible(object, 0, macro, false, type, slotno, entry.macro) then
                table.insert(possiblemacros, entry.macro)
            end
        end
        slots[type][slotno] = { currentmacro = currentmacro, possiblemacros = possiblemacros , slotsize = slotsize }
    end

    local type = "thruster"
    slots[type] = {}
    for slotno = 1, tonumber(C.GetNumVirtualUpgradeSlots(object, macro, type)) do
        -- convert index from lua to C-style
        --const char* GetMacroClass(const char* macroname);
        local class = ffi.string(C.GetMacroClass(macro))
        local slotsize = "" 
        if class == "ship_s" then
            slotsize = "small"
        elseif menu.class == "ship_m" then
            class = "medium"
        elseif menu.class == "ship_l" then
            class = "large"
        elseif menu.class == "ship_xl" then
            class = "extralarge"
        end
        local currentmacro = tShipPlan[type][slotno].macro or ""
        local possiblemacros = {}
        for _, entry in ipairs(upgradewares[type] or {} ) do     -- or {} kullanmak gerekiyor, istasyon economic bir factiona ait olmayabilir
            if C.IsVirtualUpgradeMacroCompatible(object, macro, type, slotno, entry.macro) then
                table.insert(possiblemacros, entry.macro)
            end
        end
        slots[type][slotno] = { currentmacro = currentmacro, possiblemacros = possiblemacros , slotsize = slotsize }
    end

    return slots
end

--- verilen 'tShipPlan' icinde 'lRespondWares' listesinde verilen wareleri bulur ve ilgili slotlarin cikarildigi yeni bir shipplan geri verir
---  * gemiye ait kritik softwareler kaldirilmaz
---  * lRespondWares verilmis ise listedeki ware macrolari ile uyusan tShipPlanı macrolari bosaltilir , verilmemis ise geri donus degeri tShipPlan olur.
---  * lRespondWares verilmis ise icindeki 'engine' ve 'thruster' lar icin 2 secenek mevcut, 
---         1- useenginelots tablosu verilmis   ise 'engine' ve 'thruster' burdaki veriler ile degistirilir.
---         2- useenginelots tablosu verilmemis ise removeengines = true ise kaldirilir, 
---@param tShipPlan any         -- tShipPlan tablosu
---@param lRespondWares any     -- cikarilmak icin dikkate alinacak ware listesi. verilmez ise tShipPlani geri verir
---@param macro any             -- tShipPlan sahibi obje macrosu, ('software' listesinde cikarilmamasi gerekenleri tespit icin kullanilacak )
---@param removeengines any     -- default false, 'engine' ve 'thrusterlar' cikarilacak mi?
---@param useenginelots any     -- default false , 'boolean' ya da 'table' alabilir. Belirtilmez ise 'boolean false' dikkate alinir. lRespondWares icindeki engineleri useenginelotsdakilerle degistirir.
function menu.get_Removed_RespondWares_FromShipPlan(tShipPlan, lRespondWares, macro, removeengines, useenginelots )
    
    local shipplan = menu.tablecopy(tShipPlan)
    local respondwares = menu.tablecopy(lRespondWares or {})
    removeengines = removeengines or false
    if useenginelots then
        if type(useenginelots) ~= "table" then
            useenginelots = tonumber(useenginelots) == 1
        end
    else
        useenginelots = false
    end

    for j, respondware in ipairs(respondwares) do
        for _, upgradetype in ipairs(Helper.upgradetypes) do
            local shipplanentry = shipplan[upgradetype.type]
            local numberentry = menu.GetTableLng(shipplanentry)
            if numberentry > 0 then
                if upgradetype.supertype == "macro" or upgradetype.supertype == "virtualmacro" or upgradetype.supertype == "group" then
                    for i = numberentry, 1, -1 do
                        if shipplanentry[i].macro == respondware.macro then
                            local remove = false
                            if (respondware.type =="engine" or respondware.type =="thruster" ) then
                                if useenginelots then
                                    local mkF = GetMacroData(shipplanentry[i].macro, "mk")
                                    local found = false
                                    for _,macro in ipairs(useenginelots[respondware.type][i].possiblemacros) do
                                        local mkT = GetMacroData(macro, "mk")
                                        if tonumber(mkF) == tonumber(mkT) then
                                            shipplanentry[i].macro = macro
                                            found = true
                                            break
                                        end 
                                    end
                                    if not found then   -- aynı tip bulamaz ise referanslardan birinciyi al
                                        shipplanentry[i].macro = useenginelots[respondware.type][i].possiblemacros[1]
                                    end
                                else
                                    if removeengines then
                                        remove = true
                                    end
                                end
                            else
                                remove = true
                            end
                            if remove then
                                shipplanentry[i].macro = ""
                                shipplanentry[i].weaponmode = ""
                                shipplanentry[i].ammomacro = ""
                                if upgradetype.supertype == "group" then
                                    shipplanentry[i].count = 0
                                end
                            end
                        end
                    end
                elseif upgradetype.supertype == "ammo" then
                    if shipplanentry[respondware.macro] then
                        menu.tableremoveKey(shipplanentry,respondware.macro)
                    end
                elseif (upgradetype.supertype == "software") and (respondware.type == "software") then
                    
                    for i = numberentry, 1, -1 do
                        -- upgradetype.supertype == "macro" olanlar için C.IsSlotMandatory sorgulatılabilir
                        -- normalde softwareler respond listesine düşmemesi gerekiyor, 
                        -- ama kontrol amaçlı gemi türüne göre install edilmesi gereken softwareleri çıkarmayacağız
                        -- 1 [Docking Software Mk..]
                        -- 2 [Flight Assist Software]
                        -- 3 [Long Range Scanner Software Mk..]
                        -- 4 [Object Scanner Software]
                        -- 5 [Targeting Computer Extension Mk..]
                        -- 6 [Trading Computer Extension Mk..]
                        if shipplanentry[i] == respondware.ware then
                            local isdefault = false
                            local ware = shipplanentry[i]
                            if ware ~= "" then
                                isdefault = C.IsSoftwareDefault(0, macro, ware )
                            end
                            if not isdefault then
                                shipplanentry[i] = ""
                            end
                        end
                    end
                end
            end
        end
    end
    
    --menu.tablePrint(shipplan, " shipplan = ")
    return shipplan
end


function menu.get_ShipPriceFromStation(container64, objetmacro, tShipPlan, tBulkCrew)
    
    local crew = { ware = "crew" }
    
    local prices = {}   -- kontrol etmek için eklendi
    local objectprice = 0
    local objectcrewprice = 0
    local isplayerowned = GetComponentData(container64, "isplayerowned")

    -- Object Price
    if not isplayerowned then
        local wareprice 
        -- chassis tutarı
        wareprice = tonumber(C.GetBuildWarePrice(container64, GetMacroData(objetmacro, "ware") or ""))
        objectprice = objectprice + wareprice
        -- equipmentların hepsini tarayacağız
        for i, upgradetype in ipairs(Helper.upgradetypes) do
            local upgradeplanslots = tShipPlan[upgradetype.type]
            if upgradetype.supertype == "macro" or upgradetype.supertype == "virtualmacro" then
                prices[upgradetype.type] = {}
                for j,entry in ipairs(upgradeplanslots) do
                    local macro = entry.macro
                    if macro ~= "" then
                        local count = 1
                        wareprice = tonumber(C.GetBuildWarePrice(container64, GetMacroData(macro, "ware") or ""))
                        objectprice = objectprice + wareprice
                        if not prices[upgradetype.type][macro] then
                            prices[upgradetype.type][macro] = { price = wareprice, count = count , total = count * wareprice}
                        else
                            prices[upgradetype.type][macro].count = prices[upgradetype.type][macro].count + count
                            prices[upgradetype.type][macro].total = prices[upgradetype.type][macro].total + count * wareprice
                        end
                    end
                end
            elseif upgradetype.supertype == "group" then
                prices[upgradetype.type] = {}
                for j,entry in ipairs(upgradeplanslots) do
                    local macro = entry.macro
                    local count = entry.count
                    if macro ~= "" then
                        wareprice = tonumber(C.GetBuildWarePrice(container64, GetMacroData(macro, "ware") or ""))
                        objectprice = objectprice + count * wareprice
                        if not prices[upgradetype.type][macro] then
                            prices[upgradetype.type][macro] = { price = wareprice, count = count , total = count * wareprice}
                        else
                            prices[upgradetype.type][macro].count = prices[upgradetype.type][macro].count + count
                            prices[upgradetype.type][macro].total = prices[upgradetype.type][macro].total + count * wareprice
                        end
                    end
                end
            elseif upgradetype.supertype == "software" then
                for j = 1, #upgradeplanslots do
                    local ware = upgradeplanslots[j]
                    if ware ~= "" then
                        wareprice = C.GetContainerBuildPriceFactor(container64) * GetContainerWarePrice(ConvertStringToLuaID(tostring(container64)), ware, false)
                        objectprice = objectprice + wareprice
                        if not prices[upgradetype.type] then
                            prices[upgradetype.type] = {}
                        end
                        prices[upgradetype.type][ware] = wareprice
                    end
                end
            elseif upgradetype.supertype == "ammo" then
                prices[upgradetype.type] = {}
                for macro, count in pairs(upgradeplanslots) do
                    wareprice = tonumber(C.GetBuildWarePrice(container64, GetMacroData(macro, "ware") or ""))
                    objectprice = objectprice + count * wareprice
                    if not prices[upgradetype.type][macro] then
                        prices[upgradetype.type][macro] = { price = wareprice, count = count , total = count * wareprice}
                    else
                        prices[upgradetype.type][macro].count = prices[upgradetype.type][macro].count + count
                        prices[upgradetype.type][macro].total = prices[upgradetype.type][macro].total + count * wareprice
                    end
                end
            end

        end

        -- Crews Price
        --  Üretilen gemiye personel atama işini md içinde üretilince yapacağız, boş personel ile üretim istiyoruz
        local hiringdiscounts = GetComponentData(container64, "hiringdiscounts")
        hiringdiscounts.totalfactor = 1
        for _, entry in ipairs(hiringdiscounts) do
            hiringdiscounts.totalfactor = hiringdiscounts.totalfactor - entry.amount / 100
        end
        
        local workforceinfo = C.GetWorkForceInfo(container64, "")
        crew.availableworkforce = workforceinfo.available
        crew.maxavailableworkforce = workforceinfo.maxavailable
        
        local minprice, maxprice = GetWareData(crew.ware, "minprice", "maxprice")
        crew.price = Helper.round(
            hiringdiscounts.totalfactor * C.GetContainerBuildPriceFactor(container64) * 
            (maxprice - 
                (crew.availableworkforce ) / 
                (crew.maxavailableworkforce ) * (maxprice - minprice)
            )
        )


        crew.service = (next(tBulkCrew.service)) and #tBulkCrew.service or 0
        crew.marine = (next(tBulkCrew.marine)) and #tBulkCrew.marine or 0
        crew.totalprice = (crew.service + crew.marine) * crew.price
        objectcrewprice = crew.totalprice

        --menu.tablePrint(crew, "crew = " , true, true)

        prices[crew.ware] = {}
        prices[crew.ware].service = crew.service
        prices[crew.ware].marine = crew.marine
        prices[crew.ware].totalprice = crew.totalprice
        
    end

    prices.objectprice = objectprice
    prices.objectcrewprice = objectcrewprice

    prices.RoundTotal_objectprice = RoundTotalTradePrice(objectprice)
    prices.RoundTotal_objectcrewprice = RoundTotalTradePrice(objectcrewprice)

    --menu.tablePrint(prices, objetmacro .. " için Hesaplanan prices = " , true, true)

    return RoundTotalTradePrice(objectprice), RoundTotalTradePrice(objectcrewprice)
end

--- belirlenen stationa verilen macro, tShipPlan ve tIndividualInstructions kullanilarak stationa build task olusturur
---@param container64 any
---@param macro any
---@param tShipPlan table
---@param tIndividualInstructions table
---@param customshipname any
---@param haspaid any                       -- pesin ödenen tutar
---@param totalprice any                    -- toplam task maliyeti
---@param objectprice any                   -- haspaid varsa taska aktarilacak tutar yoksa haspaid
---@param objectcrewprice any               -- haspaid varsa taska aktarilacak tutar yoksa haspaid
---@return BuildTaskID uint64_t             -- uretilen BuildTaskID, taskinfosu ile detaylara ulasilabilir
function menu.add_build_to_construct_ship(container64, macro, tShipPlan, tIndividualInstructions, tBulkkCrew, customshipname, haspaid, totalprice, objectprice, objectcrewprice)
    
    -- hemen üretim istenecek
    local immediate = true
    -- crewplan oluşturmak istersek , Helper.callLoadoutFunction içinde alttaki gibi okyacak veriyi
    -- crewplan.transferdetails = {  { newrole = 'service' , npc = seed , price = 0  } , { newrole = 'marine', npc = , price =  }, { newrole = , npc = , price =  }  }
    local crewplan = false
    -- var olan üzerinde çalışmayacağız, bu yüzden object = istasyon olacak
    local object = 0 -- task için mevcut objemiz yok, macro devreye girecek
    local isplayerowned = GetComponentData(container64, "isplayerowned")


    local numblacklisttypes = 0
    for _,bltype in ipairs(config.blacklisttypes) do
        for _,entry in ipairs(tIndividualInstructions) do
            if entry.a_rowdata == ("orders_blacklist_" .. bltype.type) then
                numblacklisttypes = numblacklisttypes + 1
            end
        end
    end
    local blacklists = ffi.new("BlacklistTypeID[?]", numblacklisttypes)
    local i = 0
    for _,blacklisttype in ipairs(config.blacklisttypes) do
        for _,entry in ipairs(tIndividualInstructions) do
            if entry.a_rowdata == ("orders_blacklist_" .. blacklisttype.type) then
                blacklists[i].type = blacklisttype.type
                blacklists[i].id = entry.BlacklistID
                i = i + 1
            end
        end
    end

    local numfightruletypes = 1
    local fightrules = ffi.new("FightRuleTypeID[?]", numfightruletypes)
    for _,entry in ipairs(tIndividualInstructions) do
        if entry.a_rowdata == ("orders_fightrule_" .. "attack") then
            fightrules[0].type = "attack"
            fightrules[0].id = entry.FightRuleID
            break
        end
    end


    local additionalinfo = ffi.new("AddBuildTask5Container", {
        blacklists = blacklists,
        numblacklists = numblacklisttypes,
        fightrules = fightrules,
        numfightrules = numfightruletypes
    })

    

	--BuildTaskID AddBuildTask4(UniverseID containerid, UniverseID defensibleid, const char* macroname, UILoadout2 uiloadout, int64_t price, CrewTransferInfo2 crewtransfer, bool immediate, const char* customname);
	--BuildTaskID AddBuildTask5(UniverseID containerid, UniverseID defensibleid, const char* macroname, UILoadout2 uiloadout, int64_t price, CrewTransferInfo2 crewtransfer, bool immediate, const char* customname, AddBuildTask5Container* additionalinfo);

    local buildtaskid = Helper.callLoadoutFunction(
            tShipPlan, 
            crewplan, 
            function (loadout, crewtransfer) return C.AddBuildTask5(container64, object, macro, loadout, isplayerowned and 0 or (objectprice or totalprice) , crewtransfer, immediate, customshipname, additionalinfo) end, 
            nil, 
            "UILoadout2"
    )

    if (buildtaskid ~= 0) and haspaid then
        -- oluşturulan taska .transferedamount tutarını verelim, (parasını peşin verdiğimizi bildiriyoruz)
        C.SetBuildTaskTransferredMoney(buildtaskid, objectprice and (objectprice + objectcrewprice) or haspaid)
    end

    return buildtaskid
    
end

-- ----------------------------------------------------
-- Individual Instructions FUNCTIONS
-- ----------------------------------------------------

function menu.getTradeRules()
	local traderules = {}
	Helper.ffiVLA(traderules, "TradeRuleID", C.GetNumAllTradeRules, C.GetAllTradeRules)
	for i = #traderules, 1, -1 do
		local id = traderules[i]

		local counts = C.GetTradeRuleInfoCounts(id)
		local buf = ffi.new("TradeRuleInfo")
		buf.numfactions = counts.numfactions
		buf.factions = Helper.ffiNewHelper("const char*[?]", counts.numfactions)
		if C.GetTradeRuleInfo(buf, id) then
			local factions = {}
			local hasplayer = false
			for j = 0, buf.numfactions - 1 do
				local faction = ffi.string(buf.factions[j])
				if faction == "player" then
					hasplayer = true
				else
					table.insert(factions, faction)
				end
			end
			table.sort(factions, Helper.sortFactionName)
			if hasplayer then
				table.insert(factions, 1, "player")
			end

			traderules[i] = { id = id, name = ffi.string(buf.name), factions = factions, iswhitelist = buf.iswhitelist }
		else
			table.remove(traderules, i)
		end
	end
	table.sort(traderules, Helper.sortID)

    return traderules
end

function menu.get_SignalData(rowdata)
    for _, entry in ipairs(menu.tIndividualInstructions) do
        if tostring(entry.a_rowdata) == tostring(rowdata) then
            return entry
        end
    end
    return nil
end

local function Set_IndividualInstructions(_, params)

    playerID = playerID or ConvertStringTo64Bit(tostring(C.GetPlayerID()))

    local IIStack = GetNPCBlackboard(playerID, "$IIStack")

    if not IIStack then DebugError(menu.name .. ", player.entity.$IIStack = nil must be a list"); return; end

    if #IIStack > 0 then
        local IndividualInstructions = IIStack[1]
        --menu.tablePrint(IndividualInstructions, " IIStack[" .. "1/" .. tostring(#IIStack) .. "] = " , false, true, 2)
        table.remove(IIStack, 1)
        SetNPCBlackboard(playerID, "$IIStack", IIStack)

        local controllable = ConvertStringTo64Bit(tostring(IndividualInstructions.controllable))
        local RFMKey = tonumber(IndividualInstructions.RFMKey)
        local ShipKey = tonumber(IndividualInstructions.ShipKey)
        local xdebug = (tonumber(IndividualInstructions.isdebug) == 1)
        menu.tIndividualInstructions = IndividualInstructions.tIndividualInstructions
        
        if IsValidComponent(controllable) then 

            local isShip, isStation = C.IsComponentClass(controllable, "ship"), C.IsComponentClass(controllable, "station")
            local faction, primarypurpose, issupplyship = GetComponentData(controllable, "owner", "primarypurpose", "issupplyship")

            local blacklists = Helper.getBlackLists()
            local fightrules = Helper.getFightRules()
            local traderules = menu.getTradeRules()

            -- Reaction to Events
            if isShip then
                if #menu.signals == 0 then local x = xdebug and DebugError("menu.Set_IndividualInstructions()  menu.signals boş") end
                for _, signalentry in ipairs(menu.signals) do
                    local entry = menu.get_SignalData("orders_" .. signalentry.id)
                    if entry then
                        local signalid = entry.id
                        local hasownresponse = (tonumber(entry.hasOwn) == 1)
                        local ask = (tonumber(entry.ask) == 1)
                        local response = entry.response
                        if not hasownresponse then
                            if not C.ResetResponseToSignalForControllable(signalid, controllable) then
                                local x = xdebug and DebugError("menu.".. menu.name .. ":Set_IndividualInstructions() Failed resetting response to signal " .. tostring(signalid) .. " for controllable " .. ffi.string(C.GetComponentName(controllable)) .. " " .. tostring(controllable))
                            end
                        else
                            C.SetDefaultResponseToSignalForControllable(response, ask, signalid, controllable)
                        end
                    end
                end
            end

            -- resupply, blacklists, fight rules
            if isShip or isStation then
                -- Automatic resupply
                local entry = menu.get_SignalData("orders_resupply")
                if entry then
                    local hasOwn = (tonumber(entry.hasOwn) == 1)
                    if hasOwn then
                        C.SetDefensibleLoadoutLevel(controllable, tonumber(entry.LoadoutLevel))
                    else
                        C.SetDefensibleLoadoutLevel(controllable, -1)
                    end
                end

                -- blacklists
                local types = {
                    { type = "sectortravel",	name = "Sector Travel" },
                    { type = "sectoractivity",	name = "Sector Activities" },
                    { type = "objectactivity",	name = "Trade Restrictions" },
                }
                for i, type in ipairs(types) do
                    local entry = menu.get_SignalData("orders_blacklist_"..type.type)
                    if entry then
                        local hasOwn = (tonumber(entry.hasOwn) == 1)
                        if hasOwn then
                            local found = false
                            for _, blacklist in ipairs(blacklists) do
                                if blacklist.type == entry.type then
                                    if tonumber(blacklist.id) == tonumber(entry.BlacklistID) then
                                        found = true
                                        break
                                    end
                                end
                            end
                            if found then
                                C.SetControllableBlacklist(controllable, tonumber(entry.BlacklistID), entry.type, true)
                            else
                                C.SetControllableBlacklist(controllable, -1, entry.type, true)
                            end
                        else
                            C.SetControllableBlacklist(controllable, -1, entry.type, false)
                        end
                    end
                end

                --menu.tablePrint(fightrules, " fightrules = ")

                -- fight rules
                local entry = menu.get_SignalData("orders_fightrule_attack")
                if entry then
                    local hasOwn = (tonumber(entry.hasOwn) == 1)
                    if hasOwn then
                        local found = false
                        for _, fightrule in ipairs(fightrules) do
                            if tonumber(fightrule.id) == tonumber(entry.FightRuleID) then
                                found = true
                                break
                            end
                        end
                        if found then
                            C.SetControllableFightRule(controllable, tonumber(entry.FightRuleID), entry.type, true)
                        else
                            C.SetControllableFightRule(controllable, -1, entry.type, true)
                        end
                    else
                        C.SetControllableFightRule(controllable, -1, entry.type, false)
                    end
                end
            end

            -- ship trade prices & restrictions
            if isShip then
                -- trade loop cargo reservations
                local entry = menu.get_SignalData("orders_cargoreservations")
                if entry then
                    local hasOwn = (tonumber(entry.hasOwn) == 1)
                    if not hasOwn then
                        C.RemoveShipTradeLoopCargoReservationOverride(controllable)
                    else
                        C.SetShipTradeLoopCargoReservationOverride(controllable, (tonumber(entry.TradeLoopCargoReservationSetting) == 1))
                    end
                end

                -- preferred build method, trade rule
                if issupplyship then
                    -- preferred build method
                    local entry = menu.get_SignalData("info_buildrule")
                    if entry then
                        local hasOwn = (tonumber(entry.hasOwn) == 1)
                        if not hasOwn then
                            C.SetContainerBuildMethod(controllable, "")
                        else
                            C.SetContainerBuildMethod(controllable, entry.BuildMethodID)
                        end
                    end

                    -- trade rule
                    local entry = menu.get_SignalData("order_wares_current")
                    if entry then
                        local hasOwn = (tonumber(entry.hasOwn) == 1)
                        if hasOwn then
                            local found = false
                            for _, traderule in ipairs(traderules) do
                                if tonumber(traderule.id) == tonumber(entry.TradeRuleID) then
                                    found = true
                                    break
                                end
                            end
                            if found then
                                C.SetContainerTradeRule(controllable, tonumber(entry.TradeRuleID), "buy", "", true)
                                C.SetContainerTradeRule(controllable, tonumber(entry.TradeRuleID), "sell", "", true)
                            else
                                C.SetContainerTradeRule(controllable, -1, "buy", "", true)
                                C.SetContainerTradeRule(controllable, -1, "sell", "", true)
                            end
                        else
                            C.SetContainerTradeRule(controllable, -1, "buy", "", false)
                            C.SetContainerTradeRule(controllable, -1, "sell", "", false)
                        end
                    end

                    -- resupply trade wares
                    local wares = {}
                    local n = C.GetNumMaxProductionStorage(controllable)
                    local buf = ffi.new("UIWareAmount[?]", n)
                    n = C.GetMaxProductionStorage(buf, n, controllable)
                    for i = 0, n - 1 do
                        table.insert(wares, ffi.string(buf[i].wareid))
                    end
                    for _, ware in ipairs(wares) do
                        local entry = menu.get_SignalData("order_wares_"..ware)
                        if entry then
                            -- trade rule
                            local hasownlist = (tonumber(entry.hasOwn) == 1)
                            local traderuleid = tonumber(entry.TradeRuleID)
                            local currentprice = entry.currentprice
                            local haspriceoverride = (tonumber(entry.haspriceoverride) == 1)

                            if hasownlist then
                                local found = false
                                for _, traderule in ipairs(traderules) do
                                    if tonumber(traderule.id) == tonumber(entry.TradeRuleID) then
                                        found = true
                                        break
                                    end
                                end
                                if found then
                                    C.SetContainerTradeRule(controllable, tonumber(entry.TradeRuleID), "buy", ware, true)
                                    C.SetContainerTradeRule(controllable, tonumber(entry.TradeRuleID), "sell", ware, true)
                                else
                                    C.SetContainerTradeRule(controllable, -1, "buy", ware, true)
                                    C.SetContainerTradeRule(controllable, -1, "sell", ware, true)
                                end
                            else
                                C.SetContainerTradeRule(controllable, -1, "buy", ware, false)
                                C.SetContainerTradeRule(controllable, -1, "sell", ware, false)
                            end
            
                            if not haspriceoverride then
                                ClearContainerWarePriceOverride(controllable, ware, true)
                            else
                                SetContainerWarePriceOverride(controllable, ware, true, currentprice)
                            end
                        end
                    end
                end
            end

            local x = xdebug and DebugError("Completed Set_IndividualInstructions {" .. tostring(RFMKey) .. "}.{" .. tostring(ShipKey) .. "} for controllable " .. ffi.string(C.GetComponentName(controllable)) .. " objectlua = " .. tostring( ConvertStringToLuaID(tostring(controllable)) )  .. " Left #IIStack = " .. tostring(#IIStack) )
        end

        if #IIStack == 0 then
            SetNPCBlackboard(playerID, "$IIStack", nil)
        end
    else
        DebugError("IIStack is EMPTY" )
    end

end
RegisterEvent("Set_IndividualInstructions", Set_IndividualInstructions)

--- 'controllable' icin IndividualInstructions tablosu geri verir
---@param controllable any      -- object yoksa (0) ise foknsiyon default degerleri geri verecek
---@param isShip any
---@param isStation any
---@param faction any
---@param primarypurpose any
---@param issupplyship any
function menu.Get_IndividualInstructions(controllable, isShip, isStation, faction, primarypurpose, issupplyship)
    
    local IndividualInstructions = {}

    -- Reaction to Events
    if isShip then
        for _, signalentry in ipairs(menu.signals) do
			local signalid = signalentry.id
            local ask = false
            local response = signalentry.defaultresponse
            local hasownresponse = false
            if controllable ~= 0 then
                ask = C.GetAskToSignalForControllable(signalid, controllable)
                response = ffi.string(C.GetDefaultResponseToSignalForControllable(signalid, controllable))
                hasownresponse = C.HasControllableOwnResponse(controllable, signalid)
            end
            local entry = { a_rowdata = "orders_" .. tostring(signalid), a_rowgroup = "Reaction to Events", name = signalentry.name, id = signalid, response = response, ask = ask, hasOwn = hasownresponse }
            table.insert(IndividualInstructions, entry)
        end
    end

    -- resupply, blacklists, fight rules
    if isShip or isStation then
        -- Automatic resupply
        -- not hasOwn and id = -1
        -- hasOwn and id = [ 0 = Off or globals( 0.1 = Low, 0.5 = Medium, 1 = High ) ]
        local curOption = Helper.round(C.GetPlayerGlobalLoadoutLevel(), 1)
        local hasownresponse = false
        if controllable ~= 0 then
            curOption = Helper.round(C.GetDefensibleLoadoutLevel(controllable), 1)
            hasownresponse = (curOption ~= -1)
            -- recordda fleetcommanderin bu değerini rfm oluşturulurken saklamak lazım
            -- kendisi üretimde ise default değeri alsın
            if C.IsComponentOperational( controllable ) then    
                local componentlua = ConvertStringToLuaID(tostring(controllable)) 
                -- commander üretimde değilse yukarı doğru commanderları (fleet commandra kadar) tarama yapacak
                while curOption == -1 do
                    local component64 = ConvertIDTo64Bit( componentlua )
                    local isOperational = C.IsComponentOperational( component64 )
                    componentlua = ConvertStringToLuaID(tostring(component64))
                    -- üretimde olana denk gelirse okuyamayacağımız için default değeri alsın
                    if not isOperational then   
                        curOption = Helper.round(C.GetPlayerGlobalLoadoutLevel(), 1)
                        break
                    else
                        componentlua = GetCommander(component64)
                        if componentlua then
                            curOption = Helper.round(C.GetDefensibleLoadoutLevel(ConvertIDTo64Bit(componentlua)), 1)
                        else
                            curOption = Helper.round(C.GetPlayerGlobalLoadoutLevel(), 1)
                            break
                        end
                    end
                end
            else
                curOption = Helper.round(C.GetPlayerGlobalLoadoutLevel(), 1)
            end
        end
        table.insert(IndividualInstructions, { a_rowdata = "orders_resupply", a_rowgroup = isShip and "Automatic Resupply" or "Automatic Resupply of Subordinates", LoadoutLevel = curOption, hasOwn = hasownresponse } )

        -- blacklists
		local group = ((primarypurpose == "fight") or (primarypurpose == "auxiliary")) and "military" or "civilian"
		local types = {
			{ type = "sectortravel",	name = "Sector Travel" },
			{ type = "sectoractivity",	name = "Sector Activities" },
			{ type = "objectactivity",	name = "Trade Restrictions" },
		}
        for i, entry in ipairs(types) do
            local hasownlist = false
            local blacklistid = -1
            if controllable ~= 0 then
                hasownlist = C.HasControllableOwnBlacklist(controllable, entry.type)
                blacklistid = hasownlist and C.GetControllableBlacklistID(controllable, entry.type, group) or 0
            end
            table.insert(IndividualInstructions, { a_rowdata = "orders_blacklist_" .. entry.type, a_rowgroup = isShip and "Blacklists" or "Blacklists for Subordinates", type = entry.type, BlacklistID = (blacklistid ~= 0) and blacklistid or -1, hasOwn = hasownlist } )
        end

        -- fight rules
		
		local hasownrule = false
		local fightruleid = -1
        if controllable ~= 0 then
		    hasownrule = C.HasControllableOwnFightRule(controllable, "attack")
		    fightruleid = hasownrule and C.GetControllableFightRuleID(controllable, "attack") or 0
        end
        table.insert(IndividualInstructions, { a_rowdata = "orders_fightrule_attack", a_rowgroup = "Fire Authorisation Overrides", type = "attack", FightRuleID = (fightruleid ~= 0) and fightruleid or -1, hasOwn = hasownrule } )

    end
    
    -- ship trade prices & restrictions, preferred build method, trade rule
    if isShip then
        -- trade loop cargo reservations
		local hasownresponse = false
		local curOption = false
        if controllable ~= 0 then
            hasownresponse = C.HasShipTradeLoopCargoReservationOverride(controllable)
            curOption = C.GetShipTradeLoopCargoReservationSetting(controllable) 
        end
        table.insert(IndividualInstructions, { a_rowdata = "orders_cargoreservations", a_rowgroup = "Trade Loop Cargo Reservations" , TradeLoopCargoReservationSetting = curOption, hasOwn = hasownresponse } )

        -- preferred build method, trade rule
        if issupplyship then
            -- preferred build method
            local cursetting = ""
            if controllable ~= 0 then
                cursetting = ffi.string(C.GetContainerBuildMethod(controllable))
            end
            local hasownsetting = cursetting ~= ""

			local curglobalsetting = ffi.string(C.GetPlayerBuildMethod())
			local foundcursetting = false
			local n = C.GetNumPlayerBuildMethods()
			if n > 0 then
				local buf = ffi.new("ProductionMethodInfo[?]", n)
				n = C.GetPlayerBuildMethods(buf, n)
				for i = 0, n - 1 do
					local id = ffi.string(buf[i].id)
					-- check if the curglobalsetting (which can be the method of the player's race) is in the list of options
					if id == curglobalsetting then
						foundcursetting = true
					end
				end
			end
			-- if the setting is not in the list, default to default (if the race method is not in the list, there is no ware that has this method and it will always use default)
			if not foundcursetting then
				curglobalsetting = "default"
			end
            table.insert(IndividualInstructions , { a_rowdata = "info_buildrule", a_rowgroup = "Preferred Build Method", BuildMethodID = hasownsetting and cursetting or curglobalsetting, hasOwn = hasownsetting } )

            -- trade rule
			local hasownlist = false
			local traderuleid = -1
            if controllable ~= 0 then
                hasownlist = C.HasContainerOwnTradeRule(controllable, "buy", "") or C.HasContainerOwnTradeRule(controllable, "sell", "")
                traderuleid = hasownlist and C.GetContainerTradeRuleID(controllable, "buy", "") or 0
                if traderuleid ~= C.GetContainerTradeRuleID(controllable, "sell", "") then
                    DebugError("menu.Get_IndividualInstructions(): Mismatch between buy and sell trade rule on supply ship: " .. tostring(traderuleid) .. " vs " .. tostring(C.GetContainerTradeRuleID(controllable, "sell", "")))
                end
            end
            table.insert(IndividualInstructions , { a_rowdata = "order_wares_current", a_rowgroup = "Resupply Ship Trade Settings", TradeRuleID = (traderuleid ~= 0) and traderuleid or -1, hasOwn = hasownlist } )

            -- resupply trade wares
            if controllable ~= 0 then
                local wares = {}
                local n = C.GetNumMaxProductionStorage(controllable)
                local buf = ffi.new("UIWareAmount[?]", n)
                n = C.GetMaxProductionStorage(buf, n, controllable)
                for i = 0, n - 1 do
                    table.insert(wares, ffi.string(buf[i].wareid))
                end
                for _, ware in ipairs(wares) do
                    local name, minprice, maxprice = GetWareData(ware, "name", "minprice", "maxprice")
                    -- trade rule
                    local hasownlist = C.HasContainerOwnTradeRule(controllable, "buy", ware) or C.HasContainerOwnTradeRule(controllable, "sell", ware)
                    local traderuleid = hasownlist and C.GetContainerTradeRuleID(controllable, "buy", ware) or 0
                    if traderuleid ~= C.GetContainerTradeRuleID(controllable, "sell", ware) then
                        DebugError("menu.Get_IndividualInstructions(): Mismatch between buy and sell trade rule on supply ship: " .. tostring(traderuleid) .. " vs " .. tostring(C.GetContainerTradeRuleID(controllable, "sell", ware)))
                    end
                    local currentprice = math.max(minprice, math.min(maxprice, RoundTotalTradePrice(GetContainerWarePrice(controllable, ware, true))))
                    local haspriceoverride = HasContainerWarePriceOverride(controllable, ware, true)
                    local entry = { a_rowdata = "orders_wares_" .. ware, a_rowgroup = "Resupply Ship Wares", ware = ware, TradeRuleID = (traderuleid ~= 0) and traderuleid or -1, hasOwn = hasownlist, currentprice = currentprice, haspriceoverride = haspriceoverride }
                    table.insert(IndividualInstructions , entry )
                end
            end
        end
    end

    return IndividualInstructions
end


-- ----------------------------------------------------
-- LOADOUT FUNCTIONS
-- ----------------------------------------------------

--- It extracts the loadout plan structure of the ship sent from the MD and reports it to the MD with a trigger.
---@param _ any
---@param params string     'debug ; isChangeCrewAmounts'
local function Get_ShipPlan(_, params)
    local isdebug = false
    local isChangeCrewAmounts = false

    if params then
        local tPackets = menu.Split_ParamToPacket(params, ";")
        local packets = {}
        local key = ""
        for k,v in ipairs(tPackets)  do
            if (math.fmod(k,2) == 0) then    -- value
                packets[key] = v
            else
                key = v
            end
        end
        for k,v in pairs(packets)  do
            if k == "debug" then
                isdebug = tonumber(v) == 1
            end
            if k == "isChangeCrewAmounts" then
                isChangeCrewAmounts = tonumber(v) == 1
            end
        end
    end

    playerID = playerID or ConvertStringTo64Bit(tostring(C.GetPlayerID()))
    local plandata = GetNPCBlackboard(playerID, "$PlanData")
    
    if not plandata  then DebugError(menu.name .. ", player.entity.$PlanData nil"); return; end

    local resultData = menu.tablecopy(plandata)
    
    for _, shipEntry in ipairs(resultData) do
        
        local object64 = ConvertStringTo64Bit(tostring(shipEntry.Object))
        local getShipPlan = ( tonumber(shipEntry.getShipPlan) == 1 )
        local getIndividualInstructions = ( tonumber(shipEntry.getIndividualInstructions) == 1 )
        local macro = shipEntry.macro

        menu.shipplan = {}
        if getShipPlan then
            if object64 ~= 0 then
                menu.createShipPlan(object64, macro)
            else
                -- YAPILACAK : macroya göre (patlamış gemiler için)
                -- obje macrosuna ait slot datasını çıkarırız , ama slotlara hangi macroları atayacağız?
                -- tWare tablosuna göre rastgele ilgili typelara rastgele slotlara mı koyabiliriz?
            end
        end
        shipEntry.ShipPlanTable = menu.shipplan

        shipEntry.IndividualInstructions = {}
        if getIndividualInstructions then
            local isShip = (tonumber(shipEntry.isShip) == 1)
            local isStation = not isShip
            local faction = shipEntry.faction
            local primarypurpose = shipEntry.primarypurpose
            local issupplyship = (tonumber(shipEntry.issupplyship) == 1)
            shipEntry.IndividualInstructions = menu.Get_IndividualInstructions(object64, isShip, isStation, faction, primarypurpose, issupplyship )
        end
        
    end
    
    local controlID = "Set_ShipPlan"
    local screenParam = { resultData, isChangeCrewAmounts, isdebug }
    AddUITriggeredEvent(menu.name, controlID, screenParam)

    --local x = isdebug and DebugError("Returning from lua..")

end
RegisterEvent("Get_ShipPlan", Get_ShipPlan)

-- creating menu.shipplan
function menu.createShipPlan(object64, macro)
    
    local name = ffi.string(C.GetComponentName(object64))
    local idcode = ffi.string(C.GetObjectIDCode(object64))
    local class = ffi.string(C.GetComponentClass(object64))
    local primarypurpose, icon, hasanymod = GetComponentData(ConvertStringTo64Bit(tostring(object64)), "primarypurpose", "icon", "hasanymod")
    local objectID = ConvertStringToLuaID(tostring(object64))

    menu.planDATA.object = object64
    menu.planDATA.macro = macro

	-- assemble available slots/ammo/software
    menu.planDATA.missingUpgrades = {}
	menu.planDATA.groups = {}
	menu.planDATA.slots = {}
	menu.planDATA.ammo = { missile = {}, drone = {}, deployable = {}, countermeasure = {}, }
	menu.planDATA.software = {}
	menu.planDATA.crew = {
        wanted = 0,
		total = 0,
		capacity = 0,
		roles = {},
		ware = "crew",
	}

    menu.shipplan = {}
    for _, upgradetype in ipairs(Helper.upgradetypes) do
        menu.shipplan[upgradetype.type] = {}
    end

    -- menu.groups güncelle ve menu.shipplan ve menu.planDATA.upgradewares.amount bilgisini güncelle
    menu.setupGroupData(menu.planDATA.object, menu.planDATA.macro, menu.planDATA.groups)
    -- menu.slots, menu.ammo ve menu.software güncelle ve menu.planDATA.upgradewares.amount bilgisini güncelle
    menu.prepareComponentUpgradeSlots(menu.planDATA.object, menu.planDATA.macro, menu.planDATA.slots, menu.planDATA.ammo, menu.planDATA.software)
    -- menu.crew güncelle
    menu.prepareComponentCrewInfo(menu.planDATA.object)
    --menu.shipplan.hascrewexperience = true     -- nerden öğrenebiliriz?
end

function menu.setupGroupData(object, macro, groups)
	local sizecounts = { engine = {}, turret = {} }
	local n = C.GetNumUpgradeGroups(object, macro)
	local buf = ffi.new("UpgradeGroup[?]", n)
	n = C.GetUpgradeGroups(buf, n, object, macro)
	for i = 0, n - 1 do
		if (ffi.string(buf[i].path) ~= "..") or (ffi.string(buf[i].group) ~= "") then
			table.insert(groups, { path = ffi.string(buf[i].path), group = ffi.string(buf[i].group) })
			local group = groups[#groups]
			for j, upgradetype in ipairs(Helper.upgradetypes) do
				if upgradetype.supertype == "group" then
					local groupinfo = C.GetUpgradeGroupInfo(object, macro, group.path, group.group, upgradetype.grouptype)
					local currentmacro = ffi.string(groupinfo.currentmacro)
					local slotsize = ffi.string(groupinfo.slotsize)

					local compatibilities
					local n_comp = C.GetNumUpgradeGroupCompatibilities(object, macro, 0, group.path, group.group, upgradetype.grouptype)
					if n_comp > 0 then
						compatibilities = {}
						local buf_comp = ffi.new("EquipmentCompatibilityInfo[?]", n)
						n_comp = C.GetUpgradeGroupCompatibilities(buf_comp, n_comp, object, macro, 0, group.path, group.group, upgradetype.grouptype)
						for k = 0, n_comp - 1 do
							compatibilities[ffi.string(buf_comp[k].tag)] = ffi.string(buf_comp[k].name)
						end
					end

					groups[#groups][upgradetype.grouptype] = { count = groupinfo.count, operational = groupinfo.operational, total = groupinfo.total, slotsize = slotsize, compatibilities = compatibilities, currentcomponent = (groupinfo.currentcomponent ~= 0) and groupinfo.currentcomponent or nil, currentmacro = currentmacro, possiblemacros = {} }
					if upgradetype.grouptype ~= "shield" then
						groups[#groups].slotsize = slotsize
						groups[#groups].compatibilities = compatibilities

						if groups[#groups][upgradetype.grouptype].total > 0 then
							groups[#groups].groupname = #groups
							if slotsize ~= "" then
								if sizecounts[upgradetype.grouptype][slotsize] then
									sizecounts[upgradetype.grouptype][slotsize] = sizecounts[upgradetype.grouptype][slotsize] + 1
								else
									sizecounts[upgradetype.grouptype][slotsize] = 1
								end
								groups[#groups].groupname = upgradetype.shorttext[slotsize] .. sizecounts[upgradetype.grouptype][slotsize]
							end
						end
					end
					
                    local weaponmode = ""
                    if object ~= 0 then
                        weaponmode = ffi.string(C.GetTurretGroupMode2(object, 0, group.path, group.group))
                    end
                    
                    if groupinfo.total > 0 then
                        table.insert(menu.shipplan[upgradetype.type], { a_gname = group.groupname, a_slotsize = slotsize, a_total = groupinfo.total  , macro = currentmacro, count = groupinfo.count, path = group.path, group = group.group, ammomacro = "", weaponmode = weaponmode } )
                    end
				end
			end
		end
	end
end
function menu.findUpgradeMacro(loctype, macro)
	if type(menu.planDATA.upgradewares[loctype]) == "table" then
		for i, upgradeware in ipairs(menu.planDATA.upgradewares[loctype]) do
			if upgradeware.macro == macro then
				return i
			end
		end
	end
end
function menu.setMissingUpgrade(ware, amount, allownewentry)
	for j, entry in ipairs(menu.planDATA.missingUpgrades) do
		if entry.ware == ware then
			menu.planDATA.missingUpgrades[j].amount = menu.planDATA.missingUpgrades[j].amount + amount
			return
		end
	end
	if allownewentry then
		table.insert(menu.planDATA.missingUpgrades, { ware = ware, name = GetWareData(ware, "name"), amount = amount })
	end
end
function menu.prepareComponentCrewInfo(object)
	local n = C.GetNumAllRoles()
	local buf = ffi.new("PeopleInfo[?]", n)
	n = C.GetPeople2(buf, n, object, true)
	local numhireable = 0
	for i = 0, n - 1 do
		if buf[i].canhire then
			numhireable = numhireable + 1
			menu.planDATA.crew.roles[numhireable] = { id = ffi.string(buf[i].id), name = ffi.string(buf[i].name), desc = ffi.string(buf[i].desc), total = buf[i].amount, wanted = buf[i].amount, tiers = {}, canhire = buf[i].canhire }
			menu.planDATA.crew.total = menu.planDATA.crew.total + buf[i].amount
            menu.shipplan.crew[ffi.string(buf[i].id)] = buf[i].amount
            --[[
			local numtiers = buf[i].numtiers
			local buf2 = ffi.new("RoleTierData[?]", numtiers)
			numtiers = C.GetRoleTiers(buf2, numtiers, object, menu.planDATA.crew.roles[numhireable].id)
			for j = 0, numtiers - 1 do
				menu.planDATA.crew.roles[numhireable].tiers[j + 1] = { skilllevel = buf2[j].skilllevel, name = ffi.string(buf2[j].name), total = buf2[j].amount, wanted = buf2[j].amount, npcs = {}, currentnpcs = {} }

				local numnpcs = buf2[j].amount
				local buf3 = ffi.new("NPCSeed[?]", numnpcs)
				numnpcs = C.GetRoleTierNPCs(buf3, numnpcs, object, menu.planDATA.crew.roles[numhireable].id, menu.planDATA.crew.roles[numhireable].tiers[j + 1].skilllevel)
				for k = 0, numnpcs - 1 do
					table.insert(menu.planDATA.crew.roles[numhireable].tiers[j + 1].npcs, buf3[k])
					table.insert(menu.planDATA.crew.roles[numhireable].tiers[j + 1].currentnpcs, buf3[k])
				end
			end
			if numtiers == 0 then
				menu.planDATA.crew.roles[numhireable].tiers[1] = { skilllevel = 0, hidden = true, total = buf[i].amount, wanted = buf[i].amount, npcs = {}, currentnpcs = {} }
				local numnpcs = buf[i].amount
				local buf3 = ffi.new("NPCSeed[?]", numnpcs)
				numnpcs = C.GetRoleTierNPCs(buf3, numnpcs, object, menu.planDATA.crew.roles[numhireable].id, 0)
				for k = 0, numnpcs - 1 do
					table.insert(menu.planDATA.crew.roles[numhireable].tiers[1].npcs, buf3[k])
					table.insert(menu.planDATA.crew.roles[numhireable].tiers[1].currentnpcs, buf3[k])
				end
			end
            ]]                        
		end
	end

	menu.planDATA.crew.capacity = C.GetPeopleCapacity(menu.planDATA.object, menu.planDATA.macro, false)
end
function menu.prepareComponentUpgradeSlots(object, macro, slots, ammo, software)
	
	-- for all members of set upgradetypes,
	for i, upgradetype in ipairs(Helper.upgradetypes) do
		-- with supertype "macro" (there should be 4)
        -- engine , shield, weapon, turret
		if upgradetype.supertype == "macro" then
			-- initialize an entry in table slots with key upgradetype.type
			slots[upgradetype.type] = {}
			-- and for all slots in the object,
            -- engine , shield, weapon, turret
            menu.shipplan[upgradetype.type] = {}
			for j = 1, tonumber(C.GetNumUpgradeSlots(object, "", upgradetype.type)) do
				local groupinfo = C.GetUpgradeSlotGroup(object, "", upgradetype.type, j)
                -- engine or others shield, weapon, turret
				if upgradetype.pseudogroup or ((ffi.string(groupinfo.path) == "..") and (ffi.string(groupinfo.group) == "")) then
                    local currentmacro = ffi.string(C.GetUpgradeSlotCurrentMacro(object, 0, upgradetype.type, j))
					-- slots[upgradetype.type][j] = { currentmacro = ffi.string(C.GetUpgradeSlotCurrentMacro(object, 0, upgradetype.type, j)), possiblemacros = {}, component = nil }

                    local slotsize = ffi.string(C.GetSlotSize(object, 0, macro, false, upgradetype.type, j ) )                    
                    local slotname = ""
                    if slotsize == "small" then
                        slotname = "S" .. tostring(j)
                    elseif slotsize == "medium" then
                        slotname = "M" .. tostring(j)
                    elseif slotsize == "large" then
                        slotname = "L" .. tostring(j)
                    elseif slotsize == "extralarge" then
                        slotname = "XL" .. tostring(j)
                    end
    
                    local entry = { a_slot = tostring(j), a_slotname = slotname, a_slotsize = slotsize, macro = currentmacro, ammomacro = "", weaponmode = "" }

                    local currentcomponent = C.GetUpgradeSlotCurrentComponent(object, upgradetype.type, j)
                    if currentcomponent ~= 0 then
                        -- slots[upgradetype.type][j].component = currentcomponent
                        if C.IsComponentClass(currentcomponent, "weapon") then
                            --menu.shipplan[upgradetype.type][j].weaponmode = ffi.string(C.GetWeaponMode(currentcomponent))
                            entry.weaponmode = ffi.string(C.GetWeaponMode(currentcomponent))
                            if C.IsComponentClass(currentcomponent, "missilelauncher") then
                                --menu.shipplan[upgradetype.type][j].ammomacro = ffi.string(C.GetCurrentAmmoOfWeapon(currentcomponent))
                                entry.ammomacro = ffi.string(C.GetCurrentAmmoOfWeapon(currentcomponent))
                            end
                        end
                    end
                    
                    table.insert(menu.shipplan[upgradetype.type], entry)

                else
					-- slots[upgradetype.type][j] = { currentmacro = "", possiblemacros = {}, component = nil }
				end

			end
		elseif upgradetype.supertype == "ammo" then
			ammo[upgradetype.type] = {}

			local ammoentry = {}
			if upgradetype.type == "missile" then
				local n = C.GetNumAllMissiles(object)
				local buf = ffi.new("AmmoData[?]", n)
				n = C.GetAllMissiles(buf, n, object)
				for j = 0, n - 1 do
					local entry = {}
					entry.macro = ffi.string(buf[j].macro)
					entry.amount = buf[j].amount
					table.insert(ammoentry, entry)
				end
			elseif upgradetype.type == "drone" then
				local n = C.GetNumAllUnits(object, false)
				local buf = ffi.new("UnitData[?]", n)
				n = C.GetAllUnits(buf, n, object, false)
				for j = 0, n - 1 do
					local entry = {}
					entry.macro = ffi.string(buf[j].macro)
					entry.category = ffi.string(buf[j].category)
					entry.amount = buf[j].amount
					table.insert(ammoentry, entry)
				end
			elseif upgradetype.type == "deployable" then
				local numlasertowers = C.GetNumAllLaserTowers(object)
				local lasertowers = ffi.new("AmmoData[?]", numlasertowers)
				numlasertowers = C.GetAllLaserTowers(lasertowers, numlasertowers, object)
				for j = 0, numlasertowers - 1 do
					local entry = {}
					entry.macro = ffi.string(lasertowers[j].macro)
					entry.amount = lasertowers[j].amount
					table.insert(ammoentry, entry)
				end

				local numsatellites = C.GetNumAllSatellites(object)
				local satellites = ffi.new("AmmoData[?]", numsatellites)
				numsatellites = C.GetAllSatellites(satellites, numsatellites, object)
				for j = 0, numsatellites - 1 do
					local entry = {}
					entry.macro = ffi.string(satellites[j].macro)
					entry.amount = satellites[j].amount
					table.insert(ammoentry, entry)
				end

				local nummines = C.GetNumAllMines(object)
				local mines = ffi.new("AmmoData[?]", nummines)
				nummines = C.GetAllMines(mines, nummines, object)
				for j = 0, nummines - 1 do
					local entry = {}
					entry.macro = ffi.string(mines[j].macro)
					entry.amount = mines[j].amount
					table.insert(ammoentry, entry)
				end

				local numnavbeacons = C.GetNumAllNavBeacons(object)
				local navbeacons = ffi.new("AmmoData[?]", numnavbeacons)
				numnavbeacons = C.GetAllNavBeacons(navbeacons, numnavbeacons, object)
				for j = 0, numnavbeacons - 1 do
					local entry = {}
					entry.macro = ffi.string(navbeacons[j].macro)
					entry.amount = navbeacons[j].amount
					table.insert(ammoentry, entry)
				end

				local numresourceprobes = C.GetNumAllResourceProbes(object)
				local resourceprobes = ffi.new("AmmoData[?]", numresourceprobes)
				numresourceprobes = C.GetAllResourceProbes(resourceprobes, numresourceprobes, object)
				for j = 0, numresourceprobes - 1 do
					local entry = {}
					entry.macro = ffi.string(resourceprobes[j].macro)
					entry.amount = resourceprobes[j].amount
					table.insert(ammoentry, entry)
				end
			elseif upgradetype.type == "countermeasure" then
				local n = C.GetNumAllCountermeasures(object)
				local buf = ffi.new("AmmoData[?]", n)
				n = C.GetAllCountermeasures(buf, n, object)
				local totalnumcountermeasures = 0
				for j = 0, n - 1 do
					local entry = {}
					entry.macro = ffi.string(buf[j].macro)
					entry.amount = buf[j].amount
					table.insert(ammoentry, entry)
				end
			end

			for _, item in ipairs(ammoentry) do
				menu.shipplan[upgradetype.type][item.macro] = item.amount
				
			end
		elseif upgradetype.supertype == "software" then
			software[upgradetype.type] = {}
			local n = C.GetNumSoftwareSlots(object, "")
			local buf = ffi.new("SoftwareSlot[?]", n)
			n = C.GetSoftwareSlots(buf, n, object, "")
			for j = 0, n - 1 do
				local entry = {}
				entry.maxsoftware = ffi.string(buf[j].max)
				entry.currentsoftware = ffi.string(buf[j].current)
				
				table.insert(menu.shipplan[upgradetype.type], entry.currentsoftware)
				
				--table.insert(software[upgradetype.type], entry)
			end
		elseif upgradetype.supertype == "virtualmacro" then
			slots[upgradetype.type] = {}
			for j = 1, tonumber(C.GetNumVirtualUpgradeSlots(object, "", upgradetype.type)) do
				-- convert index from lua to C-style

                local class = ffi.string(C.GetMacroClass(macro))
                local slotsize = "" 
                local slotname = ""
                if class == "ship_s" then
                    slotsize = "small"
                    slotname = "S" .. tostring(j)
                elseif menu.class == "ship_m" then
                    class = "medium"
                    slotname = "M" .. tostring(j)
                elseif menu.class == "ship_l" then
                    class = "large"
                    slotname = "L" .. tostring(j)
                elseif menu.class == "ship_xl" then
                    class = "extralarge"
                    slotname = "XL" .. tostring(j)
                end
        
                local currentmacro = ffi.string(C.GetVirtualUpgradeSlotCurrentMacro(object, upgradetype.type, j))
				--slots[upgradetype.type][j] = { currentmacro = ffi.string(C.GetVirtualUpgradeSlotCurrentMacro(object, upgradetype.type, j)), possiblemacros = {} }
				
				menu.shipplan[upgradetype.type][j] = { a_slot = tostring(j), a_slotname = slotname, a_slotsize = slotsize, macro = currentmacro, ammomacro = "", weaponmode = "" }
				
			end
		end
	end

end

--- plan table to loadout data
---@param shipplan table
---@return userdata     -- 'UILoadout2'
function menu.convertPlanToLoadout(shipplan)
    -- shipplan yapısını loadout a çevirecek
    local loadout = Helper.callLoadoutFunction(shipplan, nil, function (loadout, _) return loadout end, true, "UILoadout2")
    return loadout
end

--- loadout data to plan table
---@param object any        -- object64 
---@param macro string
---@param loadout userdata  -- 'UILoadout2'
---@param softwaredata table
---@return table shipplan table
function menu.convertLoadoutToPlan(object, macro, loadout, softwaredata)
    -- loadout cdata yapısında (bufferlı) olduğundan normal table gibi okuyamayız. shipplan a çevirecek
    local shipplan = Helper.convertLoadout(object, macro, loadout, softwaredata, "UILoadout2")
    return shipplan
end

function menu.Split_ParamToPacket(inputstr, sep)
    sep=sep or '%s'
    local t = {}
    for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
      table.insert(t,field)
      if s == "" then return t end
    end
end



-- ----------------------------------------------------
-- TABLE FUNCTIONS
-- ----------------------------------------------------

-- tabledeki veri sayisi (__pairs method)
function menu.GetTableLng(tbl)
    local getN = 0
    for n in pairs(tbl or {} ) do 
      getN = getN + 1 
    end
    return getN
end

-- Kopyalanacak table en sona kadar parcalanarak alinir. (__pairs method)
-- new_table = tablecopy(data)  
-- copys the table "data"
function menu.tablecopy(t)
    local t2 = {};
    for k,v in pairs(t or {}) do
        if type(v) == "table" then
            t2[k] = menu.tablecopy(v);
        else
            t2[k] = v;
        end
    end
    return t2;
end

--- Removes (and returns) a table element by its key, moving down other elements to close space and decrementing the size of the array
---@param table table
---@param key any
function menu.tableremoveKey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

--- Splits the table into rows using the __pairs method and combines each row into the list.
---@param node table
---@param nodename string 
---@param tree any                  -- ( nil = newline and no indentation) or (true = newline and indentation) or (false = no newline and no indentation)
---@param IsShowNumberKeys any      -- ( is show { [1] = xxxx, [2] = yyy } else { xxx, yyy } )
---@param indentation number        -- default 1 (number of space characters betwen by tag)
---@param lineIndentString string   -- default empty (head string of line)
---@param font string               -- default Helper.standardFont
---@param fontsize number           -- default Helper.standardFontSize
---@param width number              -- default 450
---@param useConcatResult any       -- ( nil == will use SplittedLines )
function menu.tableGetTextLines(node, nodename, tree, IsShowNumberKeys, indentation, lineIndentString, font, fontsize, width, useConcatResult)
    -- lua textTable = GetTextLines(text, font, fontsize, width) fonksiyonu en fazla 100 satıra bölebiliyor.
    -- aldığımız bilgiyi satırlara ayırıp kendi listemizi oluşturacağız
    local TextLines = {}
    local indentstring = lineIndentString or ""

    local font = font or Helper.standardFont
    local fontsize = fontsize or Helper.standardFontSize
    local width = width or 450
    local concatResult, SplittedLines = menu.getstring_TableStructure(node, nodename, tree, IsShowNumberKeys, indentation)
    if not useConcatResult then
        for k, v in ipairs(SplittedLines) do
            local textTable = GetTextLines(v, font, fontsize, width)
            for i, line in ipairs(textTable) do
                table.insert(TextLines, indentstring .. line)
            end
        end
    else
        TextLines = GetTextLines(concatResult, font, fontsize, width)
    end
    return TextLines
end

--- print table with __pairs method to DebugError 
---@param node table
---@param nodename string 
---@param tree any                  -- ( nil = newline and no indentation) or (true = newline and indentation) or (false = no newline and no indentation)
---@param IsShowNumberKeys any      -- ( is show { [1] = xxxx, [2] = yyy } else { xxx, yyy } )
---@param indentation number        -- default 1 (number of space characters betwen by tag)
---@param useConcatResult any       -- ( nil == will use SplittedLines )
function menu.tablePrint(node, nodename, tree, IsShowNumberKeys, indentation, useConcatResult)
    -- concat edilmiş string bilgisi DebugError için fazla gelebiliyor. Bu yüzden concat edilmeden önceki array lı çıktı lazım bize
    -- !!! debugerror için 238 satırda bir resetliyeceğiz, daha fazla beklersek eksik bilgi basıyor
    local concatResult, SplittedLines = menu.getstring_TableStructure(node, nodename, tree, IsShowNumberKeys, indentation)
    if not useConcatResult then
        
        local maxrowvisible = 230

        local NEW_LINE = "\n"
        local TAB_CHAR = "  "
    
        if nil == tree then
            NEW_LINE = "\n"
        elseif not tree then
            NEW_LINE = ""
            TAB_CHAR = ""
        end
    
        local row = 0
        local totalrow = 0
        local str = ""
        for i, v in ipairs(SplittedLines) do
            row = row + 1
            str = str .. TAB_CHAR .. tostring(v) .. ( (row < maxrowvisible)  and NEW_LINE or "")
            if row >= maxrowvisible then
                DebugError("linesgroup #" .. tostring(totalrow + 1) .. "-" ..  tostring(i) .. NEW_LINE .. str )
                totalrow = totalrow + row
                row = 0
                str = ""
            end
        end
        DebugError("linesgroup #" .. tostring(totalrow + 1) .. "-" .. tostring(totalrow + row) .. NEW_LINE .. str )
    else
        DebugError(concatResult)  
    end
    return concatResult
end

--- string olarak table yapsini geri verir
---@param node table
---@param nodename string 
---@param tree any                  -- ( nil = newline and no indentation) or (true = newline and indentation) or (false = no newline and no indentation)
---@param IsShowNumberKeys any      -- ( is show { [1] = xxxx, [2] = yyy } else { xxx, yyy } )
---@param indentation number        -- default 1 (number of space characters betwen by tag)
function menu.getstring_TableStructure(node, nodename, tree, IsShowNumberKeys, indentation)
    local cache, stack, output = {},{},{}
    local depth = 1

    if type(node) ~= "table" then
        return "only table type is supported, got " .. type(node)
    end

    if nil == indentation then indentation = 1 end
    
    if nil == IsShowNumberKeys then
         IsShowNumberKeys = nil
    elseif not IsShowNumberKeys then
        IsShowNumberKeys = nil
    end

    local NEW_LINE = "\n"
    local TAB_CHAR = "  "

    if nil == tree then
        NEW_LINE = "\n"
    elseif not tree then
        NEW_LINE = ""
        TAB_CHAR = ""
    end

    local output_str = ( (nodename and nodename ~= "") and tostring(nodename) .. NEW_LINE or "" )  .. "{"     
    

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find( output_str, "}", output_str:len() )) then
                    output_str = output_str .. "," .. NEW_LINE
                elseif not (string.find( output_str, NEW_LINE, output_str:len() )) then
                    output_str = output_str .. NEW_LINE
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number") then
                    key = (IsShowNumberKeys) and "[" .. tostring(k) .. "]" or ""
                elseif (type(k) == "boolean") then
                    key = "[" .. tostring(k) .. "]"
                else
                    -- key = "['"..tostring(k).."']"
                    key = "" .. tostring(k) .. ""
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep(TAB_CHAR,depth*indentation) .. key .. ((key ~= "") and " = " or "") .. tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep(TAB_CHAR,depth*indentation) .. key .. ((key ~= "") and " = " or "") .. "{"  
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep(TAB_CHAR,depth*indentation) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. NEW_LINE .. string.rep(TAB_CHAR,(depth-1)*indentation) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. NEW_LINE .. string.rep(TAB_CHAR,(depth-1)*indentation) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            --output_str = output_str .. NEW_LINE .. string.rep(TAB_CHAR,(depth-1)*indentation) .. "}"
            --output_str = output_str .. string.rep(TAB_CHAR,(depth-1)*indentation) .. "}"
            output_str = output_str ..  "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)

    local SplittedLines = {}
    for k, v in ipairs(output) do
        --DebugError("k = " .. tostring(k) .. "/" .. tostring(#output) .. " ,v = _" .. v .. "_ ,#v = " .. tostring(#v) )
        local startindex = 1
        local foundIndex = string.find( v, "\n", startindex )
        local sub = string.sub( v, startindex, foundIndex and foundIndex -1 or string.len(v) )
        --DebugError("startindex = " .. tostring(startindex) .. " ,foundIndex = " ..  tostring(foundIndex) .. " ,sub =_" .. tostring(sub) .. "_")
        if sub ~= "" then
            table.insert(SplittedLines, sub)
        end
        while foundIndex do
            startindex = foundIndex + 1 
            foundIndex = string.find( v, "\n", startindex )
            sub = string.sub( v, startindex, foundIndex and foundIndex -1 or string.len(v) )
            if sub ~= "" then
                table.insert(SplittedLines, sub)
            end
            --DebugError("startindex = " .. tostring(startindex) .. " ,foundIndex = " ..  tostring(foundIndex) .. " ,sub =_" .. tostring(sub) .. "_" )
        end
        
    end

    output_str = table.concat(output)
    return output_str, SplittedLines
end


init()

