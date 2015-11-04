# recline-editor

A [reclinejs](http://reclinejs.com) based editor, simplified, where you can send a URL for it to pull data from and a URL for it to push data to.

It aims to be used as part of a efficient data grid editor workflow, all you need to do is redirect to it passing a url that will respond with JSONP array data and a URL for where it should POST the changed JSON array to.

Example:

    <script>
    var urlWithData = 'http://localhost/records.json';
    var urlToPostData = 'http://localhost/save';
    var fields = 'afield:atitle,anotherfield:anothertitle,otherfield'; // optional
    location.href='http://localhost/editor/index.html?from='+encodeURIComponent(urlWithData)+'to='+encodeURIComponent(urlToPostData)+'fields='+fields;
    </script>

## License

MIT

