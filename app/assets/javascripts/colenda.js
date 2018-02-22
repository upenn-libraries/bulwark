renderViewer = function() {
    imagesArray = jQuery.parseJSON($("#pages").attr("data"));
    assetsHash = jQuery.parseJSON($("#navImages").attr("data"));
    var viewer = OpenSeadragon({
        id: "openseadragon",
        prefixUrl: '',
        preserveViewport: true,
        constrainDuringPan: true,
        visibilityRatio:    1,
        showNavigator:  true,
        navigatorPosition:   "TOP_RIGHT",
        minZoomLevel:       0.25,
        defaultZoomLevel:   1.05,
        sequenceMode:       true,
        showReferenceStrip: true,
        showRotationControl: true,
        referenceStripScroll: "horizontal",
        tileSources: imagesArray,
        navImages: assetsHash
    });
    return viewer;
}