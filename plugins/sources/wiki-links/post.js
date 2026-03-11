(function() {
    const root = document.getElementById('content');
    if (!root) return;

    const tokenRegex = /\[\[[^\]]+\]\]|#[\w\u4e00-\u9fa5-]+|@[\w\u4e00-\u9fa5-]+/g;
    const skipSelector = 'code,pre,a,script,style,textarea';

    const shouldSkip = (node) => {
        if (!node.parentElement) return true;
        return node.parentElement.closest(skipSelector);
    };

    const buildWikiLink = (token) => {
        const label = token.slice(2, -2).trim();
        if (!label) return document.createTextNode(token);
        const link = document.createElement('a');
        link.className = 'wikilink';
        link.href = `wikilink:${encodeURIComponent(label)}`;
        link.textContent = label;
        return link;
    };

    const buildTag = (token, className) => {
        const link = document.createElement('a');
        link.className = className;
        link.textContent = token;
        if (className === 'wikitag') {
            link.href = 'tag:' + encodeURIComponent(token);
        } else {
            link.href = 'mention:' + encodeURIComponent(token);
        }
        return link;
    };

    const replaceTokens = (node) => {
        const text = node.nodeValue;
        if (!text) return;
        tokenRegex.lastIndex = 0;
        let match;
        let lastIndex = 0;
        const fragment = document.createDocumentFragment();
        let replaced = false;

        while ((match = tokenRegex.exec(text)) !== null) {
            const start = match.index;
            const token = match[0];
            if (start > lastIndex) {
                fragment.appendChild(document.createTextNode(text.slice(lastIndex, start)));
            }

            let nodeToInsert = null;
            if (token.startsWith('[[')) {
                nodeToInsert = buildWikiLink(token);
            } else {
                const prevChar = start > 0 ? text[start - 1] : '';
                if (prevChar && /[A-Za-z0-9_\u4e00-\u9fa5]/.test(prevChar)) {
                    nodeToInsert = document.createTextNode(token);
                } else if (token.startsWith('#')) {
                    nodeToInsert = buildTag(token, 'wikitag');
                } else if (token.startsWith('@')) {
                    nodeToInsert = buildTag(token, 'wikimention');
                }
            }

            fragment.appendChild(nodeToInsert ?? document.createTextNode(token));
            lastIndex = tokenRegex.lastIndex;
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
    nodes.forEach(replaceTokens);
})();
