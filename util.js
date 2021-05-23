// Add values to query string
function updateQueryStringParam(key, value) {
	baseUrl = [location.protocol, '//', location.host, location.pathname].join('');
	urlQueryString = document.location.search;
	var newParam = key + '=' + value,
		params = '?' + newParam;

	// If the "search" string exists, then build params from it
	if (urlQueryString) {
		keyRegex = new RegExp('([\?&])' + key + '[^&]*');
		// If param exists already, update it
		if (urlQueryString.match(keyRegex) !== null) {
			params = urlQueryString.replace(keyRegex, "$1" + newParam);
		} else { // Otherwise, add it to end of query string
			params = urlQueryString + '&' + newParam;
		}
	}
	window.history.replaceState({}, "", baseUrl + params);
}

// Remove parameters from query string
function removeParameterByName(parameter) {
	var url = document.location.href;
	var urlparts = url.split('?');

	if (urlparts.length >= 2) {
		var urlBase = urlparts.shift();
		var queryString = urlparts.join("?");

		var prefix = encodeURIComponent(parameter) + '=';
		var pars = queryString.split(/[&;]/g);
		for (var i = pars.length; i-- > 0;)
			if (pars[i].lastIndexOf(prefix, 0) !== -1)
				pars.splice(i, 1);
		url = urlBase + '?' + pars.join('&');
		window.history.replaceState('', document.title, url); // added this line to push the new url directly to url bar .
	}
	return url;
}

// Get values from query string
function getParameterByName(name, def) {
	if (typeof def === 'undefined') {
		def = null;
	}

	name = name.replace(/[\[\]]/g, "\\$&");
	var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
		results = regex.exec(window.location.href);
	if (!results) return def;
	if (!results[2]) return '';
	return Number(decodeURIComponent(results[2].replace(/\+/g, " ")));
}

function round(value) {
	//return Math.round(value * 100) / 100;
	if (value > 10) {
		return Math.round(value);
	} else {
		return Math.round(value * 10) / 10;
	}
}

function nice_name(name) {
	return _.startCase(name);
}

function padded(text) {
	return text.padEnd(25, " ") + ": "
}
