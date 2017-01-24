
if ((location.search || '').indexOf('action=submit') > -1) 
  if (!document.getElementsByClassName('error')[0]) {
    var form = document.getElementsByTagName('form')[0];
    if (form) form.submit();
  }