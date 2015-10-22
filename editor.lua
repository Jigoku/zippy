--[[
 * Copyright (C) 2015 Ricky K. Thomson
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * u should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 --]]

--[[
	editor binds
	
	select/drag     : lmb
	delete entity   : rmb
	scroll entities : wu/wd
	
	select ent type	: 1-9
	move up			: numpad 8
	move down		: numpad 2
	move left		: numpad 4
	move right		: numpad 6
	theme palette   : t
	copy dimensions	: c
	paste			: p	
	delete entity	: del
	camera scale	: z
	camera position	: w,a,s,d
--]]




editor = {}
editing = false

mousePosX = 0
mousePosY = 0

editor.entdir = 0 			--(used for some entites 0,1,2,3 = up,down,right,left)
editor.entsel = 0			--current entity id for placement
editor.themesel = 0			--theme pallete in use
editor.showpos = true		--axis info for entitys
editor.showid  = true		--id info for entities
editor.drawsel = false		--selection outline
editor.drawminimap = true	--toggle minimap
editor.movespeed = 1000		--editing floatspeed
	
editor.clipboard = {}		--clipboard contents


function editor:entname(id)
	--list of entity id's (these can be reordered / renumbered
	--without any issues, as long as "entity.name" is specified
	if id == 0 then return "spawn" 
	elseif id == 1 then return "goal" 
	elseif id == 2 then return "platform" 
	elseif id == 3 then return "platform_b" 
	elseif id == 4 then return "platform_x" 
	elseif id == 5 then return "platform_y" 
	elseif id == 6 then return "checkpoint" 
	elseif id == 7 then return "crate" 
	elseif id == 8 then return "spike" 
	elseif id == 9 then return "walker" 
	elseif id ==10 then return "floater" 
	elseif id ==11 then return "gem" 
	elseif id ==12 then return "life" 
	elseif id ==13 then return "flower" 
	elseif id ==14 then return "rock" 
	elseif id ==15 then return "tree" 
	elseif id ==16 then return "spring_s" 
	elseif id ==17 then return "spring_m" 
	elseif id ==18 then return "spring_l" 
	else return editor.entsel
	end
end



function editor:themename(id)
	if id == 0 then return "jungle" 
	elseif id == 1 then return "winter" 
	elseif id == 2 then return "hell" 
	elseif id == 3 then return "mist" 
	elseif id == 4 then return "dust" 
	elseif id == 5 then return "forest" 
	end
end

function editor:settheme()
	world.theme = self:themename(self.themesel)
	world:settheme(world.theme)
	
	for i,e in ipairs(enemies) do 
		if e.name == "spike" then
			e.gfx = spike_gfx
		end
	end
	self.themesel = self.themesel +1
	if self.themesel > 5 then self.themesel = 0 end
	
end

function editor:keypressed(key)
	--print (key)
	if love.keyboard.isDown("kp+") then editor.entsel = editor.entsel +1 end
	if love.keyboard.isDown("kp-") then editor.entsel = editor.entsel -1 end
	
	if love.keyboard.isDown("delete") then self:removesel() end
	if love.keyboard.isDown("c") then self:copy() end
	if love.keyboard.isDown("v") then self:paste() end
	if love.keyboard.isDown("r") then self:rotate() end
	
	if love.keyboard.isDown("m") then self.drawminimap = not self.drawminimap end
	if love.keyboard.isDown(",") then self.showpos = not self.showpos end
	if love.keyboard.isDown(".") then self.showid = not self.showid end
	if love.keyboard.isDown("f12") then mapio:savemap(world.map) end
	
	if love.keyboard.isDown("t") then self:settheme() end
	
	if key == "kp8" or key == "kp2" or key == "kp4" or key == "kp6" then
	for i, platform in ripairs(platforms) do
		--fix this for moving platform (yorigin,xorigin etc)
		if world:inview(platform) then
			if collision:check(mousePosX,mousePosY,1,1, platform.x,platform.y,platform.w,platform.h) then
				if love.keyboard.isDown("kp8") then 
					platform.y = math.round(platform.y - 10,-1) --up
				end
				if love.keyboard.isDown("kp2") then 
					platform.y = math.round(platform.y + 10,-1) --down
					platform.yorigin = platform.y
				end 
				if love.keyboard.isDown("kp4") then 
					platform.x = math.round(platform.x - 10,-1) --left
					platform.xorigin = platform.x
				end 
				if love.keyboard.isDown("kp6") then 
					platform.x = math.round(platform.x + 10,-1)  --right
					platform.xorigin = platform.x
				end

				return true
			end
		end
	end
	end
