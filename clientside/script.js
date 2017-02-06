
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
      var button = document.createElement('button');
      button.className = 'add button';
      var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
      svg.setAttribute('viewBox', '0 0 48 48');
      svg.innerHTML = '<use xlink:href="#close-icon" /></svg>';
      button.appendChild(svg)
      summaries[i].appendChild(button);
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
document.body.appendChild(icons);

(function (global, undefined) {
    "use strict";

    if (global.setImmediate) {
        return;
    }

    var nextHandle = 1; // Spec says greater than zero
    var tasksByHandle = {};
    var currentlyRunningATask = false;
    var doc = global.document;
    var registerImmediate;

    function setImmediate(callback) {
      // Callback can either be a function or a string
      if (typeof callback !== "function") {
        callback = new Function("" + callback);
      }
      // Copy function arguments
      var args = new Array(arguments.length - 1);
      for (var i = 0; i < args.length; i++) {
          args[i] = arguments[i + 1];
      }
      // Store and register the task
      var task = { callback: callback, args: args };
      tasksByHandle[nextHandle] = task;
      registerImmediate(nextHandle);
      return nextHandle++;
    }

    function clearImmediate(handle) {
        delete tasksByHandle[handle];
    }

    function run(task) {
        var callback = task.callback;
        var args = task.args;
        switch (args.length) {
        case 0:
            callback();
            break;
        case 1:
            callback(args[0]);
            break;
        case 2:
            callback(args[0], args[1]);
            break;
        case 3:
            callback(args[0], args[1], args[2]);
            break;
        default:
            callback.apply(undefined, args);
            break;
        }
    }

    function runIfPresent(handle) {
        // From the spec: "Wait until any invocations of this algorithm started before this one have completed."
        // So if we're currently running a task, we'll need to delay this invocation.
        if (currentlyRunningATask) {
            // Delay by doing a setTimeout. setImmediate was tried instead, but in Firefox 7 it generated a
            // "too much recursion" error.
            setTimeout(runIfPresent, 0, handle);
        } else {
            var task = tasksByHandle[handle];
            if (task) {
                currentlyRunningATask = true;
                try {
                    run(task);
                } finally {
                    clearImmediate(handle);
                    currentlyRunningATask = false;
                }
            }
        }
    }

    function installNextTickImplementation() {
        registerImmediate = function(handle) {
            process.nextTick(function () { runIfPresent(handle); });
        };
    }

    function canUsePostMessage() {
        // The test against `importScripts` prevents this implementation from being installed inside a web worker,
        // where `global.postMessage` means something completely different and can't be used for this purpose.
        if (global.postMessage && !global.importScripts) {
            var postMessageIsAsynchronous = true;
            var oldOnMessage = global.onmessage;
            global.onmessage = function() {
                postMessageIsAsynchronous = false;
            };
            global.postMessage("", "*");
            global.onmessage = oldOnMessage;
            return postMessageIsAsynchronous;
        }
    }

    function installPostMessageImplementation() {
        // Installs an event handler on `global` for the `message` event: see
        // * https://developer.mozilla.org/en/DOM/window.postMessage
        // * http://www.whatwg.org/specs/web-apps/current-work/multipage/comms.html#crossDocumentMessages

        var messagePrefix = "setImmediate$" + Math.random() + "$";
        var onGlobalMessage = function(event) {
            if (event.source === global &&
                typeof event.data === "string" &&
                event.data.indexOf(messagePrefix) === 0) {
                runIfPresent(+event.data.slice(messagePrefix.length));
            }
        };

        if (global.addEventListener) {
            global.addEventListener("message", onGlobalMessage, false);
        } else {
            global.attachEvent("onmessage", onGlobalMessage);
        }

        registerImmediate = function(handle) {
            global.postMessage(messagePrefix + handle, "*");
        };
    }

    function installMessageChannelImplementation() {
        var channel = new MessageChannel();
        channel.port1.onmessage = function(event) {
            var handle = event.data;
            runIfPresent(handle);
        };

        registerImmediate = function(handle) {
            channel.port2.postMessage(handle);
        };
    }

    function installReadyStateChangeImplementation() {
        var html = doc.documentElement;
        registerImmediate = function(handle) {
            // Create a <script> element; its readystatechange event will be fired asynchronously once it is inserted
            // into the document. Do so, thus queuing up the task. Remember to clean up once it's been called.
            var script = doc.createElement("script");
            script.onreadystatechange = function () {
                runIfPresent(handle);
                script.onreadystatechange = null;
                html.removeChild(script);
                script = null;
            };
            html.appendChild(script);
        };
    }

    function installSetTimeoutImplementation() {
        registerImmediate = function(handle) {
            setTimeout(runIfPresent, 0, handle);
        };
    }

    // If supported, we should attach to the prototype of global, since that is where setTimeout et al. live.
    var attachTo = Object.getPrototypeOf && Object.getPrototypeOf(global);
    attachTo = attachTo && attachTo.setTimeout ? attachTo : global;

    // Don't get fooled by e.g. browserify environments.
    if ({}.toString.call(global.process) === "[object process]") {
        // For Node.js before 0.9
        installNextTickImplementation();

    } else if (canUsePostMessage()) {
        // For non-IE10 modern browsers
        installPostMessageImplementation();

    } else if (global.MessageChannel) {
        // For web workers, where supported
        installMessageChannelImplementation();

    } else if (doc && "onreadystatechange" in doc.createElement("script")) {
        // For IE 6–8
        installReadyStateChangeImplementation();

    } else {
        // For older browsers
        installSetTimeoutImplementation();
    }

    attachTo.setImmediate = setImmediate;
    attachTo.clearImmediate = clearImmediate;
}(typeof self === "undefined" ? typeof global === "undefined" ? this : global : self));
