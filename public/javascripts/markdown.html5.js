// Released under MIT license
// Copyright (c) 2012 Syu Kato <ukyo.web@gmail.com>

markdown.toHTML5 = function(source, dialect, options) {
    var tree = markdown.toHTML5Tree(source, dialect, options);
    return markdown.renderJsonML(tree);
};

markdown.toHTML5Tree = function(source, dialect, options) {
    return (function to5(tree, level) {
        var i, m,
            indices = [],
            hx = 'h' + level,
            n = tree.length,
            blocks = [];
        
        if(!n) return [];
        
        function set(start, end) {
            blocks.push(['section', ['h1', tree[start][1]]].concat(to5(tree.slice(start + 1, end), level + 1)));
        }
        
        for(i = 0; i < n && hx !== tree[i][0]; ++i) blocks.push(tree[i]);
        for(i = 0; i < n; ++i) if(hx === tree[i][0]) indices.push(i);
        for(i = 0, m = indices.length - 1; i < m; ++i) set(indices[i], indices[i + 1]);
        if(indices.length) set(indices[m], n);
        
        return blocks;
    })(markdown.toHTMLTree(source, dialect, options), 1);
};