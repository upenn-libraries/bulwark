$(document).on("input change", "#scaling", function() {
    $("#preview-thumbnails li img").css('width', $(this).val());
    $("#spacer").css('width', $(this).val());
});

$(document).on("click", "#off-by-one", function(){
    if(this.checked) {
        $("#spacer").removeClass("hide");
    } else {
        $("#spacer").addClass("hide");
    }
});

