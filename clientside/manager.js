var Manager = {
}
var Saver = {}
var Lister = {}

Manager.animate = function(callback) {
  if (!window.snapshot) {
    window.snapshot = Editor.Snapshot.take(document.getElementById('layout-root') || document.body, new Editor.Snapshot);
  } else {
    window.snapshot = window.snapshot.animate();
    if (Manager.editor)
      Manager.editor.snapshot = window.snapshot;
  }
}

Manager.stylesheet = document.createElement('style');
document.body.appendChild(Manager.stylesheet)



Manager.open = function(editor, section, button) {
  var anchor = section.getElementsByClassName('toolbar')[0]
  var indexF = editor.snapshot.elements.indexOf(anchor);
  if (indexF > -1) {
    var box = editor.snapshot.dimensions[indexF]
    var offsetTop = box.top + document.body.offsetTop;
    var offsetLeft = box.left + document.body.offsetLeft;
    for (var p = anchor; (p = p.parentNode) != document.body; ) {
      offsetTop -= p.scrollTop
      offsetLeft -= p.scrollLeft
    }
  } else {
    return;
  }
  editor.currentToolbar = section;
  setUIColors(null, section, 'menu');
  setUIColors(null, section, 'last');
  manager.style.top = offsetTop + 'px'
  manager.style.left = offsetLeft + 'px';
  //manager.className = section.className
  manager.removeAttribute('hidden')
}

Lister.close = function() {
  lister.setAttribute('hidden', 'hidden')
}


Lister.open = function(editor, section, button) {
  var indexF = editor.snapshot.elements.indexOf(section.getElementsByClassName('toolbar')[0]);
  if (indexF > -1) {
    var box = editor.snapshot.dimensions[indexF]
    var offsetTop = box.top// + document.body.offsetTop;
    var offsetLeft = box.left// + document.body.offsetLeft;
  } else {
    return;
  }
  editor.currentToolbar = section;
  setUIColors(null, section, 'menu');
  setUIColors(null, section, 'last');
  lister.style.top = offsetTop + 'px'
  lister.style.left = offsetLeft + 'px';
  //manager.className = section.className
  lister.removeAttribute('hidden')
}



Saver.close = function() {
  saver.setAttribute('hidden', 'hidden')
}


Saver.open = function(editor, section, button) {
  var anchor = section.getElementsByClassName('toolbar')[0];
  var indexF = editor.snapshot.elements.indexOf(anchor);
  if (indexF > -1) {
    var box = editor.snapshot.dimensions[indexF]
    var offsetTop = box.top// + document.body.offsetTop;
    var offsetLeft = box.left// + document.body.offsetLeft;
    for (var p = anchor; (p = p.parentNode) != document.body; ) {
      if (!p)
        return;
      if (p.classList.contains('list')) {
        offsetTop -= p.scrollTop
        offsetLeft -= p.scrollLeft
      }
    }
  } else {
    return;
  }
  editor.currentToolbar = section;
  setUIColors(null, section, 'menu');
  setUIColors(null, section, 'last');
  saver.style.top = offsetTop + 'px'
  saver.style.left = offsetLeft + 'px';
  //manager.className = section.className
  saver.removeAttribute('hidden')
}

Manager.close = function() {
  manager.setAttribute('hidden', 'hidden')
}

Manager.processArticle = function(article, force) {
  var oldToolbars = [];
  var newToolbars = [];
  if (force) {
    for (var j = 0; j < article.children.length; j++) {
      if (article.children[j].tagName == 'SECTION') {
        var toolbars = article.children[j].querySelectorAll('.toolbar.kx');
        for (var i = 0; i < toolbars.length; i++)
          oldToolbars.push(toolbars[i]);
      }

    }
  }
  var headers = article.getElementsByTagName('header');
  for (var i = 0; i < headers.length; i++) {
    newToolbars.push(
      Editor.Chrome.Toolbar(null, headers[i], function(element) {
        if (headers[i].parentNode.getElementsByTagName('section')[0]) {
          headers[i].parentNode.classList.remove('empty')
          return 'menu-icon'
        } else {
          headers[i].parentNode.classList.add('empty')
          return 'add-icon'
        }
      })
    )
  }
  var section = article.getElementsByTagName('section')[0];
  if (section) {
    newToolbars.push(
      Editor.Chrome.Toolbar(null, section, function(element) {
        var depth = 0;
        for (var p = element; p = p.parentNode;) {
          if (p.classList && p.classList.contains('list'))
            depth++;
        }
        if (depth == 2 || (element.parentNode.classList.contains('list'))) {
          return false;
          //return 'menu-icon'
        } else if (article.tagName == 'HEADER') {
          if (article.getAttribute('itemname') == 'origin') {
            return 'fork-icon'
          } else {
            return 'settings-icon'
          }
        } else if (element.classList.contains('starred')) {
          return 'star-icon'
        } else {
          return 'edit-icon'
        }
      })
    )
  }

  for (var i = 0; i < oldToolbars.length; i++) {
    if (oldToolbars[i].parentNode && newToolbars.indexOf(oldToolbars[i]) == -1) {
      oldToolbars[i].parentNode.removeChild(oldToolbars[i])
    }
  }
}

