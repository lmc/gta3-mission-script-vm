$ ->
  vm_client = new VmClient
  vm_client.init()


class VmClient
  constructor: () ->
    @cpu = {}

    @memory = []
    @memory_size = 0

  init: ->
    @btn_tick = $('#btn-tick')
    @btn_tick.on('click',@btn_tick_click)
    @memory_el = $('#memory .contents')
    true

  check_and_resize_memory: (start,size) =>
    end = start + size
    console.log("check_and_resize_memory")
    console.log(@memory_size)
    console.log(end)
    if end > @memory_size
      for pos in [@memory_size..end]
        el = $('<span>')
        el.addClass("pos_#{pos}")
        el.text('00')
        @memory_el.append(el)

  btn_tick_click: (event) =>
    $.ajax("/tick").
    success( (data) =>
      for [address,size,data] in data.dirty_memory
        @check_and_resize_memory(address,size)
    )
