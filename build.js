var fs = require('fs')
var glob = require('glob')


glob("**/**.html", {}, function (er, files) {
	files.forEach(function(file) {
		if (file.indexOf('backup') > -1) return;
		var content = fs.readFileSync('./' + file).toString().replace(/\n/g, '\\n').replace(/"/g, '\\"');
		var name = file.replace('.html', '').replace(/[^a-z0-9]/g, '_');
		console.log('set $' + name + ' "";\n');
		for (var i = 0; i < content.length; i += 1000) {
			console.log('set $' + name + ' "${' + name + '}' + content.substring(i, Math.min(i + 1000, content.length)) + '";\n');
		}
	})
})