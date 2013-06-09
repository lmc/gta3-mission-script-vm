$ ->
  vm_client = new VmClient
  vm_client.init()


class VmClient
  constructor: () ->
    @cpu = {}

    @memory = []
    @memory_size = 0
    @memory_view_start = 200000
    @memory_view_window = 512
    @memory_inspect_at = 110000

  init: ->
    @btn_tick = $('#btn-tick')
    @btn_tick.on('click',@btn_tick_click)
    @btn_reset = $('#btn-reset')
    @btn_reset.on('click',@btn_reset_click)

    @memory_el = $('#memory .contents')
    @memory_window = @memory_el.find('span').length / 2
    @memory_inspect_el = $('#memory .inspect')
    @memory_inspect_pos_el = $('#memory #memory_inspect_at')
    @memory_inspect_pos_el.val(@memory_inspect_at)

    @memory_do_inspect = $('#memory #memory_do_inspect')
    @memory_do_inspect.on('click',@memory_do_inspect_click)

    @memory_els = $('#memory .contents')
    @memory_els.on('click',@memory_els_click)

    @memory_addresses_el = $('#memory .contents_addresses')


    @btn_memory_view_start = $('#memory_start')
    @btn_memory_view_start.val(@memory_view_start)
    @btn_memory_view_window = $('#memory_window')
    @btn_memory_view_window.val(@memory_view_window)
    @btn_memory_view_update = $('#btn-memory-update')
    @btn_memory_view_update.on('click',@btn_memory_view_update_click)

    @btn_memory_view_update.click()
    setTimeout(( => @memory_do_inspect.click() ), 100 )


    true

  check_and_resize_memory: (start,size) =>
    end = start + size
    if end > @memory_size
      for pos in [@memory_size..end]
        @memory.push(0)
      @memory_size = end

  btn_tick_click: (event) =>
    event.preventDefault()

    console.log("tick")
    $.ajax("/tick").
    success( (data) =>
      console.log(data)
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
    )

    false

  btn_reset_click: (event) =>
    console.log("reset")
    $.ajax("/reset").complete( => window.location = window.location );

  btn_memory_view_update_click: (event) =>
    event.preventDefault()

    @memory_view_start  = parseInt( @btn_memory_view_start.val() )
    @memory_view_window = parseInt( @btn_memory_view_window.val() )

    @memory_addresses_el.html("")
    @memory_el.html("<div class='progress progress-striped active'><div class='bar' style='width: 100%'></div></div>")

    low = @memory_view_start - @memory_view_window
    low = 0 if low < 0
    high = @memory_view_start + @memory_view_window
    # high = @memory_size if high > @memory_size

    console.log("low: #{low} - high: #{high}")
    $.ajax("/memory/#{low}/#{high}").success( (data) =>
      @memory_el.html(data)
      @memory_raw_el = $('#memory #memory_break_on_instructions')
      if !@memory_raw_el.prop("checked")
        @memory_el.addClass("break-on-instruction-begin")
      else
        @memory_el.removeClass("break-on-instruction-begin")
      @build_memory_contents_addresses()
    )

    false

  build_memory_contents_addresses: =>
    @memory_addresses_el.html("")

    first_mem_left = @memory_el.find('span.instruction_name + span.mem').first().css("background-color","#000").position().left
    for el in @memory_el.find('span.mem')
      el = $(el)
      console.log("first_mem_left: #{first_mem_left}, el.position().left: #{el.position().left}")
      if el.position().left == first_mem_left
        console.log(el)
        console.log(el[0].className)
        if matches = el[0].className.match(/pos_(\d+)/)
          pos = parseInt(matches[1])
          addr_el = $("<span>#{pos}</span>")
          @memory_addresses_el.append(addr_el)

  memory_els_click: (event) =>
    console.log("memory_els_click")
    memory_el = $(event.target)
    event.preventDefault()

    if matches = event.target.className.match(/pos_(\d+)/)
      pos = matches[1]
      @memory_inspect_at = parseInt(pos)
      @memory_inspect_pos_el.val(@memory_inspect_at)
      @do_inspect_at(@memory_inspect_at)



  memory_do_inspect_click: (event) =>
    event.preventDefault()
    @memory_inspect_at = parseInt( @memory_inspect_pos_el.val() )
    @do_inspect_at(@memory_inspect_at)

  do_inspect_at: (pos) =>
    console.log("do_inspect_at: #{pos}")
    $.ajax("/inspect/#{pos}").success( (data) =>
      @memory_inspect_el.html(data)
      memory_el = @memory_el.find(".pos_#{pos}")
      # console.log(memory_el)
      # memory_el.click()
      @memory_el.find(".inspect_pos").removeClass("inspect_pos")
      @memory_el.find(".inspect_instruction").removeClass("inspect_instruction")

      # memory_el.get(0).scrollIntoView()
      memory_el.addClass("inspect_pos")
      # FIXME: breaks awfully if clicked on last instruction of editor
      if memory_el.hasClass("instruction")
        prev = memory_el
        until prev.hasClass("instruction_begin") || prev.hasClass("instruction_name")
          prev.addClass("inspect_instruction")
          prev = prev.prev()

        # HACK:
        if prev.hasClass("instruction_name")
          prev = prev.next().next()

        prev.addClass("inspect_instruction")
        prev = prev.prev()
        if prev.hasClass("instruction_name")
          prev.addClass("inspect_instruction")
        next = memory_el.next()
        until next.hasClass("instruction_begin") || next.hasClass("instruction_name")
          next.addClass("inspect_instruction")
          next = next.next()
    )

  hex: (byte) =>
    if byte then byte.toString(16).replace(/^([0-9a-f])$/,"0$1").toUpperCase() else "00"
