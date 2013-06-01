$ ->
  vm_client = new VmClient
  vm_client.init()


class VmClient
  constructor: () ->
    @cpu = {}

    @memory = []
    @memory_size = 0
    @memory_view_start = 0
    @memory_view_size = 1024

  init: ->
    @btn_tick = $('#btn-tick')
    @btn_tick.on('click',@btn_tick_click)
    @btn_reset = $('#btn-reset')
    @btn_reset.on('click',@btn_reset_click)
    @memory_el = $('#memory .contents')
    @memory_size = @memory_el.find('span').length
    @btn_memory_view_start = $('#memory_start')
    @btn_memory_view_start.val(@memory_view_start)
    @btn_memory_view_size = $('#memory_size')
    @btn_memory_view_size.val(@memory_view_size)
    @btn_memory_view_update = $('#btn-memory-update')
    @btn_memory_view_update.on('click',@btn_memory_view_update_click)
    true

  check_and_resize_memory: (start,size) =>
    end = start + size
    console.log("check_and_resize_memory")
    console.log(@memory_size)
    console.log(end)
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
      $('#cpu .contents dd.pc').text(@cpu.pc)
    )

    false

  btn_reset_click: (event) =>
    console.log("reset")
    $.ajax("/reset")
    window.location = window.location;

  btn_memory_view_update_click: (event) =>
    event.preventDefault()

    @memory_view_start = parseInt( @btn_memory_view_start.val() )
    @memory_view_size  = parseInt( @btn_memory_view_size.val() )

    @memory_el.html("")
    for pos in [(@memory_view_start)..(@memory_view_start + @memory_view_size)]
      val = @memory[pos]
      el = $("<span class='pos_#{pos}'>#{@hex(val)}</span> ")
      @memory_el.append(el)

    @memory_el.find(".current_pc").removeClass('current_pc')
    @memory_el.find(".pos_#{@cpu.pc}").addClass('current_pc')

    false

  hex: (byte) =>
    if byte then byte.toString(16).replace(/^([0-9a-f])$/,"0$1").toUpperCase() else "00"
