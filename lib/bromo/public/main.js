
$(document).ready(function(){

    $("#reload_rc_btn").click(function(event){

        var target = $(event.target);
        target.attr("disabled","disabled");

        $.ajax({
            url: "/reload_rc",
            complete: function(xhr, status){
              target.removeAttr("disabled");
              location.reload();
            }
          });

    })

  $(".redownload").click(function(event){
      var target = $(event.target);
      var id = target.attr("id");
      target.attr("disabled","disabled");

      if(id){
        $.ajax({
            url: "/redownload?id="+id,
            complete: function(xhr, status){
              target.removeAttr("disabled");
              location.reload();
            }
          });
      }
  })

})

