var filtersAdded = {};
var resultFiltersAdded = {};

var queriedHeartPaths =  [];
var queriedTimeseriesPaths = [];

function resetQueriedPaths() {
    queriedHeartPaths = [];
    queriedTimeseriesPaths = [];
}

function downloadSeriesHandler() {

    if (queriedHeartPaths.length == 0 && queriedTimeseriesPaths.length == 0) {
        alert("No data files were queried, please modify your query!");
    } else {

        var urls = queriedHeartPaths.concat(queriedTimeseriesPaths);

        var zip = new JSZip();
        var count = 0;
        var name = "medical-query-dataset.zip";
        urls.forEach(function(url){
        JSZipUtils.getBinaryContent(url, function (err, data) {
            if(err) {
                throw err; 
            }
            zip.file(url+".data", data,  {binary:true});
            count++;
            
            if (count == urls.length) {
                zip.generateAsync({type:'blob'}).then(function(content) {
                saveAs(content, name);
                });
            }
        });
        });
        
        
    }

}


function post(path, params, method) {
    method = method || "post"; // Set method to post by default if not specified.

    // The rest of this code assumes you are not using a library.
    // It can be made less wordy if you use one.
    var form = document.createElement("form");
    form.setAttribute("method", method);
    form.setAttribute("action", path);

    for(var key in params) {
        if(params.hasOwnProperty(key)) {
            var hiddenField = document.createElement("input");
            hiddenField.setAttribute("type", "hidden");
            hiddenField.setAttribute("name", key);
            hiddenField.setAttribute("value", params[key]);

            form.appendChild(hiddenField);
        }
    }

    document.body.appendChild(form);
    form.submit();
}

function searchPopcornAddItem(key, value, isset) {
    var searchPopcorn = $("#search_popcorn");
    var list = $('<li></li>');
    var input;
    if (isset == true) {
        input = $('<input type="checkbox" class="flat" checked/>');
    } else {
        input = $('<input type="checkbox" class="flat"/>')
    }
    input.attr("name", "filter");
    input.attr("value", value)
    list.append('<p>' + input[0].outerHTML + ' ' + key + ' </p>');
    searchPopcorn.append(list[0].outerHTML);
}

function resultPopcornAddItem(key, value, isset) {
    var resultPopcorn = $("#result_popcorn");
    var list = $('<li></li>');
    var input;
    if (isset == true) {
        input = $('<input type="checkbox" class="flat" checked/>');
    } else {
        input = $('<input type="checkbox" class="flat"/>')
    }
    input.attr("name", "resultFilter");
    input.attr("value", value)
    list.append('<p>' + input[0].outerHTML + ' ' + key + ' </p>');
    resultPopcorn.append(list[0].outerHTML);
}

function getSearchFilterChildrenFor(value) {
    for (var i = 0; i < searchFilters.length; i++) {
        var searchItem = searchFilters[i];
        if (searchItem.value == value) {
            return searchItem.children
        }
    }
    return [];
}

function getCollaspeListItem() {
    return '<li><a class="collapse-link"><i class="fa fa-chevron-up"></i></a></li>';
}

function getSettingsListItem(settingsKvp) {
    if (settingsKvp != null) {
        var list = $('<li class="dropdown"></li>');
        list.append('<a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><i class="fa fa-wrench"></i></a>');
        var settings = $('<ul class="dropdown-menu" role="menu"></ul>');
        // loop settings array
        for (var i = 0; i < settingsKvp.length; i++) {
            var key = settingsKvp[i].key;
            settings.append('<li><a href="#">' + key + '</a></li>')
        }
        list.append(settings);
        return list[0].outerHTML;
    } else {
        return '';
    }
}

function getCloseListItem() {
    return '<li><a class="close-link"><i class="fa fa-close"></i></a></li>';
}

function buildTitle(title, settingsKvp = null) {
    var div = $('<div class="x_title"></div>')
    div.append('<h2>' + title + ' </h2>');
    var menuList = $('<ul class="nav navbar-right panel_toolbox"></ul>');
    menuList.append(getCollaspeListItem());
    menuList.append(getSettingsListItem(settingsKvp));
    menuList.append(getCloseListItem());
    div.append(menuList[0].outerHTML);
    div.append('<div class="clearfix"></div>');
    return div[0].outerHTML;
}

