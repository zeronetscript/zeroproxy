//comes from webtelnet
function convertToColor(buf) {
  // now we send utf8 string instead of utf8 array
  // var data = new Uint8Array(buf);
  // var str = binayUtf8ToString(data, 0);
  var str = buf;

  var lines = str.split('\r\n');

  var result=[];
  for(var i=0; i<lines.length; i++) {
    var line = lines[i].replace(/\s\s/g, '&nbsp;');
    if(i < lines.length-1) line += '<br/>';

    // replace the prompt "> " with a empty line
    var len = line.length;
    if(len>=2 && line.substr(len-2) == '> ') line = line.substr(0, line-2) + '<br/>';

    line = ansi_up.ansi_to_html(line);

    result.push(line);
  }

  return result;
}

function adjustLayout() {
  var w = $(window).width(), h = $(window).height();
  var w0 = $('div#cmd').width();
  var w1 = $('button#send').outerWidth(true);
  var w2 = $('button#clear').outerWidth(true);
  $('input#cmd').css({
    width: (w0 - (w1+w2+14)) + 'px',
  });
  var h0 = $('div#cmd').outerHeight(true);
  $('div#out').css({
    width: (w-2) + 'px',
    height: (h - h0 -200) + 'px',
  });
}


