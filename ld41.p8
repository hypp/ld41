pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()
 player={}
 player.x = 64
 player.y = 64
 player.vel_y = 0.0
 player.vel_x = 0.0
 player.acc_y = 0.0
 player.acc_x = 0.0
 player.jumping = false
end

function _update()
 if btn(0) then
  player.acc_x = -1.0
 elseif btn(1) then
  player.acc_x = 1.0
 else
  player.acc_x = 0.0
  player.vel_x = 0.0
 end
 if player.jumping then
  player.acc_y += 0.1
 elseif btn(4) then
  player.jumping = true
  player.acc_y = -1.0
 end
 
 player.vel_x += player.acc_x
 player.vel_y += player.acc_y
 player.x = (player.x + player.vel_x) % 128
 player.y = player.y + player.vel_y
 
 if player.y > 100 then
  player.jumping = false
  player.acc_y = 0.0
  player.vel_y = 0.0
 end
 
end

function _draw()
 cls(7)
 spr(0,player.x,player.y,1,2,true,true)

end
__gfx__
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77711117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77111177000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77711777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
