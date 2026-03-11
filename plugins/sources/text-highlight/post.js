(function() {
    const root = document.getElementById('content');
    if (!root) return;

    const highlightRegex = /==([^=\n]+)==/g;
    const skipSelector = 'code,pre,a,script,style,textarea';

    const shouldSkip = (node) => {
        if (!node.parentElement) return true;
        return node.parentElement.closest(skipSelector);
    };

    const replaceHighlight = (node) => {
        const text = node.nodeValue;
        if (!text) return;
        highlightRegex.lastIndex = 0;
        let match;
        let lastIndex = 0;
        const fragment = document.createDocumentFragment();
        let replaced = false;

        while ((match = highlightRegex.exec(text)) !== null) {
            const start = match.index;
            if (start > lastIndex) {
                fragment.appendChild(document.createTextNode(text.slice(lastIndex, start)));
            }

            const mark = document.createElement('mark');
            mark.className = 'text-highlight';
            mark.textContent = match[1];
            fragment.appendChild(mark);

            lastIndex = highlightRegex.lastIndex;
            replaced = true;
        }

        if (!replaced) return;
        if (lastIndex < text.length) {
            fragment.appendChild(document.createTextNode(text.slice(lastIndex)));
        }
        node.parentNode.replaceChild(fragment, node);
    };

    const walker = document.createTreeWalker(
        root,
        NodeFilter.SHOW_TEXT,
        {
            acceptNode: (node) => (shouldSkip(node) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT)
        }
    );

    const nodes = [];
    while (walker.nextNode()) {
        nodes.push(walker.currentNode);
    }
    nodes.forEach(replaceHighlight);
})();
