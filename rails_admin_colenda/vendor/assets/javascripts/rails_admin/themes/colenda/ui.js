$(document).ready(function(){
  $(function() {
    $('.wait').addClass('hide');
    $(".xml-preview").removeClass("hide");
    $(".ingest-dashboard").removeClass("hide");
  });
	$(".xml-preview-form").submit(function(){
      $(".wait").removeClass("hide");
      $(".xml-preview").addClass("hide");
	});
	$(".ingest-select-form").submit(function(){
      $(".wait").removeClass("hide");
      $(".ingest-dashboard").addClass("hide");
	});
});
