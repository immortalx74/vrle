UI = require "ui/ui"

local state = "load_create"
local level = { w = 15, d = 250, h = 25, scroll = { x = 0, y = 0, z = 0 }, name = "Level1" }
local boxes = { names = {}, data = {} }
local pass_m = lovr.math.newMat4()
local cur_box_idx = 1
local level_list_idx = 1
local level_list = {}
local editing_plane = "XY"
local tool_window_m = lovr.math.newMat4( 0, 1.4, -1 )
local tab_bar_idx = 2
local save_window_open = false
local confirm_overwrite_window_open = false
local do_overwrite = false
local ref = { m = lovr.math.newMat4(), model = nil, show = true }

local function split( str, delimiter )
	local result = {}
	for part in str:gmatch( "[^" .. delimiter .. "]+" ) do
		result[ #result + 1 ] = part
	end
	return result
end

local function LoadLevel()
	local read_level_info = false
	local file = io.open( "levels/" .. level_list[ level_list_idx ], "r" )
	for line in file:lines() do
		local col = split( line, "," )
		if not read_level_info then
			read_level_info = true
			level = { w = tonumber( col[ 1 ] ), d = tonumber( col[ 2 ] ), h = tonumber( col[ 3 ] ),
				scroll = { x = tonumber( col[ 4 ] ), y = tonumber( col[ 5 ] ), z = tonumber( col[ 6 ] ) }, name = col[ 7 ] }
		else
			local b = { minx = col[ 1 ], maxx = col[ 2 ], miny = col[ 3 ], maxy = col[ 4 ], minz = col[ 5 ], maxz = col[ 6 ] }
			boxes.data[ #boxes.data + 1 ] = b
			boxes.names[ #boxes.names + 1 ] = tostring( #boxes.names + 1 )
		end
	end
	file:close()

	for i, v in ipairs( boxes.data ) do
		v.maxx = v.maxx + level.scroll.x
		v.minx = v.minx + level.scroll.x
		v.maxy = v.maxy + level.scroll.y
		v.miny = v.miny + level.scroll.y
		v.maxz = v.maxz + level.scroll.z
		v.minz = v.minz + level.scroll.z
	end
end

local function SaveLevel()
	local file = io.open( "levels/" .. level.name .. ".txt", "w" )
	file:write( level.w, ",", level.d, ",", level.h, ",", level.scroll.x, ",", level.scroll.y, ",", level.scroll.z, ",", level.name, "\n" )
	for i, v in ipairs( boxes.data ) do
		file:write( v.minx - level.scroll.x, ",", v.maxx - level.scroll.x, ",", v.miny - level.scroll.y, ",", v.maxy - level.scroll.y, ",", v.minz - level.scroll.z,
			",", v.maxz - level.scroll.z, "\n" )
	end
	file:close()
	print( "saved" )
end

local function Clamp( n, n_min, n_max )
	if n < n_min then n = n_min
	elseif n > n_max then n = n_max
	end

	return n
end

local function MoveLeft()
	boxes.data[ cur_box_idx ].maxx = boxes.data[ cur_box_idx ].maxx - 0.1
	boxes.data[ cur_box_idx ].minx = boxes.data[ cur_box_idx ].minx - 0.1
end

local function MoveRight()
	boxes.data[ cur_box_idx ].maxx = boxes.data[ cur_box_idx ].maxx + 0.1
	boxes.data[ cur_box_idx ].minx = boxes.data[ cur_box_idx ].minx + 0.1
end

local function MoveUp()
	boxes.data[ cur_box_idx ].maxy = boxes.data[ cur_box_idx ].maxy + 0.1
	boxes.data[ cur_box_idx ].miny = boxes.data[ cur_box_idx ].miny + 0.1
end

local function MoveDown()
	boxes.data[ cur_box_idx ].maxy = boxes.data[ cur_box_idx ].maxy - 0.1
	boxes.data[ cur_box_idx ].miny = boxes.data[ cur_box_idx ].miny - 0.1
end

local function MoveForward()
	boxes.data[ cur_box_idx ].maxz = boxes.data[ cur_box_idx ].maxz - 0.1
	boxes.data[ cur_box_idx ].minz = boxes.data[ cur_box_idx ].minz - 0.1
end

local function MoveBackwards()
	boxes.data[ cur_box_idx ].maxz = boxes.data[ cur_box_idx ].maxz + 0.1
	boxes.data[ cur_box_idx ].minz = boxes.data[ cur_box_idx ].minz + 0.1
end

local function GrowX()
	boxes.data[ cur_box_idx ].maxx = boxes.data[ cur_box_idx ].maxx + 0.1
end

local function ShrinkX()
	boxes.data[ cur_box_idx ].maxx = Clamp( boxes.data[ cur_box_idx ].maxx - 0.1, boxes.data[ cur_box_idx ].minx + 0.1, math.huge )
end

local function GrowY()
	boxes.data[ cur_box_idx ].maxy = boxes.data[ cur_box_idx ].maxy + 0.1
end

local function ShrinkY()
	boxes.data[ cur_box_idx ].maxy = Clamp( boxes.data[ cur_box_idx ].maxy - 0.1, boxes.data[ cur_box_idx ].miny + 0.1, math.huge )
end

local function GrowZ()
	boxes.data[ cur_box_idx ].maxz = boxes.data[ cur_box_idx ].maxz + 0.1
end

local function ShrinkZ()
	boxes.data[ cur_box_idx ].maxz = Clamp( boxes.data[ cur_box_idx ].maxz - 0.1, boxes.data[ cur_box_idx ].minz + 0.1, math.huge )
end

function lovr.load()
	UI.Init()
	lovr.graphics.setBackgroundColor( 0.4, 0.4, 1 )
	local vs = lovr.filesystem.read( "phong.vs" )
	local fs = lovr.filesystem.read( "phong.fs" )
	phong_shader = lovr.graphics.newShader( vs, fs )

	level_list = lovr.filesystem.getDirectoryItems( "levels" )
end

function lovr.update( dt )
	UI.InputInfo()
end

function lovr.draw( pass )
	pass:setShader()
	UI.NewFrame( pass )

	if state == "load_create" then
		level.scroll.z = -level.d / 2

		UI.Begin( "load_create_win", mat4( 0, 1.4, -1 ) )
		local was_clicked, idx = UI.TabBar( "tabbar", { "Load", "New" }, tab_bar_idx )
		if was_clicked then
			tab_bar_idx = idx
		end

		if tab_bar_idx == 1 then
			local _
			_, level_list_idx = UI.ListBox( "levels_lb", 8, 28, level_list )
			if UI.Button( "Open" ) then
				LoadLevel()
				state = "create_box"
			end
		end
		if tab_bar_idx == 2 then
			local _
			_, level.w = UI.SliderInt( "Level width", level.w, 10, 50, 556 )
			_, level.d = UI.SliderInt( "Level depth", level.d, 50, 600, 556 )
			_, level.h = UI.SliderInt( "Level height", level.h, 3, 70, 556 )
			local got_focus, buffer_changed, textbox_id
			got_focus, buffer_changed, textbox_id, level.name = UI.TextBox( "Level name", 16, level.name )
			if UI.Button( "Create" ) then
				local b = { minx = -0.5, maxx = 0.5, miny = 0, maxy = 1, minz = -2.5, maxz = -1.5 }
				boxes.data[ #boxes.data + 1 ] = b
				boxes.names[ #boxes.names + 1 ] = tostring( #boxes.names + 1 )
				state = "create_box"
			end
		end
		UI.End( pass )
	end

	if state == "create_box" then
		UI.Begin( "create_box_win", tool_window_m )
		UI.Label( "Boxes", true )
		UI.Label( "Editing plane: " .. editing_plane )

		-- Toggle editing plane
		if lovr.headset.wasPressed( "hand/right", "a" ) then
			if editing_plane == "XY" then
				editing_plane = "XZ"
			else
				editing_plane = "XY"
			end
		end

		-- Box size
		local rx, ry = lovr.headset.getAxis( "hand/right", "thumbstick" )
		local lx, ly = lovr.headset.getAxis( "hand/left", "thumbstick" )

		if rx > 0.7 and lovr.headset.isDown( "hand/right", "grip" ) then -- grow x
			GrowX()
		end
		if rx < -0.7 and lovr.headset.isDown( "hand/right", "grip" ) then -- shrink x
			ShrinkX()
		end
		if ry > 0.7 and lovr.headset.isDown( "hand/right", "grip" ) then -- grow y or z
			if editing_plane == "XY" then
				GrowY()
			else
				GrowZ()
			end
		end
		if ry < -0.7 and lovr.headset.isDown( "hand/right", "grip" ) then -- shrink y or z
			if editing_plane == "XY" then
				ShrinkY()
			else
				ShrinkZ()
			end
		end

		-- Box move
		if rx > 0.7 and not lovr.headset.isDown( "hand/right", "grip" ) then -- move box right
			MoveRight()
		end

		if rx < -0.7 and not lovr.headset.isDown( "hand/right", "grip" ) then -- move box left
			MoveLeft()
		end

		if ry > 0.7 and not lovr.headset.isDown( "hand/right", "grip" ) then -- move box up or forward
			if editing_plane == "XY" then
				MoveUp()
			else
				MoveForward()
			end
		end

		if ry < -0.7 and not lovr.headset.isDown( "hand/right", "grip" ) then -- move box down or backwards
			if editing_plane == "XY" then
				MoveDown()
			else
				MoveBackwards()
			end
		end

		-- Move world
		if lx > 0.7 and not lovr.headset.isDown( "hand/left", "grip" ) then -- move right
			level.scroll.x = level.scroll.x - 0.1
			for i, v in ipairs( boxes.data ) do
				v.minx = v.minx - 0.1
				v.maxx = v.maxx - 0.1
			end
		end

		if lx < -0.7 and not lovr.headset.isDown( "hand/left", "grip" ) then -- move left
			level.scroll.x = level.scroll.x + 0.1
			for i, v in ipairs( boxes.data ) do
				v.minx = v.minx + 0.1
				v.maxx = v.maxx + 0.1
			end
		end

		if ly > 0.7 and not lovr.headset.isDown( "hand/left", "grip" ) then -- move forward or up
			if editing_plane == "XY" then
				level.scroll.y = level.scroll.y - 0.1
				for i, v in ipairs( boxes.data ) do
					v.miny = v.miny - 0.1
					v.maxy = v.maxy - 0.1
				end
			else
				level.scroll.z = level.scroll.z + 0.1
				for i, v in ipairs( boxes.data ) do
					v.minz = v.minz + 0.1
					v.maxz = v.maxz + 0.1
				end
			end
		end

		if ly < -0.7 and not lovr.headset.isDown( "hand/left", "grip" ) then -- move backwards or down
			if editing_plane == "XY" then
				level.scroll.y = level.scroll.y + 0.1
				for i, v in ipairs( boxes.data ) do
					v.maxy = v.maxy + 0.1
					v.miny = v.miny + 0.1
				end
			else
				level.scroll.z = level.scroll.z - 0.1
				for i, v in ipairs( boxes.data ) do
					v.minz = v.minz - 0.1
					v.maxz = v.maxz - 0.1
				end
			end
		end


		local _
		_, cur_box_idx = UI.ListBox( "boxes_lb", 14, 5, boxes.names )
		UI.SameLine()
		if UI.Button( "Add", 476 ) then
			-- local b = { minx = -0.5, maxx = 0.5, miny = (level.h / 2) - 0.5, maxy = (level.h / 2) + 0.5, minz = -2.5, maxz = -1.5 }
			local b = { minx = -0.5, maxx = 0.5, miny = 0, maxy = 1, minz = -2.5, maxz = -1.5 }
			boxes.data[ #boxes.data + 1 ] = b
			boxes.names[ #boxes.names + 1 ] = tostring( #boxes.names + 1 )
		end
		UI.SameColumn()
		if UI.Button( "Delete", 476 ) then
		end

		UI.SameColumn()
		if UI.Button( "Save...", 476 ) then
			save_window_open = true
		end

		UI.SameColumn()
		if UI.Button( "Load ref model", 476 ) then
			ref.model = lovr.graphics.newModel( "levels/" .. level.name .. ".glb" )
		end

		UI.SameColumn()
		if UI.CheckBox( "Show ref model", ref.show ) then
			ref.show = not ref.show
		end

		if UI.Button( "Left", 300 ) then
			MoveLeft()
		end
		UI.SameLine()
		if UI.Button( "Right", 300 ) then
			MoveRight()
		end

		if UI.Button( "Up", 300 ) then
			MoveUp()
		end
		UI.SameLine()
		if UI.Button( "Down", 300 ) then
			MoveDown()
		end

		if UI.Button( "Forward", 300 ) then
			MoveForward()
		end
		UI.SameLine()
		if UI.Button( "Backwards", 300 ) then
			MoveBackwards()
		end

		UI.Dummy( 5, 20 )

		if UI.Button( "+X", 300 ) then
			GrowX()
		end
		UI.SameLine()
		if UI.Button( "-X", 300 ) then
			ShrinkX()
		end

		if UI.Button( "+Y", 300 ) then
			GrowY()
		end
		UI.SameLine()
		if UI.Button( "-Y", 300 ) then
			ShrinkY()
		end

		if UI.Button( "+Z", 300 ) then
			GrowZ()
		end
		UI.SameLine()
		if UI.Button( "-Z", 300 ) then
			ShrinkZ()
		end

		UI.End( pass )

		if save_window_open then
			local m = mat4( tool_window_m )
			m:translate( 0, 0, 0.01 )
			UI.Begin( "save_level_window", m, true )
			UI.Label( "Save level" )
			if UI.Button( "OK" ) then
				-- Check if filename exists
				for i, v in ipairs( level_list ) do
					if v == level.name .. ".txt" and not do_overwrite then
						confirm_overwrite_window_open = true
						save_window_open = false
						UI.EndModalWindow()
						return false
					else
						SaveLevel()
					end
				end

				save_window_open = false
				UI.EndModalWindow()
			end
			UI.SameLine()
			if UI.Button( "Cancel" ) then
				save_window_open = false
				UI.EndModalWindow()
			end
			UI.End( pass )
		end

		if confirm_overwrite_window_open then
			local m = mat4( tool_window_m )
			m:translate( 0, 0, 0.01 )
			UI.Begin( "overwrite_window", m, true )
			UI.Label( "Filename already exists.\nOverwrite?" )

			if UI.Button( "OK" ) then
				SaveLevel()
				confirm_overwrite_window_open = false
				UI.EndModalWindow()
			end
			UI.SameLine()
			if UI.Button( "Cancel" ) then
				confirm_overwrite_window_open = false
				UI.EndModalWindow()
			end
			UI.End( pass )
		end
	end

	pass:setShader( phong_shader )
	pass:send( 'lightColor', { 1.0, 1.0, 1.0, 1.0 } )
	pass:send( 'lightPos', { 2.0, 5.0, 0.0 } )
	pass:send( 'ambience', { 0.2, 0.2, 0.2, 1.0 } )
	pass:send( 'specularStrength', 0.8 )
	pass:send( 'metallic', 32.0 )

	-- Draw level
	pass:setColor( 0.3, 0.3, 0.3 )
	-- pass:plane( vec3( level.scroll.x, level.scroll.y + 0.0001, level.scroll.z ), vec3( level.w, level.d ), quat( math.pi / 2, 1, 0, 0 ) )
	pass:setColor( 0.6, 0.6, 0.6 )
	pass:plane( vec3( level.scroll.x, level.scroll.y, level.scroll.z ), vec3( level.w, level.d ), quat( math.pi / 2, 1, 0, 0 ), "line", level.w, level.d )
	pass:setColor( 0.3, 0.3, 0.3 )
	pass:plane( vec3( level.scroll.x, level.scroll.y + level.h, level.scroll.z ), vec3( level.w, level.d ), quat( math.pi / 2, 1, 0, 0 ), "line", level.w, level.d )
	pass:setColor( 0, 0, 0 )

	-- Draw ref
	if ref.model and ref.show then
		pass:setColor( 1, 1, 1 )
		pass:draw( ref.model, mat4( vec3( level.scroll.x, level.scroll.y, level.scroll.z ) ) )
	end

	-- Draw boxes
	for i, v in ipairs( boxes.data ) do
		pass:setColor( 0.6, 0.6, 0.6 )
		if i == cur_box_idx then
			pass:setColor( 1, 0, 0 )
		end

		pass:box( vec3( (v.minx + v.maxx) / 2, (v.miny + v.maxy) / 2, (v.minz + v.maxz) / 2 ), vec3( v.maxx - v.minx, v.maxy - v.miny, v.maxz - v.minz ) )
		pass:setColor( 0, 0, 0 )
		pass:box( vec3( (v.minx + v.maxx) / 2, (v.miny + v.maxy) / 2, (v.minz + v.maxz) / 2 ), vec3( v.maxx - v.minx, v.maxy - v.miny, v.maxz - v.minz ), quat(),
			"line" )
	end

	local ui_passes = UI.RenderFrame( pass )
	table.insert( ui_passes, pass )
	return lovr.graphics.submit( ui_passes )
end
