

Service = function() {
  Service.sitemap = document.querySelector('.sitemap');
  if (Service.sitemap)
    Service.sitemap.addEventListener('mouseover', function() {
      if (!Service.sitemapPopulated) {
       // Manager.animate()
        Service.sitemapPopulated = true;
        Service.populateNavigation(Service.sitemap)
      } else {
        //Manager.animate()
      }
    })

  Array.prototype.forEach.call(document.querySelectorAll('.list[itemtype=comment]'), function(list) {
    Service.new(list, false)
  })
}
Service.a = document.createElement('a');
Service.HTMLRequest = function(url, callback, fallback, data) {
  if (!Service.xhr) Service.xhr = new XMLHttpRequest;
  Service.xhr.open(data != null ? 'POST' : 'GET', url);
  Service.xhr.onreadystatechange = function(e) {
    if (Service.xhr.readyState == 4) {
      
      var doc = document.createElement('html');
      // rebase local urls 
      doc.innerHTML = Service.xhr.responseText.replace(/(src|href)="\.\/([^"]+?)"/g, function(m, attribute, value) {
        Service.a.href = Service.xhr.responseURL;
        var bits = Service.a.href.split('/')
        bits.pop();
        return attribute + '="' + bits.join('/') + '/' + value + '"'
      })
      if (Service.xhr.status == 200 && !doc.querySelector('.field.errored')) {
        callback.call(Service.xhr, doc)
      } else if (fallback) {
        fallback.call(Service.xhr, doc)
      }
    }
  }
  Service.xhr.send(data || '')
}
Service.XMLRequest = function(url, callback) {
  if (!Service.xhr) Service.xhr = new XMLHttpRequest;
  Service.xhr.open('GET', url);
  Service.xhr.responseType = 'document'
  Service.xhr.overrideMimeType('text/xml');
  Service.xhr.onreadystatechange = function(e) {
    if (Service.xhr.status == 200 && Service.xhr.readyState == 4) {
      if (!Service.xhr.responseXML) {
        alert('Can\'t parse XML at ' + url)
      } else {
        callback(Service.xhr.responseXML)
      }
    }
  }
  Service.xhr.send()
}

Service.IframeRequest = function(url, callback) {
  if (!Service.iframe) {
    Service.iframe = document.createElement('iframe');
    Service.iframe.setAttribute('style', 'position: fixed;bottom: 0; left: 0; z-index: 1000000; width: 100%; height: 400px;  ');
    document.body.appendChild(Service.iframe)
  }
  Service.iframe.onload = function() {
    callback(Service.iframe.contentWindow.document)
  };
  Service.iframe.src = url;
}

Service.new = function(element, focusInitially) {
  Service.currentURL = Service.getURL(element);
  Service.HTMLRequest(Service.currentURL + '/new', function(doc) {
    Service.form = doc.querySelector('#layout-root > form:not(.sitemap)');
    var article = Service.form.querySelector('article')

    for (var first = element.firstElementChild; first; first = first.nextElementSibling)
      if (first.tagName != 'HEADER' && !first.classList.contains('kx') && !(parseFloat(first.getAttribute('order') || 1) < 1))
        break;
    element.insertBefore(article, first)
    article.classList.add('unsaved')
    window.snapshot.appear(article);
    Service.currentElement = article;
    Service.createEditor(article, doc, null, function() {
      Service.hook('afterEdit', element, doc);
      if (focusInitially !== false) {
        Service.editor.focus()
        var title = element.querySelector('h1, h2') || element.querySelector('p');
        if (title)
          Editor.Placeholder.focus(Service.editor, title)
      }
    }, null, focusInitially);

    Saver.open(window, article.getElementsByTagName('section')[0]);
  }, function() {
    Service.cancel(element)
  })
}

