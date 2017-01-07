var fs = require('fs')
var glob = require('glob')


console.log('Chunks = {}');
glob("**/**.sql", {}, function (er, files) {
	files.forEach(function(file) {
		if (file.indexOf('backup') > -1) return;
		var content = fs.readFileSync('./' + file).toString().replace(/\n/g, '\\n').replace(/"/g, '\\"');
		console.log('Chunks' + '["' + file.replace('.glsl', '') + '"] = "' + content + '"\n');
	})
})