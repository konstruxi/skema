
if ((location.search || '').indexOf('action=submit') > -1) 
  if (!document.getElementsByClassName('error')[0]) {
    var form = document.getElementsByTagName('form')[0];
    if (form) form.submit();
  }



document.addEventListener('click', function(e) {
  for (var p = e.target; p; p = p.parentNode) {
    if (p.tagName == 'DETAILS') {
      var details = p;
      break;
    }
  }
  if (!details) return;
  
  var nav = document.querySelector('nav.resources');

  if (!nav.classList.contains('built')) {
    nav.classList.add('built');
    var contents = nav.getElementsByClassName('contents');
    for (var i = 0; i < contents.length; i++) {
      var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('viewBox', '0 0 48 48');
      svg.innerHTML = '<use xlink:href="#add-icon" /></svg>';
      contents[i].insertBefore(svg, contents[i].firstChild);
    }
    var summaries = nav.getElementsByTagName('summary');
    for (var i = 0; i < summaries.length; i++) {
      var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('viewBox', '0 0 48 48');
      svg.innerHTML = '<use xlink:href="#close-icon" /></svg>';
      summaries[i].appendChild(svg);
    }
    var resources = nav.getElementsByClassName('resources');
    for (var i = 0; i < resources.length; i++) {
      var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('viewBox', '0 0 48 48');
      svg.innerHTML = '<use xlink:href="#add-icon" /></svg>';
      var li = document.createElement('li')
      li.className = 'add button';
      li.appendChild(svg);
      resources[i].appendChild(li);
    }
  }

  if (window.currentDetails) {

    for (var p = window.currentDetails; p && p != details; p = p.parentNode)
      if (p.tagName == "DETAILS")
        p.removeAttribute('open')

    if (details.getAttribute('open') == null) {
      for (var p = details.parentNode; p; p = p.parentNode)
        if (p.tagName == "DETAILS")
          p.setAttribute('open', '')
    } else {
      var nested = window.currentDetails.getElementsByTagName('details');
      for (var i = 0; i < nested.length; i++) {
        if (nested[i] != details)
          nested[i].removeAttribute('open')
      }
    }
    window.currentDetails.classList.remove('current');
  }
  details.classList.add('current');
  window.currentDetails = details;
  requestAnimationFrame(function() {

      window.snapshot = window.snapshot.animate();
  })
})

var icons = document.createElement('div');
icons.classList.add('icons')
icons.innerHTML = '\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48">\
<path id="folder-icon" d="M20 8H8c-2.21 0-3.98 1.79-3.98 4L4 36c0 2.21 1.79 4 4 4h32c2.21 0 4-1.79 \
4-4V16c0-2.21-1.79-4-4-4H24l-4-4z"/>\
</svg> \
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">\
<path id="close-icon" d="M38 12.83L35.17 10 24 21.17 12.83 10 10 12.83 21.17 24 10 35.17 12.83 38 24 26.83 35.17 38 38 35.17 26.83 24z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">\
<path id="add-icon" d="M38 26H26v12h-4V26H10v-4h12V10h4v12h12v4z"/></svg>';
document.body.appendChild(icons)