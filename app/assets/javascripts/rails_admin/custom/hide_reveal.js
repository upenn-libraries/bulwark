$(document).ready(function(){
  $(function() {
    $('.wait').addClass('hide');
    $(".xml-preview").removeClass("hide");
  });
	$("#edit_metadata_builder_1").submit(function(){
      $(".wait").removeClass("hide");
      $(".xml-preview").addClass("hide");
	});
});
