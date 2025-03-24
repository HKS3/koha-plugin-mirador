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
            console.log('using mirador opac.js');            
            var volumes_table =`<div class="row" id="mirador" style="width: 800px; height: 600px;"></div>`;
            //var tabs = $('#'+tab_classname+' ul')
            //    .append('<li id="tab_volumes"><a id="vol_label" href="#volumes">Volume</a></li>');
            
            // breadcrumbs document.querySelector("#breadcrumbs")
            // var volumes = $("#breadcrumbs").after(volumes_table);                   
            // var volumes = $("#catalogue_detail_biblio > div.record > h1")
            
            $("#catalogue_detail_biblio > div.record").append(`
               <iframe src="/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber=`+biblionumber+`&viewer=1" width="800" height="600" 
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

