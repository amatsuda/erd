class ERD
  constructor: (@name, @elem, @edges) ->
    @paper = Raphael(name, @elem.css('width'), @elem.css('height'))
    @setup_handlers()
    @connect_arrows()

  upsert_change: (action, model, column, from, to) ->
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

  positions: (div) ->
    [left, width, top, height] = [parseInt(div.css('left')), parseInt(div.css('width')), parseInt(div.css('top')), parseInt(div.css('height'))]
    {left: left, right: left + width, top: top, bottom: top + height, center: {x: (left + left + width) / 2, y: (top + top + height) / 2}, vertex: {}}

  connect_arrows: ->
    $.each @edges, (i, edge) =>
      @connect_arrow $("##{edge.from}"), $("##{edge.to}")

  connect_arrow: (from_elem, to_elem) ->
    #TODO handle self referential associations
    return if from_elem.attr('id') == to_elem.attr('id')

    from = @positions(from_elem)
    to = @positions(to_elem)
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

    @paper.path(path).attr({'stroke-width': 2, opacity: 0.5, 'arrow-end': 'classic-wide-long'})

  setup_handlers: ->
    @setup_click_handlers()
    @setup_submit_handlers()
    $('div.model').draggable(drag: @handle_drag)

  handle_drag: (ev, ui) =>
    target = $(ev.target)
    model = target.data('model_name')
    from = target.data('original_position')
    to = [target.css('left').replace(/px$/, ''), target.css('top').replace(/px$/, '')].join()
    @upsert_change 'move', model, '', '', to
    @paper.clear()
    @connect_arrows(@edges)

  setup_click_handlers: ->
    text_elems = [
      'div.model_name_text',
      'span.column_name_text',
      'span.column_type_text'
    ].join()

    $(text_elems).on 'click', @handle_text_elem_click
    $('div.model a.add_column').on 'click', @handle_add_column_click
    $('div.model a.close').on 'click', @handle_remove_model_click

  setup_submit_handlers: ->
    $('form.rename_model_form').on 'submit', @handle_rename_model
    $('form.rename_column_form').on 'submit', @handle_rename_column
    $('form.alter_column_form').on 'submit', @handle_change_column_type
    $('form.add_column_form').on 'submit', @handle_add_column
    $('#changes_form').on 'submit', @handle_save

  handle_save: ->
    j = '['
    rows = ($(tr).find('td') for tr in $('#changes > tbody > tr'))
    $(rows).each (i, row) ->
      j += "{\"action\": \"#{$(row[0]).html()}\", \"model\": \"#{$(row[1]).html()}\", \"column\": \"#{$(row[2]).html()}\", \"from\": \"#{$(row[3]).html()}\", \"to\": \"#{$(row[4]).html()}\"}"
      j += ',' if i < rows.length - 1
    j += ']'
    $('#changes_form').find('input[name=changes]').val(j)

  handle_add_column: (ev) ->
    ev.preventDefault()
    target = $(ev.target)
    name = target.find('input[name=name]').val()
    return if name == ''

    model = target.find('input[name=model]').val()
    type  = target.find('input[name=type]').val()
    upsert_change 'add_column', model, "#{name}(#{type})", '', ''

    name_span = $("<span/>", class: 'column_name_text')
      .append(name)

    type_span = $("<span/>", class: 'column_type_text')
      .append(type)

    li_node = $("<li/>", class: 'column')
      .append(name_span)
      .append("&nbsp;")
      .append(type_span)

    target.hide()
      .parent()
      .siblings('.columns')
      .find('ul')
      .append(li_node)
      .end()
      .end()
      .find('a.add_column')
      .show()

  handle_change_column_type: (ev) ->
    ev.preventDefault()
    target = $(ev.target)
    to = target.find('input[name=to]').val()
    return if to == ''

    model  = target.find('input[name=model]').val()
    column = target.find('input[name=column]').val()
    type   = target.find('input[name=type]').val()
    if to != type
      upsert_change 'alter_column', model, column, type, to

    target.hide()
      .siblings('.column_type_text')
      .text(to)
      .show()

  handle_rename_column: (ev) ->
    ev.preventDefault()
    target = $(ev.target)
    to = target.find('input[name=to]').val()
    return if to == ''

    model = target.find('input[name=model]').val()
    column = target.find('input[name=column]').val()
    if to != column
      upsert_change 'rename_column', model, column, column, to

    target.hide()
      .siblings('.column_name_text')
      .text(to)
      .show()

  handle_rename_model: (ev) ->
    ev.preventDefault()
    target = $(ev.target)
    to = target.find('input[name=to]').val()
    return if to == ''

    model = target.find('input[name=model]').val()
    if to != model
      upsert_change 'rename_model', model, '', model, to

    target.hide()
      .siblings('.model_name_text')
      .text(to)
      .show()

  handle_add_column_click: (ev) ->
    ev.preventDefault()
    target = $(@)

    target.hide()
      .next('form')
      .show()
      .find('input[name=type]')
      .val('string')
      .end()
      .find('input[name=name]')
      .val('')
      .focus()

  handle_text_elem_click: (ev) ->
    target = $(@)
    text = target.text()

    target.hide()
      .next('form')
      .show()
      .find('input[name=to]')
      .val(text)
      .focus()

  handle_remove_model_click: (ev) =>
    ev.preventDefault()
    return unless confirm('remove this table?')

    target = $(ev.target)
    parent = target.parent()

    [model_id, model_name] = [parent.attr('id'), parent.data('model_name')]
    upsert_change 'remove_model', model_name, '', '', ''
    parent.hide()

    $.each @edges, (i, edge) =>
      @edges.splice i, 1 if (edge.from == model_id) || (edge.to == model_id)
    @paper.clear()
    @connect_arrows(@edges)

$ ->
  window.erd = new ERD('erd', $('#erd'), window.raw_edges)

