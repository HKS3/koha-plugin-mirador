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
            const style = document.createElement('style');
            if (showInSidebar) {
                style.innerText = `
                iframe#mirador {
                    width: 100%;
                    aspect-ratio: 4/3;
                }
                `;
            } else {
                style.innerText = `
                iframe#mirador {
                    width: 800px;
                    height: 600px;
                }
                div#miradorManifestUrl {
                    width: 800px;
                }
                `;
            }
            document.head.appendChild(style);
            const iframe = `
               <iframe src="/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber=`+biblionumber+`&viewer=1"
                   marginwidth="0" marginheight="0" frameborder="0" scrolling="no" id="mirador" allowfullscreen=""
               >
                   <div id="mirador">Mirador Body</div>
               </iframe>
            `;
            if (showInSidebar) {
                $("div.col-lg-3:has(> div#ulactioncontainer)").prepend(iframe);
            } else {
                $("#catalogue_detail_biblio > div.record").append(iframe);
            }
            if (showManifestUrl) {
                let fullUrl = `${window.location.origin}/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber=${biblionumber}`;
                const manifestUrl =  `
                    <div id="miradorManifestUrl" style="background-color: #F5F5F5; padding: 0.5em;">
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
                `;
                if (showInSidebar) {
                    // $("div.col-lg-3:has(> div#ulactioncontainer)").prepend(manifestUrl);
                    $("iframe#mirador").after(manifestUrl);
                } else {
                    $("#catalogue_detail_biblio > div.record").append(manifestUrl);
                }
            }
        })
        .error(function(data) {
            console.log('no data found');
        });
    });
}
