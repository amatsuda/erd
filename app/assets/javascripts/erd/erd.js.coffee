class ERD
  constructor: (@name, @elem, @edges) ->
    @paper = Raphael(@name, @elem.data('svg_width'), @elem.data('svg_height'))
    @setup_handlers()
    models = @elem.find('.model')
    @models = {}
    for model in models
      @models[$(model).data('model_name')] = model
    @connect_arrows(@edges)

  upsert_change: (action, model, column, from, to) ->
    rows = ($(tr).find('td') for tr in $('#changes > tbody > tr'))
    existing = null
    $(rows).each (i, row) ->
      existing = row if (action == $(row[0]).html()) && (model == $(row[1]).html()) && (column == $(row[2]).html())
    if existing == null
      $('#changes > tbody').append("""
        <tr>
          <td data-name="action">#{action}</td>
          <td data-name="model">#{model}</td>
          <td data-name="column">#{column}</td>
          <td data-name="from">#{from}</td>
          <td data-name="to">#{to}</td>
        </tr>
      """)
    else
      $(existing[3]).text(from)
      $(existing[4]).text(to)
    $('#changes').show()

  positions: (div) ->
    [left, width, top, height] = [parseFloat(div.css('left')), parseFloat(div.css('width')), parseFloat(div.css('top')), parseFloat(div.css('height'))]
    {left: left, right: left + width, top: top, bottom: top + height, center: {x: (left + left + width) / 2, y: (top + top + height) / 2}, vertex: {}}

  connect_arrows: (edges) =>
    $.each edges, (i, edge) =>
      @connect_arrow edge, $(@models[edge.from]), $(@models[edge.to])

  connect_arrow: (edge, from_elem, to_elem) ->
    #TODO handle self referential associations
    return if from_elem.attr('id') == to_elem.attr('id')

    edge.path.remove() if edge.path?

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
      path = "M#{Math.floor(from.vertex.x)} #{Math.floor(from.vertex.y)}H#{Math.floor((from.vertex.x + to.vertex.x) / 2)} V#{Math.floor(to.vertex.y)} H#{Math.floor(to.vertex.x)}"
    else
      path = "M#{Math.floor(from.vertex.x)} #{Math.floor(from.vertex.y)}V#{Math.floor((from.vertex.y + to.vertex.y) / 2)} H#{Math.floor(to.vertex.x)} V#{Math.floor(to.vertex.y)}"

    edge.path = @paper.path(path).attr({'stroke-width': 2, opacity: 0.5, 'arrow-end': 'classic-wide-long'})

  setup_handlers: ->
    @setup_click_handlers()
    @setup_submit_handlers()
    @setup_migration_event_handlers()
    $('div.model').draggable(drag: @handle_drag)

  handle_drag: (ev, ui) =>
    target = $(ev.target)
    target.addClass('noclick')
    model_name = target.data('model_name')
    from = target.data('original_position')
    to = [target.css('left').replace(/px$/, ''), target.css('top').replace(/px$/, '')].join()
    @upsert_change 'move', model_name, '', '', to
    @connect_arrows(@edges.filter((e)-> e.from == model_name || e.to == model_name))

  setup_click_handlers: ->
    $('div.model_name_text, span.column_name_text, span.column_type_text').on 'click', @handle_text_elem_click
    $('div.model a.add_column').on 'click', @handle_add_column_click
    $('div.model a.cancel').on 'click', @handle_cancel_click
    $('div.model a.close').on 'click', @handle_remove_model_click
    $('#new_model_add_column').on 'click', @handle_new_model_add_column_click
    $('div.model a.cancel').on 'click', @handle_cancel_click
    $('div#open_migration').on 'click', @handle_open_migration_click
    $('div#close_migration').on 'click', @handle_close_migration_click

  setup_submit_handlers: ->
    $('form.rename_model_form').on 'submit', @handle_rename_model
    $('form.rename_column_form').on 'submit', @handle_rename_column
    $('form.alter_column_form').on 'submit', @handle_change_column_type
    $('form.add_column_form').on 'submit', @handle_add_column
    $('#changes_form').on 'submit', @handle_save

  setup_migration_event_handlers: ->
    $('#migration_status tr input').on 'click', ->
      $(this).parents('tr').toggleClass('active')
    $('#migration_status thead td button').on 'click', (ev) ->
      ev.preventDefault()
      $('#migration_status').toggleClass('show_all_migrations')

  handle_save: (ev) =>
    changes = $('#changes > tbody > tr').map(->
      change = {}
      $(this).find('td').each ->
        name = $(this).data('name')
        value = $(this).html()
        change[name] = value
      change
    ).toArray()
    $('#changes_form').find('input[name=changes]').val(JSON.stringify(changes))

  handle_add_column: (ev) =>
    ev.preventDefault()
    target = $(ev.target)
    name = target.find('input[name=name]').val()
    return if name == ''

    model = target.find('input[name=model]').val()
    type  = target.find('input[name=type]').val()
    @upsert_change 'add_column', model, "#{name}(#{type})", '', ''

    name_span = $("<span/>", class: 'column_name_text')
      .append(name)

    type_span = $("<span/>", class: 'column_type_text unsaved')
      .append(type)

    li_node = $("<li/>", class: 'column unsaved').append(name_span).append("&nbsp;").append(type_span)

    target.hide()
      .parent()
      .siblings('.columns')
      .find('ul').append(li_node).end()
      .end()
      .find('a.add_column').show()

  handle_change_column_type: (ev) =>
    ev.preventDefault()
    target = $(ev.target)
    to = target.find('input[name=to]').val()
    return if to == ''

    model  = target.find('input[name=model]').val()
    column = target.find('input[name=column]').val()
    type   = target.find('input[name=type]').val()
    if to != type
      @upsert_change 'alter_column', model, column, type, to

    target.hide()
      .siblings('.column_type_text').text(to).show().addClass('unsaved')
      .parents('.column').addClass('unsaved')

  handle_rename_column: (ev) =>
    ev.preventDefault()
    target = $(ev.target)
    to = target.find('input[name=to]').val()
    return if to == ''

    model = target.find('input[name=model]').val()
    column = target.find('input[name=column]').val()
    if to != column
      @upsert_change 'rename_column', model, column, column, to

    target.hide()
      .siblings('.column_name_text').text(to).show()
      .parents('.column').addClass('unsaved')

  handle_rename_model: (ev) =>
    ev.preventDefault()
    target = $(ev.target)
    to = target.find('input[name=to]').val()
    return if to == ''

    model = target.find('input[name=model]').val()
    if to != model
      @upsert_change 'rename_model', model, '', model, to

    target.hide()
      .siblings('.model_name_text').text(to).show().addClass('unsaved')

  handle_add_column_click: (ev) =>
    ev.preventDefault()
    target = $(ev.currentTarget)

    m = target.parents('div.model')
    if m.hasClass('noclick')
      m.removeClass('noclick')
      return false

    target.hide()
      .next('form').show()
      .find('a.cancel').show().end()
      .find('input[name=type]').val('string').end()
      .find('input[name=name]').val('').focus()

  handle_cancel_click: (ev) =>
    ev.preventDefault()
    target = $(ev.currentTarget)

    m = target.parents('div.model')
    if m.hasClass('noclick')
      m.removeClass('noclick')
      return false

    target.hide()
      .parent('form').hide()
      .prev('a.add_column, span, div').show()


  handle_text_elem_click: (ev) =>
    target = $(ev.currentTarget)
    text = target.text()

    m = target.parents('div.model')
    if m.hasClass('noclick')
      m.removeClass('noclick')
      return false

    target.hide()
      .next('form').show()
      .find('a.cancel').show().end()
      .find('input[name=to]').val(text).focus()

  handle_remove_model_click: (ev) =>
    ev.preventDefault()

    target = $(ev.target)
    parent = target.parent()

    m = target.parents('div.model')
    if m.hasClass('noclick')
      m.removeClass('noclick')
      return false

    return unless confirm('remove this table?')

    model_name = m.data('model_name')
    window.erd.upsert_change 'remove_model', model_name, '', '', ''
    parent.hide()

    $.each @edges, (i, edge) =>
      @edges.splice i, 1 if (edge.from == model_name) || (edge.to == model_name)
    @paper.clear()
    @connect_arrows(@edges)

  handle_new_model_add_column_click: (ev) =>
    ev.preventDefault()
    target = $(ev.currentTarget)

    target.parent().siblings('table').append('<tr><td><input type="text" /></td><td class="separator">:</td><td><input type="text" value="string" /></td></tr>').find('tr:last > td > input:first').focus()


  handle_open_migration_click: (ev) =>
    ev.preventDefault()

    target = $(ev.currentTarget)
    text = target.text()

    m = target.parents('div.model')
    if m.hasClass('noclick')
      m.removeClass('noclick')
      return false

    target.hide()
      .next('div').show()
      .find('#close_migration').show()


  handle_close_migration_click: (ev) =>
    ev.preventDefault()

    target = $(ev.currentTarget)
    text = target.text()

    m = target.parents('div.model')
    if m.hasClass('noclick')
      m.removeClass('noclick')
      return false

    target.hide()
      .parent().hide()
      .prev('div').show()

