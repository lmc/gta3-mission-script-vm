$(document).ready(function(){
  
  $('#tick_form').live("submit",function(){
    $.get("/tick",function(response){

      $.each(response.segments,function(segment_id,html){
        var element = document.getElementById("segment_"+segment_id);
        if(element){
          element.innerHTML = html;
        }else{
          //alert("No element for segment: #segment_"+segment_id);
          alert("No element for segment: "+segment_id);
        }
      });
      console.log(response.dirty_memory_addresses);
      $.each(response.dirty_memory_addresses,function(_i,dirty_mem){
        var dirty_row = $(".memory_row_address_"+dirty_mem[0]);
        dirty_row.replaceWith(dirty_mem[1]);
      });
      init_memory_features();

    })
    return false;
  });


  // $('.hl_address').live("mouseover",function(ev){
  //   var element = ev.target;
  //   var address = element.className.match(/hl_address_(\d+)/);
  //   if(!address) return;
  //   address = address[1];
  //   var matched = $('.hl_address_'+address);
  //   matched.addClass("hover");
  // });

  // $('.hl_address').live("mouseout", function(ev){
  //   var element = ev.target;
  //   var address = element.className.match(/hl_address_(\d+)/);
  //   if(!address) return;
  //   address = address[1];
  //   var matched = $('.hl_address_'+address);
  //   matched.removeClass("hover");
  // });

  $('.hl_address a').live("click", function(ev){
    var element = $(ev.target);
    var address = element.parent('.hl_address')[0].className.match(/hl_address_(\d+)/)[1];
    var memory_element = $('#segment_memory .address_'+address);
    console.log('#segment_memory .address_'+address);
    memory_element[0].scrollIntoView();
  });


  var zoom_manager_el_id = '.map_holder';
  var zoom_manager_zoom = 1.0;
  var zoom_manager_width_px = 1200;
  var zoom_manager_height_px = 1200;

  $('.zoom_manager button').live("click",function(ev){
    var map = $(zoom_manager_el_id);
    var zoom = 1.0;
    var text = $(ev.target).text();
    switch(text){
      case "1":
        zoom_manager_zoom = 0.2; break;
      case "2":
        zoom_manager_zoom = 0.5; break;
      case "3":
        zoom_manager_zoom = 1.0; break;
    }
    map.css('zoom',zoom_manager_zoom);
  });

  $('.hl_render').live("click",function(ev){
    $(ev.target).hl_render();
  })

  var origin = { x: 3000.0, y: 3000.0 }; //coords render offset
  var origind = { x: 1.0, y: -1.0 };
  var coords2px = function(x,y){ return {x: ((x*origind.x)+origin.x), y: ((y*origind.y)+origin.y)}; };
  var render_types = {
    point_3d: function(layer_div,args){
      var div = $('<div>');
      div.addClass('render_target');
      var pos = coords2px(args[0],args[1]);

      var icon_width = 16, icon_height = 16;
      var icon_x = pos.x - (icon_width/2), icon_y = pos.y - (icon_height/2);
      div.css('left',pos.x).css('top',pos.y).css('width',icon_width).css('height',icon_height);

      var scroll_x = pos.x - (zoom_manager_width_px/2), scroll_y = pos.y - (zoom_manager_height_px/2);
      $('.map_outer').scrollTo({left: ''+scroll_x+'px', top: ''+scroll_y+'px'},500);

      layer_div.prepend(div);
      return div;
    }
  };
  $.fn.hl_render = function(el){
    var row = this.parent(".hl_render");
    var render_type = row.data('render-type');
    var render_args = row.data('render-args');

    if(row[0].render_target){
      row[0].render_target.remove();
    }

    var layer_div = $('.map_holder .layers');
    row[0].render_target = render_types[render_type](layer_div,render_args);
    console.log(row[0].render_target);
  };

  var init_memory_features = function(){
    $('.memory table a.allocated').popover({
      placement: "top",
      title: function(){ return $(this).data("native"); },
      content: function(){
        $this = $(this);
        var data_type = $this.data("data_type");
        var variable_label;
        var s = "";
          s += "<dl>";
          s += "<dt>Data type</dt><dd>"+data_type+" "+dt_shorthands[data_type]+"</dd>";
          if($this.data("allocation_id")){
            s += "<dt>Game object</dt><dd>"+$this.data("allocation_id")+"</dd>";
          }
          if(variable_label = variable_labels[$this.data("address")]){
            s += "<dt>Label</dt><dd>"+variable_label+"</dd>";
          }
          s += "</dl>";
          console.log()
        return s;
      }
    });
  };
  init_memory_features();

});