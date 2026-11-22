--[[
guided-exercise.lua: the guided mode of an exercise (decision 0026; proposal PR9's pilot).

Master copy: _design/assets/guided-exercise.lua, with guided-exercise.js and guided-exercise.css
beside it (see _design/quarto_style_default.md §1). /course-init copies all three to
<COURSE>/course/assets/ and _quarto.yml lists the filter under `filters:`. Edit the master copies
and re-copy; never edit a course's copy alone.

Source (the exercise template documents it for authors; _tools/step_check.py checks it, S8-S9):

  ::: {.guiado}
  Escribe el ángulo, en grados: [$\theta \approx 81.9^\circ$]{.casilla}     <- "Intentar": the
                                                                                 final answer
  ::: {.paso}
  $\mathbf{u} \cdot \mathbf{v} =$ [$1$]{.casilla}                            <- one step, one or
  :::                                                                            more slots
  ::: {.paso}
  El ángulo es

  - [agudo]{.correcta}                                                         <- or one choice
  - recto                                                                         list: one option
                                                                                   marked correct;
    El producto punto vale $1$, no $0$.                                        <- a wrong option's
  :::                                                                              feedback
  :::

  - A slot is a Math inline in a `.casilla` span. Its reference is the last plain number in the
    math: `[$1$]` is exact; `[$\sqrt{5} \approx 2.236$]` is rounded, and a student's answer must
    agree with it to the decimals either side shows; `^\circ` after the number puts a degree
    sign after the box. `decimales="n"` sets how many decimals the student must type (default:
    those the reference shows; 0 for an exact one). After two wrong tries in a step, the slot's
    math is shown.
  - Blocks before the first `.paso` are the final-answer part ("Intentar"). A wrong final answer
    offers the steps; a "Paso a paso" button opens them at any time. With no final-answer part
    (a proof whose steps are justification choices), the steps start open.
  - The solution stays the `::: {.solucion}` block after the guided block (exercise-blocks.lua).

Everything is built here, at render time, so the math is real KaTeX typeset with the page;
guided-exercise.js only opens steps, checks answers and gives feedback. Without JavaScript the
final-answer part and the solution still show. The script and style are inlined only on pages
that use the block.
]]

local lang = "es"

local WORDS = {
  es = { title = "Inténtalo", check = "Comprobar", steps = "Paso a paso", answer = "Respuesta",
         step = "Paso" },
  en = { title = "Try it", check = "Check", steps = "Step by step", answer = "Answer",
         step = "Step" },
}

local function words()
  return lang:sub(1, 2) == "en" and WORDS.en or WORDS.es
end

local function Meta(meta)
  if meta.lang then lang = pandoc.utils.stringify(meta.lang) end
  return nil
end

local function warn(msg)
  io.stderr:write("WARNING (guided-exercise.lua): " .. msg .. "\n")
end

local function raw(s) return pandoc.RawInline("html", s) end
local function rawb(s) return pandoc.RawBlock("html", s) end

-- The slot's reference: the last plain number of its math, after the last \approx or =.
local function reference(tex)
  local tail = tex
  local exact = true
  for _, rel in ipairs({ "\\approx", "=" }) do
    local at = 0
    while true do
      local s, e = tail:find(rel, at + 1, true)
      if not s then break end
      at = e
    end
    if at > 0 then
      if rel == "\\approx" then exact = false end
      tail = tail:sub(at + 1)
    end
  end
  local t, degrees = tail:gsub("%^%s*{?%s*\\circ%s*}?", "")
  t = t:gsub("{,}", "."):gsub("\\[,;:! ]", ""):gsub("%s+", "")
  local num = t:match("^%-?%d+%.?%d*$") or t:match("^%-?%.%d+$")
  if not num then return nil end
  local dec = num:match("%.(%d+)$")
  return { value = num, exact = exact, dec = dec and #dec or 0, degrees = degrees > 0 }
end

local slots = 0   -- slots in the zone being built

local function slot(span)
  local math
  for _, el in ipairs(span.content) do
    if el.t == "Math" then math = el end
  end
  if not math then
    warn("a .casilla span needs its value as math: [$...$]{.casilla}")
    return nil
  end
  slots = slots + 1
  local ref = reference(math.text)
  local attrs = ' class="casilla"'
  local unit = ""
  if ref then
    local min = span.attributes["decimales"] or (ref.exact and "0" or tostring(ref.dec))
    attrs = attrs .. ' data-valor="' .. ref.value .. '" data-exacto="' .. (ref.exact and 1 or 0)
      .. '" data-dec="' .. ref.dec .. '" data-min="' .. min .. '"'
    if ref.degrees then unit = '<span class="casilla-unidad">°</span>' end
  else
    warn("a slot needs its value as a decimal (\\sqrt{5} \\approx 2.236): " .. math.text)
  end
  return {
    raw('<span' .. attrs .. '><input type="text" autocomplete="off" spellcheck="false" '
        .. 'aria-label="' .. words().answer .. '">' .. unit .. '<span class="casilla-valor">'),
    math,
    raw('</span></span>'),
  }
end

local function marked(item)
  local first = item[1]
  if not first or (first.t ~= "Plain" and first.t ~= "Para") then return false end
  for _, il in ipairs(first.content) do
    if il.t == "Span" and il.classes:includes("correcta") then return true end
  end
  return false
end

local function choices(list)
  local any = false
  for _, item in ipairs(list.content) do
    if marked(item) then any = true end
  end
  if not any then return nil end   -- an ordinary list
  local out = pandoc.List({ rawb('<div class="opciones" role="group">') })
  for _, item in ipairs(list.content) do
    local ok = marked(item)
    local text = pandoc.List()
    for _, il in ipairs(item[1].content) do
      if il.t == "Span" and il.classes:includes("correcta") then
        text:extend(il.content)
      else
        text:insert(il)
      end
    end
    out:insert(rawb('<div class="opcion-fila">'))
    local button = pandoc.List({ raw('<button type="button" class="opcion"'
      .. (ok and ' data-ok="1"' or '') .. '>') })
    button:extend(text)
    button:insert(raw('</button>'))
    out:insert(pandoc.Plain(button))
    if #item > 1 then
      out:insert(rawb('<div class="opcion-retro">'))
      for i = 2, #item do out:insert(item[i]) end
      out:insert(rawb('</div>'))
    end
    out:insert(rawb('</div>'))
  end
  out:insert(rawb('</div>'))
  return out
end

-- One zone (the final-answer part or a step): its blocks with slots and choices built.
local function zone(blocks, classes, n, first_step)
  slots = 0
  local body = pandoc.Div(blocks):walk({
    Span = function(s) if s.classes:includes("casilla") then return slot(s) end end,
  }):walk({ BulletList = choices })
  local w = words()
  local tag = n and "li" or "div"
  local label = n and (' aria-label="' .. w.step .. ' ' .. n .. '"') or ""
  local out = pandoc.List({ rawb('<' .. tag .. ' class="guiado-zona ' .. classes .. '"'
    .. label .. '>') })
  out:extend(body.content)
  local actions = ""
  if slots > 0 then
    actions = '<button type="button" class="guiado-comprobar">' .. w.check .. '</button>'
  end
  if first_step then
    actions = actions .. '<button type="button" class="guiado-abrir">' .. w.steps .. '</button>'
  end
  if actions ~= "" then
    out:insert(rawb('<div class="guiado-acciones">' .. actions .. '</div>'))
  end
  out:insert(rawb('<p class="guiado-retro" aria-live="polite"></p>'))
  out:insert(rawb('</' .. tag .. '>'))
  return out
end

local used = false

local function Div(div)
  if not div.classes:includes("guiado") then return nil end
  used = true
  local intro, steps = pandoc.List(), pandoc.List()
  for _, b in ipairs(div.content) do
    if b.t == "Div" and b.classes:includes("paso") then
      steps:insert(pandoc.List(b.content))
    elseif #steps == 0 then
      intro:insert(b)
    else
      steps[#steps]:insert(b)
    end
  end
  local title = (div.attributes["title"] or words().title)
    :gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
  local out = pandoc.List({ rawb('<div class="guiado">'),
                            rawb('<p class="guiado-titulo">' .. title .. '</p>') })
  local has_intro = #intro > 0
  if has_intro then
    out:extend(zone(intro, "guiado-intento", nil, #steps > 0))
  end
  if #steps > 0 then
    out:insert(rawb('<ol class="guiado-pasos' .. (has_intro and ' cerrado' or '') .. '">'))
    for i, blocks in ipairs(steps) do
      out:extend(zone(blocks, "guiado-paso" .. (i > 1 and " cerrado" or ""), i, false))
    end
    out:insert(rawb('</ol>'))
  end
  out:insert(rawb('</div>'))
  return out
end

local function sibling(name)
  local path
  if quarto and quarto.utils and quarto.utils.resolve_path then
    path = quarto.utils.resolve_path(name)
  else
    local dir = PANDOC_SCRIPT_FILE and PANDOC_SCRIPT_FILE:match("^(.*)[/\\]") or "."
    path = dir .. "/" .. name
  end
  local f = io.open(path, "r")
  if not f then
    warn("cannot read " .. path)
    return ""
  end
  local text = f:read("a")
  f:close()
  return text
end

local function Pandoc(doc)
  if used and quarto and quarto.doc and quarto.doc.include_text then
    quarto.doc.include_text("in-header", "<style>\n" .. sibling("guided-exercise.css")
      .. "</style>")
    quarto.doc.include_text("after-body", "<script>\n" .. sibling("guided-exercise.js")
      .. "</script>")
  end
  return nil
end

return { { Meta = Meta }, { Div = Div }, { Pandoc = Pandoc } }
