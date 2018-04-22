pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- ld41 - sheet music editor and shoot'em up
-- by mathias olsson for ludum dare 41

-- title / start screen
--[[
                                                          
888888888888  88  888888888888  88           88888888888  
     88       88       88       88           88           
     88       88       88       88           88           
     88       88       88       88           88aaaaa      
     88       88       88       88           88"""""      
     88       88       88       88           88           
     88       88       88       88           88           
     88       88       88       88888888888  88888888888  
                                                          
                                                          
--]]

function title_init()
 -- no music while testing
 music(8)
 scroll = {}
 scroll.y = 128
 scroll.end_y = 128
 scroll.vel_y = -0.5
 scroll.msg = {
  "i was expecting a quiet day in",
  "front of my sheet music editor.",
  "i was going to compose a suite",
  "in d-minor, the saddest of all",
  "keys. ",
  "the suite would have made both",
  "mozart and beethoven envious.",
  "",
  "all of a sudden evil aliens",
  "from the deepest part of space",
  "attacked and tried to destroy",
  "my creativity. there was",
  "nothing i could to do but",
  "defend myself and the world.",
  "",
  "sheet music editor shoot'em up", 
  "   a game for ludum dare 41",
  "      by mathias olsson",
  "",
  "controls:",
  "jump with ⬆️",
  "release with ⬇️",
  "go left with ⬅️",
  "go right with ➡️",
  "change note length with ❎",
  "fire with 🅾️",
  "",
  "press ❎ to start",
 }

end

function title_update()
 -- if users presses button_x, start game
 if btnp(5) then
  mode = 1
  game_init()
 end
 scroll.y += scroll.vel_y
 if scroll.end_y < 0 then
  scroll.y = 128
 end
end

function title_draw()
 cls(7)
 local y = scroll.y
 for msg in all(scroll.msg) do
  print(msg,4,y,13)
  y += 10
 end
 scroll.end_y = y
end

-- game
--[[
                                                                 
  ,ad8888ba,          db         88b           d88  88888888888  
 d8"'    `"8b        d88b        888b         d888  88           
d8'                 d8'`8b       88`8b       d8'88  88           
88                 d8'  `8b      88 `8b     d8' 88  88aaaaa      
88      88888     d8yaaaay8b     88  `8b   d8'  88  88"""""      
y8,        88    d8""""""""8b    88   `8b d8'   88  88           
 y8a.    .a88   d8'        `8b   88    `888'    88  88           
  `"y88888p"   d8'          `8b  88     `8'     88  88888888888  
                                                                 
                                                                 
--]]

function game_init()
 -- stop music
 music(-1)

 -- player
 init_player()

 -- lines
 y = 48
 lines = {}
 for i=1,5 do
  line1={}
  line1.y = y
  line1.spring_x = 64
  line1.spring_y = y
  line1.spring_vel_y = 0.0
  line1.spring_acc_y = 0.0
  line1.has_player = false
  add(lines,line1)

  y += 10
 end

 -- bullets
 bullets = {}

 -- enemies
 enemies = {}
 
 -- explosions
 explosions = {}

 -- spring constants
 k = 0.085
 d = 0.125

 -- gravity for player
 gravity = 0.6

 -- transparency
 palt(0,false)
 palt(7,true)

 -- fire
 fire = false

 -- go music
 music(0)

end

function init_player()
 player={}
 player.x = 64
 player.y = 0
 player.vel_y = 0.0
 player.vel_x = 0.0
 player.acc_y = 0.0
 player.acc_x = 0.0
 player.jumping = false
 player.note_length = 3
 player.line = 0
 player.anchor_x = 3
 player.anchor_y = 13
 player.radi = 3
 player.flip = false
 player.energy = 100
 player.dead = false
end

function spawn_enemy()
 enemy = {}
 enemy.x = 140
 enemy.y = rnd(128-16)
 enemy.vel_x = -(rnd(2)+1)
 enemy.vel_y = 0.0
 enemy.radi = 8
 enemy.anchor_x = 9
 enemy.anchor_y = 8
 enemy.energy = 4
 enemy.damage = 20
 add(enemies,enemy)
end

function spawn_explosion(x, y)
 explosion = {}
 explosion.particles = {}
 for i=1,40 do
  particle = {}
  particle.y = y
  particle.x = x
  particle.vel_x = rnd(6)-3
  particle.vel_y = rnd(6)-3
  particle.acc_x = 0
  particle.acc_y = 0
  add(explosion.particles, particle)
 end
 add(explosions, explosion)
 
 sfx(6,3)
end

