

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
Service.HTMLRequest = function(url, callback, fallback, data, method) {
  /*if (!Service.xhr) */Service.xhr = new XMLHttpRequest;
  //if (method && method.toLowerCase() != 'get' && method.toLowerCase() != 'post') {
  //  url += '?method' + method;
  //}
  setTimeout(function() {
  Service.xhr.open(method || (data != null ? 'POST' : 'GET'), url, true);
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
  Service.xhr.send(data || undefined)

  }, String(location.host).indexOf('localhost') > -1 ? 300 : 0)
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
  element.classList.add('loading');
  Service.HTMLRequest(Service.currentURL + '/new', function(doc) {
    Service.form = doc.querySelector('#layout-root > form:not(.sitemap)');
    var article = Service.form.querySelector('article')

    for (var first = element.firstElementChild; first; first = first.nextElementSibling)
      if (first.tagName != 'HEADER' && !first.classList.contains('kx') && !(parseFloat(first.getAttribute('order') || 1) < 1))
        break;
    article.classList.add('new')
    element.insertBefore(article, first)
    element.classList.remove('empty');
    article.classList.add('new-post')
    document.body.classList.add('new-post');
    window.snapshot.appear(article);
    Service.currentElement = article;
    Service.hook('beforeEdit', element, doc);
    Service.createEditor(article, doc, null, function() {
      Service.hook('afterEdit', element, doc);
    }, function() {
      element.classList.remove('loading');
      if (focusInitially !== false) {
        Service.editor.once('focus', function() {

          var title = element.querySelector('h1, h2') || element.querySelector('p');
          if (title)
            Editor.Placeholder.focus(Service.editor, title)
        })
        Service.editor.focus()
      }
    }, null, focusInitially);
    //Editor.Style.recompute(document.body)
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

  Editor.Content.prepare(element)
  element.classList.add('loading')

  // remove link from title, it'll be added back by back end
  

  Service.createEditor(element, null, true, function() {
    var header = element.querySelector('section:first-of-type h1, section:first-of-type h2');
    if (header && header.firstElementChild && header.firstElementChild.tagName == 'A' && header.firstElementChild == header.lastElementChild) {
      Service.editorTitleContent = header.innerHTML
      header.innerHTML = header.firstElementChild.innerHTML
    }

    if (Service.doc)
      Service.setEditorDocument(Service.editor, Service.doc);
    Service.hook('afterEdit', element);
  }, function() {
    Service.editor.focus()
    Editor.Placeholder.focus(Service.editor, element.querySelector('h1, h2'))
  }, false);

  Service.HTMLRequest(Service.currentURL + '/edit?no_js=true&rand=' + Math.random(), function(doc) {
    
    Service.hook('beforeEdit', element, doc);
    Service.doc = doc;
    if (Service.editor)
      Service.setEditorDocument(Service.editor, doc);

    //Editor.Style.recompute(document.body)
  }, function() {
    Service.cancel(element)
  })
}

Service.hooks = {};
Service.hooks.edit = {}
Service.hooks.beforeEdit = {}
Service.hooks.afterEdit = {}
Service.hooks.cancel = {}
Service.hooks.save = {}
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
  document.body.classList.add('editing-list');
  Editor.Content.prepare(element)
  element.classList.add('loading');

  Service.editorContent = element.innerHTML;
  Service.createEditor(element, null, false, null, function(editor) {
    for (var first = element.firstElementChild; first; first = first.nextElementSibling)
      if (first.tagName != 'HEADER' && !first.classList.contains('kx'))
        break;
    Editor.Section.insertBefore(editor, first, element)
    element.classList.remove('empty')
  }, false);
  
  Service.HTMLRequest(Service.currentURL + '/edit?no_js=true&rand=' + Math.random(), function(doc) {
    Service.setEditorDocument(Service.editor, doc, false)
    Saver.open(window, element);
    //Editor.Style.recompute(document.body)

  }, function() {
    element.classList.remove('loading');
    Service.cancel(element)
  })
}

Service.setEditorDocument = function(editor, doc, placeholders) {

  Service.form = doc.querySelector('#layout-root > form');
  editor.options.form = Service.form;
  editor.options.placeholders = placeholders;
  editor.element.$.classList.remove('loading')
  Editor.Section(editor, null, editor.observer)
  Saver.open(window, editor.element.$.getElementsByTagName('section')[0]);
}

Service.createEditor = function(element, doc, placeholders, callback, onReady, processInitially, focusInitially) {
  if (Service.editor)
    Service.cancel(Service.editor.element.$);

  element.setAttribute('contenteditable', 'true')
  formatting.style.top = formatting.style.left = '';
  formatting.setAttribute('hidden', 'hidden')

  if (!Service.editor) {
    if (doc)
      Service.form = doc.querySelector('#layout-root > form');

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

  var articles = element.querySelectorAll('article, header');
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
    if (onReady)
      onReady(editor)
  })
  if (callback)
    callback(editor)
  Editor.Section(editor, null, editor.observer)

  return editor
}

