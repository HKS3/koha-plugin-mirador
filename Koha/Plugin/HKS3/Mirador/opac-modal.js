$(document).ready(function() {
    const mirador_page = $('body').attr('ID');
    console.log(mirador_page);
    if (mirador_page == "opac-detail") {
        var x = document.getElementsByClassName("unapi-id")[0]
                    .getAttribute("title");
            biblionumber = x.split(':')[2];
        addTab(biblionumber, 'opac');           
    }
    else if (mirador_page == "catalog_detail") {
        // console.log('alread set ',biblionumber); 
        // intranet
    } 

    function addTab(biblionumber) {    
        console.log('add tab');
        var tab_classname = 'bibliodescriptions';   
        
        $("#tab_volumes").show();
        
        $(function(e) {
            var ajaxData = { 'biblionumber': biblionumber };
            $.ajax({
              url: '/api/v1/contrib/hks3_mirador/iiifmanifest',
            type: 'GET',
            dataType: 'json',
            data: ajaxData,
        })
        .done(function(data) {
            console.log('using mirador really');            
            var volumes_table =`<div class="row" id="mirador" style="width: 800px; height: 600px;"></div>`;
            //var tabs = $('#'+tab_classname+' ul')
            //    .append('<li id="tab_volumes"><a id="vol_label" href="#volumes">Volume</a></li>');
            
            // breadcrumbs document.querySelector("#breadcrumbs")
            // var volumes = $("#breadcrumbs").after(volumes_table);                   
            // var volumes = $("#catalogue_detail_biblio > div.record > h1")
            $("body").append(`
            <div class="modal" id="miradorModal" tabindex="-1" aria-labelledby="miradorModalLabel"
             aria-hidden="true"><div class="modal-dialog modal-dialog-centered modal-dialog-scrollable"
             ><div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="miradorModalLabel">Mirador Header</h5>
                    <button type="button" class="closebtn" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                    </div><div class="modal-body">
                        <div id="mirador">Mirador Body</div></div>
                        <div class="modal-footer"><button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                        </div></div></div></div>

                        <section class="numerisation">
    <div class="row">
        
        <div class="col-md-6">
          
            <p class="iiif-collection-label"><strong>IIIF Manifest</strong></p>
          
            <div class="numerisation-iiif">
                <a class="icon-iiif " role="button" tabindex="0" href="https://api.irht.cnrs.fr/ark:/63955/fthdrzs3uxab/manifest.json?iiif-content=https://api.irht.cnrs.fr/ark:/63955/fthdrzs3uxab/manifest.json" rel="nofollow noopener noreferrer" data-toggle="popover" data-manifest="https://api.irht.cnrs.fr/ark:/63955/fthdrzs3uxab/manifest.json" data-iiif-content="https://api.irht.cnrs.fr/ark:/63955/fthdrzs3uxab/manifest.json" title="" data-original-title="Document compliant with IIIF standards">
                    <img src="https://portail.biblissima.fr/data/8d0d27acb7b0c6e6fc1a1968e7514c86/img/logo-iiif.png" alt="IIIF Drag and Drop Icon" width="24" height="24">
                </a>
                <input value="https://api.irht.cnrs.fr/ark:/63955/fthdrzs3uxab/manifest.json" id="iiifUrl" readonly="">
                <button class="clipboard manual-tooltip" data-toggle="tooltip" data-clipboard-target="#iiifUrl" aria-label="Copy to clipboard" data-original-title="Copy to clipboard" title=""><span class="fa fa-clipboard" aria-hidden="true"></span></button>
            </div>
            
        </div>
        
        
        <div class="col-md-6 clearfix numerisation-surrogate">
          
          <p><strong>Digitisation: </strong></p>
          <ul>
            
            <li><a href="https://arca.irht.cnrs.fr/ark:/63955/md92g732h349">https://arca.irht.cnrs.fr/ark:/63955/md92g732h349</a></li>
            
          </ul>
        
        </div>
        
    </div>
  </section>
            `);                        
            var miradorInstance = Mirador.viewer({
                id: 'mirador',
                theme: {
                   transitions: window.location.port === '4488' ?  { create: () => 'none' } : {},
                },
                windows: [{
                    // manifestId: '/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber='+biblionumber,
                    manifestId: 'https://api.irht.cnrs.fr/ark:/63955/fthdrzs3uxab/manifest.json',
                    thumbnailNavigationPosition: 'far-bottom'
                }],
                window: {
                    defaultView: 'gallery',
                    // ...other default window settings...
                }
            });               

            $(".results_summary.online_resources").append(`<a role="button" type="button" class="btn btn-secondary" 
                    onclick="$('#miradorModal').modal('show')">open mirador viewer</a>`);
             
            $('#miradorModal').modal('handleUpdate');
        })   
        .error(function(data) {
            console.log('no data found');
        });
        });
    }
})
