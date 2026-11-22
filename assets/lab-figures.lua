-- Lab figures on the site (decision 0024).
--
-- The site renders a lab's jupytext .md without running it, so a figure a code cell draws
-- would exist only in Colab. `_tools/exec_check.py` saves each figure from the executed
-- notebook to assets/<lab>-figN.png and writes assets/<lab>.figures.json, which keys the
-- figures by the SHA-1 of their cell's source. This filter hashes each python code block the
-- same way and places its figures right below it. Colab is unaffected: the notebook keeps its
-- own outputs, and the .md is never changed.
--
-- Scope: pages with a manifest next to them (a lab or challenge .md). Any other page, or a
-- code block the manifest does not name (a display block in a reveal), is left untouched.
-- A stale manifest only misses blocks; `exec_check.py --verify` reports it (X10).
--
-- Shared by all courses: edit this master copy, _design/assets/lab-figures.lua, and re-copy
-- it into each course's course/assets/ (see _design/quarto_style_default.md).

local function read_manifest()
  local input = quarto.doc.input_file or ""
  local dir, stem = input:match("^(.*)[/\\]([^/\\]+)%.md$")
  if not dir then
    return nil
  end
  local f = io.open(dir .. "/assets/" .. stem .. ".figures.json", "r")
  if not f then
    return nil
  end
  local data = quarto.json.decode(f:read("a"))
  f:close()
  return data and data.figures
end

function Pandoc(doc)
  local figures = read_manifest()
  if not figures or next(figures) == nil then
    return nil
  end
  local lang = pandoc.utils.stringify(doc.meta.lang or "")
  local alt = lang:match("^es") and "Figura que dibuja la celda anterior"
    or "The figure the cell above draws"
  return doc:walk({
    Blocks = function(blocks)
      local out = pandoc.Blocks({})
      for _, block in ipairs(blocks) do
        out:insert(block)
        if block.t == "CodeBlock" and block.classes:includes("python") then
          for _, src in ipairs(figures[pandoc.utils.sha1(block.text)] or {}) do
            -- Plain, not Para: a lone image in a paragraph would become a captioned figure.
            out:insert(pandoc.Div({ pandoc.Plain({ pandoc.Image(alt, src) }) },
              pandoc.Attr("", { "lab-figure" })))
          end
        end
      end
      return out
    end,
  })
end