end

function editor:checkkeys(dt)
		if love.keyboard.isDown("d") or love.keyboard.isDown("right")  then
			player.x = player.x + editor.movespeed *dt
		end
		if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
			player.x = player.x - editor.movespeed *dt
		end
		if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
			player.y = player.y - editor.movespeed *dt
		end
		if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
			player.y = player.y + editor.movespeed *dt
		end
end


function editor:mousepressed(x,y,button)
	
	local x = math.round(pressedPosX,-1)
	local y = math.round(pressedPosY,-1)
	
	-- entity selection with mousescroll
	if button == 'wu' then editor.entsel = editor.entsel +1 end
	if button == 'wd' then editor.entsel = editor.entsel -1 end
	
	if button == 'l' then
		local selection = self:entname(self.entsel)
		
		if selection == "spawn" then
			self:removeall(portals, "spawn")
			portals:add(x,y,"spawn")
		end
		if selection == "goal" then
			self:removeall(portals, "goal")
			portals:add(x,y,"goal")
		end
		
		if selection == "crate" then crates:add(x,y,"gem") end
		
		if selection == "walker" then
			enemies:walker(x,y,100,100) --movespeed,movedist should be configurable
		end
		if selection == "floater" then
			enemies:floater(x,y,100,400) --movespeed,movedist should be configurable
		end
		
		if selection == "checkpoint" then checkpoints:add(x,y) end
		if selection == "gem" then pickups:add(x,y,"gem") end
		if selection == "life" then pickups:add(x,y,"life") end
		if selection == "spike" then enemies:spike(x,y,editor.entdir) end
		if selection == "flower" then props:add(x,y,"flower") end
		if selection == "rock" then props:add(x,y,"rock") end
		if selection == "tree" then props:add(x,y,"tree") end
		if selection == "spring_s" then springs:add(x,y,editor.entdir,"spring_s") end
		if selection == "spring_m" then springs:add(x,y,editor.entdir,"spring_m") end
		if selection == "spring_l" then springs:add(x,y,editor.entdir,"spring_l") end
		
	elseif button == 'r' then
		editor:removesel()
	end
end

function editor:mousereleased(x,y,button)
	--check if we have selected platforms, then place if neccesary
	if button == 'l' then
		local selection = self:entname(self.entsel)
		if selection == "platform" or selection == "platform_b" or selection == "platform_x" or selection == "platform_y" then
			self:addplatform(pressedPosX,pressedPosY,releasedPosX,releasedPosY)
		end
		return
	end
end


