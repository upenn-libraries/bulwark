$(document).ready(function(){

  $(function() {
    $('.wait').addClass('hide');
    $(".xml-preview").removeClass("hide");
    $(".ingest-dashboard").removeClass("hide");
  });

	$("#xml_preview_submit").click(function(){
    $(".wait").removeClass("hide");
    $(".xml-preview").addClass("hide");
	});

	$("#ingest_select_submit").click(function(){
    $(".wait").removeClass("hide");
    $(".ingest-dashboard").addClass("hide");
	});

});
