

Service = function(url, callback) {
}
Service.HTMLRequest = function(url, callback, fallback, data) {
  if (!Service.xhr) Service.xhr = new XMLHttpRequest;
  Service.xhr.open(data != null ? 'POST' : 'GET', url);
  Service.xhr.onreadystatechange = function(e) {
    if (Service.xhr.readyState == 4) {
      
      var doc = document.createElement('html');
      doc.innerHTML = Service.xhr.responseText
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

Service.new = function(element) {
  var url = '';
  for (var p = element; p = p.parentNode;)
    if (p.nodeType == 1 && p.getAttribute('itemname')) {
      url += '/' + p.getAttribute('itemname');
    }
  url += '/' + element.getAttribute('itemtable') + '/'
  Service.currentURL = url;
  Service.HTMLRequest(url + '/new', function(doc) {
    Service.form = doc.querySelector('#layout-root > form:not(.sitemap)');
    var article = Service.form.querySelector('article')

    for (var first = element.firstElementChild; first; first = first.nextElementSibling)
      if (first.tagName != 'HEADER' && !first.classList.contains('kx'))
        break;
    element.insertBefore(article, first)
    article.classList.add('unsaved')
    window.snapshot.appear(article);
    Service.currentElement = article;
    Service.createEditor(article, doc);
    console.log(article, 555)
  }, function() {
    Service.cancel(element)
  })
}

Service.getURL = function(element) {
  return /*'/' + element.getAttribute('itemprop') + */'/' + element.getAttribute('itemname')
}
Service.edit = function(element) {
  Service.currentURL = Service.getURL(element);
  Service.currentElement = element;
  Service.HTMLRequest(Service.currentURL + '/edit?no_js=true&rand=' + Math.random(), function(doc) {
    Editor.Content.prepare(element)
    Service.createEditor(element, doc);
  }, function() {
    Service.cancel(element)
  })
}

Service.createEditor = function(element, doc) {
  element.setAttribute('contenteditable', 'true')
    
  Service.form = doc.querySelector('#layout-root > form:not(.sitemap)');

  if (!Service.editor) {
    var editor = Service.editor = new Editor(element, {
      form: Service.form,
      snapshot: window.snapshot
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
  document.body.classList.add('editing');
  for (var p = element; p = p.parentNode;)
    if (p.classList && p.classList.contains('list'))
      p.classList.add('has-editor')
  Manager.editor = editor;
  Editor.Section(editor, null, editor.observer)
  Saver.open(window, element.getElementsByTagName('section')[0]);
}

Service.invalidate = function(element) {

}

Service.save = function(element) {
  if (Service.form.onfakesubmit)
    Service.form.onfakesubmit()

  Editor.Content.cleanEmpty(Service.editor, true, true)

  element.classList.add('saving')

  document.body.classList.remove('undoable');
  document.body.classList.remove('redoable');

  Service.editor.fire('lockSnapshot')

  var data = new FormData(Service.form);
  Service.HTMLRequest(Service.currentURL, function(document) {
    Service.editor.fire('detachElement');
    Saver.close();
    Service.editor = null;
    var newArticle = document.querySelector('[itemtype="' + element.getAttribute('itemtype') + '"][itemid="' + element.getAttribute('itemid') + '"]')
                  || document.querySelector('.content[name$="[content]"]')
                  || document.querySelector('article[itemtype]')
    snapshot.migrate(element, newArticle)
    Manager.processArticle(element);


    Manager.animate()

    setTimeout(function() {
      element.classList.remove('saving')
      for (var p = element; p = p.parentNode;)
        if (p.classList)
          p.classList.remove('has-editor')
    }, 300);
  }, function(doc) {
//    if (this.status == 400) {
      debugger
      Service.form = doc.querySelector('#layout-root > form:not(.sitemap)');
      Service.editor.options.form = Service.form;
      var newArticle = doc.querySelector('[name$="[content]"], [name$="[title]"]')
      snapshot.migrate(element, newArticle)
      Manager.processArticle(element);
      Editor.Section(Service.editor, null, Service.editor.observer)
//    }
  }, data)


  document.body.classList.remove('editing');
}

Service.cancel = function(element) {
  document.body.classList.remove('undoable');
  document.body.classList.remove('redoable');

  Saver.close();
    
  if (Service.editor) {

    if (Service.editor.undoManager.snapshots.length && Service.editor.undoManager.undoable())
      Service.editor.undoManager.restoreImage(Service.editor.undoManager.snapshots[0])

    Service.editor.fire('detachElement');
    Service.editor = null;
    
    document.body.classList.remove('editing');
    Manager.processArticle(element, true);

    if (element.classList.contains('unsaved'))
      element.setAttribute('hidden', 'hidden')

    Manager.animate()
  }
  setTimeout(function() {
    element.classList.remove('saving')
    for (var p = element; p = p.parentNode;)
      if (p.classList)
        p.classList.remove('has-editor')

  if (element.classList.contains('unsaved'))
    element.parentNode.removeChild(element)
  }, 500);
}

Service.revert = function(element) {
  document.body.classList.remove('editing');
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
    elements[i].innerHTML = '';
  }
}
Service.makeSelectable = function(element) {
  var elements = element.querySelectorAll('[kx-html]');
  for (var i = 0; i < elements.length; i++) {
    elements[i].innerHTML = elements[i].getAttribute('kx-text');
    elements[i].removeAttribute('kx-text')
    elements[i].removeAttribute('kx-html')
    elements[i].removeAttribute('contenteditable')
  }
  
}

