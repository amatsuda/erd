$ ->
  window.paper = Raphael('erd', $('#erd').css('width'), $('#erd').css('height'))

#   $('#erd').on 'click', (ev) ->
#     console.log 'click'
  $('div.model_name_text, span.column_name_text, span.column_type_text').on('click', (ev) ->
    $(this).hide()
      .next('form').show().find('input[name=to]').val($(this).text()).focus()
  )

  $('div.model a.add_column').on 'click', (ev) ->
    ev.preventDefault()
    $(this).hide()
      .next('form').show().find('input[name=type]').val('string').end().find('input[name=name]').val('').focus()

  $('div.model a.close').on 'click', (ev) ->
    ev.preventDefault()
    if confirm('remove this table?')
      [model_id, model_name] = [$(this).parent().attr('id'), $(this).parent().data('model_name')]
      upsert_change 'remove_model', model_name, '', '', ''
      $(this).parent().hide()

      $.each window.edges, (i, edge) ->
        window.edges.splice i, 1 if (edge.from == model_id) || (edge.to == model_id)
      window.paper.clear()
      connect_arrows(window.edges)

  $('div.model').draggable
    drag: (_event, _ui) ->
      model = $(this).data('model_name')
      from = $(this).data('original_position')
      to = [$(this).css('left').replace(/px$/, ''), $(this).css('top').replace(/px$/, '')].join()
      upsert_change 'move', model, '', '', to
      window.paper.clear()
      connect_arrows(window.edges)

  $('form.rename_model_form').on('submit', (ev) ->
    ev.preventDefault()
    to = $(this).find('input[name=to]').val()

    if to != ''
      model = $(this).find('input[name=model]').val()
      if to != model
        upsert_change 'rename_model', model, '', model, to

      $(this).hide().siblings('.model_name_text').text(to).show()
  )

  $('form.rename_column_form').on('submit', (ev) ->
    ev.preventDefault()
    to = $(this).find('input[name=to]').val()

    if to != ''
      model = $(this).find('input[name=model]').val()
      column = $(this).find('input[name=column]').val()
      if to != column
        upsert_change 'rename_column', model, column, column, to

      $(this).hide().siblings('.column_name_text').text(to).show()
  )

  $('form.alter_column_form').on('submit', (ev) ->
    ev.preventDefault()
    to = $(this).find('input[name=to]').val()

    if to != ''
      model = $(this).find('input[name=model]').val()
      column = $(this).find('input[name=column]').val()
      type = $(this).find('input[name=type]').val()
      if to != type
        upsert_change 'alter_column', model, column, type, to

      $(this).hide().siblings('.column_type_text').text(to).show()
  )

  $('form.add_column_form').on('submit', (ev) ->
    ev.preventDefault()
    name = $(this).find('input[name=name]').val()

    if name != ''
      model = $(this).find('input[name=model]').val()
      type = $(this).find('input[name=type]').val()
      upsert_change 'add_column', model, "#{name}(#{type})", '', ''

      $(this).hide().parent().siblings('.columns').find('ul').append("<li class=\"column\"><span class=\"column_name_text\">#{name}</span>&nbsp;<span class=\"column_type_text\">#{type}</span></li>").end().end()
        .find('a.add_column').show()
  )

  $('#changes_form').on 'submit', (ev) ->
    j = '['
    rows = ($(tr).find('td') for tr in $('#changes > tbody > tr'))
    $(rows).each (i, row) ->
      j += "{\"action\": \"#{$(row[0]).html()}\", \"model\": \"#{$(row[1]).html()}\", \"column\": \"#{$(row[2]).html()}\", \"from\": \"#{$(row[3]).html()}\", \"to\": \"#{$(row[4]).html()}\"}"
      j += ',' if i < rows.length - 1
    j += ']'
    $('#changes_form').find('input[name=changes]').val(j)

upsert_change = (action, model, column, from, to) ->
  rows = ($(tr).find('td') for tr in $('#changes > tbody > tr'))
  existing = null
  $(rows).each (i, row) ->
    existing = row if (action == $(row[0]).html()) && (model == $(row[1]).html()) && (column == $(row[2]).html())
  if existing == null
    $('#changes > tbody').append("<tr><td>#{action}</td><td>#{model}</td><td>#{column}</td><td>#{from}</td><td>#{to}</td></tr>")
  else
    $(existing[3]).text(from)
    $(existing[4]).text(to)
  $('#changes').show()

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
