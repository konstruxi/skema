
document.addEventListener('DOMContentLoaded', function() {
  // Thanks safari
  document.body.parentNode.style.fontSize = '16.0000001px'

  Builder.init();
  Manager.animate()

  window.addEventListener('scroll', function() {
    window.snapshot.updateVisibility(true);
  })
  window.addEventListener('resize', function() {
    window.snapshot.updateVisibility();
  })
})
//window.addEventListener('load', function() {
//  window.snapshot = Kex.take(document.body, {
//    selector: 'section, div, ul, li, ol, h1, h2, h3, h4, h5, dl, dt, dd, p, nav, dl, header, footer, main, article, details, summary, aside, button, form, input, label, summary a, select, textarea'
//  });
//})