function buildCheckboxContent(htmlName, kvpArray) {
    var content = $('<div class="x_content"></div>');
    var list = $('<ul class="to_do to_do_ul"></ul>');
    for (var i = 0; i < kvpArray.length; i++) {
        var key = kvpArray[i].key;
        var value = kvpArray[i].value;
        var item = $('<li></li>');
        var input;
        if (kvpArray[i].isset == true) {
            input = $('<input type="checkbox" class="flat" checked/>');
        } else {
            input = $('<input type="checkbox" class="flat"/>')
        }
        input.attr("name", htmlName);
        input.attr("value", value)
        item.append('<p>' + input[0].outerHTML + ' ' + key + ' </p>');
        list.append(item[0].outerHTML);
    }
    var div = $('<div class=""></div>');
    div.append(list[0].outerHTML);
    content.append(div[0].outerHTML);
    return content[0].outerHTML;
}

function buildTagsContent(htmlName, kvpArray, suggestions) {
    var content = $('<div class="x_content"></div>');
    var input = $('<input class="tags form-control"/>');
    input.attr("id", htmlName + "_tags");
    input.attr("type", "text");
    input.attr("name", htmlName);
    var initialValues = "";
    for (var i = 0, itemsAdded = 0; i < kvpArray.length; i++) {
        if (kvpArray[i].isset == true) {
            if (itemsAdded > 0) {
                initialValues = initialValues + "; " + kvpArray[i].key;
            } else {
                initialValues = kvpArray[i].key;
            }
            itemsAdded++;
        }
    }
    input.attr("value", initialValues);
    content.append(input[0].outerHTML);
    content.append('<div id="suggestions-container" style="position: relative; float: left; width: 250px; margin: 10px;">' + suggestions + '</div>');
    return content[0].outerHTML;
}

function buildContent(htmlName, isCheckbox, kvpArray, suggestions = "") {
    if (isCheckbox) { 
        return buildCheckboxContent(htmlName, kvpArray, suggestions);
    } else {
        return buildTagsContent(htmlName, kvpArray, suggestions);
    }
}

function initializeTag(htmlName) {
    $('#' + htmlName + '_tags').tagsInput({ width: 'auto', delimiter: ';' });
}

function addGenderFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("gender");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="gender" style="display:none;"></div>');
    panel.append(buildTitle("Sex", settingsKvp));
    panel.append(buildContent("gender", true, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
}

function addBloodTypeFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("bloodType");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="bloodType" style="display:none;"></div>');
    panel.append(buildTitle("Blood Type", settingsKvp));
    panel.append(buildContent("bloodType", true, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
}

function addConditionTypeFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("conditions");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="conditions" style="display:none;"></div>');
    panel.append(buildTitle("Diagnosis Terms", settingsKvp));
    panel.append(buildContent("conditions", false, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
    initializeTag("conditions");
}

function addZipcodeFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("zipcode");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="zipcode" style="display:none;"></div>');
    panel.append(buildTitle("Location", settingsKvp));
    panel.append(buildContent("zipcode", false, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
    initializeTag("zipcode");
}

function addNationalityFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("nationality");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="nationality" style="display:none;"></div>');
    panel.append(buildTitle("Nationality", settingsKvp));
    panel.append(buildContent("nationality", false, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
    initializeTag("nationality");
}

function addEthnicityFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("ethnicity");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="ethnicity" style="display:none;"></div>');
    panel.append(buildTitle("Ethnicity", settingsKvp));
    panel.append(buildContent("ethnicity", false, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
    initializeTag("ethnicity");
}

function addAgeFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("ageRange");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="ageRange" style="display:none;"></div>');
    panel.append(buildTitle("Age Group", settingsKvp));
    panel.append(buildContent("ageRange", true, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
}

function addDrugAllergyFilter() {
    var settingsKvp = [
        { "key": "abc", "value": "valAbc" },
        { "key": "def", "value": "valDef" }
    ];
    var kvp = getSearchFilterChildrenFor("drug_allergy");
    var panel = $('<div class="x_panel"></div>');
    panel.append('<div name="filter_type" type="drug_allergy" style="display:none;"></div>');
    panel.append(buildTitle("Drug Allergy", settingsKvp));
    panel.append(buildContent("drug_allergy", true, kvp, ""));
    var item = $('<li class="horizontal-list-item"></li>').append(panel[0].outerHTML);
    $('#searchForm > ul').append(item[0].outerHTML);
}

function addSearchFilter(type) {
    if (filtersAdded[type] != undefined && !filtersAdded[type]) {
        switch(type) {
            case "gender":
                addGenderFilter();
                filtersAdded.gender = true;
                break;
            case "bloodType":
                addBloodTypeFilter();
                filtersAdded.bloodType = true;
                break;
            case "conditions":
                addConditionTypeFilter();
                filtersAdded.conditions = true;
                break;
            case "zipcode":
                addZipcodeFilter();
                filtersAdded.zipcode = true;
                break;
            case "ageRange":
                addAgeFilter();
                filtersAdded.ageRange = true;
                break;
            case "drug_allergy":
                addDrugAllergyFilter();
                filtersAdded.drug_allergy = true;
                break;
            case "nationality":
                addNationalityFilter();
                filtersAdded.nationality = true;
                break;
            case "ethnicity":
                addEthnicityFilter();
                filtersAdded.ethnicity = true;
                break;
        }
        init_panelHandler();
    }
}

function removeSearchFilter(type) {
    if (filtersAdded[type] != undefined && filtersAdded[type]) {
        var items = $('.horizontal-list-item > div[class="x_panel"] > div[name="filter_type"]');
        for (var i = 0; i < items.length; i++) {
            var item = $(items[i]);
            var filterType = item.attr("type");
            if (filterType == type) {
                item.closest('.x_panel').parent().remove();
                filtersAdded[type] = false;
                break;
            }
        }
    }
}

function getZipcodeMappingFor(location) {
    var zipcodeMap = getSearchFilterChildrenFor("zipcode");
    var zipcodes = [];
    for (var i = 0; i < zipcodeMap.length; i++) {
        if (zipcodeMap[i].key == location) {
            zipcodes = JSON.parse(zipcodeMap[i].value);
            break;
        }
    }
    return zipcodes;
}

function getZipcodesFor(listOfLocations) {
    var zipcodes = [];
    for (var i = 0; i < listOfLocations.length; i++) {
        var location = listOfLocations[i];
        var locationZipcodes = getZipcodeMappingFor(location);
        for (var j = 0; j < locationZipcodes.length; j++) {
            zipcodes.push(locationZipcodes[j]);
        }
    }
    zipcodes.sort(function(a,b){return a-b;});
    return zipcodes;
}

function getConditionIdFor(conditionName) {
    var conditionsList = getSearchFilterChildrenFor("conditions");
    var conditionId = 0;
    for (var i = 0; i < conditionsList.length; i++) {
        if (conditionsList[i].key == conditionName) {
            conditionId = conditionsList[i].value;
            break;
        }
    }
    return conditionId;
}

function getSearchParams() {
    var _tmp = $("#searchForm").serializeArray();
    var searchParams = [];
    for (var i = 0; i < _tmp.length; i++) {
        var _item = _tmp[i];
        var _key = _item.name;
        if (_item.name == "conditions" || _item.name == "zipcode" || 
            _item.name == "ethnicity" || _item.name == "nationality") {
            var _values = _item.value.split(";");
            for (var j = 0; j < _values.length; j++) {
                var kvp = {};
                if (_item.name == "conditions") {
                    var cid = getConditionIdFor(_values[j]);
                    if (cid == 0) { 
                        continue; // skip, invalid entry 
                    } else {
                        kvp["cid"] = cid;
                    }
                } else if (_item.name == "zipcode") {
                    var zipcodes = getZipcodeMappingFor(_values[j]);
                    if (zipcodes.length == 0) {
                        continue; // skip, invalid entry
                    } else {
                        for (var k = 0; k < zipcodes.length; k++) {
                            var _kvp = {};
                            _kvp["zipcode"] = zipcodes[k];
                            searchParams.push(_kvp);
                        }
                        continue; // terminate this loop, done.
                    }
                }
                else {
                    kvp[_key] = _values[j];
                }
                searchParams.push(kvp);
            }
        } 
        else {
            var kvp = {};
            kvp[_key] = _item.value;
            searchParams.push(kvp);
        }
    }

    return searchParams;
}

function formatHeartratePath(heartratePath) {
    heartratePath = escapeHtml(heartratePath);
    if (heartratePath == "unavailable") {
        return "Unavailable";
    }
    var icon = $('<i class="fa fa-download" aria-hidden="true"></i>');
    var anchor = $('<a> Download</a>');
    anchor.attr("href", "/kanon/heartdata/" + heartratePath);
    return icon[0].outerHTML + anchor[0].outerHTML;
}

function formatTimeSeriesPath(timeseriesPath) { 
    timeseriesPath = escapeHtml(timeseriesPath);
    if (timeseriesPath == "unavailable") {
        return "Unavailable";
    }
    var icon = $('<i class="fa fa-download" aria-hidden="true"></i>');
    var anchor = $('<a> Download</a>');
    anchor.attr("href", "/kanon/timeseriesdata/" + timeseriesPath);
    return icon[0].outerHTML + anchor[0].outerHTML;
}

function formatDrugAllergy(allergyString) {
    if (allergyString == "0") {
        return "No Known Drug Allergies";
    } else if (allergyString == "1") {
        return "Has Known Drug Allergies";
    } else {
        return "Unknown";
    }
}

function formatGender(genderString) {
    if (genderString.toUpperCase() == "M") {
        return "Male";
    } else if (genderString.toUpperCase() == "F") {
        return "Female";
    } else {
        return "Unknown";
    }
}

function scrollToTop() {
    $('html,body').animate({
        scrollTop: 0 },
        1500);
}

function scrollToResult() {
    $('html,body').animate({
        scrollTop: $("#result_x_panel").offset().top},
        1500);
}

function updateSearchMessage(resultCount) {
    var message;
    if (resultCount < 0) {
        $('#result_x_panel').effect("highlight", {"color": "#ff7e91"}, 1500);
        message = "Something went wrong, please try again later.";
    } else if (resultCount == 0) {
        $('#result_x_panel').effect("highlight", {"color": "#fffb94"}, 1500);
        message = "We didn't manage to find any results matching your query.";
    } else if (resultCount == 1) {
        $('#result_x_panel').effect("highlight", {"color": "#56ff6f"}, 1500);
        message = "We have found 1 result matching your query.";
    } else {
        $('#result_x_panel').effect("highlight", {"color": "#56ff6f"}, 1500);
        message = "We have found " + resultCount + " results matching your query.";
    }
    $('#result_message')[0].removeChild($('#result_message')[0].childNodes[0]);
    $('#result_message')[0].appendChild(document.createTextNode(message))
}

function getDatatable() {
    var dataTable = $("#datatable").DataTable({
        retrieve: true, //needed to prevent re-initialization error
        dom: '<"tbtn-info">Bfrtip',
        buttons: [
            'copy', 'csv', 'print',

            {
                text: 'Series Data',
                "sToolTip" : 'Downloads the heart readings and time series files. (CSV export feature will not download the actual files)',
                action: function ( e, dt, node, config ) {
                    downloadSeriesHandler();
                }
            }

        ],
      //  columns: jsonTableHeaders
    });
    // $("div.tbtn-info").html('<p>Export results to :</p>');
    return dataTable;
}

function resetDatatableColumns() {
    destroyDatatable();
    $('#datatable > thead > tr > th').remove();
    $('#datatable > thead > tbody').remove();
    for (var key in resultFiltersAdded) {
        if (resultFiltersAdded[key]) {
            for (var i = 0; i < resultFilters.length; i++) {
                if (resultFilters[i].value == key) {
                    var newTh = document.createElement("th");
                    newTh.appendChild(document.createTextNode(resultFilters[i].key));
                    $('#datatable > thead > tr').append(newTh);
                }
            }
        }
    }
    clearDatatable(); // reinitialize datatable with new columns
}

function destroyDatatable() {
    var dataTable = getDatatable();
    dataTable.clear();
    dataTable.destroy();
}

function clearDatatable() {
    var dataTable = getDatatable();
    dataTable.clear().draw();
}

function populateDatatableWith(results) {
    resetDatatableColumns();
    var dataTable = getDatatable();
    updateSearchMessage(results.length);
    var tableData = [];
    for (var i = 0; i < results.length; i++) {
        var rowData = [];
        for (var key in resultFiltersAdded) {
            if (resultFiltersAdded[key]) {
                if (key == "gender") {
                    rowData.push(escapeHtml(formatGender(results[i][key])));
                }  else if (key == "drug_allergy") {
                    rowData.push(escapeHtml(formatDrugAllergy(results[i][key])));
                } else if (key == "heartrate_path") {
                    rowData.push(formatHeartratePath(results[i][key]));                    
                    if (escapeHtml(results[i][key]) == "unavailable") {
                        // dont add to urls
                    } else {
                        queriedHeartPaths.push("heartdata/"+results[i][key]);
                    }                  
                } else if (key == "timeseries_path") {                  
                        rowData.push(formatTimeSeriesPath(results[i][key]));
                        if (escapeHtml(results[i][key]) == "unavailable") {
                            // dont add to urls
                        } else {
                            queriedTimeseriesPaths.push("timeseriesdata/"+results[i][key]);
                        }                        
                } else {
                    rowData.push(escapeHtml(results[i][key]));
                }
            }
        }
        tableData.push(rowData);
    }
    dataTable.rows.add(tableData).draw();
}

function submitSearchForm() {
    var searchParams = getSearchParams();
    var jqxhr = $.post(
        getApplicationRoot("search"), 
        JSON.stringify(searchParams))
        .done(function() {
            try {
                var results = jqxhr.responseJSON[0].results;
                resetQueriedPaths();
                populateDatatableWith(results);
            } catch (ex) {
                clearDatatable();
                updateSearchMessage(-1);
            }
        })
        .fail(function() {
            clearDatatable();
            updateSearchMessage(-1);
        })
        .always(function() {
            $("#search_by_filters").text("Run Search");
            $("#search_by_filters").removeAttr("disabled");
            scrollToResult();
        });
}

function loadSearchFilterSettings() {
    for (var key in filtersAdded) {
        var checkbox = $('#search_popcorn > li > p > input[value="' + key + '"]');
        checkbox.prop("checked", filtersAdded[key]);
    }
}

function loadResultFilterSettings() {
    for (var key in resultFiltersAdded) {
        var checkbox = $('#result_popcorn > li > p > input[value="' + key + '"]');
        checkbox.prop("checked", resultFiltersAdded[key]);
    }
}

function applySearchFilters() {
    var options = $('#search_popcorn > li > p > input');
    for (var i = 0; i < options.length; i++) {
        var option = $(options[i]);
        var optionSelected = option.prop("checked");
        var optionKey = option.prop("value");
        if (filtersAdded[optionKey] != undefined && 
            filtersAdded[optionKey] != optionSelected) {
            if (optionSelected) {
                addSearchFilter(optionKey);
            } else {
                removeSearchFilter(optionKey);
            }
        } 
    }
}

function applyResultFilters() {
    var options = $('#result_popcorn > li > p > input');
    for (var i = 0; i < options.length; i++) {
        var option = $(options[i]);
        var optionSelected = option.prop("checked");
        var optionKey = option.prop("value");
        if (resultFiltersAdded[optionKey] != undefined && 
            resultFiltersAdded[optionKey] != optionSelected) {
                resultFiltersAdded[optionKey] = optionSelected;
        } 
    }
}

function selectedSearchFilters() {
    for (var key in resultFiltersAdded) {
        if (resultFiltersAdded[key]) {
            return true;
        }
    }
    return false;
}

function enableSearch() {
    $("#search_by_filters").text("Run Search");
    $("#search_by_filters").removeAttr("disabled");
    $("#add_search_filters").removeAttr("disabled");
}

function disableSearch() {
    $("#search_by_filters").attr("disabled", "disabled");
    $("#search_by_filters").text("You do not have search permissions. Request for one first.");
    $("#add_search_filters").attr("disabled", "disabled");
}

function init_searchHandler() {

    if (!hasPermissions) {
        disableSearch();
    }
    
    for (var i = 0; i < searchFilters.length; i++) {
        var searchItem = searchFilters[i];
        filtersAdded[searchItem.value] = false;
        searchPopcornAddItem(searchItem.key, searchItem.value, searchItem.isset);
    }
    
    for (var i = 0; i < resultFilters.length; i++) {
        var resultItem = resultFilters[i];
        resultFiltersAdded[resultItem.value] = resultItem.isset == true;
        resultPopcornAddItem(resultItem.key, resultItem.value, resultItem.isset);
    }
    
    $("#searchForm").submit(function(e) { 
        e.preventDefault(); 
    });

    $("#search_by_filters").click(function (e) {
        var targeted_popup_class = jQuery(this).attr('popcorn-target');
        scrollToTop();
        loadResultFilterSettings();
        $('[popcorn-id="' + targeted_popup_class + '"]').fadeIn(350);
        e.preventDefault();
    });

    $('[popcorn-open]').on('click', function(e)  {
        var targeted_popup_class = jQuery(this).attr('popcorn-open');
        $('[popcorn-id="' + targeted_popup_class + '"]').fadeIn(350);
 
        e.preventDefault();
    });
 
    $('[popcorn-close]').on('click', function(e)  {
        var targeted_popup_class = jQuery(this).attr('popcorn-close');
        $('[popcorn-id="' + targeted_popup_class + '"]').fadeOut(350);
 
        e.preventDefault();
    });

    $('#add_search_filters').click(function() {
        var targeted_popup_class = jQuery(this).attr('popcorn-target');
        loadSearchFilterSettings();
        $('[popcorn-id="' + targeted_popup_class + '"]').fadeIn(350);
    })

    $('#search_popcorn > li').click(function(e) {
        if ($(e.target).closest('input[type="checkbox"]').length > 0){
            //Checkbox clicked
        } else {
            var selectedInput = $(this).find("input"); 
            var isSelected = selectedInput.prop("checked"); 
            selectedInput.prop("checked", !isSelected);
        }
    });

    $('#result_popcorn > li').click(function(e) {
        if ($(e.target).closest('input[type="checkbox"]').length > 0){
            //Checkbox clicked
        } else {
            var selectedInput = $(this).find("input"); 
            var isSelected = selectedInput.prop("checked"); 
            selectedInput.prop("checked", !isSelected);
        }
    });

    $('#search_popcorn_accept').click(function() {
        applySearchFilters();
    });

    $('#result_popcorn_accept').click(function() {
        $("#search_by_filters").attr("disabled", "disabled");
        $("#search_by_filters").text("Fetching results...");
        applyResultFilters();
        if (selectedSearchFilters()) {
            $( "#result_compulsory" ).hide();
            var targeted_popup_class = jQuery(this).attr('popcorn-target-close');
            $('[popcorn-id="' + targeted_popup_class + '"]').fadeOut(350);
            submitSearchForm();
        } else {
            $( "#result_compulsory" ).show();
        }
    });
}

function init_panelHandler() {
    $('.collapse-link').unbind('click');
    $('.collapse-link').on('click', function() {
        var $BOX_PANEL = $(this).closest('.x_panel'),
            $ICON = $(this).find('i'),
            $BOX_CONTENT = $BOX_PANEL.find('.x_content');
        
        // fix for some div with hardcoded fix class
        if ($BOX_PANEL.attr('style')) {
            $BOX_CONTENT.slideToggle(200, function(){
                $BOX_PANEL.removeAttr('style');
            });
        } else {
            $BOX_CONTENT.slideToggle(200); 
            $BOX_PANEL.css('height', 'auto');  
        }

        $ICON.toggleClass('fa-chevron-up fa-chevron-down');
    });

    $('.close-link').unbind('click');
    $('.close-link').click(function () {
        var $BOX_PANEL = $(this).closest('.x_panel');
        var removedType = $BOX_PANEL.find('div[name=filter_type]').attr("type");
        if (filtersAdded[removedType] != undefined) {
            filtersAdded[removedType] = false;
        }
        $BOX_PANEL.parent().remove();
    });

    $(".to_do_ul > li").unbind('click');
    $(".to_do_ul > li").click(function(e) {
        if ($(e.target).closest('input[type="checkbox"]').length > 0){
            //Checkbox clicked
        } else {
            var selectedInput = $(this).find("input"); 
            var isSelected = selectedInput.prop("checked"); 
            selectedInput.prop("checked", !isSelected);
        }
    });
}

function getApplicationRoot(path) {
    return "/kanon/" + path;
}

$(document).ready(function() {
    init_searchHandler();
    init_panelHandler();
});