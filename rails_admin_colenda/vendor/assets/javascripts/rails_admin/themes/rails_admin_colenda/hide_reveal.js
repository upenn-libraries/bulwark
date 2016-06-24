$(document).on("click","#xml_preview_submit", function() {
  $(".wait").removeClass("hide");
  $(".xml-preview").addClass("hide");
});

$(document).on("click","#ingest_select_submit", function() {
  $(".wait").removeClass("hide");
  $(".ingest-dashboard").addClass("hide");
});
