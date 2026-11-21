-- One title per page (decision 0012; smoke-test finding F3, 2026-11-20).
--
-- On a page with a `title:`, Quarto's title block already shows the title, so a level-1
-- heading that opens the body is a duplicate. This filter drops it at site build time only.
-- Labs, challenges and projects keep their `# Lab: ...` heading in the source on purpose:
-- the front matter never reaches the notebook (decision 2026/0025), so that heading is the
-- notebook's only visible title in Colab.
--
-- Scope: the FIRST block of the body, skipping raw blocks (HTML comments). Any other content
-- before it, a lower-level heading, or a page without a title leaves the page untouched.
--
-- Shared by all courses: edit this master copy, _design/assets/drop-title-heading.lua, and
-- re-copy it into each course's course/assets/ (see _design/quarto_style_default.md).

function Pandoc(doc)
  if doc.meta.title == nil then
    return nil
  end
  for i, block in ipairs(doc.blocks) do
    if block.t == "Header" then
      if block.level == 1 then
        doc.blocks:remove(i)
        return doc
      end
      return nil
    elseif block.t ~= "RawBlock" then
      return nil
    end
  end
  return nil
end