function editor:addplatform(x1,y1,x2,y2)
	local ent = self:entname(self.entsel)

	--we must drag down and right
	if not (x2 < x1 or y2 < y1) then
		--min sizes (we don't want impossible to select/remove platforms)
		if x2-x1 < 20  then x2 = x1 +20 end
		if y2-y1 < 20  then y2 = y1 +20 end

		local x = math.round(x1,-1)
		local y = math.round(y1,-1)
		local w = (x2-x1)
		local h = (y2-y1)
		
		--place the platform
		if ent == "platform" then
			platforms:add(x,y,w,h,1,0,0,0,0)
		end
		
		if ent == "platform_b" then
			platforms:add(x,y,w,h,0,0,0,0,0)
		end
		if ent == "platform_x" then
			platforms:add(x,y,w,h,0, 1, 0, 100, 200)
		end
		if ent == "platform_y" then
			platforms:add(x,y,w,h,0, 0, 1, 100, 200)
		end

	end
end


function editor:crosshair()
	love.graphics.setColor(200,200,255,50)
	--vertical
	love.graphics.line(
		math.round(mousePosX,-1),
		math.round(mousePosY+love.graphics.getHeight()*camera.scaleY,-1),
		math.round(mousePosX,-1),
		math.round(mousePosY-love.graphics.getHeight()*camera.scaleY,-1)
	)
	--horizontal
	love.graphics.line(
		math.round(mousePosX-love.graphics.getWidth()*camera.scaleX,-1),
		math.round(mousePosY,-1),
		math.round(mousePosX+love.graphics.getWidth()*camera.scaleX-1),
		math.round(mousePosY,-1)
	)
	
	--cursor
	love.graphics.setColor(255,200,255,255)
	love.graphics.line(
		math.round(mousePosX,-1),
		math.round(mousePosY,-1),
		math.round(mousePosX,-1)+10,
		math.round(mousePosY,-1)
	)
	love.graphics.line(
		math.round(mousePosX,-1),
		math.round(mousePosY,-1),
		math.round(mousePosX,-1),
		math.round(mousePosY,-1)+10
	)
	
	cursor = { x =mousePosX, y =mousePosY   }
	util:drawCoordinates(cursor)
	
end


function editor:draw()
	camera:set()
	
	editor:crosshair()
	editor:drawselected()
	editor:drawselbox()
	
	camera:unset()
	
	if editor.drawminimap then
		editor:drawmmap()
	end
	
end

function editor:drawselbox()
	--draw an outline when dragging mouse
	if editor.drawsel then
		love.graphics.setColor(0,255,255,100)
		love.graphics.rectangle(
			"line", 
			pressedPosX,pressedPosY, 
			mousePosX-pressedPosX, mousePosY-pressedPosY
		)
	end
end

function editor:drawselected()
	return self:selection(enemies) or
			self:selection(pickups) or	
			self:selection(portals) or		
			self:selection(crates) or
			self:selection(checkpoints) or
			self:selection(springs) or
			self:selection(props) or
			self:selection(platforms)
end

function editor:selection(entities, x,y,w,h)
	-- hilights the entity when mouseover 
	love.graphics.setColor(0,255,0,200)
	for i, entity in ripairs(entities) do
		if world:inview(entity) then
			if entity.movex == 1 then
				if collision:check(mousePosX,mousePosY,1,1,entity.xorigin, entity.yorigin, entity.movedist+entity.w, entity.h) then
					love.graphics.rectangle("line", entity.xorigin, entity.yorigin, entity.movedist+entity.w, entity.h)
					return true
				end
			elseif entity.movey == 1 then
				if collision:check(mousePosX,mousePosY,1,1,entity.xorigin, entity.yorigin, entity.w, entity.h+entity.movedist) then
					love.graphics.rectangle("line", entity.xorigin, entity.yorigin,entity.w, entity.h+entity.movedist)
					return true
				end
			elseif collision:check(mousePosX,mousePosY,1,1,entity.x,entity.y,entity.w,entity.h) then
					love.graphics.rectangle("line", entity.x,entity.y,entity.w,entity.h)
					return true
				
			end
		end
	end
end

function editor:removesel()
	return self:remove(enemies) or
			self:remove(pickups) or	
			self:remove(portals) or		
			self:remove(crates) or
			self:remove(checkpoints) or
			self:remove(springs) or
			self:remove(props) or
			self:remove(platforms)
end

function editor:removeall(entities, name)
	--removes all entity types of given entity
	for i, entity in ipairs(entities) do
		if type(entity) == "table" and entity.name == name then

			table.remove(entities,i)
		end
	end
end

function editor:remove(entities, x,y,w,h)
	--deletes the selected entity
	
	for i, entity in ripairs(entities) do
		if world:inview(entity) then
			if entity.movex == 1 then
				if collision:check(mousePosX,mousePosY,1,1,entity.xorigin, entity.yorigin, entity.movedist+entity.w, entity.h) then
					table.remove(entities,i)
					print( entity.name .. " (" .. i .. ") removed" )
					return true
				end
			elseif entity.movey == 1 then
				if collision:check(mousePosX,mousePosY,1,1,entity.xorigin, entity.yorigin, entity.w, entity.h+entity.movedist) then
					print( entity.name .. " (" .. i .. ") removed" )
					table.remove(entities,i)
					return true
				end
			elseif collision:check(mousePosX,mousePosY,1,1, entity.x,entity.y,entity.w,entity.h) then
				print( entity.name .. " (" .. i .. ") removed" )
				table.remove(entities,i)
				return true
			
			end
		end
	end
end


function editor:rotate()
	--set rotation value for the entity
	--four directions, 0,1,2,3 at 90degree angles
	editor.entdir = editor.entdir +1
	if editor.entdir > 3 then
		editor.entdir = 0
	end
end

function editor:copy()
	--primitive copy (dimensions only for now)
	for i, platform in ripairs(platforms) do
		if world:inview(platform) then
			if collision:check(mousePosX,mousePosY,1,1, platform.x,platform.y,platform.w,platform.h) then
				self.clipboard = {
					w = platform.w,
					h = platform.h,
					e = editor.entsel,
				}
				return true
			end
		end
	end
end

function editor:paste()
	--paste the new entity with copied paramaters
	--
	local x = math.round(mousePosX,-1)
	local y = math.round(mousePosY,-1)
	local w = self.clipboard.w or 20
	local h = self.clipboard.h or 20
	local selection = editor:entname(self.entsel)
	if selection == "platform" then
		platforms:add(x,y,w,h,1,0,0,0,0)
	end
	if selection == "platform_b" then
		platforms:add(x,y,w,h,0,0,0,0,0)
	end
	if selection == "platform_x" then
		platforms:add(x,y,w,h,0, 1, 0, 100, 200)
	end
	if selection == "platform_y" then
		platforms:add(x,y,w,h,0,0, 1, 100, 200)
	end
end

function editor:run(dt)
	--reset some values we don't want to be updated
	player.xvel = 0
	player.yvel = 0
end


function editor:drawmmap()
	--experimental! does not work as intended!
	--fix camera scaling... and remove duplicate code
	editor.mmapw = love.window.getWidth()/5
	editor.mmaph = love.window.getHeight()/5
	editor.mmapscale = 15
	mmapcanvas = love.graphics.newCanvas( editor.mmapw, editor.mmaph )
	love.graphics.setCanvas(mmapcanvas)
	mmapcanvas:clear()


	love.graphics.setColor(0,0,0,100)
	love.graphics.rectangle("fill", 0,0,editor.mmapw,editor.mmaph )
	

	love.graphics.setColor(255,50,0,255)
	for i, platform in ipairs(platforms) do
		love.graphics.rectangle(
			"fill", 
			(platform.x/editor.mmapscale)-(camera.x/editor.mmapscale)+editor.mmapw/3, 
			(platform.y/editor.mmapscale)-(camera.y/editor.mmapscale)+editor.mmaph/3, 
			platform.w/editor.mmapscale, 
			platform.h/editor.mmapscale
		)
	end

	love.graphics.setColor(0,255,255,255)
	for i, crate in ipairs(crates) do
		love.graphics.rectangle(
			"fill", 
			(crate.x/editor.mmapscale)-camera.x/editor.mmapscale+editor.mmapw/3, 
			(crate.y/editor.mmapscale)-camera.y/editor.mmapscale+editor.mmaph/3, 
			crate.w/editor.mmapscale, 
			crate.h/editor.mmapscale
		)
	end
	
	love.graphics.setColor(255,0,255,255)
	for i, enemy in ipairs(enemies) do
		love.graphics.rectangle(
			"line", 
			(enemy.x/editor.mmapscale)-camera.x/editor.mmapscale+editor.mmapw/3, 
			(enemy.y/editor.mmapscale)-camera.y/editor.mmapscale+editor.mmaph/3, 
			enemy.w/editor.mmapscale, 
			enemy.h/editor.mmapscale
		)
	end
	
	love.graphics.setColor(255,255,100,255)
	for i, pickup in ipairs(pickups) do
		love.graphics.rectangle(
			"line", 
			(pickup.x/editor.mmapscale)-camera.x/editor.mmapscale+editor.mmapw/3, 
			(pickup.y/editor.mmapscale)-camera.y/editor.mmapscale+editor.mmaph/3, 
			pickup.w/editor.mmapscale, 
			pickup.h/editor.mmapscale
		)
	end
	
	love.graphics.setColor(0,255,0,255)
	for i, checkpoint in ipairs(checkpoints) do
		love.graphics.rectangle(
			"fill", 
			(checkpoint.x/editor.mmapscale)-camera.x/editor.mmapscale+editor.mmapw/3, 
			(checkpoint.y/editor.mmapscale)-camera.y/editor.mmapscale+editor.mmaph/3, 
			checkpoint.w/editor.mmapscale, 
			checkpoint.h/editor.mmapscale
		)
	end

	love.graphics.setColor(255,255,255,255)
	love.graphics.rectangle(
		"line", 
		(player.x/editor.mmapscale)-(camera.x/editor.mmapscale)+editor.mmapw/3, 
		(player.y/editor.mmapscale)-(camera.y/editor.mmapscale)+editor.mmaph/3, 
		player.w/editor.mmapscale, 
		player.h/editor.mmapscale
	)
	

	love.graphics.setCanvas()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(mmapcanvas, love.window.getWidth()-10-editor.mmapw,love.graphics.getHeight()-10-editor.mmaph )

end