Service.getURL = function(element) {
  if (element.getAttribute('itemname')) {
    if (element.getAttribute('itemtype') == 'service')
      return '/~' + element.getAttribute('itemname');
    var url = '/' + element.getAttribute('itemname')
  } else {

    var url = '';
    for (var p = element; p = p.parentNode;)
      if (p.nodeType == 1 && p.getAttribute('itemname') && p.getAttribute('itemtype') != 'service') {
        url = '/' + p.getAttribute('itemname') + url;
      }
    url += '/' + (element.getAttribute('itemtable') || element.getAttribute('itemprop'))

    
  }
  var domain = location.pathname.match(/~([a-z0-9_-]+)/)
  if (domain) {
    return '/~' + domain[1] + url
  }
  return url;
}
Service.edit = function(element) {
  Service.currentURL = Service.getURL(element);
  Service.currentElement = element;
  Service.HTMLRequest(Service.currentURL + '/edit?no_js=true&rand=' + Math.random(), function(doc) {
    Editor.Content.prepare(element)
    // remove link from title, it'll be added back by back end
    var header = element.querySelector('section:first-of-type h1, section:first-of-type h2');
    if (header && header.firstElementChild && header.firstElementChild.tagName == 'A' && header.firstElementChild == header.lastElementChild) {
      header.innerHTML = header.firstElementChild.innerHTML
    }
    Service.createEditor(element, doc, true, function() {
      Service.editor.focus()
      Service.hook('afterEdit', element, doc);
      Editor.Placeholder.focus(Service.editor, element.querySelector('h1, h2'))
    });
    Saver.open(window, element.getElementsByTagName('section')[0]);
  }, function() {
    Service.cancel(element)
  })
}

Service.hooks = {};
Service.hooks.edit = {}
Service.hooks.beforeEdit = {}
Service.hooks.afterEdit = {}
Service.hooks.cancel = {}
Service.hook = function(name, element, argument) {
  var hooks = Service.hooks[name];
  if (hooks) {
    var fn = hooks[element.getAttribute('itemtype')];
    if (fn) {
      var result = fn(element, argument, name);
      if (result != null)
        argument = result;
    }
  }
  return argument;

}

Service.editList = function(element) {
  Service.currentURL = Service.getURL(element.parentNode);
  Service.currentElement = element;
  Service.HTMLRequest(Service.currentURL + '/edit?no_js=true&rand=' + Math.random(), function(doc) {
    Editor.Content.prepare(element)
    

    Service.createEditor(element, doc, false, function(editor) {
    for (var first = element.firstElementChild; first; first = first.nextElementSibling)
      if (first.tagName != 'HEADER' && !first.classList.contains('kx'))
        break;
      Editor.Section.insertBefore(editor, first, element)
    }, false);
    Saver.open(window, element);

  }, function() {
    Service.cancel(element)
  })
}

Service.createEditor = function(element, doc, placeholders, callback, processInitially, focusInitially) {
  if (Service.editor)
    Service.cancel(Service.editor.element.$);

  element.setAttribute('contenteditable', 'true')

  Service.form = doc.querySelector('#layout-root > form');

  if (!Service.editor) {
    var editor = Service.editor = new Editor(element, {
      form: Service.form,
      snapshot: window.snapshot,
      placeholders: placeholders,
      processInitially: processInitially
    })
  } else {
    var editor = Service.editor;
    editor.fire('attachElement', element);
  }

  editor.doNotParseInitially = true;

  editor.on('change', function(content) {
    if (editor.undoManager.redoable()) {
      document.body.classList.add('redoable');
    } else {
      document.body.classList.remove('redoable');
    }
    if (editor.undoManager.undoable()) {
      document.body.classList.add('undoable');
    } else {
      document.body.classList.remove('undoable');
    }
  })

  var articles = element.getElementsByTagName('article');
  for (var i = 0; i < articles.length; i++) {
    Service.makeUnselectable(articles[i])
  }
  if (focusInitially !== false)
    document.body.classList.add('editing');
  for (var p = element; p; p = p.parentNode)
    if (p.classList && p.classList.contains('list') || p.tagName == 'ARTICLE' || p == element)
      p.classList.add('has-editor')
  Manager.editor = editor;

  editor.once('instanceReady', function() {
    if (callback)
      callback(editor)
  })
  Editor.Section(editor, null, editor.observer)

  return editor
}

Service.invalidate = function(element) {

}

