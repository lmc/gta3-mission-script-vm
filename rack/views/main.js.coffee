$ ->
  vm_client = new VmClient
  vm_client.init()


class VmClient
  constructor: () ->
    @cpu = {}

    @memory = []
    @memory_size = 0
    @memory_view_start = 0
    @memory_view_window = 512

  init: ->
    @btn_tick = $('#btn-tick')
    @btn_tick.on('click',@btn_tick_click)
    @btn_reset = $('#btn-reset')
    @btn_reset.on('click',@btn_reset_click)
    @memory_el = $('#memory .contents')
    @memory_window = @memory_el.find('span').length / 2
    @memory_inspect_el = $('#memory .inspect')
    @memory_els = $('#memory .contents')
    @memory_els.on('click',@memory_els_click)
    @btn_memory_view_start = $('#memory_start')
    @btn_memory_view_start.val(@memory_view_start)
    @btn_memory_view_window = $('#memory_window')
    @btn_memory_view_window.val(@memory_view_window)
    @btn_memory_view_update = $('#btn-memory-update')
    @btn_memory_view_update.on('click',@btn_memory_view_update_click)
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
      for [address,size,data] in data.dirty_memory
        console.log("updating #{address} + #{size}")
        @check_and_resize_memory(address,size)
        for byte, idx in data
          pos = address + idx
          @memory[pos] = byte

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

    @memory_el.html("")

    low = @memory_view_start - @memory_view_window
    low = 0 if low < 0
    high = @memory_view_start + @memory_view_window
    high = @memory_size if high > @memory_size

    console.log("low: #{low} - high: #{high}")
    for pos in [low..high]
      val = @memory[pos]
      el = $("<span class='pos_#{pos}'>#{@hex(val)}</span> ")
      @memory_el.append(el)

    console.log(@cpu.pc)
    @memory_el.find(".current_pc").removeClass('current_pc')
    @memory_el.find(".pos_#{@cpu.pc}").addClass('current_pc')

    false

  memory_els_click: (event) =>
    console.log("memory_els_click")
    event.preventDefault()
    if matches = event.target.className.match(/pos_(\d+)/)
      pos = matches[1]
      $.ajax("/inspect/#{pos}").success( (data) =>
        @memory_inspect_el.html(data)
      )

  hex: (byte) =>
    if byte then byte.toString(16).replace(/^([0-9a-f])$/,"0$1").toUpperCase() else "00"
