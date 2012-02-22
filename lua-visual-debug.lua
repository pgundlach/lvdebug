-- Copyright 2012 Patrick Gundlach, patrick@gundla.ch
-- released under the "MIT license" (see footer of this file)
-- Public repository: https://github.com/pgundlach/lvdebug (issues/pull requests,...)

module(...,package.seeall)

local factor = 65782  -- big points vs. TeX points
local rule_width = 0.1


local function draw_pagebox(head,parent)
  while head do
    if head.id == 0 or head.id == 1 then -- hbox / vbox

      local wd = head.width                  / factor - rule_width
      local ht = (head.height + head.depth)  / factor - rule_width
      local dp = head.depth                  / factor - rule_width / 2

      draw_pagebox(head.list,head)
      local wbox = node.new("whatsit","pdf_literal")
      if head.id == 0 then -- hbox
        wbox.data = string.format("q 0.5 G %g w %g %g %g %g re s Q", rule_width, -rule_width / 2, -dp, wd, ht)
      else
        wbox.data = string.format("q 0.1 G %g w %g %g %g %g re s Q", rule_width, -rule_width / 2, 0, wd, -ht)
      end
      wbox.mode = 0

      head.list = node.insert_before(head.list,head.list,wbox)

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

      local wbox = node.new("whatsit","pdf_literal")
      if parent.id == 0 then --hlist
        wbox.data = string.format("q %s [0.2] 0 d  0.5 w 0 0  m %g 0 l s Q",color,wd / factor)
      else -- vlist
        wbox.data = string.format("q 0.1 G 0.1 w -0.5 0 m 0.5 0 l -0.5 %g m 0.5 %g l s [0.2] 0 d  0.5 w 0.25 0  m 0.25 %g l s Q",-wd / factor,-wd / factor,-wd / factor)
      end
      wbox.mode = 0

      node.insert_before(parent.list,head,wbox)
    elseif head.id == 11 then -- kern
      local wbox = node.new("whatsit","pdf_literal")
      local color = "1 1 0 rg"
      if head.kern < 0 then color = "1 0 0 rg" end
      if parent.id == 0 then --hlist
        wbox.data = string.format("q %s 0 w 0 0  %g 1 re B Q",color, head.kern / factor )
      else
        wbox.data = string.format("q %s 0 w 0 0  1 %g re B Q",color, -head.kern / factor )
      end
      node.insert_before(parent.list,head,wbox)
    elseif head.id == 12 then -- penalty
      local color = "1 g"
      local wbox = node.new("whatsit","pdf_literal")
      if head.penalty < 10000 then
        color = string.format("%d g", 1 - head.penalty / 10000)
      end
      wbox.data = string.format("q %s 0 w 0 0 1 1 re B Q",color)
      node.insert_before(parent.list,head,wbox)
    else
      -- ignore
    end
    head = head.next
  end
end

local function draw()
  draw_pagebox(tex.box["AtBeginShipoutBox"].list,tex.box["AtBeginShipoutBox"])
end

return { draw = draw }

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
