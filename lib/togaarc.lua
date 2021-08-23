local togaarc = {
  old_arc = nil,
  old_osc_in = nil,
  cols = 4,
  rows = 64,
  old_buffer = nil,
  new_buffer = nil,
  encoder_pos = nil,
  dest = {},
  cleanup_done = false,
  key = nil, -- key event callback
  delta = nil -- delta event callback
}

function togaarc:connect()
    if _ENV.togaarc then return _ENV.togaarc end
    togaarc:init()
    _ENV.togaarc = togaarc
    return togaarc
end

function create_buffer(width,height)
  local new_buffer = {}

  for r = 1,width do
    new_buffer[r] = {}
    for c = 1,height do
      new_buffer[r][c] = 0
    end
  end

  return new_buffer
end

function togaarc:init()
  -- UNCOMMENT to add default touchosc client
  --table.insert(self.dest, {"192.168.0.123",8002})

  self.encoder_pos = {}
  for i = 1,self.cols do
    self.encoder_pos[i] = -1
  end

  self.old_buffer = create_buffer(self.cols, self.rows)
  self.new_buffer = create_buffer(self.cols, self.rows)
  self:hook_osc_in()
  self:refresh(true)

  self.old_arc = arc.connect()
  if self.old_arc then
    self.old_arc.key = function(x, s)
      if togaarc.key then
        togaarc.key(x, s)
      end
    end
    self.old_arc.delta = function(x, delta)
      if togaarc.delta then
        togaarc.delta(x, delta)
      end
    end
  end
  
  self:send_connected(nil, true)
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function togaarc:get_encoder_delta(i, pos)
  local delta = 0
  if self.encoder_pos[i] ~= -1 then
    delta = pos - self.encoder_pos[i]
    if delta > 0.5 then
      delta = 1 - delta
    elseif delta < -0.5 then
      delta = -1 - delta
    end
  end
  self.encoder_pos[i] = pos
  return delta
end

-- @static
function togaarc.osc_in(path, args, from)
  local consumed = false
  if not togaarc.cleanup_done then
    local x, y, z
    --print("togaarc_osc_in", dump(path), dump(args), dump(from))
    if string.starts(path, "/toga_connection") then
      print("togaarc connect!", togaarc.cleanup_done)
      local added = false
      for d, dest in pairs(togaarc.dest) do
        if dest[1] == from[1] and dest[2] == from[2] then
          added = true
        end
      end
      if not added then
        print("togaarc: add new toga client", from[1]..":"..from[2])
        table.insert(togaarc.dest, from)
        togaarc:refresh(true, from)
      end
      -- echo back anyway to update connection button value
      togaarc:send_connected(from, true)
      -- do not consume the event so togagrid can also add the new touchosc client.
    elseif string.starts(path, "/togaarc/knob") then
      path = string.sub(path, 14)
      x = tonumber(string.sub(path,1,1))
      if string.starts(string.sub(path,2), "/button1") then
        --print("togaarc button", x, args[1])
        if togaarc.key then
          togaarc.key(x, args[1])
        else
          print("arc.key is not defined!")
        end
      elseif string.starts(string.sub(path,2), "/encoder1") then
        local delta = togaarc:get_encoder_delta(x, args[1])
        --print("togaarc encoder", x, args[1], delta)
        delta = tonumber(string.format("%.0f", delta*500))
        if delta ~= 0 then
          if togaarc.delta then
            togaarc.delta(x, delta)
          else
            --print("arc.delta is not defined!")
          end
        end
      end
      consumed = true
    end
  end

  if not consumed then
    -- invoking original osc.event callback
    togaarc.old_osc_in(path, args, from)
  end
end

function togaarc:hook_osc_in()
  if self.old_osc_in ~= nil then return end
  --print("togaarc: hook old osc_in")
  self.old_osc_in = osc.event
  osc.event = togaarc.osc_in
end

-- @static
function togaarc.cleanup()
  togaarc.old_cleanup()
  if not togaarc.cleanup_done then
    togaarc:send_connected(nil, false)
    togaarc.cleanup_done = true
  end
end

function togaarc:hook_cleanup()
  if self.old_cleanup ~= nil then return end
  --print("togaarc: hook old cleaup")
  self.old_cleanup = grid.cleanup
  grid.cleanup = togaarc.cleanup
end

function togaarc:all(z)
  for c = 1,self.cols do
    for r = 1,self.rows do
      self.new_buffer[c][r] = z
    end
  end
  
  if self.old_arc then
    self.old_arc:all(z)
  end
end

function togaarc:segment(ring, from, to, level)
  -- from arc:segment()
  local tau = math.pi * 2

  local function overlap(a, b, c, d)
    if a > b then
      return overlap(a, tau, c, d) + overlap(0, b, c, d)
    elseif c > d then
      return overlap(a, b, c, tau) + overlap(a, b, 0, d)
    else
      return math.max(0, math.min(b, d) - math.max(a, c))
    end
  end

  local function overlap_segments(a, b, c, d)
    a = a % tau
    b = b % tau
    c = c % tau
    d = d % tau

    return overlap(a, b, c, d)
  end

  local m = {}
  local sl = tau / 64

  for i=1, 64 do
    local sa = tau / 64 * (i - 1)
    local sb = tau / 64 * i

    local o = overlap_segments(from, to, sa, sb)
    m[i] = util.round(o / sl * level)
    self:led(ring, i, m[i])
  end
  
  -- we call old_arc:led() in togaarc:led() so no need to call old_arc:segment() here
end

function togaarc:led(x, y, z)
  if x > self.cols or y > self.rows then return end
  self.new_buffer[x][y] = z
  
  if self.old_arc then
    self.old_arc:led(x, y, z)
  end
end

function togaarc:refresh(force_refresh, target_dest)
  for c = 1,self.cols do
    for r = 1,self.rows do
      if force_refresh or self.new_buffer[c][r] ~= self.old_buffer[c][r] then
        self.old_buffer[c][r] = self.new_buffer[c][r]
        self:update_led(c, r, target_dest)
      end
    end
  end
  
  if self.old_arc then
    self.old_arc:refresh()
  end
end

function togaarc:cleanup()
  if self.old_arc then
    self.old_arc:cleanup()
  end
  self.cleanup_done = true
end

function togaarc:update_led(c, r, target_dest)
  local z = self.new_buffer[c][r]
  for g = 1,2 do
    local addr = string.format("/togaarc/knob%d/group%d/button%d", c, g, r)
    --print("togaarc osc.send", addr, z)
    for d, dest in pairs(self.dest) do
      if target_dest and (target_dest[1] ~= dest[1] or target_dest[2] ~= dest[2]) then
        -- do nothing
      else
        osc.send(dest, addr, {z / 15.0})
      end
    end
  end
end

function togaarc:send_connected(target_dest, connected)
  for d, dest in pairs(self.dest) do
    if target_dest and (target_dest[1] ~= dest[1] or target_dest[2] ~= dest[2]) then
      -- do nothing
    else
      osc.send(dest, "/toga_connection", {connected and 1.0 or 0.0})
    end
  end
end

return togaarc