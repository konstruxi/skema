
if ((location.search || '').indexOf('action=submit') > -1) 
  if (!document.getElementsByClassName('error')[0]) {
    var form = document.getElementsByTagName('form')[0];
    if (form) form.submit();
  }

document.addEventListener('click', function(e) {
  for (var p = e.target; p; p = p.parentNode) {
    if (p.tagName == 'LABEL') {
      var label = p;
      var target = document.getElementById(label.getAttribute('for'));
      if (target && target.classList.contains('deletion')) {
        target.checked = !target.checked;
        return e.preventDefault()
      }
    } else if (p.tagName == 'SUMMARY') {
      var summary = p;
    } else if (p.tagName == 'DETAILS') {
      var details = p;
      break;
    } else if (p.tagName == 'BODY') {
      if (window.currentDetails) {
        for (var d = window.currentDetails; d; d = d.parentNode) {
          if (d && d.tagName == 'DETAILS') {
            closeDetails(d, true)
          }
        }
        window.currentDetails = null;
        //requestAnimationFrame(function() {
          window.snapshot = window.snapshot.animate();
        //})
      }
    }
  }
  if (!details) return;
  
  if (summary && (document.activeElement != summary)) {
    e.preventDefault()
    return;
  }

  if (clickDetails(details, summary) === false)
    return e.preventDefault();
})


clickDetails = function(details, summary) {
  if (window.currentDetails) {

    for (var p = window.currentDetails; p && p != details; p = p.parentNode)
      if (p.tagName == "DETAILS") {
        closeDetails(p);
//        p.removeAttribute('open')
      }

    //if (details.getAttribute('open') == null) {
    if (!details.classList.contains('open')) {
      for (var p = details.parentNode; p; p = p.parentNode)
        if (p.tagName == "DETAILS") {
          openDetails(p);
          //p.setAttribute('open', '')
        }
    } else {
      var nested = window.currentDetails.getElementsByTagName('details');
      for (var i = 0; i < nested.length; i++) {
        if (nested[i] != details) {
          closeDetails(nested[i]);
          //nested[i].classList.remove('open')
//          nested[i].removeAttribute('open')
        }
      }
    }
    window.currentDetails.classList.remove('current');
  }
  details.classList.add('current');
  var oldDetails = window.currentDetails;
  window.currentDetails = details;

  /*
  if (details.getAttribute('open') != null)
    details.removeAttribute('open')
  else
    details.setAttribute('open', '')*/

  // force open 
    if (details.getAttribute('open') == null)
      details.setAttribute('open', '')

  // click on parent details summary to collapse current
  if (oldDetails != details && oldDetails && details.classList.contains('open')) {
    var result = false;

  // toggle summary
  } else if (summary) {

    if (details.classList.contains('open')) 
      closeDetails(details)
    else
      openDetails(details)
    var result = false;
  }
  //requestAnimationFrame(function() {
    window.snapshot = window.snapshot.animate();
  //})
  return result;
}

closeDetails = function(el, blurring) {
  el.classList.remove('open')
  if (blurring)
    el.classList.remove('current');

  var callback = function() {
    if (!el.classList.contains('open')) {
      updateDetails(el);
    }
  };

  if (blurring) callback()
  else requestAnimationFrame(callback)
}
openDetails = function(el) {
  el.classList.add('open')
}
// add has-focus to all focusable parents


updateDetails = function(el) {
  var link = el.querySelector('summary a');
  var input = el.querySelector('summary input');
  if (!input) return;
  if (input.value.trim().length == 0) {
    el.parentNode.classList.add('removed');
    setTimeout(function() {
      el.parentNode.parentNode.removeChild(el.parentNode);
      for (var p = el; p = p.parentNode;)
        if (p.tagName == 'NAV')
          rebuildList(nav, 'service', 0);
    }, 600)
  } else {
    if (link && input) {
      link.innerHTML = input.value
    }
  }
}

document.focusedElement = null;
document.addEventListener('focusin', function(e) {
  e.target.classList.add('focus')
  for (var p = e.target; p; p = p.parentNode ) {
    if (p.nodeType == 1 && p.getAttribute('tabindex') || p.tagName == 'SUMMARY') {
      p.classList.add('has-focus');
    }
  }
  document.focusedElement = e.target;
}, true)
document.addEventListener('focusout', function(e) {
  var focused = document.focusedElement;
  focused.classList.remove('focus');
  setTimeout(function() {
    var current = []
    if (document.focusedElement != focused)
      for (var p = document.focusedElement; p; p = p.parentNode ) 
        if (p.nodeType == 1 && p.getAttribute('tabindex') || p.tagName == 'SUMMARY') 
          current.push(p)
    for (var p = focused; p; p = p.parentNode ) {
      if (p.nodeType == 1 && p.getAttribute('tabindex') || p.tagName == 'SUMMARY') {
        if (current.indexOf(p) == -1)
          p.classList.remove('has-focus');
      }
    }
  }, 20);
})