Builder = {};

Builder.init = function() {
  var sitemap = document.querySelector('.sitemap');
  if (!sitemap) return;
  var list = sitemap.getElementsByTagName('ul')[0];

  var button = document.createElement('li')
  button.classList = 'edit'
  var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
  svg.setAttribute('viewBox', '0 0 48 48');
  svg.innerHTML = '<use xlink:href="#settings-icon" /></svg>';
  button.appendChild(svg)


  list.insertBefore(button, list.querySelector('li.home') || list.firstChild)

  sitemap.addEventListener('click', function(e) {
    for (var p = e.target; p; p = p.parentNode) {
      if (p.tagName && p.classList.contains('edit')) {
        Builder.open(sitemap)
      } else if (p.tagName && p.classList.contains('add')) {
        if (p.parentNode.classList.contains('resources')) {
          var level = 
            p.parentNode.classList.contains('third-level') ? 3 :
            p.parentNode.classList.contains('second-level') ? 2 : 1;
          var resource = buildResource()
          if (level == 1)
            p.parentNode.insertBefore(resource, p.nextSibling)
          else
            p.parentNode.appendChild(resource)
          rebuildList(sitemap, 'service', 0)
          resource.querySelectorAll('input[type=text]')[0].focus();
          if (clickDetails(resource.firstChild, resource.querySelector('summary')) === false) {

          }
          e.preventDefault();
          e.stopPropagation()
        }
      }
    }
  }, true)

};

Builder.open = function(sitemap) {
  if (!Builder.built) {
    Builder.built = true;
    Builder.current = sitemap;
    buildNav(sitemap);
    sitemap.classList.add('editing');
    Manager.animate();

  }
}

Builder.close = function() {
  if (!Builder.current) return;
  Builder.current.classList.remove('editing');
  Builder.current = null;
  Manager.animate();
}


function rebuildList(root, prefix, counter) {
  var count = 0;
  for (var k = 0; k < root.children.length; k++)
    if (root.children[k] && root.children[k].tagName == 'DETAILS') {
      var name = prefix + '[children][' + counter + ']'
      var summary = root.children[k].getElementsByTagName('summary')[0];
      var input = summary.getElementsByTagName('input')[0];
      input.name = name + '[alias]'
      var select = summary.getElementsByTagName('select')[0];
      select.name = name + '[table_name]'

      var dls = root.children[k].getElementsByTagName('dl');
      i = 0;
      if (dls[0]) {
        var dds = dls[i].querySelectorAll('dd select');
        for (var j = 0; j < dds.length; j++)
          dds[j].name = name + '[columns][' + j + '][type]'
        var dts = dls[i].querySelectorAll('dt select');
        for (var j = 0; j < dts.length; j++)
          dts[j].name = name + '[columns][' + j + '][type]'
      }
      count = rebuildList(root.children[k], name, count);
      counter++;
    } else {
      counter = rebuildList(root.children[k], prefix, counter)
    }
  return counter;


}