var articles = document.querySelectorAll('article[itemtype], header[itemtype]');
for (var i = 0; i < articles.length; i++) {
  Manager.processArticle(articles[i])
}

Editor.Style.recompute(document.body)

Array.prototype.forEach.call(document.querySelectorAll('img[crop-x]'), function(img) {
  Editor.Image.crop(img)
});

Manager.initHeader = function() {

var header = document.querySelector('header[itemtype] > section:first-child');
var more = document.createElement('a');
more.onclick = function() {
  //location.hash = more.hash;
  header.parentNode.classList[!header.parentNode.classList.contains('expanded') ? 'add' : 'remove']('expanded')
  more.setAttribute('href', header.parentNode.classList.contains('expanded') ? '#' : '#about')
  more.textContent   = header.parentNode.classList.contains('expanded') ? 'Collapse' : 'Read more'
  window.slowdown = 2;
  window.scrollTo(0,0)
  clearTimeout(window.slowindown)
  Manager.animate()
  window.slowindown = setTimeout(function() {
    window.slowdown = 1;
  }, 1000)
  return false;
}
more.href = location.hash == '#about' ? '#' : '#about'
if (location.hash == '#about')
  header.parentNode.classList.add('expanded')
more.innerHTML = location.hash == '#about' ? 'Collapse' : 'Read more'
header.appendChild(more)

};
Manager.initHeader()
setTimeout(function() {
  document.body.classList.add('ready')
  if (location.search.indexOf('public') > -1)
    document.body.classList.add('public')
}, 50)
document.addEventListener('click', function(e) {
  if (window.currentManager) {
    var section = window.currentManager;
    Manager.close(window, section);
    window.currentManager = null;
  }
  if (window.currentLister) {
    var listing = window.currentLister;
    Lister.close(window, section);
    window.currentLister = null;
  }
  for (var p = e.target; p; p = p.parentNode) {
    if (p.classList && p.classList.contains('edit')) {
      var edit = p;
    } else if (p.classList && p.classList.contains('save')) {
      var save = p;
    } else if (p.classList && p.classList.contains('menu')) {
      var menu = p;
    } else if (p.classList && p.classList.contains('cancel')) {
      var cancel = p;
    } else if (p.classList && p.classList.contains('delete')) {
      var Delete = p;
    } else if (p.classList && p.classList.contains('undo')) {
      var undo = p;
    } else if (p.classList && p.classList.contains('redo')) {
      var redo = p;
    } else if (p.classList && p.classList.contains('add')) {
      var add = p;
    } else if (p.classList && p.classList.contains('split')) {
      var split = p;
    } else if (p.id == 'sectionizer') {
      var clickedSectionizer = p;
    } else if (p.id == 'manager') {
      var clickedManager = p;
    } else if (p.id == 'saver') {
      var clickedSaver = p;
    } else if (p.id == 'lister') {
      var clickedLister = p;
    } else if (p.classList && p.classList.contains('toolbar')) {
      var toolbar = p;
    } else if (p.classList && p.classList.contains('list')) {
      var list = p;
    } else if (p.tagName == 'ARTICLE') {
      var article =  p;
    } else if (p.tagName == 'HEADER') {
      var header =  p;
    } else if (p.tagName == 'SECTION') {
      var section =  p;
      if (p.parentNode.getAttribute('contenteditable') != null)
        return false;
    } else if (p.classList && p.classList.contains('layout-headlines')) {
      var layout = 'headlines';
    } else if (p.classList && p.classList.contains('layout-stream')) {
      var layout = 'stream';
    } else if (p.classList && p.classList.contains('layout-carousel')) {
      var layout = 'carousel';
    } else if (p.classList && p.classList.contains('layout-thumbnails')) {
      var layout = 'thumbnails';
    }
  }
  if (toolbar && header && list) {
    if (toolbar && (toolbar.querySelector('use').getAttribute('href').indexOf('add-icon') > -1)) {
      Service.new(header.parentNode)
    } else {
      window.currentLister = header.parentNode;
      Lister.open(window, header.parentNode);
    }
  } else if (toolbar && section) {
    var use = toolbar.querySelector('use');

    if (use && (use.getAttribute('href').indexOf('fork') > -1 || 
                use.getAttribute('href').indexOf('edit') > -1 || 
                use.getAttribute('href').indexOf('star') > -1) || 
                use.getAttribute('href').indexOf('settings') > -1) {
      Service.edit(section.parentNode)

    } else {
      if (manager.getAttribute('hidden')) {
        window.currentManager = section;
        Manager.open(window, section);
      }
    }
    e.preventDefault()
  } else if (edit && clickedManager) {
    Service.edit(section.parentNode)
  } else if (save && clickedSaver) {
    Service.save(Service.currentElement)
  } else if (Delete && clickedSaver) {
    if (confirm('Are you sure to delete this ' + Service.currentElement.getAttribute('itemtype') + '?'))
      Service.delete(Service.currentElement)
  } else if (cancel && clickedSaver) {
    Service.cancel(Service.currentElement)
  } else if (undo && clickedSaver) {
    if (Service.editor) Service.editor.undoManager.undo()
  } else if (redo && clickedSaver) {
    if (Service.editor) Service.editor.undoManager.redo()
  } else if (add && clickedLister) {
    Service.new(listing)
    Lister.close(window, listing);
  } else if (split && clickedLister) {
    Service.editList(listing)
    Lister.close(window, listing);
  } else if (layout && listing) {
    if (layout == 'thumbnails')
      listing.removeAttribute('layout')
    else
      listing.setAttribute('layout', layout)
    Lister.close(window, listing)
    Layout()
    Manager.animate()
  }

})

