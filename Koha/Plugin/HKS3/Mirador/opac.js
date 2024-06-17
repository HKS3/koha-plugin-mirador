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
            var ajaxData = { 'bn': biblionumber };
            $.ajax({
              url: '/api/v1/contrib/hks3_mirador/biblionumbers',
            type: 'GET',
            dataType: 'json',
            data: ajaxData,
        })
        .done(function(data) {
            console.log('using mirador');            
            var volumes_table =`<div class="row" id="mirador" style="width: 800px; height: 600px;"></div>`;
            //var tabs = $('#'+tab_classname+' ul')
            //    .append('<li id="tab_volumes"><a id="vol_label" href="#volumes">Volume</a></li>');
            
            // #breadcrumbs document.querySelector("#breadcrumbs")
            var volumes = $("#breadcrumbs")            
            // var volumes = $("#catalogue_detail_biblio > div.record > h1")
                .after(volumes_table);       
            var miradorInstance = Mirador.viewer({
                id: 'mirador',
                // theme: {
                //   transitions: window.location.port === '4488' ?  { create: () => 'none' } : {},
                // },
                windows: [{
                    manifestId: '/api/v1/contrib/hks3_mirador/biblionumbers?bn='+biblionumber
                }]
            });               
        })   
        .error(function(data) {
            console.log('no data found');
        });
        });
    }
})
