$(document).ready(function(){
    // Select or deselect all digital objects on index page.
    $('#select-all').click(function() {
        // Grouping all the checkbox using the classname
        // Set the checked status to match the status of the select all checkbox
        $(".digital-object-checkbox").prop('checked', this.checked).change();
    });

    // Highlight all selected digital object rows in green
    $('.digital-object-checkbox').change(function() {
        if (this.checked) {
            $(this).closest("tr").addClass("success")
        } else {
            $(this).closest("tr").removeClass("success")
        }
    });
});