Service.invalidate = function(element) {

}

Service.delete = function(element) {
  var url = Service.currentURL;
  Service.HTMLRequest(url, function(doc) {
    Service.cancel(element, true)
  }, function() {
    Service.cancel(element)

  }, null, 'DELETE');
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
  var articles = element.querySelectorAll('article, header');
  for (var i = 0; i < articles.length; i++)
    Service.makeSelectable(articles[i])

  element.classList.add('saving')

  document.body.classList.remove('undoable');
  document.body.classList.remove('redoable');
  document.body.classList.remove('editing-list');
  Service.doc = null;

  var data = new FormData(Service.form);
  if (Service.form.onfakesubmit)
    Service.form.onfakesubmit(data)


  var url = Service.currentURL;
  if (element.classList.contains('new-post') || element.getAttribute('itemtype') == 'service')
    url += '/';
  Service.HTMLRequest(url, function(doc) {
    Service.hook('save', element);
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
      for (var p = element.parentNode; p = p.parentNode;) {
        if (p.nodeType == 1 && p.classList.contains('list')) {

          var lists = newArticle.querySelectorAll('.list');
          for (var i = 0; i < lists.length; i++)
            lists[i].parentNode.removeChild(lists[i])

          break;
        }
      }
    }
    for (var i = 0; i < newArticle.attributes.length; i++)
      element.setAttribute(newArticle.attributes[i].name, newArticle.attributes[i].value)
    snapshot.migrate(element, newArticle);


    Manager.processArticle(element);
    var articles = element.querySelectorAll('article, header');
    for (var i = 0; i < articles.length; i++) 
      Manager.processArticle(articles[i]);



    element.classList.remove('new-post')
    document.body.classList.remove('new-post');

    document.body.classList.remove('editing');
    Manager.animate()
    Editor.Style.recompute(document.body)

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

      var articles = element.querySelectorAll('article, header');
      for (var i = 0; i < articles.length; i++) {
        Service.makeUnselectable(articles[i])
      }
      Editor.Section(Service.editor, null, Service.editor.observer)
      Editor.Style.recompute(document.body)
//    }
  }, data)

}

Service.cancel = function(element, remove) {
  Saver.close();

  if (element.classList.contains('new-post'))
    remove = true;
  if (Service.editor) {
    var el = Service.editor.element.$;
    if (Service.editor.undoManager.undoable() && !confirm('Are you sure to discard changes in this ' + (element.getAttribute('itemtype') || 'list') + '?'))
      return false;

    Service.hook('cancel', element);
    Service.doc = null;

    document.body.classList.remove('undoable');
    document.body.classList.remove('redoable');
    document.body.classList.remove('editing-list');
    document.body.classList.remove('editing');
    document.body.classList.remove('new-post');


    if (Service.editorContent && Service.editor.undoManager.undoable()) {
      Service.editor.element.$.innerHTML = Service.editorContent;
    } else if (Service.editor.undoManager.snapshots.length && Service.editor.undoManager.undoable()) {
      Service.editor.undoManager.restoreImage(Service.editor.undoManager.snapshots[0])
    }
    Editor.Content.cleanEmpty(Service.editor, true, true)
    if (Service.editorTitleContent) {
      var title = el.querySelector('h1, h2');
      if (title) title.innerHTML = Service.editorTitleContent;
      Service.editorTitleContent = null;
    }
    Service.editorContent = null;
    Service.editor.fire('detachElement');

    Manager.processArticle(element, true);
    // keep element editable for duration of animation, then remove it
    if (remove) {
      el.setAttribute('contenteditable', 'true'); 
    }
    Service.editor = null;
    element.blur()
    element.removeAttribute('tabindex')


    var articles = element.querySelectorAll('article, header');
    for (var i = 0; i < articles.length; i++) {
      Service.makeSelectable(articles[i])
    }

    if (remove)
      element.setAttribute('hidden', 'hidden')

    var parent = element.parentNode;

    if (parent.classList.contains('list') && parent.getElementsByTagName('section').length == element.getElementsByTagName('section').length)
      parent.classList.add('empty')
    else if (element.classList.contains('list') && !element.getElementsByTagName('section').length)
      element.classList.add('empty')

    Manager.animate()
  }
  setTimeout(function() {
    element.classList.remove('saving')
    for (var p = element; p; p = p.parentNode)
      if (p.classList)
        p.classList.remove('has-editor')

    if (remove) {
      element.parentNode.removeChild(element)
      element.classList.remove('new-post')

      Editor.Style.recompute(document.body)
    }
  }, 500);
}