$ ->
  window.erd = new ERD('erd', $('#erd'), window.raw_edges)

  $('#erd').css('height', window.innerHeight)
  $(window).on 'resize', ->
    $('#erd').css('height', window.innerHeight)

  $("#open_migration").click ->
    $('#close_migration, #open_create_model_dialog').css('right', $('#migration').width() + ($(this).width() / 2) - 5)

  $("#close_migration").click ->
    $('#open_create_model_dialog').css('right', 15)

  $('#open_up').click ->
    $('#migration_status .up').addClass('open')
    $('#migration_status .down').removeClass('open')

  $('#open_down').click ->
    $('#migration_status .down').addClass('open')
    $('#migration_status .up').removeClass('open')

  $('#close_all').click ->
    $('#migration_status tr').removeClass('open')

  $('#create_model_form').dialog
    autoOpen: false,
    height: 450,
    width: 450,
    modal: true,
    buttons:
      'Create Model': ->
        model = $('#new_model_name').val()
        columns = ''
        $('#create_model_table > tbody > tr').each (i, row) ->
          [name, type] = ($(v).val() for v in $(row).find('input'))
          columns += "#{name}#{if type then ":#{type}" else ''} " if name
        window.erd.upsert_change 'create_model', model, columns, '', ''
        $(this).find('table > tbody > tr').each (i, row) ->
          row.remove() if i >= 1
        $(this).find('input').val('')
        $(this).find('input[name=new_model_column_type_1]').val('string')

        $(this).dialog('close')
      Cancel: ->
        $(this).dialog('close')

  $('#open_create_model_dialog').click (ev) ->
    ev.preventDefault()
    $('#create_model_form').dialog('open')
