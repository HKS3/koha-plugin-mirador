$(document).ready(function() {
    const mirador_page = $('body').attr('ID');
    if (mirador_page == "opac-detail") {
        var x = document.getElementsByClassName("unapi-id")[0]
                    .getAttribute("title");
            biblionumber = x.split(':')[2];
        addMirador(biblionumber, 'opac');
    }
    else if (mirador_page == "catalog_detail") {
        // console.log('alread set ',biblionumber);
        // intranet
    }

    function addMirador(biblionumber) {
        $(function(e) {
            var ajaxData = { 'biblionumber': biblionumber };
            $.ajax({
                url: '/api/v1/contrib/hks3_mirador/iiifmanifest',
                type: 'GET',
                dataType: 'json',
                data: ajaxData,
            })
            .done(function(data) {
                console.log('using mirador opac.js');
                // $("#catalogue_detail_biblio > div.record").append(`
                let fullUrl = `${window.location.origin}/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber=${biblionumber}`;
                $("div.col-lg-3:has(> div#ulactioncontainer)").prepend(`
                    <div style="background-color: #F5F5F5; padding: 0.5em;">
                        <h5> IIIF Manifest </h5>
                        <div width="100%" style="display: flex;">
                            <input type="text"
                                editable=false
                                style="flex-grow: 1;"
                                value="${fullUrl}"
                            >
                                <button type="button"
                                    onclick="navigator.clipboard.writeText('${fullUrl}')"
                                    class="btn btn-secondary"
                                >
                                    Copy
                                </button>
                            </input>
                        </div>
                    </div>
                `);
                $("div.col-lg-3:has(> div#ulactioncontainer)").prepend(`
                   <iframe src="/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber=`+biblionumber+`&viewer=1"
                   style='width: 100%; aspect-ratio: 4/3'
                   marginwidth="0" marginheight="0" frameborder="0" scrolling="no" id="frame" allowfullscreen="">
                   <div id="mirador">Mirador Body</div>
                   </iframe>
                `);
            })
            .error(function(data) {
                console.log('no data found');
            });
        });
    }
})

