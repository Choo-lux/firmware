var xmlhttp=false;
if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
	try {xmlhttp = new XMLHttpRequest();}
	catch (e) {xmlhttp=false;}
}
if (!xmlhttp && window.createRequest) {
	try {xmlhttp = window.createRequest();}
	catch (e) {xmlhttp=false;}
}

function our_onclick(tabname) {
	// Reset all of the other tabs back to normal
	document.getElementById('tab1').style.background = "#303030";
	document.getElementById('tab1span').style.color = "#4FA8FF";
	document.getElementById('tab2').style.background = "#303030";
	document.getElementById('tab2span').style.color = "#4FA8FF";
	document.getElementById('tab3').style.background = "#303030";
	document.getElementById('tab3span').style.color = "#4FA8FF";
	
	// and change this tab to be the nicer looking one
	selected_tab=tabname;
	
	document.getElementById(tabname).style.background = "#262626";
	document.getElementById(tabname + "span").style.color = "#FFFFFF";
}

function our_onmouseover(tabname) {
	// Reset all of the other tabs back to normal
	if(tabname != selected_tab) {document.getElementById(tabname).style.background = "#262626";}
	document.getElementById(tabname).style.color = "#FFFFFF";
}

function our_onmouseout(tabname) {
	// Reset all of the other tabs back to normal
	if(tabname != selected_tab) {document.getElementById(tabname).style.backgroundColor = "303030";}
}

function update_status() {
	if(window.location.href.indexOf("/cgi-bin/overview.cgi") > -1) {var is_overview = true;}
	else {var is_overview = false;}
	
	xmlhttp.open("GET", "/cgi-bin/status.cgi", true);
	xmlhttp.onreadystatechange=function() {
		if(xmlhttp.readyState==4) {
			var data = eval('(' + xmlhttp.responseText + ')');
			
			if(data.lan.status == "1") {
				data.lan.status = "Connected";
				data.lan.status_top = "Up";
				document.getElementById('lan_status_top').style.color = "green";
			}
			else {
				data.lan.status = "Disconnected";
				data.lan.status_top = "Down";
				document.getElementById('lan_status_top').style.color = "red";
			}
			
			if(data.wan.status == "1") {
				data.wan.status = "Connected";
				data.wan.status_top = "Up";
				document.getElementById('wan_status_top').style.color = "green";
			}
			else {
				data.wan.status = "Disconnected";
				data.wan.status_top = "Down";
				document.getElementById('wan_status_top').style.color = "red";
			}
			
			if(data.dns.status == "1") {
				data.dns.status = "Connected";
				data.dns.status_top = "Up";
				document.getElementById('dns_status_top').style.color = "green";
			}
			else {
				data.dns.status = "Disconnected";
				data.dns.status_top = "Down";
				document.getElementById('dns_status_top').style.color = "red";
			}
			
			if(is_overview) {
				document.getElementById('lan_status').textContent = data.lan.status;
				document.getElementById('lan_ip').textContent = data.lan.ip;
			}
			document.getElementById('lan_status_top').textContent = data.lan.status_top;
			
			if(is_overview) {
				document.getElementById('wan_status').textContent = data.wan.status;
				document.getElementById('wan_ip').textContent = data.wan.ip;
			}
			document.getElementById('wan_status_top').textContent = data.wan.status_top
			
			if(is_overview) {
				document.getElementById('dns_status').textContent = data.dns.status;
				document.getElementById('dns_ip').textContent = data.dns.ip;
			}
			document.getElementById('dns_status_top').textContent = data.dns.status_top;
			
			return true;
		}
	}
	xmlhttp.send(null);
}

window.onload = function() {
	our_onclick(selected_tab);
	update_status();
	setInterval(function() {update_status()}, 5000);
}