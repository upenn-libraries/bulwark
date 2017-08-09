renderViewer = function() {
    imagesArray = jQuery.parseJSON($("#pages").attr("data"));
    var viewer = OpenSeadragon({
        id: "openseadragon",
        prefixUrl: "/assets/",
        preserveViewport: true,
        constrainDuringPan: true,
        visibilityRatio:    1,
        showNavigator:  true,
        navigatorPosition:   "TOP_RIGHT",
        minZoomLevel:       0.25,
        defaultZoomLevel:   1.05,
        sequenceMode:       true,
        showReferenceStrip: true,
        referenceStripScroll: "horizontal",
        tileSources: imagesArray
    });
    return viewer;
}