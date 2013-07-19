$ ->
  vm_client = new VmClient
  vm_client.init()

class MemoryViewer
  constructor: (@memory_el) ->


class VmClient
  constructor: () ->
    @cpu = {}

    @memory = []
    @memory_size = 0
    @memory_view_start = 200000
    @memory_view_window = 128
    @memory_view_window_a = 256 # add after
    @memory_inspect_at = 110000

  init: ->
    return if $('#vm-exception').length > 0

    @btn_tick = $('#btn-tick')
    @btn_tick.on('click',@btn_tick_click)
    @btn_reset = $('#btn-reset')
    @btn_reset.on('click',@btn_reset_click)

    @checkbox_tick_auto = $('#btn-auto-tick')

    # new MemoryViewer()
    @memory_template = $('#memory_template')
    @memory_template.remove()

    @memory_el = $('.memory .contents')
    @memory_window = @memory_el.find('span').length / 2
    @memory_inspect_el = $('.memory .inspect')
    @memory_inspect_pos_el = $('.memory .memory_inspect_at')
    # @memory_inspect_pos_el.val(@memory_inspect_at)

    @memory_do_inspect = $('.memory .memory_do_inspect')
    @memory_do_inspect.on('click',@memory_do_inspect_click)

    @memory_els = $('.memory .contents')
    @memory_els.on('click',@memory_els_click)

    @memory_addresses_el = $('.memory .contents_addresses')
    @memory_addresses_el.on('click',@memory_els_click)


    @btn_memory_view_start = $('.memory_start')
    @btn_memory_view_start.val(@memory_view_start)
    @btn_memory_view_window = $('.memory_window')
    @btn_memory_view_window.val(@memory_view_window)
    @btn_memory_view_update = $('.btn-memory-update')
    @btn_memory_view_update.on('click',@btn_memory_view_update_click)

    # @btn_memory_view_update.click()
    # setTimeout(( => @memory_do_inspect.click() ), 100 )

    @auto_tick_ok = true
    @auto_tick_timer = setInterval( ( =>
      return if $('#vm-exception').length > 0
      return if !$('#btn-auto-tick').prop('checked')
      return if !@auto_tick_ok
      @auto_tick_ok = false
      @btn_tick.click()
      # $('#error').get(0).scrollIntoView()
    ), 20 )

    true

  check_and_resize_memory: (start,size) =>
    end = start + size
    if end > @memory_size
      for pos in [@memory_size..end]
        @memory.push(0)
      @memory_size = end

  update_variables_html: (data) =>
    return
    if data.variables_html
      $('#variables .variables').html(data.variables_html)

  update_thread_html: (data) =>
    console.log("update_thread_html data")
    console.log(data)
    force_refresh = false
    $.each data.thread_html, (id,html) =>
      if $("#threads #thread_#{id}").length == 0
        force_refresh = true

    $('.thread').addClass('muted')
    $.each data.thread_html, (id,html) =>
      thread_el = $("#threads #thread_#{id}")

      # console.log("update_thread_html: thread_el.length: #{thread_el.length}")
      if thread_el.length == 0
        thread_el = $("<div><div class='data'></div><div class='memory'></div></div>")
        thread_el.attr('id',"thread_#{id}")
        thread_el.addClass("thread").addClass("well")
        thread_el.find('.memory').html(@memory_template.html())
        thread_el.find('.memory .contents').on('click',@memory_els_click)
        thread_el.find('.memory .contents_addresses').on('click',@memory_els_click)

        $('#threads').append(thread_el)
      thread_el.find('.data').html(html)

      thread_el.find('.memory_inspect_at').val( data.thread_pcs[id] )
      thread_el.find('.memory_start').val( data.thread_pcs[id] )
      thread_el.find('.memory_window').val( @memory_view_window )

      console.log("force_refresh: #{force_refresh}")
      if force_refresh
        @btn_memory_view_update_click(null,thread_el.find('.btn-memory-update'))
        # setTimeout( ( => thread_el.find(".memory .contents .pos_#{data.thread_pcs[id]}").click() ), 1250)

      # console.log("id: #{id}, thread_id: #{data.thread_id}")
      if id == data.thread_id
        # console.log(data.current_instruction_inspect)
        # if !force_refresh
          # @btn_memory_view_update_click(null,thread_el.find('.btn-memory-update'))
        thread_el.removeClass('muted')

        if thread_el.find(".memory .contents_addresses .pos_#{data.thread_pcs[id]}").length == 0
          @btn_memory_view_update_click(null,thread_el.find('.btn-memory-update'))
        else
          @update_memory_inners(thread_el.find('.memory'))
        thread_el.find('.inspect').html(data.current_instruction_inspect)


  btn_tick_click: (event) =>
    event.preventDefault()

    if $('#vm-exception').length > 0
      return

    console.log("===")
    console.log("")
    console.log("tick")
    $.ajax("/tick").
    success( (data) =>
      # handle (presumed) vm exceptions
      if typeof(data) != "object"
        console.log("doing vm exception: #{@auto_tick_ok}")
        return unless @auto_tick_ok
        error_div = $("<div class='alert alert-block alert-error' id='vm-exception'></div>")
        error_div.html(data)
        @auto_tick_ok = false
        clearInterval(@auto_tick_timer)
        $('#error').append(error_div)

      else

        # dirty memory
        # for [address,size,data] in data.dirty_memory
        for [address,size] in data.dirty_memory
          console.log("updating #{address} + #{size}")
          @check_and_resize_memory(address,size)
          # for byte, idx in data
          #   pos = address + idx
          #   @memory[pos] = byte

        # cpu state updates
        @cpu.pc = data.pc
        $('#cpu .contents').html(data.cpu)

        @update_thread_html(data)
        @update_variables_html(data)

        @auto_tick_ok = true
    )

    false

  btn_reset_click: (event) =>
    console.log("reset")
    $.ajax("/reset").complete( => window.location = window.location );

  btn_memory_view_update_click: (event,target) =>
    console.log("btn_memory_view_update_click")
    event.preventDefault() if event

    target = if event then event.target else target

    memory_el = $(target).parents(".memory")

    memory_view_start  = parseInt( memory_el.find('.memory_start').val() )
    memory_view_window = parseInt( memory_el.find('.memory_window').val() )

    # console.log("memory_view_start: #{memory_view_start}")

    contents_el = memory_el.find('.contents')
    addresses_el = memory_el.find('.contents_addresses')
    # addresses_el.html("")
    # contents_el.html("<div class='progress progress-striped active'><div class='bar' style='width: 100%'></div></div>")

    low = memory_view_start - memory_view_window
    low = 0 if low < 0
    high = memory_view_start + memory_view_window + @memory_view_window_a

    # console.log("low: #{low} - high: #{high}")
    $.ajax("/memory/#{low}/#{high}").success( (data) =>
      contents_el.html(data)
      memory_raw_el = memory_el.find('.memory_break_on_instructions')
      if !memory_raw_el.prop("checked")
        contents_el.addClass("break-on-instruction-begin")
      else
        contents_el.removeClass("break-on-instruction-begin")

      @build_memory_contents_addresses(memory_el)

      @update_memory_inners(memory_el)
    )

    false


  update_memory_inners: (memory_el) =>
    contents_el = memory_el.find('.contents')
    addresses_el = memory_el.find('.contents_addresses')

    pc = parseInt( memory_el.parent().find('td.pc').text() )
    thread_id = parseInt( memory_el.parent().find('td.id').text() )
    contents_el.find(".current_instruction").removeClass("current_instruction")
    addresses_el.find(".current_instruction").removeClass("current_instruction")
    # contents_el.find(".pos_#{pc}").addClass("current_instruction")
    c_inst_el = contents_el.find(".pos_#{pc}")
    if c_inst_el.length > 0
      c_inst_el.addClass("current_instruction")
      addresses_el.find(".pos_#{pc}").addClass("current_instruction")
      # if thread_id < 7
      address_el = addresses_el.find(".pos_#{pc}")
      ahead = 1
      while ahead-- >= 0 and address_el.next().is('.address')
        address_el = address_el.next()
      address_el.scrollIntoView({duration: 0,offset: 20})

      if c_inst_el.prev().hasClass("instruction_name")
        c_inst_el.prev().addClass("current_instruction")

      next_el = c_inst_el.next()
      until !next_el.is('span') or next_el.hasClass('instruction_begin') or next_el.hasClass('instruction_name')
        next_el.addClass('current_instruction')
        next_el = next_el.next()



  build_memory_contents_addresses: (memory_el) =>
    memory_addresses_el = memory_el.find('.contents_addresses')
    contents_el = memory_el.find('.contents')
    memory_addresses_el.html("")

    first_mem_left = contents_el.find('span.instruction_name + span.mem').first().css("color","#000").position().left
    for el in contents_el.find('span.mem')
      el = $(el)
      # console.log("first_mem_left: #{first_mem_left}, el.position().left: #{el.position().left}")
      if el.position().left == first_mem_left
        if matches = el[0].className.match(/pos_(\d+)/)
          pos = parseInt(matches[1])
          addr_el = $("<span class='address pos_#{pos}'>#{pos}</span>")
          memory_addresses_el.append(addr_el)

  memory_els_click: (event) =>
    console.log("memory_els_click")
    memory_el = $(event.target).parents('.memory')
    event.preventDefault()

    element = event.target

    if element.className.match(/instruction_name/)
      element = $(element).next('.instruction')[0]

    # console.log("className: #{element.className}")
    if matches = element.className.match(/pos_(\d+)/)
      pos = matches[1]

    if pos
      memory_inspect_at = parseInt(pos)
      # console.log("memory_inspect_at: #{memory_inspect_at}")
      memory_el.find('.memory_inspect_at').val(memory_inspect_at)
      @do_inspect_at(memory_el,memory_inspect_at)



  # memory_do_inspect_click: (event) =>
  #   console.log("memory_do_inspect_click")
  #   event.preventDefault()
  #   @memory_inspect_at = parseInt( @memory_inspect_pos_el.val() )
  #   @do_inspect_at(@memory_inspect_at)

  do_inspect_at: (memory_el,pos) =>
    console.log("do_inspect_at: #{pos}")
    $.ajax("/inspect/#{pos}").success( (data) =>
      # @memory_inspect_el.html(data)
      memory_el.find('.inspect').html(data)
      contents_el = memory_el.find('.contents')
      pos_el = contents_el.find(".pos_#{pos}")
      # console.log(memory_el)
      # memory_el.click()
      contents_el.find(".inspect_pos").removeClass("inspect_pos")
      contents_el.find(".inspect_instruction").removeClass("inspect_instruction")

      memory_el.scrollIntoView({duration: 0})
      pos_el.addClass("inspect_pos")
      if pos_el.hasClass("instruction")
        prev = pos_el
        until !prev.is('span') or prev.hasClass("instruction_begin") or prev.hasClass("instruction_name")
          prev.addClass("inspect_instruction")
          prev = prev.prev()

        # HACK:
        if prev.hasClass("instruction_name")
          prev = prev.next().next()

        prev.addClass("inspect_instruction")
        prev = prev.prev()
        if prev.hasClass("instruction_name")
          prev.addClass("inspect_instruction")
        next = pos_el.next()
        until next.hasClass("instruction_begin") || next.hasClass("instruction_name")
          next.addClass("inspect_instruction")
          next = next.next()
    )

  hex: (byte) =>
    if byte then byte.toString(16).replace(/^([0-9a-f])$/,"0$1").toUpperCase() else "00"