Service.save = function(element) {
  Service.editor.fire('lockSnapshot')
  if (element.classList.contains('list')) {
    var name = element.getAttribute('itemtable') + '_content'
    element.setAttribute('name', element.parentNode.getAttribute('itemtype') + '[' + name + ']')
    
    var counter = 0;
    var decimal = 0;

    for (var i = 0; i < element.children.length; i++) {
      if (element.children[i].tagName == 'SECTION') {
        decimal++
        element.children[i].setAttribute('order', counter + decimal / 100);
      } else if (element.children[i].tagName == 'ARTICLE') {
        decimal = 0;
        ++counter;
      }
    }
    element = element.parentNode;


  } else {
    var name = 'content';
  }

  Editor.Content.cleanEmpty(Service.editor, true, true)
  var articles = element.getElementsByTagName('article');
  for (var i = 0; i < articles.length; i++) {
    Service.makeSelectable(articles[i])
  }

  element.classList.add('saving')

  document.body.classList.remove('undoable');
  document.body.classList.remove('redoable');

  var data = new FormData(Service.form);
  if (Service.form.onfakesubmit)
    Service.form.onfakesubmit(data)


  var url = Service.currentURL;
  if (element.classList.contains('unsaved') || element.getAttribute('itemtype') == 'service')
    url += '/';
  setTimeout(function() {
  Service.HTMLRequest(url, function(doc) {
    element.blur()
    Service.editor.fire('detachElement');
    Saver.close();
    Service.editor = null;
    var newArticle = doc.querySelector('article[itemtype="' + element.getAttribute('itemtype') + '"][itemid="' + element.getAttribute('itemid') + '"]')
                  || doc.querySelector('header[itemtype="' + element.getAttribute('itemtype') + '"][itemid="' + element.getAttribute('itemid') + '"]')
                  || doc.querySelector('.content[name$="[' + name + ']"]')
                  || doc.querySelector('article[itemtype]')

    if (element.tagName == 'HEADER') { 
      for (var i = 0; i < newArticle.children.length; i++) {
        if (firstSection)
          newArticle.removeChild(newArticle.children[i--])
        else if (newArticle.children[i].tagName == 'SECTION')
          var firstSection = newArticle.children[i];

      }
    // dont show nested lists when creating items within lists
    } else if (element.parentNode.classList.contains('list')) {
      var lists = newArticle.querySelectorAll('.list');
      for (var i = 0; i < lists.length; i++)
        lists[i].parentNode.removeChild(lists[i])
    }
    for (var i = 0; i < newArticle.attributes.length; i++)
      element.setAttribute(newArticle.attributes[i].name, newArticle.attributes[i].value)
    snapshot.migrate(element, newArticle);

    Manager.processArticle(element);
    element.classList.remove('unsaved')

    document.body.classList.remove('editing');
    Manager.animate()

    setTimeout(function() {
      element.classList.remove('saving')
      for (var p = element; p; p = p.parentNode)
        if (p.classList)
          p.classList.remove('has-editor')
    }, 300);
  }, function(doc) {
//    if (this.status == 400) {
      Service.form = doc.querySelector('#layout-root > form:not(.sitemap)');
      Service.editor.options.form = Service.form;
      var newArticle = doc.querySelector('[name$="[' + name + ']"]')
      if (newArticle) {
        if (newArticle.getAttribute('itemtype'))
        snapshot.migrate(element, newArticle)
        Manager.processArticle(element);
      }    

      var articles = element.getElementsByTagName('article');
      for (var i = 0; i < articles.length; i++) {
        Service.makeUnselectable(articles[i])
      }
      Editor.Section(Service.editor, null, Service.editor.observer)
//    }
  }, data)
  }, 10)

}

