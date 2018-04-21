pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- ld41 - sheet music editor and shoot'em up
-- by mathias olsson for ludum dare 41


function _init()
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

 -- no music while testing
 --music()
 
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
end

function _update()
 -- handle all inputs
 -- calculate all forces
 -- update all positions
 -- check if we are on a new line
 local force_y = 0
 force_y += gravity

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
 if btnp(4) then
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

 -- btn 5 note length
 if btnp(5) then
  player.note_length = (player.note_length + 1) % 4
 end
 
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
  init_player()
 end


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
 -- todo fix so we use objects center instead of upperleft corner
 for bullet in all(bullets) do
  for enemy in all(enemies) do
   dx = (bullet.x+bullet.anchor_x) - (enemy.x+enemy.anchor_x)
   dy = (bullet.y+bullet.anchor_y) - (enemy.y+enemy.anchor_y)
   distance_squared = dx*dx+dy*dy
   radi = bullet.radi+enemy.radi
   if distance_squared < radi*radi then
    -- collision
    spawn_explosion(enemy.x+enemy.anchor_x,enemy.y+enemy.anchor_y)
    
    del(bullets, bullet)
    del(enemies, enemy)
    sfx(6,3)
   end
  end -- for enemy
 end -- for bullet

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

end -- update

function _draw()
 -- clear screen
 cls(7)

 -- draw lines
 for l in all(lines) do
  line(0,l.y,l.spring_x,l.spring_y,5)
  line(l.spring_x,l.spring_y,127,l.y,5)
 end
 
 -- draw treble clef
 sspr(0, 4*8, 2*8, 4*8, 2, 35, 32, 74)

 -- draw all bullets
 for bullet in all(bullets) do
  spr(bullet.sprite, bullet.x, bullet.y, 1, 1)
  circ(bullet.x+bullet.anchor_x,bullet.y+bullet.anchor_y,bullet.radi,9)
 end

 -- draw all enemies
 for enemy in all(enemies) do
  spr(4, enemy.x, enemy.y, 2, 2)
  circ(enemy.x+enemy.anchor_x,enemy.y+enemy.anchor_y,enemy.radi,9)
 end

 -- draw player
 -- line 3 is where we flip between up or down stem
 if player.y >= lines[3].y then
  spr(player.note_length,player.x+1,player.y-14,1,2)
 else
  spr(player.note_length,player.x,player.y-2,1,2,true,true)
 end
  
 for explosion in all(explosions) do
  for particle in all(explosion.particles) do
   pset(particle.x, particle.y, 8)
  end
 end
end

__gfx__
77777777777771777777717777777177777777777748555500000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777117777777777777755700000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777171777777777777557700000000000000000000000000000000000000000000000000000000000000000000000000000000
777777777777717777777177777771717777774855d5577700000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777171777777777655589a00000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777171777777775555889a00000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777177777555555225557700000000000000000000000000000000000000000000000000000000000000000000000000000000
777777777777717777777177777771775555555522d5555500000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777177777555555225557700000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777177777777775555889a00000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777771777777717777777177777777777655589a00000000000000000000000000000000000000000000000000000000000000000000000000000000
777777777777717777777177777771777777774855d5577700000000000000000000000000000000000000000000000000000000000000000000000000000000
77111777771111777711117777111177777777777777557700000000000000000000000000000000000000000000000000000000000000000000000000000000
71777177717771777111117771111177777777777777755700000000000000000000000000000000000000000000000000000000000000000000000000000000
71777177717717777111177771111777777777777748555500000000000000000000000000000000000000000000000000000000000000000000000000000000
77111777771177777711777777117777777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
11111177711117777717777771177777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71111777711117777117777711171177000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71111777111111771177777711771777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777177777771111777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777117777777717777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777771177777777117777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777177777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777177777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__sfx__
012000001075000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001375000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001a75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001d75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000007300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000336712d66126651206411b631136210d62105611000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200003165029651236511e64118641146310f62108611026000160001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0733f515000003f5152f655000000c073000000c0733f5153f515000002f655000002f6553f0000c073000000c0733f5152f6553f515000003f5150c073000003f5150c0732f6550c0732f63533505
011000000014000131001210014004131041210411104140001400000000140000000414000000000000000000140001310012100140041310412104111041400014000000001400000004140000000414000000
0110000018350040001c3501c300243552434524335243252435524345243352432524355243452433524325183501c3001c3501c30018355183451833518325183551834518335183251c3551c3451c3351c325
__music__
01 08094344
00 08090a44
02 08090a44