Service.revert = function(element) {
  document.body.classList.remove('editing');
}


// request content from mainpage and put article titles into nav
Service.populateNavigation = function(sitemap) {
  Service.HTMLRequest(location.pathname.match(/\/(?:~[^\/]+\/)?/), function(doc) {
    sitemap.classList.add('populated')
    var links = sitemap.querySelectorAll('.sitemap > nav.main > ul > li > a');
    for (var i = 0; i < links.length; i++) {
      var bits = links[i].pathname.split('/');
      var resource = bits.pop();
      if (!resource) resource = bits.pop();
      var list = doc.querySelector('[itemtable="' + resource + '"]');
      if (list) {
        var sublist = Service.getLinkList(list);
        if (sublist) {

          links[i].parentNode.appendChild(sublist)
          links[i].parentNode.parentNode.setAttribute('open', 'open')
        }
      }
    }
    Manager.animate()

  })
}

Service.getLinkList = function(list) {
  var container = document.createElement('ul');
  container.classList.add('list');
  for (var j = 0; j < list.children.length; j++) {
    if (list.children[j].tagName == 'ARTICLE') {
      var li = document.createElement('li');
      container.appendChild(li)

      var excerpt = list.children[j].getElementsByTagName('section')[0];
      if (excerpt) {
        var a = excerpt.querySelector('h1 a, h2 a, h3 a')
        if (a)
          li.appendChild(a);
      }

      for (var k = 0; k < list.children[j].children.length; k++) {
        if (list.children[j].children[k].classList.contains('list')) {
          var sublist = Service.getLinkList(list.children[j].children[k]);
          if (sublist)
            li.appendChild(sublist)
        }
      }
    }
  }
  if (container.children.length)
    return container;
}

Service.makeUnselectable = function(element) {
  element.setAttribute('contenteditable', 'false');
  if (element.tagName == 'HEADER') {
    var elements = element.querySelectorAll('a');
  } else {
    var elements = element.querySelectorAll('p, li, h1, h2, h3');
  }
    

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
  element.removeAttribute('contenteditable');
  if (element.tagName == 'HEADER') {
    var elements = element.querySelectorAll('a');
  } else {
    var elements = element.querySelectorAll('p, li, h1, h2, h3');
  }
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
  var sitemap = document.querySelector('.sitemap.editing.resources');
  if (sitemap) {
    sitemap.parentNode.removeChild(sitemap);
  }
  var sitemap = document.querySelector('.sitemap.editing');
  if (sitemap)
    sitemap.classList.remove('editing')
  Builder.built = null
}
Service.hooks.save.service = function(element, doc) {
  var sitemap = document.querySelector('.sitemap.editing.resources');
  if (sitemap) {
    sitemap.parentNode.removeChild(sitemap);
  }
  var sitemap = document.querySelector('.sitemap.editing');
  if (sitemap)
    sitemap.classList.remove('editing')
  Builder.built = null
}


Service.hooks.beforeEdit.service = function(element, doc) {
  var sitemap = doc.querySelector('form.sitemap nav');
  element.parentNode.classList.add('editing')
  if (sitemap && element.tagName == 'HEADER') {
    var header = document.createElement('div');
    header.className = 'sitemap editing resources'
    header.appendChild(sitemap)
    element.parentNode.parentNode.insertBefore(header, element.parentNode)
    Builder.init()
    Builder.open(sitemap, false)
  }
}