function buildList(root, prefix, counter) {
  var count = 0;
  for (var k = 0; k < root.children.length; k++)
    if (root.children[k] && root.children[k].tagName == 'DETAILS') {
      var name = prefix + '[children][' + counter + ']'
      var summary = root.children[k].getElementsByTagName('summary')[0];
      var link = summary.getElementsByTagName('a')[0]
      var input = document.createElement('input')
      input.name = name + '[alias]'
      input.value = summary.textContent.trim();
      summary.appendChild(input)

      var select = document.createElement('select')
      select.name = name + '[table_name]'
      select.innerHTML = '<option>' + link.pathname.replace(/\//g, '') + '</option>';
      summary.appendChild(select)

      var dls = root.children[k].getElementsByTagName('dl');
      i = 0;
      var dds = dls[i].getElementsByTagName('dd');
      for (var j = 0; j < dds.length; j++) {
        dds[j].innerHTML = '<select name="' + name + '[columns][' + j + '][type]"><option>' + dds[j].innerHTML + '</option></select>'
      }
      var dts = dls[i].getElementsByTagName('dt');
      for (var j = 0; j < dts.length; j++) {
        dts[j].innerHTML = '<select name="' + name + '[columns][' + j + '][name]"><option>' + dts[j].innerHTML + '</option></select>'
      }
      count = buildList(root.children[k], name, count);
      counter++;
    } else {
      counter = buildList(root.children[k], prefix, counter)
    }
  return counter;


}

buildNav = function() {

  var nav = document.querySelector('nav.resources');

  if (!nav.classList.contains('built')) {
    var types = ['xml', 'text', 'timestamptz']
    buildList(nav, 'service', 0);

    nav.classList.add('built');
    var contents = nav.getElementsByClassName('contents');
    for (var i = 0; i < contents.length; i++) {
      var button = document.createElement('button');
      button.className = 'add button';
      var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('viewBox', '0 0 48 48');
      svg.innerHTML = '<use xlink:href="#add-icon" /></svg>';
      button.appendChild(svg)
      contents[i].insertBefore(button, contents[i].firstChild);
    }
    var summaries = nav.getElementsByTagName('summary');
    for (var i = 0; i < summaries.length; i++) {
      var label = document.createElement('label');
      var checkbox = document.createElement('input')
      checkbox.id = 'checkbox-' + Math.random() + Math.random();
      checkbox.className = 'deletion'
      label.setAttribute('for', checkbox.id);
      checkbox.type = 'checkbox';
      label.className = 'add button';
      var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('viewBox', '0 0 48 48');
      svg.innerHTML = '<use xlink:href="#delete-icon" /></svg>';
      summaries[i].parentNode.insertBefore(checkbox, summaries[i])
      label.appendChild(svg)
      summaries[i].appendChild(label);
    }
    var resources = nav.getElementsByClassName('resources');
    for (var i = 0; i < resources.length; i++) {
      var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('viewBox', '0 0 48 48');
      svg.innerHTML = '<use xlink:href="#add-icon" /></svg>';
      var li = document.createElement('li')
      li.className = 'add button';
      li.appendChild(svg);
      resources[i].insertBefore(li, resources[i].firstChild);
    }



    var li = document.createElement('li');
    li.className = 'link button';
    var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
    svg.setAttribute('viewBox', '0 0 48 48');
    svg.innerHTML = '<use xlink:href="#link-icon" /></svg>';
    var button = document.createElement('button')
    button.appendChild(svg);

    li.appendChild(button)
    nav.getElementsByTagName('ul')[0].appendChild(li)
  }

}

buildResource = function(level) {
  var id = Math.random() + "-" + Math.random()
  var li = document.createElement('li');
  li.className = 'inserted'
  var kls = level == 1 ? 'second-level' : 'third-level'
  li.innerHTML = "<details tabindex='-1'>\
    <input type='checkbox' id='deletion-" + id + "' />\
    <summary>\
      <a></a>\
      <input type='text' name='service[resources][0]' />\
      <select name='service[resources][0]'>\
        <option>Pick preset</option>\
      </select>\
      <label for='deletion-" + id + "' class='delete add button'><svg viewBox='0 0 48 48'><use xlink:href='#delete-icon' /></svg></label>\
    </summary>\
    <div class='contents'><dl></dl></div>\
    \
    " + (level > 2 ? '' : "<ul class='" + kls + " resources'><li class='add button'>\
      <svg viewBox='0 0 48 48'><use xlink:href='#add-icon' /></svg>\
    </li></ul>") + 
  "</details>";
  return li
}


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
<path id="add-icon" d="M38 26H26v12h-4V26H10v-4h12V10h4v12h12v4z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="save-icon" d="M36 14l-2.83-2.83-12.68 12.69 2.83 2.83L36 14zm8.49-2.83L23.31 32.34 14.97 24l-2.83 2.83L23.31 38l24-24-2.82-2.83zM.83 26.83L12 38l2.83-2.83L3.66 24 .83 26.83z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="delete-icon" d="M12 38c0 2.2 1.8 4 4 4h16c2.2 0 4-1.8 4-4V14H12v24zm4.93-14.24l2.83-2.83L24 25.17l4.24-4.24 2.83 2.83L26.83 28l4.24 4.24-2.83 2.83L24 30.83l-4.24 4.24-2.83-2.83L21.17 28l-4.24-4.24zM31 8l-2-2H19l-2 2h-7v4h28V8z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="edit-icon" d="M6 34.5V42h7.5l22.13-22.13-7.5-7.5L6 34.5zm35.41-20.41c.78-.78.78-2.05 0-2.83l-4.67-4.67c-.78-.78-2.05-.78-2.83 0l-3.66 3.66 7.5 7.5 3.66-3.66z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="nav-icon" d="M6 36h36v-4H6v4zm0-10h36v-4H6v4zm0-14v4h36v-4H6z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="apply-icon" d="M18 32.34L9.66 24l-2.83 2.83L18 38l24-24-2.83-2.83z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="undo-icon" d="M25.99 6C16.04 6 8 14.06 8 24H2l7.79 7.79.14.29L18 24h-6c0-7.73 6.27-14 14-14s14 6.27 14 14-6.27 14-14 14c-3.87 0-7.36-1.58-9.89-4.11l-2.83 2.83C16.53 39.98 21.02 42 25.99 42 35.94 42 44 33.94 44 24S35.94 6 25.99 6zM24 16v10l8.56 5.08L34 28.65l-7-4.15V16h-3z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="redo-icon" d="M42 20.25H28.43l5.49-5.64c-5.46-5.41-14.3-5.61-19.76-.2-5.46 5.41-5.46 14.17 0 19.58 5.46 5.41 14.3 5.41 19.76 0 2.72-2.7 4.08-5.83 4.07-9.79H42c0 3.96-1.76 9.1-5.28 12.59-7.02 6.95-18.42 6.95-25.44 0s-7.07-18.22-.05-25.17c7.01-6.95 18.29-6.95 25.3 0L42 6v14.25zM25 16v8.5l7 4.16-1.44 2.42L22 26V16h3z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="layout-stream-icon" d="M40 26H6c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h34c1.1 0 2-.9 2-2V28c0-1.1-.9-2-2-2zm0-20H6c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h34c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="layout-thumbnails-icon" d="M8 28h8v-8H8v8zm0 10h8v-8H8v8zm0-20h8v-8H8v8zm10 10h24v-8H18v8zm0 10h24v-8H18v8zm0-28v8h24v-8H18z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="layout-headlines-icon" d="M8 30h34v-4H8v4zm0 8h34v-4H8v4zm0-16h34v-4H8v4zm0-12v4h34v-4H8z"/></svg>\
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48"><path id="layout-carousel-icon" d="M14 38h20V8H14v30zM4 34h8V12H4v22zm32-22v22h8V12h-8z"/></svg>';

document.body.appendChild(icons);

