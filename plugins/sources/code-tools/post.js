(function() {
    const blocks = document.querySelectorAll('pre > code');
    if (!blocks.length) return;

    blocks.forEach((code, index) => {
        const pre = code.parentElement;
        if (!pre || pre.closest('.code-tools')) return;

        const wrapper = document.createElement('div');
        wrapper.className = 'code-tools';
        pre.parentNode.insertBefore(wrapper, pre);
        wrapper.appendChild(pre);

        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'code-copy';
        button.textContent = 'Copy';

        button.addEventListener('click', () => {
            const text = code.innerText;
            const setSuccess = () => {
                button.textContent = 'Copied';
                button.classList.add('copied');
                setTimeout(() => {
                    button.textContent = 'Copy';
                    button.classList.remove('copied');
                }, 1200);
            };

            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(setSuccess).catch(() => {});
            } else {
                const textarea = document.createElement('textarea');
                textarea.value = text;
                textarea.style.position = 'fixed';
                textarea.style.opacity = '0';
                document.body.appendChild(textarea);
                textarea.select();
                try {
                    document.execCommand('copy');
                    setSuccess();
                } catch (_) { }
                document.body.removeChild(textarea);
            }
        });

        wrapper.appendChild(button);
        pre.classList.add('code-block');

        const lines = code.innerHTML.split('\n');
        code.innerHTML = '';
        lines.forEach((line, lineIndex) => {
            const span = document.createElement('span');
            span.className = 'code-line';
            span.setAttribute('data-line', `${lineIndex + 1}`);
            span.innerHTML = line === '' ? ' ' : line;
            code.appendChild(span);
            if (lineIndex < lines.length - 1) {
                code.appendChild(document.createTextNode('\n'));
            }
        });
    });
})();