function player_died()
 player.dead = true
 if player.line > 0 then
  lines[player.line].has_player = false
  player.line = 0
 end
 spawn_explosion(player.x,player.y)
end


function game_update()
 -- handle all inputs
 -- calculate all forces
 -- update all positions
 -- check if we are on a new line
 local force_y = 0
 force_y += gravity

 -- do not handle input if player is dead
 if not player.dead then
  -- btn 0,1 left and right
  if btn(0) then
    player.acc_x = -1.0
  elseif btn(1) then
    player.acc_x = 1.0
  else
    player.acc_x = 0.0
    player.vel_x = 0.0
  end

  -- btn 2 jump
  if btnp(2) then
    if not player.jumping then
    player.jumping = true
    if player.line > 0 then
      lines[player.line].has_player = false
      player.line = 0
    end
    force_y += -2.1*(4-player.note_length+1)
    end
  end

  -- btn 3 release
  if btn(3) then
    if player.line > 0 then
     lines[player.line].has_player = false
     player.line = 0
    end
  end

  -- btn 4 fire
  if btn(4) then
   if not fire then
    fire = true
    bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.vel_y = 0.0
    bullet.vel_x = 3.1
    bullet.sprite = 32+player.note_length
    -- todo store this in a table
    if player.note_length == 0 then
    bullet.radi = 2
    bullet.anchor_x = 3
    bullet.anchor_y = 1
    bullet.damage = 4
    elseif player.note_length == 1 then
    bullet.radi = 2
    bullet.anchor_x = 3
    bullet.anchor_y = 1
    bullet.damage = 3
    elseif player.note_length == 2 then
    bullet.radi = 2.5
    bullet.anchor_x = 1
    bullet.anchor_y = 2.5
    bullet.damage = 2
    else
    bullet.radi = 3.5
    bullet.anchor_x = 2
    bullet.anchor_y = 3
    bullet.damage = 1
    end
    add(bullets, bullet)
    sfx(7,3)
   end
  else
   fire = false
  end

  -- btn 5 note length
  if btnp(5) then
    player.note_length = (player.note_length + 1) % 4
  end
end -- if not player.dead
 
 -- do not update player position if player is dead
 if not player.dead then
  -- todo notes should weigh different things
  if player.line > 0 then
    diff = lines[player.line].y - player.y
    force_y += diff*k - player.vel_y*d
  end

  player.acc_y = force_y

  player.vel_x += player.acc_x
  player.vel_y += player.acc_y
  player.x = player.x + player.vel_x

  if player.x < 32 then
    player.x = 32
  end
  if player.x > 127-8 then
    player.x = 127-8
  end

  player.y = player.y + player.vel_y
  if player.y > 128+16 then
   -- player died
   player_died()
  end
 end -- if not player.dead

 for l in all(lines) do
  if l.has_player then
   l.spring_x = player.x
   l.spring_y = player.y
  else
   force_y = 0.0
--   force_y += 0.6 -- gravity
   
   diff = l.y - l.spring_y
   force_y += diff*k - l.spring_vel_y*d
   l.spring_acc_y = force_y
   l.spring_vel_y += l.spring_acc_y
   l.spring_y += l.spring_vel_y
  end
 end

 if not player.dead then
  -- if moving down, try to attach to line
  if player.vel_y > 0 and player.line == 0 then
    for key,value in pairs(lines) do
    if value.y-4 < player.y and value.y+4 > player.y then
      value.has_player = true
      player.line = key
      player.jumping = false
      sfx(5-key,3)
      break
    end
    end
  end

  -- check if above/below middle line
  if player.y >= lines[3].y then
    player.flip = false
    player.anchor_x = 3
    player.anchor_y = 13
  else
    player.flip = true
    player.anchor_x = 4
    player.anchor_y = 2
  end
 end -- if not player.dead

 -- move all bullets
 for bullet in all(bullets) do
    bullet.x += bullet.vel_x
    bullet.y += bullet.vel_y
    if bullet.x < 0-16 or bullet.x > 128+16 or bullet.y < 0-16 or bullet.y > 128.16 then
      del(bullets, bullet)
    end
 end

 -- move all enemies
 for enemy in all(enemies) do
    enemy.x += enemy.vel_x
    enemy.y += enemy.vel_y
    if enemy.x < 0-16 or enemy.x > 128+16 or enemy.y < 0-16 or enemy.y > 128.16 then
      del(enemies, enemy)
    end
 end

 if #enemies < 4 then
  spawn_enemy()
 end

 -- check if bullet hits enemies
 -- todo this is really slow
 for bullet in all(bullets) do
  for enemy in all(enemies) do
   dx = (bullet.x) - (enemy.x)
   dy = (bullet.y) - (enemy.y)
   distance_squared = dx*dx+dy*dy
   radi = bullet.radi+enemy.radi
   if distance_squared < radi*radi then
    -- collision
    enemy.energy -= bullet.damage
    if enemy.energy <= 0 then
     spawn_explosion(enemy.x,enemy.y)
     del(enemies, enemy)
    end

    del(bullets, bullet)
   end
  end -- for enemy
 end -- for bullet

 if not player.dead then
  -- check if enemy hits player
  for enemy in all(enemies) do
    dx = (player.x) - (enemy.x)
    dy = (player.y) - (enemy.y)
    distance_squared = dx*dx+dy*dy
    radi = player.radi+enemy.radi
    if distance_squared < radi*radi then
    -- collision
    player.energy -= enemy.damage
    if player.energy <= 0 then
      -- player died
      player_died()
    end

    spawn_explosion(enemy.x,enemy.y)
    del(enemies, enemy)
    end
  end
 end -- if not player.dead

 for explosion in all(explosions) do
  for particle in all(explosion.particles) do
   particle.vel_x += particle.acc_x
   particle.x += particle.vel_x   
   particle.acc_y += 0.02 -- gravity
   particle.vel_y += particle.acc_y
   particle.y += particle.vel_y

   if particle.y > 128 or particle.x < 0 or particle.y > 128 then
    del(explosion.particles, particle)
   end
  end -- for particle
  if #explosion.particles == 0 then
   del(explosions, explosion)
  end 
 end -- for explosion

 -- if player has died and all explosions are done
 if player.dead and #explosions == 0 then
  mode = 2
  game_over_init()
 end

