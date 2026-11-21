--[[
exercise-blocks.lua: the two block kinds of a mathematics exercise page (decision 0016).

Master copy: _design/assets/exercise-blocks.lua (see _design/quarto_style_default.md §1).
/course-init copies it to <COURSE>/course/assets/ and _quarto.yml lists it under `filters:`.
Edit the master copy and re-copy; never edit a course's copy alone.

  ::: {.solucion}                 ->  <details class="solucion"><summary>Solución</summary> ... </details>
  ::: {.solucion title="Pista"}       (the summary text; default "Solución", "Solution" in English)

  ::: {.error-comun}              ->  a visible warning callout titled "Error común"
  ::: {.error-comun title="..."}      (another title)

Why <details> and not a collapsed callout: Quarto's callout header is a <div> that Tab never
reaches, so a keyboard user cannot open it; <summary> is a native control. The few CSS lines
below give the <details> the callout's look (probed in Chrome, 2026-11-20; b2-build-plan piece 2).
The content stays Pandoc blocks, so math, lists and code inside render as usual.
_tools/step_check.py finds both blocks by these class names in the source.
]]

local CSS = [[
<style>
details.solucion { border: 1px solid #dee2e6; border-left: 5px solid #3fb618;
  border-radius: .25rem; margin: 1rem 0; }
details.solucion > summary { cursor: pointer; padding: .4rem .8rem; font-weight: 600;
  background: #ecf8e8; color: inherit; }
details.solucion[open] > summary { border-bottom: 1px solid #dee2e6; margin-bottom: .6rem; }
details.solucion > :not(summary) { margin-left: .8rem; margin-right: .8rem; }
details.solucion > summary:focus-visible { outline: 2px solid #2780e3; outline-offset: 2px; }
</style>
]]

local lang = "es"

local function words()
  if lang:sub(1, 2) == "en" then return "Solution", "Common error" end
  return "Solución", "Error común"
end

local function Meta(meta)
  if meta.lang then lang = pandoc.utils.stringify(meta.lang) end
  return nil
end

local used = false

local function Div(div)
  local solution, mistake = words()
  if div.classes:includes("solucion") then
    used = true
    local summary = (div.attributes["title"] or solution)
      :gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    local out = pandoc.List({ pandoc.RawBlock("html",
      '<details class="solucion">\n<summary>' .. summary .. '</summary>') })
    out:extend(div.content)
    out:insert(pandoc.RawBlock("html", "</details>"))
    return out
  end
  if div.classes:includes("error-comun") then
    local title = div.attributes["title"] or mistake
    -- Quarto parses `.callout-*` Divs before user filters run, so adding the class here is too
    -- late (probed on Quarto 1.10.18): build the callout through Quarto's API instead.
    if quarto and quarto.Callout then
      -- no `collapse` key: `collapse = false` means "collapsible, starting open" (an arrow)
      return quarto.Callout({ type = "warning", title = title, content = div.content })
    end
    -- plain Pandoc (the tests): keep the Div, marked as Quarto would read it
    div.classes:insert("callout-warning")
    div.attributes["title"] = title
    return div
  end
  return nil
end

local function Pandoc(doc)
  if used and quarto and quarto.doc and quarto.doc.include_text then
    quarto.doc.include_text("in-header", CSS)
  end
  return nil
end

return { { Meta = Meta }, { Div = Div }, { Pandoc = Pandoc } }
