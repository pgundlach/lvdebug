-- Copyright 2012 Patrick Gundlach, patrick@gundla.ch
-- Public repository: https://github.com/pgundlach/lvdebug (issues/pull requests,...)

-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
-- publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



module(...,package.seeall)

-- There are 65782 scaled points in a PDF point
-- Therefore we need to devide all TeX lengths by
-- this amount to get the PDF points.
local number_sp_in_a_pdf_point = 65782


-- The idea is the following: at page shipout, all elements on a page are fixed.
-- TeX creates an intermediate data structure before putting that into the PDF
-- We can "intercept" that data structure and add pdf_literal (whatist) nodes,
-- that makes glues, kerns and other items visible by drawing a rule, rectangle or
-- other visual aids.
-- This has no influence on typeset material, because these pdf_literal instructions
-- are only visible to the PDF file (PDF renderer) and have no size themselves.

-- We recursively loop through the contents of boxes and look at the (linear) list of
-- items in that box. We start at the "shipout box".

-- The "algorithm" goes like this:
--
-- head = pointer_to_beginning_of_box_material
-- while head is not nil
--   if this_item_is_a_box
--     recurse_into_contents
--     draw a rectangle around the contents
--   elseif this_item_is_a_glue
--     draw a rule that has the length of that glue
--   elseif this_item_is_a_kern
--     draw a rectangle with width of that kern
--   ...
--   end
--   move pointer to the next item in the list
--   -- the pointer is "nil" if there is no next item
-- end


function show_page_elements(parent)
  local head = parent.list
  while head do
    if head.id == 0 or head.id == 1 then -- hbox / vbox

      local rule_width = 0.1
      local wd = head.width                  / number_sp_in_a_pdf_point - rule_width
      local ht = (head.height + head.depth)  / number_sp_in_a_pdf_point - rule_width
      local dp = head.depth                  / number_sp_in_a_pdf_point - rule_width / 2

      -- recurse into the contents of the box
      show_page_elements(head)
      local rectangle = node.new("whatsit","pdf_literal")
      if head.id == 0 then -- hbox
        rectangle.data = string.format("q 0.5 G %g w %g %g %g %g re s Q", rule_width, -rule_width / 2, -dp, wd, ht)
      else
        rectangle.data = string.format("q 0.1 G %g w %g %g %g %g re s Q", rule_width, -rule_width / 2, 0, wd, -ht)
      end
      head.list = node.insert_before(head.list,head.list,rectangle)


    elseif head.id == 2 then -- rule
      if head.width == 0 then head.width = 0.4 * 2^16 end
      local goback = node.new("kern")
      goback.kern = -head.width
      node.insert_after(parent.list,head,goback)
      head = goback


    elseif head.id == 7 then -- disc
      local hyphen_marker = node.new("whatsit","pdf_literal")
      hyphen_marker.data = "q 0 0 1 RG 0.3 w 0 -1 m 0 0 l S Q"
      parent.list = node.insert_before(parent.list,head,hyphen_marker)


    elseif head.id == 10 then -- glue
      local wd = head.spec.width
      local color = "0.5 G"
      if parent.glue_sign == 1 and parent.glue_order == head.spec.stretch_order then
        wd = wd + parent.glue_set * head.spec.stretch
        color = "0 0 1 RG"
      elseif parent.glue_sign == 2 and parent.glue_order == head.spec.shrink_order then
        wd = wd - parent.glue_set * head.spec.shrink
        color = "1 0 1 RG"
      end
      local pdfstring = node.new("whatsit","pdf_literal")
      if parent.id == 0 then --hlist
        pdfstring.data = string.format("q %s [0.2] 0 d  0.5 w 0 0  m %g 0 l s Q",color,wd / number_sp_in_a_pdf_point)
      else -- vlist
        pdfstring.data = string.format("q 0.1 G 0.1 w -0.5 0 m 0.5 0 l -0.5 %g m 0.5 %g l s [0.2] 0 d  0.5 w 0.25 0  m 0.25 %g l s Q",-wd / number_sp_in_a_pdf_point,-wd / number_sp_in_a_pdf_point,-wd / number_sp_in_a_pdf_point)
      end
      parent.list = node.insert_before(parent.list,head,pdfstring)


    elseif head.id == 11 then -- kern
      local rectangle = node.new("whatsit","pdf_literal")
      local color = "1 1 0 rg"
      if head.kern < 0 then color = "1 0 0 rg" end
      if parent.id == 0 then --hlist
        rectangle.data = string.format("q %s 0 w 0 0  %g 1 re B Q",color, head.kern / number_sp_in_a_pdf_point )
      else
        rectangle.data = string.format("q %s 0 w 0 0  1 %g re B Q",color, -head.kern / number_sp_in_a_pdf_point )
      end
      parent.list = node.insert_before(parent.list,head,rectangle)

    elseif head.id == 12 then -- penalty
      local color = "1 g"
      local rectangle = node.new("whatsit","pdf_literal")
      if head.penalty < 10000 then
        color = string.format("%d g", 1 - head.penalty / 10000)
      end
      rectangle.data = string.format("q %s 0 w 0 0 1 1 re B Q",color)
      parent.list = node.insert_before(parent.list,head,rectangle)
    end
    head = head.next
  end
  return true
end