end -- update

function game_draw()
 -- clear screen
 cls(7)
 map(0,0,0,0)

 -- draw lines
 for l in all(lines) do
  line(0,l.y,l.spring_x,l.spring_y,5)
  line(l.spring_x,l.spring_y,127,l.y,5)
 end
 
 -- draw treble clef
 sspr(0, 4*8, 2*8, 4*8, 2, 35, 32, 74)

 -- draw all bullets
 for bullet in all(bullets) do
  spr(bullet.sprite, bullet.x-bullet.anchor_x, bullet.y-bullet.anchor_y, 1, 1)
  --circ(bullet.x,bullet.y,bullet.radi,9)
 end

 -- draw all enemies
 for enemy in all(enemies) do
  spr(4, enemy.x-enemy.anchor_x, enemy.y-enemy.anchor_y, 2, 2)
  --circ(enemy.x,enemy.y,enemy.radi,9)
 end

 -- draw player
 if not player.dead then
  spr(player.note_length,player.x-player.anchor_x,player.y-player.anchor_y,1,2,player.flip,player.flip)
  --circ(player.x,player.y,player.radi,9)
 end

 colors = {8, 9, 10, 15, 14, 13} 
 for explosion in all(explosions) do
  for particle in all(explosion.particles) do
   pset(particle.x, particle.y, colors[flr(rnd(#colors))])
  end
 end
end

-- game over
--[[
                                                                                                                                
  ,ad8888ba,          db         88b           d88  88888888888        ,ad8888ba,    8b           d8  88888888888  88888888ba   
 d8"'    `"8b        d88b        888b         d888  88                d8"'    `"8b   `8b         d8'  88           88      "8b  
d8'                 d8'`8b       88`8b       d8'88  88               d8'        `8b   `8b       d8'   88           88      ,8p  
88                 d8'  `8b      88 `8b     d8' 88  88aaaaa          88          88    `8b     d8'    88aaaaa      88aaaaaa8p'  
88      88888     d8yaaaay8b     88  `8b   d8'  88  88"""""          88          88     `8b   d8'     88"""""      88""""88'    
y8,        88    d8""""""""8b    88   `8b d8'   88  88               y8,        ,8p      `8b d8'      88           88    `8b    
 y8a.    .a88   d8'        `8b   88    `888'    88  88                y8a.    .a8p        `888'       88           88     `8b   
  `"y88888p"   d8'          `8b  88     `8'     88  88888888888        `"y8888y"'          `8'        88888888888  88      `8b  
                                                                                                                                
                                                                                                                                
--]]

function game_over_init()
 i = 3
end

function game_over_update()
 if btnp(4) and btnp(5) then
  mode = 0
  title_init()
 end
end

function game_over_draw()
 cls(7)
 print("game over",0,40,0)
 print("press ❎ and 🅾️ to restart",0,80,0)
end

-- state machine

function _init()
 mode = 0
 title_init()
end

function _update()
 if mode == 0 then
  title_update()
 elseif mode == 1 then
  game_update()
 else
  game_over_update()
 end
end

function _draw()
 if mode == 0 then
  title_draw()
 elseif mode == 1 then
  game_draw()
 else
  game_over_draw()
 end
end


__gfx__
77777777777771777777717777777177777777777748555500000000000000000000000000000000000000000000000000000000000000006600000006677600
77777777777771777777717777777117777777777777755700000000000000000000000000000000000000000000000000000000000000007760000067777606
77777777777771777777717777777171777777777777557700000000000000000000000000000000000000000000000000000000000000007776000677777767
777777777777717777777177777771717777774855d5577700000000000000000000000000000000000000000000000000000000000000007776066777777777
77777777777771777777717777777171777777777655589a00000000000000000000000000000000000000000000000000000000000000007777677777777777
77777777777771777777717777777171777777775555889a00000000000000000000000000000000000000000000000000000000000000007777777777777777
77777777777771777777717777777177777555555225557700000000000000000000000000000000000000000000000000000000000000007777777777777777
777777777777717777777177777771775555555522d5555500000000000000000000000000000000000000000000000000000000000000007777777777777777
77777777777771777777717777777177777555555225557700000000000000000000000000000000000000000000000000000000000000007777777777777777
77777777777771777777717777777177777777775555889a00000000000000000000000000000000000000000000000000000000000000007777777777777777
77777777777771777777717777777177777777777655589a00000000000000000000000000000000000000000000000000000000000000007777777777777777
777777777777717777777177777771777777774855d5577700000000000000000000000000000000000000000000000000000000000000007777777777777777
77111777771111777711117777111177777777777777557700000000000000000000000000000000000000000000000000000000000000007777777777777677
71777177717771777111117771111177777777777777755700000000000000000000000000000000000000000000000000000000000000007776777777776067
71777177717717777111177771111777777777777748555500000000000000000000000000000000000000000000000000000000000000007760677667760067
77111777771177777711777777117777777777777777777700000000000000000000000000000000000000000000000000000000000000007760676006760677
11111177711117777717777771177777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71111777711117777117777711171177777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71111777111111771177777711771777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777177777771111777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777117777777717777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777771177777777117777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777177777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777177777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777770007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777700000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777700770777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777000770777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777007770777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777007700777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777007007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777007007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777000077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77770000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700007777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77000707777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007700007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70077000000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00770770770077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700770770077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700770770077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70770770070077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70070000770077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77007770700777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000007777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77077770077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007770077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000770077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70007770077777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70077770777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77000000777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0e0f0e0f0e0f0e0f0e0f0e0f0e0f0e0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
012000002875000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000002b75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000002f75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000003275000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000003575000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000007300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000336712d66126651206411b631136210d62105611000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003165029651236511e64118641146310f62108611026000160001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0733f515000003f5152f655000000c073000000c0733f5153f515000002f655000002f6553f0000c073000000c0733f5152f6553f515000003f5150c073000003f5150c0732f6550c0732f63533505
011000000014000131001210014004131041210411104140001400000000140000000414000000000000000000140001310012100140041310412104111041400014000000001400000004140000000414000000
0110000018350040001c3501c300243552434524335243252435524345243352432524355243452433524325183501c3001c3501c30018355183451833518325183551834518335183251c3551c3451c3351c325
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000003205000000390503605000000320500000000000370500000000000320502f0500000000000000003905000000000003b0503c0500000034050000002b050000002d050000002f050000002b05000000
011000000e050000000000000000150500000000000120501305000000170500000017050000001a0500e00015050170501805017050180501a0501005012050130501305013050130500e0500e0000b0000b050
0110000039050000000000000000320500000000000000003b0500000000000000003705000000000000000034050000000000000000390500000000000000003b05000000000000000037050000000000000000
0110000026255000002d2552a255000002625500000000002b255000000000026255232550000000000000002d25500000000002f255302550000028255000001f25500000212550000023255000001f25500000
011000000e050000001505012050000000e05000000000001305000000000000e0500b0500000000000000001505000000000001705018050000001005000000070500000009050000000b050000000705000000
01100000262550000000000000002d25500000000002a2552b255000002f255000002f25500000322550e0002125523255242552325524255262551c2551e2551f2551f2551f2551f2551a2550e0000b00017255
011000002d255000000000000000262550000000000000002f2550000000000000002b255000000000000000282550000000000000002d2550000000000000002f2550000000000000002b255000000000000000
__music__
01 08094344
00 08090a44
02 08090a44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 10424344
00 10114344
01 12111344
00 12141544
02 10111644

