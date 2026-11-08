-- Workspaces globais 1–10 em round robin entre os monitores, da esquerda para
-- a direita. Com três monitores (notebook | DP-1 | DP-3):
--
--   notebook: 1 4 7 10   DP-1: 2 5 8   DP-3: 3 6 9
--
-- O Omarchy faz outra coisa: cada monitor tem um bloco próprio de 1–10
-- (default/hypr/monitor-workspaces.lua), e ele refaz isso a cada reload. Este
-- arquivo desliga esse comportamento: troca as funções de o.workspaces que os
-- atalhos e a barra usam, e grava todos os monitores no bloco 0 do arquivo de
-- estado, para a barra mostrar os workspaces 1–10 em todos os monitores.
--
-- Para voltar ao padrão do Omarchy: tire o require("hypr.workspaces") do
-- hyprland.lua e apague ~/.local/state/omarchy/monitor-workspaces.

local paths = require("default.hypr.paths")

local SLOTS = 10
local STATE_FILE = paths.state_home .. "/omarchy/monitor-workspaces"

-- Monitores reais, da esquerda para a direita (depois de cima para baixo).
local function ordered_monitors()
  local list = {}
  for _, monitor in ipairs(hl.get_monitors()) do
    if not monitor.is_mirror then
      list[#list + 1] = monitor
    end
  end
  table.sort(list, function(a, b)
    if a.x ~= b.x then return a.x < b.x end
    return a.y < b.y
  end)
  return list
end

-- Workspace -> monitor que é dono dele.
local function owner_of(id, monitors)
  if #monitors == 0 or id < 1 or id > SLOTS then return nil end
  return monitors[(id - 1) % #monitors + 1]
end

-- Workspaces (1–10) que pertencem a um monitor, em ordem.
local function owned_by(monitor, monitors)
  local ids = {}
  for id = 1, SLOTS do
    local owner = owner_of(id, monitors)
    if owner and owner.name == monitor.name then ids[#ids + 1] = id end
  end
  return ids
end

-- Regras: cada workspace abre no seu monitor; o primeiro de cada um é o padrão.
local function apply_rules(monitors)
  for id = 1, SLOTS do
    local owner = owner_of(id, monitors)
    if owner then
      hl.workspace_rule({ workspace = tostring(id), monitor = owner.name, default = id <= #monitors })
    end
  end
end

-- A barra do Omarchy lê este arquivo para saber o bloco de cada monitor.
-- Todos no bloco 0: cada barra mostra os workspaces 1–10.
local function write_state(monitors)
  local lines = {}
  for _, monitor in ipairs(monitors) do
    local identity = (monitor.description ~= nil and monitor.description ~= "") and monitor.description or monitor.name
    lines[#lines + 1] = "0\t" .. monitor.name .. "\t" .. identity
  end
  local content = table.concat(lines, "\n") .. "\n"

  local current = io.open(STATE_FILE, "r")
  if current then
    local old = current:read("*a")
    current:close()
    if old == content then return end
  end

  local file = io.open(STATE_FILE, "w")
  if file then
    file:write(content)
    file:close()
  end
end

local function regular(workspace)
  return workspace and not workspace.special and workspace.id > 0
end

-- Põe cada workspace no seu monitor sem fazer as janelas pularem de tela: um
-- workspace com janelas no monitor errado ganha um número livre do monitor
-- onde está (vale para os 11–30 que o Omarchy criou). Depois, cada monitor
-- passa a mostrar um workspace dele.
local function reconcile()
  local monitors = ordered_monitors()
  if #monitors == 0 then return end

  write_state(monitors)

  for _, workspace in ipairs(hl.get_workspaces()) do
    if regular(workspace) and workspace.monitor and (workspace.windows or 0) > 0 then
      local owner = owner_of(workspace.id, monitors)
      if not owner or owner.name ~= workspace.monitor.name then
        local here = hl.get_monitor(workspace.monitor.name)
        local moved = false
        if here then
          for _, id in ipairs(owned_by(here, monitors)) do
            if not hl.get_workspace(id) then
              hl.dispatch(hl.dsp.workspace.change_id({ workspace = tostring(workspace.id), id = id }))
              moved = true
              break
            end
          end
        end
        if not moved and owner then
          hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(workspace.id), monitor = owner.name }))
        end
      end
    end
  end

  for _, monitor in ipairs(monitors) do
    local fresh = hl.get_monitor(monitor.name)
    local active = fresh and fresh.active_workspace
    local owner = active and regular(active) and owner_of(active.id, monitors)
    if fresh and not (owner and owner.name == fresh.name) then
      local target = owned_by(fresh, monitors)[1]
      for _, id in ipairs(owned_by(fresh, monitors)) do
        local ws = hl.get_workspace(id)
        if ws and ws.monitor and ws.monitor.name == fresh.name then
          target = id
          break
        end
      end
      if target then
        hl.dispatch(hl.dsp.focus({ monitor = fresh.name }))
        hl.dispatch(hl.dsp.focus({ workspace = tostring(target) }))
      end
    end
  end
end

apply_rules(ordered_monitors())

-- Troca as funções do Omarchy. Os eventos dele (reload, monitor ligado/
-- desligado) chamam o.workspaces.reconcile, que agora é o daqui. A barra chama
-- o.workspaces.focus(slot, monitor) ao clicar.
local W = o.workspaces

local function action(fn, expression)
  o.bind_expressions[fn] = expression
  return fn
end

W.reconcile = function() reconcile() end

W.workspace_id = function(_, slot) return slot end

W.focus = function(slot)
  return action(function()
    hl.dispatch(hl.dsp.focus({ workspace = tostring(slot) }))
  end, "o.workspaces.focus(" .. slot .. ")")
end

W.move_window = function(slot, follow)
  return action(function()
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(slot), follow = follow ~= false }))
  end, "o.workspaces.move_window(" .. slot .. (follow == false and ", false" or "") .. ")")
end

W.move_to_monitor = function(direction)
  return action(function()
    local target = hl.get_monitor(direction)
    if target then
      hl.dispatch(hl.dsp.workspace.move({ monitor = target.name }))
    end
  end, "o.workspaces.move_to_monitor(\"" .. direction .. "\")")
end

-- Os atalhos Super+1..0 foram criados com as funções antigas; refaz com as novas.
for slot = 1, SLOTS do
  local key = "code:" .. tostring(slot + 9)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. slot, W.focus(slot))
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. slot, W.move_window(slot))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. slot, W.move_window(slot, false))
end
for _, direction in ipairs({ "l", "r", "u", "d" }) do
  local names = { l = "LEFT", r = "RIGHT", u = "UP", d = "DOWN" }
  local words = { l = "left", r = "right", u = "up", d = "down" }
  o.rebind("SUPER + SHIFT + ALT + " .. names[direction], "Move workspace to " .. words[direction] .. " monitor", W.move_to_monitor(direction))
end
