$ ->
  window.paper = Raphael('erd', $('#erd').css('width'), $('#erd').css('height'))

positions = (div) ->
  [left, width, top, height] = [parseInt(div.css('left')), parseInt(div.css('width')), parseInt(div.css('top')), parseInt(div.css('height'))]
  {left: left, right: left + width, top: top, bottom: top + height, center: {x: (left + left + width) / 2, y: (top + top + height) / 2}, vertex: {}}


window.connect_arrows = (edges) ->
  $.each(edges, (i, edge) ->
    window.connect_arrow $("##{edge.from}"), $("##{edge.to}")
  )

window.connect_arrow = (from_elem, to_elem) ->
  #TODO handle self referential associations
  return if from_elem.attr('id') == to_elem.attr('id')

  from = positions(from_elem)
  to = positions(to_elem)
  #FIXME terrible code
  a = (to.center.y - from.center.y) / (to.center.x - from.center.x)
  b = from.center.y - from.center.x * a

  x2y = (x) -> ( a * x + b )
  y2x = (y) -> ( (y - b) / a )

  if from.center.x > to.center.x
    [from.vertex.x, from.vertex.y] = [from.left, x2y(from.left)]
    [to.vertex.x, to.vertex.y] = [to.right, x2y(to.right)]
  else
    [from.vertex.x, from.vertex.y] = [from.right, x2y(from.right)]
    [to.vertex.x, to.vertex.y] = [to.left, x2y(to.left)]
  for rect in [from, to]
    if rect.vertex.y < rect.top
      [rect.vertex.x, rect.vertex.y, rect.vertex.direction] = [y2x(rect.top), rect.top, 'v']
    else if rect.vertex.y > rect.bottom
      [rect.vertex.x, rect.vertex.y, rect.vertex.direction] = [y2x(rect.bottom), rect.bottom, 'v']
    else
      from.vertex.direction = 'h'

  if from.vertex.direction == 'h'
    path = "M#{parseInt(from.vertex.x)} #{parseInt(from.vertex.y)}H#{parseInt((from.vertex.x + to.vertex.x) / 2)} V#{parseInt(to.vertex.y)} H#{parseInt(to.vertex.x)}"
  else
    path = "M#{parseInt(from.vertex.x)} #{parseInt(from.vertex.y)}V#{parseInt((from.vertex.y + to.vertex.y) / 2)} H#{parseInt(to.vertex.x)} V#{parseInt(to.vertex.y)}"

  window.paper.path(path).attr({'stroke-width': 2, opacity: 0.5, 'arrow-end': 'classic-wide-long'})