Service.cancel = function(element) {
  document.body.classList.remove('undoable');
  document.body.classList.remove('redoable');

  Saver.close();

  Service.hook('cancel', element);
  if (Service.editor) {

    if (Service.editor.undoManager.snapshots.length && Service.editor.undoManager.undoable())
      Service.editor.undoManager.restoreImage(Service.editor.undoManager.snapshots[0])

    Service.editor.fire('detachElement');
    Service.editor = null;
    element.removeAttribute('tabindex')
    element.blur()

    document.body.classList.remove('editing');
    Manager.processArticle(element, true);

    if (element.classList.contains('unsaved'))
      element.setAttribute('hidden', 'hidden')
    element.classList.remove('unsaved')
    Service.makeSelectable(element);
    Manager.animate()
  }
  setTimeout(function() {
    element.classList.remove('saving')
    for (var p = element; p; p = p.parentNode)
      if (p.classList)
        p.classList.remove('has-editor')

    if (element.classList.contains('unsaved'))
      element.parentNode.removeChild(element)
  }, 500);
}

Service.revert = function(element) {
  document.body.classList.remove('editing');
}


// request content from mainpage and put article titles into nav
Service.populateNavigation = function(sitemap) {
  Service.HTMLRequest('/', function(doc) {
    var links = sitemap.querySelectorAll('.sitemap > nav.main > ul > li > a');
    for (var i = 0; i < links.length; i++) {
      var bits = links[i].pathname.split('/');
      var resource = bits.pop();
      if (!resource) resource = bits.pop();
      var container = document.createElement('div');
      container.classList.add('list');
      links[i].parentNode.appendChild(container)
      var list = document.querySelector('[itemtable="' + resource + '"]');
      if (list) {
        links[i].parentNode.parentNode.setAttribute('open', 'open')
        for (var j = 0; j < list.children.length; j++) {
          if (list.children[j].tagName == 'ARTICLE') {
            var excerpt = list.children[j].getElementsByTagName('section')[0];
            if (excerpt) {
              var clone = excerpt.cloneNode(true);
              var children = clone.children;
              for (var k = 0; k < children.length; k++)
                if (children[k].classList 
                  && !children[k].classList.contains('kx')
                  && children[k].tagName != 'HEADER'
                  && !children[k].classList.contains('list'))
                  container.appendChild(excerpt.cloneNode(true))
            }
          }
        }
      }
      console.log(links[i], resource)
    }
    Manager.animate()

  })
}

Service.makeUnselectable = function(element) {
  var elements = element.querySelectorAll('p, li, h1, h2, h3');
  for (var i = 0; i < elements.length; i++) {
    if (elements[i].firstElementChild 
    &&  elements[i].firstElementChild == elements[i].lastElementChild 
    &&  elements[i].firstElementChild.tagName == 'A') {
      elements[i] = elements[i].firstElementChild;
    }
    if (elements[i].getAttribute('kx-text')) return
    elements[i].setAttribute('kx-text', elements[i].textContent)
    elements[i].setAttribute('kx-html', elements[i].innerHTML)
    elements[i].setAttribute('contenteditable', 'false')
    if (elements[i].parentNode.tagName == 'UL' || elements[i].parentNode.tagName == 'BLOCKQUOTE')
      elements[i].parentNode.setAttribute('contenteditable', 'false')
    elements[i].innerHTML = '';
  }
}
Service.makeSelectable = function(element) {
  var elements = element.querySelectorAll('[kx-html]');
  for (var i = 0; i < elements.length; i++) {
    elements[i].innerHTML = elements[i].getAttribute('kx-html');
    elements[i].removeAttribute('kx-text')
    elements[i].removeAttribute('kx-html')
    elements[i].removeAttribute('contenteditable')
    if (elements[i].parentNode.tagName == 'UL' || elements[i].parentNode.tagName == 'BLOCKQUOTE')
      elements[i].parentNode.removeAttribute('contenteditable')
  }
  
}



Service()



Service.hooks.cancel.service = function(element, doc) {
  var sitemap = element.parentNode.querySelector('nav.resources');
  if (sitemap) {
    sitemap.parentNode.removeChild(sitemap);
  }
}


Service.hooks.afterEdit.service = function(element, doc) {
  var sitemap = doc.querySelector('form.sitemap nav');
  element.parentNode.classList.add('editing')
  if (sitemap) {
    element.parentNode.insertBefore(sitemap, element)
    buildNav()
  }
}

