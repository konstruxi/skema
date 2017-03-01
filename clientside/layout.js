Layout = function(doc) {
  if (!doc) doc = document;

  var lists = doc.querySelectorAll('.list[layout="carousel"], .list[layout="stream"], .list[layout="headlines"]');

  var compacted = []
  for (var i = 0; i < lists.length; i++) {
    var sections = lists[i].querySelectorAll('section, article');
    for (var j = 0; j < sections.length; j++) {
      compacted.push(sections[j]);
      sections[j].classList.add('compacted')
    }
  }

  var old = doc.querySelectorAll('.compacted');
  for (var i = 0; i < old.length; i++) {
    if (compacted.indexOf(old[i]) == -1)
      old[i].classList.remove('compacted')
  }
}

Layout()