var manager = document.createElement('div');
manager.id = 'manager';
manager.setAttribute('hidden', 'hidden')
manager.className = 'circle-menu';
manager.innerHTML = '\
  <svg viewBox="0 0 48 48" class="top edit handler icon"><use xlink:href="#edit-icon"></use></svg>\
  <svg viewBox="0 0 48 48" class="center unstar icon"><use xlink:href="#unstar-icon"></use></svg>\
  <svg viewBox="0 0 48 48" class="center star icon"><use xlink:href="#star-icon"></use></svg>\
  <svg viewBox="-1 0 50 50" class="left pick palette icon"><use xlink:href="#palette-icon"></use></svg>\
  <svg viewBox="-1 0 50 50" class="right pick settings icon"><use xlink:href="#settings-icon"></use></svg>\
  <svg viewBox="-2 2 48 48" class="bottom-left shrink zoomer icon"><use xlink:href="#zoom-out-icon"></use></svg>\
  <svg viewBox="-2 2 48 48" class="bottom-right enlarge zoomer icon"><use xlink:href="#zoom-in-icon"></use></svg>\
'
document.body.appendChild(manager);


var saver = document.createElement('div');
saver.id = 'saver';
saver.setAttribute('hidden', 'hidden')
saver.className = 'circle-menu';
saver.innerHTML = '\
  <svg viewBox="1 0 49 48" class="bottom-left undo icon"><use xlink:href="#undo-icon"></use></svg>\
  <svg viewBox="1 0 49 48" class="left cancel icon"><use xlink:href="#close-icon"></use></svg>\
  <svg viewBox="1 0 49 48" class="bottom-right redo icon"><use xlink:href="#redo-icon"></use></svg>\
  <svg viewBox="-2 2 48 48" class="right redo icon"><use xlink:href="#redo-icon"></use></svg>\
  <svg viewBox="-2 2 48 48" class="right save icon"><use xlink:href="#apply-icon"></use></svg>\
  <svg viewBox="1 0 49 48" class="top delete icon"><use xlink:href="#delete-icon"></use></svg>\
'
document.body.appendChild(saver);



var lister = document.createElement('div');
lister.id = 'lister';
lister.setAttribute('hidden', 'hidden')
lister.className = 'circle-menu';
lister.innerHTML = '\
  <svg viewBox="0 0 48 48" class="top add icon"><use xlink:href="#add-icon"></use></svg>\
  <svg viewBox="0 0 48 48" class="left layout-carousel icon"><use xlink:href="#layout-carousel-icon"></use></svg>\
  <svg viewBox="-2 -2 52 52" class="right layout-stream icon"><use xlink:href="#layout-stream-icon"></use></svg>\
  <svg viewBox="0 0 48 48" class="bottom-left layout-thumbnails icon"><use xlink:href="#layout-thumbnails-icon"></use></svg>\
  <svg viewBox="0 0 48 48" class="bottom-right layout-headlines icon"><use xlink:href="#layout-headlines-icon"></use></svg>\
  <svg viewBox="-2 2 48 48" class="center split icon"><use xlink:href="#split-section-icon"></use></svg>\
'
document.body.appendChild(lister);
