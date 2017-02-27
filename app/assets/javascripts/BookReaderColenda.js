//
// This file shows the minimum you need to provide to BookReader to display a book
//
// Copyright(c)2008-2009 Internet Archive. Software license AGPL version 3.

function getParameterByName(name, url) {
    if (!url) {
        return
    }
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

// Create the BookReader object
br = new BookReader();


// Return the width of a given page.
br.getPageWidth = function(index) {
    number = parseInt(getParameterByName('width',br.pages[index]));
    if(number <= 250){
        calculatedNumber = number;
    } else {
        calculatedNumber = 250;
    }
    return calculatedNumber;
}

// Return the height of a given page.
br.getPageHeight = function(index) {
    width = parseInt(getParameterByName('width',br.pages[index]));
    height = parseInt(getParameterByName('height',br.pages[index]));
    return (height/width)*250;
}

// We load the images from archive.org -- you can modify this function to retrieve images
// using a different URL structure
br.getPageURI = function(index, reduce, rotate) {
    // reduce and rotate are ignored in this simple implementation, but we
    // could e.g. look at reduce and load images from a different directory
    // or pass the information to an image server
    var leafStr = '000';
    var imgStr = (br.pages[index]).toString();
    var re = new RegExp("0{"+imgStr.length+"}$");
    var url = imgStr;
    return url;
}

// Return which side, left or right, that a given page should be displayed on
br.getPageSide = function(index) {
    if (0 == (index & 0x1)) {
        return 'R';
    } else {
        return 'L';
    }
}

br.canRotatePage = function() { }
br.getPageNum = function() { }

// This function returns the left and right indices for the user-visible
// spread that contains the given index.  The return values may be
// null if there is no facing page or the index is invalid.
br.getSpreadIndices = function(pindex) {
    var spreadIndices = [null, null];
    if ('rl' == this.pageProgression) {
        // Right to Left
        if (this.getPageSide(pindex) == 'R') {
            spreadIndices[1] = pindex;
            spreadIndices[0] = pindex + 1;
        } else {
            // Given index was LHS
            spreadIndices[0] = pindex;
            spreadIndices[1] = pindex - 1;
        }
    } else {
        // Left to right
        if (this.getPageSide(pindex) == 'L') {
            spreadIndices[0] = pindex;
            spreadIndices[1] = pindex + 1;
        } else {
            // Given index was RHS
            spreadIndices[1] = pindex;
            spreadIndices[0] = pindex - 1;
        }
    }

    return spreadIndices;
}

// For a given "accessible page index" return the page number in the book.
//
// For example, index 5 might correspond to "Page 1" if there is front matter such
// as a title page and table of contents.
br.getPageNum = function(index) {
    return index+1;
}

// Book title and the URL used for the book title link
br.bookTitle= 'Page Turning View';
// Override the path used to find UI images
br.imagesBaseURL = '/vendor/assets/javascripts/bookreader/BookReader/images/';
br.bookUrl  = '';

br.getEmbedCode = function(frameWidth, frameHeight, viewParams) {
    return "Embed code not supported in bookreader.";
}

br.renderViewer = function() {
  br.pages = jQuery.parseJSON($("#pages").attr("data"));
  br.numLeafs = br.pages.length;
  br.init();
  $('#BRtoolbar').find('.read').hide();
  $('#textSrch').hide();
  $('#btnSrch').hide();
  /* Undo the aggressive title changing from BookReader */
  document.title = $('#content h1').text();
}
